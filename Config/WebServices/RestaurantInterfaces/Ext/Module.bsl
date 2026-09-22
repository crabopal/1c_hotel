#Region EventHandlers 

// -----------------------------------------------------------------------------
Function AddAmountToDiscountCard(pCardNumber, pSum, pRemarks, pExternalCode, pExternalSystemCode, pHotel, pSource = "")
	Return cmAddAmountToDiscountCard(pCardNumber, pSum, pRemarks, pExternalCode, pExternalSystemCode, pHotel, pSource);
EndFunction // ActivateCertificateByDiscountCard

// -----------------------------------------------------------------------------
Function AddTaskForDepartment(pExternalSystemCode, pHotel, pDepartment, pRemarks, pPopUp)
	// Get hotel
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotel) Then
		vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	EndIf;
	// Get department
	vDepartment = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Departments", pDepartment);
	// Create task
	cmSendMessageToDepartment(vDepartment, pRemarks, vHotel.MessageStatus, pPopUp, , True);
	// Return success
	Return True;
EndFunction // AddTaskForDepartment

// -----------------------------------------------------------------------------
Function ChargeServiceByClientCard(pCard, pService, pSum, pQuantity, pRemarks, pDetails, pCurrency, pExternalSystemCode)
	// Call API
	vRetVal = cmChargeExternalService(pCard, pService, pSum, pQuantity, pRemarks, pDetails, pCurrency, pExternalSystemCode);
	// Return
	Return Left(vRetVal, 4096);
EndFunction // ChargeServiceByClientCard

// -----------------------------------------------------------------------------
Function ChargeServiceByClientCardWithSMS(pCard, pService, pSum, pQuantity, pRemarks, pDetails, pCurrency, pExternalSystemCode, pSentSms = True)
	// Call API
	vCharge = Undefined;
	vPhone = "";
	vRetVal = cmChargeExternalService(pCard, pService, pSum, pQuantity, pRemarks, pDetails, pCurrency, pExternalSystemCode,,pSentSms,vPhone, vCharge);
	// Return
	vReplyType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ErrorDescriptionArray");
	vRetXDTO 			= XDTOFactory.Create(vReplyType);
	vRetXDTO.Error   	= Left(vRetVal, 4096);
	vRetXDTO.SentSms 	= pSentSms;
	vRetXDTO.ClientPhone= vPhone;
	vRetXDTO.ChargeNumber = ?(vCharge = Undefined,"",vCharge.Number);
	Return vRetXDTO;
EndFunction // ChargeServiceByClientCard

// -----------------------------------------------------------------------------
Function ChargeServiceByFolio(pFolioNumber, pService, pSum, pQuantity, pRemarks, pDetails, pHotel, pExternalSystemCode, pCurrency)
	// Call API
	vRetVal = cmChargeExternalServiceByFolio(pFolioNumber, pService, pSum, pQuantity, pRemarks, pDetails, pHotel, pExternalSystemCode, pCurrency);
	// Return
	Return Left(vRetVal, 4096);
EndFunction // ChargeServiceByFolio

// -----------------------------------------------------------------------------
Function ChargeServiceByFolioWithSMS(pFolioNumber, pService, pSum, pQuantity, pRemarks, pDetails, pHotel, pExternalSystemCode, pCurrency, pSentSms = True)
	// Call API
	vPhone = "";
	vCharge = Undefined;
	vRetVal = cmChargeExternalServiceByFolio(pFolioNumber, pService, pSum, pQuantity, pRemarks, pDetails, pHotel, pExternalSystemCode, pCurrency,,pSentSms,vPhone,,vCharge);
	// Return
	vReplyType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ErrorDescriptionArray");
	vRetXDTO 			= XDTOFactory.Create(vReplyType);
	vRetXDTO.Error   	= Left(vRetVal, 4096);
	vRetXDTO.SentSms 	= pSentSms;
	vRetXDTO.ClientPhone= vPhone;
	vRetXDTO.ChargeNumber = ?(vCharge = Undefined,"",vCharge.Number);
	Return vRetXDTO;
EndFunction // ChargeServiceByFolio

// -----------------------------------------------------------------------------
Function ChargeServiceByRoom(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode)
	// Call API
	vRetVal = cmChargeRoomService(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode);
	// Return
	Return Left(vRetVal, 4096);
EndFunction // ChargeServiceByRoom

// -----------------------------------------------------------------------------
Function ChargeServiceByRoomExt(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode, pExtCode)
	// Call API
	vRetVal = cmChargeRoomService(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode,Undefined,pExtCode);
	// Return
	Return Left(vRetVal, 4096);
EndFunction // ChargeServiceByRoom

// -----------------------------------------------------------------------------
Function ChargeServiceByRoomWithSMS(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode,pExtCode="", pSentSms = True)
	// Call API
	vCharge = Undefined;
	vPhone = "";
	vRetVal = cmChargeRoomService(pRoom, pDateTime, pSum, pClient, pCurrency, pService, pQuantity, pChargeType, pRemarks, pDetails, pHotel, pExternalSystemCode,,,,pSentSms,vPhone,, vCharge);
	// Return
	vReplyType 			= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ErrorDescriptionArray");
	vRetXDTO 			= XDTOFactory.Create(vReplyType);
	vRetXDTO.Error   	= Left(vRetVal, 4096);
	vRetXDTO.SentSms 	= pSentSms;
	vRetXDTO.ClientPhone= vPhone;
	vRetXDTO.ChargeNumber = ?(vCharge = Undefined,"",vCharge.Number);
	Return vRetXDTO;
EndFunction // ChargeServiceByRoom

// -----------------------------------------------------------------------------
Function CreateOrder(pExternalSystemCode, pHotel, pExternalOrderCode, pType, pDepartment, pOrderTime, pClient, pRemarks, //main parametr 
	pPickupFrom, pDestination, pPassengersNumber, pChildSeatsNumber, pCarType,  // Transfer parametr 
	pRentTime, pRentResourcesId,  // Rent parametr 
	pItems,pSum) // Room services parametr 
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotel) Then
		vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	EndIf;
	// Get department
	vDepartment = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Departments", pDepartment);
	// Get type
	vType = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Ordertypes",pType);
	If ValueIsFilled(vType) Then
		Info = Orders.GetGuestInfo(pExternalSystemCode, pHotel, pClient);
		
		vClient = Info.Guest;
		vPhone  = Info.Phone;
		vRoom    = Info.Room;
		vParentDoc =  Info.ParentDoc;
		If vType.PredefinedDataName = "Rent" Then
			If not ValueIsFilled(pRentTime) Then
				Return NStr("en='Rental resource lease time is not filled!'; ru='Не заполнено время аренды объекта'; de='Mietdauer ist nicht belegt!'");
			EndIf;
			
			vRentResources = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "Resources", pRentResourcesId);
			If not ValueIsFilled(vRentResources) Then
				Return NStr("en='Error determining rental resource!'; ru='Ошибка определения арендуемого ресурса!'; de='Fehler beim Bestimmen der Mietressource!'");
			EndIf;
			
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient,vRoom, vPhone, pRemarks,pSum,,,,,,pRentTime,vRentResources);			
			
		ElsIf vType.PredefinedDataName = "RoomService" Then
			
			If pItems.OrderItem.Count() = 0 Then
				Return NStr("en='The table of order items is not filled!'; ru='Не заполнена таблица позиций заказа!'; de='Die Tabelle der Auftragspositionen ist nicht gefüllt!'");
			EndIf;
			
			vOrderItems = New ValueTable;
			vOrderItems.Columns.Add("Item");
			vOrderItems.Columns.Add("Quantity");
			vOrderItems.Columns.Add("Price");
			
			For Each ItemRow In pItems.OrderItem Do
				
				vItem = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "OrderItems", ItemRow.ItemId);
				If not ValueIsFilled(vItem) Then 
					OrderItem = Catalogs.OrderItems.CreateItem();
					OrderItem.Description = ItemRow.ItemName;
					OrderItem.Price	      = ItemRow.Price;
					OrderItem.Code        = ItemRow.ItemId;
					OrderItem.Write();
					vItem = OrderItem.Ref;	
				EndIf;
				
				vNewRow = vOrderItems.Add();
				vNewRow.Item  = vItem;
				vNewRow.Quantity = ItemRow.Quantity; 
				vNewRow.Price = ItemRow.Price;				
				
			EndDo;
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient, vRoom, vPhone, pRemarks, pSum, , , , , , , , vOrderItems);
		ElsIf vType.PredefinedDataName = "Transfer" Then
			Orders.CreateOrderFromObjects(pExternalSystemCode, vHotel, pExternalOrderCode, vType, vDepartment, pOrderTime, vClient, vRoom, vPhone, pRemarks, pSum, pPickupFrom, pDestination);
		EndIf;
		Return "";
	Else
		Return NStr("en='Order type not found!'; ru='Тип заказа не существует!'; de='Bestelltyp nicht gefunden!'");
	EndIf;
EndFunction // CreateOrder

// -----------------------------------------------------------------------------
Function EventRating(pExternalSystemCode, pHotel, pGuestUUID, pEvent)
	WriteLogEvent(NStr("en = 'Get guest med schedule'; ru = 'Получить расписание медицинских назначений'; de = 'ärztlichen Zeitplan'"), EventLogLevel.Information, , , 
				NStr("en = 'External system code: '; ru = 'Код внешней системы: '; de = 'External system code: '") + pExternalSystemCode + Chars.LF +
				NStr("en='Hotel: '; de='Hotel: '; ru='Гостиница: '") + pHotel + Chars.LF +
				NStr("en='Guest UUID: '; de='Gast UUID: '; ru='UUID гостя: '") + pGuestUUID);

	vResult = "OK";
	vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	If ValueIsFilled(vHotel) THen
		Try
			vRecordManager 						= InformationRegisters.EventsRating.CreateRecordManager();
			vRecordManager.Hotel 				= vHotel;
			vRecordManager.ClientId				= pGuestUUID;
			vRecordManager.Period				= pEvent.Date;
			vRecordManager.Location				= pEvent.Location;
			vRecordManager.Description			= pEvent.Description;
			vRecordManager.Rating				= pEvent.Rating;
			vRecordManager.CalendarId			= pEvent.CalendarId;
			vRecordManager.EventId				= pEvent.EventId;	
			vRecordManager.Write(True);
		Except
			vResult = ErrorDescription();
		EndTry;
	Else
		vResult = "Failed to find hotel by code";
	EndIf;
	
	Return vResult;
EndFunction // EventRating

// -----------------------------------------------------------------------------
Function GetCardBalance(pCard, pExternalSystemCode)
	Return cmGetClientIdentificationCardBalance(pCard, "XDTO", pExternalSystemCode);
EndFunction // GetCardBalance

// -----------------------------------------------------------------------------
Function GetCertificateAmount(pGiftCertificate)
	Return  cmGetCertificateAmount(pGiftCertificate);
EndFunction // GetCertificateAmount

// -----------------------------------------------------------------------------
Function GetClientCardBalance(pCard)
	Return cmGetClientIdentificationCardBalance(pCard, "XDTO");
EndFunction // GetClientCardBalance

// -----------------------------------------------------------------------------
Function GetFolioDescription(pFolioNumber, pHotel, pExternalSystemCode)
	Return cmGetFolioDescription(pFolioNumber, pHotel, pExternalSystemCode, "XDTO");
EndFunction // GetFolioDescription

// -----------------------------------------------------------------------------
Function GetGuestDetails(pGuest)
	Return cmGetGuestDetails(pGuest, "XDTO");
EndFunction // GetGuestDetails

// -----------------------------------------------------------------------------
Function GetGuestFoliosWithTransactions(pExternalSystemCode, pHotel, pGuestUUID)
	WriteLogEvent(NStr("en='Get guest folios with transactions'; de='Get guest folios with transactions'; ru='Получить список лицевых счетов гостя с транзакциями'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel: '; de='Hotel: '; ru='Гостиница: '") + pHotel + Chars.LF +
				  NStr("en='Guest UUID: '; de='Gast UUID: '; ru='UUID гостя: '") + pGuestUUID);
	// Try to find guest accommodation by accommodation uuid
	vAccRef = SMS.GetClientDocumentByMyFolioId(pGuestUUID);
	
	If Not ValueIsFilled(vAccRef) AND StrLen(pGuestUUID) = 36 Then
		// It's a document guuid, try to find this document
		vUUID = New UUID(TrimAll(pGuestUUID));
		
		// Check if it's accommodation first
		vDocRef = Documents.Accommodation.GetRef(vUUID);
		If vDocRef.GetObject() = Undefined Then
			// Then check if it's reservation
			vDocRef = Documents.Reservation.GetRef(vUUID);
		EndIf;
		If vDocRef.GetObject() <> Undefined Then
			// Found document by GUUID
			vAccRef = vDocRef;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vAccRef) Then
		vCardRef = cmGetClientIdentificationCardById(pGuestUUID, False);
		If ValueIsFilled(vCardRef) And ValueIsFilled(vCardRef.ParentDoc) Then
			vAccRef = vCardRef.ParentDoc;
		EndIf;
		If Not ValueIsFilled(vAccRef) Then
			Raise NStr("en='Guest ID is wrong!'; ru='ID гостя указано неверно!'; de='Guest-ID ist falsch'");
		EndIf;
	EndIf;
	// Check that accommodation is in-house or check-out was today
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		If Not vAccRef.Posted Or Not vAccRef.AccommodationStatus.IsActive Or Not vAccRef.AccommodationStatus.IsInHouse And BegOfDay(vAccRef.CheckOutDate) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en='Guest is not in-house!'; ru='Гость не проживает!'; de='Gast nicht in-house!'");
		EndIf;
		vGuest = vAccRef.Guest;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ReservationStatus.IsActive Then
			Raise NStr("en='Reservation is canceled!'; ru='Бронь не активна!'; de='Die Reservierung ist storniert!'");
		EndIf;
		vGuest = vAccRef.Guest;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") Then
		If Not vAccRef.Posted Or Not vAccRef.ResourceReservationStatus.IsActive Or vAccRef.ResourceReservationStatus.ServicesAreDelivered And BegOfDay(vAccRef.DateTimeTo) < BegOfDay(CurrentSessionDate()) Then
			Raise NStr("en='Client is not in-house!'; ru='Мероприятие уже закончено!'; de='Kunde nicht in-house!'");
		EndIf;
		vGuest = vAccRef.Client;
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Folio") Then
		vGuest = vAccRef.Client;
	EndIf;
	If Not ValueIsFilled(vGuest) Then
		Raise NStr("en='Guest info is not in the system yet! Please wait a bit and try again...'; 
		           |ru='Данные гостя еще не занесены в систему! Пожалуйста подождите немного и попробуйте еще раз...'; 
				   |de='Gäste-Info ist nicht im System noch nicht! Bitte warten Sie ein wenig und versuchen Sie es erneut...'");
	EndIf;
	vLanguage = vGuest.Language;
	vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
	// Fill guest info
	vClientBalance = 0;
	vCreditLimit = 0;
	vRepCurrencyCode = "";
	vCurrency = Catalogs.Currencies.EmptyRef();
	vExchangeRateDate = CurrentSessionDate();
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestFoliosWithTransactions"));
	vGuestItem = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem"));
	vGuestFoliosList = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestFoliosList"));
	// Fill guest item
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		vGuestItem.Guest = TrimAll(vAccRef.GuestFullName) + ?(ValueIsFilled(vAccRef.DiscountCard), "(DC " + TrimAll(vAccRef.DiscountCard.Identifier) + ")", "");
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		vGuestItem.Guest = TrimAll(vAccRef.GuestFullName) + ?(ValueIsFilled(vAccRef.DiscountCard), "(DC " + TrimAll(vAccRef.DiscountCard.Identifier) + ")", "");
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") And ValueIsFilled(vAccRef.Client) Then
		vGuestItem.Guest = TrimAll(vAccRef.Client.FullName) + ?(ValueIsFilled(vAccRef.DiscountCard), "(DC " + TrimAll(vAccRef.DiscountCard.Identifier) + ")", "");
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Folio") And ValueIsFilled(vAccRef.Client) Then
		vGuestItem.Guest = TrimAll(vAccRef.Client.FullName);
	EndIf;
	vGuestItem.GuestCode = TrimAll(vGuest.Code);
	vGuestItem.GuestSex = Upper(Left(TrimAll(vGuest.Sex), 1));
	vGuestItem.GuestDateOfBirth = vGuest.DateOfBirth;
	vGuestItem.GuestAge = vGuest.Age;
	vGuestItem.GuestCitizenship = ?(ValueIsFilled(vGuest.Citizenship), Upper(TrimAll(vGuest.Citizenship.ISOCode3)), "");
	vGuestItem.GuestLanguage = ?(ValueIsFilled(vGuest.Language), Upper(TrimAll(vGuest.Language.Code)), "");
	vGuestItem.GuestLocale = ?(ValueIsFilled(vGuest.Language), ?(IsBlankString(vGuest.Language.LocalizationCode), "ru_RU", TrimAll(vGuest.Language.LocalizationCode)), "ru_RU");
	vGuestItem.Hotel = TrimAll(vAccRef.Hotel.Description);
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Then
		If ValueIsFilled(vAccRef.Room) Then
			vGuestItem.Room = TrimAll(vAccRef.Room.Description);
		EndIf;
		vGuestItem.CheckInDate = Date(vAccRef.CheckInDate);
		vGuestItem.CheckOutDate = Date(vAccRef.CheckOutDate);
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If ValueIsFilled(vAccRef.Room) Then
			vGuestItem.Room = TrimAll(vAccRef.Room.Description);
		EndIf;
		vGuestItem.CheckInDate = Date(vAccRef.CheckInDate);
		vGuestItem.CheckOutDate = Date(vAccRef.CheckOutDate);
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.ResourceReservation") Then
		vGuestItem.CheckInDate = Date(vAccRef.DateTimeFrom);
		vGuestItem.CheckOutDate = Date(vAccRef.DateTimeTo);
		vGuestItem.FolioNumber = ?(ValueIsFilled(vAccRef.ChargingFolio),vAccRef.ChargingFolio.Number,"");
	ElsIf TypeOf(vAccRef) = Type("DocumentRef.Folio") Then
		vGuestItem.CheckInDate = Date(vAccRef.DateTimeFrom);
		vGuestItem.CheckOutDate = Date(vAccRef.DateTimeTo);
		vGuestItem.FolioNumber = vAccRef.Number;
	EndIf;
	If ValueIsFilled(vAccRef.GuestGroup) Then
		vGuestItem.GuestGroup = vAccRef.GuestGroup.Code;
	EndIf;
	If ValueIsFilled(vAccRef.Customer) Then
		vGuestItem.Customer = TrimAll(vAccRef.Customer.Description);
	EndIf;
	If TypeOf(vAccRef) = Type("DocumentRef.Folio") Then
		If ValueIsFilled(vAccRef.FolioCurrency) Then
			vRepCurrencyCode = TrimAll(vAccRef.FolioCurrency.Code);
			vCurrency = vAccRef.FolioCurrency;
		EndIf;
		vExchangeRateDate = CurrentSessionDate();
		vGuestItem.PaymentMethod = vAccRef.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
		If ValueIsFilled(vAccRef.ParentDoc) Then
			vGuestItem.Discount = vAccRef.ParentDoc.Discount;
			vGuestItem.DiscountType = ?(ValueIsFilled(vAccRef.ParentDoc.DiscountType), TrimAll(vAccRef.ParentDoc.DiscountType.Description), "");
			vGuestItem.DiscountCard = ?(ValueIsFilled(vAccRef.ParentDoc.DiscountCard), TrimAll(vAccRef.ParentDoc.DiscountCard.Identifier), "");
			vGuestItem.AccommodationCode = TrimAll(vAccRef.ParentDoc.Number);
			If ValueIsFilled(vAccRef.ParentDoc.ClientType) Then
				vGuestItem.ClientType = vAccRef.ParentDoc.ClientType.Description;
			EndIf;
		Else
			vGuestItem.Discount = ?(ValueIsFilled(vAccRef.FolioDiscountType),vAccRef.FolioDiscountType.GetObject().pmGetDiscount(),0);
			vGuestItem.DiscountType = ?(ValueIsFilled(vAccRef.FolioDiscountType), TrimAll(vAccRef.FolioDiscountType.Description), "");
			vGuestItem.DiscountCard = ?(ValueIsFilled(vAccRef.FolioDiscountCard), TrimAll(vAccRef.FolioDiscountCard.Identifier), "");
			If ValueIsFilled(vAccRef.Client.ClientType) Then
				vGuestItem.ClientType = vAccRef.Client.ClientType.Description;
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(vAccRef.ReportingCurrency) Then
			vRepCurrencyCode = TrimAll(vAccRef.ReportingCurrency.Code);
			vCurrency = vAccRef.ReportingCurrency;
		EndIf;
		vExchangeRateDate = vAccRef.ExchangeRateDate;
		vGuestItem.PaymentMethod = vAccRef.PlannedPaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
		
		vGuestItem.Discount = vAccRef.Discount;
		vGuestItem.DiscountType = ?(ValueIsFilled(vAccRef.DiscountType), TrimAll(vAccRef.DiscountType.Description), "");
		vGuestItem.DiscountCard = ?(ValueIsFilled(vAccRef.DiscountCard), TrimAll(vAccRef.DiscountCard.Identifier), "");
		vGuestItem.AccommodationCode = TrimAll(vAccRef.Number);
		If ValueIsFilled(vAccRef.ClientType) Then
			vGuestItem.ClientType = vAccRef.ClientType.Description;
		EndIf;
	EndIf;
	vGuestItem.FolioCurrency = vRepCurrencyCode;
	If Not IsBlankString(vGuest.Phone) Then
		vGuestItem.GuestPhone = TrimAll(vGuest.Phone);
	ElsIf Not IsBlankString(vAccRef.Phone) Then
		vGuestItem.GuestPhone = TrimAll(vGuest.Phone);
	Else
		vGuestItem.GuestPhone = "";
	EndIf;
	vIsRoomShare = False;
	If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Or TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
		If ValueIsFilled(vAccRef.AccommodationType) And vAccRef.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
			vIsRoomShare = True;
		EndIf;
	EndIf;
	vGuestItem.IsRoomShare = vIsRoomShare;
	// Get document folios
	// Build and run query
	vFoliosCounter = 0;
	If TypeOf(vAccRef) = Type("DocumentRef.Folio") Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Folio.Ref AS Folio
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	Folio.Ref = &qDoc
		|	AND Folio.DeletionMark = FALSE
		|
		|ORDER BY
		|	Folio.PointInTime";
		vQry.SetParameter("qDoc", vAccRef);	
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Folio.Ref AS Folio
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	Folio.ParentDoc = &qDoc
		|	AND Folio.DeletionMark = FALSE
		|
		|ORDER BY
		|	Folio.PointInTime";
		vQry.SetParameter("qDoc", vAccRef);
	EndIf;
	vAccFolios = vQry.Execute().Unload();
	For Each vAccFoliosRow In vAccFolios Do
		
		vFolioRef = vAccFoliosRow.Folio;
		If TypeOf(vAccRef) = Type("DocumentRef.Accommodation") Or TypeOf(vAccRef) = Type("DocumentRef.Reservation") Then
			If ValueIsFilled(vFolioRef.Customer) And Not vFolioRef.Customer.IsIndividual Then
				Continue;
			EndIf;
		EndIf;
		
		vFolioObj = vFolioRef.GetObject();
		vFolioPreauthLimit = 0;
		vFolioBalance = vFolioObj.pmGetBalance(Undefined, vAccRef.Hotel, Undefined, vFolioPreauthLimit);
		vFolioBalance = 0;
		vFoliosCounter = vFoliosCounter + 1;
		
		// Build XDTO
		vGuestFolioItem = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestFolioItem"));
		vFolioItem = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Folio"));
		
		// Fill folio parameters
		vFolioItem.FolioNumber = TrimAll(vFolioObj.Number);
		vFolioItem.FolioDescription = Format(vFoliosCounter, "ND=10; NFD=; NG=") + ?(IsBlankString(vFolioObj.Description), "", " - ") + Left(TrimAll(vFolioObj.Description), 4096);
		vFolioItem.Hotel = TrimAll(vAccRef.Hotel.Description);
		vFolioItem.Room = TrimAll(vFolioObj.Room);
		vFolioItem.CheckInDate = vFolioObj.DateTimeFrom;
		vFolioItem.CheckOutDate = vFolioObj.DateTimeTo;
		vFolioItem.GuestGroup = ?(ValueIsFilled(vFolioObj.GuestGroup), vFolioObj.GuestGroup.Code, 0);
		vFolioItem.Customer = TrimAll(vFolioObj.Customer);
		vFolioItem.PaymentMethod = ?(ValueIsFilled(vFolioObj.PaymentMethod), vFolioObj.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage), "");
		vFolioItem.FolioCurrency = TrimAll(vFolioObj.FolioCurrency.Code);
		vFolioItem.CreditLimit = vFolioObj.CreditLimit;
		vFolioItem.Client = ?(ValueIsFilled(vFolioObj.Client), TrimAll(vFolioObj.Client.FullName), "");
		vFolioItem.ClientCode = ?(ValueIsFilled(vFolioObj.Client), TrimAll(vFolioObj.Client.Code), "");
		vFolioItem.CustomerCode = ?(ValueIsFilled(vFolioObj.Customer), TrimAll(vFolioObj.Customer.Code), "");
		vFolioItem.Discount = ?(ValueIsFilled(vFolioObj.FolioDiscountType), vFolioObj.FolioDiscountType.GetObject().pmGetDiscount(, , vFolioObj.Hotel), 0);
		vFolioItem.DiscountType = ?(ValueIsFilled(vFolioObj.FolioDiscountType), TrimAll(vFolioObj.FolioDiscountType.Description), "");
		vFolioItem.DiscountCard = ?(ValueIsFilled(vFolioObj.FolioDiscountCard), TrimAll(vFolioObj.FolioDiscountCard.Identifier), "");
		
		// Get folio transactions
		vFolioTransactionsList = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "FolioTransactionsList"));
		
		vTrans = vFolioObj.pmGetAllFolioTransactions();
		For Each vTransRow In vTrans Do
			If vTransRow.RecordType = AccumulationRecordType.Receipt And vTransRow.Sum = 0 Then
				Continue;
			ElsIf vTransRow.RecordType = AccumulationRecordType.Expense And vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
				Continue;
			EndIf;
				
			vFolioTransactionItem = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "FolioTransactionItem"));
			
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.PaymentMethod = Catalogs.PaymentMethods.Settlement Then
					vFolioTransactionItem.Type = "Settlement";
				ElsIf vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Type = "Preauthorization";
				ElsIf TypeOf(vTransRow.Document) = Type("DocumentRef.DepositTransfer") Then
					vFolioTransactionItem.Type = "DepositTransfer";
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Return";
				Else
					vFolioTransactionItem.Type = "Payment";
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Type = "Storno";
				Else
					vFolioTransactionItem.Type = "Charge";
				EndIf;
			EndIf;
			vFolioTransactionItem.Date = vTransRow.Period;
			vFolioTransactionItem.Description = "";
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.Limit <> 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Preauthorization - '; ru='Преавторизация - '; de='Preauthorization - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				ElsIf vFolioTransactionItem.Type = "DepositTransfer" Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Money transfer'; ru='Перенос денег'; de='Geldtransfer'", vLanguage);
				ElsIf vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Return - '; ru='Возврат - '; de='Rückzahlung - '", vLanguage);
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				Else
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.PaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = 0;
				vFolioTransactionItem.Unit = "";
				vFolioTransactionItem.Price = 0;
				vFolioTransactionItem.Discount = 0;
				vFolioTransactionItem.DiscountSum = 0;
				vFolioTransactionItem.Sum = ?(vTransRow.Limit <> 0, -vTransRow.Limit, -vTransRow.Sum);
				If vFolioTransactionItem.Type <> "DepositTransfer" Then
					vFolioTransactionItem.Details = ?(vTransRow.PaymentSum <> 0, ?(Not IsBlankString(vTransRow.Document.SlipText), TrimAll(vTransRow.Document.SlipText), ""), "");
				EndIf;
			Else
				If vTransRow.Sum < 0 Then
					vFolioTransactionItem.Description = vFolioTransactionItem.Description + cmNStr("en='Cancel - '; ru='Отмена - '; de='Storno - '", vLanguage);
				EndIf;
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + vTransRow.Service.GetObject().pmGetServiceDescription(vLanguage);
				vFolioTransactionItem.Description = vFolioTransactionItem.Description + ?(IsBlankString(vTransRow.Remarks), "", " - " + TrimAll(vTransRow.Remarks));
				vFolioTransactionItem.Quantity = vTransRow.Quantity;
				vFolioTransactionItem.Unit = vTransRow.Service.GetObject().pmGetServiceUnitDescription(vLanguage);
				vFolioTransactionItem.Price = vTransRow.Price;
				vFolioTransactionItem.Discount = ?(ValueIsFilled(vTransRow.Charge), vTransRow.Charge.Discount, 0);
				vFolioTransactionItem.DiscountSum = vTransRow.Discount;
				vFolioTransactionItem.Sum = vTransRow.Sum;
				vFolioTransactionItem.Details = ?(ValueIsFilled(vTransRow.Charge), TrimAll(vTransRow.Charge.Details), "");
			EndIf;
			
			vFolioTransactionsList.FolioTransactionItem.Add(vFolioTransactionItem);
			
			If vTransRow.RecordType = AccumulationRecordType.Expense Then
				If vTransRow.Limit <> 0 Then
					vFolioBalance = vFolioBalance - vTransRow.Limit;
				Else
					vFolioBalance = vFolioBalance - vTransRow.Sum;
				EndIf;
			Else
				vFolioBalance = vFolioBalance + vTransRow.Sum;
			EndIf;
		EndDo;
		
		vFolioItem.FolioBalance = vFolioBalance;
		
		vFolioBalanceInRepCur = cmConvertCurrencies(vFolioBalance, vFolioObj.FolioCurrency, , vCurrency, , vExchangeRateDate, vAccRef.Hotel);
		vFolioCreditLimitInRepCur = cmConvertCurrencies(vFolioObj.CreditLimit, vFolioObj.FolioCurrency, , vCurrency, , vExchangeRateDate, vAccRef.Hotel);
		
		vClientBalance = vClientBalance + vFolioBalanceInRepCur;
		vCreditLimit = vCreditLimit + vFolioCreditLimitInRepCur;
		
		// Add folio to the folios list
		vGuestFolioItem.FolioItem = vFolioItem;
		vGuestFolioItem.FolioTransactionsList = vFolioTransactionsList;
		vGuestFoliosList.GuestFolioItem.Add(vGuestFolioItem);
	EndDo;
		
	vOrdersXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrdersDetailed"));
	If ValueIsFilled(vAccRef) Then
		Query = New Query;
		qText = 
		"SELECT
		|	Order.Number AS Number,
		|	Order.Type AS Type,
		|	Order.Quantity AS Quantity,
		|	Order.GuestsQuantity AS GuestsQuantity,
		|	Order.Sum AS Sum,
		|	Order.OrderTime AS OrderTime,
		|	Order.Items.(
		|		Ref AS Ref,
		|		LineNumber AS LineNumber,
		|		Item AS Item,
		|		Quantity AS Quantity,
		|		Price AS Price,
		|		Sum AS Sum
		|	) AS Items,
		|	Order.Hotel AS Hotel,
		|	Order.Status AS Status,
		|	Order.Service AS Service,
		|	Order.Currency AS Currency,
		|	Order.Remarks AS Remarks,
		|	Order.Department AS Department,
		|	Order.PickupFrom AS PickupFrom,
		|	Order.Destination AS Destination,
		|	Order.ChildSeatsNumber AS ChildSeatsNumber,
		|	Order.TransferType AS TransferType
		|FROM
		|	Document.Order AS Order
		|WHERE
		|	NOT Order.DeletionMark";
		If TypeOf(vAccRef) = Type("DocumentRef.Folio") Then		
			qText= qText+"
			|	AND Order.Folio = &ParentDoc";
		Else
			qText= qText+"
			|	AND Order.ParentDoc = &ParentDoc";
		EndIf;
		qText= qText+"
		|	AND NOT Order.Status.isOrderComplete
		|	AND NOT Order.Status.isOrderCancel";
		Query.Text = qText;
		Query.SetParameter("ParentDoc",vAccRef);
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		vQuery = New Query;
		vQuery.Text = 
			"SELECT
			|	ExternalSystemsObjectCodesMappings.ObjectTypeName AS ObjectTypeName,
			|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
			|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
			|FROM
			|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
			|WHERE
			|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
			|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode";
		
		vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);
		vQuery.SetParameter("qHotel", vHotel);
		
		vMappings = vQuery.Execute().Unload();

		While SelectionDetailRecords.Next() Do
			vOrderXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
			vOrderXDTO.OrderID        	= SelectionDetailRecords.Number;
			vOrderXDTO.OrderDate      	= SelectionDetailRecords.OrderTime;
			vOrderXDTO.Hotel      	 	= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Hotel, 	"Hotels");
			vOrderXDTO.OrderType    	= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Type, 	"OrderTypes");			
			vOrderXDTO.OrderStatus    	= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Status, 	"OrderStatuses");
			
			// Fill order type statuses (to display progress)
			If ValueIsFilled(SelectionDetailRecords.Status) Then
				vCurrentStatusXDTO			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
				vCurrentStatusXDTO.StatusSortCode    = SelectionDetailRecords.Status.SortCode;
				vCurrentStatusXDTO.StatusDescription = SelectionDetailRecords.Status.Description;
				vOrderXDTO.CurrentStatus 	= vCurrentStatusXDTO;
			Else
				vOrderXDTO.CurrentStatus 	= Undefined;
			EndIf;
			If ValueIsFilled(SelectionDetailRecords.Type) Then
				vStatusesListXDTO			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "StatusesList"));
				For Each vOrderTypeStatus In SelectionDetailRecords.Type.StatusesCourse Do
					vOrderStatusXDTO			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
					vOrderStatusXDTO.StatusSortCode    = vOrderTypeStatus.Status.SortCode;
					vOrderStatusXDTO.StatusDescription = vOrderTypeStatus.Status.Description;
					vStatusesListXDTO.OrderStatus.Add(vOrderStatusXDTO);	
				EndDo;
				vOrderXDTO.StatusesList 	= vStatusesListXDTO;
			Else
				vOrderXDTO.StatusesList 	= Undefined;
			EndIf;
			
			vOrderXDTO.Service    		= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Service, "Services");			
			vOrderXDTO.Sum            	= SelectionDetailRecords.Sum;
			vOrderXDTO.Quantity       	= SelectionDetailRecords.Quantity;
			vOrderXDTO.Currency    		= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Currency, "Currencies", "Code");
			vOrderXDTO.Remarks    		= SelectionDetailRecords.Remarks;
			vOrderXDTO.Department    	= GetRefMappingFromTable(vMappings, SelectionDetailRecords.Department, "Departments");;               		
			vOrderXDTO.GuestsQuantity 	= SelectionDetailRecords.GuestsQuantity;			
			
			vTransferXDTO					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Transfer"));
			vTransferXDTO.PickupFrom		= SelectionDetailRecords.PickupFrom;
			vTransferXDTO.Destination		= SelectionDetailRecords.Destination;
			vTransferXDTO.PassengersNumber	= SelectionDetailRecords.GuestsQuantity;
			vTransferXDTO.ChildSeatsNumber	= SelectionDetailRecords.ChildSeatsNumber;
			vTransferXDTO.CarType			= GetRefMappingFromTable(vMappings, SelectionDetailRecords.TransferType, "TransferTypes");   
			
			vOrderXDTO.Transfer    		= vTransferXDTO;
						
			vOrderItemsXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
			vOrderItems = SelectionDetailRecords.Items.Select();
			While vOrderItems.Next() Do
				vOrderItemXDTO 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
				vOrderItemXDTO.ItemName = vOrderItems.Item.Description;
				vOrderItemXDTO.ItemId 	= vOrderItems.Item.Code;
				vOrderItemXDTO.Quantity = vOrderItems.Quantity;
				vOrderItemXDTO.Price 	= vOrderItems.Price;
				vOrderItemXDTO.Sum 		= vOrderItems.Sum;
				vOrderItemsXDTO.OrderItem.Add(vOrderItemXDTO);	
			EndDo;
			vOrderXDTO.OrderItems = vOrderItemsXDTO;
			vOrdersXDTO.OrderDetails.Add(vOrderXDTO);			
		EndDo;		
	EndIf;
	vRetXDTO.Orders = vOrdersXDTO;
	
	// Fill balances
	vGuestItem.ClientBalance = vClientBalance;
	vGuestItem.CreditLimit = vCreditLimit;
	
	vRetXDTO.GuestItem = vGuestItem;
	vRetXDTO.GuestFoliosList = vGuestFoliosList;
	
	If ValueIsFilled(vHotel) Then
		vEventsRatingsXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "EventsRatings"));
		vEventsRatings 		= GetEventsRatingsByMyFolioUUID(pGuestUUID, vHotel);
		For each vEvent in vEventsRatings Do
			vEventXDTO 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Event"));
			vEventXDTO.Date 		= vEvent.Period;
			vEventXDTO.CalendarId 	= vEvent.CalendarId; 
			vEventXDTO.EventId 		= vEvent.EventId; 
			vEventXDTO.Rating 		= vEvent.Rating; 
			vEventsRatingsXDTO.Events.Add(vEventXDTO);
		EndDo;
		vRetXDTO.EventsRatings = vEventsRatingsXDTO;
	EndIf;
	
	vServicesDiscountXDTO 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServicesDiscount"));
	vDiscountType = vGuest.DiscountType;
	If Not ValueIsFilled(vDiscountType) AND ValueIsFilled(vGuest.ClientType) Then
		vDiscountType = vGuest.ClientType.DiscountType;
	EndIf;
	If ValueIsFilled(vDiscountType) Then
		vServicesDiscount 	= GetServicesDiscount(pExternalSystemCode, vDiscountType, vHotel);
		For each vDiscount in vServicesDiscount Do
			vServiceDiscountRow 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServiceDiscountRow"));
			vServiceDiscountRow.ServiceGroup	= vDiscount.ObjectExternalCode;
			vServiceDiscountRow.Discount		= vDiscount.Discount;
			vServicesDiscountXDTO.ServiceDiscountRow.Add(vServiceDiscountRow);
		EndDo;		
	EndIf;
	vRetXDTO.ServicesDiscount = vServicesDiscountXDTO;
	Return vRetXDTO;
EndFunction // GetGuestFoliosWithTransactions

// -----------------------------------------------------------------------------
Function GetGuestMedSchedule(pExternalSystemCode, pHotel, pGuestUUID, pDate)
	WriteLogEvent(NStr("en = 'Get guest med schedule'; ru = 'Получить расписание медицинских назначений'; de = 'ärztlichen Zeitplan'"), EventLogLevel.Information, , , 
	NStr("en = 'External system code: '; ru = 'Код внешней системы: '; de = 'External system code: '") + pExternalSystemCode + Chars.LF +
	NStr("en='Date: '; de='Date: '; ru='Дата: '") + pDate + Chars.LF +
	NStr("en='Hotel: '; de='Hotel: '; ru='Гостиница: '") + pHotel + Chars.LF +
	NStr("en='Guest UUID: '; de='Gast UUID: '; ru='UUID гостя: '") + pGuestUUID);
	
	
	vMedScheduleXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestMedSchedule"));
	vGuest = GetGuestByMyFolioUUID(pGuestUUID);
	If ValueIsFilled(vGuest) Then
		vHotel = cmGetHotelByCode(pHotel, pExternalSystemCode);
		If ValueIsFilled(vHotel) and ValueIsFilled(vHotel.MedicineWSDL) Then
			Try
				vWSDefine 	= New WSDefinitions(vHotel.MedicineWSDL);
				vWSProxy 	= New WSProxy(vWSDefine,"http://www.1chotel.ru/ws/interfaces/medicine/","HotelInterfaces","HotelInterfacesSoap");
				
				vMedHotelCode = cmGetObjectExternalSystemCodeByRef(vHotel,"1CMEDICINE","Hotels",vHotel);
				vXDTOResult = vWSProxy.GetServicesGuest(vGuest.Code, vMedHotelCode, pDate);
			Except
				vError = ErrorDescription();
				WriteLogEvent(NStr("en = 'Get guest med schedule'; ru = 'Получить расписание медицинских назначений'; de = 'ärztlichen Zeitplan'"), EventLogLevel.Error,,, vError);
			EndTry;
			Try
				For each vRow in vXDTOResult.Services.ServicesItemRow Do
					vMedServiceXDTO 				= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "MedService"));
					vMedServiceXDTO.id 				= vRow.UID;
					vMedServiceXDTO.Service 		= vRow.Description; 
					vMedServiceXDTO.Remarks 		= vRow.Remarks; 
					vMedServiceXDTO.MedicalOffice 	= vRow.MedicalOffice; 
					vMedServiceXDTO.Physician 		= vRow.Physician; 
					vMedServiceXDTO.PlanningDate 	= vRow.PlanningDate; 
					vMedScheduleXDTO.MedService.Add(vMedServiceXDTO);
				EndDo;
			Except
				vError = ErrorDescription();
				WriteLogEvent(NStr("en = 'Get guest med schedule'; ru = 'Получить расписание медицинских назначений'; de = 'ärztlichen Zeitplan'"), EventLogLevel.Error,,, vError);	
			EndTry;	
		EndIf;
	Else
		WriteLogEvent(NStr("en = 'Get guest med schedule'; ru = 'Получить расписание медицинских назначений'; de = 'ärztlichen Zeitplan'"), EventLogLevel.Error,,, "Failed to find guest by UUID");
	EndIf;
	
	Return vMedScheduleXDTO; 
EndFunction // GetGuestMedSchedule

// -----------------------------------------------------------------------------
Function GetHotelGuests(pGuest, pRoom, pHotel)
	Return cmGetHotelGuestsList(pGuest, pRoom, pHotel, "XDTO");
EndFunction // GetHotelGuests

// -----------------------------------------------------------------------------
Function GetReservationsList(pGuest, pRoom, pHotel)
	Return cmGetReservationsList(pGuest, pRoom, pHotel, "XDTO");
EndFunction // GetReservationsList

// -----------------------------------------------------------------------------
Function GetOpenShiftOrders(pPOSCode, pHotelCode, pExternalSystemCode)
	WriteLogEvent(NStr("en='Get open POS shift orders'; de='Get open POS shift orders'; ru='Получить список заказов открытой смены POS системы'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel code: '; de='Hotel code: '; ru='Код гостиницы: '") + pHotelCode + Chars.LF + 
	              NStr("en='POS code: '; de='POS code: '; ru='Код POS: '") + pPOSCode);
	// Try to find hotel by name or code
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	
	// Try to find cash register by code
	vCashRegister = Undefined;
	If Not IsBlankString(pPOSCode) Then
		vCashRegister = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "CashRegisters", pPOSCode);
	EndIf;
	If Not ValueIsFilled(vCashRegister) Then
		Raise NStr("en='Failed to get POS cash register by code!'; ru='Ошибка получения ККМ по коду POS системы!'; de='Fehler beim Abrufen der POS-Kasse per Code!'");
	EndIf;
	
	// Try to get time of close of last POS shift
	vOpenShiftStartTime = BegOfDay(CurrentSessionDate());
	If ValueIsFilled(vHotel) And ValueIsFilled(vHotel.AccountingDate) Then
		vOpenShiftStartTime = BegOfDay(vHotel.AccountingDate);
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT TOP 1
	|	CloseOfCashRegisterDays.Date AS Date
	|FROM
	|	Document.CloseOfCashRegisterDay AS CloseOfCashRegisterDays
	|WHERE
	|	CloseOfCashRegisterDays.CashRegister = &qCashRegister
	|	AND CloseOfCashRegisterDays.Posted
	|
	|ORDER BY
	|	Date DESC";
	vQry.SetParameter("qCashRegister", vCashRegister);
	vDocs = vQry.Execute().Unload();
	For Each vDocsRow In vDocs Do
		If vDocsRow.Date <> NULL And ValueIsFilled(vDocsRow.Date) Then
			vOpenShiftStartTime = vDocsRow.Date;
		EndIf;
		Break;
	EndDo;
		
	// Build list of orders later then end of last POS shift
	vOrdersXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Orders"));				
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalOrderCodes.ExternalOrderCode AS ID,
	|	Orders.Number AS Number,
	|	Orders.Type AS Type,
	|	Orders.Quantity AS Quantity,
	|	Orders.GuestsQuantity AS GuestsQuantity,
	|	Orders.Sum AS Sum,
	|	Orders.OrderTime AS OrderTime,
	|	Orders.Status AS Status,
	|	ISNULL(Orders.Client.FullName, """") AS FullName,
	|	ISNULL(Orders.Client.Code, """") AS Code
	|FROM
	|	Document.Order AS Orders
	|		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
	|		ON (ExternalOrderCodes.Order = Orders.Ref)
	|			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
	|WHERE
	|	Orders.CashRegister = &qCashRegister
	|	AND Orders.Date > &qPeriodFrom
	|	AND Orders.Posted
	|	AND NOT ExternalOrderCodes.ExternalOrderCode IS NULL";
	vQry.SetParameter("qCashRegister", vCashRegister);
	vQry.SetParameter("qPeriodFrom", vOpenShiftStartTime);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);
	
	vQryRecords = vQry.Execute().Select();
	While vQryRecords.Next() Do
		vOrderXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Order"));
		vOrderXDTO.id = vQryRecords.ID;
		vOrderXDTO.Description = String(vQryRecords.Type);
		vOrderXDTO.ClientId = vQryRecords.Code;
		vOrderXDTO.GuestsQuantity = vQryRecords.GuestsQuantity;
		vOrderXDTO.OrderDate = vQryRecords.OrderTime;
		vOrderXDTO.Quantity = vQryRecords.Quantity;
		vOrderXDTO.Sum = vQryRecords.Sum;
		vOrderXDTO.ClientName = vQryRecords.FullName;
		vOrderXDTO.Orderstatus = String(vQryRecords.Status);
		
		vOrdersXDTO.Order.Add(vOrderXDTO);
	EndDo;
	
	Return vOrdersXDTO;
EndFunction // GetOpenShiftOrders

// -----------------------------------------------------------------------------
Function GetServiceItemByFolio(pFolioNumber)
	vServiceItemsType 		= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServiceItems");
	vServiceItemRowType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServiceItemRow");
	vServiceItemListType 	= XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ServiceItemList");
	
	vRetXDTO 			= 	XDTOFactory.Create(vServiceItemListType);
	
	vRetXDTO.ServiceItems   	= XDTOFactory.Create(vServiceItemsType);
	vRetXDTO.ErrorDescription 	= "";
	
	Try
		
		// Get hotel
		vHotel = SessionParameters.CurrentHotel;
		
		// Get folio reference by folio number
		vFolioNumber = cmGetDocumentNumberFromPresentation(pFolioNumber, vHotel);
		vFolio = Documents.Folio.FindByNumber(vFolioNumber);
		If Not ValueIsFilled(vFolio) Then
			WriteLogEvent(NStr("en='Get external service by folio'; de='Get external service by folio'; ru='Получение позиций меню из внешней системы по лицевому счету'"), EventLogLevel.Warning, , , 
			              NStr("en='Folio was not found!';ru='Фолио не найдено по номеру!';de='Folio wurde nach der Nummer nicht gefunden!'")+" "+pFolioNumber);
			vError = NStr("en='Folio was not found: '; de='Folio was not found: '; ru='Фолио не найдено по номеру: '")+pFolioNumber;
			
			Return vRetXDTO.ErrorDescription = vError;
		EndIf;
		
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Services.Service.Description AS ServiceDescription,
		|	Services.AccountingDate AS AccountingDate,
		|	ServiceItems.ServiceId,
		|	ServiceItems.Quantity,
		|	ServiceItems.ServiceItem.ExternalCode AS ServiceItemCode,
		|	ServiceItems.Price
		|FROM
		|	Document.ResourceReservation.ServiceItems AS ServiceItems
		|		LEFT JOIN Document.ResourceReservation.Services AS Services
		|		ON ServiceItems.ServiceId = Services.ServiceId
		|			AND ServiceItems.Ref.ChargingFolio = Services.Ref.ChargingFolio
		|WHERE
		|	ServiceItems.Ref.ChargingFolio = &qFolio
		|	AND NOT ServiceItems.ServiceItem.ExternalCode IS NULL";
		
		vQry.SetParameter("qFolio", vFolio);
		vTableServiceItems = vQry.Execute().Unload();
		If  vTableServiceItems.Count() = 0 Then  
			Return vRetXDTO.ErrorDescription = "";
		EndIf;
		
		For Each mRow In vTableServiceItems Do
			vServiceItemRow = XDTOFactory.Create(vServiceItemRowType);
			
			vServiceItemRow.ServiceId			=  mRow.ServiceId;
			vServiceItemRow.ServiceItemCode     =  mRow.ServiceItemCode;
			vServiceItemRow.Price               =  mRow.Price;
			vServiceItemRow.Quantity            =  mRow.Quantity;
			vServiceItemRow.ServiceDescription  =  mRow.ServiceDescription;
			vServiceItemRow.AccountingDate      =  mRow.AccountingDate;
			
			vRetXDTO.ServiceItems.ServiceItemRow.Add(vServiceItemRow);
		EndDo;
		
		Return vRetXDTO;	
		
	Except
		vError = ErrorDescription();
		Return vRetXDTO.ErrorDescription = vError;
	EndTry;

EndFunction // GetServiceItemByFolio

// -----------------------------------------------------------------------------
Function PayByCertificate(CertificateNumber, Sum, Remarks, Details, ExternalSystemCode, Hotel, Currency, VatRate)
	Return cmPayByCertificate(CertificateNumber, Sum, Remarks, Details, ExternalSystemCode, Hotel, Currency, VatRate);
EndFunction // PayByCertificate

// -----------------------------------------------------------------------------
Function PayByDiscountCard(pCardNumber, pSum, pRemarks, pExternalCode, pExternalSystemCode, pHotel, pSource = "")
	Return cmPayByDiscountCard(pCardNumber, pSum, pRemarks, pExternalCode, pExternalSystemCode, pHotel, pSource);	
EndFunction // PayByDiscountCard

// -----------------------------------------------------------------------------
Function WriteGuestPayment(pPayerName, pCard, pFolioNumber, pRoom, pPaymentMethod, pCurrency, pSum, pExternalSystemCode, 
                           pPaymentExternalCode, pRemarks, pHotel = "")
	Return cmWritePaymentExternalFOSystem(pHotel,pPayerName, CurrentSessionDate(), pExternalSystemCode, 
								pCard, pFolioNumber, pRoom, pPaymentMethod, pCurrency, pSum, pRemarks,  
								pPaymentExternalCode, "XDTO");
EndFunction // WriteGuestPayment

// -----------------------------------------------------------------------------
Function WriteGuestPaymentExt(pPayerName, pCard, pFolioNumber, pRoom, pPaymentMethod, pCurrency, pSum, pExternalSystemCode, 
                              pPaymentExternalCode, pRemarks, pHotel = "", pPOSCode = "", pPaymentSectionCode = "", 
						      pReferenceNumber = "", pAuthorizationCode = "", pExternalPaymentData = Undefined)
	vPaymentDate = CurrentSessionDate();
	If pExternalPaymentData <> Undefined Then
		If ValueIsFilled(pExternalPaymentData.Date) Then
			vPaymentDate = pExternalPaymentData.Date;
		EndIf;
	EndIf;
	Return cmWritePaymentExternalFOSystem(pHotel, pPayerName, vPaymentDate, pExternalSystemCode, 
								pCard, pFolioNumber, pRoom, pPaymentMethod, pCurrency, pSum, pRemarks,  
								pPaymentExternalCode, "XDTO", pPaymentSectionCode, pPOSCode);
EndFunction // WriteGuestPaymentExt

// -----------------------------------------------------------------------------
Function WritePOSOrder(pClient, pOrder, pSource)
	Return cmWritePOSOrder(pClient, pOrder, pSource);
EndFunction // WritePOSOrder

// -----------------------------------------------------------------------------
Function ZPOS(pPOSCode, pDateTime, pSum, pCurrency, pHotel, pExternalSystemCode)
	vDateTime = ?(ValueIsFilled(pDateTime), pDateTime, CurrentSessionDate());
	Return cmZPOS(pPOSCode, vDateTime, pSum, pCurrency, pHotel, pExternalSystemCode);
EndFunction // ZPOS

// -----------------------------------------------------------------------------
Function GetFoliosForDirectPostings(pHotelCode, pExternalSystemCode, pPOSCode)
	WriteLogEvent(NStr("en='Get folios for direct postings'; de='Get folios for direct postings'; ru='Получить список лицевых счетов для прямых начислений'"), EventLogLevel.Information, , , 
	              NStr("en='External system code: '; de='External system code: '; ru='Код внешней системы: '") + pExternalSystemCode + Chars.LF + 
	              NStr("en='Hotel code: '; de='Hotel code: '; ru='Код гостиницы: '") + pHotelCode + Chars.LF + 
	              NStr("en='POS code: '; de='POS code: '; ru='Код POS: '") + pPOSCode);
	// Try to find hotel by name or code
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	// Try to find cash register by code
	vCashRegister = Undefined;
	If Not IsBlankString(pPOSCode) Then
		vCashRegister = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "CashRegisters", pPOSCode);
	EndIf;
	
	// Call API to get folios list
	vFolios = cmGetExternalPOSFolios(vHotel, ?(ValueIsFilled(vCashRegister), vCashRegister.Owner, Undefined), Undefined, Undefined);
	
	// Create return XDTO object
	vRetXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Folios"));
	
	// Do for each folio document in the list
	For Each vFoliosItem In vFolios Do
		vFolio = vFoliosItem.Value;
		
		// Get folio balance
		vLimit = 0;
		vFolioBalance = vFolio.GetObject().pmGetBalance( , , , vLimit);
		vFolioBalance = vFolioBalance + vLimit;
		
		// Get discount data
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
		If ValueIsFilled(vFolio.FolioDiscountCard) Then
			vDiscountCard = vFolio.FolioDiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			If ValueIsFilled(vDiscountType) Then
				vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
			EndIf;
		ElsIf ValueIsFilled(vFolio.FolioDiscountType) Then
			vDiscountType = vFolio.FolioDiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		ElsIf ValueIsFilled(vFolio.ParentDoc) And 
			(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
			vDiscountCard = vFolio.ParentDoc.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vFolio.ParentDoc.Discount;
		ElsIf ValueIsFilled(vFolio.ParentDoc) And 
			(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
			ValueIsFilled(vFolio.ParentDoc.DiscountType) Then
			vDiscountType = vFolio.ParentDoc.DiscountType;
			vDiscount = vFolio.ParentDoc.Discount;
		ElsIf ValueIsFilled(vFolio.Client) Then
			If ValueIsFilled(vFolio.Client.DiscountType) Then
				vDiscountType = vFolio.Client.DiscountType;
				vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
			Else
				vDiscountCard = cmGetDiscountCardByClient(vFolio.Client);
				If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
					vDiscountType = vDiscountCard.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		vCreditLimit = vFolio.CreditLimit;
		If vFolio.IsClosed Then
			vCreditLimit = 0;
		Else
			If ValueIsFilled(vHotel) And vHotel.NoCreditLimit Then
				vCreditLimit = 999999999;
			EndIf;
		EndIf;
		
		// Add client bonuses
		If ValueIsFilled(vFolio.Client) Then
			vDocDiscountCard = Undefined;
			If ValueIsFilled(vFolio.ParentDoc) And 
				(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) And 
				ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
				vDocDiscountCard = vFolio.ParentDoc.DiscountCard;
			EndIf;
			vClientObj = vFolio.Client.GetObject();
			vBonus = 0;
			vBonusAmount = vClientObj.pmGetBonusesAmount(vFolio.Hotel, vFolio.FolioCurrency, vDocDiscountCard, vBonus);
			If vCreditLimit < 999999999 Then
				vCreditLimit = vCreditLimit + vBonusAmount;
			EndIf;
		EndIf;
		
		vFolioXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Folio"));
		
		// Fill attributes
		vFolioXDTO.FolioNumber = TrimAll(vFolio.Number);
		vFolioXDTO.FolioDescription = Left(TrimAll(vFolio.Description), 4096);
		vFolioXDTO.Hotel = TrimAll(vHotel.Code);
		vFolioXDTO.Room = TrimAll(vFolio.Room);
		vFolioXDTO.CheckInDate = vFolio.DateTimeFrom;
		vFolioXDTO.CheckOutDate = vFolio.DateTimeTo;
		vFolioXDTO.GuestGroup = ?(ValueIsFilled(vFolio.GuestGroup), vFolio.GuestGroup.Code, 0);
		vFolioXDTO.Customer = TrimAll(vFolio.Customer);
		vFolioXDTO.PaymentMethod = TrimAll(vFolio.PaymentMethod);
		vFolioXDTO.FolioBalance = vFolioBalance;
		vFolioXDTO.FolioCurrency = TrimAll(vFolio.FolioCurrency.Code);
		vFolioXDTO.CreditLimit = vCreditLimit;
		vFolioXDTO.Client = ?(ValueIsFilled(vFolio.Client), TrimAll(vFolio.Client.FullName), "");
		vFolioXDTO.ClientCode = ?(ValueIsFilled(vFolio.Client), TrimAll(vFolio.Client.Code), "");
		vFolioXDTO.CustomerCode = ?(ValueIsFilled(vFolio.Customer), TrimAll(vFolio.Customer.Code), "");
		vFolioXDTO.Discount = vDiscount;
		vFolioXDTO.DiscountType = ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
		vFolioXDTO.DiscountCard = ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
		vFolioXDTO.IsForExternalPOS = vFolio.IsForExternalPOS;
		vFolioXDTO.IsForDirectPostings = vFolio.IsForDirectPostings;
		vFolioXDTO.IsComplimentary = vFolio.IsComplimentary;
		vFolioXDTO.IsHouseUse = vFolio.IsHouseUse;
		
		// Add object to the collection
		vRetXDTO.Folio.Add(vFolioXDTO);	
	EndDo;
	
	// Return object
	Return vRetXDTO;
EndFunction // GetFoliosForDirectPostings

// -----------------------------------------------------------------------------
Function ActivateGiftCertificate(pCertificateNumber, pAmount, pRemarks, pCurrency, pVatRate, pHotel, pExternalCode, pExternalSystemCode)
	Return cmActivateGiftCertificate(pCertificateNumber, pAmount, pRemarks, pCurrency, pVatRate, pHotel, pExternalCode, pExternalSystemCode);
EndFunction // ActivateGiftCertificate

// -----------------------------------------------------------------------------
Function IssueDiscountCard(pCard, pSource, pHotel, pRemarks)
	Return cmIssueDiscountCardExt(pCard, pSource, pHotel, pRemarks);
EndFunction // IssueDiscountCard

// -----------------------------------------------------------------------------
Function GetHotelGuestsExt(pClient, pHotel, pExternalSystemCode)
	   Return cmGetHotelGuestsListExt(pClient, pHotel, pExternalSystemCode);
EndFunction // GetHotelGuestsExt

// --------------------------------------------------------------------------------------------------
Function GetOrders(pClientId, pRoom, pFolioNumber, pHotelCode, pExternalSystemCode, pStatus)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;

	vWriteDebug = False;
	If Not IsBlankString(pExternalSystemCode) Then
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pExternalSystemCode, vHotel);
		If ValueIsFilled(vInteraction) Then
			vWriteDebug = vInteraction.DebugMode;
		EndIf;	
	EndIf;
	vInputParameters = New Structure;
	vInputParameters.Insert("ClientId", pClientId);
	vInputParameters.Insert("Room", pRoom);
	vInputParameters.Insert("FolioNumber", pFolioNumber);
	vInputParameters.Insert("HotelCode", pHotelCode);
	vInputParameters.Insert("ExternalSystemCode", pExternalSystemCode);
	vInputParameters.Insert("Status", pStatus);
	vExtraXML = Catalogs.DataConvertationRules.MapToJSON(vInputParameters);
	
	vFuncLog = NStr("en = 'Get orders'; de = 'Get orders'; ru = 'Получить список заказов'");
	If vWriteDebug Then
		vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vExtraXML, , vMsg);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
	EndIf;
	
	// Order status
	vOrderStatus = cmGetObjectRefByExternalSystemCode(vHotel, pExternalSystemCode, "OrderStatuses", TrimAll(pStatus));
	If Not ValueIsFilled(vOrderStatus) Then
		vOrderStatus = Catalogs.OrderStatuses.EmptyRef();
	EndIf;

	// Get room by room code
	vRoom = Catalogs.Rooms.EmptyRef();
	If Not IsBlankString(pRoom) Then
		vRoom = cmGetRoomByCode(pRoom, pHotelCode, pExternalSystemCode);
	EndIf;

	vOrdersXDTO = Undefined;
	Try
		If ValueIsFilled(pClientId) Then
			vOrdersXDTO = GetOrdersByClientId(pClientId, vHotel, vOrderStatus, pExternalSystemCode);
		ElsIf ValueIsFilled(vRoom) Then
			vOrdersXDTO = GetOrdersByRoom(vRoom, vHotel, vOrderStatus, pExternalSystemCode);
		ElsIf ValueIsFilled(pFolioNumber) Then
			vOrdersXDTO = GetOrdersByFolioNumber(pFolioNumber, vHotel, vOrderStatus, pExternalSystemCode);
		ElsIf ValueIsFilled(vOrderStatus) Then	
			vOrdersXDTO = GetAllOrdersByStatus(vHotel, vOrderStatus, pExternalSystemCode);
		EndIf
	Except
		vErr = ErrorDescription();
		If ValueIsFilled(vInteraction) Then
			vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Error, vErr, , vMsg);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Error, , , vErr);
		EndIf;
	EndTry;
	// Write log output parameters
	If Not vOrdersXDTO = Undefined Then
		vExtraXML = cmGetXMLStringFromXDTO(vOrdersXDTO);
		If vWriteDebug Then
			vMsg =  NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, , vExtraXML, vMsg);
		Else
			WriteLogEvent(vFuncLog, EventLogLevel.Information, , , vExtraXML);
		EndIf;
	EndIf;	
	Return vOrdersXDTO
EndFunction // GetOrders

// --------------------------------------------------------------------------------------------------
Function GetGroupGuestsList(pGuestGroupCode, pHotelCode, pExternalSystemCode)
	vHotel = Undefined;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pExternalSystemCode);
	EndIf;
	If Not ValueIsFilled(vHotel) Then
		vHotel = SessionParameters.CurrentHotel;
	EndIf;
	
	vGuestGroup = Catalogs.GuestGroups.FindByCode(pGuestGroupCode, False, , vHotel);
	If Not ValueIsFilled(vGuestGroup) Then
		Raise NStr("en='Group was not found by code '; ru='Группа не найдена по коду '; de='Gruppe nicht vom Code gefunden '") + Format(pGuestGroupCode, "NFD=0; NG=") + ", " + TrimAll(vHotel);
	EndIf;
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.Number AS Number,
	|	Reservations.Hotel AS Hotel,
	|	Reservations.GuestFullName AS GuestFullName,
	|	Reservations.Guest AS Guest,
	|	Reservations.ClientType AS ClientType,
	|	Reservations.Discount AS Discount,
	|	Reservations.DiscountCard AS DiscountCard,
	|	Reservations.DiscountType AS DiscountType,
	|	Reservations.CheckInDate AS CheckInDate,
	|	Reservations.Duration AS Duration,
	|	Reservations.CheckOutDate AS CheckOutDate,
	|	Reservations.RoomType AS RoomType,
	|	Reservations.Room AS Room,
	|	Reservations.GuestGroup AS GuestGroup,
	|	Reservations.Customer AS Customer,
	|	Reservations.ReportingCurrency.Code AS ReportingCurrencyCode,
	|	Reservations.PlannedPaymentMethod AS PlannedPaymentMethod,
	|	Reservations.AccommodationType AS AccommodationType,
	|	Reservations.AccommodationType.Type AS AccommodationTypeType,
	|	Reservations.ServicePackage AS ServicePackage,
	|	Reservations.ServicePackage.Code AS ServicePackageCode,
	|	Reservations.ServicePackage.Description AS ServicePackageDescription,
	|	Reservations.RoomRate AS RoomRate,
	|	Reservations.RoomRate.Code AS RoomRateCode,
	|	Reservations.RoomRate.Description AS RoomRateDescription,
	|	Reservations.ReservationStatus AS Status,
	|	Reservations.NoPost AS NoPost
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.GuestGroup = &qGuestGroup
	|	AND Reservations.Hotel = &qHotel
	|	AND (Reservations.ReservationStatus.IsActive
	|			OR Reservations.ReservationStatus.IsPreliminary)
	|	AND NOT Reservations.ReservationStatus.IsCheckIn
	|	AND Reservations.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Accommodations.Ref,
	|	Accommodations.Number,
	|	Accommodations.Hotel,
	|	Accommodations.GuestFullName,
	|	Accommodations.Guest,
	|	Accommodations.ClientType,
	|	Accommodations.Discount,
	|	Accommodations.DiscountCard,
	|	Accommodations.DiscountType,
	|	Accommodations.CheckInDate,
	|	Accommodations.Duration,
	|	Accommodations.CheckOutDate,
	|	Accommodations.RoomType,
	|	Accommodations.Room,
	|	Accommodations.GuestGroup,
	|	Accommodations.Customer,
	|	Accommodations.ReportingCurrency.Code,
	|	Accommodations.PlannedPaymentMethod,
	|	Accommodations.AccommodationType,
	|	Accommodations.AccommodationType.Type,
	|	Accommodations.ServicePackage,
	|	Accommodations.ServicePackage.Code,
	|	Accommodations.ServicePackage.Description,
	|	Accommodations.RoomRate,
	|	Accommodations.RoomRate.Code,
	|	Accommodations.RoomRate.Description,
	|	Accommodations.AccommodationStatus,
	|	Accommodations.NoPost
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.GuestGroup = &qGuestGroup
	|	AND Accommodations.Hotel = &qHotel
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.Posted";
	vQry.SetParameter("qGuestGroup", vGuestGroup);
	vQry.SetParameter("qHotel", vHotel);
	vQryRecords = vQry.Execute().Select();

	vGuestsListXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestsList"));
	vGuestsListXDTO.GuestGroupDescription = TrimAll(vGuestGroup.Description);
	
	vGuestItemsXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItems"));
	While vQryRecords.Next() Do
		vDocRef = vQryRecords.Ref;
		
		vGuestItemXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "GuestItem"));
		vClientProfileXDTO = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "ClientProfile"));

		// Fill guest item
		vGuest = vDocRef.Guest;
		vLanguage = SessionParameters.CurrentLanguage;
		
		vGuestItemXDTO.Guest = TrimAll(vQryRecords.GuestFullName) + ?(ValueIsFilled(vDocRef.DiscountCard), "(DC " + TrimAll(vDocRef.DiscountCard.Identifier) + ")", "");
		If ValueIsFilled(vGuest) Then
			If ValueIsFilled(vGuest.Language) Then
				vLanguage = vGuest.Language;
			EndIf; 
			
 			vGuestItemXDTO.GuestCode = TrimAll(vGuest.Code);
			vGuestItemXDTO.GuestSex = Upper(Left(TrimAll(vGuest.Sex), 1));
			vGuestItemXDTO.GuestDateOfBirth = vGuest.DateOfBirth;
			vGuestItemXDTO.GuestAge = vGuest.Age;
			vGuestItemXDTO.GuestCitizenship = ?(ValueIsFilled(vGuest.Citizenship), Upper(TrimAll(vGuest.Citizenship.ISOCode3)), "");
			vGuestItemXDTO.GuestLanguage = ?(ValueIsFilled(vGuest.Language), Upper(TrimAll(vGuest.Language.Code)), "");
			vGuestItemXDTO.GuestLocale = ?(ValueIsFilled(vGuest.Language), ?(IsBlankString(vGuest.Language.LocalizationCode), "ru_RU", TrimAll(vGuest.Language.LocalizationCode)), "ru_RU");
			If Not IsBlankString(vGuest.Phone) Then
				vGuestItemXDTO.GuestPhone = TrimAll(vGuest.Phone);
			ElsIf Not IsBlankString(vDocRef.Phone) Then
				vGuestItemXDTO.GuestPhone = TrimAll(vGuest.Phone);
			Else
				vGuestItemXDTO.GuestPhone = "";
			EndIf;
           	vClientSexCode = Left(vGuest.Sex, 1);
            vClientCitizenshipCode = TrimAll(?(ValueIsFilled(vGuest.Citizenship), vGuest.Citizenship.ISOCode3, ""));
			
			vClientProfileXDTO.ClientCode = vGuest.Code;
			vClientProfileXDTO.ClientLastName = vGuest.LastName;
			vClientProfileXDTO.ClientFirstName = vGuest.FirstName;
	    	vClientProfileXDTO.ClientSecondName = vGuest.SecondName;
			vClientProfileXDTO.ClientBirthDate = vGuest.DateOfBirth;
			vClientProfileXDTO.ClientSex = vClientSexCode; 
			vClientProfileXDTO.ClientCitizenship = vClientCitizenshipCode;
			vClientProfileXDTO.PlaceOfBirth = vGuest.PlaceOfBirth;
			
			vClientProfileXDTO.ClientPhone = vGuest.Phone;
			vClientProfileXDTO.ClientEmail = vGuest.Email;
			vClientProfileXDTO.ClientFax = vGuest.Fax;
			vClientProfileXDTO.Address = vGuest.Address;	
			
			vClientProfileXDTO.ClientIdentityDocumentType = vGuest.IdentityDocumentType.Description;
            vClientProfileXDTO.ClientIdentityDocumentSeries = vGuest.IdentityDocumentSeries;
			vClientProfileXDTO.ClientIdentityDocumentNumber = vGuest.IdentityDocumentNumber;
			vClientProfileXDTO.ClientIdentityDocumentIssueDate = vGuest.IdentityDocumentIssueDate; 
			vClientProfileXDTO.ClientIdentityDocumentValidToDate = vGuest.IdentityDocumentValidToDate; 
			vClientProfileXDTO.ClientIdentityDocumentIssuedBy = vGuest.IdentityDocumentIssuedBy;
			vClientProfileXDTO.CIientIdentityDocumentUnitCode = vGuest.IdentityDocumentUnitCode;
			
			vClientProfileXDTO.ClientSendSMS = NOT vGuest.NoSMSDelivery;
			vClientProfileXDTO.IsIndividual = True;	
			
			vGuestItemXDTO.ClientProfile = vClientProfileXDTO;
		EndIf;
		
		vGuestItemXDTO.Hotel = TrimAll(vQryRecords.Hotel);
		vGuestItemXDTO.Room = TrimAll(vQryRecords.Room);
		vGuestItemXDTO.CheckInDate = BegOfDay(vQryRecords.CheckInDate);
		vGuestItemXDTO.CheckOutDate = BegOfDay(vQryRecords.CheckOutDate);
		If ValueIsFilled(vQryRecords.GuestGroup) Then
			vGuestItemXDTO.GuestGroup = vQryRecords.GuestGroup.Code;
		EndIf;
		vGuestItemXDTO.Customer = TrimAll(vQryRecords.Customer);
		If ValueIsFilled(vQryRecords.PlannedPaymentMethod) Then
			vGuestItemXDTO.PaymentMethod = vQryRecords.PlannedPaymentMethod.GetObject().pmGetPaymentMethodDescription(vLanguage);
		EndIf;
		vGuestItemXDTO.Discount = vQryRecords.Discount;
		vGuestItemXDTO.DiscountType = ?(ValueIsFilled(vQryRecords.DiscountType), TrimAll(vQryRecords.DiscountType.Description), "");
		vGuestItemXDTO.DiscountCard = ?(ValueIsFilled(vQryRecords.DiscountCard), TrimAll(vQryRecords.DiscountCard.Identifier), "");
		vGuestItemXDTO.AccommodationCode = TrimAll(vQryRecords.Number);
		vGuestItemXDTO.ClientType = TrimAll(vQryRecords.ClientType);
		vGuestItemXDTO.FolioCurrency = TrimAll(vQryRecords.ReportingCurrencyCode);
		vIsRoomShare = False;
		If ValueIsFilled(vQryRecords.AccommodationType) And vQryRecords.AccommodationTypeType <> Enums.AccomodationTypes.Room Then
			vIsRoomShare = True;
		EndIf;
		vGuestItemXDTO.IsRoomShare = vIsRoomShare;
		If ValueIsFilled(vQryRecords.ServicePackage) And vQryRecords.ServicePackage.IsMealBoardTerm Then
			vGuestItemXDTO.MealBoardTerm = vQryRecords.ServicePackageCode;
			vGuestItemXDTO.MealBoardName = vQryRecords.ServicePackageDescription;
		Else
			vGuestItemXDTO.MealBoardTerm = "";
			vGuestItemXDTO.MealBoardName = "";
		EndIf;
		If ValueIsFilled(vQryRecords.RoomRate) Then
			vGuestItemXDTO.RoomRate = vQryRecords.RoomRateDescription;
			vGuestItemXDTO.RoomRateCode = vQryRecords.RoomRateCode;
		Else
			vGuestItemXDTO.RoomRate = "";
			vGuestItemXDTO.RoomRateCode = "";
		EndIf;
		vGuestItemXDTO.ReservationStatus = TrimAll(vQryRecords.Status);
		vGuestItemXDTO.NoPost = vQryRecords.NoPost;
		
		vGuestItemXDTO.ClientBalance = 0;
		vGuestItemXDTO.CreditLimit	= 0; 
		vGuestItemXDTO.GuestRemarks = "";
		
		vGuestItemsXDTO.GuestItem.Add(vGuestItemXDTO);
	EndDo;
	vGuestsListXDTO.GuestItems = vGuestItemsXDTO;
	
	Return vGuestsListXDTO;
EndFunction // GetGroupGuestsList

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetRefMappingFromTable(pMappingTable, pRef, pType, pParameterIfNotFound = "Description")
	
	vResult = "";
	
	If pMappingTable <> Undefined AND pMappingTable.Count() > 0 Then
		vMappingsRows = pMappingTable.FindRows(New Structure("ObjectTypeName, ObjectRef", pType, pRef));
		If vMappingsRows.Count() > 0 Then
			vResult = vMappingsRows[0].ObjectExternalCode;	
		EndIf;
	EndIf;
	
	If vResult = "" Then
		vResult = pRef[pParameterIfNotFound];
	EndIf;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetGuestByMyFolioUUID(pUUID)
	vResult = Undefined;
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ISNULL(MyFolioSystemIdentificators.ClientDocument.Guest, MyFolioSystemIdentificators.ClientDocument.Client) AS Guest
	|FROM
	|	InformationRegister.MyFolioSystemIdentificators AS MyFolioSystemIdentificators
	|WHERE
	|	MyFolioSystemIdentificators.Identifier = &qIdentifier";
	
	vQuery.SetParameter("qIdentifier", pUUID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For each vRow in vQueryResult Do
		vResult = vRow.Guest;
	EndDo;
	
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetEventsRatingsByMyFolioUUID(pUUID, pHotel)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	EventsRating.Period,
		|	EventsRating.CalendarId,
		|	EventsRating.EventId,
		|	EventsRating.Rating
		|FROM
		|	InformationRegister.EventsRating AS EventsRating
		|WHERE
		|	EventsRating.ClientId = &qClientId
		|	AND EventsRating.Hotel = &qHotel";
	
	vQuery.SetParameter("qClientId", pUUID);
	vQuery.SetParameter("qHotel", pHotel);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;	
EndFunction

// -----------------------------------------------------------------------------
Function GetServicesDiscount(pExternalSystemCode, pDiscountType, pHotel)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	DiscountsSliceLast.ServiceGroup,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
	|	DiscountsSliceLast.Discount
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|		INNER JOIN InformationRegister.Discounts.SliceLast AS DiscountsSliceLast
	|		ON ExternalSystemsObjectCodesMappings.ObjectRef = DiscountsSliceLast.ServiceGroup
	|WHERE
	|	DiscountsSliceLast.DiscountType = &qDiscountType
	|	AND (DiscountsSliceLast.Hotel = &qHotel
	|			OR DiscountsSliceLast.Hotel = &qEmptyHotel)
	|	AND NOT DiscountsSliceLast.DiscountType.DeletionMark
	|	AND NOT DiscountsSliceLast.ServiceGroup.DeletionMark
	|	AND (ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|			OR ExternalSystemsObjectCodesMappings.Hotel = &qEmptyHotel)
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""ServiceGroups""
	|
	|GROUP BY
	|	DiscountsSliceLast.ServiceGroup,
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode,
	|	DiscountsSliceLast.Discount";
	
	vQuery.SetParameter("qDiscountType", pDiscountType);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQuery.SetParameter("qExternalSystemCode", pExternalSystemCode);

	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
EndFunction

// --------------------------------------------------------------------------------------------------
Function GetOrdersByClientId(pClientId, pHotel, pStatus, pExternalSystemCode)
	
	vQry = New Query;
	vQry.Text = "SELECT
	            |	ExternalOrderCodes.ExternalOrderCode AS OrderID,
	            |	Orders.Date AS OrderDate,
	            |	Orders.Hotel.Description AS Hotel,
	            |	Orders.Type.Description AS OrderType,
	            |	Orders.Status.Description AS OrderStatus,
	            |	Orders.Status.Code AS CurrentStatusCode,
	            |	Orders.Status.Description AS CurrentStatusDescription,
	            |	"""" AS StatusesList,
	            |	Orders.Service.Description AS Service,
	            |	Orders.Sum AS Sum,
	            |	Orders.Quantity AS Quantity,
	            |	Orders.Currency.Description AS Currency,
	            |	Orders.Remarks AS Remarks,
	            |	ISNULL(Orders.Department.Description, """") AS Department,
	            |	Orders.Items.(
	            |		Service.Description AS Service,
	            |		Item.Description AS ItemName,
	            |		Item.Code AS ItemId,
	            |		Quantity AS Quantity,
	            |		Price AS Price,
	            |		Sum AS Sum
	            |	) AS OrderItems,
	            |	Orders.GuestsQuantity AS GuestsQuantity,
	            |	Orders.OrderPaymentType AS Payment
	            |FROM
	            |	Document.Order AS Orders
	            |		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
	            |		ON Orders.Ref = ExternalOrderCodes.Order
	            |			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
	            |WHERE
	            |	Orders.Hotel = &qHotel
	            |	AND Orders.Posted
	            |	AND NOT Orders.Status.isOrderComplete
	            |	AND NOT Orders.Status.isOrderCancel
	            |	AND NOT Orders.DeletionMark
	            |	AND CASE
	            |			WHEN &qStatusIsEmpty = TRUE
	            |				THEN TRUE
	            |			ELSE Orders.Status = &qStatus
	            |		END
	            |	AND Orders.Client.Code = &ClientId";
	vQry.SetParameter("ClientId", pClientId);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(pStatus));
	vQry.SetParameter("qStatus", pStatus);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);
	
	vQryRecords = vQry.Execute().Select();
	
	vOrdersXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrdersDetailed"));
	While vQryRecords.Next() Do
		vOrderXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
		
		FillPropertyValues(vOrderXDTO, vQryRecords, ,"OrderItems, StatusesList, Payment");
		vCurrentStatusXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
		vCurrentStatusXDTO.StatusSortCode=vQryRecords.CurrentStatusCode;
		vCurrentStatusXDTO.StatusDescription=vQryRecords.CurrentStatusDescription;
		vOrderXDTO.CurrentStatus=vCurrentStatusXDTO;
		
		vQryItemsRecords=vQryRecords.OrderItems.Select();
		vOrderItemsXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
		While vQryItemsRecords.Next() Do
			vItemXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
			FillPropertyValues(vItemXDTO, vQryItemsRecords);
			
			vOrderItemsXDTO.OrderItem.Add(vItemXDTO);
		EndDo;
		vOrderXDTO.OrderItems=vOrderItemsXDTO;

		vOrdersXDTO.OrderDetails.Add(vOrderXDTO)
	EndDo;
	
	Return vOrdersXDTO;
EndFunction

// --------------------------------------------------------------------------------------------------
Function GetOrdersByRoom(pRoom, pHotel, pStatus, pExternalSystemCode)
	
	vQry = New Query;
	vQry.Text = "SELECT
	            |	ExternalOrderCodes.ExternalOrderCode AS OrderID,
	            |	Orders.Date AS OrderDate,
	            |	Orders.Hotel.Description AS Hotel,
	            |	Orders.Type.Description AS OrderType,
	            |	Orders.Status.Description AS OrderStatus,
	            |	Orders.Status.Code AS CurrentStatusCode,
	            |	Orders.Status.Description AS CurrentStatusDescription,
	            |	"""" AS StatusesList,
	            |	Orders.Service.Description AS Service,
	            |	Orders.Sum AS Sum,
	            |	Orders.Quantity AS Quantity,
	            |	Orders.Currency.Description AS Currency,
	            |	Orders.Remarks AS Remarks,
	            |	ISNULL(Orders.Department.Description, """") AS Department,
	            |	Orders.Items.(
	            |		Service.Description AS Service,
	            |		Item.Description AS ItemName,
	            |		Item.Code AS ItemId,
	            |		Quantity AS Quantity,
	            |		Price AS Price,
	            |		Sum AS Sum
	            |	) AS OrderItems,
	            |	Orders.GuestsQuantity AS GuestsQuantity,
	            |	Orders.OrderPaymentType AS Payment
	            |FROM
	            |	Document.Order AS Orders
	            |		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
	            |		ON Orders.Ref = ExternalOrderCodes.Order
	            |			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
	            |WHERE
	            |	Orders.Hotel = &qHotel
	            |	AND Orders.Posted
	            |	AND NOT Orders.Status.isOrderComplete
	            |	AND NOT Orders.Status.isOrderCancel
	            |	AND NOT Orders.DeletionMark
	            |	AND CASE
	            |			WHEN &qStatusIsEmpty = TRUE
	            |				THEN TRUE
	            |			ELSE Orders.Status = &qStatus
	            |		END
	            |	AND Orders.Room = &qRoom
	            |	AND Orders.Folio.ParentDoc.AccommodationStatus.IsActive
	            |	AND Orders.Folio.ParentDoc.AccommodationStatus.IsInHouse";
	
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(pStatus));
	vQry.SetParameter("qStatus", pStatus);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);

	vQryRecords = vQry.Execute().Select();
	
	vOrdersXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrdersDetailed"));
	While vQryRecords.Next() Do
		vOrderXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
		
		FillPropertyValues(vOrderXDTO, vQryRecords, ,"OrderItems, StatusesList, Payment");
		vCurrentStatusXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
		vCurrentStatusXDTO.StatusSortCode=vQryRecords.CurrentStatusCode;
		vCurrentStatusXDTO.StatusDescription=vQryRecords.CurrentStatusDescription;
		vOrderXDTO.CurrentStatus=vCurrentStatusXDTO;
		
		vQryItemsRecords=vQryRecords.OrderItems.Select();
		vOrderItemsXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
		While vQryItemsRecords.Next() Do
			vItemXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
			FillPropertyValues(vItemXDTO, vQryItemsRecords);
			
			vOrderItemsXDTO.OrderItem.Add(vItemXDTO);
		EndDo;
		vOrderXDTO.OrderItems=vOrderItemsXDTO;

		vOrdersXDTO.OrderDetails.Add(vOrderXDTO)
	EndDo;
	
	Return vOrdersXDTO;
EndFunction

// --------------------------------------------------------------------------------------------------
Function GetOrdersByFolioNumber(pFolioNumber, pHotel, pStatus, pExternalSystemCode)
	
	vQry = New Query;
	vQry.Text = "SELECT
			|	ExternalOrderCodes.ExternalOrderCode AS OrderID,
			|	Orders.Date AS OrderDate,
			|	Orders.Hotel.Description AS Hotel,
			|	Orders.Type.Description AS OrderType,
			|	Orders.Status.Description AS OrderStatus,
			|	Orders.Status.Code AS CurrentStatusCode,
			|	Orders.Status.Description AS CurrentStatusDescription,
			|	"""" AS StatusesList,
			|	Orders.Service.Description AS Service,
			|	Orders.Sum AS Sum,
			|	Orders.Quantity AS Quantity,
			|	Orders.Currency.Description AS Currency,
			|	Orders.Remarks AS Remarks,
			|	ISNULL(Orders.Department.Description, """") AS Department,
			|	Orders.Items.(
			|		ISNULL(Service.Description, """") AS Service,
			|		ISNULL(Item.Description,"""") AS ItemName,
			|		ISNULL(Item.Code,"""") AS ItemId,
			|		Quantity AS Quantity,
			|		Price AS Price,
			|		Sum AS Sum
			|	) AS OrderItems,
			|	Orders.GuestsQuantity AS GuestsQuantity,
			|	Orders.OrderPaymentType AS Payment
			|FROM
			|	Document.Order AS Orders
			|		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
			|		ON Orders.Ref = ExternalOrderCodes.Order
			|			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
			|WHERE
			|	Orders.Hotel = &qHotel
			|	AND Orders.Posted
			|	AND NOT Orders.Status.isOrderComplete
			|	AND NOT Orders.Status.isOrderCancel
			|	AND NOT Orders.DeletionMark
			|	AND CASE
			|			WHEN &qStatusIsEmpty = TRUE
			|				THEN TRUE
			|			ELSE Orders.Status = &qStatus
			|		END
			|	AND Orders.Folio.Number = &qFolio";
	
	vQry.SetParameter("qFolio", pFolioNumber);
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(pStatus));
	vQry.SetParameter("qStatus", pStatus);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);


	vQryRecords = vQry.Execute().Select();
	
	vOrdersXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrdersDetailed"));
	While vQryRecords.Next() Do
		vOrderXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
		
		FillPropertyValues(vOrderXDTO, vQryRecords, ,"OrderItems, StatusesList, Payment");
		vCurrentStatusXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
		vCurrentStatusXDTO.StatusSortCode=vQryRecords.CurrentStatusCode;
		vCurrentStatusXDTO.StatusDescription=vQryRecords.CurrentStatusDescription;
		vOrderXDTO.CurrentStatus=vCurrentStatusXDTO;
		
		vQryItemsRecords=vQryRecords.OrderItems.Select();
		vOrderItemsXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
		While vQryItemsRecords.Next() Do
			vItemXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
			FillPropertyValues(vItemXDTO, vQryItemsRecords);
			
			vOrderItemsXDTO.OrderItem.Add(vItemXDTO);
		EndDo;
		vOrderXDTO.OrderItems=vOrderItemsXDTO;

		vOrdersXDTO.OrderDetails.Add(vOrderXDTO)
	EndDo;
	
	Return vOrdersXDTO;
EndFunction

// --------------------------------------------------------------------------------------------------
Function GetAllOrdersByStatus(pHotel, pStatus, pExternalSystemCode)
	
	vQry = New Query;
	vQry.Text = "SELECT
	            |	ExternalOrderCodes.ExternalOrderCode AS OrderID,
	            |	Orders.Date AS OrderDate,
	            |	Orders.Hotel.Description AS Hotel,
	            |	Orders.Type.Description AS OrderType,
	            |	Orders.Status.Description AS OrderStatus,
	            |	Orders.Status.Code AS CurrentStatusCode,
	            |	Orders.Status.Description AS CurrentStatusDescription,
	            |	"""" AS StatusesList,
	            |	Orders.Service.Description AS Service,
	            |	Orders.Sum AS Sum,
	            |	Orders.Quantity AS Quantity,
	            |	Orders.Currency.Description AS Currency,
	            |	Orders.Remarks AS Remarks,
	            |	ISNULL(Orders.Department.Description, """") AS Department,
	            |	Orders.Items.(
	            |		ISNULL(Orders.Items.Service.Description, """") AS Service,
	            |		ISNULL(Orders.Items.Item.Description, """") AS ItemName,
	            |		ISNULL(Orders.Items.Item.Code, """") AS ItemId,
	            |		Quantity AS Quantity,
	            |		Price AS Price,
	            |		Sum AS Sum
	            |	) AS OrderItems,
	            |	Orders.GuestsQuantity AS GuestsQuantity,
	            |	Orders.OrderPaymentType AS Payment
	            |FROM
	            |	Document.Order AS Orders
	            |		LEFT JOIN InformationRegister.ExternalOrderCodes AS ExternalOrderCodes
	            |		ON Orders.Ref = ExternalOrderCodes.Order
	            |			AND (ExternalOrderCodes.ExternalSystemCode = &qExternalSystemCode)
	            |WHERE
	            |	Orders.Hotel = &qHotel
	            |	AND Orders.Posted
	            |	AND NOT Orders.Status.isOrderComplete
	            |	AND NOT Orders.Status.isOrderCancel
	            |	AND NOT Orders.DeletionMark
	            |	AND CASE
	            |			WHEN &qStatusIsEmpty = TRUE
	            |				THEN TRUE
	            |			ELSE Orders.Status = &qStatus
	            |		END";
	
	vQry.SetParameter("qStatusIsEmpty", Not ValueIsFilled(pStatus));
	vQry.SetParameter("qStatus", pStatus);
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qExternalSystemCode", pExternalSystemCode);
	
	vQryRecords = vQry.Execute().Select();
	
	vOrdersXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrdersDetailed"));
	While vQryRecords.Next() Do
		vOrderXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
		
		FillPropertyValues(vOrderXDTO, vQryRecords, ,"OrderItems, StatusesList, Payment");
		vCurrentStatusXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderStatus"));
		vCurrentStatusXDTO.StatusSortCode=vQryRecords.CurrentStatusCode;
		vCurrentStatusXDTO.StatusDescription=vQryRecords.CurrentStatusDescription;
		vOrderXDTO.CurrentStatus=vCurrentStatusXDTO;
		
		vQryItemsRecords=vQryRecords.OrderItems.Select();
		vOrderItemsXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
		While vQryItemsRecords.Next() Do
			vItemXDTO=XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
			FillPropertyValues(vItemXDTO, vQryItemsRecords);
			
			vOrderItemsXDTO.OrderItem.Add(vItemXDTO);
		EndDo;
		vOrderXDTO.OrderItems=vOrderItemsXDTO;

		vOrdersXDTO.OrderDetails.Add(vOrderXDTO)
	EndDo;
	
	Return vOrdersXDTO;
EndFunction

#EndRegion
