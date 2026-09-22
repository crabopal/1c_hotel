
#Region Variables

Var SEP;
Var STX;
Var ETX;

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_SYNTAX_ERROR Export; // Syntax error
Var RC_NO_COMMUNICATION Export; // No communication
Var RC_CARD_FORMAT_ERROR Export; // Card format error
Var RC_GENERAL_READ_WRITE_ERROR Export; // General read write error
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_NO_CARD Export; // No card
Var RC_CARD_NOT_EMPTY Export; // Card not empty
Var RC_CARD_COUNT_OVER_LIMIT Export; // Card count over limit
Var RC_EMPTY_CARD Export; // Empty card

// -----------------------------------------------------------------------------
Var SystemName;

// -----------------------------------------------------------------------------
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pIsAdditionalKey - Boolean	 - Additional key
// 
// Returns:
//  String - Error code
//
Function pmNewKey(pIsAdditionalKey = False) Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string starting from room codes
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = Left(TrimR(Room.LockCode), 47);
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
				vRoomCode = Left(TrimR(Room.LockCode), 47);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + "R" + vRoomCode;
	
	// Add card type
	vDta = vDta + SEP + "T" + TrimAll(DoorLockSystemParameters.KeyCardType);
	
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
	vDta = vDta + SEP + "D" + Format(vCheckInDate, "DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate, "DF=yyyyMMddHHmm");
	
	// Add guest name
	vGuestName = "";
	If ValueIsFilled(Guest) Then
		vGuestName = Left(Transliterate(TrimAll(Guest.FullName), True), 50);
		vDta = vDta + SEP + "N" + vGuestName;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + "C" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vDta = vDta + SEP + "C" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		If Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) Then
			vDta = vDta + SEP + "C" + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		EndIf;
	EndIf;
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys, vDta, pIsAdditionalKey);
	If vErrorCode = RC_OK Then
		WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
		cmWriteKeyCardSecuritySystemEvent(?(pIsAdditionalKey, "ADD", "NEW"), "", Room, vDta, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
	EndIf;
	
	// Disconnect from door lock system
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	Return pmNewKey(True);
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
	
	vDta = "";
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vDta, vCardDesc);
	If vErrorCode = RC_OK Then
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
		Return(NStr("ru = 'Не удалось установить соединение с системой " + SystemName + "!';en = 'Failed to connect to the door locks system " + SystemName + "!';de = 'Failed to connect to the door locks system " + SystemName + "!'")); 
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |en = '" + SystemName + " system is not responding!';
					|de = '" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
					|en = '" + SystemName + " system replied with unknown format!';
		            |de = '" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("en='The encoder does not answer (failure in the communications or switched off)!';ru='Энкодер не отвечает (возможно выключен или не подключен)!';de='Encoder antwortet nicht (ist möglicherweise abgeschaltet oder nicht eingeschaltet)!'"));
	ElsIf pRC = RC_CARD_FORMAT_ERROR Then              
		Return(NStr("en='Card inserted wrongly, card is broken or from another system!';ru='Не правильно вставлена карта, карта не читается или карта от другой системы!';de='Die Karte ist falsche eingesetzt, kann nicht gelesen werden oder stammt aus einem anderen System!'"));
	ElsIf pRC = RC_GENERAL_READ_WRITE_ERROR Then
		Return(NStr("en='General Read/Write error. The reading/writing operation failed!';ru='Ошибка чтения/записи карты. Прочитать/записать данные с карты не удалось!';de='Fehler beim Lesen / Schreiben der Karte. Die Daten konnten nicht von der Karte gelesen / auf die Karte geschrieben werden!'"));
	ElsIf pRC = RC_NO_CARD Then
		Return(NStr("en='No card!';ru='Нет карты!';de='Keine Karte!'"));
	ElsIf pRC = RC_CARD_NOT_EMPTY Then
		Return(NStr("en='Card is not empty, revoke it firstly!';ru='Карта уже записана! Удалите данные с карты.';de='Die Karte ist bereits beschrieben! Löschen Sie die Daten auf der Karte'"));
	ElsIf pRC = RC_EMPTY_CARD Then
		Return(NStr("en='Card is empty!';ru='Пустая карта!';de='Leere Karte!'"));
	ElsIf pRC = RC_CARD_COUNT_OVER_LIMIT Then
		Return(NStr("ru = 'Card count over limit!'; 
					|en = 'Card count over limit!';
		            |en = 'Card count over limit!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

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
Function pmConnect()
	// Fill system name
	SystemName = "Xeeder";
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
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
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; en = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pAdd = False)
	// Add/get client identification card
	If ValueIsFilled(Folio) Then
		vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
		If ValueIsFilled(vIDCardRef) Then
			// Track 2 data: CardIdentifier
			If DoorLockSystemParameters.WriteTrack2 Then
				vTrack2 = TrimAll(vIDCardRef.Identifier);
				pDta = pDta + SEP + "S2" + SEP + "H" + Left(vTrack2, 14);
			Else
				pDta = pDta + SEP + "S2" + SEP + "H";
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
	Return RC_OK;
EndFunction //  AddTrack2	

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	vErrorCode = RC_UNKNOWN;
	If pRC = "08" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "00" Then
		vErrorCode = RC_OK;	
	ElsIf pRC = "09" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "01" Then
		vErrorCode = RC_NO_CARD;
	ElsIf pRC = "12" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "03" Then
		vErrorCode = RC_CARD_FORMAT_ERROR;
	ElsIf pRC = "04" Then
		vErrorCode = RC_CARD_FORMAT_ERROR;
	ElsIf pRC = "23" Then
		vErrorCode = RC_CARD_FORMAT_ERROR;
	ElsIf pRC = "05" Then
		vErrorCode = RC_GENERAL_READ_WRITE_ERROR;
	ElsIf pRC = "14" Then
		vErrorCode = RC_GENERAL_READ_WRITE_ERROR;
	ElsIf pRC = "15" Then
		vErrorCode = RC_GENERAL_READ_WRITE_ERROR;
	ElsIf pRC = "18" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "19" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "02" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "06" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "11" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "13" Then
		vErrorCode = RC_CARD_NOT_EMPTY;
	ElsIf pRC = "17" Then
		vErrorCode = RC_CARD_COUNT_OVER_LIMIT;
	ElsIf pRC = "20" Then
		vErrorCode = RC_EMPTY_CARD;
	EndIf;
	Return vErrorCode;
EndFunction //  GetErrorCode

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pCommandCode, pDta, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	// Build command string for the TCP interface
	vCmd = STX;
	// Add encoder number
	vCmd = vCmd + TrimAll(DoorLockSystemParameters.EncoderNumber);
	// Add source id
	vCmd = vCmd + TrimAll(DoorLockSystemParameters.PCId);
	// Save command prefix
	vCommandPrefix = vCmd;
	vPrefixLen = StrLen(vCommandPrefix);
	// Add command code
	vCmd = vCmd + pCommandCode; // Command code
	// Add command data
	vCmd = vCmd + pDta; // Command data
	// Add end of transmission field
	vCmd = vCmd + ETX;
	// Send command and get acknowledgement
	pReply = "";
	pDLSys.Timeout = 3;
	vFRes = pDLSys.Flush();
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Left(pReply, vPrefixLen) <> vCommandPrefix Then
				Return RC_WRONG_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls:'") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return RC_NO_CONNECTION;
	EndIf;
	// Retreive return code
	vRC = Mid(pReply, vPrefixLen + 1, 2);
	vErrorCode = GetErrorCode(vRC);
	If vErrorCode = RC_OK Then
		// Retreive reply data
		If StrLen(pReply) > (vPrefixLen + 3) Then
			pReply = Mid(pReply, vPrefixLen + 4, StrLen(pReply) - (vPrefixLen + 4));
		Else
			pReply = "";
		EndIf;
	Else
		AddError(NStr("en='Command execution error: ';ru='Ошибка выполнения команды: ';de='Fehler bei der Befehlausführung: '") + vRC + " - " + pmGetErrorDescription(vErrorCode) + Chars.LF + NStr("en='System reply is: ';ru='Ответ системы: ';de='Antwort des Systems: '") + pReply);
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDta, pIsAdditionalKey = False)
	vErrorCode = RC_OK;
	
	// Erase card first
	If Not pIsAdditionalKey Then
		vCommandCode = "0B";
		If DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			vDta = "";
			vReply = "";
			vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply);
		EndIf;
		If vErrorCode <> RC_OK Then
			Return vErrorCode;
		EndIf;
	EndIf;
	
	// Check-in guest
	vCommandCode = "0I";
	If DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, pDta, vReply);
	EndIf;
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	EndIf;
	
	// Write track 2 if neccessary
	If DoorLockSystemParameters.WriteTrack2 Then
		vCommandCode = "0W";
		vDta = "";
		vErrorCode = AddTrack2(pDLSys, vDta, False);
		If vErrorCode <> RC_OK Then
			Return vErrorCode;
		EndIf;
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply);
	EndIf;
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	EndIf;
	
	// Read card UID if neccessary
	If DoorLockSystemParameters.ReturnCardUID Then
		// Fill identification card
		IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, False);
			If ValueIsFilled(vIDCardRef) Then
				IdentificationCard = vIDCardRef;
			EndIf;
		EndIf;
		
		// Read card data
		vCommandCode = "0E";
		vDta = "";
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply);
		If vErrorCode <> RC_OK Then
			Return vErrorCode;
		EndIf;
		
		// Save card UID
		If Not IsBlankString(vReply) And ValueIsFilled(IdentificationCard) Then
			vCardUID = GetField("M", vReply);
			If Not IsBlankString(vCardUID) Then
				vIDCardObj = IdentificationCard.GetObject();
				vIDCardObj.CardUID = vCardUID;
				vIDCardObj.Write();
			EndIf;
		EndIf;
	EndIf;
	
	// Return result code
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function GetField(pFieldCode, pCardData)
	vFieldData = "";
	vCardData = TrimAll(pCardData);
	vPos = Find(vCardData, SEP + pFieldCode);
	If vPos > 0 Then
		vCardData = Mid(vCardData, vPos + 2);
		vSEPPos = Find(vCardData, SEP);
		If vSEPPos > 0 Then
			vFieldData = Left(vCardData, vSEPPos - 1);
		Else
			If Right(vCardData, 1) = ETX Then
				vFieldData = Left(vCardData, StrLen(vCardData) - 1);
			Else
				vFieldData = TrimAll(vCardData);
			EndIf;
		EndIf;
	EndIf;
	Return vFieldData;
EndFunction //  GetField

// -----------------------------------------------------------------------------
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			vDay = Mid(pDateStr, 7, 2);
			vMonth = Mid(pDateStr, 5, 2);
			vYear = Left(pDateStr, 4);
			vHour = Mid(pDateStr, 9, 2);
			vMinutes = Mid(pDateStr, 11, 2);
			Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinutes), 0);
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction //  GetDate

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardGuestName", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardType", "");
	
	// Card parameters
	vCardData.CardRoom = GetField("R", pCardDesc);
	vCardData.CardCheckInDate = GetDate(GetField("D", pCardDesc));
	vCardData.CardCheckOutDate = GetDate(GetField("O", pCardDesc));
	vCardData.CardGuestName = GetField("N", pCardDesc);
	vCardData.CardType = GetField("T", pCardDesc);
	
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDta, pCardDesc)
	// Read card data
	vCommandCode = "0E";
	pCardDesc = "";
	If DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, pDta, pCardDesc);
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion   

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(124); // SEP
STX = Char(2);
ETX = Char(3);

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
RC_CARD_FORMAT_ERROR = 108;
RC_GENERAL_READ_WRITE_ERROR = 109;
RC_DEVICE_TIME_OUT = 111;
RC_WRONG_ROOM = 113;
RC_ROOM_WITHOUT_DOOR_LOCK = 114;
RC_NO_CARD = 115;
RC_CARD_NOT_EMPTY = 116;
RC_CARD_COUNT_OVER_LIMIT = 117;
RC_EMPTY_CARD = 118;

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion
