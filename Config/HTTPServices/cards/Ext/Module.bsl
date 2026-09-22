
#Region Public

// --------------------------------------------------------------------------------
Function GetCardInfoExPOST(pRequest)
	vCardCode = "";
	vExternalSystemCode = "r_keeper";
	vIsCloseToTheRoom = False;
	vIsCloseToTheFolio = False;
	
	vWriteDebug = False;
	vMaxRoomNumberLength = 0;
	vMinCardNumberLength = 0;
	
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExternalSystemCode);
	If ValueIsFilled(vInteraction) Then
		vWriteDebug = vInteraction.DebugMode;
		vMaxRoomNumberLength = vInteraction.RoomNumberLenght;
		vMinCardNumberLength = vInteraction.CardNumberLength;
	EndIf;	
	
	vFuncLog = "GetCardInfoEx";

	startHOLDERS = False;
	
	vResponse = New HTTPServiceResponse(200);
	vRequestBody 	= pRequest.GetBodyAsString();

	vMsg = "POST";
	vUUID = "";  
	vTimestamp = CurrentSessionDate();
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vRequestBody, , vMsg, vInteraction.MaxLogLenght, vUUID, vTimestamp);
	Else
		WriteLogEvent("FarCard.GetCardInfoExPOST",EventLogLevel.Note, , , vRequestBody);
	EndIf;
	
	xmlRequest = New XMLReader;
	xmlRequest.SetString(vRequestBody);
	vTotalOrderSum = 0;
	While xmlRequest.Read() Do
		If xmlRequest.NodeType = XMLNodeType.StartElement Then
			If xmlRequest.Name = "INTERFACE" Then
				vInterfaceID = xmlRequest.GetAttribute("interface");
			EndIf;
			If xmlRequest.Name = "HOLDERS" Then
				startHOLDERS = True;
			EndIf;
			If xmlRequest.Name = "ITEM" and startHOLDERS Then
				vCardCode = xmlRequest.GetAttribute("cardcode");
			EndIf;
			If xmlRequest.Name = "LINE" Then
				Try
					itemSum = Number(xmlRequest.GetAttribute("sum"));
				Except
					WriteLogEvent("FarCard.GetCardInfoExPOST", EventLogLevel.Note, , , "Error converting number LINE sum " + ErrorDescription());
					itemSum = 0;
				EndTry;
				vTotalOrderSum = vTotalOrderSum + itemSum;
			EndIf;
		EndIf;		
		If xmlRequest.NodeType = XMLNodeType.EndElement Then
			If xmlRequest.Name = "HOLDERS" Then
				startHOLDERS = False;
			EndIf;
		EndIf;
	EndDo;
	
	vHotel = cmGetObjectRefByExternalSystemCode("", vExternalSystemCode, "Hotels", vInterfaceID, False);
	If Not ValueIsFilled(vHotel) Then
		vHotel = cmGetHotelByCode("", vExternalSystemCode);
	EndIF;
	
	xmlResponse = New XMLWriter;
	vXMLWriterSettings = New XMLWriterSettings("UTF-8", "1.0", False, False);
	xmlResponse.SetString(vXMLWriterSettings);
	xmlResponse.WriteXMLDeclaration();
	
	// Check the cardcode prefix - R - is used for room number, F - for folio number
	If Not IsBlankString(vCardCode) Then
		If Left(vCardCode, 1) = "R" Then
			vIsCloseToTheRoom = True;
			vCardCode = Mid(TrimAll(vCardCode), 2);
		ElsIf Left(vCardCode, 1) = "F" Then
			vIsCloseToTheFolio = True;
			vCardCode = Mid(TrimAll(vCardCode), 2);
		EndIf;
	Endif;
	
	// Check the length of cardcode, in some cases we use length to determine of it's a room or folio number
	If vMaxRoomNumberLength > 0 And StrLen(vCardCode) <= vMaxRoomNumberLength Then
		vIsCloseToTheRoom = True;
	ElsIf (vMinCardNumberLength > 0 And StrLen(vCardCode) < vMinCardNumberLength) 
		Or (vMinCardNumberLength = 0 And vMaxRoomNumberLength > 0 And StrLen(vCardCode) > vMaxRoomNumberLength) Then
		vIsCloseToTheFolio = True;
	EndIf;
	
	// Mapping of the interface id and payment method is prevail
	vPayMethod = cmGetObjectRefByExternalSystemCode(vHotel, vExternalSystemCode, "PaymentMethods", vInterfaceID, True);
	If Not vIsCloseToTheRoom And Not vIsCloseToTheFolio And ValueIsFilled(vPayMethod) Then
		vIsCloseToTheRoom  = vPayMethod.IsCloseToTheRoom;
		vIsCloseToTheFolio = vPayMethod.IsCloseToTheFolio;
	EndIf;
		
	Try	
		If Not IsBlankString(vCardCode) Then
			If vIsCloseToTheRoom Then
				// Room
				cardInfo = cmGetHotelGuestsList("", vCardCode, ?(ValueIsFilled(vHotel), TrimAll(vHotel.Code), ""), "XML", vExternalSystemCode);
				xmlResponse.WriteStartElement("Root");
				vNumberOfGuests = 0;
				vCurRoom = Undefined;
				For Each guest in cardInfo.GuestItems.GuestItem Do
					// We will return only one guest per room because there is no way to select guest to charge ticket to in R-Keeper
					If vCurRoom <> Undefined And vCurRoom = TrimAll(guest.Room) Then
						If ValueIsFilled(vInteraction) And vInteraction.IntegrationType = Enums.Integrations.rkeeper Then
							Continue;
						EndIf;
					Else
						vCurRoom = TrimAll(guest.Room);
					EndIf;
					
					xmlResponse.WriteStartElement("GetCardInfoEx");
					xmlResponse.WriteAttribute("CardCode", guest.Room);
					xmlResponse.WriteAttribute("Account", Right(GetNumberNoPrefix(guest.GuestCode), 9)); // Will be used in transation post for room in case several clients in the room
					xmlResponse.WriteAttribute("Deleted", "0");
					xmlResponse.WriteAttribute("Locked", "0");
					xmlResponse.WriteAttribute("Seize", "0");
					xmlResponse.WriteAttribute("Discount", ?(IsBlankString(TrimAll(guest.DiscountType)), "0", ?(cmIsNumber(TrimAll(guest.DiscountType)), TrimAll(guest.DiscountType), "0"))); // Discount code as it is in r-keeper
					xmlResponse.WriteAttribute("Bonus", "0");
					xmlResponse.WriteAttribute("Summa", Format(guest.CreditLimit * 100 - guest.ClientBalance * 100, "ND=15; NZ=0; NG="));
					xmlResponse.WriteAttribute("DiscLimit", "99999999"); // Maximium discount no limit
					
					vRemarks = "";
					vHolder = ?(IsBlankString(guest.Guest),guest.Room,guest.Guest);
					If ValueIsFilled(guest.CheckOutDate) Then
						vRemarks = NStr("en = 'Check-out: '; de = 'Abreise: '; ru = 'Выезд: '")+Format(guest.CheckOutDate,"DF=dd.MM.yyyy");
						If BegOfDay(guest.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
							vRemarks = vRemarks + NStr("en = ' (today!)'; de = ' (heute!)'; ru = ' (сегодня!)'");
						EndIf;
						vRemarks = vRemarks + Chars.CR;
					EndIf;
					If ValueIsFilled(guest.GuestDateOfBirth) Then
						If ((Month(guest.GuestDateOfBirth) * 100 + Day(guest.GuestDateOfBirth)) - (Month(CurrentSessionDate()) * 100 + Day(CurrentSessionDate()))) = 0 Then
							// It's guests birthday today
							vHolder =  vHolder+NStr("en = ' Birthday today:'; de = ' Geburtstag: '; ru = ' День рождения: '") + Format(guest.GuestDateOfBirth, "DF=dd.MMM") + Chars.CR;
						EndIf;
					EndIf;
					vRemarks = vRemarks + " " + guest.GuestRemarks; 	 
					xmlResponse.WriteAttribute("Holder", vHolder);
					xmlResponse.WriteAttribute("DopInfo", vRemarks);
					
					xmlResponse.WriteAttribute("WhyLock", "");
					xmlResponse.WriteAttribute("ScrMessage", "");
					xmlResponse.WriteAttribute("PrnMessage", "");
					xmlResponse.WriteAttribute("Result", "0");
					xmlResponse.WriteEndElement();
					vNumberOfGuests = vNumberOfGuests + 1;
				EndDo;
				If vNumberOfGuests = 0 Then
					xmlResponse.WriteStartElement("GetCardInfoEx");
					xmlResponse.WriteAttribute("Result","1");
					vErrorText = NStr("en = 'No guests in the room'; de = 'Keine Gäste im Zimmer'; ru = 'В номере нет проживающих гостей'");
					xmlResponse.WriteAttribute("ErrorText",vErrorText);
					xmlResponse.WriteEndElement();
				EndIf;
				
				xmlResponse.WriteEndElement(); // ROOT
			ElsIf vIsCloseToTheFolio Then
				// Folio number
				cardInfo = cmGetFolioDescription(vCardCode, ?(ValueIsFilled(vHotel), TrimAll(vHotel.Code), ""), vExternalSystemCode, "XDTO");
				
				xmlResponse.WriteStartElement("Root");
				
				xmlResponse.WriteStartElement("GetCardInfoEx");
				xmlResponse.WriteAttribute("CardCode", vCardCode);
				xmlResponse.WriteAttribute("Account", Right(GetNumberNoPrefix(cardInfo.FolioNumber), 9));
				xmlResponse.WriteAttribute("Deleted", "0");
				xmlResponse.WriteAttribute("Locked", "0");
				xmlResponse.WriteAttribute("Seize", "0");
				xmlResponse.WriteAttribute("Discount", ?(IsBlankString(TrimAll(cardInfo.DiscountType)), "0", ?(cmIsNumber(TrimAll(cardInfo.DiscountType)), TrimAll(cardInfo.DiscountType), "0")));
				xmlResponse.WriteAttribute("Bonus", "0");
				xmlResponse.WriteAttribute("Summa", Format(cardInfo.CreditLimit * 100 - cardInfo.FolioBalance * 100, "ND=15; NZ=0; NG="));
				xmlResponse.WriteAttribute("DiscLimit", "99999999");
				// The folio is for customer
				xmlResponse.WriteAttribute("Holder", cardInfo.Customer);
				xmlResponse.WriteAttribute("DopInfo", cardInfo.FolioDescription);
				xmlResponse.WriteAttribute("WhyLock", "");
				xmlResponse.WriteAttribute("ScrMessage", "");
				xmlResponse.WriteAttribute("PrnMessage", "");
				xmlResponse.WriteAttribute("Result", "0");
				xmlResponse.WriteEndElement();
				
				xmlResponse.WriteEndElement(); // ROOT
				
			Else
				// Card number
				cardInfo = cmGetClientIdentificationCardBalance(vCardCode, "XML", vExternalSystemCode);
				
				xmlResponse.WriteStartElement("Root");
				
				xmlResponse.WriteStartElement("GetCardInfoEx");
				xmlResponse.WriteAttribute("CardCode", vCardCode);
				xmlResponse.WriteAttribute("Account", ?(IsBlankString(cardInfo.ClientCode), Right(vCardCode, 9), GetNumberNoPrefix(cardInfo.ClientCode))); // Account Has to be integer value, and maximum value for integer is 2147483647 thats why 9 symbols
				xmlResponse.WriteAttribute("Deleted", "0");
				If cardInfo.IsBlocked Then 
					xmlResponse.WriteAttribute("Locked", "1");
					xmlResponse.WriteAttribute("ScrMessage", cardInfo.BlockReason);
				Else
					xmlResponse.WriteAttribute("Locked", "0");
					xmlResponse.WriteAttribute("ScrMessage", "");
				EndIf;
				xmlResponse.WriteAttribute("Seize", "0");
				xmlResponse.WriteAttribute("Discount", ?(IsBlankString(TrimAll(cardInfo.DiscountType)), "0", ?(cmIsNumber(TrimAll(cardInfo.DiscountType)), TrimAll(cardInfo.DiscountType), "0")));
				xmlResponse.WriteAttribute("Bonus", "0");
				
				vCardBalance = (cardInfo.CreditLimit - cardInfo.Balance) * 100;
				
				vDiscountCardInfo =  cardInfo.Properties().Get("DiscountCardInfo");
				vRemarks = "";
				vHolder = ?(IsBlankString(cardInfo.Client),vCardCode,cardInfo.Client);
				If ValueIsFilled(cardInfo.CheckOutDate) Then
					vRemarks = NStr("en = 'Check-out: '; de = 'Abreise: '; ru = 'Выезд: '") + Format(cardInfo.CheckOutDate, "DF=dd.MM.yyyy");
					If BegOfDay(cardInfo.CheckOutDate) = BegOfDay(CurrentSessionDate()) Then
						vRemarks = vRemarks+NStr("en = ' (today!)'; de = ' (heute!)'; ru = ' (сегодня!)'");
					EndIf;
					vRemarks=vRemarks+Chars.CR;
				EndIf;
				If ValueIsFilled(cardInfo.ClientBirthDate) Then
					If ((Month(cardInfo.ClientBirthDate) * 100 + Day(cardInfo.ClientBirthDate)) - (Month(CurrentSessionDate()) * 100 + Day(CurrentSessionDate()))) = 0 Then
						// It's guests birthday today
						vHolder =  vHolder + NStr("en = ' Birthday today:'; de = ' Geburtstag: '; ru = ' День рождения: '") + Format(cardInfo.ClientBirthDate, "DF=dd.MMM") + Chars.CR;
					EndIf;
				EndIf;
				vDiscLimit = 99999999; // Defualt - no limit
				If cardInfo.IsSet(vDiscountCardInfo) And (Not IsBlankString(cardInfo.DiscountCardInfo.TypeCard)) Then
					vCardBalance = cardInfo.DiscountCardInfo.CardBalance * 100;
					vRemarks = cardInfo.DiscountCardInfo.TypeCard;
					vMaxPercentPayment = cardInfo.DiscountCardInfo.MaxPercentPayment;
					If vMaxPercentPayment > 0 Then
						vDiscLimit = vTotalOrderSum * vMaxPercentPayment / 100;
					EndIf;
				EndIf;
				
				xmlResponse.WriteAttribute("Holder",vHolder);
				xmlResponse.WriteAttribute("DopInfo",vRemarks);
				xmlResponse.WriteAttribute("Summa",Format(vCardBalance, "ND=15; NZ=0; NG="));
				xmlResponse.WriteAttribute("DiscLimit",Format(vDiscLimit * 100,"ND=9; NFD=0; NG="));
				
				xmlResponse.WriteAttribute("WhyLock", cardInfo.BlockReason);
				xmlResponse.WriteAttribute("PrnMessage", "");
				xmlResponse.WriteAttribute("Result", "0");
				xmlResponse.WriteEndElement();
				
				xmlResponse.WriteEndElement(); // ROOT
			EndIf;
		Else
			vErrorText = NStr("en = 'No payment method is set for the interface %1. Map it in the 1C:Hotel.'; 
							  |de = 'Für die Schnittstelle %1 ist keine Zahlungsmethode festgelegt. Richten Sie das 1C:Hotel ein.'; 
							  |ru = 'Для интерфейса %1 не задан вариант оплаты. Задайте соответсвие в 1С-Отель.'");
			vErrorText = StrTemplate(vErrorText, vInterfaceID);
			xmlResponse.WriteStartElement("Root");
			xmlResponse.WriteStartElement("GetCardInfoEx");
			xmlResponse.WriteAttribute("Result", "1");
			xmlResponse.WriteAttribute("ErrorText", vErrorText);
			xmlResponse.WriteEndElement();
			xmlResponse.WriteEndElement();
		EndIF;
	Except
		vErrorText = ErrorDescription();
		vMsg = NStr("en = 'Error'; de = 'Fehler'; ru = 'Ошибка'");
		WriteLogEvent("FarCard.GetCardInfoExResponse", EventLogLevel.Error, , , vErrorText);
		xmlResponse = New XMLWriter;
		vXMLWriterSettings = New XMLWriterSettings("UTF-8", "1.0", False, False);
		xmlResponse.SetString(vXMLWriterSettings);
		xmlResponse.WriteXMLDeclaration();
		
		xmlResponse.WriteStartElement("Root");
		xmlResponse.WriteStartElement("GetCardInfoEx");
		xmlResponse.WriteAttribute("Result", "1");
		xmlResponse.WriteAttribute("ErrorText", vErrorText);
		xmlResponse.WriteEndElement();
		xmlResponse.WriteEndElement();
	EndTry;
	vResponseXML = xmlResponse.Close();
	vResponse.Headers = GetHeaders(StrLen(vResponseXML), "text/xml");
	
	vResponse.SetBodyFromString(vResponseXML);
	
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vRequestBody, vResponseXML , vMsg, vInteraction.MaxLogLenght, vUUID, vTimestamp);
	Else
		WriteLogEvent("FarCard.GetCardInfoExResponse",EventLogLevel.Note, , , vResponseXML);
	EndIf;
	
	Return vResponse;
EndFunction // GetCardInfoExPOST

// --------------------------------------------------------------------------------
Function GetCardImageExPOST(pRequest)
	vResponse = New HTTPServiceResponse(200);
	vRequestBody = pRequest.GetBodyAsString();
	// Log request
	WriteLogEvent("FarCard.GetCardImageExPOST", EventLogLevel.Note, , , vRequestBody);
	
	vResponseXML = "";	
	vResponse.Headers = GetHeaders(StrLen(vResponseXML), "text/xml");
	vResponse.SetBodyFromString(vResponseXML);
	Return vResponse;
EndFunction // GetCardImageExPOST

// --------------------------------------------------------------------------------
Function FindEmailPOST(pRequest)
	vResponse = New HTTPServiceResponse(200);
	vRequestBody = pRequest.GetBodyAsString();
	// Log request
	WriteLogEvent("FarCard.FindEmailPOST", EventLogLevel.Note, , , vRequestBody);
	
	vResponseXML = "";	
	vResponse.Headers = GetHeaders(StrLen(vResponseXML), "text/xml");
	vResponse.SetBodyFromString(vResponseXML);
	Return vResponse;
EndFunction // FindEmailPOST

// --------------------------------------------------------------------------------
Function TransactionsExPOST(pRequest)
	vExternalSystemCode = "r_keeper";
	vErrorDescription = "";
	cardcode = "";
	interface_id = "";
	shiftdate = "";
	chmode = "";
	shiftnum = "";
	orderguid = "";
	checknum = "";
	
	vWriteDebug = False;
	vMaxRoomNumberLength = 0;
	vMinCardNumberLength = 0;
	
	vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vExternalSystemCode);
	If ValueIsFilled(vInteraction) Then
		vWriteDebug = vInteraction.DebugMode;
		vMaxRoomNumberLength = vInteraction.RoomNumberLenght;
		vMinCardNumberLength = vInteraction.CardNumberLength;
	EndIf;	
	
	vResponse = New HTTPServiceResponse(200);
	vRequestBody = pRequest.GetBodyAsString();
	
	vFuncLog = "FarCard.TransactionsExPOST";
	vMsg = "POST";
	vUUID = "";  
	vTimestamp = CurrentSessionDate();
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vRequestBody, , vMsg, vInteraction.MaxLogLenght, vUUID, vTimestamp);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Note, , , vRequestBody);
	EndIf;
	
	xdtoClient = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderClient"));
	xdtoOrder  = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderDetails"));
	xdtoSource = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "Source"));
	xdtoOrderItems = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItems"));
	xdtoOrderPaymentMethods = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPaymentMethods"));
	xdtoPayment = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPayment"));
	
	vOrderNum = "";
	vTotalOrderSum = 0;
	vTotalPaymentSum = 0;
	vNonFiscalPayments = 0;
	vTPayments = New ValueTable;
	vTPayments.Columns.Add("cardcode");
	vTPayments.Columns.Add("paymentmethodcode");
	vTPayments.Columns.Add("sum", cmGetSumTypeDescription());
	vTPayments.Columns.Add("uni");
	
	xmlRequest = New XMLReader;
	xmlRequest.SetString(vRequestBody);
	While xmlRequest.Read() Do
		If xmlRequest.NodeType = XMLNodeType.StartElement Then
			If xmlRequest.Name = "CHECK" Then
				chmode = xmlRequest.GetAttribute("chmode");
				xdtoSource.ExternalSystemCode = vExternalSystemCode;
				xdtoSource.POS = xmlRequest.GetAttribute("cashservername"); // Map to cash register
				// XdtoSource.POS = xmlRequest.GetAttribute("stationcode");
				// XdtoSource.POS = ""; 27/12/2021 Fix for GROPT
				xdtoOrder.Service = xmlRequest.GetAttribute("cashservername");
				shiftdate = xmlRequest.GetAttribute("shiftdate");
				shiftnum  = xmlRequest.GetAttribute("shiftnum");
			EndIf;
			If xmlRequest.Name = "INTERFACE" Then
				interface_id = xmlRequest.GetAttribute("interface");
			EndIf;
			If xmlRequest.Name = "CHECKDATA" Then
				orderguid = Mid(xmlRequest.GetAttribute("orderguid"), 2, 36);
				
				xdtoOrder.OrderDate = xmlRequest.GetAttribute("closedatetime");
				checknum = xmlRequest.GetAttribute("checknum");
				vOrderNum = checknum;
				If IsBlankString(vOrderNum) Then
					vOrderNum = xmlRequest.GetAttribute("ordernum");
				EndIf;
				vOrderNum = vOrderNum+"/"+chmode;
				
				xdtoOrder.OrderID = orderguid+"/"+vOrderNum; // We need to add chmode as void or strono transaction comes with the same guid and we have make differance
				xdtoOrder.Remarks = NStr("de='Bestellung Nr. ';en='Order N ';ru='Заказ № '") + vOrderNum 
								  + NStr("en = ' opened '; de = ' geöffnet '; ru = ' открыт '") + xmlRequest.GetAttribute("startservice") 
								  + NStr("en = ' Table# '; de = ' Tisch # '; ru = ' Стол № '") + xmlRequest.GetAttribute("tablename");
				xdtoOrder.Department = "Restaurant";
				xdtoOrder.GuestsQuantity = xmlRequest.GetAttribute("guests");
			EndIf;
			If xmlRequest.Name = "LINE" Then
				item = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderItem"));
				item.Service = xmlRequest.GetAttribute("servprint");
				item.ItemName = xmlRequest.GetAttribute("name");
				item.ItemId = xmlRequest.GetAttribute("code");
				lineType = xmlRequest.GetAttribute("type");
				Try
					item.Quantity = Number(xmlRequest.GetAttribute("quantity"));
				Except
					WriteLogEvent("FarCard.TransactionsExPOST", EventLogLevel.Note, , , "Error converting number LINE quantity" + ErrorDescription());
					item.Quantity = 1;
				EndTry;
				Try
					item.Price = Number(xmlRequest.GetAttribute("price"));
				Except
					WriteLogEvent("FarCard.TransactionsExPOST", EventLogLevel.Note, , , "Error converting number LINE price" + ErrorDescription());
					item.Price = 0;
				EndTry;
				Try
					item.Sum = Number(xmlRequest.GetAttribute("sum"));
				Except
					WriteLogEvent("FarCard.TransactionsExPOST", EventLogLevel.Note, , , "Error converting number LINE sum " + ErrorDescription());
					item.Sum = 0;
				EndTry;
				If chmode = "3" Then
					// It's a void or strorno transaction
					item.Price = -item.Price;
					item.Sum = -item.Sum;
				EndIf;
				If lineType = "modify" OR lineType = "combo" Then
					// Skip modificator and combo lines as they doubled by dish lines
				Else
                    // Calculate order sum only for it's not combo or modify
					vTotalOrderSum = vTotalOrderSum + item.Sum;
					xdtoOrderItems.OrderItem.Add(item);
				EndIf;				
			EndIf;
			If xmlRequest.Name = "PAYMENT" Then
				// Payment line key
				vPaymentMethodCode = TrimAll(xmlRequest.GetAttribute("interface"));
				If IsBlankString(vPaymentMethodCode) Then
					vPaymentMethodCode = TrimAll(xmlRequest.GetAttribute("name"));
				EndIF;
				  vPaymentID = orderguid + "/" + vOrderNum + "/" + TrimAll(xmlRequest.GetAttribute("uni"));
				vRowSum = 0;
				Try
					vRowSum = Number(xmlRequest.GetAttribute("sum"));
				Except
					WriteLogEvent("FarCard.TransactionsExPOST", EventLogLevel.Note, , , "Error converting number " + ErrorDescription());
				EndTry;
				If chmode = "3" Then
					// It's a void or strorno transaction
					vRowSum = -vRowSum;
				EndIf;
				// Try to find an existing payment method line
				vPayRow = vTPayments.Find(vPaymentMethodCode, "paymentmethodcode");
				If vPayRow = Undefined Then
					vPayRow = vTPayments.Add();
				EndIf;
				vPayRow.cardcode = xmlRequest.GetAttribute("cardcode");
				vPayRow.paymentmethodcode = vPaymentMethodCode;
				vPayRow.uni = vPaymentID;
				vPayRow.sum = vPayRow.sum + vRowSum;
			EndIf; // PAYMENT
		EndIf;		
	EndDo;
	
	vHotel = cmGetObjectRefByExternalSystemCode("", vExternalSystemCode, "Hotels", interface_id, False);
	If Not ValueIsFilled(vHotel) Then
		vHotel = cmGetHotelByCode("", vExternalSystemCode);
	EndIF;

	xdtoOrder.Hotel = vHotel.Code;
	
	// Process payment lines sored in temp table
	// as we can have a few lines for one payment method (cash specifically)
	// and those lines are for change calculation with minus sign in sum for change
	
	For Each vPayRow In vTPayments Do
		vIsByGiftCertificate = False;
		vIsByBonuses = False;
		vIsCloseToTheRoom = False;
		vIsCloseToTheFolio = False;
		
		pay = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/restaurant/", "OrderPaymentMethod"));
				
		cardcode = vPayRow.cardcode;
		// Check the cardcode prefix - R - is used for room number, F - for folio number
		If Not IsBlankString(cardcode) Then
			If Left(cardcode,1) = "R" Then
				vIsCloseToTheRoom = True;
				cardcode = Mid(TrimAll(cardcode), 2);
			ElsIf Left(cardcode,1) = "F" Then
				vIsCloseToTheFolio = True;
				cardcode = Mid(TrimAll(cardcode), 2);
			EndIf;
		Endif;
		
		// Check the length of cardcode, in some cases we use length to determine of it's a room or folio number
		If StrLen(cardcode) > 0 Then
			If vMaxRoomNumberLength > 0 And StrLen(cardcode) <= vMaxRoomNumberLength Then
				vIsCloseToTheRoom = True;
			ElsIf (vMinCardNumberLength > 0 And StrLen(cardcode) < vMinCardNumberLength) OR
				(vMinCardNumberLength = 0 And vMaxRoomNumberLength > 0 And StrLen(cardcode) > vMaxRoomNumberLength) Then
				vIsCloseToTheFolio = True;
			EndIf;
		EndIf;
		vPaymentMethod = cmGetObjectRefByExternalSystemCode(vHotel, vExternalSystemCode, "PaymentMethods", vPayRow.paymentmethodcode);
		
		If Not vIsCloseToTheRoom And Not vIsCloseToTheFolio And ValueIsFilled(vPaymentMethod) Then
				vIsCloseToTheRoom  = vPaymentMethod.IsCloseToTheRoom;
				vIsCloseToTheFolio = vPaymentMethod.IsCloseToTheFolio;
				vIsByGiftCertificate = vPaymentMethod.IsByGiftCertificate;
				vIsByBonuses = vPaymentMethod.IsByBonuses;
		EndIf;
		
		vPaySum = vPayRow.sum; 				

		If vIsCloseToTheRoom Then
			vNonFiscalPayments = vNonFiscalPayments + 1;
			xdtoClient.Room = cardcode;
		ElsIf vIsCloseToTheFolio Then
			vNonFiscalPayments = vNonFiscalPayments + 1;
			xdtoClient.FolioNumber = cardcode;
		ElsIf vIsByGiftCertificate OR vIsByBonuses Then
			vNonFiscalPayments = vNonFiscalPayments + 1;
			xdtoClient.Card = cardcode;
			
			pay.PaymentMethod = vPayRow.paymentmethodcode;
			
			pay.Currency = TrimAll(vHotel.FolioCurrency);
			pay.PaymentExternalCode = vPayRow.uni;
			xdtoOrderPaymentMethods.OrderPaymentMethod.Add(pay);
			pay.Sum = vPaySum; 
			vTotalPaymentSum = vTotalPaymentSum + vPaySum;
		ElsIf Not ValueIsFilled(vPaymentMethod) And ValueIsFilled(cardcode) Then
			// It's close to the card folio - fill the card in the order and don't need to make a payment transaction
			xdtoClient.Card = cardcode;
			vNonFiscalPayments = vNonFiscalPayments + 1;
			vTotalPaymentSum = vTotalPaymentSum + vPaySum;
		Else
			pay.PaymentMethod = vPayRow.paymentmethodcode;
			pay.Sum = vPaySum; 
			pay.Currency = TrimAll(vHotel.FolioCurrency);
			pay.PaymentExternalCode = vPayRow.uni;
			xdtoOrderPaymentMethods.OrderPaymentMethod.Add(pay);
			
			vTotalPaymentSum = vTotalPaymentSum + vPaySum;
		EndIf;
	EndDo;
	xdtoOrder.Sum = vTotalOrderSum;
	xdtoOrder.Quantity = 1;
	vSkipInterface = False;
	
	If xdtoClient.Room = Undefined And xdtoClient.FolioNumber = Undefined And xdtoClient.Card = Undefined Then
		If Not IsBlankString(cardcode) Then
			xdtoClient.Card = cardcode;
		ElsIf Not IsBlankString(interface_id) Then
			// It's paid reciept for statistics
			vPaymentMethod = cmGetObjectRefByExternalSystemCode(vHotel, vExternalSystemCode, "PaymentMethods", interface_id);
			If vPaymentMethod <> Undefined And vPaymentMethod.IsCloseToTheFolio Then
				xdtoClient.FolioNumber = GetFolioNumber(vHotel, vExternalSystemCode, shiftdate, xdtoOrder.Service, xdtoSource.POS);
				vSkipInterface = False;
			Else
				vErrorDescription = NStr("en = 'Skip interface for load'; de = 'Schnittstelle zum laden überspringen'; ru = 'Этот интерфейс не загружается'");
				vSkipInterface = True;
			EndIf;
		Else
			vErrorDescription = NStr("en = 'Card not found'; de = 'Karte nicht gefunden'; ru = 'Карта не определена'");
		EndIf;		
	EndIf;
	xdtoOrder.OrderItems = xdtoOrderItems;
	xdtoPayment.OrderPaymentMethods = xdtoOrderPaymentMethods;
	xdtoPayment.PaymentRemarks = checknum;
	xdtoOrder.Payment = xdtoPayment;
	
	If vNonFiscalPayments > 1 Then
		// We can combine only one payment to the room or to the folio or to a card 
		// with fiscal payments like cash and credit card
		vErrorDescription = NStr("en = 'Multiple payment methods can not be combined.'; de = 'Mehrere Zahlungsmethoden können nicht kombiniert werden.'; ru = 'Нельзя комбинировать несколько вариантов оплаты.'");;
	EndIf;
	
	If IsBlankString(vErrorDescription) And (chmode = "1" OR chmode = "3") Then
		// Chmode - 1 = payment, other values have to be ignored
		retOrder = cmWritePOSOrder(xdtoClient, xdtoOrder, xdtoSource);
		If IsBlankString(retOrder.Error) Then
			// Close the shift id if shiftnumber has chanaged
			Try
				cmCheckAndClosePOSShift(xdtoSource.POS, shiftdate, shiftnum, xdtoOrder.OrderDate, xdtoOrder.Hotel, vExternalSystemCode);
			Except
				vErrorDescription = cmGetRootErrorDescription(ErrorInfo());
			EndTry;
		EndIf;
		vErrorDescription = retOrder.Error;
	Endif;
	
	xmlResponse = New XMLWriter;
	vXMLWriterSettings = New XMLWriterSettings("UTF-8", "1.0", False, False);
	
	xmlResponse.SetString(vXMLWriterSettings);
	xmlResponse.WriteXMLDeclaration();
	xmlResponse.WriteStartElement("Root");
	xmlResponse.WriteStartElement("TransactionsEx");
	xmlResponse.WriteAttribute("Result", ?(IsBlankString(vErrorDescription), "0", ?(vSkipInterface, "0", "1")));
	xmlResponse.WriteEndElement();
	xmlResponse.WriteStartElement("OutBuf");
	xmlResponse.WriteAttribute("OutKind", "1");
	xmlResponse.WriteStartElement("TRRESPONSE");
	xmlResponse.WriteAttribute("OutKind", "1"); 
	xmlResponse.WriteAttribute("error_code", ?(IsBlankString(vErrorDescription), "0", ?(vSkipInterface,"0","1")));
	xmlResponse.WriteAttribute("error_text", vErrorDescription);
	xmlResponse.WriteEndElement(); // TRRESPONSE
	xmlResponse.WriteEndElement(); // OutBuf
	xmlResponse.WriteEndElement(); // ROOT
	
	vResponseXML = xmlResponse.Close();
	vResponse.Headers = GetHeaders(StrLen(vResponseXML), "text/xml");
	vResponse.SetBodyFromString(vResponseXML);
	
	If Not IsBlankString(vErrorDescription) Then
		vMsg = NStr("en = 'Error'; de = 'Fehler'; ru = 'Ошибка'");
	EndIf;
	If vWriteDebug Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, vFuncLog, Enums.ExternalSystemEventTypes.Info, vRequestBody,vResponseXML , vMsg, vInteraction.MaxLogLenght, vUUID, vTimestamp);
	Else
		WriteLogEvent(vFuncLog, EventLogLevel.Note, , , vResponseXML);
	EndIf;
	
	Return vResponse;
EndFunction // TransactionsExPOST

// --------------------------------------------------------------------------------
Function LicenseInfoPOST(pRequest)
	vResponse = New HTTPServiceResponse(200);
	vRequestBody = pRequest.GetBodyAsString();
	// Log request
	WriteLogEvent("FarCard.LicenseInfoPOST", EventLogLevel.Note, , , vRequestBody);
	
	vResponseXML = "";	
	vResponse.Headers = GetHeaders(StrLen(vResponseXML), "text/xml");
	vResponse.SetBodyFromString(vResponseXML);
	
	Return vResponse;
EndFunction // LicenseInfoPOST

// --------------------------------------------------------------------------------
Function GetCardInfoExGET(Request)
	
	vResponseBody = "<html><head><title>GetCardInfoExGET</title></head><body>";
	vResponseBody = vResponseBody + "<p>" + SessionParameters.CurrentHotel + "</p>";
	vResponseBody = vResponseBody + "<p>" + SessionParameters.CurrentUser + "</p>
	|<p>" + ComputerName() + "</p>
	|<p>" + SessionTimeZone() + "</p>
	|<p>" + InfoBaseConnectionString() + "</p>";
	vResponseBody = vResponseBody + "<p>OK</p>";
	
	Response = New HTTPServiceResponse(200);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString(vResponseBody);
	Return Response;
	
EndFunction // GetCardInfoExGET

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetNumberNoPrefix(pStrNumber)
	// It has to be digits only for account number
	// so we jave to get rid if char prefix
	vNum = TrimAll(pStrNumber);
	vInt = StrLen(vNum);
	While vInt > 0 Do
		vChar = Mid(vNum, vInt, 1);
		If vChar = "0" Or vChar = "1" Or vChar = "2" Or vChar = "3" Or vChar = "4" Or
			vChar = "5" Or vChar = "6" Or vChar = "7" Or vChar = "8" Or vChar = "9" Then
			vNumStr = vChar + vNumStr;
		Else
			vPrefixStr = Left(vNum, vInt);
			Break;
		EndIf;
		vInt = vInt - 1; 
	EndDo;
	If Not IsBlankString(vNumStr) Then
		Return vNumStr;
	Else
		Return "0";
	EndIf;
EndFunction // GetNumberNoPrefix

// --------------------------------------------------------------------------------
Function GetHeaders(pLength = 0, pContentType = "text/xml")
	vHeaders = New Map;
	vHeaders.Insert("Date", Format(CurrentDate(), "DF='dd.MMM.yyyy HH:mm:ss'"));
	If pLength > 0 Then
		vHeaders.Insert("Content-Length", pLength);
	EndIf;	
	vHeaders.Insert("Keep-Alive", "timeout=5, max=100");
	vHeaders.Insert("Connection", "Keep-Alive");
	vHeaders.Insert("Content-Type", pContentType);
	Return vHeaders;
EndFunction // GetHeaders

// --------------------------------------------------------------------------------
Function GetFolioNumber(pHotel, pExternalSystemCode, pShiftdate, pService, pPOS)
	// Try to find folio by description. 
	// We will have one folio for all reciepts for one shift date and staion code from r-keeper
	vFolioDescription = "" + pShiftdate + NStr("en=' - order from r-keeper ';ru=' - Загрузка из r-keeper ';de=' - Laden aus r-keeper '") + "(" + TrimAll(pService) + "/" + TrimAll(pPOS) + ")";
	
	vQ = New Query("SELECT
	               |	Folio.Ref AS Ref,
	               |	Folio.Number AS FolioNumber
	               |FROM
	               |	Document.Folio AS Folio
	               |WHERE
	               |	Folio.Description = &qDescription
	               |	AND Folio.Hotel = &qHotel
	               |	AND NOT Folio.IsClosed
	               |	AND NOT Folio.DeletionMark");
	vQ.SetParameter("qDescription", vFolioDescription);
	vQ.SetParameter("qHotel", pHotel);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.FolioNumber;
	Endif;
	
	// Folio not found  - create new one
	vCashRegister = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "CashRegisters", pPOS);
	vCompany = pHotel.Company;
	
	If ValueIsFilled(vCashRegister) Then
		vCompany = vCashRegister.Owner;
	Endif;
	
	vDateFrom = GetShiftDate(pShiftdate,pHotel);
	
	vFolioObj = Documents.Folio.CreateDocument();
	vFolioObj.pmFillAttributesWithDefaultValues();
	vFolioObj.Company = vCompany;
	vFolioObj.Date = CurrentSessionDate();
	vFolioObj.DateTimeFrom = BegOfDay(vDateFrom);
	vFolioObj.DateTimeTo = EndOfDay(vDateFrom);
	vFolioObj.Description = vFolioDescription;
	vFolioObj.Customer = cmGetObjectRefByExternalSystemCode(pHotel, pExternalSystemCode, "Customers", pPOS);
	If ValueIsFilled(vFolioObj.Customer) Then
		vFolioObj.Contract = vFolioObj.Customer.Contract;
	EndIf;
	vFolioObj.Write();
	
	Return vFolioObj.Number;
EndFunction // GetFolioNumber

// --------------------------------------------------------------------------------
//  Parse date and return as date
//  in case date cannot be parsed - return current hotel accounting date
//  shiftdate="2020-10-07"
//
// Parameters:
//  pDateStr - String - Date as string
//  pHotel	 - CatalogRef.Hotels - Ref
// 
// Returns:
//  Date - AccountingDate
//
Function GetShiftDate(pDateStr, pHotel)
	Try
		If Not IsBlankString(pDateStr) And StrLen(pDateStr)= 10 Then
			vYear = Left(pDateStr, 4);
			vMonth = Mid(pDateStr, 6, 2);
			vDay = Mid(pDateStr, 9, 2);
			Return Date(Number(vYear), Number(vMonth), Number(vDay), 0, 0, 0);
		ElsIf ValueIsFilled(pHotel) Then
			Return pHotel.AccountingDate;
		Else
			Return '00010101';
		EndIf;
	Except
		If ValueIsFilled(pHotel) Then
			Return pHotel.AccountingDate;
		Else
			Return '00010101';
		EndIf;
	EndTry;		
EndFunction // GetShiftDate

#EndRegion
