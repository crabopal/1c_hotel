
#Region Variables

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // OK
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_UNKNOWN Export; // Unknown

// -----------------------------------------------------------------------------
Var SystemName;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code
//
Function pmNewKey() Export
	// Connect
	vLock = pmConnect();
	If vLock = Undefined Then
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
	// Card type (authorizations)
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vAreaID = Number(Room.Owner.Code);
	// Floor ID = first numbers of a RoomID
	If StrLen(vRoomCode) > 2 Then
		vRoomID = Number(Right(vRoomCode,2));
		vFloorID = Number(Left(vRoomCode,StrLen(vRoomCode)-2));
	Else
		vRoomID = vRoomCode;
		vFloorID = 0;
	EndIf;
	vCardID = 0;
	If DoorLockSystemParameters.WriteTrack2 Then
		vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, false);
		Try
			vCardID = Number(vIDCardRef.Identifier);
		Except
			vCardID = 0;
		EndTry;
	EndIf;
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	vChilRoom = 0;
	// Call API
	vErrorCode = vLock.GuestManage(1, vAreaID, vFloorID, vRoomID, vChilRoom, vCardID, vSDate, vEDate);
	If vErrorCode = "1" Then
		vErrorCode = RC_OK;
		cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, "", vCheckInDate, vCheckOutDate, ParentDoc, Guest);
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmNewKey
 
// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	// Not supported by ActiveX driver
	Return pmNewKey();
EndFunction // pmAddKey

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
	vLock = pmConnect();
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Call API
	vRes = vLock.GuestManage(2,,,,,,,);
	If StrLineCount(vRes) = 8 then 
		vErrorCode = RC_OK;
	Else
		vErrorCode = RC_UNKNOWN;
	EndIf;
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vRes);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vRes);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmVerify

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
		            |en = 'Failed to connect to the door locks system " + SystemName + "!';
					|de = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error!';ru='Неизвестная ошибка!';de='Unbekannter Fehler!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "Motolong";
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vLock = Undefined;
		vLock = New COMObject("HotelCom.HotCom");
		// Open COM port
		vRes = vLock.InitializeCom(TrimAll(DoorLockSystemParameters.Port), "C3F415C3-1BDB-4638-805A-B59C8358FA88", DoorLockSystemParameters.EncoderNumber);
		If vRes <> "1" Then
			AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure // pmDisconnect

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
// Input parameter data example
// [SEP]R100[SEP]TSingle Room[SEP]FPupkin[SEP]NVasya[SEP]URegular Guest[SEP]D200506071000[SEP]O200506201200
// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
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
	
	pAreaID 					= StrGetLine(pCardDesc,2);		
	vCardData.CardRoom 			= ""+StrGetLine(pCardDesc,3)+StrGetLine(pCardDesc,4);		
	pChilRoom 					= StrGetLine(pCardDesc,5);		
	vCardData.CardTrack2 		= StrGetLine(pCardDesc,6);		
	vCardData.CardCheckInDate 	= GetDate(StrGetLine(pCardDesc,7));		
	vCardData.CardCheckOutDate 	= GetDate(StrGetLine(pCardDesc,8));
		
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 48;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_UNKNOWN = 999;

#EndRegion
