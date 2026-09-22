
#Region Variables

Var SEP;
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknouwn
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

// -----------------------------------------------------------------------------
Var SystemName;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey() Export
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
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + DoorLockSystemParameters.UserGroup;
	EndIf;
	// Check check out date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	vDta = vDta + SEP + "O" + Format(vCheckOutDate, "DF=yyyyMMddHHmm");

	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vVision, vDta, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
		vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		vSourceAddress = "00";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API first af all need to check out old guests
		vErrorCode = CheckOutGuest(vVision, vSourceAddress, vEncoderNumber, vOpFirstName, vOpLastName, vDta);
		// Then make new key
		vErrorCode = MakeNewKey(vVision, vSourceAddress, vEncoderNumber, vOpFirstName, vOpLastName, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '" + vDta));
			cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest);
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
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + "R" + vRoomCode;
	// Card type (authorizations)
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) 
		And ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) 
		And Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + DoorLockSystemParameters.UserGroup;
	EndIf;
	// Check in and check out dates
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	vDta = vDta + SEP + "O" + Format(vCheckOutDate, "DF=yyyyMMddHHmm");
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vVision, vDta, True);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
		vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		vSourceAddress = "00";
		If Not IsBlankString(DoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		vErrorCode = AddKey(vVision, vSourceAddress, vEncoderNumber, vOpFirstName, vOpLastName, vDta);
	    If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '" + vDta));
			cmWriteKeyCardSecuritySystemEvent("ADD", "", Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest);
		EndIf;
		
		pmDisconnect(vVision);
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
	vVision = pmConnect();
	If vVision = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vOpFirstName = Left(SessionParameters.CurrentUser.FirstName, 15);
	vOpLastName = Left(SessionParameters.CurrentUser.LastName, 15);
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	vSourceAddress = "00";
	If Not IsBlankString(DoorLockSystemParameters.PCId) Then
		vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
	EndIf;
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vVision, vSourceAddress, vEncoderNumber, vOpFirstName, vOpLastName, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vVision);
	
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
		           |en = 'Failed to connect to the door locks system " + SystemName + "!';
				   |de = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';
					|ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';
					|de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = RC_DEVICE_IS_BUSY Then
		Return(NStr("en='Cards encoder is in use by another application!';
					|ru='Энкодер карт используется другим приложением!';
					|de='Encoder der Karten wird von einer anderen Anwendung verwendet!'"));
	ElsIf pRC = RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK Then
		Return(NStr("en='Maximum number of key cards is reached for the room!';
					|ru='На номер уже выписано максимальное число дополнительных карт!';
					|de='Für das Zimmer wurde bereits die maximale Anzahl an Zusatzkarten ausgegeben!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en='No checked in guests in the room! Make new key card instead.';
					|ru='В номере нет размещенных гостей! Выдайте гостю новую карту.';
					|de='In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_CHECK_IN_TIME Then
		Return(NStr("en='Check in time is wrong!';ru='Неверно указано время заезда!';de='Die Uhrzeit der Anreise wurde falsch angegeben!'"));
	ElsIf pRC = RC_WRONG_CHECK_OUT_TIME Then
		Return(NStr("en='Check out time is wrong!';ru='Неверно указано время выезда!';de='Der Abreisezeitpunkt wurde falsch angegeben!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан не верно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_VISION Then
		Return(NStr("en='VISION is not started!';ru='Не запущен VISION!';de='VISION wurde nicht gestartet!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |en = '" + SystemName + " system is not responding!';
					|de = '" + SystemName + " system is not responding!'"))
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |en = '" + SystemName + " system replied with unknown format!';
					|de = '" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';
					|ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';
					|de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='Device time-out!';ru='Время ожидания карты истекло!';de='Zeit der Erwartung der Karte ist abgelaufen!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

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
	|	DoorLockSystemAuthorizations.Ref AS Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.KeyCardType = &qKeyCardType
	|	AND DoorLockSystemAuthorizations.UserGroup = &qUserGroup
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND NOT DoorLockSystemAuthorizations.DeletionMark
	|	AND NOT DoorLockSystemAuthorizations.IsFolder
	|
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
Procedure MessageP(pStr)
	pStr = StrReplace(pStr,ACK, "<ACK>");
	pStr = StrReplace(pStr,NAK, "<NAK>");
	pStr = StrReplace(pStr,ENQ, "<ENQ>");
	pStr = StrReplace(pStr,SEP, "|");
	pStr = StrReplace(pStr,STX, "<STX>");
	pStr = StrReplace(pStr,ETX, "<ETX>");
	pStr = StrReplace(pStr,DLE, "<DLE>");
EndProcedure

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
	vStr = vStr + ",X";
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function ReadString(pVision)
	vReply = "";
	vBytesRcv = 1;
	While vBytesRcv > 0 Do
		vChar = 0;
		vBytesRcv = pVision.Read(vChar, 1);
		If vBytesRcv > 0 Then
			vReply = vReply + Char(vChar);
		EndIf;
	EndDo;
	Return vReply;
EndFunction

// -----------------------------------------------------------------------------
Function Acknowledgement(pVision)
	// Send ENQand wait for ACK
	vReply = "";
	vBytesSent = pVision.WriteStr(ENQ);
	MessageP("PMS>" + ENQ);
	If vBytesSent = 1 Then
		pVision.TimeoutReadTotalConstant = 1000;
		vReply = ReadString(pVision);
		If NOT IsBlankString(vReply) Then
			MessageP("VC>" + vReply);
			If vReply = ACK Then
				Return True;
			ElsIf vReply = NAK Then
				AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
			Else
				AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten:'") + vReply);
			EndIf;
		Else
			AddError(NStr("en='Device is busy';ru='Энкодер не отвечает';de='Encoder reagiert nicht!'") + vReply);
		EndIf;	
	Else
		AddError(NStr("en='Wrong number of bytes sent on acknowledgement: ';ru='При подтверждении связи отправлено байт: ';de='Bei der Bestätigung der Verbindung Byte versendet:'") + vBytesSent);
	EndIf;
	Return False;
EndFunction //  Acknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "VingCard";
	If DoorLockSystemParameters.DoorLockSystemType = Enums.DoorLockSystems.VingCard2100 Then
		SystemName = "VingCard 2100 (PLUS)";
	ElsIf DoorLockSystemParameters.DoorLockSystemType = Enums.DoorLockSystems.VingCard2800 Then
		SystemName = "VingCard 2800";
	EndIf;
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vVision = Undefined;
		vVision = New COMObject("SPort.SPortAx.1");
		// Set connection parameters
		vVision.InitString(GetCOMPortConnectionString());
		// Open COM port
		vIsOpen = vVision.Open(TrimAll(DoorLockSystemParameters.Port));
		If Not vIsOpen Then
			AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(DoorLockSystemParameters.Port));
			Return Undefined;
		EndIf;
		// Set block mode
		vVision.BlockMode = true;
		// Setup timeouts
		vVision.TimeoutReadInterval = 100;
		vVision.TimeoutReadTotalConstant = 100;
		vVision.TimeoutReadTotalMultiplier = 100;
		vVision.TimeoutWriteTotalConstant = 100;
		vVision.TimeoutWriteTotalMultiplier = 100;
		// Send/receive acknowledgement
		If Not Acknowledgement(vVision) Then
			AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + SystemName + "!'; 
			|en = 'Acknowledgement with system " + SystemName + " failed!';
			|de = 'Acknowledgement with system " + SystemName + " failed!'"));
			vVision.Close();
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
					  |en = '" + SystemName + " door lock system connection error: 
					  |de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vVision;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pVision)
	Try
		pVision.Close();
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": ';
					  |en = '" + SystemName + " system disconnect error: ';
					  |de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
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
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If DoorLockSystemParameters.WriteTrack1 Then
					vTrack1 = TrimAll(vIDCardRef.Identifier) + "^" 
							+ ?(ValueIsFilled(vIDCardRef.Folio), Transliterate(TrimAll(vIDCardRef.Folio.Number), True), "") + "^" 
							+ ?(ValueIsFilled(vIDCardRef.Room), Transliterate(TrimAll(vIDCardRef.Room.Description), True), "") + "^" 
							+ ?(ValueIsFilled(vIDCardRef.Client), Transliterate(TrimAll(vIDCardRef.Client.FullName), True), "") + "^" 
							+ Format(vIDCardRef.DateTimeFrom, "DF='yyMMdd'") + "^" + Format(vIDCardRef.DateTimeTo, "DF='yyMMdd'");
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
	If Not Acknowledgement(pVision) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pVision.TimeoutReadTotalConstant = 100;
	vBytesSent = pVision.WriteStr(vCmd);
	MessageP("PMS>" + vCmd);
	If vBytesSent > 0 Then
		For i = 1 To 3 Do
			vReply = pVision.ReadStr();
			MessageP("VC>" + vReply);
			If StrLen(vReply) > 7 Then
				vErrorCode = Mid(vReply, 7, 1);
			ElsIf Left(vReply, 1) = ACK Then
				vErrorCode = RC_OK;
				vReply = ReadString(pVision);
				MessageP("VC>" + vReply);
			EndIf;
			vBytesSent = pVision.WriteStr(ACK);
			Break;
		EndDo;
	Else
		Return RC_NO_CONNECTION;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CheckOutGuest(pVision, pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pDta)
	// Define command code equal to "Check Out Guest"
	vCommandCode = "B";
	// Build command string for the RS232 interface
	vDta = "";
	vPos = Find(pDta, SEP + "U");
	If vPos > 1 Then
		vDta = Left(pDta, vPos - 1);
	Else
		Return RC_UNKNOWN;
	EndIf;
	// Send command and process reply
	vReply = "";
	vErrorCode = CallRS232Command(pVision, 3000, pSourceAddress, pEncoderNumber, vCommandCode, vDta, vReply);
	Return vErrorCode;
EndFunction //  CheckOutGuest

// -----------------------------------------------------------------------------
Function MakeNewKey(pVision, pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pDta)
	// Define default command code equal to "Check Out Old, Check In New"
	vCommandCode = "A";
	// Send command and process reply
	vReply = "";
	vErrorCode = CallRS232Command(pVision, 60000, pSourceAddress, pEncoderNumber, vCommandCode, pDta, vReply);
	Return vErrorCode;
EndFunction //  MakeNewKey
 
// -----------------------------------------------------------------------------
Function AddKey(pVision, pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pDta)
		// There is no "Add Guest" command for the VC 2100 systems. Use "Check In Guest" instead
		vCommandCode = "A";
		// Send command and process reply
		vReply = "";
		vErrorCode = CallRS232Command(pVision, 60000, pSourceAddress, pEncoderNumber, vCommandCode, pDta, vReply);
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter = "")
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
EndFunction // GetDate

// -----------------------------------------------------------------------------
Procedure FillParameter(pCardData, pWord)
	If StrLen(pWord) <=1 Then
		Return;
	EndIf;
	vCommand = Left(pWord, 1);
	If vCommand = "R" Then
		pCardData.CardRoom = Right(pWord,StrLen(pWord) - 1);
	ElsIf vCommand = "L" Then
		pCardData.CardRoom2 = GetNextWord(pWord, ",");
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom3 = GetNextWord(pWord, ",");
		EndIf;
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom4 = GetNextWord(pWord, ",");
		EndIf;
	ElsIf vCommand = "T" Then
		pCardData.CardType = Right(pWord,StrLen(pWord) - 1);	
	ElsIf vCommand = "F" Then
	   pCardData.CardFirstName = Right(pWord,StrLen(pWord) - 1);	
	ElsIf vCommand = "N" Then
		pCardData.CardLastName = Right(pWord,StrLen(pWord) - 1);	
	ElsIf vCommand = "U" Then
		pCardData.CardUserGroup = Right(pWord,StrLen(pWord) - 1);	
	ElsIf vCommand = "D" Then
		pCardData.CardCheckInDate = GetDate(Right(pWord,StrLen(pWord) - 1));	
	ElsIf vCommand = "O" Then
		pCardData.CardCheckOutDate = GetDate(Right(pWord,StrLen(pWord) - 1));		
	EndIf;	
EndProcedure // FillParameter

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
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
Function Verify(pVision, pSourceAddress, pEncoderNumber, pOpFirstName, pOpLastName, pCardDesc)
	vErrorCode = RC_OK;
	pCardDesc = "";
	// Define default command code equal to "Check card"
	vCommandCode = "E";
	// Send command and process reply
	vReply = "";
	vErrorCode = CallRS232Command(pVision, 60000, pSourceAddress, pEncoderNumber, vCommandCode, "", vReply);
	// Retrieve card data
	If vErrorCode = RC_OK Then
		pCardDesc = vReply;
	ElsIf vErrorCode = RC_UNKNOWN Then
		// Card was not recognized
		vErrorCode = RC_OK;
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

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = "0";
RC_UNKNOWN = "1";
RC_DEVICE_IS_BUSY = 53;
RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK = "6";
RC_DEVICE_TIME_OUT = 56;
RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 57;
RC_WRONG_CHECK_IN_TIME = "D";
RC_WRONG_CHECK_OUT_TIME = "O";
RC_WRONG_ROOM = "R";
RC_NO_VISION = 50;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_WRONG_REPLY = 104;

#EndRegion
