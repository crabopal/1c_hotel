
#Region Public

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
	BeginInstallAddIn(,"CommonTemplate.AddInLocksProUSB");
EndProcedure // EndProcedure

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage, pIsAddKey = False) Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = -9999;
	RC_MAX_NUMBER_OF_DOOR_LOOK = -10000;
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.proUSB);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	vLock.HotelID = Number(vParams.HotelPassword);
	
	// Check in dates
	vCheckInDate = pParameters.CheckInDate;
	If vParams.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vParams.SubtractMinutes * 60;
	EndIf;
	vLock.BDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	
	// Check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vParams.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vParams.AddMinutes * 60;
	EndIf;
	vLock.EDate = Format(vCheckOutDate, "DF=yyMMddHHmm");
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vParams.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vParams.DefaultRoom) Then
		pParameters.Room = vParams.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vParams.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		pmDisconnect(vLock);
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf; 
	
	vLock.LockNo = vRoomCode;
	vLock.LLock = vParams.Deadbolt; 
	
	// Common area
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) Then
		vLock.Pdoors = Number(TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")));
	Else
		vLock.Pdoors = vParams.AssignedAuthorizations;
	EndIf;
	
	vLock.Dai = tcDoorLocksAtServer.GetLastKeysSet(pParameters.Room, False);
	
	If pIsAddKey Then
		vLock.CardNo = tcDoorLocksAtServer.GetLastNumberOfKeys(pParameters.Room, vLock.Dai) + 1;
		If vLock.CardNo > 15 Then
			Return RC_MAX_NUMBER_OF_DOOR_LOOK;
		EndIf;
	Else
		vLock.Dai = vLock.Dai + 1;
		If vLock.Dai > 255 Then
			vLock.Dai = 0;
		EndIf;
		vLock.CardNo = 0;
	EndIf;
	
	vErrorCode = vLock.MakeGuestCard();
	
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		vCardIDHex = vLock.CardID;
		If vParams.ReturnCardUID And ValueIsFilled(vCardIDHex) Then
			If vParams.ConvertCardIDToDec Then
				vCardID = HexToDec(vCardIDHex, 16);
			Else
				vCardID = vCardIDHex;
			EndIf;
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.KeyIssued'; de = 'DoorLockSystem.KeyIssued'; ru = 'СистемаЭлектронныхЗамков.ВыданКлюч'"), "Information", , , NStr("en = 'Key card issued: '; de = 'Kartenschlüssel wurde ausgehändigt: '; ru = 'Выдан ключ-карта: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		If pIsAddKey Then
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", TrimAll(vCardID), pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest, vLock.CardNo, vLock.Dai);
		Else
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", TrimAll(vCardID), pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest, vLock.CardNo, vLock.Dai);
		EndIf;
	Else
		rErrorMessage = vLock.LastErrorDescription;
		AddError(NStr("en = 'Error issuing key card: '; de = 'Fehler bei der Kartenausstellung: '; ru = 'Ошибка выдачи карты: '") + vErrorCode + " - " + rErrorMessage);	
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDeviceArr, pParameters, rErrorMessage) Export
	Return pmNewKey(pDeviceArr, pParameters, rErrorMessage, True);
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -1;
	
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.proUSB);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	vLock.HotelID = Number(vParams.HotelPassword);
	
	vErrorCode = vLock.ReadGuestCard();
	
	If vErrorCode <> 0 Then
		AddError(NStr("en = 'Error reading key card: '; de = 'Fehler beim Lesen der Karte: '; ru = 'Ошибка чтения карты: '") + vErrorCode + " - " + vLock.LastErrorDescription);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock);
	EndIf;
	
	// Disconnect
	pmDisconnect(vLock);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmDelete(pDevice) Export 
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	
	// Call API
	vParams = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	
	// Connect
	vLock = pmConnect(pDevice, vParams.proUSB);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf; 
	vLock.HotelID = Number(vParams.HotelPassword);
	
	// Call API
	vErrorCode = vLock.CardErase();
	If vErrorCode <> RC_OK Then
		AddError(NStr("en = 'Erase card error: '; de = 'Fehler beim Löschen der Karte: '; ru = 'Ошибка стирания карты: '") + vErrorCode + Chars.LF + vLock.LastErrorDescription);
	EndIf;
	pmDisconnect(vLock);
	Return vErrorCode;
EndFunction //  pmDelete

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pCode, pSystemName) Export
	If pCode = -1 Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		|de = 'Failed to connect to the door locks system " + pSystemName + "!'; 
		|en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pCode = -99 Then
		Return(NStr("ru = 'Не удалось загрузить proRFL.DLL " + pSystemName + "!'; 
		|de = 'Fehler beim laden " + pSystemName + "!'; 
		|en = 'Failed to load proRFL.DLL " + pSystemName + "!'"));
	ElsIf pCode = -999 Then
		Return(NStr("en='Room has no key card door lock!';
		|ru='В номере нет электронного замка!';
		|de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pCode = -1000 Then
		Return(NStr("en = 'The maximum number of keys for this room has been issued!'; 
		|de = 'Die maximale Anzahl an Schlüsseln für dieses Zimmer ist vergeben!'; 
		|ru = 'Выдано максимальное количество ключей для этого номера!'"));
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
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.Error'; de = 'DoorLockSystem.Error'; ru = 'СистемаЭлектронныхЗамков.Ошибка'"), "Warning", , , pErrorText);
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
		vResult = vResult + (Find("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", Mid(pValue, vChar, 1)) - 1) * vMultiplier;
	EndDo;
	Return Round(vResult);
EndFunction //  HexToDec

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, proUSB)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vLock = Undefined;
	
	// Fill system name
	vSystemName = String(pDevice.SystemName);
	Try
		// Build ActiveX object to work with
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksProUSB", "Native", AddInType.Native); // ACC:561
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + Chars.LF + ErrorDescription());
			Return Undefined;
		Endif;
		vLock = New("AddIn.Native.proUSB");
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	
	vLock.proUSB = proUSB;
	
	If vLock.Connect() <> 0 Then 
		vLock = Undefined;
	EndIf;
	
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock.Disconnect();
	pLock = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pLock)
	vRoomCode = TrimAll(pLock.LockNo);
	vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(TrimAll(vRoomCode));
	
	vRoom = vRoomCode;
	If ValueIsFilled(vRoomRef) Then
		vRoom = vRoomRef;
	EndIf;
	
	vYear = Left(Format(CurrentDate(), "DF=yyyy"), 2);
	
	vEDate = ?(ValueIsFilled(pLock.EDate), AddMonth(Date(vYear + pLock.EDate), 16 * 12), Date(1, 1, 1));
	
	vCardFullName = "";
	vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(TrimAll(pLock.CardID), , ?(ValueIsFilled(pLock.EDate), vEDate, vRoomRef));
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
	vCardData.Insert("CardCheckInDate", ?(ValueIsFilled(pLock.BDate), Date(vYear + pLock.BDate), ""));
	vCardData.Insert("CardCheckOutDate", vEDate);
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", TrimAll(pLock.CardID));
	vCardData.Insert("CardFullName", vCardFullName);
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion
