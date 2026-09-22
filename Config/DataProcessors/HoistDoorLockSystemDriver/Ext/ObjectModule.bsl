
#Region Variables

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_UNKNOWN Export; // Unknown

Var RC_OK Export; // Ok

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
	// Check in and check out dates
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	
	objDoorLockSystemParameters = DoorLockSystemParameters.GetObject();
	p = objDoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
	
	// Call API
	vErrorCode = vLock.MakeGuestCard(p.IP, p.Port, p.DataBaseType,0, vRoomCode, "", "", vSDate, vEDate, p.DataSource, p.UserID, p.Password);
	ErrorDescription = vLock.ErrorDescription;
	
	If vErrorCode = 0 Then
		If DoorLockSystemParameters.ReturnCardUID Then
			IdentificationCard = cmGetClientIdentificationCard(vLock.CardNumber, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, false);
		EndIf;
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
	// Not supported by ActiveX driver
	Return pmNewKey();
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
	objDoorLockSystemParameters = DoorLockSystemParameters.GetObject();
	p = objDoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
	vRoomCode= "";
	vSDate = "";
	vEDate = "";
	vSuitCode = "";
	vPubDoor = "";
	
	// Call API
	vErrorCode = vLock.ReadGuestCard(p.IP,0,p.DataBaseType,p.DataSource,p.UserID,p.Password);
	ErrorDescription = vLock.ErrorDescription;
	If vErrorCode <> 0 Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode+" "+ErrorDescription);
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
	Return ErrorDescription;
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
	SystemName = "HOIST";
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;

		// Build ActiveX object to work with
		vLock = Undefined;
		
		IsConnected = AttachAddIn("DataProcessor.HoistDoorLockSystemDriver.Template.AddInLocks", "Native", AddInType.Native);
				
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") +Chars.CR+ ErrorDescription());
			Return Undefined;
		Endif;
			
		vLock = New("AddIn.Native.hoistlocks");
		
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
Function pmParseCardDescription(Val pLock) 
	// Input parameter data example
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
	vCardData.Insert("CardAuthorizations", "");
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_UNKNOWN = 999;
RC_OK = 0;

#EndRegion
