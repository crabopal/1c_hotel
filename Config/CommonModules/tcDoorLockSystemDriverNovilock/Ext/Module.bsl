
#Region Public

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "") Export
	pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	
	SEP = Char(1110);
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return -1; 
	EndIf;
	
	// Build command data string
	vRoom = pParameters.Room;
	vRoomCode = TrimR(vRoom);
	If ValueIsFilled(vRoom) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		vRoom = pDevice.DefaultRoom;
		pParameters.Room = vRoom;
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return 114;
	EndIf;
	vDta = SEP + vRoomCode;
	// Additional rooms are not supported.
	vDta = vDta + SEP; // Room 2
	vDta = vDta + SEP; // Room 3
	vDta = vDta + SEP; // Room 4
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(vRoom) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(vRoom,"DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAtributeAsArray(vDoorLockSystemAuthorization);
	EndIf;	
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(pDevice) And 
		   Not IsBlankString(pDevice.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(pDevice.AssignedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(pDevice.AssignedAuthorizations);
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.DeniedAuthorizations) Then
		If ValueIsFilled(pDevice) And 
		   Not IsBlankString(pDevice.DeniedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations) + TrimAll(pDevice.DeniedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(pDevice.DeniedAuthorizations);
	EndIf;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckInDate,"DF=HHddMMyy");
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HHddMMyy");
	// Operators data
	vOperatorName = "";
	vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
	If ValueIsFilled(vEmployeePreferences) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vEmployeePreferences,"DoorLockSystemLogin")) Then
		vOperatorName = Left(Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin")), pDevice.DoGuestNamesTransliteration),20); 
	Else
		vOperatorName = Left(Transliterate(TrimAll(tcOnServer.cmGetCurrentUserAttribute()), pDevice.DoGuestNamesTransliteration), 20);
	EndIf;
	vDta = vDta + SEP + vOperatorName;
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False,pDevice,pParameters);
	If vErrorCode <> 0 Then // RC_OK = 0
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If pDevice.ReturnCardUID Then
			vDta = vDta + SEP + SEP + "1";
		EndIf;
		
		// Get encoder number
		vEncoderNumber = TrimAll(pDevice.EncoderNumber);
		
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vDta, pDevice, pParameters);
		If vErrorCode <> 0 Then // RC_OK = 0
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
		Else
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoom) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard,"CardUID")), ""), vRoom, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys,pDevice);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	
	SEP = Char(1110);
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return -1;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	vRoom = pParameters.Room;
	If ValueIsFilled(pParameters.Room) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		vRoom = pDevice.DefaultRoom;
		pParameters.Room = vRoom;
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return 114;
	EndIf;
	
	vDta = SEP + vRoomCode;
	// Additional rooms are not supported.
	vDta = vDta + SEP; // Room 2
	vDta = vDta + SEP; // Room 3
	vDta = vDta + SEP; // Room 4
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(vRoom) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(vRoom,"DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAtributeAsArray(vDoorLockSystemAuthorization);
	EndIf;	
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(pDevice) And 
		   Not IsBlankString(pDevice.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(pDevice.AssignedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(pDevice.AssignedAuthorizations);
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.DeniedAuthorizations) Then
		If ValueIsFilled(pDevice) And 
		   Not IsBlankString(pDevice.DeniedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations) + TrimAll(pDevice.DeniedAuthorizations);
		Else
			vDta = vDta + SEP + TrimAll(vDoorLockSystemAuthorization.DeniedAuthorizations);
		EndIf;
	Else
		vDta = vDta + SEP + TrimAll(pDevice.DeniedAuthorizations);
	EndIf;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckInDate,"DF=HHddMMyy");
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + Format(vCheckOutDate,"DF=HHddMMyy");
	// Operators data
	vOperatorName = "";
	vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
	If ValueIsFilled(vEmployeePreferences) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vEmployeePreferences,"DoorLockSystemLogin")) Then
		vOperatorName = Left(Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin")), pDevice.DoGuestNamesTransliteration),20); 
	Else
		vOperatorName = Left(Transliterate(TrimAll(tcOnServer.cmGetCurrentUserAttribute()), pDevice.DoGuestNamesTransliteration), 20);
	EndIf;
	vDta = vDta + SEP + vOperatorName;
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False, pDevice, pParameters);
	If vErrorCode <> 0 Then
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If pDevice.ReturnCardUID Then
			vDta = vDta + SEP + SEP + "1";
		EndIf;
		
		// Get encoder number
		vEncoderNumber = TrimAll(pDevice.EncoderNumber);
		
		// Call API
		vErrorCode = AddKey(vDLSys, vEncoderNumber, vDta, pDevice, pParameters);
		If vErrorCode <> 0 Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
		Else
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard,"CardUID")), ""), vRoom, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys, pDevice);
		Return vErrorCode;
	EndIf;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return -1;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(pDevice.EncoderNumber);
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vEncoderNumber, vCardDesc, pDevice);
	If vErrorCode <> 0 Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc, pDevice.Hotel);
		
		// Read track 2 data
		If pCardData.ReplyType <> "Message" And ValueIsFilled(pDevice) And pDevice.WriteTrack2 Then
			vTrack2 = "";
			vErrorCode = ReadTrack2(vDLSys, vEncoderNumber, vTrack2, pDevice, pDevice.SystemName);
			If vErrorCode <> 0 Then
				AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
			Else
				pCardData.CardID = tcConnectionHardwareAtClient.GetCardIdentifier(StrReplace(StrReplace(StrReplace(vTrack2, Char(13), ""), Char(1110), ""), Char(3), "")); 
				vIDCardRef = tcOnServer.cmGetCatalogItemRefByAttribute("IdentificationCards", "Identifier", false, pCardData.CardID);
				If ValueIsFilled(vIDCardRef) Then
					vClient = tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client");
					If ValueIsFilled(vClient) Then
						pCardData.CardFullName = tcOnServer.cmGetAttributeByRef(vClient, "FullName");
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vSystemName = pSystemName;
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

	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + vSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + vSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + vSystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + vSystemName + " не отвечает!'; 
		            |de = 'System " + vSystemName + "  antwortet nicht!'; 
		            |en = '" + vSystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + vSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + vSystemName + " system replied with unknown format!'; 
		            |en = '" + vSystemName + " system replied with unknown format!'"));
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
EndFunction // pmGetErrorDescription

#EndRegion

#Region Internal

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pDoGuestNamesTransliteration)	
	vStr = pStr; 
	If pDoGuestNamesTransliteration Then  
		vStr = Upper(vStr);
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
	Else
		vStr = StrReplace(vStr, "А", "&#1040;");
		vStr = StrReplace(vStr, "Б", "&#1041;");
		vStr = StrReplace(vStr, "В", "&#1042;");
		vStr = StrReplace(vStr, "Г", "&#1043;");
		vStr = StrReplace(vStr, "Д", "&#1044;");
		vStr = StrReplace(vStr, "Е", "&#1045;");
		vStr = StrReplace(vStr, "Ё", "&#1025;");
		vStr = StrReplace(vStr, "Ж", "&#1046;");
		vStr = StrReplace(vStr, "З", "&#1047;");
		vStr = StrReplace(vStr, "И", "&#1048;");
		vStr = StrReplace(vStr, "Й", "&#1049;");
		vStr = StrReplace(vStr, "К", "&#1050;");
		vStr = StrReplace(vStr, "Л", "&#1051;");
		vStr = StrReplace(vStr, "М", "&#1052;");
		vStr = StrReplace(vStr, "Н", "&#1053;");
		vStr = StrReplace(vStr, "О", "&#1054;");
		vStr = StrReplace(vStr, "П", "&#1055;");
		vStr = StrReplace(vStr, "Р", "&#1056;");
		vStr = StrReplace(vStr, "С", "&#1057;");
		vStr = StrReplace(vStr, "Т", "&#1058;");
		vStr = StrReplace(vStr, "У", "&#1059;");
		vStr = StrReplace(vStr, "Ф", "&#1060;");
		vStr = StrReplace(vStr, "Х", "&#1061;");
		vStr = StrReplace(vStr, "Ц", "&#1062;");
		vStr = StrReplace(vStr, "Ч", "&#1063;");
		vStr = StrReplace(vStr, "Ш", "&#1064;");
		vStr = StrReplace(vStr, "Щ", "&#1065;");
		vStr = StrReplace(vStr, "Ь", "&#1066;");
		vStr = StrReplace(vStr, "Ы", "&#1067;");
		vStr = StrReplace(vStr, "Ъ", "&#1068;");
		vStr = StrReplace(vStr, "Э", "&#1069;");
		vStr = StrReplace(vStr, "Ю", "&#1070;");
		vStr = StrReplace(vStr, "Я", "&#1071;"); 	
		vStr = StrReplace(vStr, "а", "&#1072;");
		vStr = StrReplace(vStr, "б", "&#1073;");
		vStr = StrReplace(vStr, "в", "&#1074;");
		vStr = StrReplace(vStr, "г", "&#1075;");
		vStr = StrReplace(vStr, "д", "&#1076;");
		vStr = StrReplace(vStr, "е", "&#1077;");
		vStr = StrReplace(vStr, "ё", "&#1105;");
		vStr = StrReplace(vStr, "ж", "&#1078;");
		vStr = StrReplace(vStr, "з", "&#1079;");
		vStr = StrReplace(vStr, "и", "&#1080;");
		vStr = StrReplace(vStr, "й", "&#1081;");
		vStr = StrReplace(vStr, "к", "&#1082;");
		vStr = StrReplace(vStr, "л", "&#1083;");
		vStr = StrReplace(vStr, "м", "&#1084;");
		vStr = StrReplace(vStr, "н", "&#1085;");
		vStr = StrReplace(vStr, "о", "&#1086;");
		vStr = StrReplace(vStr, "п", "&#1087;");
		vStr = StrReplace(vStr, "р", "&#1088;");
		vStr = StrReplace(vStr, "с", "&#1089;");
		vStr = StrReplace(vStr, "т", "&#1090;");
		vStr = StrReplace(vStr, "у", "&#1091;");
		vStr = StrReplace(vStr, "ф", "&#1092;");
		vStr = StrReplace(vStr, "х", "&#1093;");
		vStr = StrReplace(vStr, "ц", "&#1094;");
		vStr = StrReplace(vStr, "ч", "&#1095;");
		vStr = StrReplace(vStr, "ш", "&#1096;");
		vStr = StrReplace(vStr, "щ", "&#1097;");
		vStr = StrReplace(vStr, "ь", "&#1098;");
		vStr = StrReplace(vStr, "ы", "&#1099;");
		vStr = StrReplace(vStr, "ъ", "&#1100;");
		vStr = StrReplace(vStr, "э", "&#1101;");
		vStr = StrReplace(vStr, "ю", "&#1102;");
		vStr = StrReplace(vStr, "я", "&#1103;");
	EndIf;
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function ConvertUUIDToDecimal(Val pCardUID, pBytesToConvert) 
	vCardUID = pCardUID; 
	If pBytesToConvert = PredefinedValue("Enum.BytesToConvert.Byte5") Then
		While StrLen(vCardUID) < 4 Do
			vCardUID = vCardUID + "0"	
		EndDo;
		vHex = Left(vCardUID, 4);
		vBinaryDataBuffer = GetBinaryDataBufferFromHexString(vHex);
		vCardUID = Format(vBinaryDataBuffer.ReadInt16(0, ByteOrder.LittleEndian), "NFD=0; NZ=0; NG=");
	ElsIf pBytesToConvert = PredefinedValue("Enum.BytesToConvert.Byte8") Then
		While StrLen(vCardUID) < 6 Do
			vCardUID = vCardUID + "0"	
		EndDo;	
		vHex = Left(vCardUID, 6) + "00";
		vBinaryDataBuffer = GetBinaryDataBufferFromHexString(vHex);
		vCardUID = Format(vBinaryDataBuffer.ReadInt16(2, ByteOrder.LittleEndian), "NFD=0; NZ=0; NG=") + Format(vBinaryDataBuffer.ReadInt16(0, ByteOrder.LittleEndian), "NFD=0; NZ=0; NG=");
	Else
		vCardUID = NumberFromHexString("0x" + vCardUID);
	EndIf;
	Return vCardUID;
EndFunction // ConvertUUIDToDecimal

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;

	// Fill system name
	vSystemName = pDevice.SystemName;
		
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
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
			AddError(NStr("en = 'SocketTools.SocketWrench component initialization error: '; ru = 'Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: '; de = 'Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
			Return Undefined;
		EndIf;     
		vDLSys.Blocking = True;
		vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
		vErrorCode = vDLSys.Connect(TrimAll(pDevice.ServerName), Number(TrimAll(pDevice.Port)));
		If vErrorCode <> 0 Then
			AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; 
			              |de = '" + vSystemName + " system server was not found: '; 
			              |en = '" + vSystemName + " system server was not found: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
			Return Undefined;
		EndIf;     
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice)
	vSystemName = pDevice.SystemName;
	Try
		vErrorCode = pDLSys.Disconnect();
		If vErrorCode <> 0 Then
			AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + vSystemName + ": '; 
			              |de = '" + vSystemName + " server disconnect error: '; 
			              |en = '" + vSystemName + " server disconnect error: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
			Return;
		EndIf;  
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + vSystemName + ": '; 
		              |de = '" + vSystemName + " system disconnect error: '; 
		              |en = '" + vSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
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
	
	vErrorCode = RC_UNKNOWN;
	If pRC = "ES" Then
		vErrorCode = RC_SYNTAX_ERROR;
	ElsIf pRC = "NC" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "NF" Then
		vErrorCode = RC_CARD_MEMORY_OVERFLOW;
	ElsIf pRC = "OV" Then
		vErrorCode = RC_OVERFLOW;
	ElsIf pRC = "EP" Then
		vErrorCode = RC_MAGNETIC_TRACK_ERROR;
	ElsIf pRC = "EF" Then
		vErrorCode = RC_MAGNETIC_FORMAT_ERROR;
	ElsIf pRC = "EN" Then
		vErrorCode = RC_MAGNETIC_LEVEL_ERROR;
	ElsIf pRC = "TD" Then
		vErrorCode = RC_WRONG_ROOM;
	ElsIf pRC = "ED" Then
		vErrorCode = RC_DEVICE_TIME_OUT;
	ElsIf pRC = "EA" Then
		vErrorCode = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN;
	ElsIf pRC = "OS" Then
		vErrorCode = RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	Return vErrorCode;
EndFunction // GetErrorCode

// -----------------------------------------------------------------------------
Function AddTrack1And2(pDLSys, pDta, pAdd = False, pDevice, pParameters)
	SEP = Char(1110);
	If pDevice.WriteTrack1 Or pDevice.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pAdd);
			vIDCardArr = tcOnServer.cmGetAtributeAsArray(vIDCardRef);
			If ValueIsFilled(vIDCardRef) Then
				pParameters.IdentificationCard = vIDCardRef;
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If pDevice.WriteTrack1 Then
					vTrack1 = ?(ValueIsFilled(vIDCardArr.Client), Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Client, "FullName")), pDevice.DoGuestNamesTransliteration), "");
					pDta = pDta + SEP + Left(vTrack1, ?(pDevice.Track1Length > 0, pDevice.Track1Length, StrLen(vTrack1)));
				Else
					pDta = pDta + SEP;
				EndIf;
				// Track 2 data: CardIdentifier
				If pDevice.WriteTrack2 Then
					vTrack2 = TrimAll(vIDCardArr.Identifier);
					pDta = pDta + SEP + Left(vTrack2, 14);
				Else
					pDta = pDta + SEP;
				EndIf;
			Else
				vErrorCode = 102;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
				pmDisconnect(pDLSys, pDevice);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = 101;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
			pmDisconnect(pDLSys, pDevice);
			Return vErrorCode;
		EndIf;
	Else
		pDta = pDta + SEP + SEP;
	EndIf;
	Return 0;
EndFunction // AddTrack1And2	

// -----------------------------------------------------------------------------
Function TCPAcknowledgement(pDLSys)
	ENQ = Char(5);
	ACK = Char(6);
	NAK = Char(21);
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.Write(ENQ, 1);
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 3;
		vReply = "";    
		For i = 1 To 2 Do
			If pDLSys.Read(vReply, 1) <> -1 Then			
				If vReply = ACK Then
					Return True;
				ElsIf vReply = NAK And i = 2 Then
					AddError(NStr("en = 'NAK received on acknowledgement!'; ru = 'При подтверждении связи получен NAK!'; de = 'Bei der Bestätigung der Verbindung NAK erhalten!'"));
				ElsIf vReply <> NAK Then
					AddError(NStr("en = 'Wrong reply received on acknowledgement: '; ru = 'При подтверждении связи получен символ: '; de = 'Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
				EndIf;
			Else
				AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Break;
			EndIf;		
		EndDo;
	Else
		AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction // TCPAcknowledgement

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pCommandCode, pDta, pWithRetention = "", pReply, pSystemName)
	SEP = Char(1110); // It will be converted from Char(1110) in UTF-8 to Char(179) in CP-437 (Win-1251, etc...)
	ENQ = Char(5);
	ACK = Char(6);
	NAK = Char(21);
	STX = Char(2);
	ETX = Char(3);
	DLE = Char(16);
	RC_NO_REPLY = 103;
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_UNKNOWN = 100;
	RC_SYNTAX_ERROR = 105;
	RC_WRONG_REPLY = 104;
	
	vErrorCode = RC_OK;

	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	// Build command string for the TCP interface
	vCmd = SEP + pCommandCode; // Command code
	vCmd = vCmd + SEP + vEncoderNumber; // Destination address
	If pCommandCode <> "CO" And pCommandCode <> "CP" Then
		If pWithRetention <> "NO_CARD_EJECTION" Then
			vCmd = vCmd + SEP + "E"; // With ejection of the card
		Else
			vCmd = vCmd + SEP + "R"; // With retention of the card
		EndIf;
	EndIf;
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + SEP + ETX;
	vCmd = STX + vCmd + CharLRC(vCmd);
	// Send command and get acknowledgement
	pDLSys.Timeout = 3;
	For i = 1 To 3 Do
		// Send acknowledgement
		If Not TCPAcknowledgement(pDLSys) Then
			Return RC_NO_REPLY;
		EndIf;
		
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = ""; 
			For j = 1 To 2 Do
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
			EndDo;
			If vReply = ACK Then
				Break;	
			EndIf;
		Else
			AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	
	pReply = ""; 
	pDLSys.Timeout = pReadTimeout;
	If Not pDLSys.Read(pReply, 1024) <> -1 Then
		AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return RC_NO_CONNECTION;
	Else   
		If IsBlankString(pReply) Then
			Return RC_NO_REPLY;	
		EndIf;  
		
		pReply = StrReplace(pReply, STX, "");
		
		// Retreive return code
		vRC = Mid(pReply, 2, 2);
		If vRC <> Left(pCommandCode, 2) Then
			vErrorCode = GetErrorCode(vRC);
			AddError(NStr("ru = 'Ошибка системы эл. замков " + pSystemName + ": '; 
			              |de = '" + pSystemName + " system error: '; 
			              |en = '" + pSystemName + " system error: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pSystemName));
		Else
			// Retreive reply data
			vPrefixLen = StrLen(SEP + pCommandCode + SEP + vEncoderNumber);
			If StrLen(pReply) > vPrefixLen Then
				pReply = Mid(pReply, vPrefixLen+1, StrLen(pReply) - vPrefixLen);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pDta, pDevice, pParameters)
	// Define command code
	vCommandCode = "CN";
	vNumberOfKeys = pParameters.NumberOfKeys;
	If vNumberOfKeys > 1 Then
		vCommandCode = vCommandCode + Format(vNumberOfKeys, "ND=1; NFD=0; NG=");
	EndIf;	
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply, pDevice.SystemName);
	// Save card UID
	If Not IsBlankString(vReply) And pDevice.ReturnCardUID Then
		vReplyLen = StrLen(vReply);
		If vReplyLen > 3 Then
			vCardUID = Mid(vReply, 2, (vReplyLen - 4));
			If pDevice.ConvertUUIDToDecimal Then
				vCardUID = ConvertUUIDToDecimal(vCardUID, pDevice.BytesToConvert); 		
			EndIf;
			If ValueIsFilled(pParameters.IdentificationCard) Then
				tcOnServer.cmWriteAttributeCatalogByRef(pParameters.IdentificationCard, New Structure("CardUID", vCardUID));
			Else
				pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pEncoderNumber, pDta, pDevice, pParameters)
	// Define command code
	vCommandCode = "CC";
	vNumberOfKeys = pParameters.NumberOfKeys;
	If vNumberOfKeys > 1 Then
		vCommandCode = vCommandCode + Format(vNumberOfKeys, "ND=1; NFD=0; NG=");
	EndIf;	
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply, pDevice.SystemName);
	// Save card UID
	If Not IsBlankString(vReply) And pDevice.ReturnCardUID Then
		vReplyLen = StrLen(vReply);
		If vReplyLen > 3 Then
			vCardUID = Mid(vReply, 2, (vReplyLen - 4));
			If pDevice.ConvertUUIDToDecimal Then
				vCardUID = ConvertUUIDToDecimal(vCardUID, pDevice.BytesToConvert); 		
			EndIf;
			If ValueIsFilled(pParameters.IdentificationCard) Then
				tcOnServer.cmWriteAttributeCatalogByRef(pParameters.IdentificationCard, New Structure("CardUID", vCardUID));
			Else
				pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pCardDesc, pDevice)
	pCardDesc = "";
	vReply = "";
	// Retention or ejection of the card
	vRetention = "";
	If ValueIsFilled(pDevice) And 
	  (pDevice.WriteTrack2 Or pDevice.WriteTrack1) Then
		vRetention = "NO_CARD_EJECTION";
	EndIf;
	// Define command
	vCommandCode = "LT";
	// Send command using TCP interface
	vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, "", vRetention, vReply, pDevice.SystemName);
	// Retrieve card data
	If vErrorCode = 0 Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc, pHotel)
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
	
	// Get reply type
	vReplyType = Mid(pCardDesc, 2, 2);
	If vReplyType = "LD" Then
		vCardData.ReplyType = "Message";
		vCardData.ReplyDescription = NStr("en='Unidentified card!';ru='Карта не опознана!';de='Die Karte wurde nicht erkannt!'");
	ElsIf vReplyType = "LC" Then
		vCardData.ReplyType = "Message";
		vCardData.ReplyDescription = NStr("en='Guest card NOT valid!';ru='Карта не действует!';de='Die Karte funktioniert nicht!'");
	ElsIf vReplyType = "LM" Then
		vCardData.ReplyType = "Message";
		vCardData.ReplyDescription = NStr("en='Master card or special card!';ru='Мастер-карта или другая специальная карта!';de='Leitkarte und eine andere Spezialkarte!'");
	ElsIf vReplyType = "LR" Then
		vCardData.ReplyType = "Message";
		vCardData.ReplyDescription = NStr("en='Spare card for guests!';ru='Запасная гостевая карта!';de='Ersatzkarte des Gastes!'");
	ElsIf vReplyType = "LS" Then
		vCardData.ReplyType = "Message";
		vCardData.ReplyDescription = NStr("en='Diagnostic card!';ru='Диагностическая карта!';de='Diagnosekarte!'");
	Else
		// Read card data
		pCardDesc = Right(pCardDesc, StrLen(pCardDesc) - 1);
		// Card parameters
		vWord = GetNextWord(pCardDesc);
		vCardData.CardRoom = vWord;
		vWord = GetNextWord(pCardDesc);
		vCardData.CardRoom2 = vWord;
		vWord = GetNextWord(pCardDesc);
		vCardData.CardRoom3 = vWord;
		vWord = GetNextWord(pCardDesc);
		vCardData.CardRoom4 = vWord;
		vWord = GetNextWord(pCardDesc);
		vCardData.IsCardValidCode = vWord;
		If vWord = "CI" Then
			vCardData.IsCardValidDescription = NStr("en='Card is valid!';ru='Действующая карта!';de='Gültige Karte!'");
		ElsIf vWord = "CO" Then
			vCardData.IsCardValidDescription = NStr("en='Card has been canceled by check out or other card!';ru='Гость выехал или карта отменена другой картой!';de='Der Gast ist abgereist oder die Karte wurde durch eine andere ersetzt!'");
		EndIf;
		vWord = GetNextWord(pCardDesc);
		vCardData.CardCopyNumber = vWord;
		If vWord > "0" Then
			vCardData.IsCardValidDescription = vCardData.IsCardValidDescription + Chars.LF + 
			                                   NStr("en='Copy N';ru='Копия №';de='Kopie Nr.'") + 
			                                   vWord;
		EndIf;
		vWord = GetNextWord(pCardDesc);
		vCardData.AssignedAuthorizations = vWord;
		// Try to retrieve card authorizations
		vAuthRef = tcOnServer.qmFindAuthorizations(pHotel, vCardData.AssignedAuthorizations);
		If ValueIsFilled(vAuthRef) Then 
			vCardData.CardAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Code")) + " - " + TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Description"));
		EndIf;
		vWord = GetNextWord(pCardDesc);
 		vCardData.CardCheckInDate = GetDate(vWord);
		vWord = GetNextWord(pCardDesc);
		vCardData.CardCheckOutDate = GetDate(vWord);
		vWord = GetNextWord(pCardDesc);
		vCardData.CardOperator = vWord;
	EndIf;
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	SEP = Char(1110);
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
Function CharLRC(pStr, pRet13 = True) Export
	If pRet13 Then
		Return Char(13);
	Else
		vBinaryDataBuffer = GetBinaryDataBufferFromString(pStr);
		vSeedBinaryDataBuffer = New BinaryDataBuffer(1);
		For i = 0 To vBinaryDataBuffer.Size - 1 Do
			vSeedBinaryDataBuffer.WriteBitwiseXor(0, vBinaryDataBuffer.Read(i, 1), 1);	
		EndDo;
		Return Char(vSeedBinaryDataBuffer[0]); 
	EndIf;
EndFunction // CharLRC

// -----------------------------------------------------------------------------
Function ReadTrack2(pDLSys, pEncoderNumber, pTrack2, pDevice, pSystemName)
	pTrack2 = "";
	vReply = "";
	// Send command using TCP interface
	vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, "L2", "", "", vReply, pSystemName);
	// Retrieve card data
	If vErrorCode = 0 Then
		pTrack2 = vReply;
	EndIf;
	Return vErrorCode;
EndFunction // ReadTrack2

// -----------------------------------------------------------------------------
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			If StrLen(pDateStr) > 8 Then
				vHour = Left(pDateStr, 2);
				vMinute = Mid(pDateStr, 3, 2);
				vDay = Mid(pDateStr, 5, 2);
				vMonth = Mid(pDateStr, 7, 2);
				vYear = "20" + Mid(pDateStr, 9, 2);
			Else
				vHour = Left(pDateStr, 2);
				vMinute = "0";
				vDay = Mid(pDateStr, 3, 2);
				vMonth = Mid(pDateStr, 5, 2);
				vYear = "20" + Mid(pDateStr, 7, 2);
			EndIf;
			Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinute), 0);
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction // GetDate

#EndRegion

