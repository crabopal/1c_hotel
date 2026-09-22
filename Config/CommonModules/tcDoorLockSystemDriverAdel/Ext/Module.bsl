
#Region Public

// -----------------------------------------------------------------------------
Function pmConnect(pDevice) Export
	SEP = Char(124);
	If Not TypeOf(pDevice) = Type("Structure") Then
		Return Undefined;
	EndIf;
	
	vDLSys = Undefined;		
	#IF NOT MobileClient THEN
		Try
			// Build ActiveX object to work with
			Try
			    vDLSys = New COMObject("SocketTools.SocketWrench.10");
				// Load license
				vErrorCode = vDLSys.Initialize(tcDoorLocksAtServer.GetCSWSOCK10LicenseKey());
			Except
				vDLSys = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = vDLSys.Initialize(tcDoorLocksAtServer.GetCSWSOCK6LicenseKey());
			EndTry;
			
			If vErrorCode <> 0 Then
				AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			
			vDLSys.Blocking = True;
			vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(pDevice.ServerName), Number(TrimAll(pDevice.Port)));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system server was not found: '; de = '" + pDevice.SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " door lock system connection error: '; de = '" + pDevice.SystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice) Export
	Try
		vErrorCode = pDLSys.Disconnect();
		If vErrorCode <> 0 Then
			AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " server disconnect error: '; de = '" + pDevice.SystemName + " server disconnect error: '") + vErrorCode);
			Return;
		EndIf;  
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system disconnect error: '; de = '" + pDevice.SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "") Export
	SEP = Char(124);
	STX = Char(2);
	ETX = Char(3);
	
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = "";
	If ValueIsFilled(pParameters.Room) Then
		vRoom = tcOnServer.cmGetAtributeAsArray(pParameters.Room);
		vRoomCode = TrimR(vRoom.Description);
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoom.LockCode) Then
				vRoomCode = Left(TrimR(vRoom.LockCode), 18);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		pParameters.Room = pDevice.DefaultRoom;
		vRoom = tcOnServer.cmGetAtributeAsArray(pParameters.Room);
		vRoomCode = TrimR(vRoom.Description);
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoom.LockCode) Then
				vRoomCode = Left(TrimR(vRoom.LockCode), 18);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK; 
	EndIf;
	
	// PMS: <STX>0103I<RS>R101<RS>NDuck<RS>D200212201200<RS>O200212302100<EXT>
	// <STX>ddssff[data]<ETX>
	// collect now [data] string
	vDta = SEP + "R" + vRoomCode;
	// Card type (authorizations)
	// Guest
	If ValueIsFilled(pParameters.Guest) Then
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName")));
	Else
		vDta = vDta + SEP + "N";		
	EndIf;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	vSourceAddress = "";
	If Not IsBlankString(pDevice.PCId) Then
		vSourceAddress = TrimAll(pDevice.PCId);
	EndIf;
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys, pDevice, vSourceAddress, vDta);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", "", pParameters.Room, vDta, vCheckInDate, vCheckOutDate, pParameters.FolioNumber, pParameters.Guest);
	EndIf;
	
	pmDisconnect(vDLSys, pDevice);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	SEP = Char(124);
	
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = "";
	If ValueIsFilled(pParameters.Room) Then
		vRoom = tcOnServer.cmGetAtributeAsArray(pParameters.Room);
		vRoomCode = TrimR(vRoom.Description);
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoom.LockCode) Then
				vRoomCode = Left(TrimR(vRoom.LockCode), 18);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		pParameters.Room = pDevice.DefaultRoom;
		vRoom = tcOnServer.cmGetAtributeAsArray(pParameters.Room);
		vRoomCode = TrimR(vRoom.Description);
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoom.LockCode) Then
				vRoomCode = Left(TrimR(vRoom.LockCode), 18);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK; 
	EndIf;

	// collect now [data] string
	vDta = SEP + "R" + vRoomCode;
	
	// Card type (authorizations)
	
	// Guest
	If ValueIsFilled(pParameters.Guest) Then
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName")));
	Else
		vDta = vDta + SEP + "N";		
	EndIf;
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	vSourceAddress = "";
	If Not IsBlankString(pDevice.PCId) Then
		vSourceAddress = TrimAll(pDevice.PCId);
	EndIf;
	
	// Call API
	vErrorCode = AddKey(vDLSys, pDevice, vSourceAddress, vDta);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", "", pParameters.Room, vDta, vCheckInDate, vCheckOutDate, pParameters.FolioNumber, pParameters.Guest);
	EndIf;
	
	pmDisconnect(vDLSys, pDevice);
	Return vErrorCode;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc, pHotel) Export
	STX = Char(2);
	ETX = Char(3);
	
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
	
	// AIS: <STX>03010<RS>R101<RS>NDUuck<RS>D200212201200<RS>O200212302100<ETX>
	// Parse all fields
	vDataLen = StrLen(pCardDesc);
	While vDataLen > 0 Do
		vWord = GetNextWord(pCardDesc);
		vDataLen = StrLen(pCardDesc);
		FillParameter(vCardData,vWord);
	EndDo;
	
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	SEP = Char(124);
	
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(pDevice.EncoderNumber);
	vSourceAddress = "";
	If Not IsBlankString(pDevice.PCId) Then
		vSourceAddress = TrimAll(pDevice.PCId);
	EndIf;
	
	// Build command data string
	vDta = "";
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, pDevice, vSourceAddress, vDta, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc, pDevice.Hotel);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_UNKNOWN = 100;

	RC_UNCONFIRMED_ERROR = 101;
	RC_INVALID_TARGET_ERROR = 102;
	RC_INVALID_COMMAND = 103;
	RC_ROOM_OCCUPIED = 104;
	RC_NO_COMMUNICATION = 105;
	RC_WRONG_ROOM = 106;
	RC_KEYCODE_EXITS = 107;
	RC_DEVICE_TIME_OUT = 108;

	RC_NO_FOLIO = 201;
	RC_NO_ID_CARD = 202;
	RC_NO_REPLY = 203;
	RC_WRONG_REPLY = 204;
	RC_GENERAL_READ_ERROR = 209;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;

	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru='Не удалось установить соединение с системой AIS!'; 
		            |en='Failed to connect to the door locks system AIS!';
					|de='Failed to connect to the door locks system AIS!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_ROOM_OCCUPIED Then
		Return(NStr("en='The room is occupied.';ru='Номер занят.';de='Die Zimmer ist besetzt.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан не верно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru='Система AIS не отвечает!'; 
		            |en='AIS system is not responding!';
					|de='AIS system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru='От системы AIS получен ответ в неизвестном формате!'; 
		            |en='AIS system replied with unknown format!';
					|de='AIS system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_INVALID_TARGET_ERROR Then
		Return(NStr("en='Wrong (invalid) target address';ru='Неверный номер энкодера!';de='Falsche Encoder-Nummer!'"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("ru='Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |en='Error of COM, or the encoder is busy';
					|de='Error of COM, or the encoder is busy'"));
	ElsIf pRC = RC_INVALID_COMMAND Then
		Return(NStr("en='Invalid command code';ru='Ошибка кода команды!';de='Fehler des Befehlcodes!'"));
	ElsIf pRC = RC_UNCONFIRMED_ERROR Then
		Return(NStr("en='Unconfirmed error!';ru='Неподтвержденная ошибка!';de='Nicht bestätigter Fehler!'"));
	ElsIf pRC = RC_GENERAL_READ_ERROR Then
		Return(NStr("en='General Reading error. The reading operation is not successful!';ru='Ошибка чтения карты. Прочитать данные с карты не удалось!';de='Fehler beim Lesen der Karte. Die Daten konnten nicht von der Karte gelesen werden!'"));
	ElsIf pRC = RC_KEYCODE_EXITS Then
		Return(NStr("en='Key code already exits';ru='Ошибка кодирования карты. Ключ уже выписан!';de='Fehler der Kartencodierung. Der Schlüssel ist bereits ausgeschrieben!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
EndProcedure // pmInstall

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False, pDoGuestNamesTransliteration = True)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If pDoGuestNamesTransliteration Or pAlways Then
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
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_UNKNOWN = 100;

	RC_UNCONFIRMED_ERROR = 101;
	RC_INVALID_TARGET_ERROR = 102;
	RC_INVALID_COMMAND = 103;
	RC_ROOM_OCCUPIED = 104;
	RC_NO_COMMUNICATION = 105;
	RC_WRONG_ROOM = 106;
	RC_KEYCODE_EXITS = 107;
	RC_DEVICE_TIME_OUT = 108;

	RC_NO_FOLIO = 201;
	RC_NO_ID_CARD = 202;
	RC_NO_REPLY = 203;
	RC_WRONG_REPLY = 204;
	RC_GENERAL_READ_ERROR = 209;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	vErrorCode = RC_UNKNOWN;
	If pRC = "1" Then
		vErrorCode = RC_UNCONFIRMED_ERROR;
	ElsIf pRC = "2" Then
		vErrorCode = RC_INVALID_TARGET_ERROR;
	ElsIf pRC = "3" Then
		vErrorCode = RC_INVALID_COMMAND;
	ElsIf pRC = "4" Then
		vErrorCode = RC_ROOM_OCCUPIED;
	ElsIf pRC = "5" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "6" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "7" Then
		vErrorCode = RC_KEYCODE_EXITS;
	ElsIf pRC = "8" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	EndIf;
	Return vErrorCode;
EndFunction // GetErrorCode

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pDevice, pReadTimeout = 60, pSourceAddress, pCommandCode, pDta, pReply)
	SEP = Char(124);
	STX = Char(2);
	ETX = Char(3);
	
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	
	vErrorCode = RC_OK;
	
	pReply = "";
	
	// Format source address
	vSourceAddress = TrimAll(pSourceAddress);
	
	// Build command string for the TCP interface
	vCmd = STX;
	// Add source address only if it is not blank, assuming that 
	// if PC Id was not specified then Inhova PMS-Server is not used
	If Not IsBlankString(vSourceAddress) Then	
		vCmd = vCmd + vSourceAddress+"01";
	EndIf;
	vCmd = vCmd + pCommandCode; // Command code
	vPrefixLen = StrLen(vCmd); // Length of command prefix
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	
	// Send command
	pDLSys.Timeout = 30;
	vFRes = pDLSys.Flush();
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		vReply = "";
		If pDLSys.Read(vReply, 1024) <> -1 Then
			pReply = vReply;
		Else
			AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Read command reply message
	// Retreive return code
	vRC = Right(Left(pReply, vPrefixLen), 1);
	If vRC <> "0" Then
		AddError(NStr("ru = 'Ошибка системы эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system error: '; de = '" + pDevice.SystemName + " system error: '") + pReply + " <- " + vCmd);
		vErrorCode = GetErrorCode(vRC);
	Else
		// Retreive reply data
		If StrLen(pReply) > (vPrefixLen + 2) Then
			pReply = Mid(pReply, vPrefixLen + 1, StrLen(pReply) - (vPrefixLen + 2));
		Else
			pReply = "";
		EndIf;
	EndIf;
	
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDevice, pSourceAddress, pDta)
	// Define command code
	vCommandCode = "I";
	// Choose transport
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, pDevice, 60, pSourceAddress, vCommandCode, pDta, vReply);
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pDevice, pSourceAddress, pDta)
	// Define command code
	vCommandCode = "G";
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, pDevice, 60, pSourceAddress, vCommandCode, pDta, vReply);
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	SEP = Char(124);
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
EndFunction // GetNextWord

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
		pCardData.CardRoom = Right(pWord,StrLen(pWord)-1);
	ElsIf vCommand = "N" Then
		pCardData.CardFullName = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "D" Then
		pCardData.CardCheckInDate = GetDate(Right(pWord,StrLen(pWord)-1));	
	ElsIf vCommand = "O" Then
		pCardData.CardCheckOutDate = GetDate(Right(pWord,StrLen(pWord)-1));		
	EndIf;	
EndProcedure // FillParameter

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDevice, pSourceAddress, pDta, pCardDesc)
	RC_OK = 0;
	
	vErrorCode = RC_OK;
	pCardDesc = "";
	vReply = "";
	
	// Define command
	vCommandCode = "E";
	// Send command using TCP interface
	vErrorCode = CallTCPCommand(pDLSys, pDevice, 60, pSourceAddress, vCommandCode, pDta, vReply);
	
	// Retrieve card data
	If vErrorCode = RC_OK Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction // Verify

#EndRegion
