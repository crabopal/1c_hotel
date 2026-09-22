  
#Region Variables

Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

// -----------------------------------------------------------------------------
Var RC_SYNTAX_ERROR Export;  // Syntax error
Var RC_NO_COMMUNICATION Export; // No communication
Var RC_OVERFLOW Export; // Overflow
Var RC_MAGNETIC_TRACK_ERROR Export;  // Error
Var RC_MAGNETIC_FORMAT_ERROR Export; // Error
Var RC_MAGNETIC_LEVEL_ERROR Export;  // Error
Var RC_NO_CONNECTION Export; // No Connection
Var RC_OK Export;  // Ok
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Export; // No guest previosly checked in
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock 
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_CARD_MEMORY_OVERFLOW Export; // Memory overflow

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
				vRoomCode = Left(TrimR(Room.LockCode), 15);
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
	
	// PFC 20; transaction request delimiter
	vDta = "20";
	
	// To SAFLOK interface station number
	vDta = vDta+TrimAll(DoorLockSystemParameters.PCId);
	
	// From SAFLOK interface station number.Always set 00
	vDta = vDta+"00";
	
	// Unique PMS terminal number or PMS interface request number
	vDta = vDta+Left(TrimAll(DoorLockSystemParameters.EncoderNumber), 3);
	
	// Transaction code (TXC) with 001 = new key and 003 = duplicate ke
	vDta = vDta+"001";

	// SAFLOK password  = seven alphanumeric characters
	vPassword = "SAFLOK "; //default
	If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemPassword) Then
		vPassword = SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemPassword;
		While StrLen(vPassword)<7 Do
			vPassword = vPassword+" ";	
		EndDo; 
	ElsIf ValueIsFilled(DoorLockSystemParameters.LicenseCode) Then
		vPassword =  DoorLockSystemParameters.LicenseCode;
		While StrLen(vPassword)<7 Do
			vPassword = vPassword+" ";	
		EndDo;
	EndIf;	
	vDta = vDta + vPassword;
	
	// Room  (15 alphanumeric characters)
	While StrLen(vRoomCode)<15 Do
		vRoomCode = vRoomCode+" ";	
	EndDo;
	vDta = vDta + vRoomCode;
	
	// Key level; 1 = guest level, 2 = connecter level, 3 = multi-connector  level, 4 = limited-use level
	vDta = vDta + "1";
	
	// Encoder station number to make key(s) at (default: 01)
	vEncStationNumber = "01";
	vSplitterPos = StrFind(TrimAll(DoorLockSystemParameters.EncoderNumber), "/");
	If vSplitterPos > 0 Then
		vEncStationNumber = Mid(TrimAll(DoorLockSystemParameters.EncoderNumber), vSplitterPos + 1, 2);
	EndIf;
	vDta = vDta + vEncStationNumber;
	
	// Encoder LED control information (normally set to FF)
	vDta = vDta + "FF";

	// Number of keys to make 
	vDta = vDta + String(Format(NumberOfKeys,"ND=2; NLZ="));
	
	// Calculate check-out date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	
	// Projected check-out date 
	vDta = vDta + Format(vCheckOutDate,"DF=MMddyy");
	
	// Projected check-out time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate,"DF=HHmm");
	
	// Key expiration date 
	vDta = vDta + Format(vCheckOutDate,"DF=MMddyy");
	
	// Key expiration time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate,"DF=HHmm");
	
	// Pass number option
	vDta = vDta + "1";

	If Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) Then
		// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
		// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
		vDta = vDta + Left(TrimAll(DoorLockSystemParameters.AssignedAuthorizations), 12);
	Else	
		// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
		// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
		vDta = vDta + "000000000000";
	EndIf;
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDLSys	 - Object	 - Com object
//  pDta	 - String	 - Params
// 
// Returns:
//  String - Error code
//
Function AddKey(pDLSys, pDta)
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pDta, "", vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pDta, "", vReply);
	EndIf;
	// Save card UID
	If vErrorCode = RC_OK Then
		If Not IsBlankString(vReply) And DoorLockSystemParameters.ReturnCardUID Then
			vReplyLen = StrLen(vReply);
			If vReplyLen > 3 Then
				vCardUID = vReply;
				IdentificationCard = cmGetClientIdentificationCard(vCardUID, cmGetClientIdentificationCardById(vCardUID), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code
//
Function pmAddKey() Export
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
	
	// PFC 20; transaction request delimiter
	vDta = "20";
	
	// To SAFLOK interface station number
	vDta = vDta+TrimAll(DoorLockSystemParameters.PCId);
	
	// From SAFLOK interface station number.Always set 00
	vDta = vDta+"00";
	
	// Unique PMS terminal number or PMS interface request number
	vDta = vDta+Left(TrimAll(DoorLockSystemParameters.EncoderNumber),3);
	
	// Transaction code (TXC) with 001 = new key and 003 = duplicate ke
	vDta = vDta+"003";

	// SAFLOK password  = seven alphanumeric characters
	vPassword = "SAFLOK "; //default
	If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemPassword) Then
		vPassword = SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemPassword;
		While StrLen(vPassword)<7 Do
			vPassword = vPassword+" ";	
		EndDo; 
	ElsIf ValueIsFilled(DoorLockSystemParameters.LicenseCode) Then
		vPassword =  DoorLockSystemParameters.LicenseCode;
		While StrLen(vPassword)<7 Do
			vPassword = vPassword+" ";	
		EndDo;
	EndIf;	
	vDta = vDta + vPassword;
	
	// Room  (15 alphanumeric characters)
	While StrLen(vRoomCode)<15 Do
		vRoomCode = vRoomCode+" ";	
	EndDo;
	vDta = vDta + vRoomCode;
	
	// Key level; 1 = guest level, 2 = connecter level, 3 = multi-connector  level, 4 = limited-use level
	vDta = vDta + "1";
	
	// Encoder station number to make key(s) at (default: 01)
	vEncStationNumber = "01";
	vSplitterPos = StrFind(TrimAll(DoorLockSystemParameters.EncoderNumber), "/");
	If vSplitterPos > 0 Then
		vEncStationNumber = Mid(TrimAll(DoorLockSystemParameters.EncoderNumber), vSplitterPos + 1, 2);
	EndIf;
	vDta = vDta + vEncStationNumber;
	
	// Encoder LED control information (normally set to FF)
	vDta = vDta + "FF";

	// Number of keys to make 
	vDta = vDta + String(Format(NumberOfKeys,"ND=2; NLZ="));
	
	// Calculate check-out date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	
	// Projected check-out date 
	vDta = vDta + Format(vCheckOutDate,"DF=MMddyy");
	
	// Projected check-out time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate,"DF=HHmm");
	
	// Key expiration date 
	vDta = vDta + Format(vCheckOutDate,"DF=MMddyy");
	
	// Key expiration time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate,"DF=HHmm");
	
	// Pass number option
	vDta = vDta + "1";

	If Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) Then
		// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
		// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
		vDta = vDta + Left(TrimAll(DoorLockSystemParameters.AssignedAuthorizations), 12);
	Else	
		// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
		// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
		vDta = vDta + "000000000000";
	EndIf;

	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		// Call API
		vErrorCode = AddKey(vDLSys, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmAddKey

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
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |de = 'System " + SystemName + "  antwortet nicht!'; 
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
	ElsIf pRC = RC_OVERFLOW Then
		Return(NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = RC_MAGNETIC_TRACK_ERROR Then
		Return(NStr("en='Card inserted wrongly or without magnetic stripe!';ru='Не правильно вставлена карта или карта без магнитной полосы!';de='Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'"));
	ElsIf pRC = RC_MAGNETIC_FORMAT_ERROR Then
		Return(NStr("en='You have removed card from the encoder before operation has finished or card/magnetic strip is damaged!';ru='Возможно сняли карту с энкодера не дожидаясь окончания операции или карта/магнитная полоса повреждена!';de='Möglicherweise haben Sie die Karte von Encoder vor dem Ende der Operation genommen oder die Karte/der Magnetstreifen ist beschädigt!'"));
	ElsIf pRC = RC_MAGNETIC_LEVEL_ERROR Then
		Return(NStr("en='The card has been encoded with a too low magnetic level due to dust in the reader magnetic head or low quality card!';ru='Низкий уровень намагничивания (возможно грязный энкодер или карта плохого качества)!';de='Niedriges Magnetisierungsniveau (möglicherweise ist der Encoder verschmutzt oder die Qualität der Karte ist schlecht)!'"));
	ElsIf pRC = RC_CARD_MEMORY_OVERFLOW Then
		Return(NStr("en='Card memory overflow!';ru='Переполнение памяти карты!';de='Der Kartenspeicher ist voll!'"));
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
Function RS232Acknowledgement(pDLSys)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 3000;
		vReply = pDLSys.ReadStr();
		If vReply = ACK Then
			Return True;
		ElsIf vReply = NAK Then
			AddError(NStr("en = 'NAK received on acknowledgement!'; ru = 'При подтверждении связи получен NAK!'; de = 'Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en = 'Wrong reply received on acknowledgement: '; ru = 'При подтверждении связи получен символ: '; de = 'Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en = 'Wrong number of bytes sent on acknowledgement: '; ru = 'При подтверждении связи отправлено байт: '; de = 'Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction //  RS232Acknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "KabaSaflok";
		
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
	    	AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + SystemName + "!'; 
	    	              |de = 'Acknowledgement with system " + SystemName + " failed!'; 
	    	              |en = 'Acknowledgement with system " + SystemName + " failed!'"));
			Return Undefined;
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
				AddError(NStr("en = 'SocketTools.SocketWrench component initialization error: '; ru = 'Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: '; de = 'Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vDLSys.Blocking = True;
			vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), Number(TrimAll(DoorLockSystemParameters.Port)));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; 
				              |de = '" + SystemName + " system server was not found: '; 
				              |en = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
		              |de = '" + SystemName + " door lock system connection error: '; 
		              |en = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
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
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; 
				              |de = '" + SystemName + " server disconnect error: '; 
				              |en = '" + SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; 
		              |de = '" + SystemName + " system disconnect error: '; 
		              |en = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack1And2(pDLSys, pDta, pAdd = False)
	If DoorLockSystemParameters.WriteTrack1 Or DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				IdentificationCard = vIDCardRef;
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If DoorLockSystemParameters.WriteTrack1 Then
					pDta = pDta + "*";
					// Track 2 data: CardIdentifier
					If DoorLockSystemParameters.WriteTrack2 Then
						vTrack2 = Left(TrimAll(vIDCardRef.Identifier), 35);
						pDta = pDta + "2" + Format(StrLen(vTrack2), "ND=2; NLZ=; NG=") + vTrack2;
					EndIf;
					vTrack1 = TrimAll(vIDCardRef.Identifier) + "^" +
					          ?(ValueIsFilled(vIDCardRef.Folio), Transliterate(Upper(TrimAll(vIDCardRef.Folio.Number)), True), "") + "^" + 
					          ?(ValueIsFilled(vIDCardRef.Room), Transliterate(Upper(TrimAll(vIDCardRef.Room.Description)), True), "") + "^" + 
					          ?(ValueIsFilled(vIDCardRef.Client), Transliterate(Upper(TrimAll(vIDCardRef.Client.FullName)), True), "") + "^" + 
					          Format(vIDCardRef.DateTimeFrom, "DF='yyMMdd'") + "^" + 
					          Format(vIDCardRef.DateTimeTo, "DF='yyMMdd'");
					vTrack1 = Left(TrimAll(vTrack1), ?(DoorLockSystemParameters.Track1Length > 0, DoorLockSystemParameters.Track1Length, 79));
					pDta = pDta + "1" + Format(StrLen(vTrack1), "ND=2; NLZ=; NG=") + vTrack1;
				Else
					// Track 2 data: CardIdentifier
					If DoorLockSystemParameters.WriteTrack2 Then
						vTrack2 = Left(TrimAll(vIDCardRef.Identifier), 35);
						pDta = pDta + vTrack2;
					EndIf;
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
	Return RC_OK;
EndFunction //  AddTrack1And2	

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pDta, pWithRetention = "", pReply)
	vErrorCode = RC_OK;
	pReply = "";
	
	vCmd = pDta; // Command data
	vCmd = vCmd + ETX;
	vCmd = STX + vCmd + cmCharLRC(vCmd);
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 3000;
	For i = 1 To 3 Do
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
			pReply = StrReplace(pReply, STX, "");
			If cmCheckCharLRC(pReply) Then
				vBytesSent = pDLSys.WriteStr(ACK);
				// Get error codes
				If StrLen(pReply) >= 14 Then
					vErrCode = Mid(pReply, 10, 2);
					If vErrCode = "00" Then
						vReadOK = True;
						// Get card id
						vTildaPos = StrFind(pReply, "~");
						If vTildaPos = 0 Then
							vTildaPos = 15;
						EndIf;
						pReply = Mid(pReply, vTildaPos + 1);
					Else
						vDetErrCode = Mid(pReply, 12, 3);
						pReply = vErrCode + "/" + vDetErrCode;
						If pReply = "03/190" Then
							Return RC_DEVICE_TIME_OUT;
						ElsIf pReply = "03/000" Then
							Return RC_NO_COMMUNICATION;
						ElsIf pReply = "03/157" Then
							Return RC_NO_COMMUNICATION;
						ElsIf pReply = "03/050" Then
							Return RC_OVERFLOW;
						EndIf;
					EndIf;
				Else
					Return RC_WRONG_REPLY;
				EndIf;
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
		pReply = "";
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pDta, pWithRetention = "", pReply)
	vErrorCode = RC_OK;
	pReply = "";
	
	vCmd = pDta; // Command data
	vCmd = vCmd + ETX;
	vCmd = STX + vCmd + cmCharLRC(vCmd);
	// Send command and get acknowledgement
	pDLSys.Timeout = 3;
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		// Read command reply message
		vReadOK = False;
		pDLSys.Timeout = pReadTimeout;
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Check LRC
				pReply = StrReplace(pReply, STX, "");
				If cmCheckCharLRC(pReply) Then
					// Get error codes
					If StrLen(pReply) >= 14 Then
						vErrCode = Mid(pReply, 10, 2);
						If vErrCode = "00" Then
							vReadOK = True;
							// Get card id
							vTildaPos = StrFind(pReply, "~");
							If vTildaPos = 0 Then
								vTildaPos = 15;
							EndIf;
							pReply = Mid(pReply, vTildaPos + 1);
						Else
							vDetErrCode = Mid(pReply, 12, 3);
							pReply = vErrCode + "/" + vDetErrCode;
							If pReply = "03/190" Then
								Return RC_DEVICE_TIME_OUT;
							ElsIf pReply = "03/000" Then
								Return RC_NO_COMMUNICATION;
							ElsIf pReply = "03/157" Then
								Return RC_NO_COMMUNICATION;
							ElsIf pReply = "03/050" Then
								Return RC_OVERFLOW;
							EndIf;
						EndIf;
					Else
						Return RC_WRONG_REPLY;
					EndIf;
				Else
					Return RC_WRONG_REPLY;
				EndIf;
			Else
				Return RC_NO_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
		If Not vReadOK Then
			vErrorCode = RC_WRONG_REPLY;
		Else
			pReply = "";
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return RC_NO_CONNECTION;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDta)
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pDta, "", vReply);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60,  pDta, "", vReply);
	EndIf;
	// Save card UID
	If vErrorCode = RC_OK Then
		If Not IsBlankString(vReply) And DoorLockSystemParameters.ReturnCardUID Then
			vReplyLen = StrLen(vReply);
			If vReplyLen > 3 Then
				vCardUID = vReply;
				IdentificationCard = cmGetClientIdentificationCard(vCardUID, cmGetClientIdentificationCardById(vCardUID), ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

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
RC_OVERFLOW = 107;
RC_MAGNETIC_TRACK_ERROR = 108;
RC_MAGNETIC_FORMAT_ERROR = 109;
RC_MAGNETIC_LEVEL_ERROR = 110;
RC_DEVICE_TIME_OUT = 111;
RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 112;
RC_WRONG_ROOM = 113;
RC_ROOM_WITHOUT_DOOR_LOCK = 114;
RC_CARD_MEMORY_OVERFLOW = 115;

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion

