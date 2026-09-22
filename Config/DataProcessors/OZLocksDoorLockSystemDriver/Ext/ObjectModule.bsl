
#Region Variables

// -----------------------------------------------------------------------------
Var RC_OK; // OK
Var RC_NO_CONNECTION; // No connection
Var RC_INVALID_ROOM_CODE; // Invalied room code
Var RC_CLEAR_CARD; // Clear card
Var RC_FAILED; // Failed

// -----------------------------------------------------------------------------
Var ConnectionParameters;
Var SystemName; 

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey(pIsAddKey = False) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	// Connect
	vLock = pmConnect();
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	ConnectionParameters = DoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
	
	// Check out dates
	vCheckOutDate = CheckOutDate;
	If ConnectionParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + ConnectionParameters.AddMinutes * 60;
	EndIf;
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	
	vBuildingNumber = 0;
	vFloorNumber = 0; 
	vRoomNumber = 0;
	vRoomCode = Room.LockCode;
	vRoomsArray = StrSplit(vRoomCode,".");
	If vRoomsArray.Count() = 3 Then
		vBuildingNumber = Number(vRoomsArray[0]);
		vFloorNumber = Number(vRoomsArray[1]); 
		vRoomNumber = Number(vRoomsArray[2]); 
	EndIf;
	
	vKeyCount = tcDoorLocksAtServer.GetCountKeys(Room) + 1;
	vMaxKeyCount = 255;
	If vKeyCount > vMaxKeyCount Then
		vKeyCount = vKeyCount - vMaxKeyCount * Int(vKeyCount / vMaxKeyCount);
	EndIf;
	
	vGroupOfKey = tcDoorLocksAtServer.GetLastKeysSet(Room, False);
	If Not pIsAddKey Then
		vGroupOfKey = vGroupOfKey + 1;
	EndIf;
	
	vMaxGroupOfKey = 255;
	If vGroupOfKey > vMaxGroupOfKey Then
		vGroupOfKey = 0;
	EndIf;
	
	// Call API
	If vBuildingNumber <> 0 And vFloorNumber <> 0 And vRoomNumber <> 0 Then 
		vErrorCode = vLock.GuestCard(Number(ConnectionParameters.HotelPassword), vKeyCount, vGroupOfKey, 0, vEDate, vBuildingNumber, vFloorNumber, vRoomNumber);
	Else
		vErrorCode = RC_INVALID_ROOM_CODE;
	EndIf;
		
	If vErrorCode <> 0 Then
		ErrorDescription = vLock.ErrorDescription;
		AddError(NStr("en = 'Error writing key card:'; de = 'Fehler beim Schreiben der Karte: '; ru = 'Ошибка записи карты: '") + vErrorCode + " - " + ErrorDescription);
	Else
		If ConnectionParameters.ReturnCardUID Then
			IdentificationCard = cmGetClientIdentificationCard(vLock.CardID, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, false);
		EndIf;
		vCardType = "NEW";
		If pIsAddKey Then
			vCardType = "ADD";
		EndIf;
		cmWriteKeyCardSecuritySystemEvent(vCardType, "", Room, "", CheckInDate, vCheckOutDate, ParentDoc, Guest, , vGroupOfKey);
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
	Return pmNewKey(True);
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
	
	ConnectionParameters = DoorLockSystemParameters.DoorLockSystemConnectionParameters.Get();
	
	// Call API
	vErrorCode = vLock.ReadCard(Number(ConnectionParameters.HotelPassword));
	
	If vErrorCode <> 0 Then
		ErrorDescription = vLock.ErrorDescription;
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + ErrorDescription);
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
            		|de = 'Failed to connect to the door locks system " + SystemName + "!'; 
            		|en = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_CLEAR_CARD Then
		Return(NStr("ru = 'Чистая карта " + SystemName + "!'; 
            		|de = 'Saubere Karte " + SystemName + "!'; 
            		|en = 'Clean card " + SystemName + "!'"));
	ElsIf pRC = RC_FAILED Then
		Return(NStr("ru = 'Не удалось загрузить LOCKRF26.DLL " + SystemName + "!'; 
            		|de = 'Fehler beim laden " + SystemName + "!'; 
           		 	|en = 'Failed to load LOCKRF26.DLL " + SystemName + "!'"));
	ElsIf pRC = RC_INVALID_ROOM_CODE Then
		Return(NStr("ru = 'Неверный код номера " + SystemName + "!'; 
            		|de = 'Ungültiger ZimmerCode " + SystemName + "!'; 
           		 	|en = 'Invalid room code " + SystemName + "!'"));
	Else
		Return NStr("ru = 'Неизвестная ошибка " + SystemName + "!'; 
		            |de = 'Unbekannter Fehler " + SystemName + "!'; 
		            |en = 'Unknown error " + SystemName + "!'")
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
	SystemName = "OZLocks";
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;

		// Build ActiveX object to work with
		vLock = Undefined;
		
		IsConnected = AttachAddIn("DataProcessor.OZLocksDoorLockSystemDriver.Template.AddInLocks", "Native", ТипВнешнейКомпоненты.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '") +Chars.CR+ ErrorDescription());
			Return Undefined;
		Endif;
		
		vLock = New("AddIn.Native.OZLocks");
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
	vRoomCode = Mid(TrimAll(pLock.Room), 1, 2) + "." + Mid(TrimAll(pLock.Room), 3, 2) + "." + Mid(TrimAll(pLock.Room), 5, 2);
	vRoomRef = cmGetRoomByCode(TrimAll(vRoomCode), SessionParameters.CurrentHotel);
	
	vRoom = vRoomCode;
	If ValueIsFilled(vRoomRef) Then
		vRoom = vRoomRef;
	EndIf;
		
	vCardData = New Structure();
	vCardData.Insert("CardRoom", vRoom);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("CardType", "");
	vCardData.Insert("CardUserGroup", "");
	vCardData.Insert("CardCheckInDate", ?(ValueIsFilled(pLock.CheckinTime), Date(pLock.CheckinTime), ""));
	vCardData.Insert("CardCheckOutDate", ?(ValueIsFilled(pLock.CheckoutTime), Date(pLock.CheckoutTime), ""));
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
	vCardData.Insert("CardTrack1", "");
	vCardData.Insert("CardTrack2", TrimAll(pLock.CardID));
	vCardData.Insert("CardAuthorizations", "");
		
	// Return card data
	Return vCardData;
EndFunction //  pmParseCardDescription

#EndRegion  

#Region Initialize

// -----------------------------------------------------------------------------
RC_OK = 0;
RC_NO_CONNECTION = -1;
RC_INVALID_ROOM_CODE = -9999;
RC_CLEAR_CARD = -5;
RC_FAILED = -99;

#EndRegion
