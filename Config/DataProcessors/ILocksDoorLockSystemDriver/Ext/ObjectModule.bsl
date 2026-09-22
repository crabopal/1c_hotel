
#Region Variables

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export;  // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_UNKNOWN Export; // Unknouwn

// -----------------------------------------------------------------------------
Var SystemName;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  isExtra	 - Boolean	 - Take check-in time from last key issued for this room
// 
// Returns:
//  String - Error code 
//
Function pmNewKey(isExtra = false) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
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
	If isExtra Then
		// Take check-in time from last key issued for this room
		vCheckInDate = GetLastKeyDate();
	EndIf;
	If DoorLockSystemParameters.SubtractMinutes <> 0 AND Not isExtra Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vSDate = Format(vCheckInDate,"DF='yyyy-MM-dd HH:mm:ss'");
	vEDate = Format(vCheckOutDate,"DF='yyyy-MM-dd HH:mm:ss'");
	iFlags = ?(IsBlankString(vDoorLockSystemAuthorization),0,Number(vDoorLockSystemAuthorization));
	
	// Call API
	vErrorCode = vLock.MakeGuestCard(vRoomCode, vSDate,vEDate,iFlags);
	If vErrorCode = 1 Then
		If DoorLockSystemParameters.ReturnCardUID Then
			IdentificationCard = cmGetClientIdentificationCard(vLock.CardNumber, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, false);
		EndIf;
		vErrorCode = RC_OK;
		cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, "", vCheckInDate, vCheckOutDate, ParentDoc, Guest);
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	Return pmNewKey(true);
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
	vLock = pmConnect();
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Call API
	vRes = vLock.ReadGuestCard();
	If vRes = 1 then 
		vErrorCode = RC_OK;
	Else
		vErrorCode = RC_UNKNOWN;
	EndIf;
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vRes+" "+vLock.ErrorDescription);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
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
EndFunction //  pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "iLocks";
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;

		// Build ActiveX object to work with
		vLock = Undefined;
		
		IsConnected = AttachAddIn("DataProcessor.ILocksDoorLockSystemDriver.Template.AddInLocks", "Native", ТипВнешнейКомпоненты.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + TrimAll(vLock.ErrorCode)+" "+ TrimAll(vLock.ErrorDescription)+Chars.CR+ ErrorDescription());
			Return Undefined;
		Endif;
			
		vLock = New("AddIn.Native.Locks");
	    vRes = vLock.Configuration(Number(DoorLockSystemParameters.EncoderNumber));
		
		If vRes <> 1 Then
			AddError(NStr("en = 'Failed to connect: '; ru = 'Не удалось подключиться: '; de = 'Verbindung fehlgeschlagen: '") + TrimAll(vLock.ErrorCode)+" "+ TrimAll(vLock.ErrorDescription));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vLock;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
//  Input parameter data example
//
// Parameters:
//  pLock	 - Structure - Door lock params 
// 
// Returns:
//  Structure - Card params
//
Function pmParseCardDescription(Val pLock)   
	// [SEP]R100[SEP]TSingle Room[SEP]FPupkin[SEP]NVasya[SEP]URegular Guest[SEP]D200506071000[SEP]O200506201200

	vCardData = New Structure();
	vCardData.Insert("CardRoom", pLock.Room);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("CardType", "");
	vCardData.Insert("CardUserGroup", "");
	vCardData.Insert("CardCheckInDate", pLock.CheckinTime);
	vCardData.Insert("CardCheckOutDate", pLock.CheckoutTime);
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
	vCardData.Insert("CardTrack1", "");
	vCardData.Insert("CardTrack2", pLock.CardNumber);
	vCardData.Insert("CardAuthorizations", "");
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function GetLastKeyDate()
	If ValueIsFilled(Room) Then
		vQ = New Query("SELECT TOP 1
		               |	SafetySystemEvents.PeriodFrom
		               |FROM
		               |	InformationRegister.SafetySystemEvents AS SafetySystemEvents
		               |WHERE
		               |	SafetySystemEvents.Room = &qRoom
		               |
		               |ORDER BY
		               |	SafetySystemEvents.PeriodFrom DESC");
		vQ.SetParameter("qRoom", Room);
		qRes = vQ.Execute().Select();
		If qRes.Next() Then
			Return qRes.PeriodFrom;
		EndIf;
	EndIf;
	Return CheckInDate;
EndFunction //  GetLastKeyDate

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
