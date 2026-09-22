#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Parameters
	IdentityCardSystemParameters = Undefined;
	If Parameters.Property("IdentityCardSystemParameters") Then
		IdentityCardSystemParameters = Parameters.IdentityCardSystemParameters;
		CardReaderType = IdentityCardSystemParameters. CardReaderType;
	EndIf;
	// Fill room
	Room = Undefined;
	If Parameters.Property("Room") Then
		Room = Parameters.Room;
	EndIf;
	// Fill hotel
	If Parameters.Property("Hotel") Then
		Hotel = Parameters.Hotel;
	EndIf;
	If Not ValueIsFilled(Hotel) And ValueIsFilled(Room) Then
		Hotel = Room.Owner;
	EndIf;	
	// Fill client
	Client = Undefined;
	If Parameters.Property("Client") Then
		Client = Parameters.Client;
	EndIf;
	// Fill check-in date
	CheckInDate = Undefined;
	If Parameters.Property("CheckInDate") Then
		CheckInDate = Parameters.CheckInDate;
	EndIf;
	// Fill check-out date
	CheckOutDate = Undefined;
	If Parameters.Property("CheckOutDate") Then
		CheckOutDate = Parameters.CheckOutDate;
	EndIf;
	// Fill check-out date
	AccommodationType = Undefined;
	If Parameters.Property("AccommodationType") Then
		AccommodationType = Parameters.AccommodationType;
	EndIf;
	// Fill folio
	Folio = Undefined;
	If Parameters.Property("Folio") Then
		Folio = Parameters.Folio;
	EndIf;
	If Parameters.Property("ParentDoc") Then
		ParentDoc = Parameters.ParentDoc;
	EndIf;
	If Not ValueIsFilled(ParentDoc) And ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then
		ParentDoc = Folio.ParentDoc;
		If ValueIsFilled(ParentDoc.Room) And Not Room = ParentDoc.Room Then
			Room = ParentDoc.Room;
		EndIf;
	EndIf;
	If Not ValueIsFilled(Hotel) And ValueIsFilled(ParentDoc) Then
		Hotel = ParentDoc.Hotel;
	EndIf;
	If Not ValueIsFilled(Hotel) And ValueIsFilled(Folio) Then
		Hotel = Folio.Hotel;
	EndIf;
	// Clear cards are blocked
	CardsAreBlocked = False;
	If ValueIsFilled(Room) Or ValueIsFilled(Folio) Then
		// Fill list of cards to be issued
		FillToBeIssuedCards();
		// Fill list of cards already being issued
		FillIssuedCards();
		// Ckeck if there are issued cards
		If IssuedCards.Count() > 0 Then
			If TargetCards.Count() = 0 Then
				ShowStatusMessage(NStr("en='There are already issued cards!';ru='Существуют ранее выданные карты!';de='Es gibt bereits ausgegebenen Karten!'"));
				// Clear card data
				CardData = "";
				// Block card data input
				Items.CardData.ReadOnly = True;
				// Hide card data
				Items.CardData.Visible = False;
				// Clear cards are blocked
				CardsAreBlocked = False;
			EndIf;
		Else
			If TargetCards.Count() = 0 Then
				ShowStatusMessage(NStr("en='There is no card to issue!';ru='Нет карт, которые можно выдать!';de='Keine Karten, die ausgegeben werden können!'"));
				// Clear card data
				CardData = "";
				// Block card data input
				Items.CardData.ReadOnly = True;
				// Hide card data
				Items.CardData.Visible = False;
				// Clear cards are blocked
				CardsAreBlocked = False;
			EndIf;
		EndIf;
		// Check cards to be processed
		If GuestsInRoom.Count() = 0 Then
			ShowStatusMessage(NStr("en='There is no one to give cards!';ru='Некому выдавать карты!';de='Es ist niemand zu Karten geben!'"), True);
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
			// Clear cards are blocked
			CardsAreBlocked = False;
		EndIf;
	Else
		// Show attention message
		ShowStatusMessage(NStr("en='Room and folio are not specified!';ru='Не указан ни номер комнаты ни фолио!';de='Zimmer oder Folio ist nicht angegeben!'"), True);
		// Clear card data
		CardData = "";
		// Block card data input
		Items.CardData.ReadOnly = True;
		// Hide card data
		Items.CardData.Visible = False;
		// Clear cards are blocked
		CardsAreBlocked = False;
	EndIf;
	ExternalSystemInteraction = IdentityCardSystemParameters.ExternalInteraction;
	FillConditionalApperance();
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.DeleteCards.Visible = False;
	EndIf;
	CurrentTime = CurrentSessionDate();
	
	If ValueIsFilled(ParentDoc) Then
		vCashRegistersList = cmGetListOfCashRegistersAllowed(ParentDoc.Company, SessionParameters.CurrentWorkstation);
		If vCashRegistersList.Count() > 0 Then
			CashRegister = vCashRegistersList[0].Value;
		EndIf;	
	EndIf;	
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Wait for new card to be read
	If Not CardsAreBlocked And Not Items.CardData.ReadOnly Then
		RegisterNewCardAtClient(Undefined);
	Else
		// Hide card data
		Items.CardData.Visible = False;
	EndIf;
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	StopReadingCards = False;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		CardData = vEventData.DeviceData;
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
	EndIf;
EndProcedure // ExternalEvent

// -----------------------------------------------------------------------------
&AtClient
Procedure OnClose(Exit)
	DetachIdleHandler("CheckBackgroundJobs");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure TargetCardsOnActivateRow(Item)
	If TargetCards.Count() > 0 Then
		RegisterNewCardAtClient(Undefined);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RegisterNewCardAtClient(pCommand)
	If StopReadingCards Then
		Return;
	EndIf;
	// Clear card data
	CardData = "";
	// Show card data
	Items.CardData.Visible = True;
	// Enable card data input
	Items.CardData.ReadOnly = False;
	CurrentItem = Items.CardData;
	// Guest to process first
	vGuestsInRoomRow = Items.TargetCards.CurrentData;
	If vGuestsInRoomRow <> Undefined Then 
		If SelGuestsInRoom <> vGuestsInRoomRow.Client Then
			ShowClientStatusMessage(vGuestsInRoomRow);   
		EndIf;	
		// Set mapping
		If IsBlankString(vGuestsInRoomRow.RoomRateCode) And IsBlankString(vGuestsInRoomRow.ParkingCode) And AllowedSetMapping() Then 
			AttachIdleHandler("SetISDRoomRateMapping", 0.2, True);
		EndIf;	
	EndIf;  
	// Wait for card to be read	
	AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
EndProcedure // RegisterNewCardAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteCardsAtClient(pCommand)
	vCurRows = Items.IssuedCards.SelectedRows;
	If vCurRows.Count() > 0 Then
		// Ask user if he really wants to delete cards
		vNF = New NotifyDescription("AfterDeleteCardsConfirmation", ThisObject, New Structure("SelectedRows", vCurRows));
		vQuery = NStr("en = 'Do you want to delete selected cards?'; de = 'Wollen Sie alle Folio Karten zu löschen?'; ru = 'Хотите удалить выбранные карты?'");
		ShowQueryBox(vNF, vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	Else
		ShowMessageBox(, NStr("en = 'You must select the cards for cleaning from the issued cards window!'; de = 'Sie müssen die zu reinigenden Karten aus dem Fenster der ausgegebenen Karten auswählen!'; ru = 'Необходимо выбрать карты для очистки из окна выданных карт!'"));
	EndIf;
	// Wait for card to be read	
	AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
EndProcedure // DeleteCardsAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure RepeatIssue(Command)
	vCurRows = Items.IssuedCards.SelectedRows;
	If vCurRows.Count() > 0 Then
		UpdateCards(vCurRows);
	Else
		ShowMessageBox(, NStr("en = 'It is necessary to select cards for re-sending to ISD from the issued cards window!'; 
						      |de = 'Es ist notwendig, Karten für das erneute Senden an ISD aus dem Fenster mit den ausgegebenen Karten auszuwählen!'; 
							  |ru = 'Необходимо выбрать карты для повторной отправки в ISD из окна выданных карт!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CardInfo(Command)
	vCurRow = Items.IssuedCards.CurrentData;
	
	vParamCard = New Structure();
	vParamCard.Insert("ExternalSystemInteraction", ExternalSystemInteraction);
	vParamCard.Insert("IsDetailsInfo", False);
	If Not vCurRow = Undefined Then
		vParamCard.Insert("IdentificationCard", vCurRow.CardCode);
	EndIf;
	OpenForm("Catalog.IdentificationCards.Form.tcISDCardInfo", vParamCard, ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DetailsInfo(Command)
	vCurRow = Items.IssuedCards.CurrentData;
	
	vParamCard = New Structure();
	vParamCard.Insert("ExternalSystemInteraction", ExternalSystemInteraction);
	vParamCard.Insert("IsDetailsInfo", True);
	If Not vCurRow = Undefined Then
		vParamCard.Insert("IdentificationCard", vCurRow.CardCode);
	EndIf;
	OpenForm("Catalog.IdentificationCards.Form.tcISDCardInfo", vParamCard, ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReplaceCard(Command)
	vCurRows = Items.IssuedCards.CurrentData;
	If Not vCurRows = Undefined Then
		// Ask user if he really wants to delete cards
		vNF = New NotifyDescription("AfterReplaceCardConfirmation", ThisObject, New Structure("SelectedRow", vCurRows));
		vQuery = NStr("en = 'The current card will be blocked!
                       |Are you sure you want to reissue the selected card?'; de = 'Die aktuelle Karte wird gesperrt!
                       |Möchten Sie die ausgewählte Karte wirklich erneut ausstellen?'; ru = 'Текущая карта будет заблокирована!
                       |Действительно хотите перевыпустить выбранную карту?
                       |'");
		ShowQueryBox(vNF, vQuery, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	Else
		ShowMessageBox(, NStr("en = 'You must select the card to be replaced from the issued cards window!'; de = 'Sie müssen die zu ersetzende Karte im Fenster der ausgestellten Karten auswählen!'; ru = 'Необходимо выбрать карту для замены из окна выданных карт!'"));
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AdditionalCard(Command)
	vCurRow = Items.IssuedCards.CurrentData;
	If Not vCurRow = Undefined Then
		// Detach handlers
		DetachIdleHandler("CheckNewCardWasRead");
		vMaxCard = tcOnServer.cmGetAttributeByRef(vCurRow.CardType, "NumberOfAdditionalCards");
		If vMaxCard = 0 Then
			vMsg = NStr("en = 'Issuance of additional cards is prohibited!'; de = 'Die Ausgabe von Zusatzkarten ist verboten!'; ru = 'Выдача дополнительных карт запрещена!'");
			ShowMessageBox(, vMsg);
		Else
			vIssued = GetAvailableQuantityCards(vCurRow.Card);
			If (vMaxCard - vIssued) > 0 Then
				vParamCard = New Structure();
				vParamCard.Insert("ExternalSystemInteraction", ExternalSystemInteraction);
				vParamCard.Insert("IsDetailsInfo", False);
				vParamCard.Insert("IsReplaceCard", True);    
				vParamCard.Insert("RateISD", vCurRow.RoomRateCode);
				vNF = New NotifyDescription("ContinueIssueAddCard", ThisObject, New Structure("SelectedRow", vCurRow));
				OpenForm("Catalog.IdentificationCards.Form.tcISDCardInfo", vParamCard, ThisObject, UUID, , , vNF, FormWindowOpeningMode.LockOwnerWindow);
			Else	
			    vMsg = NStr("en = 'For guest %1, the limit (%2) of additional cards has been reached! '; 
							|de = 'Für Gast %1 ist das Limit (%2) der Zusatzkarten erreicht!'; 
							|ru = 'Для гостя %1, лимит (%2) дополнительных карт исчерпан!'");
				ShowMessageBox(, StrTemplate(vMsg, vCurRow.Client, vMaxCard));
			EndIf;
		EndIf;	
	Else
		ShowMessageBox(, NStr("en = 'You must select a guest for issuing an additional card from the issued cards window!'; 
							  |de = 'Sie müssen einen Gast auswählen, um eine zusätzliche Karte aus dem Fenster ""Ausgestellte Karten"" auszustellen!'; 
							  |ru = 'Необходимо выбрать гостя для выдачи дополнительной карты из окна выданных карт!'"));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure LateCheckOut(Command)
	If Not ValueIsFilled(CashRegister) Then
		ShowMessageBox(, NStr("en = 'POS printer is not connected at this workplace'; 
							  |de = 'Kassendrucker ist an diesem Arbeitsplatz nicht angeschlossen'; 
							  |ru = 'На данном рабочем месте не подключен ККМ для печати билетов'"),, "ERROR");
		Return;
	EndIf;
	vErr = "";
	If AllowedPrintLateCheckOutTikets(vErr) Then
		Items.LateCheckOut.Picture = PictureLib.LongOperation16;
		AttachIdleHandler("PrintTickets", 1, True);
	Else
		ShowMessageBox(,vErr ,, "ERROR");
		Return;
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintTickets()
	FillLateCheckOutTickets();
	
	Items.LateCheckOut.Picture = PictureLib.WaitClock;
	
	vGuestList = GetGuestList();
	If vGuestList.Count() > 0 Then
		vND = New NotifyDescription("PrintTickets_AfterInput", ThisObject, New Structure());
		vGuestList.ShowCheckItems(vND, NStr("en = 'Select guests to print tickets'; de = 'Wählen Sie Gäste aus, um Tickets auszudrucken'; ru = 'Выберите гостей для печати билетов'"));
	Else
		ShowMessageBox(, NStr("en = 'No guests evicted'; 
							|de = 'Keine Gäste vertrieben'; 
							|ru = 'Нет выселенных гостей'"),, "ERROR");
		Return;
		
	EndIf;
	
EndProcedure
	
// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetAvailableQuantityCards(pCard)
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	IdentificationCards.Ref AS Ref
		|FROM
		|	Catalog.IdentificationCards AS IdentificationCards
		|WHERE
		|	IdentificationCards.DeletionMark = FALSE
		|	AND IdentificationCards.Client = &qClient
		|	AND IdentificationCards.IsAdditionalCard
		|	AND IdentificationCards.Hotel = &qHotel
		|
		|GROUP BY
		|	IdentificationCards.Ref";
	
	vQuery.SetParameter("qClient", pCard.Client);
	vQuery.SetParameter("qHotel", pCard.Hotel);
	
	vQueryResult = vQuery.Execute();
	
	Return  vQueryResult.Select().Count();
	

EndFunction //  GetAvailableQuantityCards

// -----------------------------------------------------------------------------
&AtClient
Procedure UpdateCards(vList)
	For Each vCardsRow In vList Do
		vRow = IssuedCards.FindByID(vCardsRow);
		vCardRef = GetClientIdentificationCardById(vRow.CardCode);
		If ValueIsFilled(vCardRef) Then
			vRequestParams = New Structure;
			vRequestParams.Insert("Card", 			vCardRef);
			vRequestParams.Insert("KeyID", 			vRow.CardCode);
			vRequestParams.Insert("CardAction",		"updateTicket");   
			vRequestParams.Insert("TariffID", 		vRow.RoomRateCode);
			vRequestParams.Insert("ParkID", 		vRow.ParkingCode);
			vRequestParams.Insert("WorkstationID",	GetPSALID());
			vRequestParams.Insert("PeriodFrom", 	vRow.PeriodFrom);
			vRequestParams.Insert("PeriodTo", 		vRow.PeriodTo);
			vRequestParams.Insert("kkm_regnum", 	"");
			vRequestParams.Insert("kkm_fnserial", 	"");
			vRequestParams.Insert("kkm_fiscdoc", 	"");
			vRequestParams.Insert("kkm_fpd",     	"");
			
			AsincIssueCard(vRow.Document, vRequestParams);
			
			FillToBeIssuedCards();
			// Fill issued cards list
			FillIssuedCards();
		EndIf;
	EndDo;	
EndProcedure	
	
// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteCards(pCards)
	Try
		// Check should we reuse deleted cards
		vUseDeleted = IdentityCardSystemParameters.UseDeleted;
		For Each vCardsRow In pCards Do
			vRow = IssuedCards.FindByID(vCardsRow);
			// Get params for query
			vKeyParams = New Structure;   
			vKeyParams.Insert("media_num", vRow.CardCode);
			vKeyParams.Insert("pointsale", GetPSALID());
			vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
			vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
			vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
			
			vRes = ISD.ClearCard(ExternalSystemInteraction, vKeyParams); 
			If vRes.Success Then
				vCardRef = GetClientIdentificationCardById(vRow.CardCode);
				If ValueIsFilled(vCardRef) Then
					vCardObj = vCardRef.GetObject();
					If vUseDeleted Then
						// Update card
						vCardObj.Folio = Documents.Folio.EmptyRef();
						vCardObj.ParentDoc = Undefined;
						vCardObj.GuestGroup = Catalogs.GuestGroups.EmptyRef();
						vCardObj.Client = Catalogs.Clients.EmptyRef();
						vCardObj.Room = Catalogs.Rooms.EmptyRef();
						vCardObj.DateTimeFrom = Undefined;
						vCardObj.DateTimeTo = Undefined;
						vCardObj.Hotel = Catalogs.Hotels.EmptyRef();
						vCardObj.BlockReason = "";
						vCardObj.IsBlocked = False;
						vCardObj.IsCheckedOut = False;
						vCardObj.Write();
					Else
						// Delete card
						vCardObj.SetDeletionMark(True);
					EndIf;
				EndIf;
			Else
				ShowStatusMessage(NStr("en='Client identification cards deletion error: ';ru='Ошибка удаления карт идентификации клиентов: ';de='Fehler beim Löschen der Kundenidentifikationskarten: '") + vRes.StatusDescription, True);
			EndIf;
		EndDo;
	Except
		ShowStatusMessage(NStr("en='Client identification cards deletion error: ';ru='Ошибка удаления карт идентификации клиентов: ';de='Fehler beim Löschen der Kundenidentifikationskarten: '") + ErrorDescription(), True);
	EndTry;
	// Fill list of cards to be issued
	FillToBeIssuedCards();
	// Fill issued cards list
	FillIssuedCards();
EndProcedure // DeleteFolioCards

// -----------------------------------------------------------------------------
&AtServer
Function RegisterNewCard(pCardData, pIsMaster = False, pCardType = Undefined, pFolio = Undefined, pParentDoc = Undefined, pClient = Undefined, pISDRateCode = "", pParkingCode = "", pCard = Undefined)
	// Get card identifier
	vCardID = cmGetCardIdentifier(pCardData);
	vKeyParams = GetISDTestCardParams(vCardID, pISDRateCode);
	// Check card in ISD
	vRes = ISD.TestCard(ExternalSystemInteraction, vKeyParams);
	If Not vRes.Success Then
		vErr = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
		ShowStatusMessage(vErr, True);
		StopReadingCards = True;
		Return False;  
	Else
		vMediaNum = vRes.MapResponse.Get("media_num");
		If vMediaNum <> Undefined Then
			vCardID = vMediaNum;	
		EndIf;	
	EndIf;	
	If ValueIsFilled(pFolio) Then
		vFolio = pFolio;
	Else
		vFolio = GetClientFolio(pParentDoc.GuestGroup, pParentDoc.Room, pParentDoc.Guest, pParentDoc);
	EndIf;
	// Check should we reuse deleted cards
	vUseDeleted = IdentityCardSystemParameters.UseDeleted;
	// Check if card with this identifier already exists
	vIDCardRef = Undefined;
	If vUseDeleted Then
		vIDCardRef = cmGetClientIdentificationCardById(vCardID, vUseDeleted);
		If ValueIsFilled(vIDCardRef) Then
			If Not vIDCardRef.DeletionMark Then
				If ValueIsFilled(vIDCardRef.Folio) And Not vIDCardRef.Folio.IsClosed Then
					ShowStatusMessage(NStr("en='You are processing card that is already in use!';ru='Выбрали карту, которая уже выдана на другого клиента!';de='Verwenden Sie die Karte, die bereits auf einem anderen Client aufgeführt ist!'"), True);
					Return False;
				EndIf;
			EndIf;
			If vIDCardRef.IdentificationCardType <> pCardType Then
				ShowStatusMessage(NStr("en='You are processing card with wrong type!';ru='Выбрали карту не того типа!';de='Sie halten die falsche Type von Karte!'"), True);
				Return False;
			EndIf;
			If Not ValueIsFilled(vFolio.ParentDoc) Then
				vFolioCards = cmGetClientIdentificationCardsByFolio(vFolio);
				For Each vFolioCardsRow In vFolioCards Do
					If vFolioCardsRow.Ref <> vIDCardRef Then
						ShowStatusMessage(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"), True);
						Return False;
					EndIf;
				EndDo;
			EndIf;
		Else
			ShowStatusMessage(NStr("en='Card is not known! Ask your system administrator';ru='Карта не введена в базу данных! Обратитесь к системному администратору';de='Karte ist nicht bekannt! Fragen Sie Ihren Systemadministrator!'"), True);
			Return False;
		EndIf;
	EndIf;
	// Register card
	If Not vUseDeleted Then
		vOldIDCardRef = cmGetClientIdentificationCardById(vCardID, vUseDeleted);
		If ValueIsFilled(vOldIDCardRef) Then
			If vOldIDCardRef.ParentDoc = ?(pParentDoc <> Undefined, pParentDoc, vFolio.ParentDoc) And vOldIDCardRef.Client = ?(pClient <> Undefined, pClient, vFolio.Client) Then
				vOldIDCardObj = vOldIDCardRef.GetObject();
				vOldIDCardObj.SetDeletionMark(True);
			EndIf;
		EndIf;
	EndIf;
	vIDCardRef = GetClientIdentificationCard(vCardID, vIDCardRef, ?(pParentDoc <> Undefined, pParentDoc, vFolio.ParentDoc), vFolio, pClient, pParentDoc.Room, pParentDoc.CheckInDate, pParentDoc.CheckOutDate, True, , vUseDeleted, pCardType);
	If Not ValueIsFilled(vIDCardRef) Then
		ShowStatusMessage(NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"), True);
		Return False;
	ElsIf Not vUseDeleted And TrimAll(vIDCardRef.Identifier) <> vCardID Then
		ShowStatusMessage(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"), True);
		Return False;
	EndIf;
	// Check should we update is master folio flag
	If ValueIsFilled(vFolio) And pFolio = Undefined Then
		If vFolio.IsMaster <> pIsMaster Then
			vFolioObj = vFolio.GetObject();
			vFolioObj.IsMaster = pIsMaster;
			vFolioObj.Write(DocumentWriteMode.Write);
			// Try to set folio client default charging rules
			If ValueIsFilled(vFolio.Client) And Not ValueIsFilled(vFolio.Room) And Not ValueIsFilled(vFolio.GuestGroup) Then
				vClientObj = vFolio.Client.GetObject();
				If ValueIsFilled(vFolio.Hotel) Then
					vClientObj.ChargingRules.Clear();
					vClientObj.pmCreateFolios(vFolio.Hotel, CurrentSessionDate());
					If vClientObj.ChargingRules.Count() > 0 Then
						vCRRow = vClientObj.ChargingRules.Get(0);
						vOldFolio = vCRRow.ChargingFolio;
						vCRRow.ChargingFolio = vFolio;
						vClientObj.Write();
						// Try to mark old folio as deleted
						If ValueIsFilled(vOldFolio) Then
							vOldFolioObj = vOldFolio.GetObject();
							vOldFolioObj.SetDeletionMark(True);
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	If vCardID = vMediaNum And ValueIsFilled(vMediaNum) Then
		Try
			vDecID = Format(GetBinaryDataBufferFromHexString(vCardID).ReadInt64(0, ByteOrder.BigEndian), "NG=0");
		Except
			vDecID = "";
		EndTry;
	Else
		vDecID = pCardData;
	EndIf;
	vCardObj = vIDCardRef.GetObject();
	vCardObj.CardUID = vDecID;
	vCardObj.ISDRateCode = pISDRateCode;
	vCardObj.ISDParkingRateCode = pParkingCode;
	vCardObj.Write();
	pCard = vIDCardRef;
	// Return success
	Return True;
EndFunction // RegisterNewCard

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterDeleteCardsConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		// Detach handlers
		DetachIdleHandler("CheckNewCardWasRead");
		// Clear card data
		CardData = "";
		// Block card data input
		Items.CardData.ReadOnly = True;
		// Hide card data
		Items.CardData.Visible = False;
		// Show what user have to do
		ShowStatusMessage(NStr("en='Processing...';ru='Обработка...';de='Bearbeitung…'"));
		
		DeleteCards(pExtraParams.SelectedRows);
		
		FillToBeIssuedCards();
		// Fill issued cards list
		FillIssuedCards();
	EndIf;
EndProcedure // AfterDeleteCardsConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterReplaceCardConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		// Detach handlers
		DetachIdleHandler("CheckNewCardWasRead");
		vCurRow = pExtraParams.SelectedRow;
		vParamCard = New Structure();
		vParamCard.Insert("ExternalSystemInteraction", ExternalSystemInteraction);
		vParamCard.Insert("IsDetailsInfo", False);
		vParamCard.Insert("IsReplaceCard", True);    
		vParamCard.Insert("RateISD", vCurRow.RoomRateCode);
		vParamCard.Insert("IdentificationCard", vCurRow.CardCode);
		vNF = New NotifyDescription("ContinueReplaceCard", ThisObject, New Structure("SelectedRow", vCurRow));
		OpenForm("Catalog.IdentificationCards.Form.tcISDCardInfo", vParamCard, ThisObject, UUID, , , vNF, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // AfterReplaceCardConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure ContinueReplaceCard(pAnsver, pExtraParams) Export
	If Not pAnsver = Undefined And ValueIsFilled(pAnsver.IdentificationCard) Then
		vCurRow = pExtraParams.SelectedRow;
		vRequestParams = New Structure;
		vRequestParams.Insert("Card", 			vCurRow.Card);
		vRequestParams.Insert("KeyOldID", 		?(IsBlankString(pAnsver.ReplaceCard), vCurRow.CardCode, pAnsver.ReplaceCard));
		vRequestParams.Insert("KeyNewID",		pAnsver.IdentificationCard);   
		vRequestParams.Insert("WorkstationID",	GetPSALID());

		vRes = ISD.ReplaceCard(ExternalSystemInteraction, vRequestParams);
		If Not vRes.Success Then
			vErr = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
			ShowStatusMessage(vErr);
			Return;
		EndIf;	
		FillToBeIssuedCards();
		FillIssuedCards();
	EndIf;
EndProcedure // AfterReplaceCardConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure ContinueIssueAddCard(pAnsver, pExtraParams) Export
	If Not pAnsver = Undefined And ValueIsFilled(pAnsver.IdentificationCard) Then
		vCurRow = pExtraParams.SelectedRow;
		CardData = pAnsver.IdentificationCard;
		RegisterNewCardAfterConfirm(vCurRow.CardType, vCurRow, , True);
		CardData = "";
		FillToBeIssuedCards();
		FillIssuedCards();
	EndIf;
EndProcedure // ContinueIssueAddCard

// -----------------------------------------------------------------------------
&AtServer
Procedure ShowStatusMessage(pMsg = "", pAttention = False, pColor = Undefined)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.BackColor = StyleColors.FieldSelectionBackColor;
		Items.HelpMessage.TextColor = StyleColors.FieldSelectedTextColor;
	Else
		If pColor <> Undefined Then
			Items.HelpMessage.BackColor = pColor;
			Items.HelpMessage.TextColor = StyleColors.FieldSelectedTextColor;
		Else
			Items.HelpMessage.BackColor = StyleColors.FormBackColor;
			Items.HelpMessage.TextColor = StyleColors.FieldSelectionBackColor;
		EndIf;
	EndIf;
EndProcedure // ShowStatusMessage

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetColorAtServer(pItem) 
	vColor = Undefined;
	If pItem.Color <> Undefined Then
		vColor = pItem.Color.Get();
	EndIf;
	Return vColor;
EndFunction // GetColorAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowClientStatusMessage(pClientRow)
	vCardType = pClientRow.CardType;
	vClientFullName = "";
	If ValueIsFilled(pClientRow.Client) Then
		vClientFullName = TrimAll(tcOnServer.cmGetAttributeByRef(pClientRow.Client, "FullName"));
	EndIf;
	vClientAccommodationType = "";
	If ValueIsFilled(pClientRow.AccommodationType) Then
		vClientAccommodationType = TrimAll(pClientRow.AccommodationType);
	EndIf;
	If Not ValueIsFilled(vCardType) Then
		ShowStatusMessage(NStr("en='Slip new card to read it!';ru='Считайте новую карту!';de='Ziehen Sie eine neue Karte durch!'") +
			Chars.LF + vClientFullName + ?(IsBlankString(vClientAccommodationType), "", " " + vClientAccommodationType) );
	Else
		vCardTypeColor = GetColorAtServer(vCardType);  
		If IsBlankString(pClientRow.RoomRateDesc) Then
			vMsg = NStr("en = 'The card type is not configured to match the ISD, contact your system administrator!'; de = 'Der Kartentyp ist nicht passend zur ISD konfiguriert, wenden Sie sich an Ihren Systemadministrator!'; ru = 'Для тарифа и/или пакета не настроено соответствие с тарифом в ISD. Обратитесь к ответственному сотруднику!'");
			ShowStatusMessage(vMsg, True, vCardTypeColor); 
		Else
			ShowStatusMessage(NStr("en='Slip new card to read it!';ru='Считайте новую карту!';de='Ziehen Sie eine neue Karte durch!'") + Chars.LF + 
							  NStr("en='Card type is ';ru='Тип карты: ';de='Karten-Typ ist '") + TrimAll(tcOnServer.cmGetAttributeByRef(vCardType, "Description")) + Chars.LF + 
							  NStr("en='Tariff ISD ';ru='Тариф ISD: ';de='Tariff ISD '") + pClientRow.RoomRateDesc + ", "+Format(pClientRow.PeriodFrom,"DF='dd.MM.yyyy HH:mm'") + " - " + Format(pClientRow.PeriodTo,"DF='dd.MM.yyyy HH:mm'") + Chars.LF +
							    vClientFullName + ?(IsBlankString(vClientAccommodationType), "", " " + vClientAccommodationType), , vCardTypeColor);
	
		EndIf;
	EndIf;
EndProcedure // ShowClientStatusMessage

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckNewCardWasRead()
	If StopReadingCards Then
		Return;
	EndIf;
	If IsBlankString(CardData) Then
		// Show card data
		Items.CardData.Visible = True;
		// Enable card data input
		Items.CardData.ReadOnly = False;
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		Return;
	EndIf;
	// Check if this card was already registered
	vIssuedCardsRows = IssuedCards.FindRows(New Structure("CardCode", CardData));
	If vIssuedCardsRows.Count() > 0 Then
		vRow = vIssuedCardsRows[0]; 
		ShowStatusMessage(NStr("en='This card is already registered, guest!';ru='Эта карта уже зарегистрирована на гостя!';de='Diese Karte ist bereits registriert!'") + " " + String(vRow.Client));
		// Clear card data
		CardData = "";
		// Wait for card to be read	
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		Return;
	Else
		vIDCardRef = GetClientIdentificationCardById(CardData);
		If ValueIsFilled(vIDCardRef) Then
			ShowStatusMessage(NStr("en='This card is already registered!';ru='Эта карта уже зарегистрирована!';de='Diese Karte ist bereits registriert!'") + " " + String(vIDCardRef));
			// Clear card data
			CardData = "";
			// Wait for card to be read	
			AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
			Return;
		EndIf;
	EndIf;
	// Check if there are issued cards
	If IssuedCards.Count() > 0 Then
		If TargetCards.Count() = 0 Then
			ShowStatusMessage(NStr("en='All cards are already being issued!';ru='Все карты уже выданы!';de='Alle Karten bereits ausgegeben wurden!'"));
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
			// Clear cards are blocked
			CardsAreBlocked = False;
			Return;
		EndIf;
	Else
		If TargetCards.Count() = 0 Then
			ShowStatusMessage(NStr("en='There is no card to issue!';ru='Нет карт, которые можно выдать!';de='Keine Karten, die ausgegeben werden können!'"));
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
			// Clear cards are blocked
			CardsAreBlocked = False;
			Return;
		EndIf;
	EndIf;
	// Register new card
	vTargetCardRow = Items.TargetCards.CurrentData;
	vCardType = vTargetCardRow.CardType;
	If Not ValueIsFilled(vTargetCardRow.Client) Then
		ShowStatusMessage(NStr("en = 'Guest must be filled!'; de = 'Guest must be filled!'; ru = 'Необходимо заполнить гостя, перед выдачей карты!'"));
		// Clear card data
		CardData = "";
		Return;
	EndIf;	 
	If IsBlankString(tcOnServer.cmGetAttributeByRef(vTargetCardRow.Client, "LastName")) Then
		ShowStatusMessage(NStr("en = 'To issue a card, you must fill in the full name of the guest!'; de = 'Um eine Karte auszustellen, müssen Sie den vollständigen Namen des Gastes eintragen!'; ru = 'Для выдачи карты необходимо заполнить ФИО гостя!'"));
		// Clear card data
		CardData = "";
		Return;
	EndIf;
	If Not ValueIsFilled(vCardType) Then
		ShowStatusMessage(NStr("en = 'The type of card is not specified, contact your system administrator to configure interaction with ISD!'; de = 'Der Kartentyp ist nicht angegeben, wenden Sie sich an Ihren Systemadministrator, um die Interaktion mit ISD zu konfigurieren!'; ru = 'Не указан тип карты, обратитесь к ответственному сотруднику для настройки взаимодействия с ISD!'"));
		// Clear card data
		CardData = "";
		Return;
	EndIf;	
	If IsBlankString(vTargetCardRow.RoomRateCode) Then
		ShowStatusMessage(NStr("en = 'The card type is not configured to match the ISD, contact your system administrator!'; de = 'Der Kartentyp ist nicht passend zur ISD konfiguriert, wenden Sie sich an Ihren Systemadministrator!'; ru = 'Для тарифа и/или пакета не настроено соответствие с тарифом в ISD. Обратитесь к ответственному сотруднику!'"));
		// Clear card data
		CardData = "";
		Return;
	EndIf;	
	vAskGuestVehicle = tcOnServer.cmGetAttributeByRef(vCardType, "AskGuestVehicle");
	If vAskGuestVehicle Then
		vKeyParams = GetISDTestCardParams(CardData, vTargetCardRow.RoomRateCode);
		// Check card in ISD
		vRes = ISD.TestCard(ExternalSystemInteraction, vKeyParams);
		If Not vRes.Success Then
			vErr = ?(Not IsBlankString(vRes.StatusDescription), vRes.StatusDescription, vRes.MapResponse.Get("descr"));
			ShowStatusMessage(vErr, True);
			DetachIdleHandler("CheckNewCardWasRead");
			StopReadingCards = True;
			Return;
		EndIf;	
		vNF = New NotifyDescription("AskGuestVehicleAnswer", ThisObject, New Structure("CardType, CardRow", vCardType, vTargetCardRow));
		OpenForm("Catalog.GuestVehicles.ObjectForm", , ThisObject, UUID, , , vNF, FormWindowOpeningMode.LockOwnerWindow)
	Else	
		RegisterNewCardAfterConfirm(vCardType, vTargetCardRow);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SetISDRoomRateMapping()
	vParam = New Structure;
	vParam.Insert("ExternalSystemInteraction", ExternalSystemInteraction);
	vParam.Insert("RoomRatesForMatch", GetISDRoomRateMapping()); 
	vNF = New NotifyDescription("AfterSetMapping", ThisObject);
	OpenForm("Catalog.IdentificationCards.Form.tcISDRoomRatesMappingForm", vParam, ThisObject, UUID, , , vNF, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

//-----------------------------------------------------------------------------
&AtClient
Procedure AfterSetMapping(pResult, pExtraParams) Export
	If pResult = True Then
		// Fill list of cards to be issued
		FillToBeIssuedCards();
		// Fill list of cards already being issued
		FillIssuedCards();  
	EndIf;
EndProcedure // AfterSetMapping

// -----------------------------------------------------------------------------
&AtServer
Function GetISDRoomRateMapping()
	Return PutToTempStorage(FormAttributeToValue("RoomRatesForMatch"));
EndFunction // GetISDRoomRateMapping

// -----------------------------------------------------------------------------
&AtServer
Function GetISDTestCardParams(pCardData, pRoomRateCode)
	vKeyParams = New Structure;   
	vKeyParams.Insert("media_num", pCardData);
	vKeyParams.Insert("tariff_id", pRoomRateCode);
	vKeyParams.Insert("pointsale", GetPSALID());
	vKeyParams.Insert("Workstation",  String(SessionParameters.CurrentWorkstation));
	vKeyParams.Insert("Hotel", String(SessionParameters.CurrentHotel));
	vKeyParams.Insert("User", String(SessionParameters.CurrentUser));
	Return vKeyParams;

EndFunction

// -----------------------------------------------------------------------------
&AtClient
Procedure AskGuestVehicleAnswer(pResult, pAddParams) Export 
	If Not pResult = Undefined Then
		 RegisterNewCardAfterConfirm(pAddParams.CardType, pAddParams.CardRow, pResult)
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RegisterNewCardAfterConfirm(pCardType, pTargetCardRow, pGuestVehicle = Undefined, pIsAddCard = False)
	vCardRef = Undefined;
	If RegisterNewCard(CardData, False, pCardType, Undefined, pTargetCardRow.Document, pTargetCardRow.Client, pTargetCardRow.RoomRateCode, pTargetCardRow.ParkingCode, vCardRef) Then
		If ValueIsFilled(vCardRef) And ValueIsFilled(pGuestVehicle) Then
			tcOnServer.cmWriteAttributeCatalogByRef(vCardRef, New Structure("Vehicle", pGuestVehicle));
			// Save car plate number to the reservation
			If ValueIsFilled(pGuestVehicle) And 
			   ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
				StoreCarPlateNumberInReservationAtServer(ParentDoc, pGuestVehicle, CardData);
				If TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
					Notify("Document.Reservation.Write", ParentDoc, ThisObject);
				Else
					Notify("Document.Accommodation.Write", ParentDoc, ThisObject);
				EndIf;
			EndIf;
		EndIf;	
		If ValueIsFilled(vCardRef) And pIsAddCard Then
			tcOnServer.cmWriteAttributeCatalogByRef(vCardRef, New Structure("IsAdditionalCard", pIsAddCard));
		EndIf;
		If Not IsBlankString(pTargetCardRow.RoomRateCode) Or Not IsBlankString(pTargetCardRow.ParkingCode) Then
			vRequestParams = New Structure;
			vRequestParams.Insert("Card", 			vCardRef);
			vRequestParams.Insert("KeyID", 			CardData);
			vRequestParams.Insert("CardAction",		"newTicket");   
			vRequestParams.Insert("TariffID", 		pTargetCardRow.RoomRateCode);
			vRequestParams.Insert("ParkID", 		pTargetCardRow.ParkingCode);
			vRequestParams.Insert("WorkstationID",	GetPSALID());
			vRequestParams.Insert("PeriodFrom", 	pTargetCardRow.PeriodFrom);
			vRequestParams.Insert("PeriodTo", 		pTargetCardRow.PeriodTo);
			vRequestParams.Insert("KeyID", 			CardData);
			vRequestParams.Insert("kkm_regnum", 	"");
			vRequestParams.Insert("kkm_fnserial", 	"");
			vRequestParams.Insert("kkm_fiscdoc", 	"");
			vRequestParams.Insert("kkm_fpd",     	"");
			
			AsincIssueCard(pTargetCardRow.Document, vRequestParams);
		EndIf;
		If Not Items.TargetCards.CurrentRow = Undefined Then
			vRowTargetCards = TargetCards.FindByID(Items.TargetCards.CurrentRow); 
			If Not vRowTargetCards = Undefined Then
				TargetCards.Delete(vRowTargetCards);
			EndIf;
		EndIf;
		If TargetCards.Count() = 0 Then
			ShowStatusMessage(NStr("en='There is no card to issue!';ru='Нет карт, которые можно выдать!';de='Keine Karten, die ausgegeben werden können!'"));
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
		Else
			vRow = TargetCards[0];
			// Get type of card to be read
			ShowClientStatusMessage(vRow);
			// Clear card data
			CardData = "";
			// Show card data
			Items.CardData.Visible = True;
			// Enable card data input
			Items.CardData.ReadOnly = False;
			// Fill list of cards to be issued
			FillToBeIssuedCards();
			// Fill issued cards list
			FillIssuedCards();
			// Wait for card to be read	
			AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		EndIf;
	Else
		// Clear card data
		CardData = "";
		// Show card data
		Items.CardData.Visible = True;
		// Enable card data input
		Items.CardData.ReadOnly = False;
		// Clear cards are blocked
		CardsAreBlocked = False;
		// Wait for card to be read	
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
	EndIf;
EndProcedure // CheckNewCardWasRead

// -----------------------------------------------------------------------------
&AtServerNoContext
Procedure StoreCarPlateNumberInReservationAtServer(pParentDoc, pGuestVehicle, pCardData)
	vCar = TrimAll(pGuestVehicle);
	If Not IsBlankString(vCar) Then
		If StrFind(pParentDoc.Car, vCar) = 0 Then
			vObj = pParentDoc.GetObject();
			vObj.Car = TrimAll(vObj.Car) + ?(IsBlankString(TrimAll(vObj.Car)), "", ", ") + 
			                               vCar + " - " + 
			                               GetCardIDPresentation(cmGetCardIdentifier(pCardData)) + " - " +
										   Format(CurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + " " + 
										   TrimAll(SessionParameters.CurrentUser);
			vObj.Write(DocumentWriteMode.Write);
			If TypeOf(vObj) = Type("DocumentObject.Accommodation") Then
				vObj.pmWriteToAccommodationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			ElsIf TypeOf(vObj) = Type("DocumentObject.Reservation") Then
				vObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			EndIf; 
		EndIf;
	EndIf;
EndProcedure // StoreCarPlateNumberInReservationAtServer

// -----------------------------------------------------------------------------
&AtServer
Function GetPSALID()
	vISDWorkstationID = "";
	vISDWorkstations = InformationRegisters.ExternalSystemIntegrationData.GetData(ExternalSystemInteraction, "Workstation", "ID", SessionParameters.CurrentWorkstation);
	If vISDWorkstations.Count() > 0 Then
		vISDWorkstationID = vISDWorkstations.Get(0).ExternalSystemDataCode;
	Endif;
	Return vISDWorkstationID
EndFunction	

// -----------------------------------------------------------------------------
&AtServer
Function GetClientFolio(pGuestGroup, pRoom, pClient, pDoc)
	// Try to find personal folio
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Folio.Ref
	|FROM
	|	Document.Folio AS Folio
	|WHERE
	|	NOT Folio.DeletionMark
	|	AND Folio.GuestGroup = &qGuestGroup
	|	AND (NOT &qRoomIsSet
	|			OR &qRoomIsSet
	|				AND Folio.Room = &qRoom)
	|	AND (Folio.Client = &qClient)
	|	AND (NOT &qDescriptionIsSet
	|			OR &qDescriptionIsSet
	|				AND Folio.Description LIKE &qDescription)
	|	AND NOT Folio.IsClosed
	|
	|ORDER BY
	|	Folio.Date DESC";
	vQry.SetParameter("qGuestGroup", pGuestGroup);
	vQry.SetParameter("qRoom", pRoom);
	vQry.SetParameter("qRoomIsSet", ValueIsFilled(pRoom));
	vQry.SetParameter("qClient", pClient);
	vQry.SetParameter("qParentDoc", pDoc);
	vDescription = TrimAll(pGuestGroup.Owner.AdditionalServicesFolioCondition);
	vQry.SetParameter("qDescription", "%" + vDescription + "%");
	vQry.SetParameter("qDescriptionIsSet", Not IsBlankString(vDescription));
	vFolios = vQry.Execute().Unload();
	If vFolios.Count() > 0 Then
		Return vFolios.Get(0).Ref;
	Else
		// Try to find main room guest folio
		If TypeOf(pDoc) = Type("DocumentRef.Accommodation") Then
			vMainRoomDoc = cmGetOneRoomAccommodation(pRoom, pGuestGroup, pGuestGroup.CheckInDate, pGuestGroup.CheckOutDate);
			If vMainRoomDoc <> Undefined And vMainRoomDoc <> pDoc Then
				Return GetClientFolio(pGuestGroup, pRoom, vMainRoomDoc.Guest, vMainRoomDoc);
			Else
				Return Undefined;
			EndIf;
		ElsIf TypeOf(pDoc) = Type("DocumentRef.Reservation") Then
			vMainRoomDoc = cmGetOneRoomReservation(TrimAll(pDoc.Number), pGuestGroup, pRoom);
			If vMainRoomDoc <> Undefined And vMainRoomDoc <> pDoc Then
				Return GetClientFolio(pGuestGroup, pRoom, vMainRoomDoc.Guest, vMainRoomDoc);
			Else
				Return Undefined;
			EndIf;
		Else
			Return Undefined;
		EndIf;
	EndIf;
EndFunction // GetClientFolio

// -----------------------------------------------------------------------------
&AtServer
Procedure FillToBeIssuedCards(pInitializeGuestsInRoom = True)
	TargetCards.Clear();
	// Initialize guests in room value table
	If pInitializeGuestsInRoom Then
		GuestsInRoom.Clear();
	EndIf;
	If ValueIsFilled(ParentDoc) Or ValueIsFilled(Folio) And ValueIsFilled(Folio.ParentDoc) Then   
		vAcc = ?(ValueIsFilled(ParentDoc), ParentDoc, Folio.ParentDoc);
		If TypeOf(vAcc) = Type("DocumentRef.Reservation") Then
			vCards = ISD.GetMappingISDByReservation(vAcc);
		ElsIf TypeOf(vAcc) = Type("DocumentRef.Accommodation") Then	
			vCards = ISD.GetMappingISDByAccommodation(vAcc);
		Else
			Raise NStr("en = 'The card can be issued only for accommodation or reservation'; de = 'Die Karte kann nur für Unterkunft oder Reservierung ausgestellt werden'; ru = 'Карту можно выдать только по размещению или брони'");
		EndIf;  
		RoomRatesForMatch.Clear();
		For Each vGuestsRow In vCards Do
			vDocRef = vGuestsRow.Document;
			If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And vDocRef.AccommodationStatus.IsInHouse = False Or TypeOf(vDocRef) = Type("DocumentRef.Accommodation") And vDocRef.AccommodationStatus.IsActive = False Then
				Continue;
			EndIf;
			If TypeOf(vDocRef) = Type("DocumentRef.Reservation") And vDocRef.ReservationStatus.IsInWaitingList = False Then
				Continue;
			EndIf;
			// Add row to room guests
			If pInitializeGuestsInRoom Then
				vNewRowGuestsInRoom = GuestsInRoom.Add();
				FillGuestInRoomRow(vNewRowGuestsInRoom, vDocRef);
				vNewRowGuestsInRoom.CardType = vGuestsRow.CardType;
				vFolio = GetClientFolio(vDocRef.GuestGroup, vDocRef.Room, vDocRef.Guest, vDocRef);
				vNewRowGuestsInRoom.Folio = vFolio;
				If ValueIsFilled(vGuestsRow.CardType) Then
					vNewRowGuestsInRoom.CardTypeSortCode = vGuestsRow.SortCode;
				Else
					vNewRowGuestsInRoom.CardTypeSortCode = 0;
				EndIf;
				vNewRowGuestsInRoom.ParkingCode = vGuestsRow.ParkingCode;
				vNewRowGuestsInRoom.RoomRateCode = vGuestsRow.RoomRateCode;
				vNewRowGuestsInRoom.DateTimeFrom = vGuestsRow.PeriodFrom;
				vNewRowGuestsInRoom.DateTimeTo = vGuestsRow.PeriodTo;
			EndIf;     
			// Add row to be set map  
			If vGuestsRow.IsFound = False Then 
				If RoomRatesForMatch.FindRows(New Structure("UUIDRowMapping", vGuestsRow.UUIDRowMapping)).Count() = 0 Then
					vNewRowMap = RoomRatesForMatch.Add();
					vNewRowMap.RoomRate = vGuestsRow.RoomRate;
					vNewRowMap.CardType = vGuestsRow.CardType;
					vNewRowMap.UUIDRowMapping = vGuestsRow.UUIDRowMapping;
					vPkgMap = New Array;
					If Not IsBlankString(vGuestsRow.PackagesHash) Then
						vPackages = StrSplit(vGuestsRow.PackagesHash, "_", True);
						For Each vPkg In vPackages Do
							vPkgMap.Add(String(Catalogs.ServicePackages.GetRef(New UUID(vPkg))));
						EndDo;
					EndIf;
					vNewRowMap.Packages = StrConcat(vPkgMap, ";"); 
				EndIf;
			EndIf;
		EndDo;
		vCards.GroupBy("Document, CardType, SortCode, RoomRateCode, ParkingCode, PeriodFrom, PeriodTo, RoomRateDesc, ParkingDesc");
		vCards.Sort("SortCode");
		TargetCards.Clear();
		For Each vCardsRow In vCards Do
			vDoc = vCardsRow.Document;
			If TypeOf(vDoc) = Type("DocumentRef.Accommodation") And vDoc.AccommodationStatus.IsInHouse = False Or TypeOf(vDoc) = Type("DocumentRef.Accommodation") And vDoc.AccommodationStatus.IsActive = False Then
				Continue;
			EndIf;
			If TypeOf(vDoc) = Type("DocumentRef.Reservation") And vDoc.ReservationStatus.IsInWaitingList = False Then
				Continue;
			EndIf;
			vTargetCardsRow = TargetCards.Add();
			FillPropertyValues(vTargetCardsRow, vCardsRow);
			vTargetCardsRow.UUIDSrting = String(vDoc.UUID()) + "_" + vCardsRow.RoomRateCode + "_" + vCardsRow.ParkingCode;
			vTargetCardsRow.Client = vDoc.Guest;
			vTargetCardsRow.AccommodationType = vDoc.AccommodationType;
			vTargetCardsRow.AccommodationTypeSortCode = vTargetCardsRow.AccommodationType.SortCode;
		EndDo;
		TargetCards.Sort("SortCode, AccommodationTypeSortCode");
	Else	
		Raise NStr("en = 'The card can be issued only for accommodation or reservation'; de = 'Die Karte kann nur für Unterkunft oder Reservierung ausgestellt werden'; ru = 'Карту можно выдать только по размещению или брони'");
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillGuestInRoomRow(pNewRow, pDocRef)
	pNewRow.Document = pDocRef;
	pNewRow.Hotel = pDocRef.Hotel;
	pNewRow.GuestGroup = pDocRef.GuestGroup;
	If TypeOf(pDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(pDocRef) = Type("DocumentRef.Reservation") Then
		pNewRow.Room = pDocRef.Room;
		pNewRow.Client = pDocRef.Guest;
		pNewRow.AccommodationType = pDocRef.AccommodationType;
		pNewRow.AccommodationTypeSortCode = pDocRef.AccommodationType.SortCode;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.ResourceReservation") Then
		pNewRow.Client = pDocRef.Client;
		pNewRow.AccommodationTypeSortCode = 0;
	ElsIf TypeOf(pDocRef) = Type("DocumentRef.Folio") Then
		pNewRow.Client = pDocRef.Client;
		pNewRow.AccommodationTypeSortCode = 0;
	EndIf;
EndProcedure // FillToBeIssuedCards

// -----------------------------------------------------------------------------
&AtServer
Procedure FillIssuedCards()
	IssuedCards.Clear();
	CardsAreBlocked = False;
	vBlockReason = "";
	If ValueIsFilled(Room) Then
		vIssuedCards = cmGetClientIdentificationCardsByRoom(Room, False, ?(ValueIsFilled(Folio), Folio.GuestGroup, Undefined), True);
	ElsIf ValueIsFilled(Folio) Then
		vIssuedCards = cmGetClientIdentificationCardsByFolio(Folio);
	Else
		Return;
	EndIf;
	If vIssuedCards.Count() > 0 Then
		vBlockReason = "";
		vLastBlockReason = "";
		vCards = New Valuetable();
		vCards.Columns.Add("CardType", cmGetCatalogTypeDescription("IdentificationCardTypes"));
		vCards.Columns.Add("CardCode", cmGetStringTypeDescription());
		vCards.Columns.Add("Quantity", cmGetNumberTypeDescription(6, 0));
		vCards.Columns.Add("SortCode", cmGetNumberTypeDescription(6, 0));
		vCards.Columns.Add("Document");
		vCards.Columns.Add("IsBlocked", cmGetBooleanTypeDescription());
		vCards.Columns.Add("UUIDSrting", cmGetStringTypeDescription());
		vCards.Columns.Add("ParkingCode", cmGetStringTypeDescription());
		vCards.Columns.Add("RoomRateCode", cmGetStringTypeDescription());
		vCards.Columns.Add("Issued", cmGetBooleanTypeDescription());
		vCards.Columns.Add("Message", cmGetStringTypeDescription());
		vCards.Columns.Add("Client");
		vCards.Columns.Add("Card");
		vCards.Columns.Add("PeriodFrom");
		vCards.Columns.Add("PeriodTo");

		For Each vIssuedCardsRow In vIssuedCards Do
			vCardRef = vIssuedCardsRow.Ref;
			If vCardRef.IsBlocked Then
				CardsAreBlocked = True;
				If IsBlankString(vBlockReason) Then
					vBlockReason = TrimAll(vCardRef.BlockReason);
				ElsIf TrimAll(vCardRef.BlockReason) <> vLastBlockReason Then
					vBlockReason = vBlockReason + Chars.LF + TrimAll(vCardRef.BlockReason);
				EndIf;
				vLastBlockReason = TrimAll(vCardRef.BlockReason);
			EndIf;
			vCardType = vCardRef.IdentificationCardType;
			vCardsRow = vCards.Add();
			vCardsRow.CardType = vCardType;
			vCardsRow.CardCode = TrimAll(vCardRef.Identifier);
			vCardsRow.Quantity = 1;
			vCardsRow.Document = ?(ValueIsFilled(vCardRef.ParentDoc), vCardRef.ParentDoc, vCardRef.Folio);
			If ValueIsFilled(vCardsRow.CardType) Then
				vCardsRow.SortCode = vCardsRow.CardType.SortCode;
			Else
				vCardsRow.SortCode = 999999;
			EndIf;
			vCardsRow.IsBlocked = vCardRef.IsBlocked;
			vCardsRow.UUIDSrting = String(vCardsRow.Document.UUID()) + "_" + vCardRef.ISDRateCode + "_" + vCardRef.ISDParkingRateCode;
			vCardsRow.ParkingCode = vCardRef.ISDParkingRateCode;
			vCardsRow.RoomRateCode = vCardRef.ISDRateCode;
			vCardsRow.Issued = vCardRef.Issued;
			vCardsRow.Message = vCardRef.StatusDescription;
			vCardsRow.Client = vCardRef.Client;
			vCardsRow.PeriodFrom = vCardRef.DateTimeFrom;
			vCardsRow.PeriodTo = vCardRef.DateTimeTo;

			vCardsRow.Card = vCardRef;
		EndDo;
		vCards.GroupBy("CardType, Card, Client, CardCode, PeriodFrom, PeriodTo, SortCode, Document, IsBlocked, UUIDSrting, ParkingCode, RoomRateCode, Issued, Message", "Quantity");
		vCards.Sort("SortCode");
		vGuestsInRoom = FormAttributeToValue("GuestsInRoom", Type("ValueTable"));
		For Each vCardsRow In vCards Do
			vFilterByGuest = vGuestsInRoom.FindRows(New Structure("CardType, Client", vCardsRow.CardType, vCardsRow.Client));
			If vFilterByGuest.Count() = 0 Then
			    Continue;
			EndIf; 
			vFilterGuestRow = Undefined;
			vFilterByGustAndPeriod = vGuestsInRoom.FindRows(New Structure("CardType, Client, DateTimeFrom, DateTimeTo", vCardsRow.CardType, vCardsRow.Client, vCardsRow.PeriodFrom, vCardsRow.PeriodTo));
			If vFilterByGustAndPeriod.Count()>0 Then
				vFilterGuestRow = vFilterByGustAndPeriod[0];
			Else
				For Each vRow In vFilterByGuest Do
					If vRow.DateTimeFrom <= vCardsRow.PeriodTo And vRow.DateTimeTo >= vCardsRow.PeriodFrom Then
						vFilterGuestRow = vRow;
						Break;
					EndIf;
				EndDo; 
			EndIf;	
			If vFilterGuestRow = Undefined Then
			    Continue;
			EndIf; 

			vRoomRateCode = vFilterGuestRow.RoomRateCode;
			vParkingCode = vFilterGuestRow.ParkingCode;
			vIssuedCardsRow = IssuedCards.Add();
			FillPropertyValues(vIssuedCardsRow, vCardsRow);
			vIssuedCardsRow.CardPresentation = GetCardIDPresentation(vCardsRow.CardCode);
			vIssuedCardsRow.IsAdditionalCard = vCardsRow.Card.IsAdditionalCard;
			If vCardsRow.Issued Then
				vIssuedCardsRow.Status = PutToTempStorage(PictureLib.CheckMark, UUID);
				If Not vRoomRateCode = vCardsRow.RoomRateCode Or Not vParkingCode = vCardsRow.ParkingCode Then
					vIssuedCardsRow.Status = PutToTempStorage(PictureLib.Attention, UUID);
					vIssuedCardsRow.StatusDescription = ?(IsBlankString(vCardsRow.Message), Nstr("en = 'ISD tariff is different, click ""Retry issue""'; de = 'ISD-Tarif ist anders, klicken Sie auf ""Problem wiederholen""'; ru = 'Отличается тариф ISD, нажмите ""Обновить в ISD""'"), vCardsRow.Message);
					vIssuedCardsRow.RoomRateCode = vRoomRateCode;
					vIssuedCardsRow.ParkingCode = vParkingCode;
				ElsIf vCardsRow.PeriodFrom <> vFilterGuestRow.DateTimeFrom Or vCardsRow.PeriodTo <> vFilterGuestRow.DateTimeTo Then
					vIssuedCardsRow.Status = PutToTempStorage(PictureLib.Attention, UUID);
					vIssuedCardsRow.StatusDescription = ?(IsBlankString(vCardsRow.Message), Nstr("en = 'The validity period is different, click ""Update in ISD""'; de = 'Die Gültigkeitsdauer ist unterschiedlich, klicken Sie auf ""Update in ISD""'; ru = 'Отличается период действия, нажмите ""Обновить в ISD""'"), vCardsRow.Message);
				EndIf;	
			ElsIf IsBlankString(vRoomRateCode) And 	IsBlankString(vParkingCode) Then
				vIssuedCardsRow.Status = PutToTempStorage(PictureLib.AttentionMedium, UUID);
				vIssuedCardsRow.StatusDescription = Nstr("en = 'Mapping is not configured for the map type!'; de = 'Das Mapping ist nicht für den Kartentyp konfiguriert!'; ru = 'Для типа карты не настроен маппинг!'");
				
			Else 	
				vIssuedCardsRow.Status = PutToTempStorage(PictureLib.Attention, UUID);
				vIssuedCardsRow.StatusDescription = ?(IsBlankString(vCardsRow.Message), Nstr("en = 'Not issued in ISD'; de = 'Nicht ausgestellt ISD'; ru = 'Не выдана в ISD'"), vCardsRow.Message);
			EndIf;
			vIssuedCardsRow.RoomRateCode = vRoomRateCode;
			vIssuedCardsRow.PeriodFrom = vFilterGuestRow.DateTimeFrom;
			vIssuedCardsRow.PeriodTo = vFilterGuestRow.DateTimeTo;
		EndDo;
		// Fix cards to be issued and mark clients as processed
		vTargetCards = FormAttributeToValue("TargetCards", Type("ValueTable"));
		For Each vIssuedCardsRow In IssuedCards Do
			// Card type totals
			vFilterByTargetCards = vTargetCards.FindRows(New Structure("CardType, Client, PeriodFrom, PeriodTo", vIssuedCardsRow.CardType, vIssuedCardsRow.Client, vIssuedCardsRow.PeriodFrom, vIssuedCardsRow.PeriodTo));
			If vFilterByTargetCards.Count() > 0 Then
				vCardsRow = vFilterByTargetCards[0];
				vTargetCards.Delete(vCardsRow);
			EndIf;
		EndDo;
		ValueToFormAttribute(vTargetCards, "TargetCards");
		ValueToFormAttribute(vGuestsInRoom, "GuestsInRoom");
	EndIf;
	If CardsAreBlocked Then 
		If Not IsBlankString(vBlockReason) Then
			// Show attention message
			ShowStatusMessage(NStr("en='There are blocked cards!';ru='Есть заблокированные карты!';de='Es gibt gesperrten Karten!'") + Chars.LF + vBlockReason, True);
		Else
			// Show attention message
			ShowStatusMessage(NStr("en='There are blocked cards!';ru='Есть заблокированные карты!';de='Es gibt gesperrten Karten!'"), True);
		EndIf;
	Else
		ShowStatusMessage(NStr("en='Choose operation';ru='Выберите действие';de='Wählen Sie die Aktion'"));
	EndIf;
EndProcedure // FillIssuedCards

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientIdentificationCardById(pCardCode, pUseDeleted = False)
	Return cmGetClientIdentificationCardById(pCardCode, pUseDeleted);
EndFunction // GetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtClient
Procedure AsincIssueCard(pDoc, pKeyParams)
	vUUID = New UUID(); 
	vUUIDSrting = String(pDoc.UUID()) + "_" + pKeyParams.TariffID + "_" + pKeyParams.ParkID;

	vDoRun = True;
	If BackgroundJobsList.Count() > 0 Then
		vFilter = BackgroundJobsList.FindRows(New Structure("UUIDString", vUUIDSrting));
		For each vJob in vFilter Do 
			If vJob.Status = "Processing" Then
				vDoRun = False;
				Break;
			ElsIf vJob.Status = "Completed" Then
				BackgroundJobsList.Delete(vJob);
				Break;
			ElsIf vJob.Status = "Error" Or vJob.Status = "Canceled" Then
				BackgroundJobsList.Delete(vJob);
				Break;
			EndIf;	
		EndDo;
	EndIf;	
	If vDoRun Then
		vTempStorageAdress = PutToTempStorage(Undefined, vUUID);
		
		vProcedureParameters = new Array;
		vProcedureParameters.Add(ExternalSystemInteraction);
		vProcedureParameters.Add(pKeyParams.CardAction);
		vProcedureParameters.Add(pDoc);
		vProcedureParameters.Add(pKeyParams);
		vProcedureParameters.Add(vTempStorageAdress);
		
		AttachIdleHandler("CheckBackgroundJobs", 2, False);
		
		vTtl = "Issue new key for guest: " + TrimAll(tcOnServer.cmGetAttributeByRef(pDoc, "Guest.Description"));
		vBgj = AsyncCalls.StartBackgroundJob("ProlongedOperations.GetISDNewKey", vProcedureParameters, vUUID, vTtl, vTempStorageAdress);
		
		vNewRow 				= BackgroundJobsList.Add();
		vNewRow.Name 		 	= vTtl;
		vNewRow.UUID 		 	= vBgj.UUID;
		vNewRow.UUIDString 		= vUUIDSrting;
		vNewRow.ResultAddress 	= vBgj.TempStorageAddress;
		vNewRow.Status 		 	= "Processing";
		vNewRow.Start 		 	= CurrentDate();
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckBackgroundJobs()
	vProcessing = False;
	For Each Job in BackgroundJobsList Do
		vCurRow = Undefined;
		vFilter = IssuedCards.FindRows(New Structure("UUIDSrting", Job.UUIDString));
		If vFilter.Count() > 0 Then
			vCurRow = vFilter[0];
		EndIf;	
		If Job.Status = "Processing" Then
			If Not vCurRow = Undefined Then
				vCurRow.Status = PutToTempStorage(PictureLib.LongOperation16, UUID);
				vCurRow.StatusDescription= Nstr("en = 'Isuue in ISD!'; de = 'Isuue in ISD!'; ru = 'Выпускаем в ISD!'");
			EndIf;	
			vProcessing = True;
			vBackgroundJob 	= CheckBackgroundJobStatus(Job.UUID);
			
			If vBackgroundJob <> Undefined Then 
				Job.Status = vBackgroundJob.Status;
				Job.Message = vBackgroundJob.Error;
			Else
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error checking background job: " + Job.Name + "'; 
				             |ru = 'Ошибка проверки фонового задания: " + Job.Name + "';
							 |de = 'Fehler beim Überprüfen des Hintergrundjobs: " + Job.Name + "'"));
			EndIf;
		Else
			vRes = GetFromTempStorage(Job.ResultAddress);
			If TypeOf(vRes) = Type("Structure") And Not vCurRow = Undefined Then
				If vRes.Success Then
					vCurRow.Status = PutToTempStorage(PictureLib.CheckMark, UUID);
					vCurRow.StatusDescription= "";
					vCard = vCurRow.Card;
				Else
					vCurRow.Status = PutToTempStorage(PictureLib.Attention, UUID);;
					vCurRow.StatusDescription = vRes.StatusDescription;
				EndIf;
			EndIf

		EndIf;
	EndDo;
	
	If NOT vProcessing Then
		DetachIdleHandler("CheckBackgroundJobs");
		BackgroundJobsList.Clear();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function CheckBackgroundJobStatus(pBackgroundJobId)
	Return AsyncCalls.CheckBackgroundJob(pBackgroundJobId); 
EndFunction

// -----------------------------------------------------------------------------
//  Creates new or returns existing client identification card by card identifier
//
// Parameters:
//  pIdentifier				 - 	 - 
//  pIDCardRef				 - 	 - 
//  pParentDoc				 - 	 - 
//  pFolio					 - 	 - 
//  pClient					 - 	 - 
//  pRoom					 - 	 - 
//  pDateTimeFrom			 - 	 - 
//  pDateTimeTo				 - 	 - 
//  pAdd					 - 	 - 
//  pCardUID				 - 	 - 
//  pUseDeleted				 - 	 - 
//  pIdentificationCardType	 - 	 - 
// 
// Returns:
//  CatlogRef.IdentificationCards - Client identification card reference
//
&AtServer
Function GetClientIdentificationCard(pIdentifier, pIDCardRef, pParentDoc, pFolio, pClient, pRoom, pDateTimeFrom, pDateTimeTo, pAdd = True, pCardUID = Undefined, pUseDeleted = False, pIdentificationCardType = Undefined) 
	vIDCardRef = Catalogs.IdentificationCards.EmptyRef();
	// Get list of cards for the current folio
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref,
	|	IdentificationCards.Code AS Code,
	|	IdentificationCards.Description,
	|	IdentificationCards.IsBlocked,
	|	IdentificationCards.IsCheckedOut,
	|	IdentificationCards.Identifier,
	|	IdentificationCards.ParentDoc,
	|	IdentificationCards.Folio,
	|	IdentificationCards.GuestGroup,
	|	IdentificationCards.Client,
	|	IdentificationCards.Room,
	|	IdentificationCards.DateTimeFrom,
	|	IdentificationCards.DateTimeTo,
	|	IdentificationCards.Hotel,
	|	IdentificationCards.BlockReason
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	(&qUseDeleted
	|			OR NOT &qUseDeleted
	|				AND NOT IdentificationCards.DeletionMark)
	|	AND NOT IdentificationCards.IsBlocked
	|	AND (IdentificationCards.Folio = &qFolio
	|				AND &qFolioIsNotEmpty
	|			OR IdentificationCards.ParentDoc = &qParentDoc
	|				AND &qParentDocIsNotEmpty)
	|
	|ORDER BY
	|	Code";
	vQry.SetParameter("qUseDeleted", pUseDeleted);
	vQry.SetParameter("qFolio", pFolio);
	vQry.SetParameter("qFolioIsNotEmpty", ValueIsFilled(pFolio));
	vQry.SetParameter("qParentDoc", pParentDoc);
	vQry.SetParameter("qParentDocIsNotEmpty", ValueIsFilled(pParentDoc));
	vCards = vQry.Execute().Unload();
	If pAdd Or vCards.Count() = 0 Then
		// Create new client identification card
		If ValueIsFilled(pIDCardRef) Then
			vIDCardObj = pIDCardRef.GetObject();
		Else
			vIDCardObj = Catalogs.IdentificationCards.CreateItem();
			vIDCardObj.SetNewCode();
		EndIf;
		vIDCardObj.Description = ?(ValueIsFilled(pClient), TrimAll(pClient.FullName), "");
		If ValueIsFilled(pIdentifier) Then
			vIDCardObj.Identifier = pIdentifier;
		Else
			vIDCardObj.Identifier = Format(cmCastToNumber(vIDCardObj.Code), "ND=12; NFD=0; NZ=; NLZ=; NG=");
		EndIf;
		vIDCardObj.Folio = pFolio;
		vIDCardObj.ParentDoc = pParentDoc;
		vIDCardObj.GuestGroup = pParentDoc.GuestGroup;
		vIDCardObj.Client = pClient;
		vIDCardObj.Room = pRoom;
		vIDCardObj.DateTimeFrom = pDateTimeFrom;
		vIDCardObj.DateTimeTo = pDateTimeTo;
		vIDCardObj.IsBlocked = False;
		vIDCardObj.BlockReason = "";
		vIDCardObj.IsCheckedOut = ?(ValueIsFilled(pFolio), pFolio.IsClosed, False);
		vIDCardObj.Hotel = pParentDoc.Hotel;
		If pCardUID <> Undefined Then
			vIDCardObj.CardUID = TrimAll(pCardUID);
		EndIf;
		If pIdentificationCardType <> Undefined Then
			vIDCardObj.IdentificationCardType = pIdentificationCardType;
		EndIf;
		vIDCardObj.Author = SessionParameters.CurrentUser;
		vIDCardObj.CreateDate = CurrentSessionDate();
		vIDCardObj.DeletionMark = False;
		vIDCardObj.Write();
		// Get ref
		vIDCardRef = vIDCardObj.Ref;
	Else
		If vCards.Count() > 0 Then
			vIDCardRef = vCards.Get(0).Ref;
			If vIDCardRef.DeletionMark Then
				vIDCardObj = vIDCardRef.GetObject();
				vIDCardObj.SetDeletionMark(False);
			EndIf;
		EndIf;
	EndIf;
	Return vIDCardRef;
EndFunction // cmGetClientIdentificationCard

// -----------------------------------------------------------------------------
&AtServer
Procedure FillConditionalApperance()
	vQuery = New Query;
	vQuery.Text = 
		"SELECT DISTINCT
		|	IdentificationCardTypes.Ref AS Ref
		|FROM
		|	Catalog.IdentificationCardTypes AS IdentificationCardTypes";
	
	vQueryResult = vQuery.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		// New conditional appearance
		vNewConditionalAppearance = ConditionalAppearance.Items.Add();
		vNewConditionalAppearance.Appearance.Items[0].Value = vRes.Ref.Color.Get();
		vNewConditionalAppearance.Appearance.Items[0].Use = True;
		// Filter
		vNewFilterForAppearance = vNewConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilterForAppearance.LeftValue = New DataCompositionField("TargetCards.CardType");
		vNewFilterForAppearance.ComparisonType = DataCompositionComparisonType.Equal;
		vNewFilterForAppearance.RightValue = vRes.Ref;
		vNewFilterForAppearance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("TargetCardsClient");
		vNewFieldsForApperance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("TargetCardsCardType");
		vNewFieldsForApperance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("TargetCardsPeriodFrom");
		vNewFieldsForApperance.Use = True;
		// Fields
		vNewFieldsForApperance = vNewConditionalAppearance.Fields.Items.Add();
		vNewFieldsForApperance.Field = New DataCompositionField("TargetCardsPeriodTo");
		vNewFieldsForApperance.Use = True;
	EndDo;
EndProcedure // FillConditionalApperance

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetOneRoomAccommodationsWhenCheckOut(pDoc)
	// Build and run query
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	Accommodation.Ref AS Reservation,
	|	Accommodation.Number AS Number,
	|	Accommodation.Guest AS Guest,
	|	Accommodation.PointInTime AS PointInTime
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	Accommodation.GuestGroup = &qGuestGroup
	|	AND Accommodation.Posted
	|	AND Accommodation.Number = &qNumber
	|	AND Accommodation.AccommodationStatus.IsActive = TRUE
	|	AND Accommodation.AccommodationStatus.IsInHouse = FALSE
	|	AND Accommodation.AccommodationStatus.IsCheckOut = TRUE
	|
	|GROUP BY
	|	Accommodation.Ref,
	|	Accommodation.Number,
	|	Accommodation.Guest,
	|	Accommodation.PointInTime
	|
	|ORDER BY
	|	Number,
	|	PointInTime";
	vQry.SetParameter("qGuestGroup", pDoc.GuestGroup);
	vQry.SetParameter("qNumber", pDoc.Number);
	vDocs = vQry.Execute().Unload();

	Return vDocs;
EndFunction

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetTickets(Val vDoc)
	// Get Custom fields
	vFields = "NORDERBAR,NORDER,NTICKET";
	vArrFields = StrSplit(vFields,",");
	vCustFieldsValues = GetReservationCustomFieldsValues(vDoc);
	vResBarcodes = New Structure(vFields);
	For Each vRow In vCustFieldsValues Do
		vField = TrimAll(vRow.CharacteristicCode);
		If Not vArrFields.Find(vField) = Undefined Then
			vResBarcodes[vField] = vRow.CharacteristicValue;
		EndIf;
	EndDo;
	Return vResBarcodes;

EndFunction // SetParameters

// -----------------------------------------------------------------------------
&AtServer
Procedure FillLateCheckOutTickets()
	If BegOfDay(ParentDoc.CheckOutDate) <> BegOfDay(CurrentSessionDate()) Then
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The ticket can be printed only on the day of the guest''s departure'; 
					 |de = 'Das Ticket kann nur am Abreisetag des Gastes ausgedruckt werden'; 
					 |ru = 'Билет можно распечатать только в день выезда гостя'"));
		pCancel = True;
		Return;
	EndIf;
	vDocList = GetOneRoomAccommodationsWhenCheckOut(ParentDoc);
	vDoUpdateBarcodes = False;
	Tickets.Clear();
	For Each vDocRow In vDocList Do
		vNewRow = Tickets.Add();
		vNewRow.Document = vDocRow.Reservation;
		vNewRow.Client = vDocRow.Guest;
		vNewRow.Barcode = GetTickets(vNewRow.Document).NTICKET;
		If IsBlankString(vNewRow.Barcode) Then
			vDoUpdateBarcodes = True;
		EndIf;
	EndDo; 
	If vDoUpdateBarcodes Then
		ISD.EditTicket("new", ParentDoc, ParentDoc.Hotel);
		Tickets.Clear();
		For Each vDocRow In vDocList Do
			vBarcode = GetTickets(vDocRow.Reservation).NTICKET;
			If Not IsBlankString(vBarcode) Then
				vNewRow = Tickets.Add();
				vNewRow.Document = vDocRow.Reservation;
				vNewRow.Client = vDocRow.Guest;
				vNewRow.Barcode = vBarcode;
			EndIf;
		EndDo; 
	EndIf;	

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function GetGuestList()
	vList = New ValueList;
	For Each vGuestRow In Tickets Do
		vClient = vGuestRow.Client;
		If vList.FindByValue(vClient) = Undefined And Not IsBlankString(vGuestRow.Barcode) Then
			vSex = vClient.Sex;
			If ValueIsFilled(vClient.Sex) Then
				vSex = vClient.Sex;
			Else
				vSex = cmGetSexByNames(vClient.LastName, vClient.FirstName, vClient.SecondName);	
			EndIf; 
			vFIO = cmGetFullPersonName(vClient);
			vRowParams = New Structure;
			vRowParams.Insert("Client", vClient);
			vRowParams.Insert("FIO", vFIO);
			vRowParams.Insert("Barcode", vGuestRow.Barcode);
			vRowParams.Insert("CheckInDate", Format(vGuestRow.Document.CheckInDate, "DF='dd.MM.yyyy HH:mm'"));
			vRowParams.Insert("CheckOutDate", Format(vGuestRow.Document.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			vRowParams.Insert("Room", String(vGuestRow.Document.Room));
			vRowParams.Insert("Hotel", Catalogs.Hotels.pmGetHotelPrintName(vGuestRow.Document.Hotel, SessionParameters.CurrentLanguage));
			vList.Add(vRowParams,vFIO ,, ?(vSex = Enums.Sex.Male, PictureLib.Male, PictureLib.Female));
		EndIf;	
	EndDo;
	Return vList;
EndFunction // GetGuestList 

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintTickets_AfterInput(pSelectedList, pAddParams) Export 
	If TypeOf(pSelectedList) = Type("ValueList") And pSelectedList.Count()>0 Then
		vArrCashRegister = tcOnServer.cmGetAtributeAsArray(CashRegister);
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, CashRegister);
		If IsBlankString(vPasswordKKM) Then
			vPasswordKKM = TrimAll(vArrCashRegister.AccessPassword);
		EndIf;
		rMessage = "";
		vFR = Connect(rMessage, vArrCashRegister, vPasswordKKM);
		If vFR <> Undefined Then
			vFR.Password = vPasswordKKM;
			vFR.UseJournalRibbon=0; 
			vFR.UseReceiptRibbon=1;
			vFR.StringQuantity = 4;
			vFR.FeedDocument();
			vFR.CutType = True;
			vFR.CutCheck();
			For Each vRowList In pSelectedList Do
				If vRowList.Check = False Then
					 Continue;
				EndIf;	
				vRow = vRowList.Value;
				vFR.StringForPrinting = GetString("********************************************************************************", vArrCashRegister); 
				vFR.PrintString();
				vFR.StringForPrinting = " ";
				vFR.PrintString();
				// Guest
				vFR.StringForPrinting =  GetString(NStr("en = 'Client: '; de = 'Client: '; ru = 'Гость: '") + vRow.FIO, vArrCashRegister);
				vFR.PrintString();
				// Hotel
				vFR.StringForPrinting =  GetString(NStr("en = 'Hotel: '; de = 'Hotel: '; ru = 'Отель: '") + vRow.Hotel, vArrCashRegister);
				vFR.PrintString();
				// Room
				vFR.StringForPrinting =  GetString(NStr("en = 'Room: '; de = 'Room: '; ru = 'Комната: '") + vRow.Room, vArrCashRegister);
				vFR.PrintString();
				// Accommodation
				vFR.StringForPrinting =  NStr("en = 'Check-In: '; de = 'Check-In: '; ru = 'Заезд: '") + vRow.CheckInDate;
				vFR.PrintString();
				vFR.StringForPrinting =   NStr("en = 'Check-Out: '; de = 'Check-Out: '; ru = 'Выезд: '") + vRow.CheckOutDate;
				vFR.PrintString();

				vFR.StringForPrinting = " ";
				vFR.PrintString();
				vFR.StringForPrinting = GetString("********************************************************************************", vArrCashRegister); 
				vFR.PrintString();
				vFR.StringForPrinting = " ";
				vFR.PrintString();
				// Barcode
				vFR.BarCode = TrimAll(vRow.Barcode);
				vFR.LineNumber = 120;
				vFR.BarWidth = 2;
				vFR.BarcodeType = 1;
				vFR.BarcodeAlignment = 0;
				vFR.PrintBarcodeText = 1;
				vFR.PrintBarcodeLine();
				If vFR.ResultCode <> 0 Then
					tcCommonFunctionOnClientServer.UserMessage(TrimAll(vFR.ResultCodeDescription));	
					Break;
				EndIf;
				vFR.StringForPrinting = " ";
				vFR.PrintString();
				vFR.StringForPrinting = GetString("********************************************************************************", vArrCashRegister); 
				vFR.PrintString();
				vFR.StringQuantity = 4;
				vFR.FeedDocument();
				vFR.CutType = True;
				vFR.CutCheck();
			EndDo;
			Disconnect(vFR);
		Else
			tcCommonFunctionOnClientServer.UserMessage(rMessage);
			Return;
		EndIf;
	EndIf;	
EndProcedure // PrintTickets_AfterInput

// -----------------------------------------------------------------------------
&AtClient
Function Connect(rMessage, vArrCashRegister, pPassword="")
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		Try
			AttachAddIn("AddIn.DrvFR");
			vFR = New("AddIn.DrvFR");
		Except
			LoadAddIn("DrvFR.dll");
			vFR = New("AddIn.DrvFR");
		EndTry;

		// Set active logical device
		If vArrCashRegister.UseLogicalDevice And vArrCashRegister.LogicalDeviceNumber > 0 Then
			vFR.LDNumber = vArrCashRegister.LogicalDeviceNumber;
			vFR.SetActiveLD();
		EndIf;
		vFR.Password = pPassword;
		If Not IsBlankString(vArrCashRegister.DriverProtocol) And TrimAll(vArrCashRegister.DriverProtocol) = "1" Then
			vFR.ProtocolType = 1;
		EndIf;
		If Not IsBlankString(vArrCashRegister.ConnectionType) Then
			Try
				vFR.ConnectionType = Number(TrimAll(vArrCashRegister.ConnectionType));
			Except
				vFR.ConnectionType = 0;
			EndTry;
		EndIf;
		vPortNumber = GetPortNumber(vArrCashRegister);
		vBaudRate = GetBaudRate(vArrCashRegister);
		If vPortNumber > 0 Then
			If vFR.ConnectionType = 6 Then
				vFR.TCPPort = vPortNumber;
			Else
				vFR.ComNumber = vPortNumber;
			EndIf;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(vArrCashRegister.Address) Then
			vFR.ComputerName = TrimAll(vArrCashRegister.Address);
		EndIf;
		If Not IsBlankString(vArrCashRegister.OFDServer) Then
			vFR.OFDServer = TrimAll(vArrCashRegister.OFDServer);
		EndIf;
		If vArrCashRegister.OFDPort <> 0 Then
			vFR.OFDPort = vArrCashRegister.OFDPort;
		EndIf;
		If vArrCashRegister.OFDPollPeriod <> 0 Then
			vFR.OFDPollPeriod = vArrCashRegister.OFDPollPeriod;
		EndIf;
		// Try to enable device
		vFR.Connect();
		// Check result code
		If vFR.ResultCode <> 0 Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultCodeDescription);
			Return Undefined;
		Else
			// OK
			Return vFR;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
&AtClient
Procedure Disconnect(pFR)
	Try
		pFR.Disconnect();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
&AtClient
Function IsNumber(pStr)
	Try 
		vNumStr = Number(pStr);
		Return True;
	Except
	EndTry;
	Return False;
EndFunction // IsNumber

// -----------------------------------------------------------------------------
&AtClient
Function GetPortNumber(pCashRegister)
	vPort = TrimAll(pCashRegister.Port);
	If vPort = "" Then
		Return 1; //COM1 by default
	Else
		vPortNumber = 0;
		If Upper(Left(vPort, 3)) = "COM" Then
			vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
		ElsIf IsNumber(vPort) Then
			vPortNumber = Number(vPort);
		EndIf;
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
&AtClient
Function GetBaudRate(pCashRegister)
	vBaudRate = pCashRegister.BaudRate;
	If vBaudRate = 2400 Then
		Return 0;
	ElsIf vBaudRate = 4800 Then
		Return 1;
	ElsIf vBaudRate = 9600 Then
		Return 2;
	ElsIf vBaudRate = 19200 Then
		Return 3;
	ElsIf vBaudRate = 38400 Then
		Return 4;
	ElsIf vBaudRate = 57600 Then
		Return 5;
	ElsIf vBaudRate = 115200 Then
		Return 6;
	ElsIf vBaudRate = 0 Then
		Return 6;
	EndIf;		
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
&AtClient
Function GetString(pStr, pArrCashRegister)
	vChequeWidth = pArrCashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetReservationCustomFieldsValues(pDoc) 
	// Run query
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ReservationCustomAttributeValues.Characteristic AS Characteristic,
	|	ReservationCustomAttributeValues.Characteristic.Code AS CharacteristicCode,
	|	ReservationCustomAttributeValues.CharacteristicValue AS CharacteristicValue
	|FROM
	|	InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues
	|WHERE
	|	ReservationCustomAttributeValues.Owner = &qDoc
	|
	|ORDER BY
	|	ReservationCustomAttributeValues.Characteristic.SortCode,
	|	ReservationCustomAttributeValues.Characteristic.Code";
	vQry.SetParameter("qDoc", pDoc);
	vCustFieldsValues = vQry.Execute().Unload();
	Return vCustFieldsValues;
EndFunction // cmGetListOfReservationCustomFields

// -----------------------------------------------------------------------------
&AtServerNoContext
Function AllowedPrintLateCheckOutTikets(pError = "")
	// Get interaction
	vExtIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.ISD, SessionParameters.CurrentHotel);
	If Not ValueIsFilled(vExtIntegration) Then 
		pError = Nstr("en = 'Could not find ISD interaction to connect'; de = 'Es konnte keine ISD-Interaktion zum Herstellen einer Verbindung gefunden werden'; ru = 'Не удалось найти ISD взаимодействие для управления билетами'");
		Return False;
	EndIf;	 
	vCurPermissionGroups = SessionParameters.CurrentUser.PermissionGroup;
	vPermissionGroups = InformationRegisters.ExternalSystemIntegrationData.GetData(vExtIntegration, "PermissionGroups");
	If vPermissionGroups.Count()> 0 And vPermissionGroups.Find(vCurPermissionGroups) = Undefined Then
		pError = NStr("en = 'You are not authorized to print late check-out tickets'; 
					  |de = 'Sie sind nicht berechtigt, Tickets für den späten Check-out auszudrucken'; 
					  |ru = 'Нет прав на печать билетов позднего выезда'");
		Return False;
	Else	
		Return True;
	EndIf;
EndFunction	//AllowedPrintLateCheckOutTikets

// -----------------------------------------------------------------------------
&AtServerNoContext
Function AllowedSetMapping(pError = "")
	// Get interaction
	vExtIntegration = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionType(Enums.Integrations.ISD, SessionParameters.CurrentHotel);
	If Not ValueIsFilled(vExtIntegration) Then 
		pError = Nstr("en = 'Could not find ISD interaction to connect'; de = 'Es konnte keine ISD-Interaktion zum Herstellen einer Verbindung gefunden werden'; ru = 'Не удалось найти ISD взаимодействие для управления билетами'");
		Return False;
	EndIf;	 
	vCurPermissionGroups = SessionParameters.CurrentUser.PermissionGroup;
	vPermissionGroups = InformationRegisters.ExternalSystemIntegrationData.GetData(vExtIntegration, "PermissionGroupsSetMapping");
	If vPermissionGroups.Count()> 0 And vPermissionGroups.Find(vCurPermissionGroups) = Undefined Then
		pError = NStr("en = 'You do not have the right to set compliance with ISD tariffs'; 
					  |de = 'Sie haben keinen Anspruch auf Einhaltung der ISD-Tarife'; 
					  |ru = 'Нет прав устанавливать соответствие тарифам ISD'");
		Return False;
	Else	
		Return True;
	EndIf;
EndFunction	//AllowedSetMapping

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIDPresentation(pID)
	vID = pID;
	Try
		If StrLen(pID) = 20 Then
			vID = Format(Number(pID), "NG=4,4,4,4,4");
		ElsIf StrLen(pID) = 16 Then
			vID =  Format(Number(GetBinaryDataBufferFromHexString(pID).ReadInt64(0, ByteOrder.BigEndian)), "NG=4,4,4,4,4");
		EndIf;	
	Except
	EndTry;
	Return vID;
EndFunction // GetCardIDPresentation

#EndRegion



