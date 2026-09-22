
#Region Variables

// -----------------------------------------------------------------------------
Var RC;
Var RC_CODE; // Last error code
Var RC_OK Export; // Ok result
Var RC_UNKNOWN;
Var RC_LOGICAL_DEVICE_NOT_FOUND;
Var RC_NO_ID_CARD;
Var RC_NO_FOLIO;
Var RC_NO_ROOM;
Var RC_CARD_ALREADY_EXISTS;
Var RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
Var RC_WRONG_CARD_TYPE;
Var RC_CARD_NOT_REGISTERED;
Var RC_CARD_IS_IN_USE;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  rErrorDescription	 - String - Error description
// 
// Returns:
//  String - Error code
//
Function pmGetLastError(rErrorDescription = "") Export
	vErrorDescription = RC.Get(RC_CODE);
	If vErrorDescription = Undefined Then
		rErrorDescription = "";
	Else
		rErrorDescription = vErrorDescription;
	EndIf;
	Return RC_CODE;
EndFunction //  pmGetLastError

// -----------------------------------------------------------------------------
// 
// Returns:
//  ComObject - Device driver
//
Function pmConnect() Export
	Try
		If Not ValueIsFilled(IdentityCardSystemParameters) Then
			Raise NStr("en='Identity cards system parameters are not set!';ru='Не установлены параметры системы подключения карт идентификации клиентов!';de='Parameter des Anschlusssystems der Kundenidentifikationskarten sind nicht festgelegt!'");
		EndIf;
		
		// Create reader object
		If IdentityCardSystemParameters.CardReaderType = Enums.CardReaderTypes.RS232_1C Then
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.Scanner");
					vReaderMC = New("AddIn.Scanner");
				Except
					LoadAddIn("ScanOPOS.dll");
					vReaderMC = New("AddIn.Scanner");
				EndTry;
			#ELSE
				vReaderMC = New("AddIn.Scanner");
			#ENDIF
		Else
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.Scaner45");
					vReaderMC = New("AddIn.Scaner45");
				Except
					LoadAddIn("Scaner1C.dll");
					vReaderMC = New("AddIn.Scaner45");
				EndTry;
			#ELSE
				vReaderMC = New("AddIn.Scaner45");
			#ENDIF
		EndIf;
		
		// Set current logical device number
		vReaderMC.CurrentDeviceNumber = ?(IdentityCardSystemParameters.LogicalDeviceNumber = 0, 1, IdentityCardSystemParameters.LogicalDeviceNumber);
		If vReaderMC.ResultCode = RC_LOGICAL_DEVICE_NOT_FOUND Then
			vReaderMC.AddDevice();
			If CheckResult(vReaderMC) <> 0 Then
				Return Undefined;
			EndIf;  
			// Save logical device number
			vPrmObj = IdentityCardSystemParameters.GetObject();
			vPrmObj.LogicalDeviceNumber = vReaderMC.CurrentDeviceNumber;
			vPrmObj.Write();
		ElsIf CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Do not lock logical devices
		vReaderMC.LockDevices = 0;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;  
		
		// Set reader connection parameters
		If IdentityCardSystemParameters.CardReaderType = Enums.CardReaderTypes.IronLogicZ2 Then
			vReaderMC.Model = 13;
			Try
				vReaderMC.DataFormat = 3;
			Except
				vReaderMC.Model = 1;
			EndTry;
		Else	
			vReaderMC.Model = 1;
		EndIf;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		// Port
		vPortNumber = 1;
		If Not IsBlankString(IdentityCardSystemParameters.Port) Then
			vPortNumber = Number(Mid(TrimAll(IdentityCardSystemParameters.Port), 4));
		EndIf;
		vReaderMC.PortNumber = vPortNumber;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		// Baud rate
		vBaudRate = 7;
		If IdentityCardSystemParameters.BaudRate > 0 Then
			If IdentityCardSystemParameters.BaudRate = 1200 Then
				vBaudRate = 3;
			ElsIf IdentityCardSystemParameters.BaudRate = 2400 Then
				vBaudRate = 4;
			ElsIf IdentityCardSystemParameters.BaudRate = 4800 Then
				vBaudRate = 5;
			ElsIf IdentityCardSystemParameters.BaudRate = 9600 Then
				vBaudRate = 7;
			EndIf;
		EndIf;
		vReaderMC.BaudRate = vBaudRate;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		// Data bits
		vDataBits = 4;
		If ValueIsFilled(IdentityCardSystemParameters.DataBits) Then
			If IdentityCardSystemParameters.DataBits = Enums.DataBits.Bits7 Then
				vDataBits = 3;
			ElsIf IdentityCardSystemParameters.DataBits = Enums.DataBits.Bits8 Then
				vDataBits = 4;
			EndIf;
		EndIf;
		vReaderMC.DataBits = vDataBits;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		// Parity
		vParity = 0;
		If ValueIsFilled(IdentityCardSystemParameters.Parity) Then
			If IdentityCardSystemParameters.Parity = Enums.ParityTypes.Even Then
				vParity = 2;
			ElsIf IdentityCardSystemParameters.Parity = Enums.ParityTypes.Odd Then
				vParity = 1;
			ElsIf IdentityCardSystemParameters.Parity = Enums.ParityTypes.None Then
				vParity = 0;
			ElsIf IdentityCardSystemParameters.Parity = Enums.ParityTypes.Mark Then
				vParity = 3;
			ElsIf IdentityCardSystemParameters.Parity = Enums.ParityTypes.Space Then
				vParity = 4;
			EndIf;
		EndIf;
		vReaderMC.Parity = vParity;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop bits
		vStopBits = 0;
		If ValueIsFilled(IdentityCardSystemParameters.StopBits) Then
			If IdentityCardSystemParameters.StopBits = Enums.StopBits.Bits1 Then
				vStopBits = 0;
			ElsIf IdentityCardSystemParameters.StopBits = Enums.StopBits.Bits2 Then
				vStopBits = 2;
			EndIf;
		EndIf;
		vReaderMC.StopBits = vStopBits;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Prefix and suffix
		If IdentityCardSystemParameters.CardReaderType <> Enums.CardReaderTypes.IronLogicZ2 Then
			vReaderMC.Prefix = GetCharsFromCodes(IdentityCardSystemParameters.Prefix);
			vReaderMC.Suffix = GetCharsFromCodes(IdentityCardSystemParameters.Suffix);
		EndIf;
		
		// Set reader object properties
		vReaderMC.DataEventEnabled = 1;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;  
		vReaderMC.OldVersion = 0;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;  
		vReaderMC.AutoDisable = 1;
		If CheckResult(vReaderMC) <> 0 Then
			Return Undefined;
		EndIf;  
		// Switch reader on
		If vReaderMC.DeviceEnabled = 0 Then
			vReaderMC.DeviceEnabled = 1;
			If CheckResult(vReaderMC) <> 0 Then
				Return Undefined;
			EndIf;  
		EndIf;
		// Clear events
		If vReaderMC.DataCount > 0 Then
			vReaderMC.DeleteEvent();
			vReaderMC.DataEventEnabled = 1;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Magnetic cards reader connection error: ';ru='Ошибка подключения ридера магнитных карт: ';de='Fehler beim Anschluss des Magnetkartenlesers: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vReaderMC;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReaderMC	 - ComObject	 - Device driver
//
Procedure pmDisconnect(pReaderMC) Export
	Try
		If pReaderMC <> Undefined Then
			pReaderMC.CurrentDeviceNumber = ?(IdentityCardSystemParameters.LogicalDeviceNumber = 0, 1, IdentityCardSystemParameters.LogicalDeviceNumber);
			pReaderMC.DeviceEnabled = 0;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Magnetic cards reader disconnect error: ';ru='Ошибка отключения ридера магнитных карт: ';de='Fehler bei Abschalten des Magnetkartenlesers: '") + ErrorDescription());
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure			 - 
//  pIsMaster	 - Boolean				 - 
//  pCardType	 - String				 - 
//  pFolio		 - DocumentRef.Folio	 - 
//  pParentDoc	 - DocumentRef.Reservation	 - 
//  pClient		 - CatalogRef.Client		 - 
// 
// Returns:
//  String - Error code or success
//
Function pmRegisterNewCard(pCardData, pIsMaster = False, pCardType = Undefined, pFolio = Undefined, pParentDoc = Undefined, pClient = Undefined) Export
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
						AddError(RC_CARD_IS_IN_USE, NStr("en='You are processing card that is already in use!';ru='Взяли карту, которая уже выдана на другого клиента!';de='Verwenden Sie die Karte, die bereits auf einem anderen Client aufgeführt ist!'"));
						Return RC_CARD_IS_IN_USE;
					EndIf;
				EndIf;
				If vIDCardRef.IdentificationCardType <> pCardType Then
					AddError(RC_WRONG_CARD_TYPE, NStr("en='You are processing card with wrong type!';ru='Взяли карту не того типа!';de='Sie halten die falsche Type von Karte!'"));
					Return RC_WRONG_CARD_TYPE;
				EndIf;
				If Not ValueIsFilled(vFolio.ParentDoc) Then
					vFolioCards = cmGetClientIdentificationCardsByFolio(vFolio);
					For Each vFolioCardsRow In vFolioCards Do
						If vFolioCardsRow.Ref <> vIDCardRef Then
							AddError(RC_ONLY_ONE_ACTIVE_CARD_ALLOWED, NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
							Return RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
						EndIf;
					EndDo;
				EndIf;
			Else
				AddError(RC_CARD_NOT_REGISTERED, NStr("en='Card is not known! Ask your system administrator';ru='Карта не введена в базу данных! Обратитесь к системному администратору';de='Karte ist nicht bekannt! Fragen Sie Ihren Systemadministrator!'"));
				Return RC_CARD_NOT_REGISTERED;
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
			AddError(RC_NO_ID_CARD, NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"));
			Return RC_NO_ID_CARD;
		ElsIf Not vUseDeleted And TrimAll(vIDCardRef.Identifier) <> vCardID Then
			AddError(RC_ONLY_ONE_ACTIVE_CARD_ALLOWED, NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
			Return RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
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
		AddError(RC_NO_FOLIO, NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return RC_NO_FOLIO;
	EndIf;
	Return RC_OK;
EndFunction // pmRegisterNewCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIDCardRef			 - CatalogRef.IdentificationCards	 - 
//  pCardType			 - Enum.IdentificationCardType	 - 
//  pDoNotSearchFolio	 - Boolean	 - 
// 
// Returns:
//  String - Error code or success 
//
Function pmRegisterNewSpecialCard(pIDCardRef, pCardType = Undefined, pDoNotSearchFolio = False) Export
	// Add/get client identification card
	If ValueIsFilled(Folio) Then
		If Not ValueIsFilled(pIDCardRef) Then
			AddError(RC_NO_ID_CARD, NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"));
			Return RC_NO_ID_CARD;
		EndIf;
		// Get main room folio
		vFolio = Folio;
		If Not pDoNotSearchFolio Then
			If ValueIsFilled(pIDCardRef.IdentificationCardType) And ValueIsFilled(Folio.GuestGroup) And ValueIsFilled(Folio.Room) Then
				vFolioDescription = TrimAll(pIDCardRef.IdentificationCardType.AdditionalServicesFolioCondition);
				If Not IsBlankString(vFolioDescription) Then
					vFolio = GetRoomExtraServicesFolioByDescription(vFolioDescription);
					If Not ValueIsFilled(vFolio) Then
						AddError(RC_NO_FOLIO, NStr("en='Folio is not found for type ';ru='Не найден лицевой счет с описанием ';de='Das Personenkonto ist nicht gefunden! Personenkonto Beschreibung ist '") + vFolioDescription + "!");
						Return RC_NO_FOLIO;
					EndIf;
				EndIf;
			EndIf;
		Else
			If pCardType <> Undefined Then
				If pIDCardRef.IdentificationCardType <> pCardType Then
					AddError(RC_WRONG_CARD_TYPE, NStr("en='You are processing card with wrong type!';ru='Взяли карту не того типа!';de='Sie halten die falsche Type von Karte!'"));
					Return RC_WRONG_CARD_TYPE;
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
		AddError(RC_NO_FOLIO, NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return RC_NO_FOLIO;
	EndIf;
	Return RC_OK;
EndFunction //  pmRegisterNewSpecialCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBlockReason - Boolean - Block reason 
// 
// Returns:
//  String - Error code or success 
//
Function pmBlockFolioCards(pBlockReason) Export
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
		Else
			AddError(RC_NO_FOLIO, NStr("en='Neither parent document nor folio is specified!';ru='Не указан ни документ основание ни лицевой счет, по которому блокировать карты идентификации клиента!';de='Weder das Dokument, noch die Begründung, noch das Personenkonto sind angegeben, über die die Identifikationskarten des Kunden blockiert werden sollen!'"));
			Return RC_NO_FOLIO;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Client identification cards block error: ';ru='Ошибка блокировки карт идентификации клиентов: ';de='Fehler in der Kartenblockierung und Kundenidentifizierung: '") + ErrorDescription());
		Return RC_UNKNOWN;
	EndTry;
	Return RC_OK;
EndFunction //  pmBlockFolioCards

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBlockReason - Boolean - BlockReason
// 
// Returns:
//  String - Error code or success 
//
Function pmBlockRoomCards(pBlockReason) Export
	Try
		If ValueIsFilled(Room) Then
			// Get all cards for the current parent document
			vCards = cmGetClientIdentificationCardsByRoom(Room, False, ?(ValueIsFilled(Folio), Folio.GuestGroup, Undefined));
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
		Else
			AddError(RC_NO_ROOM, NStr("en='Room is not specified!';ru='Не указан номер комнаты, по которой блокировать карты идентификации клиента!';de='Zimmer nicht angegeben, über die die Identifikationskarten des Kunden blockiert werden sollen!'"));
			Return RC_NO_ROOM;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Client identification cards block error: ';ru='Ошибка блокировки карт идентификации клиентов: ';de='Fehler in der Kartenblockierung und Kundenidentifizierung: '") + ErrorDescription());
		Return RC_UNKNOWN;
	EndTry;
	Return RC_OK;
EndFunction //  pmBlockFolioCards

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code or success 
//
Function pmDeleteFolioCards() Export
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
		Else
			AddError(RC_NO_FOLIO, NStr("en='Neither parent document nor folio is specified!';ru='Не указан ни документ основание ни лицевой счет, по которому удалять карты идентификации клиента!';de='Weder das Dokument, noch die Begründung, noch das Personenkonto sind angegeben, über die die Identifikationskarten des Kunden gelöscht werden sollen!'"));
			Return RC_NO_FOLIO;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Client identification cards deletion error: ';ru='Ошибка удаления карт идентификации клиентов: ';de='Fehler beim Löschen der Kundenidentifikationskarten: '") + ErrorDescription());
		Return RC_UNKNOWN;
	EndTry;
	Return RC_OK;
EndFunction //  pmDeleteFolioCards

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code or success 
//
Function pmDeleteRoomCards() Export
	Try
		If ValueIsFilled(Room) Then
			// Check should we reuse deleted cards
			vUseDeleted = IdentityCardSystemParameters.UseDeleted;
			// Get all cards for the current folio
			vCards = cmGetClientIdentificationCardsByRoom(Room, False, ?(ValueIsFilled(Folio), Folio.GuestGroup, Undefined));
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
		Else
			AddError(RC_NO_ROOM, NStr("en='Room is not specified!';ru='Не указан номер комнаты, по которой удалять карты идентификации клиента!';de='Zimmer nicht angegeben, über die die Identifikationskarten des Kunden entfernen werden sollen!'"));
			Return RC_NO_ROOM;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Client identification cards deletion error: ';ru='Ошибка удаления карт идентификации клиентов: ';de='Fehler beim Löschen der Kundenidentifikationskarten: '") + ErrorDescription());
		Return RC_UNKNOWN;
	EndTry;
	Return RC_OK;
EndFunction //  pmDeleteFolioCards

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure			 - Params
//  rCardRef	 - CatalogRef.IdentityCards	 - Ref 
// 
// Returns:
//  String - Error code or success
//
Function pmVerify(pCardData, rCardRef) Export
	rCardRef = Undefined;
	Try
		// Get card identifier
		vCardID = cmGetCardIdentifier(pCardData);
		// Get card by identifier
		rCardRef = cmGetClientIdentificationCardById(vCardID);
	Except
		AddError(RC_UNKNOWN, NStr("en='Client identification card verification error: ';ru='Ошибка проверки карты идентификации клиента: ';de='Fehler bei der Prüfung der Kundenidentifikationskarte: '") + ErrorDescription());
		Return RC_UNKNOWN;
	EndTry;
	Return RC_OK;
EndFunction //  pmVerify

// -----------------------------------------------------------------------------
//
// Parameters:
//  pReaderMC	 - ComObject - Device driver 
// 
// Returns:
//  String - Track2
//
Function pmGetTrack2(pReaderMC) Export
	pReaderMC.CurrentDeviceNumber = ?(IdentityCardSystemParameters.LogicalDeviceNumber = 0, 1, IdentityCardSystemParameters.LogicalDeviceNumber);
	vTrack2 = TrimAll(pReaderMC.Track2);
	If IsBlankString(vTrack2) Then
		vTrack2 = TrimAll(pReaderMC.ScanData);
	EndIf;
	vTrack2 = cmGetCardIdentifier(vTrack2);
	Return vTrack2;
EndFunction //  pmGetTrack2

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorCode, pErrorText)
	RC_CODE = pErrorCode;
	RC.Insert(pErrorCode, pErrorText);
	WriteLogEvent(NStr("en='IdentityCardsDriver.Error';ru='ДрайверКартИдентификацииКлиентов.Ошибка';de='IdentityCardsDriver.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// ------------------------------------------------------------------------------
Function CheckResult(pReaderMC)
	RC_CODE = RC_OK;
	vResultCode = pReaderMC.ResultCode;
	vResultDescription = pReaderMC.ResultDescription;
	If vResultCode <> RC_OK Then
		AddError(vResultCode, NStr("en='Error using magnetic cards reader! Error code: ';ru='Ошибка работы с ридером магнитных карт! Код ошибки: ';de='Fehler bei der Arbeit mit dem Magnetkartenleser! Fehlercode: '") + TrimAll(vResultCode) + NStr("en=' Error description: ';ru=' Описание ошибки: ';de= ' Fehlerbeschreibung: '") + TrimAll(vResultDescription));
	EndIf;
	Return vResultCode;
EndFunction //  CheckResult

// ------------------------------------------------------------------------------
Function GetCharsFromCodes(pStr) 
	vStr = "";
	If IsBlankString(pStr) Then
		Return vStr;
	EndIf;
	vPos = Find(pStr, "#");
	If vPos > 0 Then
		vStrCodes = TrimAll(Mid(pStr, vPos + 1));
		While vPos > 0 Do
			vPos = Find(vStrCodes, "#");
			If vPos = 0 Then
				vStr = vStr + Char(Number(vStrCodes));
			Else
				vStr = vStr + Char(Number(Left(vStrCodes, vPos - 1)));
				vStrCodes = TrimAll(Mid(vStrCodes, vPos + 1));
			EndIf;
		EndDo;
	Else
		vStr = TrimR(pStr);
	EndIf;
	Return vStr;
EndFunction //  GetCharsFromCodes

// -----------------------------------------------------------------------------
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
EndFunction //  GetRoomExtraServicesFolioByDescription

#EndRegion 

#Region Initialize

// Initialize return codes map 
RC = New Map();
// Initialize return code constants
RC_OK = 0;
RC_CODE = RC_OK;
RC_UNKNOWN = 99;
RC_NO_ID_CARD = 98;
RC_NO_FOLIO = 97;
RC_NO_ROOM = 94;
RC_CARD_ALREADY_EXISTS = 96;
RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = 95;
RC_LOGICAL_DEVICE_NOT_FOUND = -9;
RC_WRONG_CARD_TYPE = 93;
RC_CARD_NOT_REGISTERED = 92;
RC_CARD_IS_IN_USE = 91;

#EndRegion
