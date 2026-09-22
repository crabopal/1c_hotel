
#Region Public

// -----------------------------------------------------------------------------
Function pmNewKey(pDeviceArr, pParameters, pErrorMessage) Export
	amRCErrorDescription = "";	
	vDoorLockSystemParameters = pDeviceArr.Ref;
	// Connect
	vOrbita = pmConnect(vDoorLockSystemParameters);
	If vOrbita = Undefined Then
		Return GetErrorCod("RC_NO_CONNECTION");
	EndIf;
	
	// Check room code
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "UseRoomLockCodes") Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		If ValueIsFilled(tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom")) Then
			pParameters.Room = tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "DefaultRoom");
		EndIf;
		vRoomCode = TrimR(pParameters.Room);
		If tcOnServer.cmGetAttributeByRef(vDoorLockSystemParameters, "UseRoomLockCodes") Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return GetErrorCod("RC_ROOM_WITHOUT_DOOR_LOCK");
	EndIf;
	
	// Call API
	vErrorCode = MakeNewKey(vOrbita, pParameters, vDoorLockSystemParameters);
	
	If vErrorCode <> GetErrorCod("RC_OK") Then
		AddError(NStr("en = 'Error issuing key card: '; de = 'Fehler bei der Kartenausstellung: '; ru = 'Ошибка выдачи карты: '") + vErrorCode + " " + amRCErrorDescription);
	Else
		tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.KeyIssued'; de = 'DoorLockSystem.KeyIssued'; ru = 'СистемаЭлектронныхЗамков.ВыданКлюч'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", "", pParameters.Room, "", pParameters.CheckInDate, pParameters.CheckOutDate, pParameters.ParentDoc, pParameters.Guest);
	EndIf;
	pErrorMessage = vOrbita.ErrorDescription;
	pmDisconnect(vOrbita);
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Procedure pmInstall() Export
	BeginInstallAddIn(, "CommonTemplate.AddInLocksOrbita4X");
EndProcedure

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDeviceArr, pParameters) Export
	amRCErrorDescription = "";  
	
	vDoorLockSystemParameters = pDeviceArr.Ref;
	// Connect
	vOrbita = pmConnect(vDoorLockSystemParameters);
	If vOrbita = Undefined Then
		Return GetErrorCod("RC_NO_CONNECTION");
	EndIf;
	
	// Call API
	vErrorCode = Verify(vOrbita, vDoorLockSystemParameters);
	If vErrorCode <> GetErrorCod("RC_OK") Then
		AddError(NStr("en = 'Error reading key card: '; de = 'Fehler beim Lesen der Karte: '; ru = 'Ошибка чтения карты: '") + vErrorCode + ?(vErrorCode = GetErrorCod("RC_EXCEPTION"), Chars.LF + amRCErrorDescription, ""));
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vOrbita);
	EndIf;
	pmDisconnect(vOrbita);
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	If pRC = GetErrorCod("RC_NO_CONNECTION") Then
		Return(StrTemplate(NStr("en = 'Failed to connect to the door locks system %1!'; 
								|de = 'Failed to connect to the door locks system %1!'; 
								|ru = 'Не удалось установить соединение с системой %1!'"), pSystemName));
	ElsIf pRC = GetErrorCod("RC_EXCEPTION") Then
		If Not IsBlankString(amRCErrorDescription) Then
			Return amRCErrorDescription;
		Else
			Return(NStr("en = 'Unknown error!'; de = 'Unbekannter Fehler!'; ru = 'Неизвестная ошибка!'"));
		EndIf;
	ElsIf pRC = GetErrorCod("RC_WRONG_CONNECTION_TYPE") Then
		Return(NStr("en = 'Connection type specified is not supported!'; de = 'Der gewählte Anschlusstyp wird nicht unterstützt!'; ru = 'Указанный тип подключения не поддерживается!'"));
	ElsIf pRC = GetErrorCod("RC_WRONG_ROOM") Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = GetErrorCod("RC_ROOM_WITHOUT_DOOR_LOCK") Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = GetErrorCod("RC_NO_PREV_CARD_ISSUED") Then
		Return(NStr("en='Issue new key card or read previous first!';ru='Сначала выдайте новый ключ или прочитайте предыдущий!';de='Zuerst einen neuen Schlüssel herausgeben oder den vorherigen einlesen!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function pmConnect(pDoorLockSystemParameters)
	// Fill system name
	SystemName = "Orbita 4.X";
	
	Try
		If Not ValueIsFilled(pDoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vLock = Undefined;
		
		// ACC:561-off
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksOrbita4X", "Orbita4X", AddInType.Native);
		If Not IsConnected Then      
			vErr = StrTemplate(NStr("en = '%1 door lock system connection error: %2 %3'; 
									|de = '%1 door lock system connection error: %2 %3'; 
									|ru = 'Ошибка подключения системы электронных замков %1: %2 %3'"), SystemName, TrimAll(vLock.ErrorCode), TrimAll(vLock.ErrorDescription));
			AddError(vErr + Chars.CR + ErrorDescription());
			Return Undefined;
		Endif;
			
		vLock = New("AddIn.Orbita4X.OrbitaLocks");
		// ACC:561-on
	Except    
		vErr = StrTemplate(NStr("en = '%1 door lock system connection error: %2'; 
									|de = '%1 door lock system connection error: %2'; 
									|ru = 'Ошибка подключения системы электронных замков %1: %2'"), SystemName, ErrorDescription());
		AddError(vErr);
		Return Undefined;
	EndTry;
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Function MakeNewKey(pLock, pParameters, pDoorLockSystemParameters)
	vErrorCode = GetErrorCod("RC_OK");
	If ValueIsFilled(tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"ConnectionType")) And
	   tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"ConnectionType") = PredefinedValue("Enum.ConnectionTypes.USB") Then
		// Using USB interface
		vAuth = TrimAll(tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"LicenseCode"));
		vCheckInDate = Format(pParameters.CheckInDate, "DF='yyyy-MM-dd HH:mm:ss'");
		If tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters, "SubtractMinutes") <> 0 Then
			vCheckInDate = Format(pParameters.CheckInDate - tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"SubtractMinutes") * 60, "DF='yyyy-MM-dd HH:mm:ss'");
		EndIf;
		vCheckOutDate = Format(pParameters.CheckOutDate, "DF='yyyy-MM-dd HH:mm:ss'");
		If tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters, "AddMinutes") <> 0 Then
			vCheckOutDate = Format(pParameters.CheckOutDate + tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters, "AddMinutes") * 60, "DF='yyyy-MM-dd HH:mm:ss'");
		EndIf;
		vBuilding = "";
		If tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters, "UseRoomLockCodes") And Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
			vLockCode = TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
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
			vRoom = TrimAll(pParameters.Room.Description);
		EndIf;
		Try
			vErrorCode = pLock.MakeGuestCard(vAuth, vBuilding, vRoom, vCheckInDate, vCheckOutDate);
			amRCErrorDescription = pLock.ErrorDescription;
		Except
			vErrorCode = GetErrorCod("RC_EXCEPTION");
			amRCErrorDescription = GetUserErrorDescription(ErrorDescription());
		EndTry;
	Else
		vErrorCode = GetErrorCod("RC_WRONG_CONNECTION_TYPE");
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function GetUserErrorDescription(pErrorDesc)
	vErrorDesc = TrimAll(pErrorDesc);
	vPos = Find(vErrorDesc, "1):");
	If vPos > 0 And (vPos + 4) < StrLen(vErrorDesc) Then
		vErrorDesc = Mid(vErrorDesc, vPos + 4);
		If Upper(vErrorDesc) = "NO CARD PRESENT" Then
			vErrorDesc = NStr("en = 'No card present'; de = 'Im Lesegerät gibt es keine Karte'; ru = 'Нет карты в считывателе'");
		ElsIf Upper(vErrorDesc) = "WRITE CARD ERROR" Then
			vErrorDesc = NStr("en = 'Write card error'; de = 'Fehler beim Schreiben der Karte'; ru = 'Ошибка записи карты'");
		ElsIf Upper(vErrorDesc) = "NOT ENCODED BY THIS SYSTEM" Then
			vErrorDesc = NStr("en = 'Not encoded by this system'; de = 'Die Karte ist in einem anderen System kodiert'; ru = 'Карта закодирована в другой системе'");
		ElsIf Upper(vErrorDesc) = "COMMUNICATION ERROR BETWEEN THE HOST AND ENCODER" Then
			vErrorDesc = NStr("en = 'Communication error between the host and encoder'; de = 'Fehler beim Anschließen des Computers an den Schlüssel-Encoder'; ru = 'Ошибка подключения компьютера к энкодеру ключей'");
		EndIf;
	ElsIf vPos > 0 And (vPos + 3) = StrLen(vErrorDesc) Then
		vErrorDesc = "";
	EndIf;
	Return vErrorDesc;
EndFunction // GetUserErrorDescription

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.Error'; de = 'DoorLockSystem.Error'; ru = 'СистемаЭлектронныхЗамков.Ошибка'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pOrbita)
		pOrbita = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pOrbita)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", pOrbita.Room);
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", pOrbita.CheckinTime);
	vCardData.Insert("CardCheckOutDate", pOrbita.CheckoutTime);
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", pOrbita.CardNumber);
	vCardData.Insert("CardFullName", "");
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pOrbita, pDoorLockSystemParameters)
	vErrorCode = GetErrorCod("RC_OK");
	If ValueIsFilled(tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"ConnectionType")) And
	   tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters,"ConnectionType") = PredefinedValue("Enum.ConnectionTypes.USB") Then
		// Using USB interface
		vAuth = TrimAll(tcOnServer.cmGetAttributeByRef(pDoorLockSystemParameters, "LicenseCode"));
		// Call API
		Try
			vErrorCode = pOrbita.ReadGuestCard(vAuth);
			If vErrorCode <> 0 Then
				vErrorCode = GetErrorCod("RC_EXCEPTION");
				amRCErrorDescription = pOrbita.ErrorDescription;
			EndIf;
		Except
			vErrorCode = GetErrorCod("RC_EXCEPTION");
			amRCErrorDescription = GetUserErrorDescription(ErrorDescription());
		EndTry;
	Else
		vErrorCode = GetErrorCod("RC_WRONG_CONNECTION_TYPE");
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function GetErrorCod(pName)
	If "RC_OK" = pName Then
		Return 0;	
	ElsIf "RC_NO_CONNECTION" = pName Then
		Return 1;
	ElsIf "RC_WRONG_CONNECTION_TYPE" = pName Then
		Return 2;
	ElsIf "RC_WRONG_ROOM" = pName Then
		Return 3;
	ElsIf "RC_ROOM_WITHOUT_DOOR_LOCK" = pName Then
		Return 4;
	ElsIf "RC_NO_PREV_CARD_ISSUED" = pName Then
		Return 5;
	ElsIf "RC_EXCEPTION" = pName Then
		Return 6;
	ElsIf "PrevCardKey" = pName Then
		Return '00010101';	
	EndIf;
	Return Undefined;
EndFunction

#EndRegion
