
#Region Public

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
	BeginInstallAddIn(, "CommonTemplate.AddInLocksiLocks");
EndProcedure

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "", pIsExtra = False) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_UNKNOWN = 999;
	
	vDoorLockSystemParameters = pDevice.Ref;

	IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	
	// Connect
	vLock = pmConnect(vDoorLockSystemParameters);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	If ValueIsFilled(pParameters.Room) Then
		If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
			vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
		Else
			vRoomCode = "";
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom")) Then
		vDefaultRoom = tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom"); 
		If Not IsBlankString(tcOnServer.cmGetAttributeByRef(vDefaultRoom, "LockCode")) Then
			vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(vDefaultRoom, "LockCode"));
		Else
			vRoomCode = "";
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// Card type (authorizations)
	vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.DoorLockSystemAuthorization, "AssignedAuthorizations");
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pIsExtra Then
		// Take check-in time from last key issued for this room
		vCheckInDate = tcDoorLocksAtServer.GetLastKeyDate(pParameters.Room, pParameters.CheckInDate);
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "SubtractMinutes") <> 0 And Not pIsExtra Then
		vCheckInDate = vCheckInDate - tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "SubtractMinutes") * 60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "AddMinutes") <> 0 Then
		vCheckOutDate = vCheckOutDate + tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters,"AddMinutes") * 60;
	EndIf;
	vSDate = Format(vCheckInDate, "DF='yyyy-MM-dd HH:mm:ss'");
	vEDate = Format(vCheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'");
	iFlags = ?(IsBlankString(vDoorLockSystemAuthorization), 0, Number(vDoorLockSystemAuthorization));
	
	// Call API
	vErrorCode = vLock.MakeGuestCard(vRoomCode, vSDate, vEDate, iFlags);
	If vErrorCode = 1 Then
		vCardUID = Left(vLock.CardNumber, 8);         
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "ConvertUUIDToDecimal") Then
			vCardUID = ConvertUUIDToDecimal(vCardUID, tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "BytesToConvert")); 		
		EndIf;
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "ReturnCardUID") Then
			IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID, , , vDoorLockSystemAuthorization);	
		EndIf;
		vErrorCode = RC_OK; 
		If Not pIsExtra Then 
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(IdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
		Else	
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(IdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
		EndIf;
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmNewKey
 
// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	Return pmNewKey(pDevice, pParameters, rErrorMessage, True);
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDeviceArr, pParameters) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_UNKNOWN = 999;    
	
	vDoorLockSystemParameters = pDeviceArr.Ref;
	// Connect
	vLock = pmConnect(vDoorLockSystemParameters);
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
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vRes + " " + vLock.ErrorDescription);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pName) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_UNKNOWN = 999;
	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой iLocks!'; 
		            |en = 'Failed to connect to the door locks system iLocks!';
					|de = 'Failed to connect to the door locks system iLocks!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return (NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return (NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return (NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error!';ru='Неизвестная ошибка!';de='Unbekannter Fehler!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.Error'; de = 'DoorLockSystem.Error'; ru = 'СистемаЭлектронныхЗамков.Ошибка'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDoorLockSystemParameters)
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_UNKNOWN = 999;
	// Fill system name
	SystemName = "iLocks";
	Try
		If Not ValueIsFilled(pDoorLockSystemParameters) Then
			Return Undefined;
		EndIf;

		// Build ActiveX object to work with
		vLock = Undefined;
		
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksiLocks", "Native", AddInType.Native); // ACC:561
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; en = '" + SystemName + " door lock system connection error: '; de = '" + SystemName + " door lock system connection error: '"));
			Return Undefined;
		Endif;
			
		vLock = New("AddIn.Native.Locks");
	    vRes = vLock.Configuration(Number(tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"EncoderNumber")));
		
		If vRes <> 1 Then
			AddError(NStr("en = 'Failed to connect: '; ru = 'Не удалось подключиться: '; de = 'Verbindung fehlgeschlagen: '") + TrimAll(vLock.ErrorCode)+ " " + TrimAll(vLock.ErrorDescription));
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
// Input parameter data example
// [SEP]R100[SEP]TSingle Room[SEP]FPupkin[SEP]NVasya[SEP]URegular Guest[SEP]D200506071000[SEP]O200506201200
// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pLock)
	vRoomCode = TrimAll(pLock.Room);
	
	vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(vRoomCode);
	If Not ValueIsFilled(vRoomRef) Then
		vNewRoomCodeArr = New Array;
		vRoomCodeArr = StrSplit(vRoomCode, ".", False);
		For Each vRoomCodeRow In vRoomCodeArr Do
			vNewRoomCodeArr.Add(Format(Number(vRoomCodeRow), "NFD=0; NZ=; NG="));	
		EndDo;
		vRoomCode = StrConcat(vNewRoomCodeArr, ".");
		vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(vRoomCode);
	EndIf;
	
	vCardFullName = "";  
	vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(TrimAll(Left(pLock.CardNumber, 8)), , ?(ValueIsFilled(pLock.CheckoutTime), Date(StrReplace(StrReplace(StrReplace(pLock.CheckoutTime, ":", ""), "-", ""), " ", "")), Date(1,1,1)), vRoomRef);
	If ValueIsFilled(vClientRef) Then
		vCardFullName = tcOnServer.cmGetAttributeByRef(vClientRef, "FullName");
	EndIf;
	
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", ?(Not ValueIsFilled(vRoomRef), vRoomCode, vRoomRef));
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
	vCardData.Insert("CardID", Left(pLock.CardNumber, 8));
	vCardData.Insert("CardFullName", vCardFullName);
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

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

#EndRegion
