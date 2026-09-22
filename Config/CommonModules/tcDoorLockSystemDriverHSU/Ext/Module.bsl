
#Region Public 

// --------------------------------------------------------------------------------
//  Creates new card for just Checked-In guest, record the data on it.
//
// Parameters:
//  pDevice			 - Structure - The Device used for encoding
//  pParameters		 - Structure - Parameters of the guest
//  rErrorMessage	 - String	 - Error description
//  pIsAddKey		 - Boolean	 - Is add key
//  pIsFirst		 - Boolean	 - Is first
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmNewKey(pDevice, pParameters, rErrorMessage, pIsAddKey = False, pIsFirst = True) Export
	vErrorCode = 0;
	vDoorLockSystemParameters = tcOnServer.cmGetAtributeAsArray(pDevice.Ref);
	
	vMinute = 60;
	
	// Check in dates
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes * vMinute;
	EndIf;
	
	// Check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * vMinute;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) Then
		Return 57;
	EndIf;
	
	vGuestName = "";
	If ValueIsFilled(pParameters.Guest) Then
		vGuestName = TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "FullName"));
	EndIf;
	
	vCardType = 0;
	If pIsAddKey Then
		vCardType = 1;
	EndIf;
	
	vOperatorName = "";
	vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
	If ValueIsFilled(vEmployeePreferences) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin")) Then
		vOperatorName = TrimAll(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"));
	Else
		vOperatorName = TrimAll(tcOnServer.cmGetCurrentUserAttribute());
	EndIf;
	
	vEncoderNumber = -1;
	If tcOnServer.IsNumber(vDoorLockSystemParameters.EncoderNumber) Then
		vEncoderNumber = Number(TrimAll(vDoorLockSystemParameters.EncoderNumber));
	EndIf;
	
	vAreas = "";
	
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAtributeAsArray(vDoorLockSystemAuthorization);
	EndIf;
	
	If ValueIsFilled(vDoorLockSystemAuthorization) And Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		If ValueIsFilled(vDoorLockSystemParameters) And Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) And vDoorLockSystemAuthorization.MergeWithDefault Then
			vAreas = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + " " + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
		Else
			vAreas = TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations);
		EndIf;
	Else
		vAreas = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	
	vRequestMap = New Structure;
	vRequestMap.Insert("room", vRoomCode);
	vRequestMap.Insert("checkInDateTime", Format(vCheckInDate, "DF='dd/MM/yyyy HH:mm'"));
	vRequestMap.Insert("checkOutDateTime", Format(vCheckOutDate, "DF='dd/MM/yyyy HH:mm'"));
	vRequestMap.Insert("guestName", vGuestName);
	vRequestMap.Insert("cardIssuer", vOperatorName);
	vRequestMap.Insert("cardType", vCardType);
	If vEncoderNumber <> -1 Then
		vRequestMap.Insert("encoder", vEncoderNumber);
	EndIf;
	vRequestMap.Insert("areas", GetAreaCodes(vAreas));
	
	vRequestBody = tcConnectedHardwareOnClientServer.MapToJson(vRequestMap);
	
	vResourceAddress = "/IssueCard";
	If pIsAddKey Then
		vResourceAddress = "/IssueJoinerCard";
	EndIf;
	
	vErrorOverflow = 54;
	vTimeOut = 5;
	
	vResponse = SendRequest(vDoorLockSystemParameters.ServerName + ":" + vDoorLockSystemParameters.Port, vResourceAddress, TrimAll(vDoorLockSystemParameters.LicenseCode), "POST", vRequestBody, vErrorCode, rErrorMessage);
	If vResponse = Undefined Then
		If pIsFirst And vErrorCode = vErrorOverflow Then
			tcOnServer.Wait(vTimeOut);
			Return pmNewKey(pDevice, pParameters, rErrorMessage, pIsAddKey, False);
		EndIf;
		
		If vErrorCode <> -1 Then
			AddError(NStr("en = 'Error issuing key card: '; de = 'Fehler bei der Kartenausstellung: '; ru = 'Ошибка выдачи карты: '") + vErrorCode + " - " + rErrorMessage);
		EndIf;
		
		Return vErrorCode;
	EndIf;
	
	vCardID = "";
	If vResponse["number"] <> Undefined Then
		vCardID = vResponse["number"];
	EndIf;
	
	If vDoorLockSystemParameters.ReturnCardUID And Not IsBlankString(vCardID) Then
		pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardID);
	EndIf;
	
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.KeyIssued'; de = 'DoorLockSystem.KeyIssued'; ru = 'СистемаЭлектронныхЗамков.ВыданКлюч'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(vCheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(vCheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
	If pIsAddKey Then
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", TrimAll(vCardID), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest);
	Else
		tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", TrimAll(vCardID), pParameters.Room, "", vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest);
	EndIf;
	
	Return vErrorCode;
EndFunction // NewKey

// --------------------------------------------------------------------------------
//  Adds new card for the exitsting room, record the data on it. Does not create new card.
//
// Parameters:
//  pDevice			 - Structure - The Device used for encoding
//  pParameters		 - Structure - Parameters of the guest
//  rErrorMessage	 - String	 - Error description
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
	Return pmNewKey(pDevice, pParameters, rErrorMessage, True);
EndFunction // AddKey

// --------------------------------------------------------------------------------
//  Read the card data
//
// Parameters:
//  rCardData	 - Structure - Ref Object. Structure which recieves the data for this card
//  pDevice		 - Structure - The Device used for encoding
//  pParameters	 - Structure - Parameters of the guest
//  pIsFirst	 - Boolean	 - Is first
// 
// Returns:
//  Number - ErrorCode of the operation, 0 is for OK
//
Function pmVerify(rCardData, pDevice, pParameters, pIsFirst = True) Export
	vErrorMessage = "";
	vErrorCode = 0;
	vDoorLockSystemParameters = tcOnServer.cmGetAtributeAsArray(pDevice.Ref);
	
	vEncoderNumber = -1;
	If tcOnServer.IsNumber(vDoorLockSystemParameters.EncoderNumber) Then
		vEncoderNumber = Number(TrimAll(vDoorLockSystemParameters.EncoderNumber));
	EndIf;
	
	vRequestBody = "";
	If vEncoderNumber <> -1 Then
		vRequestMap = New Structure;
		vRequestMap.Insert("encoder", vEncoderNumber);
		vRequestBody = tcConnectedHardwareOnClientServer.MapToJson(vRequestMap);
	EndIf;
	
	vErrorOverflow = 54;
	vTimeOut = 5;
	
	vResponse = SendRequest(vDoorLockSystemParameters.ServerName + ":" + vDoorLockSystemParameters.Port, "/ReadCard", TrimAll(vDoorLockSystemParameters.LicenseCode), "POST", vRequestBody, vErrorCode, vErrorMessage);
	If vResponse = Undefined Then
		If pIsFirst And vErrorCode = vErrorOverflow Then
			tcOnServer.Wait(vTimeOut);
			Return pmVerify(rCardData, pDevice, pParameters, False);
		EndIf;
		
		If vErrorCode <> -1 Then
			AddError(NStr("en = 'Guest checkout error: '; de = 'Fehler beim Gast-Checkout: '; ru = 'Ошибка выселение гостя: '") + vErrorCode + " - " + vErrorMessage);
		EndIf;
		
		Return vErrorCode;
	EndIf;
	
	rCardData = ParseCardDescription(vResponse);
	
	Return vErrorCode;
EndFunction

// --------------------------------------------------------------------------------
//  CheckOut the guest, binded to this card
//
// Parameters:
//  pDevice		 - Structure - The Device used for Encoding
//  pParameters	 - Structure - Parameters of the guest
//  pIsFirst	 - Boolean	 - Is first
// 
// Returns:
//  Number - ErrorCode of operation, 0 is for OK
//
Function pmCancel(pDevice, pParameters, pIsFirst = True) Export
	vErrorMessage = "";
	vErrorCode = 0;
	vDoorLockSystemParameters = tcOnServer.cmGetAtributeAsArray(pDevice.Ref);
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode")) Then
				vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode"));
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	
	If IsBlankString(vRoomCode) Then
		Return 57;
	EndIf;
	
	vOperatorName = "";
	vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
	If ValueIsFilled(vEmployeePreferences) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin")) Then
		vOperatorName = TrimAll(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"));
	Else
		vOperatorName = TrimAll(tcOnServer.cmGetCurrentUserAttribute());
	EndIf;
	
	vRequestMap = New Structure;
	vRequestMap.Insert("room", vRoomCode);
	vRequestMap.Insert("cardIssuer", vOperatorName);
	
	vRequestBody = tcConnectedHardwareOnClientServer.MapToJson(vRequestMap);
	
	vErrorOverflow = 54;
	vTimeOut = 5;
	
	vResponse = SendRequest(vDoorLockSystemParameters.ServerName + ":" + vDoorLockSystemParameters.Port, "/CheckOut", TrimAll(vDoorLockSystemParameters.LicenseCode), "POST", vRequestBody, vErrorCode, vErrorMessage);
	If vResponse = Undefined Then
		If pIsFirst And vErrorCode = vErrorOverflow Then
			tcOnServer.Wait(vTimeOut);
			Return pmCancel(pDevice, pParameters, False);
		EndIf;
		
		If vErrorCode <> -1 Then
			AddError(NStr("en = 'Guest checkout error: '; de = 'Fehler beim Gast-Checkout: '; ru = 'Ошибка выселение гостя: '") + vErrorCode + " - " + vErrorMessage);
		EndIf;
		
		Return vErrorCode;
	EndIf;
	
	Return vErrorCode;
EndFunction // Cancel

// --------------------------------------------------------------------------------
//
// Parameters:
//  pRC			 - String	 - code of existing error
//  pSystemName	 - String	 - Door Lock system name
// 
// Returns:
//  String - Description of the recieved error
//
Function pmGetErrorDescription(pRC, pSystemName) Export
	vResult = "";
	pRC = Format(pRC, "NZ=; NG=");
	RC_NO_CONNECTION = "-1";
	RC_OK = "0";
	RC_SYNTAX = "20";
	RC_COMM = "52";
	RC_SWIPE = "64";
	RC_TBD = "TBD";
	RC_OVERFLOW = "54";
	RC_NO_CARD = "70";
	RC_UNKNOWN_ROOM = "57";
	RC_TIMEOUT_ERROR = "71";
	RC_NOT_ARRIVED = "59";
	RC_OUT_OF_SERVICE = "60";
	RC_CARD_VALID = "62";
	RC_ONLINE_ONLY = "72";
	RC_TIME_ERROR = "74";
	RC_NOFILES = "53";
	RC_SYNTAX = "14";
	RC_CARD = "12";
	
	If pRC = RC_NO_CONNECTION Then
		vResult = (NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		|de = 'Failed to connect to the door locks system " + pSystemName + "!'; 
		|en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = RC_SYNTAX Then
		vResult = (NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_COMM Then
		vResult = (NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		|de = 'System " + pSystemName + "  antwortet nicht!'; 
		|en = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = RC_SWIPE Then
		vResult = (NStr("en = 'Attach the card again!';de = 'Bringen Sie die Karte wieder an!'; ru = 'Приложите карту заново!'"));
	ElsIf pRC = RC_TBD Then
		vResult = (NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_OVERFLOW Then
		vResult = (NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = RC_NO_CARD Then
		vResult = (NStr("en = 'The encoder does not see the card.';de = 'Der Encoder erkennt die Karte nicht.'; ru = 'Энкодер не видит карту.'"));
	ElsIf pRC = RC_UNKNOWN_ROOM Then
		vResult = (NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_TIMEOUT_ERROR Then
		vResult = (NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = RC_NOT_ARRIVED Then
		vResult = (NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_OUT_OF_SERVICE Then
		vResult = (NStr("en = 'The requested room is under renovation!';de = 'Das gewünschte Zimmer wird gerade renoviert!'; ru = 'Запрошенная комната на ремонте!'"));
	ElsIf pRC = RC_CARD_VALID Then
		vResult = (NStr("en = 'An attempt to write a guest card to the staff master card!';de = 'Ein Versuch, eine Gästekarte auf die Personalstammkarte zu schreiben!'; ru = 'Попыткa записать карту гостя на мастер карту персонала!'"));
	ElsIf pRC = RC_ONLINE_ONLY Then
		vResult = (NStr("en = 'Not for offline system – only online. The command is only supported by the online HTLock system.';de = 'Nicht für ein Offline-System – nur online. Der Befehl wird nur vom Online-HTLock-System unterstützt.'; ru = 'Hе для автономной системы – только онлайн. Команда поддерживается только онлайн системой HTLock.'"));
	ElsIf pRC = RC_TIME_ERROR Then
		vResult = (NStr("en = 'Conflicting check-in and check-out date parameters.';de = 'Widersprüchliche Check-in- und Check-out-Datumsparameter.'; ru = 'Противоречивые параметры даты заселения и выезда.'"));
	ElsIf pRC = RC_NOFILES Then
		vResult = (NStr("en = 'The Door Lock system database is damage or missing!';de = 'Die Datenbank des Türschlosssystems ist beschädigt oder fehlt!'; ru = 'База данных замковой системы повреждена или не найдена!'"));
	ElsIf pRC = RC_SYNTAX Then
		vResult = (NStr("en = 'The Server recieved unknown or wrong command!';de = 'Der Server hat einen unbekannten oder falschen Befehl erhalten!'; ru = 'Сервер получил неверную или неизвестную команду!'"));
	ElsIf pRC = RC_CARD Then
		vResult = (NStr("en = 'The card is empty or incorrectly placed on the encoder!';de = 'Die Karte ist leer oder falsch auf dem Encoder platziert!'; ru = 'Карта пустая или неправильно положена на энкодер!'"));
	Else
		vResult = (NStr("en='Unknown error!';ru='Неизвестная ошибка!';de='Unbekannter Fehler!'"));
	EndIf;
	Return vResult;
EndFunction // GetErrorDescription

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en = 'DoorLockSystem.Error'; de = 'DoorLockSystem.Error'; ru = 'СистемаЭлектронныхЗамков.Ошибка'"), "Warning", , , pErrorText);
EndProcedure // AddError

// --------------------------------------------------------------------------------
Function GetAreaCodes(pAssignedAuthorizations)
	vAreas = "";
	
	vAssignedAuthorizationsArr = StrSplit(pAssignedAuthorizations, " ", False);
	For Each vArea In vAssignedAuthorizationsArr Do
		If tcOnServer.IsNumber(vArea) Then
			vZone = Number(TrimAll(vArea));
			
			vZoneCode = vZone;
			If vZoneCode >= 1 And vZoneCode <= 9 Then
				vZoneCode = 49 + vZone;
			ElsIf vZoneCode >= 10 And vZoneCode <= 35 Then
				vZoneCode = 55 + vZone;
			ElsIf vZoneCode = 36 Then
				vZoneCode = 33;
			ElsIf vZoneCode >= 37 And vZoneCode <= 40 Then
				vZoneCode = -2 + vZone;
			ElsIf vZoneCode >= 41 And vZoneCode <= 48 Then
				vZoneCode = -1 + vZone;
			ElsIf vZoneCode >= 49 And vZoneCode <= 55 Then
				vZoneCode = 9 + vZone;
			ElsIf vZoneCode >= 56 And vZoneCode <= 60 Then
				vZoneCode = 35 + vZone;
			ElsIf vZoneCode = 61 Then
				vZoneCode = 123;
			ElsIf vZoneCode = 62 Then
				vZoneCode = 125;
			Else
				Continue;
			EndIf;
			
			vAreas = vAreas + Char(vZoneCode);
		Else
			vAreas = vAreas + TrimAll(vArea);
		EndIf;
	EndDo;
	
	Return vAreas;
EndFunction // GetAreaCodes

// --------------------------------------------------------------------------------
Function SendRequest(pHttpServer, pResourceAddress, pAPI, pMethod, pJSON = "", rStatusCode = 0, rMessage = "")
	Try
		vSSL = Undefined;
		If StrFind(pHttpServer, "https://") Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);
		EndIf;
		
		vHttpServer = StrReplace(StrReplace(pHttpServer, "https://", ""), "http://", "");
		
		vTimeOut = 15;
		
		vHTTPConnection = New HTTPConnection(vHttpServer, , , , , vTimeOut, vSSL);
		
		vHeaders = New Map;
		vHeaders.Insert("Content-Type", "application/json; charset=utf-8");
		vHeaders.Insert("API-KEY", pAPI);
		
		vHTTPRequest = New HTTPRequest(pResourceAddress, vHeaders);
		If Not IsBlankString(pJSON) Then
			vHTTPRequest.SetBodyFromString(pJSON);
		EndIf;
		
		vHTTPResponse = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
		
		vSuccessCode = 299;
		
		vResponseBody = vHTTPResponse.GetBodyAsString(TextEncoding.UTF8);
		If vHTTPResponse.StatusCode > vSuccessCode Then
			rMessage = vResponseBody;
			rStatusCode = -999;
			
			vResponseBodyMap = tcConnectedHardwareOnClientServer.JsonToMap(vResponseBody);
			If vResponseBodyMap <> Undefined Then
				For Each vErrorRow In vResponseBodyMap.errors Do
					rMessage = vErrorRow["message"];
					
					vErrorCode = vErrorRow["code"];
					If tcOnServer.IsNumber(vErrorCode) Then
						rStatusCode = Number(TrimAll(vErrorCode));
					EndIf;
					
					Break;
				EndDo;
			EndIf;
			
			Return Undefined;
		EndIf;
		
		Return tcConnectedHardwareOnClientServer.JsonToMap(vResponseBody);
	Except
		vErrorInfo = ErrorInfo();
		rMessage = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		AddError(NStr("en = 'Error sending request'; de = 'Fehler beim Senden der Anfrage'; ru = 'Ошибка отправки запроса'") + ErrorProcessing.DetailErrorDescription(vErrorInfo));
		rStatusCode = -1;
	EndTry; 
	
	Return Undefined;
EndFunction // SendRequest

// --------------------------------------------------------------------------------
Function ParseCardDescription(pResponse)
	vRoom = "";
	If pResponse["room"] <> Undefined Then
		vRoom = TrimAll(pResponse["room"]);
		vRoomRef = tcDoorLocksAtServer.GetRoomRefByCode(vRoom);
		If ValueIsFilled(vRoomRef) Then
			vRoom = vRoomRef;
		EndIf;
	EndIf;
	
	vCheckInDateTime = '00010101';
	If pResponse["checkInDateTime"] <> Undefined Then
		vCheckInDateTime = tcCommonFunctionOnClientServer.StringToDateByFormat("dd/MM/yyyy HH:mm", TrimAll(pResponse["checkInDateTime"]));
	EndIf;
	
	vCheckOutDateTime = '00010101';
	If pResponse["checkOutDateTime"] <> Undefined Then
		vCheckOutDateTime = tcCommonFunctionOnClientServer.StringToDateByFormat("dd/MM/yyyy HH:mm", TrimAll(pResponse["checkOutDateTime"]));
	EndIf;
	
	vCardID = "";
	If pResponse["number"] <> Undefined Then
		vCardID = TrimAll(pResponse["number"]);
	EndIf;
	
	vCardFullName = "";
	If pResponse["guestName"] <> Undefined Then
		vCardFullName = TrimAll(pResponse["guestName"]);
	EndIf;
	
	vClientRef = tcDoorLocksAtServer.GetClientRefByCardUID(vCardID, vCheckInDateTime, vCheckOutDateTime, vRoom);
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
	vCardData.Insert("CardCheckInDate", vCheckInDateTime);
	vCardData.Insert("CardCheckOutDate", vCheckOutDateTime);
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", vCardID);
	vCardData.Insert("CardFullName", vCardFullName);
	Return vCardData;
EndFunction // ParseCardDescription

#EndRegion