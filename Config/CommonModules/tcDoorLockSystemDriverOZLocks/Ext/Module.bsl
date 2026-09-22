
#Region Public

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
	BeginInstallAddIn(,"CommonTemplate.AddInLocksOZLocks");
EndProcedure // EndProcedure

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage, pIsAddKey = False) Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_INVALID_ROOM_CODE = -9999;
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;

	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vParams.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vParams.AddMinutes * 60;
	EndIf;
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	
	vBuildingNumber = 0;
	vFloorNumber = 0; 
	vRoomNumber = 0;
	vRoomCode = TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode"));
	vRoomsArray = StrSplit(vRoomCode,".");
	If vRoomsArray.Count() = 3 Then
		vBuildingNumber = Number(vRoomsArray[0]);
		vFloorNumber = Number(vRoomsArray[1]); 
		vRoomNumber = Number(vRoomsArray[2]); 
	EndIf;
	
	vKeyCount = tcDoorLocksAtServer.GetCountKeys(pParameters.Room) + 1;
	vMaxKeyCount = 255;
	If vKeyCount > vMaxKeyCount Then
		vKeyCount = vKeyCount - vMaxKeyCount * Int(vKeyCount / vMaxKeyCount);
	EndIf;
	
	vGroupOfKey = tcDoorLocksAtServer.GetLastKeysSet(pParameters.Room, False);
	If Not pIsAddKey Then
		vGroupOfKey = vGroupOfKey + 1;
	EndIf;
	
	vMaxGroupOfKey = 255;
	If vGroupOfKey > vMaxGroupOfKey Then
		vGroupOfKey = 0;
	EndIf;
	
	If vBuildingNumber <> 0 And vFloorNumber <> 0 And vRoomNumber <> 0 Then 
		vErrorCode = vLock.GuestCard(Number(vParams.HotelPassword), vKeyCount, vGroupOfKey, 0, vEDate, vBuildingNumber, vFloorNumber, vRoomNumber);
	Else
		vErrorCode = RC_INVALID_ROOM_CODE;
	EndIf;
	
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		vCardIDHex = vLock.CardID;
		If vParams.ReturnCardUID And ValueIsFilled(vCardIDHex) Then
			If vParams.ConvertCardIDToDec Then
				vCardID = HexToDec(vCardIDHex,16);
			Else
				vCardID = vCardIDHex;
			EndIf;
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information",,, NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		
		vCardType = "NEW";
		If pIsAddKey Then
			vCardType = "ADD";
		EndIf;
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent(vCardType, TrimAll(vCardID), pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1, vGroupOfKey);
	Else
		rErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + rErrorMessage);
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // NewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDeviceArr, pParameters, rErrorMessage) Export
	Return pmNewKey(pDeviceArr, pParameters, rErrorMessage, True);
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -1;
		
	// Connect
	vLock = pmConnect(pDevice);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	vErrorCode = vLock.ReadCard(Number(vParams.HotelPassword));
	
	If vErrorCode <> 0 Then
		vErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + vErrorMessage);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pCode, pSystemName) Export
	If pCode = -1 Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!';
		|de = 'Failed to connect to the door locks system " + pSystemName + "!';
		|en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pCode = -5 Then
		Return(NStr("ru = 'Чистая карта " + pSystemName + "!';
		|de = 'Saubere Karte " + pSystemName + "!';
		|en = 'Clean card " + pSystemName + "!'"));
	ElsIf pCode = -99 Then
		Return(NStr("ru = 'Не удалось загрузить LOCKRF26.DLL " + pSystemName + "!';
		|de = 'Fehler beim laden " + pSystemName + "!';
		|en = 'Failed to load LOCKRF26.DLL " + pSystemName + "!'"));
	ElsIf pCode = -9999 Then
		Return(NStr("ru = 'Неверный код номера " + pSystemName + "!';
		|de = 'Ungültiger ZimmerCode " + pSystemName + "!';
		|en = 'Invalid room code " + pSystemName + "!'"));
	Else
		Return NStr("ru = 'Неизвестная ошибка " + pSystemName + "!';
		|de = 'Unbekannter Fehler " + pSystemName + "!';
		|en = 'Unknown error " + pSystemName + "!'")
	EndIf;
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function HexToDec(Val pValue, pBasis)
	vResult = 0;
	vLength = StrLen(pValue);
	For vChar = 1 To StrLen(pValue) Do
		vMultiplier = 1;
		For vCount = 1 To vLength - vChar Do 
			vMultiplier = vMultiplier * pBasis;
		EndDo;
		vResult = vResult + (Find("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Mid(pValue, vChar, 1))-1) * vMultiplier;
	EndDo;
	Return Round(vResult);
EndFunction // HexToDec

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vLock = Undefined;

	// Fill system name
	vSystemName = String(pDevice.SystemName);
	Try
		// Build ActiveX object to work with
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksOZLocks", "Native", AddInType.Native); // ACC:561
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + Chars.LF + ErrorDescription());
			Return Undefined;
		Endif;
		vLock = New("AddIn.Native.OZLocks");
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
	vRoomCode = Mid(TrimAll(pLock.Room), 1, 2) + "." + Mid(TrimAll(pLock.Room), 3, 2) + "." + Mid(TrimAll(pLock.Room), 5, 2);
	vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(TrimAll(vRoomCode));
	
	vRoom = vRoomCode;
	If ValueIsFilled(vRoomRef) Then
		vRoom = vRoomRef;
	EndIf;
	
	vCardFullName = "";
	vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(TrimAll(pLock.CardID), , ?(ValueIsFilled(pLock.CheckoutTime), Date(pLock.CheckoutTime), Date(1,1,1)), vRoomRef);
	If ValueIsFilled(vClientRef) Then
		vCardFullName = tcOnServer.cmGetAttributeByRef(vClientRef, "FullName");
	EndIf;
	
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", vRoom);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", ?(ValueIsFilled(pLock.CheckinTime), Date(pLock.CheckinTime), ""));
	vCardData.Insert("CardCheckOutDate", ?(ValueIsFilled(pLock.CheckoutTime), Date(pLock.CheckoutTime), ""));
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", TrimAll(pLock.CardID));
	vCardData.Insert("CardFullName", vCardFullName);
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion

