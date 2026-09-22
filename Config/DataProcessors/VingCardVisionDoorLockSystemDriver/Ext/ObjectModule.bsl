
#Region Variables

Var SEP;
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;
Var ui32Synch1;
Var ui32Synch2;
Var nRetOK;

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_IS_BUSY Export; // Device is busy
Var RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK Export; // No more room for cards in lock
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Export; // No guest previosly checked in
Var RC_WRONG_CHECK_IN_TIME Export; // Wrong check in time
Var RC_WRONG_CHECK_OUT_TIME Export; // Wrong check out time
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_VISION Export; // No vision
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_SYNTAX_ERROR Export; // Syntax error
Var RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Export; // Only one active card allowed

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
	vVision = pmConnect();
	If vVision = Undefined Then
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
	vDta = SEP + "R" + vRoomCode;
	// Card type (authorizations)
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.KeyCardType) Then
		vDta = vDta + SEP + "T" + TrimAll(vDoorLockSystemAuthorization.KeyCardType);
	Else
		vDta = vDta + SEP + "T" + TrimAll(DoorLockSystemParameters.KeyCardType);
	EndIf;
	// Guest
	If ValueIsFilled(Guest) Then
		vDta = vDta + SEP + "F" + Transliterate(TrimAll(Guest.FirstName));
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(Guest.LastName));
	Else
		vDta = vDta + SEP + "F";
		vDta = vDta + SEP + "N";		
	EndIf;
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + DoorLockSystemParameters.UserGroup;
	EndIf;
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vVision, vDta, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If DoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + SEP + "S";
		EndIf;
		
		vOpId = "PMS";
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			vOpId = Left(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin, 9);
		EndIf;
		vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
		vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		vSourceAddress = "00";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		vErrorCode = MakeNewKey(vVision, vSourceAddress, vEncoderNumber, vOpId, vOpFirstName, vOpLastName, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + vDta);
			cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
		EndIf;
		
		pmDisconnect(vVision);
		Return vErrorCode;
	EndIf;
EndFunction //  pmNewKey
 
// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vVision = pmConnect();
	If vVision = Undefined Then
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
	vDta = SEP + "R" + vRoomCode;
	// Card type (authorizations)
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.KeyCardType) Then
		vDta = vDta + SEP + "T" + TrimAll(vDoorLockSystemAuthorization.KeyCardType);
	Else
		vDta = vDta + SEP + "T" + TrimAll(DoorLockSystemParameters.KeyCardType);
	EndIf;
	// Guest
	If ValueIsFilled(Guest) Then
		vDta = vDta + SEP + "F" + Transliterate(TrimAll(Guest.FirstName));
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(Guest.LastName));
	Else
		vDta = vDta + SEP + "F";
		vDta = vDta + SEP + "N";		
	EndIf;
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + DoorLockSystemParameters.UserGroup;
	EndIf;
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vVision, vDta, True);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If DoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + SEP + "S";
		EndIf;
		
		vOpId = "PMS";
		If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			vOpId = Left(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin, 9);
		EndIf;
		vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
		vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		vSourceAddress = "00";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		vErrorCode = AddKey(vVision, vSourceAddress, vEncoderNumber, vOpId, vOpFirstName, vOpLastName, vDta);
	    If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + vDta);
			cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
		EndIf;
		
		pmDisconnect(vVision);
		Return vErrorCode;
	EndIf;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data
// 
// Returns:
//  String - Error code 
//
Function pmVerify(pCardData) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vVision = pmConnect();
	If vVision = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vOpId = "PMS";
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
		vOpId = Left(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin, 9);
	EndIf;
	vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
	vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	vSourceAddress = "00";
	If Not IsBlankString(DoorLockSystemParameters.PCId) Then
		vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
	EndIf;
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vVision, vSourceAddress, vEncoderNumber, vOpId, vOpFirstName, vOpLastName, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vVision);
	
	Return vErrorCode;
EndFunction // pmVerify

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
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = RC_DEVICE_IS_BUSY Then
		Return(NStr("ru = 'Энкодер карт используется другим приложением!'; 
		            |de = 'Cards encoder is in use by another application!';
		            |en = 'Cards encoder is in use by another application!'"));
	ElsIf pRC = RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK Then
		Return(NStr("ru = 'На номер уже выписано максимальное число дополнительных карт!'; 
		            |de = 'Maximum number of key cards is reached for the room!'; 
		            |en = 'Maximum number of key cards is reached for the room!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en='No checked in guests in the room! Make new key card instead.';ru='В номере нет размещенных гостей! Выдайте гостю новую карту.';de='In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_CHECK_IN_TIME Then
		Return(NStr("ru = 'Неверно указано время заезда!'; 
		            |de = 'Check in time is wrong!'; 
		            |en = 'Check in time is wrong!'"));
	ElsIf pRC = RC_WRONG_CHECK_OUT_TIME Then
		Return(NStr("ru = 'Неверно указано время выезда!'; 
		            |de = 'Check out time is wrong!';
		            |en = 'Check out time is wrong!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_VISION Then
		Return(NStr("ru = 'Не запущен VISION!'; 
		            |de = 'VISION is not started!'; 
		            |en = 'VISION is not started!'"));
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
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='Device time-out!';
		            |de='Device time-out!';
			        |ru='Время ожидания карты истекло!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card params
//  pIsMaster	 - Boolean	 - Is master
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
//  pHotel		 - CatalogRef.Hotel	 - Ref
//  pKeyCardType - String			 - Card type
//  pUserGroup	 - String			 - User group
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Catalog ref or undefined
//
Function pmFindAuthorizations(pHotel, pKeyCardType, pUserGroup) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.KeyCardType = &qKeyCardType
	|	AND DoorLockSystemAuthorizations.UserGroup = &qUserGroup
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (NOT DoorLockSystemAuthorizations.DeletionMark)
	|	AND (NOT DoorLockSystemAuthorizations.IsFolder)
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qKeyCardType", pKeyCardType);
	vQry.SetParameter("qUserGroup", pUserGroup);
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
Function RS232Acknowledgement(pVision)
	// Send ENQ and wait for ACK
	vBytesSent = pVision.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pVision.TimeoutReadTotalConstant = 3000;
		vReply = pVision.ReadStr();
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
Function SPMSifHdr(pCommand, pBodySize)
	vHdr = "";
	// uint32 ui32Synch1;	/* Message synch1 = 0x55555555 */
	vHdr = vHdr + ui32Synch1;
	// uint32 ui32Synch2;	/* Message synch2 = 0xaaaaaaaa */
	vHdr = vHdr + ui32Synch2;
	// uint16 ui16Version;	/* Header format version = 1   */
	vHdr = vHdr + Char(1);
	// uint32 ui32Cmd;	    /* Command				       */
	vHdr = vHdr + Char(0) + Char(pCommand);
	// uint32 ui32BodySize;	/* Size of message body        */
	vMap = cmGetByte2CharIndexMap();
	vHexBodySize = cmBin2Hex(cmDec2Bin(pBodySize));
	If StrLen(vHexBodySize) = 1 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0) + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 2 Then
		vHdr = vHdr + Char(0) + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 3 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 4 Then
		vHdr = vHdr + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 5 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0);
	ElsIf StrLen(vHexBodySize) = 6 Then
		vHdr = vHdr + Char(0);
	ElsIf StrLen(vHexBodySize) = 7 Then
		vHexBodySize = "0" + vHexBodySize;
	EndIf;
	For i = 1 To StrLen(vHexBodySize)/2 Do
		vHexByte = Mid(vHexBodySize, i, 2);
		vHdr = vHdr + Char(vMap.Get(vHexByte));
	EndDo;
	vHdr = vHdr + ?(pCommand = 4, Char(2), Char(0)) + Char(0) + Char(0);
	// Return
	Return vHdr;
EndFunction //  SPMSifHdr

// -----------------------------------------------------------------------------
Function PMSifRegister(pVision, pReadTimeout = 60)
	// Build message string
	vHdr = SPMSifHdr(1, 44);
	vMsg = vHdr + cmGetNullTerminatingString(TrimAll(DoorLockSystemParameters.LicenseCode), 20);
	vMsg = vMsg + cmGetNullTerminatingString("1CHOTEL", 20);
	vMsg = vMsg + nRetOK;
	// Send PMSifRegister message
	vReply = "";
	pVision.Timeout = pReadTimeout;
	vBytesSent = pVision.Write(vMsg, 62);
	If vBytesSent <> -1 Then
		If pVision.Read(vReply, 62) <> -1 Then
			If StrLen(vReply) >= StrLen(vHdr) And 
			   Mid(vReply, 1, 4) = ui32Synch1 And 
			   Mid(vReply, 5, 4) = ui32Synch2 Then
				nRet = Right(vReply, 4);
				If nRet = nRetOK Then
					Return True;
				Else
					AddError(NStr("ru = 'При регистрации на сервере Vision PMS interface получен код ошибки: '; en = 'Error return code received after Vision PMS interface server registration: '; de = 'Error return code received after Vision PMS interface server registration: '") + nRet);
				EndIf;
			Else
				AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + vReply);
			EndIf;
		Else
			AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + pVision.LastError + " - " + pVision.LastErrorString);
		EndIf;
	Else
		AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + pVision.LastError + " - " + pVision.LastErrorString);
	EndIf;
	// Close TCP/IP socket
	vErrorCode = pVision.Disconnect();
	pVision = Undefined;
	// Return failure
	Return False;
EndFunction //  PMSifRegister

// -----------------------------------------------------------------------------
Procedure PMSifUnregister(pVision)
	// Build message string
	vHdr = SPMSifHdr(2, 4);
	vMsg = vHdr + nRetOK;
	// Send PMSifUnregister message
	vBytesSent = pVision.Write(vMsg, 22);
EndProcedure //  PMSifUnregister

// -----------------------------------------------------------------------------
Function PMSifEncodeKcdRmt(pVision, pReadTimeout, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, pDta, rReply)
	rReply = "";
	// Build header
	vHdr = SPMSifHdr(4, 53);
	// Build message string
	vMsg = vHdr;
	// Dta[512]
	vMsg = vMsg + cmGetNullTerminatingString(pDta, 513);
	// dd[3]
	vMsg = vMsg + cmGetNullTerminatingString(pEncoderNumber, 3);
	// ss[3]
	vMsg = vMsg + cmGetNullTerminatingString(pSourceAddress, 3);
	// Debug
	vMsg = vMsg + Char(0) + Char(0) + Char(0) + Char(0);
	// szOpID[10]
	vMsg = vMsg + cmGetNullTerminatingString(TrimAll(pOpId), 10);
	// szOpFirst[16]
	vMsg = vMsg + cmGetNullTerminatingString(TrimAll(pOpFirstName), 16);
	// szOpLast[16]
	vMsg = vMsg + cmGetNullTerminatingString(TrimAll(pOpLastName), 16);
	// Send PMSifEncodeKcdRmt message
	vReply = "";
	pVision.Timeout = pReadTimeout;
	vBytesSent = pVision.Write(vMsg, 583);
	If vBytesSent <> -1 Then
		If pVision.Read(vReply, 583) <> -1 Then
			If StrLen(vReply) >= StrLen(vHdr) And 
			   Mid(vReply, 1, 4) = ui32Synch1 And 
			   Mid(vReply, 5, 4) = ui32Synch2 Then
				rReply = Mid(vReply, 19);
				Return True;
			Else
				AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + vReply);
			EndIf;
		Else
			AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + pVision.LastError + " - " + pVision.LastErrorString);
		EndIf;
	Else
		AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + pVision.LastError + " - " + pVision.LastErrorString);
	EndIf;
	// Close TCP/IP socket
	vErrorCode = pVision.Disconnect();
	pVision = Undefined;
	// Return failure
	Return False;
EndFunction //  PMSifEncodeKcdRmt

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "VingCard";
	If DoorLockSystemParameters.DoorLockSystemType = Enums.DoorLockSystems.VingCardVision Then
		SystemName = "VingCard Vision";
	ElsIf DoorLockSystemParameters.DoorLockSystemType = Enums.DoorLockSystems.VingCardDavinci Then
		SystemName = "VingCard DaVinci";
	EndIf;
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vVision = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			vVision = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			vVision.InitString(GetCOMPortConnectionString());
			// Open COM port
			vIsOpen = vVision.Open(TrimAll(DoorLockSystemParameters.Port));
			If Not vIsOpen Then
				AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
				Return Undefined;
			EndIf;
			// Set block mode
			vVision.BlockMode = True;
			// Setup timeouts
			vVision.TimeoutReadInterval = 1000;
			vVision.TimeoutReadTotalConstant = 3000;
			vVision.TimeoutReadTotalMultiplier = 100;
			vVision.TimeoutWriteTotalConstant = 3000;
			vVision.TimeoutWriteTotalMultiplier = 100;
			// Send/receive acknowledgement
			If Not RS232Acknowledgement(vVision) Then
				AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + SystemName + "!'; en = 'Acknowledgement with system " + SystemName + " failed!'; de = 'Acknowledgement with system " + SystemName + " failed!'"));
				vVision.Close();
				Return Undefined;
			EndIf;
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			Try
			    vVision = New COMObject("SocketTools.SocketWrench.10");
				// Load license
				vErrorCode = vVision.Initialize(CSWSOCK10_LICENSE_KEY);
			Except
				vVision = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = vVision.Initialize(CSWSOCK6_LICENSE_KEY);
			EndTry;
			If vErrorCode <> 0 Then
				AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vVision.Blocking = True;
			vVision.Timeout = 30; // 30 seconds blocking read timeout by default
			vErrorCode = vVision.Connect(TrimAll(DoorLockSystemParameters.ServerName), ?(IsBlankString(DoorLockSystemParameters.Port), 3015, Number(TrimAll(DoorLockSystemParameters.Port))));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;
			// Call PMSifRegister
			If Not PMSifRegister(vVision, 30) Then
				AddError(NStr("ru = 'Ошибка регистрации на сервере Vision! Возможно неверно указан код лицензии.'; en = 'Failed to register at Vision server! PMS license code is possibly wrong.'; de = 'Failed to register at Vision server! PMS license code is possibly wrong.'"));
				Return Undefined;
			EndIf;     
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.VisionIntDll Then
			vVision = New COMObject("VisionInt.Vision.1");
			vErrorCode = vVision.VCConnect(DoorLockSystemParameters.ServerName);
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vErrorCode = vVision.VCRegister(TrimAll(DoorLockSystemParameters.LicenseCode), "1CHOTEL");
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка регистрации на сервере системы электронных замков " + SystemName + ": '; en = 'Registration error at " + SystemName + " server: '; de = 'Registration error at " + SystemName + " server: '") + vErrorCode);
				Return Undefined;
			EndIf;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vVision;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pVision)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			pVision.Close();
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			If pVision <> Undefined Then
				// Call PMSifUnregister
				PMSifUnregister(pVision);
				// Close TCP/IP socket
				vErrorCode = pVision.Disconnect();
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
					Return;
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.VisionIntDll Then
			vErrorCode = pVision.VCUnregister();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pVision = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack1And2(pVision, pDta, pAdd = False)
	If DoorLockSystemParameters.WriteTrack1 Or DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				IdentificationCard = vIDCardRef;
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If DoorLockSystemParameters.WriteTrack1 Then
					vTrack1 = TrimAll(vIDCardRef.Identifier) + "^" +
					          ?(ValueIsFilled(vIDCardRef.Folio), Transliterate(TrimAll(vIDCardRef.Folio.Number), True), "") + "^" + 
					          ?(ValueIsFilled(vIDCardRef.Room), Transliterate(TrimAll(vIDCardRef.Room.Description), True), "") + "^" + 
					          ?(ValueIsFilled(vIDCardRef.Client), Transliterate(TrimAll(vIDCardRef.Client.FullName), True), "") + "^" + 
					          Format(vIDCardRef.DateTimeFrom, "DF='yyMMdd'") + "^" + 
					          Format(vIDCardRef.DateTimeTo, "DF='yyMMdd'");
					pDta = pDta + SEP + "1" + Left(vTrack1, ?(DoorLockSystemParameters.Track1Length > 0, DoorLockSystemParameters.Track1Length, 76));
				EndIf;
				// Track 2 data: CardIdentifier
				If DoorLockSystemParameters.WriteTrack2 Then
					vTrack2 = TrimAll(vIDCardRef.Identifier);
					pDta = pDta + SEP + "2" + Left(vTrack2, 37);
				EndIf;
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pVision);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pVision);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return RC_OK;
EndFunction //  AddTrack1And2	

// -----------------------------------------------------------------------------
Function CallRS232Command(pVision, pReadTimeout = 60000, pEncoderNumber, pSourceAddress, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vSourceAddress = Format(Number(TrimAll(pSourceAddress)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Build command string for the RS232 interface
	vCmd = vEncoderNumber; // Destination address
	vCmd = vCmd + vSourceAddress; // Source address
	vCmd = vCmd + pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + ETX;
	vCmd = STX + vCmd + cmHexLRC(vCmd);
	// Send acknowledgement
	If Not RS232Acknowledgement(pVision) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pVision.TimeoutReadTotalConstant = 3000;
	For i = 1 To 3 Do
		vBytesSent = pVision.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pVision.ReadStr();
			If vReply = ACK Then
				Break;
			Else
				If vReply <> NAK Then
					Return RC_NO_REPLY;
				EndIf;
				pVision.PurgeQueue();
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	pVision.PurgeQueue();
	If vReply = NAK Then
		Return RC_SYNTAX_ERROR;
	EndIf;
	// Read command reply message
	vReadOK = False;
	pVision.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pVision.ReadStr();
		If Not IsBlankString(pReply) Then
			// Check LRC
			pReply = StrReplace(pReply, STX, "");
			If cmCheckHexLRC(pReply) Then
				vBytesSent = pVision.WriteStr(ACK);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pVision.WriteStr(NAK);
			EndIf;
		Else
			Return RC_NO_REPLY;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vErrorCode = CharCode(Mid(pReply, 5, 1));
		// Retreive reply data
		If StrLen(pReply) > 8 Then
			pReply = Mid(pReply, 6, StrLen(pReply) - 8);
		Else
			pReply = "";
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pVision, pReadTimeout = 60, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vSourceAddress = Format(Number(TrimAll(pSourceAddress)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Build command string for the TCP/IP interface
	vCmd = pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	// Send command
	If Not PMSifEncodeKcdRmt(pVision, pReadTimeout, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCmd, pReply) Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		vErrorCode = RC_WRONG_REPLY;
		// Retreive reply data
		If StrLen(pReply) > 2 Then
			// Retreive return code
			vErrorCode = CharCode(Mid(pReply, 1, 1));
			// Remove command code
			pReply = Mid(pReply, 3);
		Else
			pReply = "";
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pVision, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pDta)
	// Define default command code equal to "Check Out Old, Check In New"
	If BegOfDay(CheckInDate) > BegOfDay(CurrentSessionDate()) Then
		vCommandCode = "G";
	Else
		vCommandCode = "I";
	EndIf;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command and process reply
		vReply = "";
		vErrorCode = CallRS232Command(pVision, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pVision, 30, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, vReply);
		// Save card UID
		If DoorLockSystemParameters.ReturnCardUID And DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			If Not IsBlankString(vReply) Then
				vCardUID = GetCardUID(vReply);
				If StrLen(vCardUID) = 14 Then
					vCardIdentifier = TrimAll(Mid(vCardUID, 7, 8)) + TrimAll(Left(vCardUID, 6));
				Else
					vCardIdentifier = TrimAll(vCardUID);
				EndIf;
				If Not IsBlankString(vCardUID) Then
					IdentificationCard = cmGetClientIdentificationCard(vCardIdentifier, cmGetClientIdentificationCardById(vCardIdentifier), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
				EndIf;
			EndIf;
		EndIf;
	ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.VisionIntDll Then
		// Using VisionInt.dll interface
		vErrorCode = pVision.VCMakeNewKey(pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pDta);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pVision, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pDta)
	// Define default command code equal to "Add Guest"
	If BegOfDay(CheckInDate) > BegOfDay(CurrentSessionDate()) Then
		vCommandCode = "G";
	Else
		vCommandCode = "H";
	EndIf;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command and process reply
		vReply = "";
		vErrorCode = CallRS232Command(pVision, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply);
	ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pVision, 30, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, vReply);
		// Save card UID
		If DoorLockSystemParameters.ReturnCardUID And DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			If Not IsBlankString(vReply) Then
				vCardUID = GetCardUID(vReply);
				If StrLen(vCardUID) = 14 Then
					vCardIdentifier = TrimAll(Mid(vCardUID, 7, 8)) + TrimAll(Left(vCardUID, 6));
				Else
					vCardIdentifier = TrimAll(vCardUID);
				EndIf;
				If Not IsBlankString(vCardUID) Then
					IdentificationCard = cmGetClientIdentificationCard(vCardIdentifier, cmGetClientIdentificationCardById(vCardIdentifier), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
				EndIf;
			EndIf;
		EndIf;
	ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.VisionIntDll Then
		// Using VisionInt.dll interface
		vErrorCode = pVision.VCAddKey(pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pDta);
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetCardUID(pReply)
	vCardUID = "";
	vIdIsFound = Find(pReply, "S");
	If vIdIsFound > 0 Then
		vCardUID = Mid(pReply, vIdIsFound + 1);
		vSepIsFound = Find(vCardUID, SEP);
		If vSepIsFound > 1 Then
			vCardUID = Left(vCardUID, vSepIsFound - 1);
		EndIf;
	EndIf;
	Return vCardUID;
EndFunction //  GetCardUID

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	If pDelimeter = "" Then
		pDelimeter = SEP;
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
Function GetDate(pDateNum)
	Try
		If Not IsBlankString(pDateNum) Then
			Return Date(TrimAll(pDateNum));
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction //  GetDate

// -----------------------------------------------------------------------------
Procedure FillParameter(pCardData, pWord)
	If StrLen(pWord) <=1 Then
		Return;
	EndIf;
	vCommand = Left(pWord, 1);
	If vCommand = "R" Then
		pCardData.CardRoom = Right(pWord,StrLen(pWord)-1);
	ElsIf vCommand = "L" Then
		pCardData.CardRoom2 = GetNextWord(pWord, ",");
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom3 = GetNextWord(pWord, ",");
		EndIf;
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom4 = GetNextWord(pWord, ",");
		EndIf;
	ElsIf vCommand = "T" Then
		pCardData.CardType = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "F" Then
	   pCardData.CardFirstName = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "N" Then
		pCardData.CardLastName = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "U" Then
		pCardData.CardUserGroup = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "D" Then
		pCardData.CardCheckInDate = GetDate(Right(pWord,StrLen(pWord)-1));	
	ElsIf vCommand = "O" Then
		pCardData.CardCheckOutDate = GetDate(Right(pWord,StrLen(pWord)-1));		
	ElsIf vCommand = "S" Then
		vCardIdentifier = "";
		pCardData.CardID = cmGetCardIdentifier(Right(pWord,StrLen(pWord)-1));
		If StrLen(pCardData.CardID) = 14 Then
			vCardIdentifier = TrimAll(Mid(pCardData.CardID, 7)) + TrimAll(Left(pCardData.CardID, 6));
		Else
			vCardIdentifier = TrimAll(pCardData.CardID);
		EndIf;
		If Not IsBlankString(vCardIdentifier) Then
			vIDCardRef = cmGetClientIdentificationCardById(vCardIdentifier);
			If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.Client) Then
				pCardData.CardFullName = vIDCardRef.Client.FullName;
			EndIf;
		EndIf;
	EndIf;	
EndProcedure //  FillParameter

// -----------------------------------------------------------------------------
// Input parameter data example
Function pmParseCardDescription(Val pCardDesc)   
	// [SEP]R100[SEP]TSingle Room[SEP]FPupkin[SEP]NVasya[SEP]URegular Guest[SEP]D200506071000[SEP]O200506201200
	vCardData = New Structure();
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("CardType", "");
	vCardData.Insert("CardUserGroup", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
	vCardData.Insert("CardTrack1", "");
	vCardData.Insert("CardTrack2", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
	
	// Parse all fields
	vDataLen = StrLen(pCardDesc);
	While vDataLen > 0 Do
		vWord = GetNextWord(pCardDesc);
		vDataLen = StrLen(pCardDesc);
		FillParameter(vCardData,vWord);
	EndDo;
	
	// Try to retrieve card authorizations
	vAuthRef = pmFindAuthorizations(DoorLockSystemParameters.Hotel, vCardData.CardType, vCardData.CardUserGroup);
	If ValueIsFilled(vAuthRef) Then
		vCardData.CardAuthorizations = TrimAll(vAuthRef.Code) + " - " + TrimAll(vAuthRef.Description);
	EndIf;
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pVision, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pCardDesc)
	// Define default command code equal to "Check card"
	vCommandCode = "E";
	vErrorCode = RC_OK;
	pCardDesc = "";
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command and process reply
		vReply = "";
		vErrorCode = CallRS232Command(pVision, 60000, pEncoderNumber, pSourceAddress, vCommandCode, "", vReply);
		// Retrieve card data
		If vErrorCode = RC_OK Then
			pCardDesc = vReply;
		ElsIf vErrorCode = RC_UNKNOWN Then
			// Card was not recognized
			vErrorCode = RC_OK;
		EndIf;
	Else
		If DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			// Using TCP/IP interface
			vReply = "";
			vErrorCode = CallTCPCommand(pVision, 30, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, "", vReply);
			// Retrieve card data
			If vErrorCode = RC_OK Then
				pCardDesc = vReply;
			ElsIf vErrorCode = RC_UNKNOWN Then
				// Card was not recognized
				vErrorCode = RC_OK;
			EndIf;
		ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.VisionIntDll Then
			// Using VisionInt.dll interface
			pCardDesc = pVision.VCVerify(pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName);
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion     

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(30);
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);

ui32Synch1 = Char(85) + Char(85) + Char(85) + Char(85);
ui32Synch2 = Char(1028) + Char(1028) + Char(1028) + Char(1028);
nRetOK = Char(0) + Char(0) + Char(0) + Char(0);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 48;
RC_UNKNOWN = 49;
RC_DEVICE_IS_BUSY = 53;
RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK = 54;
RC_DEVICE_TIME_OUT = 56;
RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 57;
RC_WRONG_CHECK_IN_TIME = 68;
RC_WRONG_CHECK_OUT_TIME = 79;
RC_WRONG_ROOM = 82;
RC_NO_VISION = 50;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_WRONG_REPLY = 104;
RC_SYNTAX_ERROR = 105;
RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = 95;

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion

