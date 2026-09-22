
#Region Public

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	If vDoorLockSystemParameters = Undefined Then
		Return vRCList.RC_NO_SETTINGS;	
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;

	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = Left(TrimR(vLockCode), 15);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// PFC 20; transaction request delimiter
	vDta = "20";
	
	// To SAFLOK interface station number
	vToStationNumber = "00";
	vToStationNumberStr = TrimAll(vDoorLockSystemParameters.PCId); 
	If ValueIsFilled(vToStationNumberStr) And tcOnServer.IsNumber(vToStationNumberStr) Then 
		vToStationNumber = Format(Number(vToStationNumberStr), "ND=2; NFD=0; NZ=00; NLZ=; NG=");
	EndIf;
	vDta = vDta + vToStationNumber;
	
	// From SAFLOK interface station number.Always set 00
	vDta = vDta + "00";
	
	// Unique PMS terminal number or PMS interface request number
	vTerminalNumber = 001;
	vTerminalNumberStr = Left(TrimAll(vDoorLockSystemParameters.EncoderNumber), 3);
	If ValueIsFilled(vTerminalNumberStr) And tcOnServer.IsNumber(vTerminalNumberStr) Then
		vTerminalNumber = Format(Number(vTerminalNumberStr), "ND=3; NFD=0; NZ=001; NLZ=; NG=");	
	EndIf;
	vDta = vDta + vTerminalNumber; 
	
	// Transaction code (TXC) with 001 = new key and 003 = duplicate ke
	vDta = vDta + "001";

	// SAFLOK password  = seven alphanumeric characters
	vPassword = "SAFLOK "; //default
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences"); 
	If ValueIsFilled(vEmployeePreferences) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemPassword")) Then
		vPassword = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemPassword");
		While StrLen(vPassword) < 7 Do
			vPassword = vPassword + " ";	
		EndDo; 
	ElsIf ValueIsFilled(vDoorLockSystemParameters.LicenseCode) Then
		vPassword =  vDoorLockSystemParameters.LicenseCode;
		While StrLen(vPassword) < 7 Do
			vPassword = vPassword + " ";	
		EndDo;
	EndIf;	
	vDta = vDta + vPassword;
	
	vRoomCodeSize = 5;
	If vDoorLockSystemParameters.Property("IsFormatMessage74Bytes") And vDoorLockSystemParameters.IsFormatMessage74Bytes Then
		vRoomCodeSize = 15;	
	EndIf;
	
	// Room  (15 alphanumeric characters)
	While StrLen(vRoomCode) < vRoomCodeSize Do
		vRoomCode = vRoomCode + " ";	
	EndDo;
	vDta = vDta + Left(vRoomCode, vRoomCodeSize);
	
	// Key level; 1 = guest level, 2 = connecter level, 3 = multi-connector  level, 4 = limited-use level
	vDta = vDta + "1";
	
	// Encoder station number to make key(s) at (default: 01)
	vEncStationNumber = "01";
	vSplitterPos = StrFind(TrimAll(vDoorLockSystemParameters.EncoderNumber), "/");
	If vSplitterPos > 0 Then
		vEncStationNumberStr = Mid(TrimAll(vDoorLockSystemParameters.EncoderNumber), vSplitterPos + 1, 2);
		If ValueIsFilled(vEncStationNumberStr) And tcOnServer.IsNumber(vEncStationNumberStr) Then
			vEncStationNumber = Format(Number(vEncStationNumberStr), "ND=2; NFD=0; NZ=00; NLZ=; NG=");	
		EndIf;
	EndIf;
	vDta = vDta + vEncStationNumber;
	
	// Encoder LED control information (normally set to FF)
	vDta = vDta + "FF";

	// Number of keys to make 
	vDta = vDta + String(Format(pParameters.NumberOfKeys, "ND=2; NLZ="));
	
	// Calculate check-out date
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	
	// Projected check-out date 
	vDta = vDta + Format(vCheckOutDate, "DF=MMddyy");
	
	// Projected check-out time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate, "DF=HHmm");
	
	// Key expiration date 
	vDta = vDta + Format(vCheckOutDate, "DF=MMddyy");
	
	// Key expiration time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate, "DF=HHmm");
	
	// Pass number option
	vDta = vDta + "1";

	// Check and write extra access area
	// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
	// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
	vAssignedAuthorizations = "";
	
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	
	If ValueIsFilled(vDoorLockSystemAuthorization) Then 
	    vAssignedAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"));
		If ValueIsFilled(TrimAll(vAssignedAuthorizations)) Then
			If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) And tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
				vAssignedAuthorizations = Left(TrimAll(vAssignedAuthorizations) + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
			Else
				vAssignedAuthorizations = Left(TrimAll(vAssignedAuthorizations), 12);
			EndIf;
		Else
			If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) Then
				vAssignedAuthorizations = Left(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) Then
			vAssignedAuthorizations = Left(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
		EndIf;
	EndIf;
	
	vAssignedAuthorizations = TrimAll(vAssignedAuthorizations);
	
	While StrLen(vAssignedAuthorizations) < 12 Do
		vAssignedAuthorizations = "0" + vAssignedAuthorizations;	
	EndDo;
	
	vDta = vDta + Left(vAssignedAuthorizations, 12);
	
	// Add track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False, pDevice, pParameters, vDoorLockSystemParameters, vRCList);
	If vErrorCode <> vRCList.RC_OK Then
		Return vErrorCode;
	Else
				
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vDta, pParameters, vDoorLockSystemParameters, vRCList, vCharList);
		If vErrorCode <> vRCList.RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
		Else
			For Each vItem In vCharList Do
				vDta = StrReplace(vDta, vItem.Value, "(" + vItem.Key + ")");  	
			EndDo;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard, "CardUID")), ""), pParameters.Room, vDta, tcOnServer.cmGetServerCurrentSessionDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		pmDisconnect(vDLSys, pDevice);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	If vDoorLockSystemParameters = Undefined Then
		Return vRCList.RC_NO_SETTINGS;	
	EndIf;

	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(vDoorLockSystemParameters.DefaultRoom) Then
		pParameters.Room = vDoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(pParameters.Room);
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	
	// PFC 20; transaction request delimiter
	vDta = "20";
	
	// To SAFLOK interface station number
	vToStationNumber = "00";
	vToStationNumberStr = TrimAll(vDoorLockSystemParameters.PCId); 
	If ValueIsFilled(vToStationNumberStr) And tcOnServer.IsNumber(vToStationNumberStr) Then 
		vToStationNumber = Format(Number(vToStationNumberStr), "ND=2; NFD=0; NZ=00; NLZ=; NG=");
	EndIf;
	vDta = vDta + vToStationNumber;
	
	// From SAFLOK interface station number.Always set 00
	vDta = vDta + "00";
	
	// Unique PMS terminal number or PMS interface request number
	vTerminalNumber = 001;
	vTerminalNumberStr = Left(TrimAll(vDoorLockSystemParameters.EncoderNumber), 3);
	If ValueIsFilled(vTerminalNumberStr) And tcOnServer.IsNumber(vTerminalNumberStr) Then
		vTerminalNumber = Format(Number(vTerminalNumberStr), "ND=3; NFD=0; NZ=001; NLZ=; NG=");	
	EndIf;
	vDta = vDta + vTerminalNumber;
		
	// Transaction code (TXC) with 001 = new key and 003 = duplicate ke
	vDta = vDta + "003";

	// SAFLOK password  = seven alphanumeric characters
	vPassword = "SAFLOK "; //default
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences"); 
	If ValueIsFilled(vEmployeePreferences) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemPassword")) Then
		vPassword = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemPassword");
		While StrLen(vPassword) < 7 Do
			vPassword = vPassword + " ";	
		EndDo; 
	ElsIf ValueIsFilled(vDoorLockSystemParameters.LicenseCode) Then
		vPassword =  vDoorLockSystemParameters.LicenseCode;
		While StrLen(vPassword) < 7 Do
			vPassword = vPassword + " ";	
		EndDo;
	EndIf;	
	vDta = vDta + vPassword;
	
	vRoomCodeSize = 5;
	If vDoorLockSystemParameters.Property("IsFormatMessage74Bytes") And vDoorLockSystemParameters.IsFormatMessage74Bytes Then
		vRoomCodeSize = 15;	
	EndIf;
	
	// Room  (15 alphanumeric characters)
	While StrLen(vRoomCode) < vRoomCodeSize Do
		vRoomCode = vRoomCode + " ";	
	EndDo;
	vDta = vDta + Left(vRoomCode, vRoomCodeSize);
	
	// Key level; 1 = guest level, 2 = connecter level, 3 = multi-connector  level, 4 = limited-use level
	vDta = vDta + "1";
	
	// Encoder station number to make key(s) at (default: 01)
	vEncStationNumber = "01";
	vSplitterPos = StrFind(TrimAll(vDoorLockSystemParameters.EncoderNumber), "/");
	If vSplitterPos > 0 Then
		vEncStationNumberStr = Mid(TrimAll(vDoorLockSystemParameters.EncoderNumber), vSplitterPos + 1, 2);
		If ValueIsFilled(vEncStationNumberStr) And tcOnServer.IsNumber(vEncStationNumberStr) Then
			vEncStationNumber = Format(Number(vEncStationNumberStr), "ND=2; NFD=0; NZ=00; NLZ=; NG=");	
		EndIf;
	EndIf;
	vDta = vDta + vEncStationNumber;
	
	// Encoder LED control information (normally set to FF)
	vDta = vDta + "FF";

	// Number of keys to make 
	vDta = vDta + String(Format(pParameters.NumberOfKeys, "ND=2; NLZ="));
	
	// Calculate check-out date
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes * 60;
	EndIf;
	
	// Projected check-out date 
	vDta = vDta + Format(vCheckOutDate, "DF=MMddyy");
	
	// Projected check-out time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate, "DF=HHmm");
	
	// Key expiration date 
	vDta = vDta + Format(vCheckOutDate, "DF=MMddyy");
	
	// Key expiration time; military/24-hour time 
	vDta = vDta + Format(vCheckOutDate, "DF=HHmm");
	
	// Pass number option
	vDta = vDta + "1";

	// Check and write extra access area
	// Pass numbers 12 to 1; each byte  represents a pass number from 12 to 1 (pass number positions are in
	// descending order); 1 = pass, 0 = no pass; pass number 12 = 71st byte, 11 = 72nd byte…to 1 = 82nd byte
	vAssignedAuthorizations = "";
	
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	
	If ValueIsFilled(vDoorLockSystemAuthorization) Then 
	    vAssignedAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"));
		If ValueIsFilled(TrimAll(vAssignedAuthorizations)) Then
			If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) And tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
				vAssignedAuthorizations = Left(TrimAll(vAssignedAuthorizations) + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
			Else
				vAssignedAuthorizations = Left(TrimAll(vAssignedAuthorizations), 12);
			EndIf;
		Else
			If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) Then
				vAssignedAuthorizations = Left(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
			EndIf;
		EndIf;
	Else
		If ValueIsFilled(vDoorLockSystemParameters) And ValueIsFilled(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations)) Then
			vAssignedAuthorizations = Left(TrimAll(vDoorLockSystemParameters.AssignedAuthorizations), 12);
		EndIf;
	EndIf;
	
	vAssignedAuthorizations = TrimAll(vAssignedAuthorizations);
	
	While StrLen(vAssignedAuthorizations) < 12 Do
		vAssignedAuthorizations = "0" + vAssignedAuthorizations;	
	EndDo;
	
	vDta = vDta + Left(vAssignedAuthorizations, 12);
	
	// Add track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False, pDevice, pParameters, vDoorLockSystemParameters, vRCList);
	If vErrorCode <> vRCList.RC_OK Then
		Return vErrorCode;
	Else
		// Call API
		vErrorCode = AddKey(vDLSys, vDta, pParameters, vDoorLockSystemParameters, vRCList, vCharList);
		If vErrorCode <> vRCList.RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
		Else
			For Each vItem In vCharList Do
				vDta = StrReplace(vDta, vItem.Value, "(" + vItem.Key + ")");  	
			EndDo;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(pParameters.IdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.IdentificationCard, "CardUID")), ""), pParameters.Room, vDta, tcOnServer.cmGetServerCurrentSessionDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		pmDisconnect(vDLSys, pDevice);
		Return vErrorCode;
	EndIf;	
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	Return -9999;	
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vRCList = GetErrorList();
	If pRC = vRCList.RC_NO_SETTINGS Then
		Return(NStr("ru = 'Замковая система " + pSystemName + " не настроена!'; 
			            |de = 'The " + pSystemName + " locking system is not configured!'; 
			            |en = 'The " + pSystemName + " locking system is not configured!'"));	
	ElsIf pRC = vRCList.RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + pSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = vRCList.RC_UNKNOWN Then
		Return(NStr("en = 'Unknown error! See error log for details.'; ru = 'Неизвестная ошибка! Дополнительная информация сохранена в системном логе.'; de = 'Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = vRCList.RC_DEVICE_TIME_OUT Then
		Return(NStr("en = 'The reader/writer has been waiting too long for a card!'; ru = 'Закончилось время ожидания карты энкодером!'; de = 'Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = vRCList.RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en = 'No checked in guests in the room! Make new key card instead.'; ru = 'В номере нет размещенных гостей! Выдайте гостю новую карту.'; de = 'In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = vRCList.RC_WRONG_ROOM Then
		Return(NStr("en = 'Room is wrong!'; ru = 'Номер комнаты указан неверно!'; de = 'Die Zimmernummer ist falsch!'"));
	ElsIf pRC = vRCList.RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		            |de = 'System " + pSystemName + "  antwortet nicht!'; 
		            |en = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = vRCList.RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + pSystemName + " system replied with unknown format!'; 
		            |en = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRCList.RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRCList.RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRCList.RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = vRCList.RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = vRCList.RC_NO_COMMUNICATION Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		            |en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = vRCList.RC_OVERFLOW Then
		Return(NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = vRCList.RC_MAGNETIC_TRACK_ERROR Then
		Return(NStr("en='Card inserted wrongly or without magnetic stripe!';ru='Не правильно вставлена карта или карта без магнитной полосы!';de='Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'"));
	ElsIf pRC = vRCList.RC_MAGNETIC_FORMAT_ERROR Then
		Return(NStr("en='You have removed card from the encoder before operation has finished or card/magnetic strip is damaged!';ru='Возможно сняли карту с энкодера не дожидаясь окончания операции или карта/магнитная полоса повреждена!';de='Möglicherweise haben Sie die Karte von Encoder vor dem Ende der Operation genommen oder die Karte/der Magnetstreifen ist beschädigt!'"));
	ElsIf pRC = vRCList.RC_MAGNETIC_LEVEL_ERROR Then
		Return(NStr("en='The card has been encoded with a too low magnetic level due to dust in the reader magnetic head or low quality card!';ru='Низкий уровень намагничивания (возможно грязный энкодер или карта плохого качества)!';de='Niedriges Magnetisierungsniveau (möglicherweise ist der Encoder verschmutzt oder die Qualität der Karte ist schlecht)!'"));
	ElsIf pRC = vRCList.RC_CARD_MEMORY_OVERFLOW Then
		Return(NStr("en='Card memory overflow!';ru='Переполнение памяти карты!';de='Der Kartenspeicher ist voll!'"));
	ElsIf pRC = vRCList.RC_LEAST_1_KEY Then
		Return(NStr("en = 'You must request at least 1 key.'; de = 'Sie müssen mindestens 1 Schlüssel anfordern.'; ru = 'Должны запросить хотя бы 1 ключ.'"));
	ElsIf pRC = vRCList.PASSWORD_IS_INVALID Then
		Return(NStr("en = 'Your SAFLOK interface password is invalid.'; de = 'Ihr SAFLOK-Schnittstellenkennwort ist ungültig.'; ru = 'Пароль интерфейса SAFLOK недействителен.'"));
	ElsIf pRC = vRCList.RC_NOT_SUPPORTED Then
		Return(NStr("en = 'Not supported.'; de = 'Nicht unterstützt.'; ru = 'Не поддерживается.'"));
	EndIf;	
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function ReplaceControlChars(Val pStr)
	pStr = StrReplace(pStr, Char(0), "<NUL>");
	pStr = StrReplace(pStr, Char(1), "<SOH>");
	pStr = StrReplace(pStr, Char(2), "<STX>");
	pStr = StrReplace(pStr, Char(3), "<ETX>");
	pStr = StrReplace(pStr, Char(4), "<EOT>");
	pStr = StrReplace(pStr, Char(5), "<ENQ>");
	pStr = StrReplace(pStr, Char(6), "<ACK>");
	pStr = StrReplace(pStr, Char(7), "<BEL>");
	pStr = StrReplace(pStr, Char(8), "<BS>");
	pStr = StrReplace(pStr, Char(9), "<TAB>");
	pStr = StrReplace(pStr, Char(10), "<LF>");
	pStr = StrReplace(pStr, Char(11), "<VT>");
	pStr = StrReplace(pStr, Char(12), "<FF>");
	pStr = StrReplace(pStr, Char(13), "<CR>");
	pStr = StrReplace(pStr, Char(14), "<SO>");
	pStr = StrReplace(pStr, Char(15), "<SI>");
	pStr = StrReplace(pStr, Char(16), "<DLE>");
	pStr = StrReplace(pStr, Char(17), "<DC1>");
	pStr = StrReplace(pStr, Char(18), "<DC2>");
	pStr = StrReplace(pStr, Char(19), "<DC3>");
	pStr = StrReplace(pStr, Char(20), "<DC4>");
	pStr = StrReplace(pStr, Char(21), "<NAK>");
	pStr = StrReplace(pStr, Char(22), "<SYN>");
	pStr = StrReplace(pStr, Char(23), "<ETB>");
	pStr = StrReplace(pStr, Char(24), "<CAN>");
	pStr = StrReplace(pStr, Char(25), "<EM>");
	pStr = StrReplace(pStr, Char(26), "<SUB>");
	pStr = StrReplace(pStr, Char(27), "<ESC>");
	pStr = StrReplace(pStr, Char(28), "<FS>");
	pStr = StrReplace(pStr, Char(29), "<GS>");
	pStr = StrReplace(pStr, Char(30), "<RS>");
	pStr = StrReplace(pStr, Char(31), "<US>");
	pStr = StrReplace(pStr, Char(127), "<Delete>");
	Return pStr;
EndFunction // ReplaceControlChars

// -----------------------------------------------------------------------------
Function CheckCharLRC(pStr, pRet13 = True)
	vInpCharLRC = Right(pStr, 1);
	vStr = Left(pStr, StrLen(pStr) - 1);
	vNewCharLRC = CharLRC(vStr, pRet13);
	If vNewCharLRC = Char(13) Or vNewCharLRC = vInpCharLRC Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckCharLRC

// -----------------------------------------------------------------------------
Function CharLRC(pStr, pRet13 = True)
	If pRet13 Then
		Return Char(13);
	Else
		vSeed = "00000000";
		For i = 1 To StrLen(pStr) Do
			vChar = Dec2Bin(CharCode(Mid(pStr, i, 1)));
			vSeed = XOR(vSeed, vChar);
		EndDo;
		Return Char(Bin2Dec(vSeed));
	EndIf;
EndFunction // CharLRC

// -----------------------------------------------------------------------------
Function Dec2Bin(pDec)
	vBin = "";
	vDiv = pDec;
	While vDiv > 0 Do
		vIntDiv = Int(vDiv/2);
		vBinChar = "0";
		If vDiv <> vIntDiv*2 Then
			vBinChar = "1";
		EndIf;
		vBin = vBinChar + vBin;
		vDiv = vIntDiv;
	EndDo;
	Return vBin;
EndFunction // Dec2Bin

// -----------------------------------------------------------------------------
Function XOR(Val pBin1, Val pBin2)
	vXOR = "";
	// Check that parameters length is the same
	vMaxLen = Max(StrLen(pBin1), StrLen(pBin2));
	pBin1 = Format(Number(pBin1), "ND=" + vMaxLen + "; NFD=0; NZ=; NLZ=; NG=");
	pBin2 = Format(Number(pBin2), "ND=" + vMaxLen + "; NFD=0; NZ=; NLZ=; NG=");
	// Do XOR
	For i = 1 To vMaxLen Do
		vChar1 = Mid(pBin1, i, 1);
		vChar2 = Mid(pBin2, i, 1);
		If vChar1 = vChar2 Then
			vXOR = vXOR + "0";
		Else
			vXOR = vXOR + "1";
		EndIf;			
	EndDo;
	Return vXOR;
EndFunction // XOR

// -----------------------------------------------------------------------------
Function Bin2Dec(pBin)
	vDec = 0;
	vLen = StrLen(pBin);
	For i = 1 To vLen Do
		vDec = vDec + Number(Mid(pBin, i, 1)) * Pow(2, (vLen - i));
	EndDo;
	Return vDec;
EndFunction // Bin2Dec

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Procedure AddInfo(Val pInfoText, pType = "Request -> ")
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Info';ru='СистемаЭлектронныхЗамков.Информация';de='DoorLockSystem.Info'"),"Information",,, pType + ReplaceControlChars(pInfoText));
EndProcedure // AddInfo

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False, pDoorLockSystemParameters)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If pDoorLockSystemParameters.DoGuestNamesTransliteration Or pAlways Then
		vStr = StrReplace(vStr, "А", "A");
		vStr = StrReplace(vStr, "Б", "B");
		vStr = StrReplace(vStr, "В", "V");
		vStr = StrReplace(vStr, "Г", "G");
		vStr = StrReplace(vStr, "Д", "D");
		vStr = StrReplace(vStr, "Е", "E");
		vStr = StrReplace(vStr, "Ё", "E");
		vStr = StrReplace(vStr, "Ж", "GH");
		vStr = StrReplace(vStr, "З", "Z");
		vStr = StrReplace(vStr, "И", "I");
		vStr = StrReplace(vStr, "Й", "Y");
		vStr = StrReplace(vStr, "К", "K");
		vStr = StrReplace(vStr, "Л", "L");
		vStr = StrReplace(vStr, "М", "M");
		vStr = StrReplace(vStr, "Н", "N");
		vStr = StrReplace(vStr, "О", "O");
		vStr = StrReplace(vStr, "П", "P");
		vStr = StrReplace(vStr, "Р", "R");
		vStr = StrReplace(vStr, "С", "S");
		vStr = StrReplace(vStr, "Т", "T");
		vStr = StrReplace(vStr, "У", "U");
		vStr = StrReplace(vStr, "Ф", "F");
		vStr = StrReplace(vStr, "Х", "H");
		vStr = StrReplace(vStr, "Ц", "C");
		vStr = StrReplace(vStr, "Ч", "CH");
		vStr = StrReplace(vStr, "Ш", "SH");
		vStr = StrReplace(vStr, "Щ", "SCH");
		vStr = StrReplace(vStr, "Ь", "");
		vStr = StrReplace(vStr, "Ы", "YI");
		vStr = StrReplace(vStr, "Ъ", "");
		vStr = StrReplace(vStr, "Э", "E");
		vStr = StrReplace(vStr, "Ю", "YU");
		vStr = StrReplace(vStr, "Я", "YA");
	EndIf;
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function AddTrack1And2(pDLSys, pDta, pAdd = False, pDevice,  pParameters, pDoorLockSystemParameters, pRCList)
	If pDoorLockSystemParameters.WriteTrack1 Or pDoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				pParameters.IdentificationCard = vIDCardRef;
				vIDCardArr = tcOnServer.cmGetAtributeAsArray(vIDCardRef);
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If pDoorLockSystemParameters.WriteTrack1 Then
					pDta = pDta + "*";
					// Track 2 data: CardIdentifier
					If pDoorLockSystemParameters.WriteTrack2 Then
						vTrack2 = Left(TrimAll(vIDCardArr.Identifier), 35);
						pDta = pDta + "2" + Format(StrLen(vTrack2), "ND=2; NLZ=; NG=") + vTrack2;
					EndIf;
					vTrack1 = TrimAll(vIDCardArr.Identifier) + "^" +
					          ?(ValueIsFilled(vIDCardArr.Folio), Transliterate(Upper(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Folio, "Number"))), True, pDoorLockSystemParameters), "") + "^" + 
					          ?(ValueIsFilled(vIDCardArr.Room), Transliterate(Upper(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Room, "Description"))), True, pDoorLockSystemParameters), "") + "^" + 
					          ?(ValueIsFilled(vIDCardArr.Client), Transliterate(Upper(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Client, "FullName"))), True, pDoorLockSystemParameters), "") + "^" + 
					          Format(vIDCardArr.DateTimeFrom, "DF='yyMMdd'") + "^" + 
					          Format(vIDCardArr.DateTimeTo, "DF='yyMMdd'");
					vTrack1 = Left(TrimAll(vTrack1), ?(pDoorLockSystemParameters.Track1Length > 0, pDoorLockSystemParameters.Track1Length, 79));
					pDta = pDta + "1" + Format(StrLen(vTrack1), "ND=2; NLZ=; NG=") + vTrack1;
				Else
					// Track 2 data: CardIdentifier
					If pDoorLockSystemParameters.WriteTrack2 Then
						vTrack2 = Left(TrimAll(vIDCardArr.Identifier), 35);
						pDta = pDta + vTrack2;
					EndIf;
				EndIf;
			Else
				vErrorCode = pRCList.RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys, pDevice);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = pRCList.RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys, pDevice);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return pRCList.RC_OK;
EndFunction // AddTrack1And2

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, pDoorLockSystemParameters)
	// Fill system name
	vSystemName = String(pDevice.SystemName);
		
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
		Try
			If Not ValueIsFilled(pDoorLockSystemParameters) Then
				Return Undefined;
			EndIf;
			
			// Build ActiveX object to work with
			If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) Then
				Try
				    vDLSys = New COMObject("SocketTools.SocketWrench.10");
					// Load license
					vErrorCode = vDLSys.Initialize(tcDoorLocksAtServer.GetCSWSOCK10LicenseKey());
				Except
					vDLSys = New COMObject("SocketTools.SocketWrench.6");
					// Load license
					vErrorCode = vDLSys.Initialize(tcDoorLocksAtServer.GetCSWSOCK6LicenseKey());
				EndTry;
				If vErrorCode <> 0 Then
					AddError(NStr("en = 'SocketTools.SocketWrench component initialization error: '; ru = 'Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: '; de = 'Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
					Return Undefined;
				EndIf;     
				vDLSys.Blocking = True;
				vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
				vErrorCode = vDLSys.Connect(TrimAll(pDoorLockSystemParameters.ServerName), Number(TrimAll(pDoorLockSystemParameters.Port)));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; 
					              |de = '" + vSystemName + " system server was not found: '; 
					              |en = '" + vSystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf;     
			EndIf;
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; 
			              |de = '" + vSystemName + " door lock system connection error: '; 
			              |en = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice)
	Try
		vSystemName = String(pDevice.SystemName);
		vErrorCode = pDLSys.Disconnect();
		If vErrorCode <> 0 Then
			AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + vSystemName + ": '; 
			              |de = '" + vSystemName + " server disconnect error: '; 
			              |en = '" + vSystemName + " server disconnect error: '") + vErrorCode);
			Return;
		EndIf;  
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + vSystemName + ": '; 
		              |de = '" + vSystemName + " system disconnect error: '; 
		              |en = '" + vSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pDta, pWithRetention = "", pReply, pDoorLockSystemParameters, pRCList, pCharList)
	vErrorCode = pRCList.RC_OK;
	pReply = "";
	
	vCmd = pDta; // Command data
	vCmd = vCmd + pCharList.ETX;
	vCmd = pCharList.STX + vCmd + CharLRC(vCmd);
	If pDoorLockSystemParameters.Property("IsDebug") And pDoorLockSystemParameters.IsDebug Then  
		AddInfo(vCmd, "Request -> ");
	EndIf;
	// Send command and get acknowledgement
	pDLSys.Timeout = 3;
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		// Read command reply message
		vReadOK = False;
		pDLSys.Timeout = pReadTimeout;
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If pDoorLockSystemParameters.Property("IsDebug") And pDoorLockSystemParameters.IsDebug Then
				AddInfo(pReply, "Response <- ");
			EndIf;
			If Not IsBlankString(pReply) Then
				// Check LRC
				pReply = StrReplace(pReply, pCharList.STX, "");
				If CheckCharLRC(pReply) Then
					// Get error codes
					If StrLen(pReply) >= 14 Then
						vErrCode = Mid(pReply, 10, 2);
						If vErrCode = "00" Then
							vReadOK = True;
							// Get card id
							vTildaPos = StrFind(pReply, "~");
							If vTildaPos = 0 Then
								vTildaPos = 15;
							EndIf;
							pReply = Mid(pReply, vTildaPos + 1);
						Else
							vDetErrCode = Mid(pReply, 12, 3);
							pReply = vErrCode + "/" + vDetErrCode;
							If pReply = "03/190" Then
								Return pRCList.RC_DEVICE_TIME_OUT;
							ElsIf pReply = "03/000" Then
								Return pRCList.RC_NO_COMMUNICATION;
							ElsIf pReply = "03/157" Then
								Return pRCList.RC_NO_COMMUNICATION;
							ElsIf pReply = "03/050" Then
								Return pRCList.RC_OVERFLOW;
							ElsIf pReply = "03/110" Then
								Return pRCList.RC_LEAST_1_KEY;
							ElsIf pReply = "03/030" Then
								Return pRCList.PASSWORD_IS_INVALID;	
							EndIf;
						EndIf;
					Else
						Return pRCList.RC_WRONG_REPLY;
					EndIf;
				Else
					Return pRCList.RC_WRONG_REPLY;
				EndIf;
			Else
				Return pRCList.RC_NO_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pRCList.RC_NO_CONNECTION;
		EndIf;
		If Not vReadOK Then
			vErrorCode = pRCList.RC_WRONG_REPLY;
		Else
			pReply = "";
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return pRCList.RC_NO_CONNECTION;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDta, pParameters, pDoorLockSystemParameters, pRCList, pCharList)
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, 60,  pDta, "", vReply, pDoorLockSystemParameters, pRCList, pCharList);
	// Save card UID
	If vErrorCode = pRCList.RC_OK Then
		If Not IsBlankString(vReply) And pDoorLockSystemParameters.ReturnCardUID Then
			vReplyLen = StrLen(vReply);
			If vReplyLen > 3 Then
				vCardUID = vReply;
				pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pDta, pParameters, pDoorLockSystemParameters, pRCList, pCharList)
	// Using TCP/IP interface
	vReply = "";
	vErrorCode = CallTCPCommand(pDLSys, 60,  pDta, "", vReply, pDoorLockSystemParameters, pRCList, pCharList);
	// Save card UID
	If vErrorCode = pRCList.RC_OK Then
		If Not IsBlankString(vReply) And pDoorLockSystemParameters.ReturnCardUID Then
			vReplyLen = StrLen(vReply);
			If vReplyLen > 3 Then
				vCardUID = vReply;
				pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_SETTINGS", -2);
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_UNKNOWN", 100);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_NO_ID_CARD", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_SYNTAX_ERROR", 105);
	vErrorList.Insert("RC_NO_COMMUNICATION", 106);
	vErrorList.Insert("RC_OVERFLOW", 107);
	vErrorList.Insert("RC_MAGNETIC_TRACK_ERROR", 108);
	vErrorList.Insert("RC_MAGNETIC_FORMAT_ERROR", 109);
	vErrorList.Insert("RC_MAGNETIC_LEVEL_ERROR", 110);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 111);
	vErrorList.Insert("RC_NO_GUEST_PREVIOUSLY_CHECKED_IN", 112);
	vErrorList.Insert("RC_WRONG_ROOM", 113);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", 114);
	vErrorList.Insert("RC_CARD_MEMORY_OVERFLOW", 115);
	vErrorList.Insert("RC_LEAST_1_KEY", 116);
	vErrorList.Insert("PASSWORD_IS_INVALID", 117);
	vErrorList.Insert("RC_NOT_SUPPORTED", -9999);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function GetCharList()
	vCharList = New Structure();
	vCharList.Insert("STX", Char(2));
	vCharList.Insert("ETX", Char(3));
	vCharList.Insert("ENQ", Char(5));
	vCharList.Insert("ACK", Char(6));
	vCharList.Insert("DLE", Char(16));
	vCharList.Insert("NAK", Char(21));
	vCharList.Insert("SEP", Char(1110));
	Return vCharList; 
EndFunction // GetErrorList


#EndRegion

