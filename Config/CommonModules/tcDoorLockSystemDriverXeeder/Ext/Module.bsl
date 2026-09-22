
#Region Public 

// -----------------------------------------------------------------------------
//  Creates new card for just Checked-In guest, record the data on it.
//
// Parameters:
//  pDevice			 - Structure - The Device used for encoding
//  pParameters		 - Structure - Parameters of the guest
//  pErrorMessage	 - String	 - Error description
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmNewKey(pDevice, pParameters, pErrorMessage, pIsAdditionalKey = False) Export
	vRoom = pParameters.Rooom;
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return -1;
	EndIf;
	
	// Build command data string starting from room codes
	vRoomCode = TrimR(vRoom);
	vDoorLockSystemParameters = pDevice.Ref;
	
	If ValueIsFilled(vRoom) Then
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "UseRoomLockCodes") Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = Left(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"), 47);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom")) Then
		vRoom = tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom");
		vRoomCode = TrimR(vRoom);
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "UseRoomLockCodes") Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = Left(TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")), 47);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return 114;
	EndIf;
	vDta = Char(124) + "R" + vRoomCode;
	
	// Add card type
	vDta = vDta + Char(124) + "T" + TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "KeyCardType"));
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + Char(124) + "D" + Format(vCheckInDate, "DF=yyyyMMddHHmm");
	vDta = vDta + Char(124) + "O" + Format(vCheckOutDate, "DF=yyyyMMddHHmm");
	
	// Add guest name
	vGuestName = "";
	If ValueIsFilled(pParameters.Guest) Then
		vGuestName = Left(Transliterate(TrimAll(pParameters.Guest.FullName), True, pDevice), 50);
		vDta = vDta + Char(124) + "N" + vGuestName;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(vRoom) Then
		vDoorLockSystemAuthorization = vRoom.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
		Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If Not IsBlankString(pDevice.AssignedAuthorizations) And vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + Char(124) + "C" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(pDevice.AssignedAuthorizations);
		Else
			vDta = vDta + Char(124) + "C" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		If Not IsBlankString(pDevice.AssignedAuthorizations) Then
			vDta = vDta + Char(124) + "C" + TrimAll(pDevice.AssignedAuthorizations);
		EndIf;
	EndIf;
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys, vDta, pIsAdditionalKey, pDevice, pParameters);
	If vErrorCode = 0 Then
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoom) + ", " + Format(vCheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent(?(pIsAdditionalKey, "ADD", "NEW"), "", vRoom, vDta, vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest);
	EndIf;
	
	// Disconnect from door lock system
	pmDisconnect(vDLSys, pDevice);
	Return vErrorCode;
EndFunction

// -----------------------------------------------------------------------------
//  Adds new card for the exitsting room, record the data on it. Does not create new card.
//
// Parameters:
//  pDevice			 - Structure - The Device used for encoding
//  pParameters		 - Structure - Parameters of the guest
//  pErrorMessage	 - String	 - Error description
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmAddKey(pDevice, pParameters, pErrorMessage) Export
	Return pmNewKey(pDevice, pParameters, pErrorMessage, True);
EndFunction

// -----------------------------------------------------------------------------
//  Read the card data
//
// Parameters:
//  pCardData	 - Structure - Ref Object. Structure which recieves the data for this card
//  pDevice		 - Structure - The Device used for encoding
//  pParameters	 - Structure - Parameters of the guest
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmVerify(pCardData, pDevice, pParameters) Export
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return -1;
	EndIf;
	
	vDta = "";
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vDta, vCardDesc, pDevice);
	If vErrorCode = 0 Then
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice);
	
	Return vErrorCode;	
EndFunction

// --------------------------------------------------------------------------------
//  CheckOut the guest, binded to this card
//
// Parameters:
//  pDevice	 - Structure - The Device used for Encoding
// 
// Returns:
//  Number - ErrorCode of operation, 0 is for OK
//
Function pmCancel(pDevice, pParameters) Export
	
	Return 0;		
EndFunction

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRC			 - String -	 code of existing error 
//  pSystemName	 - String -	 Door Lock system name 
// 
// Returns:
//   String - Description of the recieved error 
//
Function pmGetErrorDescription(pRC, pDevice) Export
	vRC = GetErrorList();
	If pRC = vRC["RC_NO_CONNECTION"] Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pDevice.SystemName + "!';en = 'Failed to connect to the door locks system " + pDevice.SystemName + "!';de = 'Failed to connect to the door locks system " + pDevice.SystemName + "!'")); 
	ElsIf pRC = vRC["RC_UNKNOWN"] Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = vRC["RC_DEVICE_TIME_OUT"] Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = vRC["RC_WRONG_ROOM"] Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = vRC["RC_NO_REPLY"] Then
		Return(NStr("ru = 'Система " + pDevice.SystemName + " не отвечает!'; 
		|en = '" + pDevice.SystemName + " system is not responding!';
		|de = '" + pDevice.SystemName + " system is not responding!'"));
	ElsIf pRC = vRC["RC_WRONG_REPLY"] Then
		Return(NStr("ru = 'От системы " + pDevice.SystemName + " получен ответ в неизвестном формате!'; 
		|en = '" + pDevice.SystemName + " system replied with unknown format!';
		|de = '" + pDevice.SystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRC["RC_ROOM_WITHOUT_DOOR_LOCK"] Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRC["RC_NO_FOLIO"] Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRC["RC_NO_ID_CARD"] Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = vRC["RC_SYNTAX_ERROR"] Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = vRC["RC_NO_COMMUNICATION"] Then
		Return(NStr("en='The encoder does not answer (failure in the communications or switched off)!';ru='Энкодер не отвечает (возможно выключен или не подключен)!';de='Encoder antwortet nicht (ist möglicherweise abgeschaltet oder nicht eingeschaltet)!'"));
	ElsIf pRC = vRC["RC_CARD_FORMAT_ERROR"] Then              
		Return(NStr("en='Card inserted wrongly, card is broken or from another system!';ru='Не правильно вставлена карта, карта не читается или карта от другой системы!';de='Die Karte ist falsche eingesetzt, kann nicht gelesen werden oder stammt aus einem anderen System!'"));
	ElsIf pRC = vRC["RC_GENERAL_READ_WRITE_ERROR"] Then
		Return(NStr("en='General Read/Write error. The reading/writing operation failed!';ru='Ошибка чтения/записи карты. Прочитать/записать данные с карты не удалось!';de='Fehler beim Lesen / Schreiben der Karte. Die Daten konnten nicht von der Karte gelesen / auf die Karte geschrieben werden!'"));
	ElsIf pRC = vRC["RC_NO_CARD"] Then
		Return(NStr("en='No card!';ru='Нет карты!';de='Keine Karte!'"));
	ElsIf pRC = vRC["RC_CARD_NOT_EMPTY"] Then
		Return(NStr("en='Card is not empty, revoke it firstly!';ru='Карта уже записана! Удалите данные с карты.';de='Die Karte ist bereits beschrieben! Löschen Sie die Daten auf der Karte'"));
	ElsIf pRC = vRC["RC_EMPTY_CARD"] Then
		Return(NStr("en='Card is empty!';ru='Пустая карта!';de='Leere Karte!'"));
	ElsIf pRC = vRC["RC_CARD_COUNT_OVER_LIMIT"] Then
		Return(NStr("ru = 'Card count over limit!'; 
		|en = 'Card count over limit!';
		|en = 'Card count over limit!'"));
	EndIf;		
EndFunction

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetField(pFieldCode, pCardData)
	vFieldData = "";
	vCardData = TrimAll(pCardData);
	vPos = Find(vCardData, Char(124) + pFieldCode);
	If vPos > 0 Then
		vCardData = Mid(vCardData, vPos + 2);
		vSEPPos = Find(vCardData, Char(124));
		If vSEPPos > 0 Then
			vFieldData = Left(vCardData, vSEPPos - 1);
		Else
			If Right(vCardData, 1) = Char(3) Then
				vFieldData = Left(vCardData, StrLen(vCardData) - 1);
			Else
				vFieldData = TrimAll(vCardData);
			EndIf;
		EndIf;
	EndIf;
	Return vFieldData;
EndFunction //  GetField

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False, pDevice)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If pDevice.DoGuestNamesTransliteration Or pAlways Then
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
Function pmConnect(pDevice)
	// Fill system name
	SystemName = "Xeeder";
	
	Try
		If Not ValueIsFilled(pDevice) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(pDevice.ConnectionType) And
			pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
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
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;     
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDLSys		 - 	 - 
//  pDta		 - 	 card data 
//  pAdd		 - 	 Boolean responsible for the type of operation: add key or new key 
//  pParameters	 - 	 Door lock system integration parameters structure 
//  pDevice		 - 	 external door lock system encoder device 
// 
// Returns:
//   Error code of the commited operation 
//
Function AddTrack2(pDLSys, pDta, pAdd = False, pParameters, pDevice)
	// Add/get client identification card
	If ValueIsFilled(pParameters.Folio) Then
		vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.pAdd);
		If ValueIsFilled(vIDCardRef) Then
			// Track 2 data: CardIdentifier
			If pDevice.WriteTrack2 Then
				vTrack2 = TrimAll(vIDCardRef.Identifier);
				pDta = pDta + Char(124) + "S2" + Char(124) + "H" + Left(vTrack2, 14);
			Else
				pDta = pDta + Char(124) + "S2" + Char(124) + "H";
			EndIf;
		Else
			vErrorCode = 102;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys, pDevice);
			Return vErrorCode;
		EndIf;
	Else
		vErrorCode = 101;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		pmDisconnect(pDLSys, pDevice);
		Return vErrorCode;
	EndIf;
	Return 0;
EndFunction //  AddTrack2

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDta, pIsAdditionalKey = False, pDevice, pParameters)
	vErrorCode = 0;
	
	// Erase card first
	If Not pIsAdditionalKey Then
		vCommandCode = "0B";
		If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
			vDta = "";
			vReply = "";
			vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply, pDevice);
		EndIf;
		If vErrorCode <> 0 Then
			Return vErrorCode;
		EndIf;
	EndIf;
	
	// Check-in guest
	vCommandCode = "0I";
	If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, pDta, vReply, pDevice);
	EndIf;
	If vErrorCode <> 0 Then
		Return vErrorCode;
	EndIf;
	
	// Write track 2 if neccessary
	If pDevice.WriteTrack2 Then
		vCommandCode = "0W";
		vDta = "";
		vErrorCode = AddTrack2(pDLSys, vDta, False, pParameters, pDevice);
		If vErrorCode <> 0 Then
			Return vErrorCode;
		EndIf;
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply, pDevice);
	EndIf;
	If vErrorCode <> 0 Then
		Return vErrorCode;
	EndIf;
	
	// Read card UID if neccessary
	If pDevice.ReturnCardUID Then
		// Fill identification card
		IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, False);
			If ValueIsFilled(vIDCardRef) Then
				IdentificationCard = vIDCardRef;
			EndIf;
		EndIf;
		
		// Read card data
		vCommandCode = "0E";
		vDta = "";
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, vDta, vReply, pDevice);
		If vErrorCode <> 0 Then
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
Function GetErrorCode(pRC)
	vErrorCode = 100;
	If pRC = "08" Then
		vErrorCode = 105;
	ElsIf pRC = "00" Then
		vErrorCode = 0;	
	ElsIf pRC = "09" Then
		vErrorCode = 105;
	ElsIf pRC = "01" Then
		vErrorCode = 115;
	ElsIf pRC = "12" Then
		vErrorCode = 106;
	ElsIf pRC = "03" Then
		vErrorCode = 108;
	ElsIf pRC = "04" Then
		vErrorCode = 108;
	ElsIf pRC = "23" Then
		vErrorCode = 108;
	ElsIf pRC = "05" Then
		vErrorCode = 109;
	ElsIf pRC = "14" Then
		vErrorCode = 109;
	ElsIf pRC = "15" Then
		vErrorCode = 109;
	ElsIf pRC = "18" Then
		vErrorCode = 113;
	ElsIf pRC = "19" Then
		vErrorCode = 113;
	ElsIf pRC = "02" Then
		vErrorCode = 111;
	ElsIf pRC = "06" Then
		vErrorCode = 111;
	ElsIf pRC = "11" Then
		vErrorCode = 111;
	ElsIf pRC = "13" Then
		vErrorCode = 116;
	ElsIf pRC = "17" Then
		vErrorCode = 117;
	ElsIf pRC = "20" Then
		vErrorCode = 118;
	EndIf;
	Return vErrorCode;
EndFunction

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pCommandCode, pDta, pReply, pDevice)
	vErrorCode = 0;
	pReply = "";
	// Build command string for the TCP interface
	vCmd = Char(2);
	// Add encoder number
	vCmd = vCmd + TrimAll(pDevice.EncoderNumber);
	// Add source id
	vCmd = vCmd + TrimAll(pDevice.PCId);
	// Save command prefix
	vCommandPrefix = vCmd;
	vPrefixLen = StrLen(vCommandPrefix);
	// Add command code
	vCmd = vCmd + pCommandCode; // Command code
	// Add command data
	vCmd = vCmd + pDta; // Command data
	// Add end of transmission field
	vCmd = vCmd + Char(3);
	// Send command and get acknowledgement
	pReply = "";
	pDLSys.Timeout = 3;
	vFRes = pDLSys.Flush();
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Left(pReply, vPrefixLen) <> vCommandPrefix Then
				Return 104;
			EndIf;
		Else
			AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return -1;
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls:'") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return -1;
	EndIf;
	// Retreive return code
	vRC = Mid(pReply, vPrefixLen + 1, 2);
	vErrorCode = GetErrorCode(vRC);
	If vErrorCode = 0 Then
		// Retreive reply data
		If StrLen(pReply) > (vPrefixLen + 3) Then
			pReply = Mid(pReply, vPrefixLen + 4, StrLen(pReply) - (vPrefixLen + 4));
		Else
			pReply = "";
		EndIf;
	Else
		AddError(NStr("en='Command execution error: ';ru='Ошибка выполнения команды: ';de='Fehler bei der Befehlausführung: '") + vRC + " - " + pmGetErrorDescription(vErrorCode, pDevice) + Chars.LF + NStr("en='System reply is: ';ru='Ответ системы: ';de='Antwort des Systems: '") + pReply);
	EndIf;
	Return vErrorCode;
EndFunction //  

// --------------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , pErrorText);
EndProcedure //  AddError

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

// --------------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice)
	Try
		If ValueIsFilled(pDevice.ConnectionType) And
			pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " +  pDevice.SystemName + ": '; en = '" +  pDevice.SystemName + " server disconnect error: '; de = '" +  pDevice.SystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " +  pDevice.SystemName + ": '; en = '" +  pDevice.SystemName + " system disconnect error: '; en = '" +  pDevice.SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_UNKNOWN", 100);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_NO_ID_CARD", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_SYNTAX_ERROR", 105);
	vErrorList.Insert("RC_NO_COMMUNICATION", 106);
	vErrorList.Insert("RC_COMMAND_NOT_APPLICABLE", 107);
	vErrorList.Insert("RC_CARD_FORMAT_ERROR", 108);
	vErrorList.Insert("RC_GENERAL_READ_ERROR", 109);
	vErrorList.Insert("RC_GENERAL_ENCODING_ERROR", 110);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 111);
	vErrorList.Insert("RC_NO_GUEST_PREVIOUSLY_CHECKED_IN", 112);
	vErrorList.Insert("RC_WRONG_ROOM", 113);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", 114);
	vErrorList.Insert("RC_ONLY_ONE_ACTIVE_CARD_ALLOWED", 95);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDta, pCardDesc, pDevice)
	// Read card data
	vCommandCode = "0E";
	pCardDesc = "";
	If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		vErrorCode = CallTCPCommand(pDLSys, 60, vCommandCode, pDta, pCardDesc, pDevice);
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion  