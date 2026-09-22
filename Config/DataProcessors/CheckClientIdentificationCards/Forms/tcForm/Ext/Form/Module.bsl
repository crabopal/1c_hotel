
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Parameters
	IdentityCardSystemParameters = Undefined;
	If Parameters.Property("IdentityCardSystemParameters") Then
		IdentityCardSystemParameters = Parameters.IdentityCardSystemParameters;
	EndIf;
	// Clear attributes
	Card = Undefined;
	Folio = Undefined;
	Client = Undefined;
	Room = Undefined;
	AccommodationType = Undefined;
	ParentDoc = Undefined;
	CheckInDate = '00010101';
	CheckOutDate = '00010101';
	CardType = Undefined;
	// Clear card is blocked
	CardIsBlocked = False;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Wait for new card to be read
	ShowStatusMessage(NStr("en='Slip card to read it!';ru='Прокатайте карту!';de='Ziehen Sie eine Karte durch!'"));
	AttachIdleHandler("CheckNewCardWasRead", 1, False);
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
		CardData = vEventData.DeviceData;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure BlockCardAtClient(pCommand)
	If ValueIsFilled(Card) Then
		If tcOnServer.cmGetAttributeByRef(Card, "IsBlocked") Then
			// Ask user if he really wants to delete cards
			ShowQueryBox(New NotifyDescription("AfterUnblockCardConfirmation", ThisForm), NStr("en='Do you want to unblock card?'; ru='Хотите отменить блокировку карты?'; de='Möchten Sie die Kartensperre abbrechen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Else
			// Show what user have to do
			ShowStatusMessage(NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"));
			vBlockReason = "";
			ShowInputString(New NotifyDescription("AfterBlockReasonInputForCard", ThisForm), vBlockReason, NStr("en='Enter block reason, please!';ru='Укажите причину блокировки!';de='Geben Sie den Grund für die Reservierung an!'"), 100, False);
		EndIf;
	Else
		ShowStatusMessage(NStr("en = 'Read card first!'; ru = 'Сначала прочитайте карту!'; de = 'Zuerst lesen Sie die Karte!'"), True);
	EndIf;
EndProcedure // BlockCardAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure DeleteCardAtClient(pCommand)
	If ValueIsFilled(Card) Then
		// Ask user if he really wants to delete cards
		ShowQueryBox(New NotifyDescription("AfterDeleteCardConfirmation", ThisForm), NStr("en='Do you want to delete card?'; ru='Хотите удалить карту?'; de='Wollen Sie Karte zu löschen?'"), QuestionDialogMode.YesNo, , DialogReturnCode.No);
	Else
		ShowMessageBox(NStr("en='Read card first!'; de='Zuerst lesen Sie die Karte!'; ru='Сначала прочитайте карту!'"), True);
	EndIf;
EndProcedure // DeleteCardAtClient

// -----------------------------------------------------------------------------
&AtClient
Procedure ClearCard(pCommand)
	// Clear attributes
	Card = Undefined;
	Folio = Undefined;
	Client = Undefined;
	Room = Undefined;
	AccommodationType = Undefined;
	ParentDoc = Undefined;
	CheckInDate = '00010101';
	CheckOutDate = '00010101';
	CardType = Undefined;
	// Clear card is blocked
	CardIsBlocked = False;
	// Show status
	ShowStatusMessage(NStr("en='Slip card to read it!';ru='Прокатайте карту!';de='Ziehen Sie eine Karte durch!'"));
EndProcedure

#EndRegion

#Region Private

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
Procedure FillCardDataAtServer(pIDCardRef)
	If ValueIsFilled(pIDCardRef) Then
		Card = pIDCardRef;
		// Fill attributes
		Folio = pIDCardRef.Folio;
		Client = pIDCardRef.Client;
		Room = pIDCardRef.Room;
		CheckInDate = pIDCardRef.DateTimeFrom;
		CheckOutDate = pIDCardRef.DateTimeTo;
		CardType = pIDCardRef.IdentificationCardType;
		ParentDoc = pIDCardRef.ParentDoc;
		If ValueIsFilled(ParentDoc) And (TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(ParentDoc) = Type("DocumentRef.Accommodation")) Then
			AccommodationType = ParentDoc.AccommodationType;
		Else
			AccommodationType = Undefined;
		EndIf;
		// Show status
		If pIDCardRef.IsBlocked Then
			ShowStatusMessage(NStr("en='Card is blocked!';ru='Карта заблокирована!';de='Karte ist gesperrt!'") + Chars.LF + TrimAll(pIDCardRef.BlockReason), True);
			// Set card is blocked
			CardIsBlocked = True;
		Else	
			ShowStatusMessage(NStr("en='Card is found';ru='Карта найдена';de='Karte gefunden'"));
			// Clear card is blocked
			CardIsBlocked = False;
		EndIf;
	Else
		// Clear attributes
		Card = Undefined;
		Folio = Undefined;
		Client = Undefined;
		Room = Undefined;
		AccommodationType = Undefined;
		ParentDoc = Undefined;
		CheckInDate = '00010101';
		CheckOutDate = '00010101';
		CardType = Undefined;
		// Clear card is blocked
		CardIsBlocked = False;
		// Show status
		ShowStatusMessage(NStr("en='Card is not found!';ru='Карта не найдена!';de='Karte nicht gefunden!'"), True);
	EndIf;
EndProcedure // FillCardDataAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CheckNewCardWasRead()
	If IsBlankString(CardData) Then
		Return;
	EndIf;
	FillCardDataAtServer(GetClientIdentificationCardById(GetCardIdentifier(CardData), False));
	// Clear card data
	CardData = "";
EndProcedure // CheckNewCardWasRead

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
Procedure AfterUnblockCardConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		AfterBlockReasonInputForCard("", Undefined);
	EndIf;
EndProcedure // AfterDeleteCardConfirmation

// -----------------------------------------------------------------------------
&AtServer
Procedure BlockCard(pBlockReason)
	Try
		vCardRef = Card;
		If vCardRef.IsBlocked Then
			// Unblock card
			vCardObj = vCardRef.GetObject();
			vCardObj.IsBlocked = False;
			vCardObj.BlockReason = "";
			vCardObj.Write();
			// Clear card is blocked
			CardIsBlocked = False;
			// Success
			ShowStatusMessage(NStr("en='Success!';ru='Успешно!';de='Erfolgreich!'"), False);
		Else
			// Block card
			vCardObj = vCardRef.GetObject();
			vCardObj.IsBlocked = True;
			vCardObj.BlockReason = pBlockReason;
			vCardObj.Write();
			// Clear card is blocked
			CardIsBlocked = True;
			// Success
			ShowStatusMessage(NStr("en='Card is blocked!';ru='Карта заблокирована!';de='Karte ist gesperrt!'") + Chars.LF + TrimAll(pBlockReason), True);
		EndIf;
	Except
		ShowStatusMessage(NStr("en='Client identification card block error: ';ru='Ошибка блокировки карты идентификации клиента: ';de='Fehler in der Karteblockierung: '") + ErrorDescription(), True);
	EndTry;
EndProcedure // BlockCard

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterBlockReasonInputForCard(pBlockReason, pExtraParams) Export
	If pBlockReason <> Undefined Then
		BlockCard(pBlockReason);
	Else
		ShowStatusMessage(NStr("en='Card is found';ru='Карта найдена';de='Karte gefunden'"));
	EndIf;
EndProcedure // AfterBlockReasonInputForCard

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterDeleteCardConfirmation(pUserAnswer, pExtraParams) Export
	If pUserAnswer = DialogReturnCode.Yes Then
		// Clear card data
		CardData = "";
		// Show what user have to do
		ShowStatusMessage(NStr("en='Processing...';ru='Обработка...';de='Bearbeitung…'"));
		// Delete card
		DeleteCard();
	EndIf;
EndProcedure // AfterDeleteCardConfirmation

// -----------------------------------------------------------------------------
&AtServer
Procedure DeleteCard()
	Try
		vCardRef = Card;
		// Check should we reuse deleted cards
		vUseDeleted = IdentityCardSystemParameters.UseDeleted;
		// Get card object
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
		// Success
		ShowStatusMessage(NStr("en='Success';ru='Успешно';de='Erfolgreich'"));
		// Clear card data
		Card = Undefined;
		Folio = Undefined;
		Client = Undefined;
		Room = Undefined;
		AccommodationType = Undefined;
		ParentDoc = Undefined;
		CheckInDate = '00010101';
		CheckOutDate = '00010101';
		CardType = Undefined;
		// Clear card is blocked
		CardIsBlocked = False;
	Except
		ShowStatusMessage(NStr("en='Client identification card deletion error: ';ru='Ошибка удаления карты идентификации клиента: ';de='Fehler beim Löschen der Kundenidentifikationskarte: '") + ErrorDescription(), True);
	EndTry;
EndProcedure // DeleteFolioCards

#EndRegion
