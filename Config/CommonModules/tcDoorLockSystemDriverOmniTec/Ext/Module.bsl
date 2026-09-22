
#Region Public

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage) Export
	vKeyParameters = New Structure();
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	//1.ROOM
	vKeyParameters.Insert("Room", vRoomCode);
	
	If IsBlankString(vRoomCode) Then
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization"); 
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"); 
		If Not IsBlankString(vAssignedAuthorizations) Then
			If ValueIsFilled(vDoorLockSystemParameters) And Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) Then 
				If tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
					vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations") + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
				Else
					vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations");
				EndIf;
			Else
				vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")
			EndIf;
		Else
			vAssignedAuthorizations = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
		EndIf;
	Else
		vAssignedAuthorizations = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 2.AssignedAuthorizations
	vKeyParameters.Insert("AssignedAuthorizations", vAssignedAuthorizations);
	
	// 3. Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes * 60;
	EndIf;
	vKeyParameters.Insert("CheckInDate",Format(vCheckInDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckInTime",Format(vCheckInDate,"DF=HHmm"));
	
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	vKeyParameters.Insert("CheckOutDate",Format(vCheckOutDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckOutTime",Format(vCheckOutDate,"DF=HHmm"));
	
	// 4. Operators data
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then 
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"); 
			If ValueIsFilled(vDoorLockSystemLogin) Then
				vOperatorName = Left(Transliterate(TrimAll(vDoorLockSystemLogin), True, vDoorLockSystemParameters), 20);
			Else 
				vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, vDoorLockSystemParameters), 20);	
			EndIf;
		Else
			vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, vDoorLockSystemParameters), 20);
		EndIf;
	EndIf;
	
	vKeyParameters.Insert("OperatorName",vOperatorName);
	
	// 5. Get encoder number
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	
	vKeyParameters.Insert("EncoderNumber",vEncoderNumber);
	
	// Call API
	vCardID = "";
	vErrorCode = MakeNewKey(vDLSys, "N", vKeyParameters, vDoorLockSystemParameters, pParameters, vRCList, vCharList, vCardID);
	If vErrorCode <> vRCList.RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		If vDoorLockSystemParameters.ReturnCardUID And Not IsBlankString(vCardID) Then
			pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, vCheckInDate, vCheckOutDate, True, vCardID);
		EndIf;	
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", ");
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
	EndIf;
	
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
	vKeyParameters = New Structure();
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	//1.ROOM
	vKeyParameters.Insert("Room", vRoomCode);
	
	If IsBlankString(vRoomCode) Then
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization"); 
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"); 
		If Not IsBlankString(vAssignedAuthorizations) Then
			If ValueIsFilled(vDoorLockSystemParameters) And Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) Then 
				If tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
					vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations") + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
				Else
					vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations");
				EndIf;
			Else
				vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")
			EndIf;
		Else
			vAssignedAuthorizations = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
		EndIf;
	Else
		vAssignedAuthorizations = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 2.AssignedAuthorizations
	vKeyParameters.Insert("AssignedAuthorizations", vAssignedAuthorizations);
	
	// 3. Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes * 60;
	EndIf;
	vKeyParameters.Insert("CheckInDate",Format(vCheckInDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckInTime",Format(vCheckInDate,"DF=HHmm"));
	
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	vKeyParameters.Insert("CheckOutDate",Format(vCheckOutDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckOutTime",Format(vCheckOutDate,"DF=HHmm"));
	
	// 4. Operators data
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then 
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"); 
			If ValueIsFilled(vDoorLockSystemLogin) Then
				vOperatorName = Left(Transliterate(TrimAll(vDoorLockSystemLogin), True, vDoorLockSystemParameters), 20);
			Else 
				vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, vDoorLockSystemParameters), 20);	
			EndIf;
		Else
			vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, vDoorLockSystemParameters), 20);
		EndIf;
	EndIf;
	
	vKeyParameters.Insert("OperatorName",vOperatorName);
	
	// 5. Get encoder number
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	
	vKeyParameters.Insert("EncoderNumber",vEncoderNumber);
	
	// Call API
	vCardID = "";
	vErrorCode = MakeNewKey(vDLSys, "C", vKeyParameters, vDoorLockSystemParameters, pParameters, vRCList, vCharList, vCardID);
	If vErrorCode <> vRCList.RC_OK And vErrorCode <> "99" Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		If vDoorLockSystemParameters.ReturnCardUID And Not IsBlankString(vCardID) Then
			pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, vCheckInDate, vCheckOutDate, True, vCardID);
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
	EndIf;
	
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	Return vErrorCode;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	
	// Call API
	pCardData = New Structure();
	vErrorCode = Verify(vDLSys, vEncoderNumber, pCardData, vDoorLockSystemParameters, vRCList, vCharList);
	If vErrorCode <> vRCList.RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	
	Return vErrorCode;	
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmCancel(pDevice, pParameters) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Get encoder number
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	
	// Call API
	vErrorCode = CancelKeys(vDLSys, vEncoderNumber, vRoomCode, vDoorLockSystemParameters, vRCList, vCharList);
	If vErrorCode <> vRCList.RC_OK Then
		AddError(NStr("ru = 'Ошибка отмены ранее выданных карт: '; en = 'Error cancelling keys: '; de = 'Error cancelling keys: '") + vErrorCode);
	Else
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.CancelKeyCards'; de='DoorLockSystem.CancelKeyCards'; ru='СистемаЭлектронныхЗамков.ОтменаРанееВыданныхКлючей'"), "Information", , , NStr("ru = 'Отменены ключи номера: '; en = 'Key cards canceled: '; de = 'Key cards canceled: '") + TrimAll(pParameters.Room));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("CANCEL", "", pParameters.Room, , '00010101', '00010101', pParameters.ParentDoc, pParameters.Guest, 0);	
	EndIf;	
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	Return vErrorCode;
EndFunction // pmCancel

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vRCList = GetErrorList();
	If pRC = vRCList.RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		|de = 'Failed to connect to the door locks system " + pSystemName + "!'; 
		|en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = vRCList.RC_UNKNOWN Then
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = vRCList.RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = vRCList.RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = vRCList.RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = vRCList.RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		|de = 'System " + pSystemName + "  antwortet nicht!'; 
		|en = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = vRCList.RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		|de = '" + pSystemName + " system replied with unknown format!'; 
		|en = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRCList.RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRCList.RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRCList.RC_NO_ID_CARD Then
		Return(NStr("en='Unknown client identification card!';ru='Неизвестная карта идентификации клиента!';de=''"));
	ElsIf pRC = vRCList.RC_NO_COMMUNICATION Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		|de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		|en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = vRCList.RC_WRITE_ERROR Then
		Return(NStr("ru = 'Ошибка записи!'; 
		|de = ''; 
		|en = 'Write error!'"));
	ElsIf pRC = vRCList.RC_NO_WRITE_ERROR_DEMO Then
		Return(NStr("ru = 'Все карты закодированы. Есть менее 15 дней, чтобы зарегистрировать GestHotel!'; 
		|de = ''; 
		|en = 'No error. All the cards have been read/written correctly, but you have less than 15 days to register GestHotel'"));
	ElsIf pRC = vRCList.RC_WRITE_ERROR_DEMO Then
		Return(NStr("ru = 'Ошибка записи! Есть менее 15 дней, чтобы зарегистрировать GestHotel'; 
		|de = ''; 
		|en = 'Some of the cards have not been read/written correctly, and you have less than 15 days to register GestHotel'"));	
	ElsIf pRC = vRCList.RC_DEMO_MODE_FINISH Then
		Return(NStr("ru = 'Ошибка записи! Демо режим GestHotel закончился'; 
		|de = ''; 
		|en = 'Test time of GestHotel has finished. None of the cards will be read/written.'"));	
	ElsIf pRC = vRCList.RC_ERROR_HDD_SN Then
		Return(NStr("ru = 'Ошибка записи! SN жесткого диска отличается от регистрационного'; 
		|de = ''; 
		|en = 'Hard disk serial number is not the same as stored in database. None of the cards will be read/written'"));
	ElsIf pRC = vRCList.RC_NO_ID_CARD_DEMO Then
		Return(NStr("ru = 'Неизвестная карта идентификации клиента.  Есть менее 15 дней, чтобы зарегистрировать GestHotel'; 
		|de = ''; 
		|en = 'Unknown card. You have less than 15 days to register GestHotel'"));
	ElsIf pRC = vRCList.RC_NO_CONNECTION_GESTHOTEL Then
		Return(NStr("ru = 'Ошибка подключения к базе данных GestHotel'; 
		|de = ''; 
		|en = 'Lost connection to GestHotel database'"));
	ElsIf pRC = vRCList.RC_PRESSED_CANCEL Then
		Return(NStr("ru = 'Выдача карты отменена в окне подтверждения'; 
		|de = ''; 
		|en = 'Cancel pressed when encoding card (in message window)'"));
	ElsIf pRC = vRCList.RC_NO_CONNECTION_CLIENT Then
		Return(NStr("ru = 'Потеря связи с энкодером'; 
		|de = ''; 
		|en = 'Lost connection to encoder client'"));
	ElsIf pRC = vRCList.RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверное число параметров!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = vRCList.RC_NOT_FOUND Then
		Return(NStr("en = 'Not Found'; de = 'Nicht gefunden'; ru = 'Не найдено'"));
	ElsIf pRC = vRCList.RC_UNAUTHORIZED Then
		Return(NStr("en = 'Unauthorized'; de = 'Nicht autorisiert'; ru = 'Неавторизованный'"));
	ElsIf pRC = vRCList.RC_BAD_REQUEST Then
		Return(NStr("en = 'Bad Request'; de = 'Ungültige Anforderung'; ru = 'Неверный запрос'"));
	ElsIf pRC = vRCList.RC_NO_CARD_OR_INVALID_CARD Then
		Return(NStr("en = 'No card or invalid card'; de = 'Keine oder ungültige Karte'; ru = 'Карта отсутствует или недействительна'"));
	ElsIf pRC = vRCList.RC_TIMEOUT Then
		Return(NStr("en = 'Timeout'; de = 'Time-out'; ru = 'Тайм-аут'"));	
	ElsIf pRC = vRCList.RC_UNUSABLE_CARD Then
		Return(NStr("en = 'Card UID is included in previous blacklist'; de = 'Die Karten-UID ist in der vorherigen Blacklist enthalten'; ru = 'UID карты включен в предыдущий черный список'"));
	ElsIf pRC = vRCList.RC_NO_VALID_ROOM Then
		Return(NStr("en = 'Reservation has not valid room'; de = 'Reservierung hat kein gültiges Zimmer'; ru = 'Бронирование не имеет действительного номера'"));
	ElsIf pRC = vRCList.RC_DEVICE_IS_NOT_INIT Then
		Return(NStr("en = 'Device is not initialized'; de = 'Gerät ist nicht initialisiert'; ru = 'Устройство не инициализировано'"));
	ElsIf pRC = vRCList.RC_UNKNOWN_PROTOCOL Then
		Return(NStr("en = 'Unknown protocol'; de = 'Unbekanntes Protokoll'; ru = 'Неизвестный протокол'"));
	ElsIf pRC = vRCList.RC_CANCELLED Then
		Return(NStr("en = 'The reservation or QR are cancelled'; de = 'Die Reservierung oder der QR wurden storniert'; ru = 'Бронирование или QR-код отменены.'"));
	ElsIf pRC = vRCList.RC_NOT_SUPPORTED Then
		Return(NStr("en = 'Not supported in the current version of the protocol'; de = 'Wird in der aktuellen Version des Protokolls nicht unterstützt'; ru = 'Не поддерживается в текущей версии протокола'"));
	ElsIf pRC = vRCList.RC_UNPROCESSABLE_ENTITY Then	
		Return(NStr("en = 'Unprocessable Entity'; de = 'Nicht verarbeitbare Entität'; ru = 'Необработанный объект'"));
	EndIf;
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, pDoorLockSystemParameters)
	// Fill system name
	vSystemName = String(pDevice.SystemName);
	
	vDLSys = GetPersistentObject("OmniTec");
	
	#IF NOT MobileClient THEN
		If vDLSys = Undefined Then
			Try
				If Not ValueIsFilled(pDoorLockSystemParameters) Then
					Return Undefined;
				EndIf;
				
				// Build ActiveX object to work with
				If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
					pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.OmniTecDLL") Then
					vDLSys = New COMObject("InterGH.clsPrincipal");
					If Not vDLSys = Undefined Then
						SetPersistentObject("OmniTec",vDLSys);
					EndIf;
				ElsIf pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
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
						AddError(NStr("en = 'SocketTools.SocketWrench component initialization error: '; de = 'Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '; ru = 'Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: '") + vErrorCode);
						Return Undefined;
					EndIf;     
					vDLSys.Blocking = True;
					vDLSys.Timeout = 30; // 30 seconds blocking read timeout by default
					vErrorCode = vDLSys.Connect(TrimAll(pDoorLockSystemParameters.ServerName), Number(TrimAll(pDoorLockSystemParameters.Port)));
					If vErrorCode <> 0 Then
						AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; 
						|de = '" + vSystemName + " system server was not found: '; 
						|en = '" + vSystemName + " system server was not found: '") + vErrorCode);
						Return Undefined;
					EndIf; 
				Else
					AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": ';  
					|de = '" + vSystemName + " door lock system connection error: '; 
					|en = '" + vSystemName + " door lock system connection error: '") + NStr("en = 'not connect'; ru = 'Подключение к системе выдачи ключей OmniTec возможен только по DLL или TCP/IP'; de = 'not connect'"));
					Return Undefined;
				EndIf;
			Except	
				AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; 
				|de = '" + vSystemName + " door lock system connection error: '; 
				|en = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
				Return Undefined;
			EndTry;
		EndIf;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters)
	Try
		vSystemName = String(pDevice.SystemName);
		If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
			pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.OmniTecDLL") Then
			pDLSys.Close();
		Else
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + vSystemName + ": '; 
				|de = '" + vSystemName + " server disconnect error: '; 
				|en = '" + vSystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + vSystemName + ": '; 
		|de = '" + vSystemName + " system disconnect error: '; 
		|en = '" + vSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function TCPAcknowledgement(pDLSys, pErrorList, pCharList)
	// Send LA and wait for LA too
	// "LA|DA071109|TI143436|  --> link alive in 09/11/2007 at 14:34:36"
	LA = pCharList.STX + "LA" + pCharList.SEP;
	vCurrentSessionDate = tcOnServer.cmGetServerCurrentSessionDate();
	vDate = "DA" + Format(vCurrentSessionDate,"DF=yyMMdd");
	LA = LA + vDate + pCharList.SEP + "TI" + Format(vCurrentSessionDate,"DF=HHmmss") + pCharList.SEP + pCharList.ETX;
	vBytesSent = pDLSys.Write(LA, StrLen(LA));
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 30;
		vReply = "";
		If pDLSys.Read(vReply, 1024) <> -1 Then
			vReply = GetAskCode(vReply, pErrorList, pCharList);
			If vReply = vDate Then
				Return True;
			Else
				AddError(NStr("en = 'Acknowledgement error: '; de = 'Fehler bei der Verbindungsbestätigung: '; ru = 'Ошибка подтверждения связи: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			EndIf;
		Else
			AddError(NStr("en = 'Acknowledgement error: '; de = 'Fehler bei der Verbindungsbestätigung: '; ru = 'Ошибка подтверждения связи: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("en = 'Acknowledgement error: '; de = 'Fehler bei der Verbindungsbestätigung: '; ru = 'Ошибка подтверждения связи: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction // TCPAcknowledgement

// -----------------------------------------------------------------------------
Function CallCOMCommand(pDLSys, pRoom, pCheckInDate, pCheckInTime, pCheckOutDate, pCheckOutTime, pAssignedAuthorizations, pEncoderNumber, pOperatorName, pCommandCode, pParameters)
	vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True);
	vIdentifier = String(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardRef, "Identifier")));
	
	vErrorCode = pDLSys.InterGH_TarjetaUsuario(pRoom, pCheckInDate, pCheckInTime, pCheckOutDate, pCheckOutTime, , , 0, pAssignedAuthorizations, 1, pEncoderNumber, vIdentifier, pCommandCode, 0, pOperatorName);
	Return vErrorCode;
EndFunction // CallCOMCommand

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pCommandCode, pDta, pParameters, pErrorList, pCharList, rCardID)	
	vErrorCode = pErrorList.RC_OK;
	pReply = "";
	
	// Build command string for the TCP interface
	vCmd = pCharList.STX + "GHHU"; 									// Command code
	vCmd = vCmd + pCharList.SEP + pDta.Room; 						// Add  room
	vCmd = vCmd + pCharList.SEP + pDta.CheckInDate;   				//Date  Format “YYYYMMDD”	
	vCmd = vCmd + pCharList.SEP + pDta.CheckInTime;   				//Time  Format “HHMM”
	vCmd = vCmd + pCharList.SEP + pDta.CheckOutDate;  				//Date  Format “YYYYMMDD”              
	vCmd = vCmd + pCharList.SEP + pDta.CheckOutTime;  				//Time  Format “HHMM”                  
	vCmd = vCmd + pCharList.SEP + pCharList.SEP; 					// Add 'room2' = Null
	vCmd = vCmd + pCharList.SEP + "0";								// Add 'Safe box', Allowed values: “0” (don’t have), “1” (have)
	vCmd = vCmd + pCharList.SEP + pDta.AssignedAuthorizations;		// Add 'AREA' 
	vCmd = vCmd + pCharList.SEP + "1"; 								// Add 'Number of cards'
	vCmd = vCmd + pCharList.SEP + pDta.EncoderNumber; 				// Add 'Encoder Number' Track 2
	vCmd = vCmd + pCharList.SEP + "";								// Add  Track 2 (Identifier card number in 1c:Hotel)
	vCmd = vCmd + pCharList.SEP + pCommandCode; 					// Add  Allowed values: “N” (new card), “C” (copy card), “D” (default treatment)
	vCmd = vCmd + pCharList.SEP + "0";								// Show confirmation msg - Allowed values: “0” (don’t show), “1” (show).  Default = “1”    
	vCmd = vCmd + pCharList.SEP + pDta.OperatorName;				// Add  User/Machine
	vCmd = vCmd + pCharList.SEP + pCharList.ETX;
	// Send acknowledgement
	If Not TCPAcknowledgement(pDLSys, pErrorList, pCharList) Then
		Return pErrorList.RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	vReadOK = False;
	pDLSys.Timeout = 30;
	For i = 1 To 3 Do
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1024) <> -1 Then
				vReplyCode = GetAskCode(vReply, pErrorList, pCharList);
				If vReplyCode = pErrorList.RC_OK Then
					vReadOK = True;
					vReplyArr = StrSplit(vReply, pCharList.SEP, True);
					If vReplyArr.Count() > 2 Then
						rCardID = vReplyArr[2]
					EndIf;
					Break;
				Else
					Return vReplyCode;
				EndIf;
			Else
				AddError(NStr("en = 'Read command confirmation error: '; de = 'Fehler bei der Einholung der Befehlbestätigung: '; ru = 'Ошибка получения подтверждения команды: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return pErrorList.RC_NO_CONNECTION;
			EndIf;
		Else
			AddError(NStr("en = 'Write command error: '; de = 'Fehler beim Versenden des Befehls: '; ru = 'Ошибка отправки команды: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pErrorList.RC_NO_CONNECTION;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = pErrorList.RC_WRONG_REPLY;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, vCommandCode, pDta, vDoorLockSystemParameters, pParameters, pErrorList, pCharList, rCardID)  
	var vRoom, vAssignedAuthorizations, vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vOperatorName, vEncoderNumber;
	// Read parameters
	pDta.Property("Room", vRoom);
	pDta.Property("AssignedAuthorizations", vAssignedAuthorizations);
	pDta.Property("CheckInDate", vCheckInDate);
	pDta.Property("CheckInTime", vCheckInTime);
	pDta.Property("CheckOutDate", vCheckOutDate);
	pDta.Property("CheckOutTime", vCheckOutTime);
	pDta.Property("OperatorName", vOperatorName);
	pDta.Property("EncoderNumber", vEncoderNumber);
	
	// Choose transport
	If ValueIsFilled(vDoorLockSystemParameters.ConnectionType) And
		vDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.OmniTecDLL") Then
		// Using COM interface
		vErrorCode = CallCOMCommand(pDLSys, vRoom, vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vAssignedAuthorizations, vEncoderNumber, vOperatorName, vCommandCode, pParameters);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, vCommandCode, pDta, pParameters, pErrorList, pCharList, rCardID);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pCardDesc, pDoorLockSystemParameters, pErrorList, pCharList)
	Var vCardType, vCardNumber, vRoom, vIsValid, vNumSec,vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vCardUUID;
	vErrorCode = pErrorList.RC_OK;
	
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then 
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"); 
			If ValueIsFilled(vDoorLockSystemLogin) Then
				vOperatorName = Left(Transliterate(TrimAll(vDoorLockSystemLogin), True, pDoorLockSystemParameters), 20);
			Else 
				vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, pDoorLockSystemParameters), 20);	
			EndIf;
		Else
			vOperatorName = Left(Transliterate(TrimAll(vCurrentUser), True, pDoorLockSystemParameters), 20);
		EndIf;
	EndIf;
	
	// Define command
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
		pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.OmniTecDLL") Then
		// Send command using COM interface
		vErrorCode = pDLSys.InterGH_LeeTarjeta(pEncoderNumber, vCardType, vCardNumber, vRoom, vIsValid, vNumSec,vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vCardUUID, vOperatorName);
	Else
		// Send command using TCP interface
		// Build command string for the TCP interface
		vCmd = pCharList.STX + "GHLT"; 					
		vCmd = vCmd + pCharList.SEP + pEncoderNumber + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + pCharList.SEP + vOperatorName + pCharList.ETX;
		// Send acknowledgement
		If Not TCPAcknowledgement(pDLSys, pErrorList, pCharList) Then
			Return pErrorList.RC_NO_REPLY;
		EndIf;
		// Send command and get acknowledgement
		pDLSys.Timeout = 30;
		For i = 1 To 3 Do
			If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
				vReply = "";
				If pDLSys.Read(vReply, 1024) <> -1 Then
					vReplyCode = GetAskCode(vReply, pErrorList, pCharList);
					If vReplyCode = pErrorList.RC_OK Then
						vReplyArr = StrSplit(vReply, pCharList.SEP, True);
						If vReplyArr.Count() > 1 Then
							vCardType = vReplyArr[1];
							vCardNumber = vReplyArr[2];
							vRoom = vReplyArr[3];
							vIsValid = vReplyArr[4];
							vNumSec = vReplyArr[5];
							vCheckInDate = vReplyArr[6];
							vCheckInTime = vReplyArr[7]; 
							vCheckOutDate = vReplyArr[8];
							vCheckOutTime = vReplyArr[9];
							If vReplyArr.Count() > 13 Then
								vCardUUID = vReplyArr[13];
							EndIf;
						EndIf;
						Break;
					Else
						Return vReplyCode;
					EndIf;
				Else
					AddError(NStr("en = 'Read command confirmation error: '; de = 'Fehler bei der Einholung der Befehlbestätigung: '; ru = 'Ошибка получения подтверждения команды: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
					Return pErrorList.RC_NO_CONNECTION;
				EndIf;
			Else
				AddError(NStr("en = 'Write command error: '; de = 'Fehler beim Versenden des Befehls: '; ru = 'Ошибка отправки команды: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return pErrorList.RC_NO_CONNECTION;
			EndIf;
		EndDo;
	EndIf;
	// Retrieve card data
	If vErrorCode = pErrorList.RC_OK Then
		vTypeCard = "";
		If tcOnServer.IsNumber(vCardType) And ValueIsFilled(vCardType) Then
			vTypeCard = GetTypeCard(Number(vCardType));
		EndIf;
		vCardUUID =?(vCardUUID = Undefined, "", vCardUUID);
		
		vRoomRef = Undefined;
		If ValueIsFilled(vRoom) Then
			If tcOnServer.IsNumber(vRoom) Then
				vRoom = Format(Number(vRoom), "ND=4; NFD=0; NG=");	
			EndIf;
			vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(vRoom);
		EndIf;  
		
		vCardFullName = "";
		vCardCheckInDate = GetDate(vCheckInDate, vCheckInTime);
		vCardCheckOutDate = GetDate(vCheckOutDate, vCheckOutTime);    
		vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(vCardUUID, vCardCheckInDate, vCardCheckOutDate, vRoomRef);
		If Not ValueIsFilled(vClientRef) Then
			vIDCardRef = tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(vCardUUID);
			If ValueIsFilled(vIDCardRef) Then
				vClientRef = tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client");	
			EndIf;
		EndIf;
		If ValueIsFilled(vClientRef) Then
			vCardFullName = tcOnServer.cmGetAttributeByRef(vClientRef, "FullName");
		EndIf;
		
		pCardDesc.Insert("CardRoom", ?(Not ValueIsFilled(vRoomRef), vRoom, vRoomRef));
		pCardDesc.Insert("CardType", vCardType);
		pCardDesc.Insert("CardNumber", vCardNumber);
		pCardDesc.Insert("CardCheckInDate", vCardCheckInDate);
		pCardDesc.Insert("CardCheckOutDate", vCardCheckOutDate);
		pCardDesc.Insert("CardID", vCardUUID);
		pCardDesc.Insert("IsCardValidCode", vIsValid);
		pCardDesc.Insert("IsCardValidDescription", vTypeCard);
		pCardDesc.Insert("CardCopyNumber", "");
		pCardDesc.Insert("AssignedAuthorizations", "");
		pCardDesc.Insert("CardOperator", vOperatorName);
		pCardDesc.Insert("CardAuthorizations", "");
		pCardDesc.Insert("CardFullName", vCardFullName);
		pCardDesc.Insert("ReplyType", "");
		pCardDesc.Insert("ReplyDescription", "");
		pCardDesc.Insert("CardRoom2", "");
		pCardDesc.Insert("CardRoom3", "");
		pCardDesc.Insert("CardRoom4", "");
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function CancelKeys(pDLSys, pEncoderNumber, pRoom, pDoorLockSystemParameters, pErrorList, pCharList)
	// Define command code
	vErrorCode = pErrorList.RC_OK;
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
		pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.OmniTecDLL") Then
		// Using COM interface
		vReply = "";
		vErrorCode = pDLSys.InterGH_TarjetaBloqueadora(pRoom, pEncoderNumber)
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = pErrorList.RC_NOT_SUPPORTED;
	EndIf;
	Return vErrorCode;
EndFunction // CancelKeys

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName)
	vObject = Undefined;
	amPersistentObjects.Property(pName, vObject);
	If vObject = Undefined Then
		amPersistentObjects.Insert(pName, vObject);
	EndIf;
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue)
	amPersistentObjects.Insert(pName, pValue);
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False, pDoorLockSystemParameters)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If pDoorLockSystemParameters.DoGuestNamesTransliteration Or pAlways Then
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
Function GetDate(pDate,pTime)
	Try
		vDate = Date(pDate + pTime);
	Except
		Return '00010101';
	EndTry;
	Return vDate;
EndFunction // GetDate

// -----------------------------------------------------------------------------
Function GetAskCode(pReply, pErrorList, pCharList)
	vNewReply = pErrorList.RC_UNKNOWN;
	vPos = Find(pReply, pCharList.SEP);
	If vPos > 0 Then
		pReply = TrimAll(Right(pReply, StrLen(pReply) - vPos));
		vPos = Find(pReply, pCharList.SEP);
		If vPos > 0 Then
			vNewReply = TrimAll(Left(pReply, vPos-1));
		Else
			vNewReply = pReply;
		EndIf;	
	EndIf;    
	If tcOnServer.IsNumber(vNewReply) Then
		Return Number(vNewReply);	
	EndIf;
	Return vNewReply;
EndFunction // GetAskCode	

// -----------------------------------------------------------------------------
Function GetTypeCard(pCardType)
	If pCardType = 1 Then
		vType = "Guest";
	Elsif pCardType = 2 Then
		vType = "Meeting";
	Elsif pCardType = 3 Then
		vType = "Emergency";
	Elsif pCardType = 4 Then
		vType = "Service";
	Elsif pCardType = 6 Then
		vType = "Security Master";
	Elsif pCardType = 7 Then
		vType = "Audit trail";
	Elsif pCardType = 8 Then
		vType = "Time";
	Elsif pCardType = 11 Then
		vType = "Bloking";
	Elsif pCardType = 12 Then
		vType = "Security Guest";
	Elsif pCardType = 22 Then
		vType = "Installation";
	Elsif pCardType = 23 Then
		vType = "Test";
	Elsif pCardType = 24 Then
		vType = "Inicialization";
	Else
		vType = "Unknown";
	EndIf;
	Return vType;
EndFunction

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_WRITE_ERROR", 1);
	vErrorList.Insert("RC_NO_WRITE_ERROR_DEMO", 2);
	vErrorList.Insert("RC_WRITE_ERROR_DEMO", 3);
	vErrorList.Insert("RC_DEMO_MODE_FINISH", 4);
	vErrorList.Insert("RC_ERROR_HDD_SN", 5);
	vErrorList.Insert("RC_NO_ID_CARD", 20);
	vErrorList.Insert("RC_NO_ID_CARD_DEMO", 22);
	vErrorList.Insert("RC_SYNTAX_ERROR", 25);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 26);
	vErrorList.Insert("RC_NO_CONNECTION_GESTHOTEL", 27);
	vErrorList.Insert("RC_PRESSED_CANCEL", 28);
	vErrorList.Insert("RC_NO_CONNECTION_CLIENT", 29);
	vErrorList.Insert("RC_NO_CONNECTION", 30);
	vErrorList.Insert("RC_UNUSABLE_CARD", 31);
	vErrorList.Insert("RC_NO_VALID_ROOM", 32);
	vErrorList.Insert("RC_DEVICE_IS_NOT_INIT", 33);
	vErrorList.Insert("RC_UNKNOWN_PROTOCOL", 34);
	vErrorList.Insert("RC_CANCELLED", 35);
	vErrorList.Insert("RC_UNKNOWN", 99);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_TIMEOUT", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_NO_CARD_OR_INVALID_CARD", 105);
	vErrorList.Insert("RC_NO_COMMUNICATION", 106);
	vErrorList.Insert("RC_OVERFLOW", 107);
	vErrorList.Insert("RC_MAGNETIC_TRACK_ERROR", 108);
	vErrorList.Insert("RC_MAGNETIC_FORMAT_ERROR", 109);
	vErrorList.Insert("RC_MAGNETIC_LEVEL_ERROR", 110);
	vErrorList.Insert("RC_NO_GUEST_PREVIOUSLY_CHECKED_IN", 112);
	vErrorList.Insert("RC_WRONG_ROOM", 113);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", 114);
	vErrorList.Insert("RC_CARD_MEMORY_OVERFLOW", 115);
	vErrorList.Insert("RC_BAD_REQUEST", 400);
	vErrorList.Insert("RC_UNAUTHORIZED", 401);
	vErrorList.Insert("RC_NOT_FOUND", 404);
	vErrorList.Insert("RC_UNPROCESSABLE_ENTITY", 422);
	vErrorList.Insert("RC_NOT_SUPPORTED", 999);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function GetCharList()
	vCharList = New Structure();
	vCharList.Insert("SEP", Char(124));
	vCharList.Insert("STX", Char(2));
	vCharList.Insert("ETX", Char(3));
	Return vCharList; 
EndFunction // GetErrorList

#EndRegion
