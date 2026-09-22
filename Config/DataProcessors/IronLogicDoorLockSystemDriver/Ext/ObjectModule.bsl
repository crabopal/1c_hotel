
#Region Variables

Var SEP;
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

// -----------------------------------------------------------------------------
Var RC_SYNTAX_ERROR Export;  // Syntax error
Var RC_NO_COMMUNICATION Export; // Error
Var RC_CARD_FORMAT_ERROR Export; // Error
Var RC_GENERAL_READ_ERROR Export; // Error
Var RC_GENERAL_ENCODING_ERROR Export; // Error
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknouwn
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Export; // No guest previosly checked in
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_COMMAND_NOT_APPLICABLE Export; // Command not applicable
Var RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Export; // Only one active card alloved

// -----------------------------------------------------------------------------
Var SystemName;

// -----------------------------------------------------------------------------
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey() Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = Left(TrimR(Room.LockCode), 18);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + vRoomCode;
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If BegOfDay(vCheckInDate) < BegOfDay(CurrentSessionDate()) Then
		vCheckInDate = BegOfDay(CurrentSessionDate()) + Hour(CurrentSessionDate()) * 3600;
	EndIf;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckInDate,"DF=dd/MM/yyyy");
	vDta = vDta + SEP + Format(vCheckInDate,"DF=HH:mm");
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=dd/MM/yyyy");
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HH:mm");
	// Authorizations
	vCommonDoorsBitMap = "";
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If vDoorLockSystemAuthorization.MergeWithDefault Then
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vCommonDoorsBitMap = TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	vDta = vDta + SEP;
	// Keypad PIN code is not supported
	vDta = vDta + SEP;
	// Card operation.
	vDta = vDta + SEP + "RP";
	// Leave operators name blank to use generic PMS operator
	vOperatorName = "";
	If ValueIsFilled(SessionParameters.CurrentUser) And 
	   ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
		vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 10);
	EndIf;
	vDta = vDta + SEP + vOperatorName;
	// encoder number
	vDta = vDta + SEP;
	// Track 1 data
	vDta = vDta + SEP;
	// Add tack 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, False, DoorLockSystemParameters.CardVersion, vCommonDoorsBitMap);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vSourceAddress = "";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		If DoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + SEP + SEP + SEP + SEP + SEP + "1";//Return ID Card
		EndIf;
		vReply = "";
		vErrorCode = MakeNewKey(vDLSys, vSourceAddress, vDta, vReply);
		
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If DoorLockSystemParameters.ReturnCardUID AND ValueIsFilled(Folio) Then
				vCardUID = GetCardUID(vReply);
				If Not IsBlankString(vCardUID) Then
					IdentificationCard = cmGetClientIdentificationCard(vCardUID, cmGetClientIdentificationCardById(vCardUID), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
				EndIf;
			EndIf;
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code
//
Function pmAddKey() Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + vRoomCode;
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If BegOfDay(vCheckInDate) < BegOfDay(CurrentSessionDate()) Then
		vCheckInDate = BegOfDay(CurrentSessionDate()) + Hour(CurrentSessionDate()) * 3600;
	EndIf;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckInDate,"DF=dd/MM/yyyy");
	vDta = vDta + SEP + Format(vCheckInDate,"DF=HH:mm");
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=dd/MM/yyyy");
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HH:mm");
	// Authorizations
	vCommonDoorsBitMap = "";
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If vDoorLockSystemAuthorization.MergeWithDefault Then
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vCommonDoorsBitMap = TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	vDta = vDta + SEP;
	// Keypad PIN code is not supported
	vDta = vDta + SEP;
	// Card operation. Indicates if, once the operation has ended, the card must be ejected
	vDta = vDta + SEP + "RP";
	// Leave operators name blank to use generic PMS operator
	vOperatorName = "";
	If ValueIsFilled(SessionParameters.CurrentUser) And 
	   ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
		vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 10);
	EndIf;
	vDta = vDta + SEP + vOperatorName;
	// encoder number
	vDta = vDta + SEP;
	// Track 1 data
	vDta = vDta + SEP;
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, False, DoorLockSystemParameters.CardVersion, vCommonDoorsBitMap);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vSourceAddress = "";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		If DoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + SEP + SEP + SEP + SEP + SEP + "1"; //Return ID Card
		EndIf;
		vReply = "";
		vErrorCode = AddKey(vDLSys, vSourceAddress, vDta, vReply);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If DoorLockSystemParameters.ReturnCardUID AND ValueIsFilled(Folio) Then
				vCardUID = GetCardUID(vReply);
				If Not IsBlankString(vCardUID) Then
					IdentificationCard = cmGetClientIdentificationCard(vCardUID, cmGetClientIdentificationCardById(vCardUID), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
				EndIf;
			EndIf;
			WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data
// 
// Returns:
//  String - Error code 
//
Function pmVerify(pCardData) Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	vSourceAddress = "";
	If Not IsBlankString(DoorLockSystemParameters.PCId) Then
		vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
	EndIf;
	
	// Build command data string
	vDta = "";
	// format
	vDta = vDta + SEP + "T";
	// Read track 3
	vDta = vDta + SEP + "3";
	// Card should be ejected
	vDta = vDta + SEP + "EF";
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vSourceAddress, vDta, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys);
	
	Return vErrorCode;
EndFunction //  pmVerify

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRC	 - String	 - Return code
// 
// Returns:
//  String - Error description
//
Function pmGetErrorDescription(pRC) Export
	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + SystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + SystemName + "!';
		            |en = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en='No checked in guests in the room! Make new key card instead.';ru='В номере нет размещенных гостей! Выдайте гостю новую карту.';de='In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |de = '" + SystemName + " system is not responding!'; 
		            |en = '" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + SystemName + " system replied with unknown format!'; 
		            |en = '" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		            |en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = RC_COMMAND_NOT_APPLICABLE Then
		Return(NStr("en='Not validated! The command cannot be accomplished because either the related room cannot be recognized, or the command is not applicable.';ru='Ошибка проверки команды! Возможно номер указан не верно или команда не применима в текущий момент.';de='Fehler bei der Prüfung des Befehls! Möglicherweise ist das Zimmer falsch angegeben oder der Befehl kann zu diesem Zeitpunkt nicht angewendet werden.'"));
	ElsIf pRC = RC_CARD_FORMAT_ERROR Then
		Return(NStr("en='Card inserted wrongly or without magnetic stripe!';ru='Не правильно вставлена карта или карта без магнитной полосы!';de='Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'"));
	ElsIf pRC = RC_GENERAL_READ_ERROR Then
		Return(NStr("en='General Reading error. The reading operation is not successful!';ru='Ошибка чтения карты. Прочитать данные с карты не удалось!';de='Fehler beim Lesen der Karte. Die Daten konnten nicht von der Karte gelesen werden!'"));
	ElsIf pRC = RC_GENERAL_ENCODING_ERROR Then
		Return(NStr("en='General Encoding error. The encoding operation is not successful!';ru='Ошибка кодирования карты. Не удалось записать данные на карту!';de='Fehler der Kartencodierung. Die Daten konnten nicht auf die Karte geschrieben werden!'"));
	ElsIf pRC = RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data
//  pIsMaster	 - Boolean	 - Is master key
// 
// Returns:
//  String - Error code
//
Function pmRegisterNewCard(pCardData, pIsMaster = False) Export
	// Add/get client identification card
	If ValueIsFilled(Folio) Then
		// Get card identifier
		vCardID = cmGetCardIdentifier(pCardData);
		// Register card
		IdentificationCard = cmGetClientIdentificationCard(vCardID, cmGetClientIdentificationCardById(vCardID), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True);
		If Not ValueIsFilled(IdentificationCard) Then
			AddError(NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"));
			Return RC_NO_ID_CARD;
		ElsIf TrimAll(IdentificationCard.Identifier) <> vCardID Then
			AddError(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
			Return RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
		EndIf;
		// Check should we update is master folio flag
		If ValueIsFilled(Folio) Then
			If Folio.IsMaster <> pIsMaster Then
				vFolioObj = Folio.GetObject();
				vFolioObj.IsMaster = pIsMaster;
				vFolioObj.Write(DocumentWriteMode.Write);
				// Try to set folio client default charging rules
				If ValueIsFilled(Folio.Client) And Not ValueIsFilled(Folio.Room) And Not ValueIsFilled(Folio.GuestGroup) Then
					vClientObj = Folio.Client.GetObject();
					If ValueIsFilled(Folio.Hotel) Then
						vClientObj.ChargingRules.Clear();
						vClientObj.pmCreateFolios(Folio.Hotel, CurrentSessionDate());
						If vClientObj.ChargingRules.Count() > 0 Then
							vCRRow = vClientObj.ChargingRules.Get(0);
							vOldFolio = vCRRow.ChargingFolio;
							vCRRow.ChargingFolio = Folio;
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
		AddError(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return RC_NO_FOLIO;
	EndIf;
	Return RC_OK;
EndFunction //  pmRegisterNewCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotels	 - Ref
//  pAssignedAuthorizations	 - CatalogRef.AssignedAuthorizations	 - Assigned authorizations
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Item ref 
//
Function pmFindAuthorizations(pHotel, pAssignedAuthorizations) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.AssignedAuthorizations = &qAssignedAuthorizations
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (NOT DoorLockSystemAuthorizations.DeletionMark)
	|	AND (NOT DoorLockSystemAuthorizations.IsFolder)
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAssignedAuthorizations", pAssignedAuthorizations);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vAuthRef = vQryRes.Get(0).Ref;
	EndIf;
	Return vAuthRef;
EndFunction //  pmFindAuthorizations

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If DoorLockSystemParameters.DoGuestNamesTransliteration Or pAlways Then
		vStr = StrReplace(vStr, "А", "A");
		vStr = StrReplace(vStr, "Б", "B");
		vStr = StrReplace(vStr, "В", "V");
		vStr = StrReplace(vStr, "Г", "G");
		vStr = StrReplace(vStr, "Д", "D");
		vStr = StrReplace(vStr, "Е", "E");
		vStr = StrReplace(vStr, "Ё", "E");
		vStr = StrReplace(vStr, "Ж", "GH");
		vStr = StrReplace(vStr, "З", "Z");
		vStr = StrReplace(vStr, "И", "I");
		vStr = StrReplace(vStr, "Й", "Y");
		vStr = StrReplace(vStr, "К", "K");
		vStr = StrReplace(vStr, "Л", "L");
		vStr = StrReplace(vStr, "М", "M");
		vStr = StrReplace(vStr, "Н", "N");
		vStr = StrReplace(vStr, "О", "O");
		vStr = StrReplace(vStr, "П", "P");
		vStr = StrReplace(vStr, "Р", "R");
		vStr = StrReplace(vStr, "С", "S");
		vStr = StrReplace(vStr, "Т", "T");
		vStr = StrReplace(vStr, "У", "U");
		vStr = StrReplace(vStr, "Ф", "F");
		vStr = StrReplace(vStr, "Х", "H");
		vStr = StrReplace(vStr, "Ц", "C");
		vStr = StrReplace(vStr, "Ч", "CH");
		vStr = StrReplace(vStr, "Ш", "SH");
		vStr = StrReplace(vStr, "Щ", "SCH");
		vStr = StrReplace(vStr, "Ь", "");
		vStr = StrReplace(vStr, "Ы", "YI");
		vStr = StrReplace(vStr, "Ъ", "");
		vStr = StrReplace(vStr, "Э", "E");
		vStr = StrReplace(vStr, "Ю", "YU");
		vStr = StrReplace(vStr, "Я", "YA");
	EndIf;
	Return vStr;
EndFunction //  Transliterate

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "9600,N,8,1,P" by default
	// Baudrate
	If DoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(DoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
	EndIf;
	// Parity
	If ValueIsFilled(DoorLockSystemParameters.Parity) Then
		If DoorLockSystemParameters.Parity = Enums.ParityTypes.Even Then
			vStr = vStr + ",E";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Odd Then
			vStr = vStr + ",O";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.None Then
			vStr = vStr + ",N";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Mark Then
			vStr = vStr + ",M";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Space Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",N";
	EndIf;
	// Data length
	If ValueIsFilled(DoorLockSystemParameters.DataBits) Then
		If DoorLockSystemParameters.DataBits = Enums.DataBits.Bits8 Then
			vStr = vStr + ",8";
		ElsIf DoorLockSystemParameters.DataBits = Enums.DataBits.Bits7 Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
	EndIf;
	// Stop bits
	If ValueIsFilled(DoorLockSystemParameters.StopBits) Then
		If DoorLockSystemParameters.StopBits = Enums.StopBits.Bits1 Then
			vStr = vStr + ",1";
		ElsIf DoorLockSystemParameters.StopBits = Enums.StopBits.Bits2 Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	// Hardware flow control always
	vStr = vStr + ",P";
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function RS232Acknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 3000;
		vReply = pDLSys.ReadStr();
		If vReply = ACK Then
			Return True;
		ElsIf vReply = NAK Then
			AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en='Wrong number of bytes sent on acknowledgement: ';ru='При подтверждении связи отправлено байт: ';de='Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction //  RS232Acknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Iron Logic";
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			vDLSys = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			vDLSys.InitString(GetCOMPortConnectionString());
			// Open COM port
			vIsOpen = vDLSys.Open(TrimAll(DoorLockSystemParameters.Port));
			If Not vIsOpen Then
				AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
				Return Undefined;
			EndIf;
			// Set block mode
			vDLSys.BlockMode = True;
			// Setup timeouts
			vDLSys.TimeoutReadInterval = 1000;
			vDLSys.TimeoutReadTotalConstant = 3000;
			vDLSys.TimeoutReadTotalMultiplier = 100;
			vDLSys.TimeoutWriteTotalConstant = 3000;
			vDLSys.TimeoutWriteTotalMultiplier = 100;
			// Send/receive acknowledgement
			If Not RS232Acknowledgement(vDLSys) Then
				AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + SystemName + "!'; en = 'Acknowledgement with system " + SystemName + " failed!'; de = 'Acknowledgement with system " + SystemName + " failed!'"));
				vDLSys.Close();
				Return Undefined;
			EndIf;
		Else
			Try
			    vDLSys = New COMObject("SocketTools.SocketWrench.10");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK10_LICENSE_KEY);
			Except
				vDLSys = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK6_LICENSE_KEY);
			EndTry;
			If vErrorCode <> 0 Then
				AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vDLSys.Blocking = True;
			vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), Number(TrimAll(DoorLockSystemParameters.Port)));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			pDLSys.Close();
		Else
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pAdd = False, pCardVersion=0, pCommonDoors="")
	vTrack2Data = "place::0";
	If DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				If DoorLockSystemParameters.WriteTrack2 Then
					If Not IsBlankString(vTrack2Data) Then
						vTrack2Data = vTrack2Data + ",";
					EndIf;
					vTrack2Data = "card_id::" + TrimAll(vIDCardRef.Identifier);
				EndIf;
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys);
			Return vErrorCode;
		EndIf;
	EndIf;
	If pCardVersion <> 0 Then
		If Not IsBlankString(vTrack2Data) Then
			vTrack2Data = vTrack2Data + ",";
		EndIf;
		vTrack2Data = vTrack2Data + "guest_card_version::" + Format(pCardVersion, "ND=3; NFD=; NZ=; NG=");
	EndIf;
	If pCommonDoors <> "" Then
		If Not IsBlankString(vTrack2Data) Then
			vTrack2Data = vTrack2Data + ",";
		EndIf;
		vTrack2Data = vTrack2Data + "common_doors::" + Format(cmBin2Dec(pCommonDoors), "NFD=; NZ=; NG=");
	EndIf;
	pDta = pDta + SEP + vTrack2Data;
	Return RC_OK;
EndFunction //  AddTrack2	

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	vErrorCode = RC_UNKNOWN;
	If pRC = "E2" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "E1" Then
		vErrorCode = RC_COMMAND_NOT_APPLICABLE;
	ElsIf pRC = "EA" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "E3" Then
		vErrorCode = RC_CARD_FORMAT_ERROR;
	ElsIf pRC = "EE" Then
		vErrorCode = RC_GENERAL_READ_ERROR;
	ElsIf pRC = "EF" Then
		vErrorCode = RC_GENERAL_ENCODING_ERROR;
	ElsIf pRC = "EU" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "E8" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "ED" Then
		vErrorCode = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN;
	EndIf;
	Return vErrorCode;
EndFunction //  GetErrorCode

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pSourceAddress, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format source address
	vSourceAddress = TrimAll(pSourceAddress);
	// Build command string for the RS232 interface
	vCmd = STX;
	// Add source address only if it is not blank, assuming that 
	// if PC Id was not specified then Iron Logic PMS-Server is not used
	If Not IsBlankString(vSourceAddress) Then	
		vCmd = vCmd + SEP + vSourceAddress;
	EndIf;
	vCmd = vCmd + SEP + pCommandCode; // Command code
	vPrefixLen = StrLen(vCmd); // Length of command prefix
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	vCmd = vCmd + cmCharLRC(vCmd);
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 3000;
	For i = 1 To 3 Do
		vPQRes = pDLSys.PurgeQueue();
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = ACK Then
				Break;
			Else
				If vReply <> NAK Then
					Return RC_NO_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	pDLSys.PurgeQueue();
	If vReply = NAK Then
		Return RC_SYNTAX_ERROR;
	EndIf;
	// Read command reply message
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pDLSys.ReadStr();
		If Not IsBlankString(pReply) Then
			// Check LRC
			If cmCheckCharLRC(Mid(pReply, 2)) Then
				vBytesSent = pDLSys.WriteStr(ACK);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pDLSys.WriteStr(NAK);
				pDLSys.TimeoutReadTotalConstant = 3000;
			EndIf;
		Else
			Return RC_NO_REPLY;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vRC = Right(Left(pReply, vPrefixLen), 2);
		If vRC <> pCommandCode Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system error: '; de = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRC);
		Else
			// Retreive reply data
			If StrLen(pReply) > (vPrefixLen + 3) Then
				pReply = Mid(pReply, vPrefixLen + 2, StrLen(pReply) - (vPrefixLen + 3));
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pSourceAddress, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format source address
	vSourceAddress = TrimAll(pSourceAddress);
	// Build command string for the TCP interface
	vCmd = STX;
	// Add source address only if it is not blank, assuming that 
	// if PC Id was not specified then Iron Logic PMS-Server is not used
	If Not IsBlankString(vSourceAddress) Then	
		vCmd = vCmd + SEP + vSourceAddress;
	EndIf;
	vCmd = vCmd + SEP + pCommandCode; // Command code
	vPrefixLen = StrLen(vCmd); // Length of command prefix
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	vCmd = vCmd + cmCharLRC(vCmd);
	// Send command
	pDLSys.Timeout = 3;
	For i = 1 To 3 Do
		vFRes = pDLSys.Flush();
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1) <> -1 Then
				If vReply = ACK Then
					Break;
				Else
					If vReply <> NAK Then
						Return RC_NO_REPLY;
					EndIf;
				EndIf;
			Else
				AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return RC_NO_CONNECTION;
			EndIf;
		Else
			AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Read command reply message
	vReadOK = False;
	pDLSys.Timeout = pReadTimeout;
	For i = 1 To 3 Do
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Check LRC
				If cmCheckCharLRC(Mid(pReply, 2)) Then
					If pDLSys.Write(ACK, 1) <> -1 Then
						vReadOK = True;
						Break;
					Else
						AddError(NStr("en='Write command reply confirmation error: ';ru='Ошибка отправки подтверждения чтения ответа: ';de='Fehler beim Versenden der Lesebestätigung der Antwort: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return RC_NO_CONNECTION;
					EndIf;
				Else
					pDLSys.Write(NAK, 1);
					pDLSys.Timeout = 3;
				EndIf;
			Else
				Return RC_NO_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vRC = Right(Left(pReply, vPrefixLen), 2);
		If vRC <> pCommandCode Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system error: '; de = '" + SystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRC);
		Else
			 // Retreive reply data
			If StrLen(pReply) > (vPrefixLen + 3) Then
				pReply = Mid(pReply, vPrefixLen + 2, StrLen(pReply) - (vPrefixLen + 3));
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pSourceAddress, pDta, pReply)
	// Define command code
	vCommandCode = "CX";
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, pReply);
	Else
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, pReply);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pSourceAddress, pDta, pReply)
	// Define command code
	vCommandCode = "CG";
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, pReply);
	Else
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, pReply);
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetCardUID(pReply)
	vCardUID = pReply;
	vIdIsFound = Find(vCardUID, SEP);
	If vIdIsFound > 0 Then
		If StrLen(TrimAll(Left(vCardUID, vIdIsFound - 1))) < 3 Then
			vCardUID = Mid(vCardUID, vIdIsFound + 1);
			vIdIsFound = Find(vCardUID, SEP);
			If vIdIsFound > 0 Then
				vCardUID = Left(vCardUID, vIdIsFound - 1);
			EndIf;
		Else
			vCardUID = Left(vCardUID, vIdIsFound - 1);
		EndIf;		
	EndIf;
	Return TrimAll(vCardUID);
EndFunction //  GetCardUID

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	If pDelimeter = "" Then
		pDelimeter = SEP; // Char(124);
	EndIf;
	vWord = "";
	vPos = Find(pStr, pDelimeter);
	If vPos > 0 Then
		vWord = Left(pStr, vPos-1);
		pStr = TrimL(Right(pStr, StrLen(pStr) - vPos));
	Else
		vWord = TrimL(pStr);
		pStr = "";
	EndIf;
	Return vWord;
EndFunction //  GetNextWord

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardAuthorizations", "");
	
	// Get reply type
	vCardGIUD = GetNextWord(pCardDesc);
	// Card parameters
	vWord = GetNextWord(pCardDesc);
	sepChar = Char(124);
	pos = StrFind(vWord,"room");
	If pos > 0 Then
		vRoom = Mid(vWord,pos+6);
		pos2 = StrFind(vRoom, sepChar);
		If pos2 > 0 Then
			vCardData.CardRoom = Mid(vRoom,0,pos2-1);
		Else
			vCardData.CardRoom = vRoom;
		EndIf;
	EndIf;
	name = "starttime::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		vDate = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(vDate, sepChar);
		If pos2 > 0 Then
			vDate = Mid(vDate,0,pos2-1);
		EndIf;
		vCardData.CardCheckInDate = StrToDate(vDate);
	EndIf;
	name = "endtime::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		vDate = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(vDate, sepChar);
		If pos2 > 0 Then
			vDate = Mid(vDate,0,pos2-1);
		EndIf;
		vCardData.CardCheckOutDate = StrToDate(vDate);
	EndIf;
	// Place guest_card_version common_doors
	name = "common_doors::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		curValue = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(curValue, sepChar);
		If pos2 > 0 Then
			vCardData.AssignedAuthorizations = Mid(curValue,0,pos2-1);
		Else
			vCardData.AssignedAuthorizations = curValue;
		EndIf;
	EndIf;

	// Try to retrieve card authorizations
	vAuthRef = pmFindAuthorizations(DoorLockSystemParameters.Hotel, vCardData.AssignedAuthorizations);
	If ValueIsFilled(vAuthRef) Then
		vCardData.CardAuthorizations = TrimAll(vAuthRef.Code) + " - " + TrimAll(vAuthRef.Description);
	EndIf;
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pSourceAddress, pDta, pCardDesc)
	vErrorCode = RC_OK;
	pCardDesc = "";
	vReply = "";
	// Define command
	vCommandCode = "RC";
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, vReply);
	Else
		// Send command using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, vReply);
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_OK Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

Function StrToDate(pStrDate)
	If Not IsBlankString(pStrDate) And StrLen(pStrDate) >= 19 Then
		Try
		vDate = Date(Number(Mid(pStrDate,16,4)),Number(Mid(pStrDate,13,2)),Number(Mid(pStrDate,10,2)),Number(Mid(pStrDate,1,2)),Number(Mid(pStrDate,4,2)),Number(Mid(pStrDate,7,2)));
		Return vDate;
		Except
		EndTry;
	EndIf;
	Return '00010101';
EndFunction

#EndRegion  

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(1110); // It will be converted from Char(1110) in UTF-8 to Char(179) in CP-437 (Win-1251, etc...)
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 0;
RC_UNKNOWN = 100;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_WRONG_REPLY = 104;
RC_SYNTAX_ERROR = 105;
RC_NO_COMMUNICATION = 106;
RC_COMMAND_NOT_APPLICABLE = 107;
RC_CARD_FORMAT_ERROR = 108;
RC_GENERAL_READ_ERROR = 109;
RC_GENERAL_ENCODING_ERROR = 110;
RC_DEVICE_TIME_OUT = 111;
RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 112;
RC_WRONG_ROOM = 113;
RC_ROOM_WITHOUT_DOOR_LOCK = 114;
RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = 95;
// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion
