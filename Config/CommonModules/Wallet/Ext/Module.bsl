
#Region Public

// --------------------------------------------------------------------------------
//  Creates card and returns URL for client
//
// Parameters:
//  pExtSystem	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  pCardOwner	 - Object								 - card owner which can be loaylty card or reservatrion document
// 
// Returns:
//  Structure - Structure with card description or error description
//
Function CreateCard(pExtSystem, pCardOwner) Export
	
	vRetStruct = GetCardReturnStruct();
	
	vResponse = GetProject(pExtSystem);
	
	If Not vResponse.Success Then
		
		vRetStruct.ErrorDescription = vResponse.ErrorDescription;					
		
		Return vRetStruct;	
		
	EndIf;
	
	Try
		
		vRequestParameters = GetQueryNewCard(pCardOwner,pExtSystem);
		
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vRequestParameters);
				
		vHeaders  = New Map;
		vHeaders.Вставить("X-Client-Id"    , pExtSystem.OAuth_AccessToken);
		vHeaders.Вставить("X-Client-Secret", pExtSystem.OAuth_ClientSecret);

		
		
		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExtSystem,vHeaders , "/v1/passes", "POST", , vRequestBody, "JSON", , , , , , , , False);
		vResponseParameters = Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		
	Except
		
		vRetStruct.ErrorDescription = "Wallet: " + ОписаниеОшибки();	
		
		Return vRetStruct;
		
	EndTry;
	

	If vResponse.StatusCode = 201 Then
		
		vRetStruct.success = True;
		vRetStruct.data   			 = vResponseParameters["data"];
		
		vRetStruct.CardSerialNumber  = vResponseParameters["data"]["serial_number"];
		vRetStruct.CardCode			 = vResponseParameters["data"]["pass_number"];		
		vRetStruct.URL   			 = vResponseParameters["data"]["link"];
		
		vRetStruct.DateCreated		= vResponseParameters["data"]["created_at"];
		vRetStruct.DateUpdated		= vResponseParameters["data"]["updated_at"];
		vRetStruct.CreatedVia		= vResponseParameters["data"]["created_via"];
		vRetStruct.ProjectID        = vResponseParameters["data"]["project_id"];
		vRetStruct.ExpirationDate   = vResponseParameters["data"]["expiration_date"];
		
		UpdateWalletCard(vRetStruct, pCardOwner);
		Return vRetStruct;
		
	Else
		
		vRetStruct.ErrorDescription = "Wallet: " + vResponseParameters["error"]["message"];
		Return vRetStruct;
		
	EndIf;
	
EndFunction

// --------------------------------------------------------------------------------
//  Updates card in the wallet system
//
// Parameters:
//  pExtSystem	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  pCardOwner	 - Object								 - card owner which can be loaylty card or reservatrion document
// 
// Returns:
//  Structure - Structure with card description or error description
//
Function UpdateCard(pExtSystem, pCardOwner) Export
	
	
	vRetStruct = GetCardReturnStruct();
	
	vWalletCard = GetWalletCard(pCardOwner);
	
	If Not ValueIsFilled(vWalletCard) Then
		
		vRetStruct.Success = False;
		vRetStruct.ErrorDescription = NStr("en = 'Wallet card found. Nothing to update.'; de = 'Wallet-Karte gefunden. Nichts zu aktualisieren.'; ru = 'Карта Wallet найдена. Нечего обновлять.'");
		
		Return vRetStruct;	
	EndIf;
	
	vResponse = GetProject(pExtSystem);
	
	If Not vResponse.Success Then
		
		vRetStruct.ErrorDescription = vResponse.ErrorDescription;					
		
		Return vRetStruct;	
		
	EndIf;
	
	Try
		
		vRequestParameters = GetQueryUpdateCard(pCardOwner,pExtSystem);
		
		vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vRequestParameters);
				
		vHeaders  = New Map;
		vHeaders.Вставить("X-Client-Id"    , pExtSystem.OAuth_AccessToken);
		vHeaders.Вставить("X-Client-Secret", pExtSystem.OAuth_ClientSecret);

		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExtSystem, vHeaders , "/v1/passes/" + vWalletCard.Code, "PATCH", , vRequestBody, "JSON", , , , , , , , False);
		
		vResponseParameters = Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		
	Except
		
		vRetStruct.ErrorDescription = "Wallet: " + ErrorDescription();	
		
		Return vRetStruct;
		
	EndTry;
	

	If vResponse.StatusCode = 200 Then
		
		vRetStruct.success = True;
		
		Return vRetStruct;
	Else
		
		vRetStruct.ErrorDescription = "Wallet: " + vResponseParameters["error"]["message"];
		Return vRetStruct;
		
	EndIf;
	
EndFunction

// --------------------------------------------------------------------------------
//  Returns URL for card. If card is not created - makes it and return URL for the new card
//
// Parameters:
//  pExtSystem	 - CatalogRef.ExternalSystemInteractions - External system interaction
//  pRef		 - AnyRef								 - ef to the object (Discount card, Reservation, Resource reservatio, Accommodation)
// 
// Returns:
//  String - URL for card
//
Function GetWalletURL(pExtSystem, pRef) Export
	// Get wallet card or create new
	Try
		vWC = Wallet.GetWalletCard(pRef);
		If vWC = Undefined Then
			vResWC = Wallet.CreateCard(pExtSystem, pRef);
			Return vResWC.URL;
		Else
			Return vWC.URL;
		EndIf;
	Except
		// In case of error just return empty ctring in order not to stop further processing
		Return "";
	EndTry;
EndFunction // GetWalletURL

// --------------------------------------------------------------------------------
//  Returns a wallet card connected with the owner
//
// Parameters:
//  pCardOwner	 - CatalogRef.WalletCards	 - reference to owner - could be discount card or reservation
// 
// Returns:
//  CatalogRef.WalletCards - wallet card ref
//
Function GetWalletCard(pCardOwner) Export
	
	vQ = New Query("SELECT
	               |	WalletCards.Ref AS Ref
	               |FROM
	               |	Catalog.WalletCards AS WalletCards
	               |WHERE
	               |	WalletCards.CardOwner = &qCardOwner");
	
	vQ.SetParameter("qCardOwner",pCardOwner);
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.Ref;
	EndIf;
	
	Return Undefined;

EndFunction

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetQueryNewCard(pCardOwner, pExtSystem)
	
	newCard = New Structure("project_id, fields", pExtSystem.InteractionID);
	
	updateCard = New Structure("first_name, last_name");
	// Loyalty cards
	If TypeOf(pCardOwner) = Type("CatalogRef.DiscountCards") Then
		If ValueIsFilled(pCardOwner.Client) Then
		
			updateCard.first_name = pCardOwner.Client.FirstName;
			updateCard.last_name  = pCardOwner.Client.LastName;
			updateCard.Insert("birthdate", Format(pCardOwner.Client.DateOfBirth, "DF=yyyy-MM-dd"));
			updateCard.Insert("email", pCardOwner.Client.Email);
			If Not IsBlankString(pCardOwner.Client.Phone) Then
				updateCard.Insert("phone_number", ?(Left(pCardOwner.Client.Phone,1) = "+", pCardOwner.Client.Phone, "+" + pCardOwner.Client.Phone));		
			Endif;
		Endif;
		If pCardOwner.LoyaltyType = Enums.LoyaltyType.Bonuses Or pCardOwner.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vBonuses = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pCardOwner);
			updateCard.Insert("bonuses", Format(vBonuses.Balance, "ND=12; NFD=0; NG="));
		Endif;
	ElsIf TypeOf(pCardOwner) = Type("DocumentRef.Reservation") Then
		// Reservation
		If ValueIsFilled(pCardOwner.Guest) Then

			vLang = pCardOwner.Guest.Language;
			
			updateCard.Insert("guest_group", pCardOwner.GuestGroup);
			updateCard.Insert("reservation_number", pCardOwner.Number);
			
			updateCard.Insert("qr_code", pCardOwner.UUID());
			
			updateCard.Insert("check_in", Format(pCardOwner.CheckInDate, "DF='dd.MM.yyyy HH:mm'"));
			updateCard.Insert("check_out", Format(pCardOwner.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			updateCard.Insert("period", cmShortPeriodPresentation(pCardOwner.CheckInDate, pCardOwner.CheckOutDate));
			
			
			updateCard.Insert("reservation_status", cmGetObjectExternalSystemCodeByRef(pCardOwner.Hotel, pExtSystem.Code, "ReservationStatuses",pCardOwner.ReservationStatus));
			
			updateCard.Insert("adults", pCardOwner.NumberOfAdults);
			updateCard.Insert("kids", pCardOwner.NumberOfChildren+pCardOwner.NumberOfTeenagers + pCardOwner.NumberOfInfants);
			
			updateCard.Insert("room_type", ?(ValueIsFilled(pCardOwner.RoomType), pCardOwner.RoomType.GetObject().pmGetRoomTypeDescription(vLang), ""));
			updateCard.Insert("room", pCardOwner.Room);
			
			
			
			updateCard.Insert("room_rate", pCardOwner.RoomRate.ReservationConditionsShort);
			updateCard.Insert("room_rate_description", pCardOwner.RoomRate.ReservationConditionsOnline);
			vLang = pCardOwner.Hotel.Language;
						
			// URLs
			
			balance = 0;
			payment_status = cmNStr("en = 'Expecting payment'; de = 'Nicht bezalt'; ru = 'Ожидает оплаты'", vLang);
			vTotalAmount = 1;
			If balance = 0 Then
				payment_status = cmNStr("en = 'Paid'; de = 'Bezahlt'; ru = 'Оплачено'", vLang);
			ElsIf balance < vTotalAmount Then
				payment_status = cmNStr("en = 'Deposit'; de = 'Deposit'; ru = 'Внесена предоплата'", vLang);
			EndIf;
			updateCard.Insert("payment_status", payment_status);
			updateCard.Insert("balance", balance);

			
			room_status = "";
			If ValueIsFilled(pCardOwner.Room) AND 
				ValueIsFilled(pCardOwner.Room.RoomStatus) AND 
				pCardOwner.Room.RoomStatus.RoomIsVacantClear AND
				BegOfDay(CurrentSessionDate()) = BegOfDay(pCardOwner.CheckInDate) Then
				// Room status to be seen only on the day of the arrival
				room_status = cmNStr("en = 'Room is ready'; de = 'Zimmer ist'; ru = 'Номер готов'", vLang);
			EndIf;
			
			updateCard.Insert("room_status", room_status);
			
			updateCard.first_name = pCardOwner.Guest.FirstName;
			updateCard.last_name  = pCardOwner.Guest.LastName;
			updateCard.Insert("birthdate", Format(pCardOwner.Guest.DateOfBirth, "DF=yyyy-MM-dd"));
			updateCard.Insert("email", pCardOwner.Guest.Email);
				
			updateCard.Insert("hotel", Catalogs.Hotels.pmGetHotelPrintName(pCardOwner.Hotel, vLang));
			updateCard.Insert("address", cmNStr(pCardOwner.Hotel.HowToDriveToTheHotelTranslations, vLang));
			
			vIntegration = Undefined;
			reservation_url = Catalogs.ExternalSystemInteractions.GetReservationGuestURL(pCardOwner, vIntegration);
			
			updateCard.Insert("reservation_url", reservation_url);

		EndIf;

	ElsIf TypeOf(pCardOwner) = Type("DocumentRef.Accommodation") Then
		// Accommodation
	EndIf;
		
	newCard.fields = updateCard;
	
	Return newCard;
	
EndFunction

// --------------------------------------------------------------------------------
Function GetQueryUpdateCard(pCardOwner, pExtSystem)
	
	updateCard = New Structure("first_name, last_name");
	If TypeOf(pCardOwner) = Type("CatalogRef.DiscountCards") Then
		If ValueIsFilled(pCardOwner.Client) Then
		
			updateCard.first_name = pCardOwner.Client.FirstName;
			updateCard.last_name  = pCardOwner.Client.LastName;
			updateCard.Insert("birthdate", Format(pCardOwner.Client.DateOfBirth, "DF=yyyy-MM-dd"));
			updateCard.Insert("email", pCardOwner.Client.Email);
			If Not IsBlankString(pCardOwner.Client.Phone) Then
				updateCard.Insert("phone_number", ?(Left(pCardOwner.Client.Phone, 1) = "+", pCardOwner.Client.Phone, "+" + pCardOwner.Client.Phone));		
			Endif;
		Endif;
		If pCardOwner.LoyaltyType = Enums.LoyaltyType.Bonuses Or pCardOwner.LoyaltyType = Enums.LoyaltyType.Certificate Then
			vBonuses = AccumulationRegisters.Bonuses.mmGetBalanceByCard(pCardOwner);
			updateCard.Insert("bonuses", Format(vBonuses.Balance, "ND=12; NFD=0; NG="));
		Endif;
	EndIf;
		
	Return updateCard;
	
EndFunction

// --------------------------------------------------------------------------------
Procedure UpdateWalletCard(pCardStruct, pCardOwner)
	
	vQ = New Query("SELECT
	               |	WalletCards.Ref AS Ref
	               |FROM
	               |	Catalog.WalletCards AS WalletCards
	               |WHERE
	               |	WalletCards.Code = &qSerialNumber");
	vQ.SetParameter("qSerialNumber",pCardStruct.CardSerialNumber);
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		vWCard = qRes.Ref.GetObject();
	Else
		vWCard = Catalogs.WalletCards.CreateItem();
		vWCard.Code = pCardStruct.CardSerialNumber;
		vWCard.Description = pCardStruct.CardCode;		
	EndIf;
	
	FillPropertyValues(vWCard,pCardStruct);
	
	vWCard.CardOwner = pCardOwner;
	vWCard.Write();	
		
EndProcedure

// --------------------------------------------------------------------------------
Function GetCardReturnStruct()
	
	vStruct =  New Structure("CardCode, CardSerialNumber, ErrorDescription, URL, status, id, data, DateCreated, DateUpdated, СreatedVia, ProjectID, ExpirationDate, IsInstalled, DeviceId, DeviceOS");
	
	vStruct.Insert("success", False);
	vStruct.Insert("SyncPhone", True);
	
	Return vStruct;
EndFunction

// --------------------------------------------------------------------------------
Function GetProject(pExtSystem)
	
	vRet = GetCardReturnStruct();
	
	vProjectID = TrimAll(pExtSystem.InteractionID);
	Try	
		vHeaders  = New Map;
		vHeaders.Вставить("X-Client-Id"    , pExtSystem.OAuth_AccessToken);
		vHeaders.Вставить("X-Client-Secret", pExtSystem.OAuth_ClientSecret);

		vResponse 		= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pExtSystem, vHeaders, "/v1/projects/" + vProjectID, "GET", , , , , , , , , , , False);
		vResponseParameters = Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);

	Except	
		
		vRet.ErrorDescription = "Wallet: " + ErrorDescription();
		
		Return vRet;
		
	EndTry;
	
	
	If vResponse.StatusCode = 200 Then
			
		vRet.Success = True;
		vRet.data	 = vResponseParameters.data;
		
		Return vRet;
		
	Else
		If ValueIsFilled(vResponseParameters) Then
			vRet.ErrorDescription = vResponseParameters.error.message;
		Else
			vRet.ErrorDescription = vResponse.Error;
		EndIf;
		
		Return vRet;
		
	EndIf;		
	
EndFunction

#EndRegion
