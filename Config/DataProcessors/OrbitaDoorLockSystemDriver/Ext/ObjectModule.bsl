
#Region Variables

// -----------------------------------------------------------------------------
Var RC_OK Export; // OK
Var RC_WRONG_CONNECTION_TYPE Export; // No connection
Var RC_NO_CONNECTION Export; // No connection
Var RC_EXCEPTION Export; // Exception
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_PREV_CARD_ISSUED Export; // Prev card issued
Var RC_ERROR_DESCRIPTION Export; // Error

// -----------------------------------------------------------------------------
Var SystemName;
Var PrevCardKey;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey() Export
	// Connect
	vOrbita = pmConnect();
	If vOrbita = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Check room code
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
	
	// Call API
	vErrorCode = MakeNewKey(vOrbita);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + ?(vErrorCode = RC_EXCEPTION, Chars.LF + RC_ERROR_DESCRIPTION, ""));
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, "", CheckInDate, CheckOutDate, ParentDoc, Guest);
	EndIf;
	
	pmDisconnect(vOrbita);
	Return vErrorCode;
EndFunction //  pmNewKey
 
// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	// Connect
	vOrbita = pmConnect();
	If vOrbita = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Check room code
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
	
	// Call API
	vErrorCode = AddKey(vOrbita);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + ?(vErrorCode = RC_EXCEPTION, Chars.LF + RC_ERROR_DESCRIPTION, ""));
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		cmWriteKeyCardSecuritySystemEvent("ADD", "", Room, "", CheckInDate, CheckOutDate, ParentDoc, Guest);
	EndIf;
	
	pmDisconnect(vOrbita);
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
	// Connect
	vOrbita = pmConnect();
	If vOrbita = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Call API
	vErrorCode = Verify(vOrbita);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + ?(vErrorCode = RC_EXCEPTION, Chars.LF + RC_ERROR_DESCRIPTION, ""));
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vOrbita);
	EndIf;
	
	// Disconnect
	pmDisconnect(vOrbita);
	
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
		            |de = 'Failed to connect to the door locks system " + SystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_EXCEPTION Then
		If Not IsBlankString(RC_ERROR_DESCRIPTION) Then
			Return RC_ERROR_DESCRIPTION;
		Else
			Return(NStr("en='Unknown error!';ru='Неизвестная ошибка!';de='Unbekannter Fehler!'"));
		EndIf;
	ElsIf pRC = RC_WRONG_CONNECTION_TYPE Then
		Return(NStr("en='Connection type specified is not supported!';ru='Указанный тип подключения не поддерживается!';de='Der gewählte Anschlusstyp wird nicht unterstützt!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_PREV_CARD_ISSUED Then
		Return(NStr("en='Issue new key card or read previous first!';ru='Сначала выдайте новый ключ или прочитайте предыдущий!';de='Zuerst einen neuen Schlüssel herausgeben oder den vorherigen einlesen!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Auth code
//
Function pmGetNewAuthCode() Export
	// Connect
	vOrbita = pmConnect();
	If vOrbita = Undefined Then
		Raise pmGetErrorDescription(RC_NO_CONNECTION);
	EndIf;
	vAuthCode = TrimR(vOrbita.NewAuthorizationCode);
	// Disconnect
	pmDisconnect(vOrbita);
	// Return code
	Return vAuthCode;
EndFunction //  pmGetNewAuthCode

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetUserErrorDescription(pErrorDesc)
	vErrorDesc = TrimAll(pErrorDesc);
	vPos = Find(vErrorDesc, "1):");
	If vPos > 0 And (vPos + 4) < StrLen(vErrorDesc) Then
		vErrorDesc = Mid(vErrorDesc, vPos + 4);
		If Upper(vErrorDesc) = "NO CARD PRESENT" Then
			vErrorDesc = NStr("en='No card present';ru='Нет карты в считывателе';de='Im Lesegerät gibt es keine Karte'");
		ElsIf Upper(vErrorDesc) = "WRITE CARD ERROR" Then
			vErrorDesc = NStr("en='Write card error';ru='Ошибка записи карты';de='Fehler beim Schreiben der Karte'");
		ElsIf Upper(vErrorDesc) = "NOT ENCODED BY THIS SYSTEM" Then
			vErrorDesc = NStr("en='Not encoded by this system';ru='Карта закодирована в другой системе';de='Die Karte ist in einem anderen System kodiert'");
		ElsIf Upper(vErrorDesc) = "COMMUNICATION ERROR BETWEEN THE HOST AND ENCODER" Then
			vErrorDesc = NStr("en='Communication error between the host and encoder';ru='Ошибка подключения компьютера к энкодеру ключей';de='Fehler beim Anschließen des Computers an den Schlüssel-Encoder'");
		EndIf;
	ElsIf vPos > 0 And (vPos + 3) = StrLen(vErrorDesc) Then
		vErrorDesc = "";
	EndIf;
	Return vErrorDesc;
EndFunction //  GetUserErrorDescription

// -----------------------------------------------------------------------------
Function GetLockType()
	If TrimAll(DoorLockSystemParameters.KeyCardType) = "CIC_LOCK " Then
		Return 2;
	ElsIf TrimAll(DoorLockSystemParameters.KeyCardType) = "TEMIC_LOCK" Then
		Return 3;
	ElsIf TrimAll(DoorLockSystemParameters.KeyCardType) = "MIFARE_LOCK" Then
		Return 4;
	ElsIf TrimAll(DoorLockSystemParameters.KeyCardType) = "IBUTTON_LOCK" Then
		Return 5;
	ElsIf TrimAll(DoorLockSystemParameters.KeyCardType) = "MAGNETIC_LOCK" Then
		Return 6;
	Else
		Return 0;
	EndIf;
EndFunction //  GetLockType

// -----------------------------------------------------------------------------
Function GetCardType(pOrbita)
	If pOrbita.CardType = 1 Then
		Return NStr("en='Authorization Card';ru='Мастер карта';de='Leitkarte'");
	ElsIf pOrbita.CardType = 2 Then
		Return NStr("en='Clock Setting Card';ru='Карта установки времени';de='Karte der Zeiteinstellung'");
	ElsIf pOrbita.CardType = 3 Then
		Return NStr("en='Reserved for Palmsize Data Collector'; de='Reserved for Palmsize Data Collector'; ru='Reserved for Palmsize Data Collector'");
	ElsIf pOrbita.CardType = 4 Then
		Return NStr("en='Programming Card';ru='Пограммирующая карта';de='Programmierende Karte'");
	ElsIf pOrbita.CardType = 5 Then
		Return NStr("en='Disable Card';ru='Карта отмены доступа';de='Karte des Zugangsabbruchs'");
	ElsIf pOrbita.CardType = 6 Then
		Return NStr("en='Check Out Card';ru='Карта выселения';de='Zimmerräumungskarte'");
	ElsIf pOrbita.CardType = 7 Then
		Return NStr("en='Emergency Card'; de='Emergency Card'; ru='Emergency Card'");
	ElsIf pOrbita.CardType = 8 Then
		Return NStr("en='Control Card';ru='Контрольная карта';de='Kontrollkarte'");
	ElsIf pOrbita.CardType = 9 Then
		Return NStr("en='Building Card';ru='Карта на здание';de='Karte fürs Gebäude'");
	ElsIf pOrbita.CardType = 10 Then
		Return NStr("en='Floor Card';ru='Карта на этаж';de='Karte für die Etage'");
	ElsIf pOrbita.CardType = 11 Then
		Return NStr("en='Room Card';ru='Гостевая карта';de='Gästekarte'");
	ElsIf pOrbita.CardType = 12 Then
		Return NStr("en='Area Card';ru='Карта горничной';de='Zimmermädchenkarte'");
	ElsIf pOrbita.CardType = 13 Then
		Return NStr("en='Maintenance Card'; ru='Maintenance Card'");
	ElsIf pOrbita.CardType = 14 Then
		Return NStr("en='Office Card'; de='Office Card'; ru='Office Card'");
	ElsIf pOrbita.CardType = 15 Then
		Return NStr("en='Mechanical Key'; de='Mechanical Key'; ru='Mechanical Key'");
	Else
		Return "<UNKNOWN>";
	EndIf;
EndFunction //  GetCardType

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Orbita (Smile)";
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vOrbita = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
			vOrbita = New COMObject("HotelReader.Card.1");
			vOrbita.LockType = GetLockType();
			If vOrbita.LockType = 3 Then
				vOrbita.LockSubType = 1;
			Else
				vOrbita.LockSubType = 0;
			EndIf;
			vOrbita.ToCollector = False;
			vOrbita.MandatoryCancel = True;
		Else
			AddError(NStr("ru = 'Не поддерживаемый тип подключения к системе электронных замков " + SystemName + "!'; en = 'Unsupported connection type for " + SystemName + " door lock system!'; de = 'Unsupported connection type for " + SystemName + " door lock system!'"));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vOrbita;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pOrbita)
	Try
		pOrbita = Undefined;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function MakeNewKey(pOrbita)
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
		// Using USB interface
		pOrbita.AuthorizationCode = TrimAll(DoorLockSystemParameters.LicenseCode);
		pOrbita.CardType = 11;
		pOrbita.CardKey = CurrentSessionDate();
		PrevCardKey = pOrbita.CardKey;
		vCheckInDate = CheckInDate;
		If DoorLockSystemParameters.SubtractMinutes <> 0 Then
			vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
		EndIf;
		vCheckOutDate = CheckOutDate;
		If DoorLockSystemParameters.AddMinutes <> 0 Then
			vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
		EndIf;
		pOrbita.StartDate = vCheckInDate;
		pOrbita.ExpireDate = vCheckOutDate;
		pOrbita.Building = 255;
		pOrbita.Floor = 255;
		If DoorLockSystemParameters.UseRoomLockCodes And Not IsBlankString(Room.LockCode) Then
			vLockCode = TrimAll(Room.LockCode);
			// Get building number
			vPos = Find(vLockCode,".");
			if vPos > 1 Then
				vBuilding = Number(Left(vLockCode,vPos-1));
				vLockCode = Mid(vLockCode,vPos+1);
			Else
				vBuilding = 255;
			EndIf;
			// Get floor number
			vPos = Find(vLockCode,".");
			if vPos > 1 Then
				vFloor = Number(Left(vLockCode,vPos-1));
				vLockCode = Mid(vLockCode,vPos+1);
			Else
				vFloor = 255;
			EndIf;
			pOrbita.Building = vBuilding;
			pOrbita.Floor = vFloor;
			pOrbita.Room = Number(vLockCode);
		Else
			pOrbita.Room = Number(TrimAll(Room.Description));
		EndIf;
		pOrbita.SubRoom = 0;
		Try
			pOrbita.CancelCard();
			pOrbita.IssueCard();
		Except
			vErrorCode = RC_EXCEPTION;
			RC_ERROR_DESCRIPTION = GetUserErrorDescription(ErrorDescription());
		EndTry;
	Else
		vErrorCode = RC_WRONG_CONNECTION_TYPE;
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pOrbita)
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
		// Using USB interface
		pOrbita.AuthorizationCode = TrimAll(DoorLockSystemParameters.LicenseCode);
		pOrbita.CardType = 11;
		If ValueIsFilled(PrevCardKey) Then
			pOrbita.CardKey = PrevCardKey;
		Else
			Return RC_NO_PREV_CARD_ISSUED;
		EndIf;
		vCheckInDate = CheckInDate;
		If DoorLockSystemParameters.SubtractMinutes <> 0 Then
			vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
		EndIf;
		vCheckOutDate = CheckOutDate;
		If DoorLockSystemParameters.AddMinutes <> 0 Then
			vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
		EndIf;
		pOrbita.StartDate = vCheckInDate;
		pOrbita.ExpireDate = vCheckOutDate;
		pOrbita.Building = 255;
		pOrbita.Floor = 255;
		If DoorLockSystemParameters.UseRoomLockCodes And Not IsBlankString(Room.LockCode) Then
			vLockCode = TrimAll(Room.LockCode);
			// Get building number
			vPos = Find(vLockCode,".");
			if vPos > 1 Then
				vBuilding = Number(Left(vLockCode,vPos-1));
				vLockCode = Mid(vLockCode,vPos+1);
			Else
				vBuilding = 255;
			EndIf;
			// Get floor number
			vPos = Find(vLockCode,".");
			if vPos > 1 Then
				vFloor = Number(Left(vLockCode,vPos-1));
				vLockCode = Mid(vLockCode,vPos+1);
			Else
				vFloor = 255;
			EndIf;
			pOrbita.Building = vBuilding;
			pOrbita.Floor = vFloor;
			pOrbita.Room = Number(vLockCode);
		Else
			pOrbita.Room = Number(TrimAll(Room.Description));
		EndIf;
		pOrbita.SubRoom = 0;
		Try
			pOrbita.CancelCard();
			pOrbita.IssueCard();
		Except
			vErrorCode = RC_EXCEPTION;
			RC_ERROR_DESCRIPTION = GetUserErrorDescription(ErrorDescription());
		EndTry;
	Else
		vErrorCode = RC_WRONG_CONNECTION_TYPE;
	EndIf;
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pOrbita)
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
	vCardData.CardRoom = Format(pOrbita.Room, "ND=6; NFD=0; NG=");
	vCardData.CardType = GetCardType(pOrbita);
	vCardData.CardCheckInDate = pOrbita.StartDate;
	vCardData.CardCheckOutDate = pOrbita.ExpireDate;
	
	// Save previous card key
	PrevCardKey = pOrbita.CardKey;
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pOrbita)
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
		// Using USB interface
		pOrbita.AuthorizationCode = TrimAll(DoorLockSystemParameters.LicenseCode);
		pOrbita.StartDate = CurrentSessionDate();
		pOrbita.ExpireDate = CurrentSessionDate();
		// Call API
		Try
			pOrbita.ReadCard();
			pOrbita.BeepSound();
		Except
			vErrorCode = RC_EXCEPTION;
			RC_ERROR_DESCRIPTION = GetUserErrorDescription(ErrorDescription());
		EndTry;
	Else
		vErrorCode = RC_WRONG_CONNECTION_TYPE;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
RC_OK = 0;
RC_NO_CONNECTION = 1;
RC_WRONG_CONNECTION_TYPE = 2;
RC_WRONG_ROOM = 3;
RC_ROOM_WITHOUT_DOOR_LOCK = 4;
RC_NO_PREV_CARD_ISSUED = 5;
RC_EXCEPTION = 6;
RC_ERROR_DESCRIPTION = "";

PrevCardKey = '00010101';

#EndRegion

