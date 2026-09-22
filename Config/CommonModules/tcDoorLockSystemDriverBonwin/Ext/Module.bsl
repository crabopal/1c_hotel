
#Region Public

// -----------------------------------------------------------------------------
//
Procedure pmInstall() Export
	BeginInstallAddIn(, "CommonTemplate.AddInLocksBonwin");
EndProcedure

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDevice			 - ComObject - Device driver
//  pParameters		 - Strucrure - Any parameters
//  rErrorMessage	 - String	 - Error
// 
// Returns:
//  String - Error code
//
Function pmNewKey(pDevice, pParameters, rErrorMessage = "") Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoom = pParameters.Room;
	vRoomCode = TrimR(vRoom);
	If ValueIsFilled(vRoom) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom, "LockCode");
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
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom, "LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK; 
	EndIf;
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes * 60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes * 60;
	EndIf;
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	vParams = "A" + TrimAll(pDevice.LicenseCode) + vRoomCode + vSDate + vEDate + "000000";
	
	If Not IsBlankString(pDevice.EncoderNumber) Then
		vLock.LockType = Number(pDevice.EncoderNumber);
	EndIf;
	
	// Call API
	vErrorCode = vLock.MakeGuestCard(vParams, Number(pDevice.KeyCardType));
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		If pDevice.ReturnCardUID Then
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vLock.CardNumber, Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, False);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.KeyIssued'; de = 'DoorLockSystem.KeyIssued'; ru = 'СистемаЭлектронныхЗамков.ВыданКлюч'"), "Information", , , NStr("en = 'Key card issued: '; de = 'Kartenschlüssel wurde ausgehändigt: '; ru = 'Выдан ключ-карта: '") + TrimAll(vRoom) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
	Else
		rErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + rErrorMessage);
	EndIf;
	pmDisconnect(vLock);
		
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDevice			 - ComObject - Device driver
//  pParameters		 - Strucrure - Any parameters
//  rErrorMessage	 - String	 - Error
// 
// Returns:
//  String - Error code
//
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	Return pmNewKey(pDevice, pParameters);
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Strucrure - CardData
//  pDevice		 - ComObject - Device driver
//  pParameters	 - Strucrure - Any parameters
// 
// Returns:
//  String - Error code
//
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -1;
	
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Call API
	vCardDesc = "";
	vErrorCode = vLock.ReadGuestCard(TrimAll(pDevice.LicenseCode), Number(pDevice.EncoderNumber));
	If vErrorCode <> 0 Then
		vErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en = 'Error reading key card: '; de = 'Fehler beim Lesen der Karte: '; ru = 'Ошибка чтения карты: '") + vErrorCode + " - " + vErrorMessage);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRC			 - Number	 - Device responce
//  pSystemName	 - String	 - System name
// 
// Returns:
//  String - Error description
//
Function pmGetErrorDescription(pRC, pSystemName) Export
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
	
	vSystemName = pSystemName;

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
		Return(NStr("en = 'Card inserted wrongly or without magnetic stripe!'; de = 'Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'; ru = 'Не правильно вставлена карта или карта без магнитной полосы!'"));
	ElsIf pRC = RC_MAGNETIC_FORMAT_ERROR Then
		Return(NStr("en = 'You have removed card from the encoder before operation has finished or card/magnetic strip is damaged!'; de = 'Möglicherweise haben Sie die Karte von Encoder vor dem Ende der Operation genommen oder die Karte/der Magnetstreifen ist beschädigt!'; ru = 'Возможно сняли карту с энкодера не дожидаясь окончания операции или карта/магнитная полоса повреждена!'"));
	ElsIf pRC = RC_MAGNETIC_LEVEL_ERROR Then
		Return(NStr("en = 'The card has been encoded with a too low magnetic level due to dust in the reader magnetic head or low quality card!'; de = 'Niedriges Magnetisierungsniveau (möglicherweise ist der Encoder verschmutzt oder die Qualität der Karte ist schlecht)!'; ru = 'Низкий уровень намагничивания (возможно грязный энкодер или карта плохого качества)!'"));
	ElsIf pRC = RC_CARD_MEMORY_OVERFLOW Then
		Return(NStr("en='Card memory overflow!';ru='Переполнение памяти карты!';de='Der Kartenspeicher ist voll!'"));
	EndIf;
	Return "";
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.Error'; de = 'DoorLockSystem.Error'; ru = 'СистемаЭлектронныхЗамков.Ошибка'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vLock = Undefined;         

	// Fill system name
	vSystemName = String(pDevice.SystemName);
	Try     
		// ACC:561-off
		// Build ActiveX object to work with
		IsConnected = AttachAddIn("DataProcessor.BonwinDoorLockSystemDriver.Template.AddInLocks", "Native", AddInType.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + Chars.LF + ErrorDescription());
			Return Undefined;
		Endif;
		vLock = New("AddIn.Native.Locks");  
		// ACC:561-on
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pLock)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", pLock.Room);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", pLock.CheckinTime);
	vCardData.Insert("CardCheckOutDate", pLock.CheckoutTime);
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", pLock.CardNumber);
	vCardData.Insert("CardFullName", "");
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion
