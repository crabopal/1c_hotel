
#Region Public

// -----------------------------------------------------------------------------
Procedure pmInstall() Export  
	InstallAddIn("CommonTemplate.AddInLocksLocstar"); // ACC:561
EndProcedure

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "", pType = "L1") Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_CARD_TYPE_EMPTY = -3;
	SEP = Char(124);
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vLock = pmConnect(vDoorLockSystemParameters, pDevice.SystemName);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	vCardType = vDoorLockSystemParameters.KeyCardType;
	If Not ValueIsFilled(vCardType) Then
		Return RC_CARD_TYPE_EMPTY;	
	EndIf;
	
	// Build command data string
	vRoom = pParameters.Room;
	vRoomCode = TrimR(vRoom);
	If ValueIsFilled(vRoom) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom, "LockCode");
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		vRoom = vDoorLockSystemParameters.DefaultRoom;
		pParameters.Room = vRoom;
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom, "LockCode");
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK; 
	EndIf;
	
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes * 60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	vSDate = Format(vCheckInDate,"DF=yyMMddHHmm");
	vEDate = Format(vCheckOutDate,"DF=yyMMddHHmm");
	vWaitS = vDoorLockSystemParameters.CardWaitingTime;
	If vWaitS = 0 Then
		vWaitS = 5;
	EndIf;
		
	If pParameters.NumberOfKeys = 1 Then 
		vData = "T" + vCardType + SEP + "R" + vRoomCode + SEP + "D" + vSDate + SEP + "O" + vEDate + SEP + pType;
		tcOnServer.Wait(vWaitS);
		vErrorCode = vLock.GuestCard(vData);
	ElsIf pType = "L1" And pParameters.NumberOfKeys > 1 Then
		vData = "T" + vCardType + SEP + "R" + vRoomCode + SEP + "D" + vSDate + SEP + "O" + vEDate + SEP + pType;
		tcOnServer.Wait(vWaitS);
		vErrorCode = vLock.GuestCard(vData);
		If vErrorCode = RC_OK Then
			tcOnServer.GetClientIdentificationCard(vLock.CardID, Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate);
			vData = "T" + vCardType + SEP + "R" + vRoomCode + SEP + "D" + vSDate + SEP + "O" + vEDate + SEP + "L0";
			For vNumber = 1 To pParameters.NumberOfKeys - 1 Do
				tcOnServer.Wait(vWaitS);
				vErrorCode = vLock.GuestCard(vData);
				If vErrorCode <> RC_OK Then
					Break;	                                
				EndIf;
				If vNumber <> pParameters.NumberOfKeys - 1 Then 
					tcOnServer.GetClientIdentificationCard(vLock.CardID, Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate);
				EndIf;
			EndDo;
		EndIf;
	ElsIf pType = "L0" And pParameters.NumberOfKeys > 1 Then
		vData = "T" + vCardType + SEP + "R" + vRoomCode + SEP + "D" + vSDate + SEP + "O" + vEDate + SEP + pType;
		For vNumber = 1 To pParameters.NumberOfKeys Do
			tcOnServer.Wait(vWaitS);
			vErrorCode = vLock.GuestCard(vData);
			If vErrorCode <> RC_OK Then
				Break;	
			EndIf;
			If vNumber <> pParameters.NumberOfKeys Then 
				tcOnServer.GetClientIdentificationCard(vLock.CardID, Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate);
			EndIf;
		EndDo;
	Else
		vData = "T" + vCardType + SEP + "R" + vRoomCode + SEP + "D" + vSDate + SEP + "O" + vEDate + SEP + pType;
		tcOnServer.Wait(vWaitS);
		vErrorCode = vLock.GuestCard(vData);
	EndIf;
				
	If vErrorCode = RC_OK Then
		vIdentificationCard = Undefined;
		If vDoorLockSystemParameters.ReturnCardUID Then
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = tcOnServer.GetClientIdentificationCard(vLock.CardID, Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate);
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"),"Information",,,NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoom) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
	Else
		rErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + rErrorMessage);
	EndIf;
	pmDisconnect(vLock);
		
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "", pType = "L0") Export
	Return	pmNewKey(pDevice, pParameters, rErrorMessage, pType);
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	RC_NO_CONNECTION = -1;
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	// Connect
	vLock = pmConnect(vDoorLockSystemParameters, pDevice.SystemName);
	If vLock = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	// Call API
	vErrorCode = vLock.ReadCard();
	If vErrorCode <> 0 Then
		vErrorMessage = vLock.ErrorDescription;
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + vErrorMessage);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vLock, vDoorLockSystemParameters.ReturnCardUID);
	EndIf;
	// Disconnect
	pmDisconnect(vLock);	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	If pRC = -1 Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; de = 'Failed to connect to the door locks system " + pSystemName + "!'; en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = -2 Then
		Return(NStr("en = 'Room has no key card door lock!'; de = 'Im Zimmer ist kein elektronisches Schloss vorhanden!'; ru = 'В номере нет электронного замка!'"));
	ElsIf pRC = -3 Then
		Return(NStr("en = 'Card type is not filled'; de = 'Kartentyp ist nicht gefüllt'; ru = 'Тип карты не заполнен'"));
	ElsIf pRC = 1 Then
		Return(NStr("en = 'No Card'; de = 'Keine Karte'; ru = 'Нет карты'"));
	ElsIf pRC = 2 Then
		Return(NStr("en = 'Card Error'; de = 'Kartenfehler'; ru = 'Ошибка карты'"));
	ElsIf pRC = 3 Then
		Return(NStr("en = 'Password Error'; de = 'Passwort-Fehler'; ru = 'Ошибка пароля'"));
	ElsIf pRC = 4 Then
		Return(NStr("en = 'Serial Port Communication Error'; de = 'Kommunikationsfehler der seriellen Schnittstelle'; ru = 'Ошибка связи последовательного порта'"));
	ElsIf pRC = 5 Then
		Return(NStr("en = 'Authorization Error'; de = 'Ошибка авторизации'; ru = 'Ошибка авторизации'"));
	ElsIf pRC = 7 Then
		Return(NStr("en = 'New Card'; de = 'Neue Karte'; ru = 'Новая карта'"));
	ElsIf pRC = 10 Then
		Return(NStr("en = 'Data Error'; de = 'Datenfehler'; ru = 'Ошибка данных'"));
	ElsIf pRC = 11 Then
		Return(NStr("en = 'Configuration file Error'; de = 'Konfigurationsdatei Fehler'; ru = 'Ошибка файла конфигурации'"));
	ElsIf pRC = 99 Then
		Return(NStr("en = 'Unknown error! See error log for details.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'"));
	Else
		Return("");
	EndIf;
EndFunction // pmGetErrorDescription

#EndRegion 

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, pSystemName)
	If Not ValueIsFilled(pDevice) Then
		Return Undefined;
	EndIf;
	vLock = Undefined;  
	// ACC:561-off
	Try
		// Build ActiveX object to work with
		IsConnected = AttachAddIn("CommonTemplate.AddInLocksLocstar", "Native", AddInType.Native);
		If Not IsConnected Then
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + pSystemName + ": '; en = '" + pSystemName + " door lock system connection error: '; de = '" + pSystemName + " door lock system connection error: '") + Chars.LF + ErrorDescription());
			Return Undefined;
		Endif;
		vLock = New("AddIn.Native.Locstar");
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + pSystemName + ": '; en = '" + pSystemName + " door lock system connection error: '; de = '" + pSystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;    
	// ACC:561-on
	Return vLock;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pLock)
	pLock = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pLock, pReturnCardUID)
	vCardData = New Structure();
	vData = pLock.CardData;
	vDataArr = StrSplit(vData, Char(124), False);
	For Each vDataItem In vDataArr Do
		If Left(vDataItem, 1) = "R" Then
			vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(Right(vDataItem, StrLen(vDataItem) - 1));
			If ValueIsFilled(vRoomRef) Then
				vCardData.Insert("CardRoom", vRoomRef);	
			Else
				vCardData.Insert("CardRoom", Right(vDataItem, StrLen(vDataItem) - 1));	
			EndIf;
		ElsIf Left(vDataItem, 1) = "D" Then
			vCardData.Insert("CardCheckInDate", Right(vDataItem, StrLen(vDataItem) - 1));
		ElsIf Left(vDataItem, 1) = "O" Then
			vCardData.Insert("CardCheckOutDate", Right(vDataItem, StrLen(vDataItem) - 1));
		EndIf;
	EndDo;
	vCardData.Insert("CardID", pLock.CardID);
	vCardData.Insert("CardFullName", "");
	If pReturnCardUID Then	
		If ValueIsFilled(vCardData.CardID) Then
			vIdentificationCard = tcOnServer.GetClientIdentificationCardById(vCardData.CardID);
			If ValueIsFilled(vIdentificationCard) Then
				vCheckInDate = tcOnServer.cmGetAttributeByRef(vIdentificationCard, "DateTimeFrom");
				vCheckOutDate = tcOnServer.cmGetAttributeByRef(vIdentificationCard, "DateTimeTo"); 
				If Format(vCheckInDate, "DF=yyMMddHHmm") = vCardData.CardCheckInDate And Format(vCheckOutDate, "DF=yyMMddHHmm") = vCardData.CardCheckOutDate Then
					vCardData.CardCheckInDate = vCheckInDate;
					vCardData.CardCheckOutDate = vCheckOutDate;
					vCardData.CardFullName = tcOnServer.cmGetAttributeByRef(vIdentificationCard, "Client");
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");;
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

#EndRegion
