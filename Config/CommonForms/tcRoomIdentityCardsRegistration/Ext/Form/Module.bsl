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
	// Fill card type
	CardType = Catalogs.IdentificationCardTypes.EmptyRef();
	If Parameters.Property("CardType") Then
		CardType = Parameters.CardType;
	Else
		// Try to find special card types by folio description
		vCardTypes = cmGetAllIdentificationCardTypes();
		For Each vCardTypesRow In vCardTypes Do
			If vCardTypesRow.DoNotUseChargingRules And Not IsBlankString(vCardTypesRow.AdditionalServicesFolioCondition) And 
			   ValueIsFilled(Folio) And StrFind(Upper(TrimAll(Folio.Description)), Upper(TrimAll(vCardTypesRow.AdditionalServicesFolioCondition))) > 0 Then
				CardType = vCardTypesRow.IdentificationCardType;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(CardType) Then
		If ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(ParentDoc) = Type("DocumentRef.Reservation")) Then
			If ValueIsFilled(ParentDoc.RoomRate) And ValueIsFilled(ParentDoc.RoomRate.IdentificationCardType) Then
				CardType = ParentDoc.RoomRate.IdentificationCardType;
			EndIf;
			vBindingsCardType = cmGetRoomRateBindingsCardType(ParentDoc);
			If ValueIsFilled(vBindingsCardType) Then
				CardType = vBindingsCardType;
			EndIf;
		ElsIf ValueIsFilled(IdentityCardSystemParameters) And ValueIsFilled(IdentityCardSystemParameters.IdentificationCardType) Then
			CardType = IdentityCardSystemParameters.IdentificationCardType;
		EndIf;
	EndIf;
	If ValueIsFilled(CardType) Then
		vCardTypeColor = CardType.Color.Get();
		If vCardTypeColor <> Undefined And TypeOf(vCardTypeColor) = Type("Color") Then
			Items.CardType.BackColor = vCardTypeColor;
		EndIf;
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
			If TargetCards.Total("Quantity") = 0 Then
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
			If TargetCards.Total("Quantity") = 0 Then
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
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		CardData = vEventData.DeviceData
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure IssuedCardsCardCodeStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.IssuedCards.CurrentData;
	If vCurRow <> Undefined Then
		If Not IsBlankString(vCurRow.CardCode) Then
			vCardRef = GetClientIdentificationCardById(TrimAll(vCurRow.CardCode));
			If ValueIsFilled(vCardRef) Then
				vDoOperation = False;
				vBlockReason = "";
				If Not tcOnServer.cmGetAttributeByRef(vCardRef, "IsBlocked") Then
					// Ask user if he really wants to block card
					ShowQueryBox(New NotifyDescription("AfterBlockCardConfirmation", ThisForm, New Structure("CardRef", vCardRef)), NStr("en='Do you want to block this card?'; ru='Хотите заблокировать карту?'; de='Wollen Sie die Karte zu blokieren?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
				Else
					// Ask user if he really wants to unblock card
					ShowQueryBox(New NotifyDescription("AfterUnblockCardConfirmation", ThisForm, New Structure("CardRef", vCardRef)), NStr("en='Do you want to unblock this card?'; ru='Хотите снять блокировку с карты?'; de='Wollen Sie die Karte zu unblokieren?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IssuedCardsCardCodeStartChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure IssuedCardsCardCodeClearing(pItem, pStandardProcessing)
	pStandardProcessing = False;
	vCurRow = Items.IssuedCards.CurrentData;
	If vCurRow <> Undefined Then
		If Not IsBlankString(vCurRow.CardCode) Then
			vCardRef = GetClientIdentificationCardById(TrimAll(vCurRow.CardCode));
			If ValueIsFilled(vCardRef) Then
				vDoOperation = False;
				// Ask user if he really wants to delete card
				ShowQueryBox(New NotifyDescription("DeleteSelectedCard", ThisForm, New Structure("CardRef", vCardRef)), NStr("en='Do you want to delete this card?'; ru='Хотите удалить карту?'; de='Wollen Sie die Karte zu löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IssuedCardsCardCodeClearing

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RegisterNewCardAtClient(pCommand)
	ShowStatusMessage(NStr("en='Slip new card to read it!';ru='Прокатайте новую карту!';de='Ziehen Sie eine neue Karte durch!'"));
	// Clear card data
	CardData = "";
	// Show card data
	Items.CardData.Visible = True;
	// Enable card data input
	Items.CardData.ReadOnly = False;
	ThisForm.CurrentItem = Items.CardData;
	// Guest to process first
	vGuestsInRoomRow = Undefined;
	vNumberOfIssuedCards = IssuedCards.Total("Quantity");
	For Each vGuestsInRoomRow In GuestsInRoom Do
		If Not vGuestsInRoomRow.Processed Then
			Break;
		Else
			vGuestsInRoomRow = Undefined;
		EndIf;
	EndDo;
	If vGuestsInRoomRow <> Undefined Then
		ShowClientStatusMessage(vGuestsInRoomRow);
	EndIf;
	// Wait for card to be read	
	AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
EndProcedure // RegisterNewCardAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockCardsAtClient(pCommand)
	// Detach handlers
	DetachIdleHandler("CheckNewCardWasRead");
	// Clear card data
	CardData = "";
	// Block card data input
	Items.CardData.ReadOnly = True;
	// Hide card data
	Items.CardData.Visible = False;
	// Show what user have to do
	ShowStatusMessage(NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"));
	vBlockReason = "";
	ShowInputString(New NotifyDescription("AfterBlockReasonInputForAllCards", ThisForm), vBlockReason, NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"), 100, False);
EndProcedure // BlockCardsAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteCardsAtClient(pCommand)
	// Ask user if he really wants to delete cards
	ShowQueryBox(New NotifyDescription("AfterDeleteCardsConfirmation", ThisForm), NStr("en='Do you want to delete all folio cards?'; ru='Хотите удалить все выданные по фолио карты?'; de='Wollen Sie alle Folio Karten zu löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // DeleteCardsAtClient

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteCards()
	Try
		// Check should we reuse deleted cards
		vUseDeleted = IdentityCardSystemParameters.UseDeleted;
		If ValueIsFilled(Room) And ValueIsFilled(ParentDoc) Then
			// Get all cards for the current parent document
			vCards = cmGetClientIdentificationCardsByRoom(Room, False, ParentDoc.GuestGroup);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
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
			EndDo;
		ElsIf ValueIsFilled(ParentDoc) Then
			// Get all cards for the current parent document
			vCards = cmGetClientIdentificationCardsByParentDoc(ParentDoc);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
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
			EndDo;
		ElsIf ValueIsFilled(Folio) Then
			// Get all cards for the current folio
			vCards = cmGetClientIdentificationCardsByFolio(Folio);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
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
			EndDo;
			// Success
			ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
			// Clear cards are blocked
			CardsAreBlocked = False;
		Else
			ShowStatusMessage(NStr("en='Neither room nor folio is specified!';ru='Не указан ни номер комнаты ни лицевой счет, по которому удалять карты идентификации клиента!';de='Weder das Zimmer, noch das Personenkonto sind angegeben, über die die Identifikationskarten des Kunden gelöscht werden sollen!'"), True);
		EndIf;
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
Procedure BlockCards(pBlockReason)
	Try
		If ValueIsFilled(Room) And ValueIsFilled(ParentDoc) Then
			// Get all cards for the current room
			vCards = cmGetClientIdentificationCardsByRoom(Room, False, ParentDoc.GuestGroup);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
				// Skip cards already blocked
				If vCardRef.IsBlocked Then
					Continue;
				EndIf;
				// Block card
				vCardObj = vCardRef.GetObject();
				vCardObj.IsBlocked = True;
				vCardObj.BlockReason = pBlockReason;
				vCardObj.Write();
			EndDo;
		ElsIf ValueIsFilled(ParentDoc) Then
			// Get all cards for the current parent document
			vCards = cmGetClientIdentificationCardsByParentDoc(ParentDoc);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
				// Skip cards already blocked
				If vCardRef.IsBlocked Then
					Continue;
				EndIf;
				// Block card
				vCardObj = vCardRef.GetObject();
				vCardObj.IsBlocked = True;
				vCardObj.BlockReason = pBlockReason;
				vCardObj.Write();
			EndDo;
		ElsIf ValueIsFilled(Folio) Then
			// Get all cards for the current folio
			vCards = cmGetClientIdentificationCardsByFolio(Folio);
			For Each vCardsRow In vCards Do
				vCardRef = vCardsRow.Ref;
				// Skip cards already blocked
				If vCardRef.IsBlocked Then
					Continue;
				EndIf;
				// Block card
				vCardObj = vCardRef.GetObject();
				vCardObj.IsBlocked = True;
				vCardObj.BlockReason = pBlockReason;
				vCardObj.Write();
			EndDo;
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
			ShowStatusMessage(NStr("en='Choose action';ru='Выберите действие';de='Wählen Sie die Aktion'"));
		Else
			ShowStatusMessage(NStr("en='Neither room nor folio is specified!';ru='Не указан ни номер комнаты ни лицевой счет, по которому блокировать карты идентификации!';de='Weder das Zimmer, noch das Personenkonto sind angegeben, über die die Identifikationskarten blockiert werden sollen!'"), True);
		EndIf;
	Except
		ShowStatusMessage(NStr("en='Client identification cards block error: ';ru='Ошибка блокировки карт идентификации клиентов: ';de='Fehler in der Kartenblockierung und Kundenidentifizierung: '") + ErrorDescription(), True);
	EndTry;
EndProcedure // BlockCards

// -----------------------------------------------------------------------------
&AtServer
Procedure BlockCardsAtServer(pBlockReason)
	// Block cards at server
	BlockCards(pBlockReason);
	// Fill list of cards to be issued
	FillToBeIssuedCards();
	// Fill issued cards list
	FillIssuedCards();
EndProcedure // BlockCards

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterBlockReasonInputForAllCards(pBlockReason, pExtraParams) Export
	If pBlockReason <> Undefined Then
		BlockCardsAtServer(pBlockReason);
	EndIf;
EndProcedure // BlockCards

// -----------------------------------------------------------------------------
&AtServer
Function RegisterNewCard(pCardData, pIsMaster = False, pCardType = Undefined, pFolio = Undefined, pParentDoc = Undefined, pClient = Undefined) Export
	vExternalSystemInteraction = IdentityCardSystemParameters.ExternalInteraction;
	vFolio = Folio;
	If ValueIsFilled(pFolio) Then
		vFolio = pFolio;
	EndIf;
	// Add/get client identification card
	If ValueIsFilled(vFolio) Then
		// Get card identifier
		vCardID = cmGetCardIdentifier(pCardData);
		// Check should we reuse deleted cards
		vUseDeleted = IdentityCardSystemParameters.UseDeleted;
		// Check if card with this identifier already exists
		vIDCardRef = Undefined;
		If vUseDeleted Then
			vIDCardRef = cmGetClientIdentificationCardById(vCardID, vUseDeleted);
			If ValueIsFilled(vIDCardRef) Then
				If Not vIDCardRef.DeletionMark Then
					If ValueIsFilled(vIDCardRef.Folio) And Not vIDCardRef.Folio.IsClosed Then
						ShowStatusMessage(NStr("en='You are processing card that is already in use!';ru='Взяли карту, которая уже выдана на другого клиента!';de='Verwenden Sie die Karte, die bereits auf einem anderen Client aufgeführt ist!'"), True);
						Return False;
					EndIf;
				EndIf;
				If vIDCardRef.IdentificationCardType <> pCardType Then
					ShowStatusMessage(NStr("en='You are processing card with wrong type!';ru='Взяли карту не того типа!';de='Sie halten die falsche Type von Karte!'"), True);
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
		vIDCardRef = cmGetClientIdentificationCard(vCardID, vIDCardRef, ?(pParentDoc <> Undefined, pParentDoc, vFolio.ParentDoc), vFolio, ?(pClient <> Undefined, pClient, vFolio.Client), vFolio.Room, vFolio.DateTimeFrom, vFolio.DateTimeTo, True, , vUseDeleted);
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
	Else
		ShowStatusMessage(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"), True);
		Return False;
	EndIf;
	// Return success
	Return True;
EndFunction // RegisterNewCard

// -----------------------------------------------------------------------------
&AtServer
Function GetRoomExtraServicesFolioByDescription(pFolioDescription)
	vFolio = Undefined;
	If ValueIsFilled(Folio) And ValueIsFilled(Folio.GuestGroup) And ValueIsFilled(Folio.Room) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Folio.Ref AS Folio
		|FROM
		|	Document.Folio AS Folio
		|WHERE
		|	NOT Folio.DeletionMark
		|	AND NOT Folio.IsClosed
		|	AND Folio.Room = &qRoom
		|	AND Folio.GuestGroup = &qGuestGroup
		|	AND Folio.Description LIKE &qDescription
		|
		|ORDER BY
		|	Folio.Date DESC";
		vQry.SetParameter("qGuestGroup", Folio.GuestGroup);
		vQry.SetParameter("qRoom", Folio.Room);
		vQry.SetParameter("qDescription", "%" + pFolioDescription + "%");
		vFolios = vQry.Execute().Unload();
		If vFolios.Count() > 0 Then
			vFolio = vFolios.Get(0).Folio;
		EndIf;
	EndIf;
	Return vFolio;
EndFunction // GetRoomExtraServicesFolioByDescription

// -----------------------------------------------------------------------------
&AtServer
Function RegisterNewSpecialCard(pIDCardRef, pCardType = Undefined, pDoNotSearchFolio = False)
	// Add/get client identification card
	If ValueIsFilled(Folio) Then
		If Not ValueIsFilled(pIDCardRef) Then
			ShowStatusMessage(NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"), True);
			Return False;
		EndIf;
		// Get main room folio
		vFolio = Folio;
		If Not pDoNotSearchFolio Then
			If ValueIsFilled(pIDCardRef.IdentificationCardType) And ValueIsFilled(Folio.GuestGroup) And ValueIsFilled(Folio.Room) Then
				vFolioDescription = TrimAll(pIDCardRef.IdentificationCardType.AdditionalServicesFolioCondition);
				If Not IsBlankString(vFolioDescription) Then
					vFolio = GetRoomExtraServicesFolioByDescription(vFolioDescription);
					If Not ValueIsFilled(vFolio) Then
						ShowStatusMessage(NStr("en='Folio is not found for type ';ru='Не найден лицевой счет с описанием ';de='Das Personenkonto ist nicht gefunden! Personenkonto Beschreibung ist '") + vFolioDescription + "!", True);
						Return False;
					EndIf;
				EndIf;
			EndIf;
		Else
			If pCardType <> Undefined Then
				If pIDCardRef.IdentificationCardType <> pCardType Then
					ShowStatusMessage(NStr("en='You are processing card with wrong type!';ru='Взяли карту не того типа!';de='Sie halten die falsche Type von Karte!'"), True);
					Return False;
				EndIf;
			EndIf;
		EndIf;
		// Update client identification card
		vIDCardObj = pIDCardRef.GetObject();
		vIDCardObj.Description = ?(ValueIsFilled(vFolio.Client), TrimAll(vFolio.Client.FullName), "");
		vIDCardObj.Folio = vFolio;
		vIDCardObj.ParentDoc = vFolio.ParentDoc;
		vIDCardObj.GuestGroup = vFolio.GuestGroup;
		vIDCardObj.Client = vFolio.Client;
		vIDCardObj.Room = vFolio.Room;
		vIDCardObj.DateTimeFrom = vFolio.DateTimeFrom;
		vIDCardObj.DateTimeTo = vFolio.DateTimeTo;
		vIDCardObj.IsBlocked = False;
		vIDCardObj.BlockReason = "";
		vIDCardObj.IsCheckedOut = vFolio.IsClosed;
		vIDCardObj.Hotel = vFolio.Hotel;
		vIDCardObj.Author = SessionParameters.CurrentUser;
		vIDCardObj.CreateDate = CurrentSessionDate();
		vIDCardObj.DeletionMark = False;
		vIDCardObj.Write();
	Else
		ShowStatusMessage(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"), True);
		Return False;
	EndIf;
	// Return success
	Return True;
EndFunction // RegisterNewSpecialCard

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
		DeleteCards();
	EndIf;
EndProcedure // AfterDeleteCardsConfirmation

// -----------------------------------------------------------------------------
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
		ShowStatusMessage(NStr("en='Slip new card to read it!';ru='Прокатайте новую карту!';de='Ziehen Sie eine neue Karte durch!'") + Chars.LF + vClientFullName + ?(IsBlankString(vClientAccommodationType), "", " " + vClientAccommodationType));
	Else
		vCardTypeColor = GetColorAtServer(vCardType);
		ShowStatusMessage(NStr("en='Slip new card to read it!';ru='Прокатайте новую карту!';de='Ziehen Sie eine neue Karte durch!'") + Chars.LF + NStr("en='Card type is ';ru='Тип карты: ';de='Karten-Typ ist '") + TrimAll(tcOnServer.cmGetAttributeByRef(vCardType, "Description")) + ?(IsBlankString(tcOnServer.cmGetAttributeByRef(vCardType, "ColorName")), "", " (" + TrimAll(tcOnServer.cmGetAttributeByRef(vCardType, "ColorName")) + ")") + Chars.LF + vClientFullName + ?(IsBlankString(vClientAccommodationType), "", " " + vClientAccommodationType), , vCardTypeColor);
	EndIf;
EndProcedure // ShowClientStatusMessage

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfThisIsSpecialCardAtServer()
	vIDCardRef = cmGetClientIdentificationCardById(cmGetCardIdentifier(CardData), True);
	If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.IdentificationCardType) And 
	   vIDCardRef.IdentificationCardType.DoNotUseChargingRules And 
	   Not IsBlankString(vIDCardRef.IdentificationCardType.AdditionalServicesFolioCondition) Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckIfThisIsSpecialCardAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckNewCardWasRead()
	If IsBlankString(CardData) Then
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		Return;
	EndIf;
	// Check if this card was already registered
	vIssuedCardsRows = IssuedCards.FindRows(New Structure("CardCode", CardData));
	If vIssuedCardsRows.Count() > 0 Then
		ShowStatusMessage(NStr("en='This card is already registered!';ru='Эта карта уже зарегистрирована!';de='Diese Karte ist bereits registriert!'"));
		// Clear card data
		CardData = "";
		// Wait for card to be read	
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		Return;
	EndIf;
	// Delete previous client or folio cards if necessary
	If ValueIsFilled(IdentityCardSystemParameters) And tcOnServer.cmGetAttributeByRef(IdentityCardSystemParameters, "DeletePreviousClientCardsBeforeIssuingNew") Then
		DeleteCards();
	EndIf;
	// Check card type and if it is special then bind this card directly to the folio selected
	If CheckIfThisIsSpecialCardAtServer() Then
		vIDCardRef = GetClientIdentificationCardById(GetCardIdentifier(CardData), True);
		If RegisterNewSpecialCard(vIDCardRef) Then
			ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
			AttachIdleHandler("CloseForm", 1, True);
			// Fill list of cards to be issued
			FillToBeIssuedCards();
			// Fill issued cards list
			FillIssuedCards();
		Else
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
			// Clear cards are blocked
			CardsAreBlocked = False;
		EndIf;
		Return;
	Else
		// Check if there are issued cards
		If IssuedCards.Count() > 0 Then
			If TargetCards.Total("Quantity") = 0 Then
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
			If TargetCards.Total("Quantity") = 0 Then
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
			Return;
		EndIf;
	EndIf;
	// Register new card
	vIsMaster = False;
	// Get client row to be processed
	vGuestsInRoomRow = Undefined;
	For Each vGuestsInRoomRow In GuestsInRoom Do
		If Not vGuestsInRoomRow.Processed Then
			Break;
		EndIf;
	EndDo;
	// Register new card
	If RegisterNewCard(CardData, vIsMaster, vGuestsInRoomRow.CardType, vGuestsInRoomRow.Folio, vGuestsInRoomRow.Document, vGuestsInRoomRow.Client) Then
		ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
		// Check should we issue next new card
		vReadNextCard = False;
		vProcessedIsSet = False;
		vGuestsInRoomRow = Undefined;
		For Each vGuestsInRoomRow In GuestsInRoom Do
			If Not vGuestsInRoomRow.Processed Then
				If Not vProcessedIsSet Then
					vGuestsInRoomRow.Processed = True;
					vProcessedIsSet = True;
					// Fill list of cards to be issued
					FillToBeIssuedCards(False);
					// Fill issued cards list
					FillIssuedCards();
				Else
					vReadNextCard = True;
					// Get type of card to be read
					ShowClientStatusMessage(vGuestsInRoomRow);
					// Clear card data
					CardData = "";
					// Show card data
					Items.CardData.Visible = True;
					// Enable card data input
					Items.CardData.ReadOnly = False;
					// Wait for card to be read	
					AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
					// Go out to avoid recursion
					Return;
				EndIf;
			EndIf;
		EndDo;
		// Go out 
		If Not vReadNextCard Then
			// Clear processed cards column
			For Each vGuestsInRoomRow In GuestsInRoom Do
				vGuestsInRoomRow.Processed = False;
			EndDo;
			// Close form if everything is OK
			AttachIdleHandler("CloseForm", 1, True);
		EndIf;
		// Fill list of cards to be issued
		FillToBeIssuedCards();
		// Fill issued cards list
		FillIssuedCards();
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
	// Read this room guests from the database
	If ValueIsFilled(Room) Then
		vGuests = cmGetOneRoomAccommodations(Room, ?(ValueIsFilled(Folio), Folio.GuestGroup, Catalogs.GuestGroups.EmptyRef()), CheckInDate, CheckOutDate);
		If vGuests.Count() = 0 And ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
			vGuests = cmGetOneRoomReservations(TrimAll(ParentDoc.Number), ?(ValueIsFilled(Folio), Folio.GuestGroup, Catalogs.GuestGroups.EmptyRef()), CheckInDate, CheckOutDate);
		EndIf;			
	ElsIf ValueIsFilled(Folio) Then
		vGuests = New ValueTable();
		vGuests.Columns.Add("Ref");
		vGuestsRow = vGuests.Add();
		vGuestsRow.Ref = Folio;
	EndIf;
	If vGuests.Count() > 0 Then
		vCards = New Valuetable();
		vCards.Columns.Add("CardType", cmGetCatalogTypeDescription("IdentificationCardTypes"));
		vCards.Columns.Add("Quantity", cmGetNumberTypeDescription(6, 0));
		vCards.Columns.Add("SortCode", cmGetNumberTypeDescription(6, 0));
		For Each vGuestsRow In vGuests Do
			vDocRef = vGuestsRow.Ref;
			vFolio = Undefined;
			vQuantity = 1;
			vCardType = Catalogs.IdentificationCardTypes.EmptyRef();
			If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(vDocRef) = Type("DocumentRef.Reservation") Then
				If ValueIsFilled(vDocRef.AccommodationType) And vDocRef.AccommodationType.DoNotIssueKeyCards Then
					Continue;
				EndIf;
				If ValueIsFilled(vDocRef.RoomRate) And ValueIsFilled(vDocRef.RoomRate.IdentificationCardType) Then
					vCardType = vDocRef.RoomRate.IdentificationCardType;
				EndIf;
				vBindingsCardType = cmGetRoomRateBindingsCardType(vDocRef);
				If ValueIsFilled(vBindingsCardType) Then
					vCardType = vBindingsCardType;
				EndIf;
				If ValueIsFilled(vDocRef.ServicePackage) And ValueIsFilled(vDocRef.ServicePackage.IdentificationCardType) Then
					vCardType = vDocRef.ServicePackage.IdentificationCardType;
				EndIf;
				vFolio = GetClientFolio(vDocRef.GuestGroup, vDocRef.Room, vDocRef.Guest, vDocRef);
				If Not ValueIsFilled(vFolio) Then
					Continue;
				EndIf;
				vQuantity = vDocRef.NumberOfPersons;
			ElsIf TypeOf(vDocRef) = Type("DocumentRef.ResourceReservation") Then
				If ValueIsFilled(vDocRef.ServicePackage) And ValueIsFilled(vDocRef.ServicePackage.IdentificationCardType) Then
					vCardType = vDocRef.ServicePackage.IdentificationCardType;
				EndIf;
				vFolio = vDocRef.ChargingFolio;
			ElsIf TypeOf(vDocRef) = Type("DocumentRef.Folio") Then
				vCardType = IdentityCardSystemParameters.IdentificationCardType;
				vFolio = vDocRef;
			EndIf;
			// Add row to cards
			vCardsRow = vCards.Add();
			vCardsRow.Quantity = vQuantity;
			vCardsRow.CardType = vCardType;
			If ValueIsFilled(vCardsRow.CardType) Then
				vCardsRow.SortCode = vCardsRow.CardType.SortCode;
			Else
				vCardsRow.SortCode = 999999;
			EndIf;
			// Add row to room guests
			If pInitializeGuestsInRoom Then
				vGuestsInRoomRow = GuestsInRoom.Add();
				vGuestsInRoomRow.Document = vDocRef;
				vGuestsInRoomRow.Hotel = vDocRef.Hotel;
				vGuestsInRoomRow.GuestGroup = vDocRef.GuestGroup;
				vGuestsInRoomRow.Folio = vFolio;
				If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(vDocRef) = Type("DocumentRef.Reservation") Then
					vGuestsInRoomRow.Room = vDocRef.Room;
					vGuestsInRoomRow.Client = vDocRef.Guest;
					vGuestsInRoomRow.DateTimeFrom = vDocRef.CheckInDate;
					vGuestsInRoomRow.DateTimeTo = vDocRef.CheckOutDate;
					vGuestsInRoomRow.AccommodationType = vDocRef.AccommodationType;
					vGuestsInRoomRow.AccommodationTypeSortCode = vDocRef.AccommodationType.SortCode;
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.ResourceReservation") Then
					vGuestsInRoomRow.Client = vDocRef.Client;
					vGuestsInRoomRow.DateTimeFrom = vDocRef.DateTimeFrom;
					vGuestsInRoomRow.DateTimeTo = vDocRef.DateTimeTo;
					vGuestsInRoomRow.AccommodationTypeSortCode = 0;
				ElsIf TypeOf(vDocRef) = Type("DocumentRef.Folio") Then
					vGuestsInRoomRow.Client = vDocRef.Client;
					vGuestsInRoomRow.DateTimeFrom = vDocRef.DateTimeFrom;
					vGuestsInRoomRow.DateTimeTo = vDocRef.DateTimeTo;
					vGuestsInRoomRow.AccommodationTypeSortCode = 0;
				EndIf;
				vGuestsInRoomRow.CardType = vCardType;
				If ValueIsFilled(vCardType) Then
					vGuestsInRoomRow.CardTypeSortCode = vCardType.SortCode;
				Else
					vGuestsInRoomRow.CardTypeSortCode = 0;
				EndIf;
			EndIf;
		EndDo;
		vCards.GroupBy("CardType, SortCode", "Quantity");
		vCards.Sort("SortCode");
		TargetCards.Clear();
		For Each vCardsRow In vCards Do
			vTargetCardsRow = TargetCards.Add();
			FillPropertyValues(vTargetCardsRow, vCardsRow);
		EndDo;
		vGuestsInRoom = FormAttributeToValue("GuestsInRoom", Type("ValueTable"));
		vGuestsInRoom.Sort("DateTimeFrom, AccommodationTypeSortCode, CardTypeSortCode");
		ValueToFormAttribute(vGuestsInRoom, "GuestsInRoom");
	Else
		// Show attention message
		If ValueIsFilled(Room) Then
			ShowStatusMessage(NStr("en='Room is vacant!';ru='В номере никто не проживает!';de='Zimmer ist frei!'"), True);
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
		Else
			ShowStatusMessage(NStr("en='Form parameters are empty!';ru='Не заполнены параметры формы!';de='Formparameteren nicht gefüllt!'"), True);
			// Clear card data
			CardData = "";
			// Block card data input
			Items.CardData.ReadOnly = True;
			// Hide card data
			Items.CardData.Visible = False;
		EndIf;
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
		EndDo;
		vCards.GroupBy("CardType, CardCode, SortCode, Document, IsBlocked", "Quantity");
		vCards.Sort("SortCode");
		For Each vCardsRow In vCards Do
			vIssuedCardsRow = IssuedCards.Add();
			FillPropertyValues(vIssuedCardsRow, vCardsRow);
		EndDo;
		// Fix cards to be issued and mark clients as processed
		vTargetCards = FormAttributeToValue("TargetCards", Type("ValueTable"));
		vGuestsInRoom = FormAttributeToValue("GuestsInRoom", Type("ValueTable"));
		For Each vIssuedCardsRow In IssuedCards Do
			// Card type totals
			vCardsRow = vTargetCards.Find(vIssuedCardsRow.CardType, "CardType");
			If vCardsRow <> Undefined Then
				vCardsRow.Quantity = vCardsRow.Quantity - 1;
				If vCardsRow.Quantity <= 0 Then
					vTargetCards.Delete(vCardsRow);
				EndIf;
			EndIf;
			// Clients
			If ValueIsFilled(vIssuedCardsRow.Document) Then
				vClientRow = vGuestsInRoom.Find(vIssuedCardsRow.Document, "Document");
				If vClientRow <> Undefined Then
					vClientRow.Processed = True;
				EndIf;
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
&AtClient
Procedure DeleteSelectedCard(pAnswer, pExtraParams) Export
	If pAnswer = DialogReturnCode.Yes Then
		// Check should we reuse deleted cards
		DeleteSelectedCardAtServer(pExtraParams.CardRef);
	EndIf;
EndProcedure // DeleteSelectedCard

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteSelectedCardAtServer(pCardRef)
	// Check should we reuse deleted cards
	vUseDeleted = IdentityCardSystemParameters.UseDeleted;
	vCardObj = pCardRef.GetObject();
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
	// Fill list of cards to be issued
	FillToBeIssuedCards();
	// Refresh list of cards
	FillIssuedCards();
EndProcedure // DeleteSelectedCardAtServer

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetClientIdentificationCardById(pCardCode, pUseDeleted = False)
	Return cmGetClientIdentificationCardById(pCardCode, pUseDeleted);
EndFunction // GetClientIdentificationCardById

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetCardIdentifier(pCardData)
	Return cmGetCardIdentifier(pCardData);
EndFunction // GetCardIdentifier

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterBlockCardConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		vBlockReason = "";
		ShowInputString(New NotifyDescription("AfterBlockReasonInput", ThisForm, pExtraParams), vBlockReason, NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"), 100, False);
	EndIf;
EndProcedure // AfterBlockCardConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUnblockCardConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		BlockCardAtServer(pExtraParams.CardRef, "");
	EndIf;
EndProcedure // AfterBlockCardConfirmation

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterBlockReasonInput(pBlockReason, pExtraParams) Export
	BlockCardAtServer(pExtraParams.CardRef, pBlockReason);
EndProcedure // AfterBlockCardConfirmation

// -----------------------------------------------------------------------------
&AtServer
Procedure BlockCardAtServer(pCardRef, pBlockReason)
	// Get card object
	vCardObj = pCardRef.GetObject();
	vCardObj.DeletionMark = False;
	vCardObj.IsBlocked = Not vCardObj.IsBlocked;
	vCardObj.BlockReason = pBlockReason;
	vCardObj.Write();
	// Fill list of cards to be issued
	FillToBeIssuedCards();
	// Refresh list of cards
	FillIssuedCards();
EndProcedure // BlockCardAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseForm()
	Close();
EndProcedure // CloseForm

#EndRegion



