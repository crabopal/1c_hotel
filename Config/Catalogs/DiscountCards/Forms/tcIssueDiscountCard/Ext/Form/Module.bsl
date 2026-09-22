
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") Then   
		Hotel = Parameters.Hotel;
	EndIf;	 
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If Parameters.Property("Client") Then   
		Client = Parameters.Client;
	EndIf;	 
	If Parameters.Property("DiscountCard") Then   
		ParentDiscountCard = Parameters.DiscountCard;
	EndIf;
	If Parameters.Property("LoyaltyProgram") Then   
		LoyaltyProgram = Parameters.LoyaltyProgram;
	EndIf;
	If Not ValueIsFilled(LoyaltyProgram) Then
		If ValueIsFilled(Hotel) And ValueIsFilled(Hotel.LoyaltyProgram) Then
			LoyaltyProgram = Hotel.LoyaltyProgram;
		EndIf;
	EndIf;
	If ValueIsFilled(LoyaltyProgram) Then
		LoyaltyType = LoyaltyProgram.LoyaltyType;
		If LoyaltyProgram.IsFolder Then
			DiscountType = LoyaltyProgram.StartLevelOfLoyaltyProgram;
		Else
			DiscountType = LoyaltyProgram;
		EndIf;
	EndIf;
	OperationType = "NEW"; 
	FillPresentation();
	If ValueIsFilled(LoyaltyType) Then
		Items.LoyaltyType.ReadOnly = True;
		CurrentItem = Items.DiscountType;
	EndIf;
	If ValueIsFilled(DiscountType) Then
		CurrentItem = Items.Client;
	EndIf;
	If ValueIsFilled(Client) Then
		CurrentItem = Items.Phone;
	EndIf;
EndProcedure

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
		Identifier = GetCardIDPresantation(vEventData.DeviceData, ExternalInteraction);
		RegisterNewDiscountCard();
		If IsBlankString(LabelNotification) Then
			Notify("Catalog.DiscountCards.Changed", Client);
			Close();
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes) 
	If ValueIsFilled(DiscountType) Then
		If DiscountType.NumberingRule = 0 Then  
			pCheckedAttributes.Add("Phone");   
			vInd = pCheckedAttributes.Find("Identifier");  
			If vInd <> Undefined Then
				pCheckedAttributes.Delete(vInd);	
			EndIf;	
			Identifier = Phone;
		EndIf;	
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure DiscountTypeOnChange(pItem)
	DiscountTypeOnChangeAtServer();
	
	FillPresentation();
EndProcedure

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetExternalSystemByDiscountType(pDiscountType)
	vExternalSystem = Undefined;
	
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(vHotel) Then
		vQ = New Query;
		vQ.Text =
		"SELECT
		|	ExternalSystemIntegrationData.ExternalSystem AS ExternalSystem
		|FROM
		|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
		|WHERE
		|	ExternalSystemIntegrationData.RefKey1 = &qDiscountType
		|	AND ExternalSystemIntegrationData.DataType = ""DiscountTypes""
		|	AND ExternalSystemIntegrationData.ExternalSystem.Hotel = &qHotel";
		
		vQ.SetParameter("qDiscountType", pDiscountType);
		vQ.SetParameter("qHotel", vHotel);
		vResult = vQ.Execute().Unload();
		
		For Each vExternalSystemRow In vResult Do
			vExternalSystem = vExternalSystemRow.ExternalSystem;
			Break;
		EndDo;
		
		If Not ValueIsFilled(vExternalSystem) Then
			vParameters = New Array;
			vParameters.Add(New Structure("Name, Value, OR", "DiscountType", pDiscountType, False)); 
			vParameters.Add(New Structure("Name, Value, OR", "Hotel", vHotel, False));
			vExternalSystem = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByParameters(vParameters);
		EndIf; 
	EndIf;
	Return vExternalSystem;	
EndFunction // GetExternalSystemByDiscountType

// -----------------------------------------------------------------------------
&AtClient
Procedure OperationTypeOnChange(Item)
	FillPresentation();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ClientOnChange(pItem)
	If ValueIsFilled(Client) Then
		Phone = tcOnServer.cmGetAttributeByRef(Client, "Phone");
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure PhoneOnChange(pItem)
	PhoneOnChangeAtServer();
EndProcedure // PhoneOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Create(pCommand)
	If CheckFilling() Then    
		vNewCard = Undefined;
		RegisterNewDiscountCard(vNewCard);
		If IsBlankString(LabelNotification) Then
			Notify("Catalog.DiscountCards.Changed", Client, vNewCard);
			Close();
		EndIf;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	GenerateVirtualIdentifier();
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure FillPresentation()  
	Items.GiftID.Visible = False;
	If ValueIsFilled(ExternalInteraction) And ExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		Items.OperationType.Visible = True; 
		Items.Generate.Visible = True;  
		If OperationType = "OLD" Then
			Items.Identifier.ReadOnly = False;  
			Items.Generate.Enabled = False;  
		Else	                             
			Items.Identifier.ReadOnly = True;  
			Items.Generate.Enabled = True;
		EndIf;
		If OperationType = "ADD" Then
			Items.SelDiscountCard.Visible = True; 
		Else
			Items.SelDiscountCard.Visible = False;
		EndIf;	
	Else   
		Items.Generate.Visible = False;
		Items.OperationType.Visible = False; 
		Items.Identifier.ReadOnly = False;
		Items.LabelNotification.Visible = False; 
		Items.SelDiscountCard.Visible = False;  
	EndIf;
	If ValueIsFilled(DiscountType) Then
		If DiscountType.NumberingRule = 0 Or DiscountType.LoyaltyType = Enums.LoyaltyType.Certificate Then  
			Items.Identifier.Visible = False;   
			Items.Decoration1.Visible = False;
		Else
			Items.Identifier.Visible = True;  
			Items.Decoration1.Visible = True;
		EndIf;	
		If DiscountType.LoyaltyType = Enums.LoyaltyType.Certificate Then
			Items.GiftID.Visible = True;   
			If DiscountType.NumberingRule = 1 Then 
				vLastID = Catalogs.DiscountCards.GetLastGiftID(DiscountType);
				If cmIsNumber(vLastID) Then
					Identifier = Format(Number(vLastID) + 1, "NG=0");  
				EndIf;	
			EndIf;
		EndIf;	
	Else
		Items.Identifier.Visible = False; 
		Items.Decoration1.Visible = False;
	EndIf;	
EndProcedure		

// -----------------------------------------------------------------------------
&AtServer
Procedure DiscountTypeOnChangeAtServer()
	If ValueIsFilled(DiscountType) And DiscountType.ExternalBonusSystemIsUsed Then
		ExternalInteraction = DiscountType.ExternalInteraction;
		If Not ValueIsFilled(ExternalInteraction) Then
			If ValueIsFilled(Client.DiscountCard) Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The client has already assigned a card';
																|de = 'Der Kunde hat bereits eine Karte zugewiesen';
																|ru = 'У клиента уже назначена карта'"));
				Return;	
			EndIf;
			If Client.RefusedToParticipateInLoyaltyProgram Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The client refused to participate in the loyalty program';
																|de = 'Der Kunde weigerte sich, am Treueprogramm teilzunehmen';
																|ru = 'Клиент отказался от участия в программе лояльности'"));
				Return;
			EndIf;
			ExternalInteraction = GetExternalSystemByDiscountType(DiscountType);
		EndIf;
	Else
		ExternalInteraction = Undefined;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------   
&AtServer
Procedure RegisterNewDiscountCard(rNewCard = Undefined)
	If IsBlankString(Identifier) Then
		Return;
	EndIf;   
	LabelNotification = "";
	rNewCard = Undefined;
	// Try to search discount card with this Id
	vDiscountCard = cmGetDiscountCardById(TrimAll(Identifier));
	If ValueIsFilled(vDiscountCard) And vDiscountCard.Client <> Client Then
		LabelNotification = NStr("en = 'This card is already registered!'; de = 'Diese Karte ist bereits registriert!'; ru = 'Эта карта уже зарегистрирована!'") + " " + String(vDiscountCard);
		Items.LabelNotification.Visible = True;
		Return;
	EndIf;  
	// Update data from ISD
	If ValueIsFilled(ExternalInteraction) And ExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		// Call ISD for add new card
		If Not IssueISD() Then 
			Return;
		EndIf;  
		// Fill card params from ISD
		UpdateCardDataFromISD(vDiscountCard);  
	Else
		// Add    
		vObjCard = Undefined;
		CreateCard(vDiscountCard, vObjCard);  
		If vObjCard <> Undefined Then
			rNewCard = vObjCard.Ref;
		EndIf;	
		// Link card to the client profile
		If OperationType = "NEW" And ValueIsFilled(LoyaltyProgram) And Not LoyaltyProgram.RequirePresentationOfDiscountCardUponCheckIn Then
			If ValueIsFilled(Client) And ValueIsFilled(rNewCard) Then
				vClientObj = Client.GetObject();
				vClientObj.DiscountCard = rNewCard;
				vClientObj.Write();
				vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf;
		EndIf;
	EndIf; 
EndProcedure

// -----------------------------------------------------------------------------   
&AtServer
Procedure CreateCard(pDiscountCard, pDiscountCardObj = Undefined)
	If ValueIsFilled(pDiscountCard) Then
		pDiscountCardObj = pDiscountCard.GetObject();
	Else	
		pDiscountCardObj = Catalogs.DiscountCards.CreateItem();
	EndIf;
	pDiscountCardObj.Identifier = TrimAll(Identifier);
	pDiscountCardObj.Client = Client;           
	pDiscountCardObj.LoyaltyType = LoyaltyType;
	pDiscountCardObj.DiscountType = DiscountType;
	pDiscountCardObj.IsBlocked = False;
	pDiscountCardObj.Remarks = Remarks;  
	If Not IsBlankString(Phone) Then
		pDiscountCardObj.Phone = Phone; 
	EndIf;	
	If (OperationType = "ADD" Or OperationType = "OLD") And ValueIsFilled(ParentDiscountCard) Then   
		pDiscountCardObj.ParentDiscountCard = ParentDiscountCard;	
	EndIf;	
	pDiscountCardObj.Write();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UpdateCardDataFromISD(pDiscountCard)   
	vRes = CallCardInfo();
	If vRes.Success Then
		vCardChange = False;
		vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);  
		If OperationType = "OLD" Then   
			If TypeOf(vParams) = Type("Structure") And vParams.Property("tariff_id") Then 
				// check exist rate in mapping
				vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalInteraction, "BonusRates");  
				vFilter = vTariffs.FindRows(New Structure("ISDCodeOld", vParams.tariff_id));  
				If vTariffs.Count() = 0 Then
					LabelNotification = NStr("en = 'The tariff of the card does not correspond to the previously issued one!'; 
					|de = 'Der Tarif der Karte entspricht nicht dem zuvor ausgestellten!'; 
					|ru = 'Тариф карты не соответствует ранее выпущенной!'") ;
					Items.LabelNotification.Visible = True;
					Return;	
				EndIf;  
			Else
				LabelNotification = NStr("en = 'Card not found in ISD!'; de = 'Karte im ISD nicht gefunden!'; ru = 'Карта не найдена в ISD!'") ;
				Items.LabelNotification.Visible = True;
				Return;	
			EndIf;
		EndIf;  
		If Not OperationType = "NEW" Then  
			vLenId = 3;
			vMainCardID = TrimAll(vParams.main_bonus_tag);
			If Not IsBlankString(vMainCardID) And StrLen(vMainCardID) > vLenId Then  
				vMainCardID = GetCardIDPresantation(vMainCardID, ExternalInteraction);
				ParentDiscountCard = cmGetDiscountCardById(vMainCardID);
				If Not ValueIsFilled(ParentDiscountCard) Then
					LabelNotification = StrTemplate(NStr("en = 'The main card with tag %1 was not found in 1C:Hotel!'; 
					|de = 'Die Hauptkarte mit Tag %1 wurde in 1C:Hotel nicht gefunden!'; 
					|ru = 'Основная карта с тегом %1 не найдена в 1С:Отель!'"), vMainCardID);
					Items.LabelNotification.Visible = True;
					Return;	
				EndIf;	
			EndIf;	     
		EndIf;
		vDiscountCardObj = Undefined;
		// Add new card
		CreateCard(pDiscountCard, vDiscountCardObj);
        // update propery
		If vParams.Property("diskt_id") Then
			vDiscountType = Format(vParams.diskt_id, "NG=0"); 
			vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalInteraction, "BonusesCardTypes");  
			If vTariffs.Count() > 0 Then 
				vFilter = vTariffs.FindRows(New Structure("ISDCode", vDiscountType)); 	
				If vFilter.Count() > 0 Then   
					vDiscountTypeRef = ?(IsBlankString(vFilter[0].DiscountType), Undefined, Catalogs.DiscountTypes.GetRef(New UUID(vFilter[0].DiscountType)));	
				EndIf;	
			EndIf;	
		EndIf;            
		If ValueIsFilled(vDiscountTypeRef) Then
			vDiscountCardObj.DiscountType = vDiscountTypeRef;
			vCardChange = True;	
		EndIf;	
		If vParams.Property("client_phone") Then
			vDiscountCardObj.Phone = SMS.GetValidPhoneNumber(vParams.client_phone);
			vCardChange = True;
		EndIf; 
		If vParams.Property("release") Then
			vDiscountCardObj.ValidFrom = Date(vParams.release + ":00");    
			vCardChange = True;
		EndIf;
		If vParams.Property("validto") Then
			vDiscountCardObj.ValidTo = Date(vParams.validto + ":00");
			vCardChange = True;
		EndIf;  
		If vCardChange Then    
			vDiscountCardObj.Description = Catalogs.DiscountCards.GetCardDescription(vDiscountCardObj);
			vDiscountCardObj.Write();
		EndIf;	 
	Else
		LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		Items.LabelNotification.Visible = True;	
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------   
&AtServer
Function IssueISD()
	vAns = True;      
	If OperationType = "OLD" Then
		Return True;	
	EndIf;	
	If OperationType = "ADD" And Not ValueIsFilled(ParentDiscountCard) Then
		LabelNotification = NStr("en = 'Cannot issue extra. card without the main one!
                                  |In the list of cards, select the card and click ""New Loyalty Card""'; de = 'Extraausgabe nicht möglich. Karte ohne die Hauptkarte!
                                  |Wählen Sie in der Kartenliste die Karte aus und klicken Sie auf „Neue Treuekarte“.'; ru = 'Нельзя выдать доп. карту без основной!
                                  |В списке карт выделите основную карту и нажмите ""Новая карта лояльности""'");
		Items.LabelNotification.Visible = True;
		Return False;
	EndIf;	 
	If OperationType = "ADD" And IsBlankString(ParentDiscountCard.Identifier) Then
		LabelNotification = NStr("en = 'The main card has no ID!'; de = 'Die Hauptkarte hat keinen Ausweis!'; ru = 'У основной карты не указан идентификатор!'");
		Items.LabelNotification.Visible = True;
		Return False;
	EndIf;	
    If OperationType = "ADD" And ValueIsFilled(ParentDiscountCard.ParentDiscountCard) Then
		LabelNotification = NStr("en = 'It is not possible to issue an additional card on the basis of an additional card!'; 
								|de = 'Extraausgabe nicht möglich. Karte basierend auf Karten!'; 
								|ru = 'Нельзя выдать доп. карту на основании доп. карты!'");
		Items.LabelNotification.Visible = True;
		Return False;
	EndIf;	
	vTariff = GetTariff(ExternalInteraction, OperationType = "NEW"); 
	If IsBlankString(vTariff) Then
		LabelNotification = NStr("en = 'ISD tariff mapping not configured!'; de = 'ISD-Tarifzuordnung nicht konfiguriert!'; ru = 'Не настроен маппинг тарифов ISD!'");
		Items.LabelNotification.Visible = True;
		Return False;
	EndIf; 
	vKeyParams = GetISDTestCardParams(Identifier, vTariff);
	// Check card in ISD
	vRes = ISD.TestCard(ExternalInteraction, vKeyParams);
	If Not vRes.Success Then
		LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		Items.LabelNotification.Visible = True;
		Return False;	
	EndIf;	
	// Issue card in isd 
	vKeyParams = GetISDIssueBonusCardParams(Identifier, vTariff);
	vRes = ISD.IssueBonusCard(ExternalInteraction, vKeyParams);
	If Not vRes.Success Then
		LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		Items.LabelNotification.Visible = True;
		Return False;	
	EndIf;
	Return vAns;
EndFunction	// IssueISD

// -----------------------------------------------------------------------------   
&AtServer
Procedure GenerateVirtualIdentifier()
	vCardTemplate = "";    
	vCardTemplateBeginNumber = 1;
	vCardTemplates = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalInteraction, "CardTemplate");
	If vCardTemplates.Count() > 0 Then
		vCardTemplate = vCardTemplates[0].CardTemplate;   
		vCardTemplateBeginNumber = Number(vCardTemplates[0].CardTemplateBeginNumber);
	EndIf;
	If IsBlankString(vCardTemplate) Then
		LabelNotification = NStr("en = 'The template for virtual cards is not set!'; 
								 |de = 'Die Vorlage für virtuelle Karten ist nicht gesetzt!'; 
								 |ru = 'Шаблон для виртуальных карт не задан!'") ;
		Items.LabelNotification.Visible = True;
		Return;
	EndIf;	
	vLastID = "";
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	DiscountCards.Identifier AS Identifier
		|FROM
		|	Catalog.DiscountCards AS DiscountCards
		|WHERE
		|	DiscountCards.Identifier LIKE &qIdentifier
		|
		|ORDER BY
		|	Identifier DESC";
	
	vQuery.SetParameter("qIdentifier", vCardTemplate + "%");
	vQueryResult = vQuery.Execute();
	vRes = vQueryResult.Select();
	While vRes.Next() Do
		vLastID = vRes.Identifier;
		Break;
	EndDo;   
	Try
		If IsBlankString(vLastID) Then
			vID = vCardTemplateBeginNumber; 
		Else
			vID = Number(Right(vLastID, 5)); 
		EndIf;  
		If vID < vCardTemplateBeginNumber Then
			vID = vCardTemplateBeginNumber;
		EndIf;	
		vInd = 1;
		While vInd <= 100 Do
		    Identifier = vCardTemplate + Format(vID + vInd, "ND=5; NLZ=; NG=0");
			vRes = CallCardInfo();
			If vRes.Success Then
				vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);  
				If vParams.Property("tariff_id") Then
					vInd = vInd + 1; 
				Else
					Return;
				EndIf; 
			Else 
				If Not IsBlankString(vRes.RawResponse) Then
					vParams = Catalogs.DataConvertationRules.JSONtoStructure(vRes.RawResponse);  
					// Is replaced card
					If vParams.Property("actual_media_num") Then  
						vInd = vInd + 1;     
						Continue;
					EndIf;
				EndIf;
				LabelNotification = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
				Items.LabelNotification.Visible = True;	
	           	Return;
			EndIf;	
		EndDo;
		LabelNotification = NStr("en = 'Failed to generate virtual card number!'; 
								 |de = 'Virtuelle Kartennummer konnte nicht generiert werden!'; 
								 |ru = 'Нет свободных номеров!'") ;
		Items.LabelNotification.Visible = True;
		Return; 
	Except
		LabelNotification = NStr("en = 'Failed to generate virtual card number!'; 
								 |de = 'Virtuelle Kartennummer konnte nicht generiert werden!'; 
								 |ru = 'Не удалось сформировать виртуальный номер карты!'") ;
		Items.LabelNotification.Visible = True;
		Return; 
	EndTry;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIDPresantation(pID, pExternalInteraction)  
	If ValueIsFilled(pExternalInteraction) And pExternalInteraction.IntegrationType = Enums.Integrations.ISD Then 
		vID = pID;
		Try
			If Not StrLen(pID) = 20 Then
				vID =  Format(Number(GetBinaryDataBufferFromHexString(pID).ReadInt64(0, ByteOrder.BigEndian)), "NG=0");
			EndIf;	
		Except
		EndTry;
	EndIf;
	Return vID;
EndFunction // GetCardIDPresantation()

// -----------------------------------------------------------------------------
&AtServer
Function GetISDTestCardParams(pCardID, pRateCode) 
	vKeyParams = New Structure;   
	vKeyParams.Insert("media_num", pCardID);
	vKeyParams.Insert("tariff_id", pRateCode); 
	vKeyParams.Insert("pointsale", ISD.GetPSALID(ExternalInteraction));
	vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
	Return vKeyParams;
EndFunction

// -----------------------------------------------------------------------------
&AtServer
Function GetISDIssueBonusCardParams(pCardID, pRateCode)   
	vParentID = "";
	If OperationType = "ADD" Then
		vParentID = ParentDiscountCard.Identifier; 
	EndIf;	
	vKeyParams = New Structure();
	vKeyParams.Insert("cli_guid", 		XMLString(Client));
	vKeyParams.Insert("cli_first", 		TrimAll(Client.FirstName));
	vKeyParams.Insert("cli_last", 		TrimAll(Client.LastName));
	vKeyParams.Insert("cli_sur", 		TrimAll(Client.SecondName));
	vKeyParams.Insert("cli_birth", 		Format(Client.DateOfBirth, "DF=dd.MM.yyyy"));
	vKeyParams.Insert("cli_tel",   		TrimAll(Client.Phone));
	vKeyParams.Insert("dt_arrive", 		Format(Date(1, 1, 1), "DF=yyyy-MM-dd-HH-mm"));
	vKeyParams.Insert("dt_depart", 		Format(Date(1, 1, 1), "DF=yyyy-MM-dd-HH-mm"));
	vKeyParams.Insert("media_num", 		pCardID); 
	vKeyParams.Insert("bonus_media_num", vParentID);
	vKeyParams.Insert("tariff_id", 		pRateCode);
	vKeyParams.Insert("pointsale", 		ISD.GetPSALID(ExternalInteraction));
	vKeyParams.Insert("Workstation",  	String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", 			String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", 			String(SessionParameters.CurrentUser)); 		
	vKeyParams.Insert("park_id", 		"");
	vKeyParams.Insert("brand", 			"");
	vKeyParams.Insert("model", 			"");
	vKeyParams.Insert("plate", 			"");
	vKeyParams.Insert("kkm_regnum", 	"");
	vKeyParams.Insert("kkm_fnserial", 	"");
	vKeyParams.Insert("kkm_fiscdoc", 	"");
	vKeyParams.Insert("kkm_fpd",     	"");
	Return vKeyParams;
EndFunction

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetTariff(pExternalInteraction, pIsMain = True)
	vHotel = SessionParameters.CurrentHotel;
	vTariff = "";
	vTariffs = InformationRegisters.ExternalSystemIntegrationData.GetData(pExternalInteraction, "BonusRates");  
	If vTariffs.Count() > 0 Then
		// Try find by hotel
		vFilter = vTariffs.FindRows(New Structure("IsDefault, Hotel", pIsMain, vHotel)); 	
		If vFilter.Count() > 0 Then  
			vRow = vFilter[0];
			vTariff = vRow.ISDCode;
		Else
			vFilter = vTariffs.FindRows(New Structure("IsDefault", pIsMain)); 	
			If vFilter.Count() > 0 Then  
				vRow = vFilter[0];
				vTariff = vRow.ISDCode;
			EndIf;
		EndIf;
	EndIf;
	
	Return vTariff;
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Function CallCardInfo()
	Identifier = GetCardIDPresantation(Identifier, ExternalInteraction);
	vKeyParams = New Structure;   
	vKeyParams.Insert("media_num", Identifier);
	vKeyParams.Insert("pointsale", ISD.GetPSALID(ExternalInteraction));
	vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
	
	vRes = ISD.CardInfo(ExternalInteraction, vKeyParams);
	Return vRes;
EndFunction // UpdateCardDataFromISD

// -----------------------------------------------------------------------------
&AtServer
Procedure PhoneOnChangeAtServer()
	If Not IsBlankString(Phone) Then
		Phone = SMS.GetValidPhoneNumber(Phone);
		If Not ValueIsFilled(Client) Then
			vClient = cmGetClientByPhone(Phone);
			If ValueIsFilled(vClient) Then
				Client = vClient;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // PhoneOnChangeAtServer

#EndRegion
