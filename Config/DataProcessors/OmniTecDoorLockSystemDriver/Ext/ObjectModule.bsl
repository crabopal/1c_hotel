   
#Region Variables

Var SEP;
Var STX;
Var ETX;

// -----------------------------------------------------------------------------
Var RC_SYNTAX_ERROR Export; // Syntax error
Var RC_NO_CONNECTION Export; // No connection
Var RC_NO_COMMUNICATION Export; // No comunication 
Var RC_ERROR_HDD_SN Export; // Error hdd sn
Var RC_NO_ID_CARD_DEMO Export; // Demo mode
Var RC_NO_CONNECTION_GESTHOTEL Export; // No connection hotel 
Var RC_NO_CONNECTION_CLIENT Export; // No connection client
Var RC_NO_WRITE_ERROR_DEMO Export; // Demo mode
Var RC_DEMO_MODE_FINISH Export;  // Demo mode finish
Var RC_OK Export; // OK
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_NO_ID_CARD Export; // No id card
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_PRESSED_CANCEL Export; // Pressed cancel
Var RC_WRITE_ERROR Export; // Write error
Var RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Export; // No guest previously checked in
Var RC_WRITE_ERROR_DEMO Export; // Error demo


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
	vKeyParameters = New Structure();
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
	// 1.ROOM
	vKeyParameters.Insert("Room",vRoomCode);
	
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vAssignedAuthorizations =  TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vAssignedAuthorizations = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vAssignedAuthorizations = TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 2.AssignedAuthorizations
	vKeyParameters.Insert("AssignedAuthorizations",vAssignedAuthorizations);
	
	// 3. Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vKeyParameters.Insert("CheckInDate",Format(vCheckInDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckInTime",Format(vCheckInDate,"DF=HHmm"));
	
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vKeyParameters.Insert("CheckOutDate",Format(vCheckOutDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckOutTime",Format(vCheckOutDate,"DF=HHmm"));

	// 4. Operators data
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 20);
		Else
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser), True), 20);
		EndIf;
	EndIf;
	
	vKeyParameters.Insert("OperatorName",vOperatorName);

	// 5. Get encoder number
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);

	vKeyParameters.Insert("EncoderNumber",vEncoderNumber);
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys,"N", vKeyParameters);
	If String(vErrorCode) <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " );//+ vDta);
		cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, "", vCheckInDate, vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	vKeyParameters = New Structure();
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

	// 1.ROOM
	vKeyParameters.Insert("Room",vRoomCode);
	
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(DoorLockSystemParameters) And 
		   Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And 
		   vDoorLockSystemAuthorization.MergeWithDefault Then
			vAssignedAuthorizations =  TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		Else
			vAssignedAuthorizations = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vAssignedAuthorizations = TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	// 2.AssignedAuthorizations
	vKeyParameters.Insert("AssignedAuthorizations",vAssignedAuthorizations);
	
	// 3. Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vKeyParameters.Insert("CheckInDate",Format(vCheckInDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckInTime",Format(vCheckInDate,"DF=HHmm"));
	
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vKeyParameters.Insert("CheckOutDate",Format(vCheckOutDate,"DF=yyyyMMdd"));
	vKeyParameters.Insert("CheckOutTime",Format(vCheckOutDate,"DF=HHmm"));

	// 4. Operators data
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 20);
		Else
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser), True), 20);
		EndIf;
	EndIf;
	
	vKeyParameters.Insert("OperatorName",vOperatorName);

	// 5. Get encoder number
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);

	vKeyParameters.Insert("EncoderNumber",vEncoderNumber);
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys,"C", vKeyParameters);
	
	If vErrorCode <> RC_OK And vErrorCode <> "99" Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") );//+ ", " + vDta);
		cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, "", vCheckInDate, vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
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
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	
	// Call API
	pCardData = New Structure;
	vErrorCode = Verify(vDLSys, vEncoderNumber, pCardData);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		If ValueIsFilled(DoorLockSystemParameters)  Then
			If vErrorCode <> RC_OK Then
				AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
			Else
				vIDCardRef = Catalogs.IdentificationCards.FindByAttribute("Identifier", pCardData.CardID);
				If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.Client) Then
					pCardData.CardFullName = vIDCardRef.Client.FullName;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys);
	
	Return vErrorCode;
EndFunction //  pmVerify

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmCancel() Export
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
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Get encoder number
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	
	// Call API
	vErrorCode = CancelKeys(vDLSys, vEncoderNumber, vRoomCode);
	If vErrorCode <> RC_OK Then
		AddError(NStr("ru = 'Ошибка отмены ранее выданных карт: '; en = 'Error cancelling keys: '; de = 'Error cancelling keys: '") + vErrorCode);
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.CancelKeyCards'; de='DoorLockSystem.CancelKeyCards'; ru='СистемаЭлектронныхЗамков.ОтменаРанееВыданныхКлючей'"), EventLogLevel.Information, , , NStr("ru = 'Отменены ключи номера: '; en = 'Key cards canceled: '; de = 'Key cards canceled: '") + TrimAll(Room));
		cmWriteKeyCardSecuritySystemEvent("CANCEL", "", Room,  , '00010101', '00010101', ParentDoc, Guest, 0);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmCancel

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
		Return(NStr("en='Unknown client identification card!';ru='Неизвестная карта идентификации клиента!';de=''"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		|de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		|en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = RC_WRITE_ERROR Then
		Return(NStr("ru = 'Ошибка записи!'; 
		|de = ''; 
		|en = 'Write error!'"));
	ElsIf pRC = RC_NO_WRITE_ERROR_DEMO Then
		Return(NStr("ru = 'Все карты закодированы. Есть менее 15 дней, чтобы зарегистрировать GestHotel!'; 
		|de = ''; 
		|en = 'No error. All the cards have been read/written correctly, but you have less than 15 days to register GestHotel'"));
	ElsIf pRC = RC_WRITE_ERROR_DEMO Then
		Return(NStr("ru = 'Ошибка записи! Есть менее 15 дней, чтобы зарегистрировать GestHotel'; 
		|de = ''; 
		|en = 'Some of the cards have not been read/written correctly, and you have less than 15 days to register GestHotel'"));	
	ElsIf pRC = RC_DEMO_MODE_FINISH Then
		Return(NStr("ru = 'Ошибка записи! Демо режим GestHotel закончился'; 
		|de = ''; 
		|en = 'Test time of GestHotel has finished. None of the cards will be read/written.'"));	
	ElsIf pRC = RC_ERROR_HDD_SN Then
		Return(NStr("ru = 'Ошибка записи! SN жесткого диска отличается от регистрационного'; 
		|de = ''; 
		|en = 'Hard disk serial number is not the same as stored in database. None of the cards will be read/written'"));
	ElsIf pRC = RC_NO_ID_CARD_DEMO Then
		Return(NStr("ru = 'Неизвестная карта идентификации клиента.  Есть менее 15 дней, чтобы зарегистрировать GestHotel'; 
		|de = ''; 
		|en = 'Unknown card. You have less than 15 days to register GestHotel'"));
	ElsIf pRC = RC_NO_CONNECTION_GESTHOTEL Then
		Return(NStr("ru = 'Ошибка подключения к базе данных GestHotel'; 
		|de = ''; 
		|en = 'Lost connection to GestHotel database'"));
	ElsIf pRC = RC_PRESSED_CANCEL Then
		Return(NStr("ru = 'Выдача карты отменена в окне подтверждения'; 
		|de = ''; 
		|en = 'Cancel pressed when encoding card (in message window)'"));
	ElsIf pRC = RC_NO_CONNECTION_CLIENT Then
		Return(NStr("ru = 'Потеря связи с энкодером'; 
		|de = ''; 
		|en = 'Lost connection to encoder client'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверное число параметров!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName	 - String	 - Object name
// 
// Returns:
//  ComObject - Door lock system
//
Function GetPersistentObject(pName) Export
	vObject = Undefined;
	#IF CLIENT THEN
		amPersistentObjects.Property(pName, vObject);
		If vObject = Undefined Then
			amPersistentObjects.Insert(pName, vObject);
		EndIf;
	#ENDIF
	Return vObject;
EndFunction //  GetPersistentObject 

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName	 - String	 - Object name 
//  pValue	 - ComObject	 - Door lock system
// 
// Returns:
//   - 
//
Procedure SetPersistentObject(pName, pValue) Export
	#IF CLIENT THEN
		amPersistentObjects.Insert(pName, pValue);
	#ENDIF
EndProcedure //  SetPersistentObject

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
Function TCPAcknowledgement(pDLSys)
	// Send LA and wait for LA too
	// "  LA|DA071109|TI143436|  --> link alive in 09/11/2007 at 14:34:36"
	LA = STX +"LA"+SEP;
	vDate="DA" + String(Format(CurrentSessionDate(),"DF=yyMMdd"));
	LA=LA+vDate+ SEP+"TI"+ String(Format(CurrentSessionDate(),"DF=HHmmss"))+SEP+ETX;
	vBytesSent = pDLSys.Write(LA, StrLen(LA));
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 30;
		vReply = "";
		If pDLSys.Read(vReply, 1024) <> -1 Then
			vReply = GetAskCode(vReply);
			If vReply = vDate Then
				Return True;
			Else
				AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			EndIf;
		Else
			AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("en = 'Acknowledgement error: '; ru = 'Ошибка подтверждения связи: '; de = 'Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction //  TCPAcknowledgement

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "OmniTec";
	
	vDLSys = GetPersistentObject("OmniTec");
	
	If vDLSys = Undefined Then
		Try
			If Not ValueIsFilled(DoorLockSystemParameters) Then
				Return Undefined;
			EndIf;
			
			// Build ActiveX object to work with
			If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
				DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.OmniTecDLL Then
				vDLSys = New COMObject("InterGH.clsPrincipal");
				If Not vDLSys = Undefined Then
					SetPersistentObject("OmniTec",vDLSys);
				EndIf;
			ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
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
				vDLSys.Timeout = 30; // 30 seconds blocking read timeout by default
				vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), Number(TrimAll(DoorLockSystemParameters.Port)));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; 
					|de = '" + SystemName + " system server was not found: '; 
					|en = '" + SystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf; 
			Else
				AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": ';  
				|de = '" + SystemName + " door lock system connection error: '; 
				|en = '" + SystemName + " door lock system connection error: '") + NStr("en = 'not connect'; ru = 'Подключение к системе выдачи ключей OmniTec возможен только по DLL или TCP/IP'; de = 'not connect'"));
				Return Undefined;
			EndIf;
		Except	
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
			|de = '" + SystemName + " door lock system connection error: '; 
			|en = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	EndIf;
	Return vDLSys;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.OmniTecDLL Then
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
Function CallCOMCommand(pDLSys,pRoom, pCheckInDate, pCheckInTime,pCheckOutDate,pCheckOutTime,pAssignedAuthorizations,pEncoderNumber,pOperatorName,pCommandCode)
	vIDCardRef 		= cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, true);
	vIdentifier     = String(TrimAll(vIDCardRef.Identifier));
	
	vErrorCode = pDLSys.InterGH_TarjetaUsuario(pRoom, pCheckInDate, pCheckInTime, pCheckOutDate, pCheckOutTime,,,0,pAssignedAuthorizations, 1, pEncoderNumber, vIdentifier, pCommandCode, 0, pOperatorName);
	Return String(vErrorCode);
EndFunction //  CallCOMCommand

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pCommandCode, pDta)
	vIDCardRef 		= cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, true);
	vIdentifier     = String(TrimAll(vIDCardRef.Identifier));

	vErrorCode = RC_OK;
	pReply = "";
	
	// Build command string for the TCP interface
	vCmd = STX + "GHHU"; 					// Command code
	vCmd = vCmd + SEP + pDta.Room; 			// Add  room
	vCmd = vCmd + SEP + pDta.CheckInDate;   // Date  Format “YYYYMMDD”	
	vCmd = vCmd + SEP + pDta.CheckInTime;   // Time  Format “HHMM”
	vCmd = vCmd + SEP + pDta.CheckOutDate;  // Date  Format “YYYYMMDD”              
	vCmd = vCmd + SEP + pDta.CheckOutTime;  // Time  Format “HHMM”                  
	vCmd = vCmd + SEP + SEP; 				// Add 'room2' = Null
	vCmd = vCmd + SEP + "0";				// Add 'Safe box', Allowed values: “0” (don’t have), “1” (have)
	vCmd = vCmd + SEP + pDta.AssignedAuthorizations;// Add 'AREA' 
	vCmd = vCmd + SEP + "1"; 				// Add 'Number of cards'
	vCmd = vCmd + SEP + pDta.EncoderNumber; // Add 'Encoder Number' Track 2
	vCmd = vCmd + SEP + vIdentifier; 		// Add  Track 2 (Identifier card number in 1c:Hotel)
	vCmd = vCmd + SEP + pCommandCode; 		// Add  Allowed values: “N” (new card), “C” (copy card), “D” (default treatment)
	vCmd = vCmd + SEP + "1"; 				// Show confirmation msg - Allowed values: “0” (don’t show), “1” (show).  Default = “1”    
	vCmd = vCmd + SEP + pDta.OperatorName; 	// Add  User/Machine
   	vCmd = vCmd + SEP + ETX;
	// Send acknowledgement
	If Not TCPAcknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	vReadOK = False;
	pDLSys.Timeout = 30;
	For i = 1 To 3 Do
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1024) <> -1 Then
				vReply = GetAskCode(vReply);
				If vReply = RC_OK Then
					vReadOK = True;
					Break;
				Else
					Return vReply;
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
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	EndIf;
	Return vErrorCode;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, vCommandCode, pDta)  
	var vRoom,vAssignedAuthorizations,vCheckInDate,vCheckInTime,vCheckOutDate,vCheckOutTime,vOperatorName,vEncoderNumber;
	// Read parameters
	pDta.Property("Room",vRoom);
	pDta.Property("AssignedAuthorizations",vAssignedAuthorizations);
	pDta.Property("CheckInDate",vCheckInDate);
	pDta.Property("CheckInTime",vCheckInTime);
	pDta.Property("CheckOutDate",vCheckOutDate);
	pDta.Property("CheckOutTime",vCheckOutTime);
	pDta.Property("OperatorName",vOperatorName);
	pDta.Property("EncoderNumber",vEncoderNumber);

	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.OmniTecDLL Then
		// Using COM interface
	   vErrorCode = CallCOMCommand(pDLSys,vRoom, vCheckInDate, vCheckInTime,vCheckOutDate,vCheckOutTime,vAssignedAuthorizations,vEncoderNumber,vOperatorName,vCommandCode);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, vCommandCode, pDta);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function GetDate(pDate,pTime)
	Try
		vDate = Date(pDate+pTime);
	Except
		Return '00010101';
	EndTry;
	Return vDate;
EndFunction //  GetDate

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pCardDesc)
	Var vCardType, vCardNumber, vRoom, vIsValid, vNumSec,vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vTrack2;
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters) And 
	  (DoorLockSystemParameters.WriteTrack2 Or DoorLockSystemParameters.WriteTrack1) Then
		vRetention = "NO_CARD_EJECTION";
	EndIf;
	
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 20);
		Else
			vOperatorName = Left(Transliterate(TrimAll(SessionParameters.CurrentUser), True), 20);
		EndIf;
	EndIf;

	// Define command
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.OmniTecDLL Then
		// Send command using COM interface
		vErrorCode = pDLSys.InterGH_LeeTarjeta(pEncoderNumber, vCardType, vCardNumber, vRoom, vIsValid, vNumSec,vCheckInDate, vCheckInTime, vCheckOutDate, vCheckOutTime, vTrack2, vOperatorName);
		vErrorCode = String(vErrorCode);
	Else
		// Send command using TCP interface
		// Build command string for the TCP interface
		vCmd = STX + "GHLT"; 					
		vCmd = vCmd + SEP + pEncoderNumber + SEP + SEP + SEP+ SEP+ SEP+ SEP+ SEP+SEP+ SEP+ SEP+SEP+vOperatorName+SEP + ETX;
		// Send acknowledgement
		If Not TCPAcknowledgement(pDLSys) Then
			Return RC_NO_REPLY;
		EndIf;
		// Send command and get acknowledgement
		pDLSys.Timeout = 30;
		For i = 1 To 3 Do
			If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
				vReply = "";
				If pDLSys.Read(vReply, 1024) <> -1 Then
					vReply = GetAskCode(vReply);
					If vReply = RC_OK Then
						Break;
					Else
						Return vReply;
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
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_OK Then
		vTypeCard ="";
		If ValueIsFilled(TrimAll(vCardType)) Then
			vTypeCard = GetTypeCard(vCardType);
		EndIf;
		vTrack2 =?(vTrack2=Undefined,"",vTrack2);
		If DoorLockSystemParameters.UseRoomLockCodes And ValueIsFilled(TrimAll(vRoom)) Then
			vRoomRef = Catalogs.Rooms.FindByAttribute("LockCode",vRoom);
			vRoom = ?(vRoomRef.IsEmpty(),vRoom,vRoomRef);
		EndIf;
		pCardDesc.Insert("CardRoom",vRoom);
		pCardDesc.Insert("CardType",vCardType);
		pCardDesc.Insert("CardNumber",vCardNumber);
		pCardDesc.Insert("CardCheckInDate",GetDate(vCheckInDate,vCheckInTime));
		pCardDesc.Insert("CardCheckOutDate",GetDate(vCheckOutDate,vCheckOutTime));
		pCardDesc.Insert("CardID",vTrack2);
		pCardDesc.Insert("IsCardValidCode", vIsValid);
		pCardDesc.Insert("IsCardValidDescription", vTypeCard);
		pCardDesc.Insert("CardCopyNumber", "");
		pCardDesc.Insert("AssignedAuthorizations", "");
		pCardDesc.Insert("CardOperator", vOperatorName);
		pCardDesc.Insert("CardAuthorizations", "");
		pCardDesc.Insert("CardFullName", "");
		pCardDesc.Insert("ReplyType", "");
		pCardDesc.Insert("ReplyDescription", "");
		pCardDesc.Insert("CardRoom2", "");
		pCardDesc.Insert("CardRoom3", "");
		pCardDesc.Insert("CardRoom4", "");
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

// -----------------------------------------------------------------------------
Function CancelKeys(pDLSys, pEncoderNumber, pRoom)
	// Define command code
	vErrorCode = RC_OK;
	// Choose transport
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.OmniTecDLL Then
		// Using COM interface
		vReply = "";
		vErrorCode = pDLSys.InterGH_TarjetaBloqueadora(pRoom,pEncoderNumber)
	Else
		// Using TCP/IP interface
		vReply = "";
		// ErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, vCommandCode, pDta, "", vReply);
	EndIf;
	Return vErrorCode;
EndFunction //  CancelKeys

// -----------------------------------------------------------------------------
Function GetAskCode(pReply)
	vNewReply = RC_UNKNOWN;
	vPos = Find(pReply, SEP);
	If vPos > 0 Then
		pReply = TrimAll(Прав(pReply, StrLen(pReply) - vPos));
		vPos = Find(pReply, SEP);
		If vPos > 0 Then
			vNewReply = TrimAll(Left(pReply, vPos-1));
		Else
			vNewReply = pReply;
		EndIf;	
	EndIf;
	
	Return vNewReply;
EndFunction	

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

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
SEP = Char(124); 
STX = Char(2);
ETX = Char(3);

// -----------------------------------------------------------------------------

RC_OK = "0";
RC_WRITE_ERROR = "1";
RC_NO_WRITE_ERROR_DEMO = "2";
RC_WRITE_ERROR_DEMO = "3";
RC_DEMO_MODE_FINISH = "4";
RC_ERROR_HDD_SN = "5";
RC_NO_ID_CARD = "20";
RC_NO_ID_CARD_DEMO = 22;
RC_SYNTAX_ERROR = "25";
RC_DEVICE_TIME_OUT = "26";
RC_NO_CONNECTION_GESTHOTEL = "27";
RC_PRESSED_CANCEL = "28";
RC_NO_CONNECTION_CLIENT = "30";
RC_NO_CONNECTION = 30;

RC_UNKNOWN = "100";
RC_NO_FOLIO = "101";
RC_NO_REPLY = "103";
RC_WRONG_REPLY = "104";

RC_NO_COMMUNICATION = 106;
RC_OVERFLOW = "107";
RC_MAGNETIC_TRACK_ERROR = "108";
RC_MAGNETIC_FORMAT_ERROR = "109";
RC_MAGNETIC_LEVEL_ERROR = "110";

RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = "112";
RC_WRONG_ROOM = "113";
RC_ROOM_WITHOUT_DOOR_LOCK = "114";
RC_CARD_MEMORY_OVERFLOW = "115";




// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion
