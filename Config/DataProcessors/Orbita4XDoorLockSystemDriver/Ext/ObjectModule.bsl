
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
	If IsBlankString(vRoomCode) Then
		If ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
			Room = DoorLockSystemParameters.DefaultRoom;
		EndIf;
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
//  Number - Error code 
//
Function pmAddKey() Export
	// Not supported by interface CLock.dll
	Return 0;
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
Procedure AddError(pErrorText)
	ErrorDescription = pErrorText;
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Orbita 4.X";
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vLock = Undefined;
		
		IsConnected = AttachAddIn("DataProcessor.Orbita4XDoorLockSystemDriver.Template.OrbitaLocks", "Native", ТипВнешнейКомпоненты.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + TrimAll(vLock.ErrorCode)+" "+ TrimAll(vLock.ErrorDescription)+Chars.CR+ ErrorDescription());
			Return Undefined;
		Endif;
			
		vLock = New("AddIn.Native.OrbitaLocks");

	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vLock;
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
Function MakeNewKey(pLock)
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
		// Using USB interface
		vAuth = TrimAll(DoorLockSystemParameters.LicenseCode);
		vCheckInDate = Format(CheckInDate,"DF='yyyy-MM-dd hh:mm:ss'");
		If DoorLockSystemParameters.SubtractMinutes <> 0 Then
			vCheckInDate = Format(CheckInDate - DoorLockSystemParameters.SubtractMinutes*60,"DF='yyyy-MM-dd hh:mm:ss'");
		EndIf;
		vCheckOutDate = Format(CheckOutDate,"DF='yyyy-MM-dd hh:mm:ss'");
		If DoorLockSystemParameters.AddMinutes <> 0 Then
			vCheckOutDate = Format(CheckOutDate + DoorLockSystemParameters.AddMinutes*60,"DF='yyyy-MM-dd hh:mm:ss'");
		EndIf;
		vBuilding = "";
		If DoorLockSystemParameters.UseRoomLockCodes And Not IsBlankString(Room.LockCode) Then
			vLockCode = TrimAll(Room.LockCode);
			// Get building number
			vPos = Find(vLockCode,".");
			if vPos > 1 Then
				vBuilding = Left(vLockCode,vPos-1);
				vRoom = Mid(vLockCode,vPos+1);
			Else
				vBuilding = "";
				vRoom = vLockCode;
			EndIf;
		Else
			vRoom = TrimAll(Room.Description);
		EndIf;
		Try
			vErrorCode = pLock.MakeGuestCard(vAuth, vBuilding, vRoom, vCheckInDate, vCheckOutDate);
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
	vCardData.CardRoom = pOrbita.Room;
	vCardData.CardCheckInDate = pOrbita.CheckinTime;
	vCardData.CardCheckOutDate = pOrbita.CheckoutTime;
	
	// Save previous card key
	PrevCardKey = pOrbita.CardNumber;
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pOrbita)
	vErrorCode = RC_OK;
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.USB Then
		// Using USB interface
		vAuth = TrimAll(DoorLockSystemParameters.LicenseCode);
		// Call API
		Try
			vErrorCode = pOrbita.ReadGuestCard(vAuth);
			If vErrorCode <> 0 Then
				vErrorCode = RC_EXCEPTION;
				RC_ERROR_DESCRIPTION = pOrbita.ErrorDescription;
			EndIf;
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
