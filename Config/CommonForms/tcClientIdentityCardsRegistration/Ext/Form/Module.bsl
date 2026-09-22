
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Parameters
	IdentityCardSystemParameters = Undefined;
	If Parameters.Property("IdentityCardSystemParameters") Then
		IdentityCardSystemParameters = Parameters.IdentityCardSystemParameters;
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
	// Fill list of cards already being issued
	FillIssuedCards();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Wait for new card to be read
	If Not CardsAreBlocked Then
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

#Region FormHeaderItemsEventHandlers

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
				ShowQueryBox(New NotifyDescription("DeleteSelectedCard", ThisObject, New Structure("CardRef", vCardRef)), NStr("en='Do you want to delete this card?'; ru='Хотите удалить карту?'; de='Wollen Sie die Karte zu löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IssuedCardsCardCodeClearing

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
					vQ = NStr("en = 'Do you want to block this card?'; de = 'Wollen Sie die Karte zu blokieren?'; ru = 'Хотите заблокировать карту?'");
					ShowQueryBox(New NotifyDescription("AfterBlockCardConfirmation", ThisObject, New Structure("CardRef", vCardRef)), vQ, QuestionDialogMode.YesNo, , DialogReturnCode.No);
				Else
					// Ask user if he really wants to unblock card    
					vQ = NStr("en = 'Do you want to unblock this card?'; de = 'Wollen Sie die Karte zu unblokieren?'; ru = 'Хотите снять блокировку с карты?'");
					ShowQueryBox(New NotifyDescription("AfterUnblockCardConfirmation", ThisObject, New Structure("CardRef", vCardRef)), vQ, QuestionDialogMode.YesNo, , DialogReturnCode.No);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // IssuedCardsCardCodeStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RegisterNewCardAtClient(pCommand)
	ShowStatusMessage(NStr("en = 'Slip new card to read it!'; de = 'Ziehen Sie eine neue Karte durch!'; ru = 'Прокатайте новую карту!'"));
	// Clear card data
	CardData = "";
	// Show card data
	Items.CardData.Visible = True;
	// Enable card data input
	Items.CardData.ReadOnly = False;
	CurrentItem = Items.CardData;
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
	ShowStatusMessage(NStr("en = 'Enter block reason, please!'; de = 'Geben Sie den Grund für die Reservierung an!'; ru = 'Укажите причину блокировки!'"));
	vBlockReason = "";   
	vTitle = NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'");
	ShowInputString(New NotifyDescription("AfterBlockReasonInputForAllCards", ThisObject), vBlockReason, vTitle, 100, False);
EndProcedure // BlockCardsAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteCardsAtClient(pCommand)
	// Ask user if he really wants to delete cards        
	vQ = NStr("en='Do you want to delete all folio cards?'; ru='Хотите удалить все выданные по фолио карты?'; de='Wollen Sie alle Folio Karten zu löschen?'");
	ShowQueryBox(New NotifyDescription("AfterDeleteCardsConfirmation", ThisObject), vQ, QuestionDialogMode.YesNo, , DialogReturnCode.No);
EndProcedure // DeleteCardsAtClient

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure BlockFolioCards(pBlockReason)
	Try
		If ValueIsFilled(ParentDoc) Then
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
			ShowStatusMessage(NStr("en = 'Choose action'; de = 'Wählen Sie die Aktion'; ru = 'Выберите действие'"));
		Else
			ShowStatusMessage(NStr("en = 'Neither parent document nor folio is specified!'; 
								   |de = 'Weder das Dokument, noch die Begründung, noch das Personenkonto sind angegeben, über die die Identifikationskarten des Kunden blockiert werden sollen!'; 
								   |ru = 'Не указан ни документ основание ни лицевой счет, по которому блокировать карты идентификации клиента!'"), True);
		EndIf;
	Except
		ShowStatusMessage(NStr("en = 'Client identification cards block error: '; de = 'Fehler in der Kartenblockierung und Kundenidentifizierung: '; ru = 'Ошибка блокировки карт идентификации клиентов: '") + ErrorDescription(), True);
	EndTry;
EndProcedure // BlockFolioCards

// -----------------------------------------------------------------------------
&AtServer
Procedure BlockCardsAtServer(pBlockReason)
	// Block cards at server
	BlockFolioCards(pBlockReason);
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
Procedure DeleteFolioCards()
	Try
		// Check should we reuse deleted cards
		vUseDeleted = IdentityCardSystemParameters.UseDeleted;
		If ValueIsFilled(ParentDoc) Then
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
			ShowStatusMessage(NStr("en = 'Success'; de = 'Erfolgreich'; ru = 'Успешно'"));
			// Clear cards are blocked
			CardsAreBlocked = False;
		Else
			ShowStatusMessage(NStr("en = 'Neither parent document nor folio is specified!'; 
								   |de = 'Weder das Dokument, noch die Begründung, noch das Personenkonto sind angegeben, über die die Identifikationskarten des Kunden gelöscht werden sollen!'; 
								   |ru = 'Не указан ни документ основание ни лицевой счет, по которому удалять карты идентификации клиента!'"), True);
		EndIf;
	Except
		ShowStatusMessage(NStr("en = 'Client identification cards deletion error: '; 
							   |de = 'Fehler beim Löschen der Kundenidentifikationskarten: '; 
							   |ru = 'Ошибка удаления карт идентификации клиентов: '") + ErrorDescription(), True);
	EndTry;
	// Fill issued cards list
	FillIssuedCards();
EndProcedure // DeleteFolioCards

// -----------------------------------------------------------------------------
&AtServer
Function RegisterNewCard(pCardData, pIsMaster = False, pCardType = Undefined, pFolio = Undefined, pParentDoc = Undefined, pClient = Undefined) Export
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
						ShowStatusMessage(NStr("en = 'You are processing card that is already in use!'; 
											   |de = 'Verwenden Sie die Karte, die bereits auf einem anderen Client aufgeführt ist!'; 
											   |ru = 'Взяли карту, которая уже выдана на другого клиента!'"), True);
						Return False;
					EndIf;
				EndIf;
				If vIDCardRef.IdentificationCardType <> pCardType Then
					ShowStatusMessage(NStr("en = 'You are processing card with wrong type!'; de = 'Sie halten die falsche Type von Karte!'; ru = 'Взяли карту не того типа!'"), True);
					Return False;
				EndIf;
				If Not ValueIsFilled(vFolio.ParentDoc) Then
					vFolioCards = cmGetClientIdentificationCardsByFolio(vFolio);
					For Each vFolioCardsRow In vFolioCards Do
						If vFolioCardsRow.Ref <> vIDCardRef Then
							ShowStatusMessage(NStr("en = 'Folio may have only one active identification card!'; 
												   |de = 'Zu dem Personenkonto kann es nur eine gültige Karte geben!'; 
												   |ru = 'По лицевому счету может быть только одна действующая карта!'"), True);
							Return False;
						EndIf;
					EndDo;
				EndIf;
			Else
				ShowStatusMessage(NStr("en = 'Card is not known! Ask your system administrator'; 
									   |de = 'Karte ist nicht bekannt! Fragen Sie Ihren Systemadministrator!'; 
									   |ru = 'Карта не введена в базу данных! Обратитесь к системному администратору'"), True);
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
			ShowStatusMessage(NStr("en = 'Failed to register client identification card!'; 
								   |de = 'Die Kundenidentifikationskarte konnte nicht registriert werden!'; 
								   |ru = 'Не удалось зарегистрировать карту идентификации клиента!'"), True);
			Return False;
		ElsIf Not vUseDeleted And TrimAll(vIDCardRef.Identifier) <> vCardID Then
			ShowStatusMessage(NStr("en = 'Folio may have only one active identification card!'; 
								   |de = 'Zu dem Personenkonto kann es nur eine gültige Karte geben!'; 
								   |ru = 'По лицевому счету может быть только одна действующая карта!'"), True);
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
		ShowStatusMessage(NStr("en = 'Folio is not specified!'; 
							   |de = 'Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'; 
							   |ru = 'Не указан лицевой счет, на который регистрировать карту идентификации клиента!'"), True);
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
		DeleteFolioCards();
	EndIf;
EndProcedure // AfterDeleteCardsConfirmation

// -----------------------------------------------------------------------------
Procedure ShowStatusMessage(pMsg = "", pAttention = False)
	HelpMessage = pMsg;
	If pAttention Then
		Items.HelpMessage.BackColor = StyleColors.FieldSelectionBackColor;
		Items.HelpMessage.TextColor = StyleColors.FieldSelectedTextColor;
	Else
		Items.HelpMessage.BackColor = StyleColors.FormBackColor;
		Items.HelpMessage.TextColor = StyleColors.FieldSelectionBackColor;
	EndIf;
EndProcedure // ShowStatusMessage

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfThereAreCardsToIssueAtServer()
	vDoRegister = True;
	If ValueIsFilled(Room) Then
		vIssuedCards = cmGetClientIdentificationCardsByRoom(Room, False, ?(ValueIsFilled(Folio), Folio.GuestGroup, Undefined), True);
		// Count maximum number of cards to be issued
		vGuests = cmGetOneRoomAccommodations(Room, ?(ValueIsFilled(Folio), Folio.GuestGroup, Catalogs.GuestGroups.EmptyRef()), CheckInDate, CheckOutDate);
		If vGuests.Count() = 0 And ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
			vGuests = cmGetOneRoomReservations(TrimAll(ParentDoc.Number), ?(ValueIsFilled(Folio), Folio.GuestGroup, Catalogs.GuestGroups.EmptyRef()), CheckInDate, CheckOutDate);
		EndIf;			
		i = 0;
		While i < vGuests.Count() Do
			vGuestsRow = vGuests.Get(i);
			vDocRef = vGuestsRow.Ref;
			If TypeOf(vDocRef) = Type("DocumentRef.Accommodation") Or TypeOf(vDocRef) = Type("DocumentRef.Reservation") Then
				If ValueIsFilled(vDocRef.AccommodationType) And vDocRef.AccommodationType.DoNotIssueKeyCards Then
					vGuests.Delete(i);
					Continue;
				EndIf;
			EndIf;
			i = i + 1;
		EndDo;
		If vGuests.Count() > 0 And vGuests.Count() <= vIssuedCards.Count() Then
			vDoRegister = False;
			vErrorDescription = NStr("en='All cards were issued already!'; ru='Все карты уже выданы!'; de='Alle Karten wurden bereits ausgegebenen!'");
			ShowStatusMessage(vErrorDescription, True);
		EndIf;
	EndIf;
	Return vDoRegister;
EndFunction // CheckIfThereAreCardsToIssueAtServer

// -----------------------------------------------------------------------------
&AtServer
Function CheckIfThereAreSpecialCardsToIssueAtServer()
	vDoRegister = True;
	If ValueIsFilled(Folio) Then
		vIssuedCards = cmGetClientIdentificationCardsByFolio(Folio);
		// Count number of cards being already issued
		If vIssuedCards.Count() > 0 Then
			vDoRegister = False;
			vErrorDescription = NStr("en='Only one card could be issued for this folio!'; ru='По лицевому счету может быть выдана только одна карта!'; de='Alle Karten wurden bereits ausgegebenen!'");
			ShowStatusMessage(vErrorDescription, True);
		EndIf;
	EndIf;
	Return vDoRegister;
EndFunction // CheckIfThereAreSpecialCardsToIssueAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckNewCardWasRead()
	If IsBlankString(CardData) Then
		AttachIdleHandler("CheckNewCardWasRead", 0.1, True);
		Return;
	EndIf;
	// Check card folio
	If ValueIsFilled(Folio) And tcOnServer.cmGetAttributeByRef(Folio, "IsClosed") Then
		// Clear card data
		CardData = "";
		// Block card data input
		Items.CardData.ReadOnly = True;
		// Hide card data
		Items.CardData.Visible = False;
		// Clear cards are blocked
		CardsAreBlocked = False;
		// Show error 
		vErrorDescription = NStr("en='Folio is closed! Operation is cancelled.'; ru='Лицевой счет закрыт! Операция отменена.'; de='Folio ist geschlossen! Vorgang wird abgebrochen.'");
		ShowStatusMessage(vErrorDescription, True);
		Return;
	EndIf;
	// Delete previous client or folio cards if necessary
	If ValueIsFilled(IdentityCardSystemParameters) And tcOnServer.cmGetAttributeByRef(IdentityCardSystemParameters, "DeletePreviousClientCardsBeforeIssuingNew") Then
		DeleteFolioCards();
	EndIf;
	// Register new card
	If Not ValueIsFilled(CardType) Or ValueIsFilled(CardType) And 
	  (Not tcOnServer.cmGetAttributeByRef(CardType, "DoNotUseChargingRules") Or tcOnServer.cmGetAttributeByRef(CardType, "DoNotUseChargingRules") And IsBlankString(tcOnServer.cmGetAttributeByRef(CardType, "AdditionalServicesFolioCondition"))) Then
		// Check number of already issued cards
		vDoRegister = CheckIfThereAreCardsToIssueAtServer();
		// Issue card
		If vDoRegister Then
			If RegisterNewCard(CardData, tcOnServer.cmGetAttributeByRef(Folio, "IsMaster"), CardType) Then
				ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
				AttachIdleHandler("CloseForm", 1, True);
				// Fill issued cards list
				FillIssuedCards();
			EndIf;
		Else
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
	ElsIf ValueIsFilled(CardType) And tcOnServer.cmGetAttributeByRef(CardType, "DoNotUseChargingRules") And Not IsBlankString(tcOnServer.cmGetAttributeByRef(CardType, "AdditionalServicesFolioCondition")) Then
		// Maximum 1 card is allowed for the folio
		vDoRegister = CheckIfThereAreSpecialCardsToIssueAtServer();
		// Issue card
		If vDoRegister Then
			vIDCardRef = GetClientIdentificationCardById(GetCardIdentifier(CardData), True);
			If RegisterNewSpecialCard(vIDCardRef, CardType, True) Then
				ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
				AttachIdleHandler("CloseForm", 1, True);
				// Fill issued cards list
				FillIssuedCards();
			EndIf;
		Else
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
		vIDCardRef = GetClientIdentificationCardById(GetCardIdentifier(CardData), True);
		If RegisterNewSpecialCard(vIDCardRef, CardType, True) Then
			ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
			AttachIdleHandler("CloseForm", 1, True);
			// Fill issued cards list
			FillIssuedCards();
		EndIf;
	EndIf;
	// Clear card data
	CardData = "";
	// Block card data input
	Items.CardData.ReadOnly = True;
	// Hide card data
	Items.CardData.Visible = False;
	// Clear cards are blocked
	CardsAreBlocked = False;
EndProcedure // CheckNewCardWasRead

// -----------------------------------------------------------------------------
&AtServer
Procedure FillIssuedCards()
	IssuedCards.Clear();
	CardsAreBlocked = False;
	vBlockReason = "";
	If ValueIsFilled(Folio) Then
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
		ShowInputString(New NotifyDescription("AfterBlockReasonInput", ThisObject, pExtraParams), vBlockReason, NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"), 100, False);
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
	// Refresh list of cards
	FillIssuedCards();
EndProcedure // BlockCardAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CloseForm()
	Close();
EndProcedure // CloseForm

#EndRegion    
