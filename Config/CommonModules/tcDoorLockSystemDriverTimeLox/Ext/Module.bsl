
#Region Public

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage, pAdditional = False) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;

	// Default command code
	If Not pAdditional Then
		vCommandCode = "001";
	Else
		vCommandCode = "061";
	EndIf;
	
	// Build command data string starting from room
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
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = Format(Number(vRoomCode), "ND=5; NFD=0; NZ=; NLZ=; NG=");
	// Nights
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vNights = Round((BegOfDay(vCheckOutDate) - BegOfDay(tcOnServer.cmGetServerCurrentSessionDate()))/(24*3600), 0);
	If vNights < 0 Then
		Raise NStr("en='Check-out date is earlier then current date!';ru='Дата выезда раньше текущей даты!';de='Das Abreisedatum liegt vor dem aktuellen Datum!'");
	EndIf;
	vDta = vDta + Format(vNights, "ND=3; NFD=0; NZ=; NLZ=; NG=");
	// Check-out hour
	vCheckOutHour = Hour(vCheckOutDate);
	vDta = vDta + Format(vCheckOutHour, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Number of keys
	vDta = vDta + Format(pParameters.NumberOfKeys, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"));
		If Not IsBlankString(vAssignedAuthorizations) Then
			// Common rooms
			If StrLen(TrimAll(vAssignedAuthorizations)) >= 2 Then 
				vDta = vDta + Left(TrimAll(vAssignedAuthorizations), 2);
			Else
				vDta = vDta + "00";
			EndIf;
			// Suite-info
			If StrLen(TrimAll(vAssignedAuthorizations)) >= 4 Then 
				vDta = vDta + Mid(TrimAll(vAssignedAuthorizations), 3, 2);
			Else
				vDta = vDta + "00";
			EndIf;
		Else
			vDta = vDta + "0000";
		EndIf;
	Else
		vDta = vDta + "0000";
	EndIf;
	// Issued by
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin");
			If Not IsBlankString(vDoorLockSystemLogin) Then
				vDta = vDta + Format(Number(TrimAll(vDoorLockSystemLogin)), "ND=3; NFD=0; NZ=; NLZ=; NG=");
			Else
				vDta = vDta + "000";
			EndIf;
		Else
			vDta = vDta + "000";
		EndIf;
	Else
		vDta = vDta + "000";
	EndIf;
	// Issued to
	If ValueIsFilled(pParameters.Guest) Then
		vGuestLastName = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName");
		If Not IsBlankString(vGuestLastName) Then
			vDta = vDta + Left(Transliterate(TrimAll(vGuestLastName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
		vGuestFirstName = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "FirstName");
		If Not IsBlankString(vGuestFirstName) Then
			vDta = vDta + Left(Transliterate(TrimAll(vGuestFirstName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
		vGuestSecondName = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "SecondName");
		If Not IsBlankString(vGuestSecondName) Then
			vDta = vDta + Left(Transliterate(TrimAll(vGuestSecondName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
	Else
		vDta = vDta + "000";
	EndIf;

	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, vCommandCode, pDevice, pParameters, vDoorLockSystemParameters, False, vRCList);
	If vErrorCode <> vRCList.RC_OK Then
		Return vErrorCode;
	Else
		// Get encoder number
		vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
		
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vCommandCode, vDta, vDoorLockSystemParameters, pDevice, vRCList, vCharList);
		If vErrorCode <> vRCList.RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
		Else
			For Each vItem In vCharList Do
				vDta = StrReplace(vDta, vItem.Value, "(" + vItem.Key + ")");  	
			EndDo;
			If Not pAdditional Then
				tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", "", pParameters.Room, vDta, tcOnServer.cmGetServerCurrentSessionDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
			Else
				tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", "", pParameters.Room, vDta, tcOnServer.cmGetServerCurrentSessionDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
			EndIf;
		EndIf;
		
		pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
	Return pmNewKey(pDevice, pParameters, rErrorMessage, True);	
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	Return -9999;	
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vRCList = GetErrorList();
	If pRC = vRCList.RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + pSystemName + "!';
					|de = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = vRCList.RC_UNKNOWN Then
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = vRCList.RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		            |en = '" + pSystemName + " system is not responding!';
					|de = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = vRCList.RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		            |en = '" + pSystemName + " system replied with unknown format!';
					|de = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRCList.RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRCList.RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRCList.RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = vRCList.RC_NO_OPERATOR_CARD_IN_CARD_ENCODER Then
		Return(NStr("en='No operator card in the encoder!';ru='Нет карты оператора в энкодере!';de='Es gibt keine Betreiberkarte im Encoder!'"));
	ElsIf pRC = vRCList.RC_BAD_DATA_ON_TRACK2 Then
		Return(NStr("en='Second track data eror!';ru='Ошибка в данных второй дорожки!';de='Fehler in den Daten der zweiten Spur!'"));
	ElsIf pRC = vRCList.RC_CARD_ERROR Then
		Return(NStr("en='Card error!';ru='Ошибка карты!';de='Kartenfehler!'"));
	ElsIf pRC = vRCList.RC_WRONG_UNIT_NUMBER Then
		Return(NStr("en='Wrong unit number!';ru='Неправильный номер юнита!';de='Falsche Unit-Nummer!'"));
	ElsIf pRC = vRCList.RC_NO_CONNECTION_TO_CARD_ENCODER Then
		Return(NStr("en='No connection to the card encoder!';ru='Нет связи с энкодером карт!';de='Es gibt keine Verbindung mit dem Kartenencoder!'"));
	ElsIf pRC = vRCList.RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER Then
		Return(NStr("en='Illegal function or room number!';ru='Запрещенная функция или номер комнаты!';de='Verbotene Funktion oder Zimmernummer!'"));
	ElsIf pRC = vRCList.RC_TIMEOUT_ERROR Then
		Return(NStr("en='Timeout error!';ru='Вышло время ожидания завершения операции!';de='Die Wartezeit für das Schließen der Operation ist abgelaufen!'"));
	ElsIf pRC = vRCList.RC_NO_DEFINED_ROOM Then
		Return(NStr("en='No defined room!';ru='Не указан номер комнаты!';de='Die Zimmernummer ist nicht angegeben!'"));
	ElsIf pRC = vRCList.RC_DATA_ERROR Then
		Return(NStr("en='Data error!';ru='Ошибка в данных!';de='Datenfehler!'"));
	ElsIf pRC = vRCList.RC_NOT_SUPPORTED Then
		Return(NStr("en = 'Not supported!'; de = 'Nicht unterstützt!'; ru = 'Не поддерживается оборудованием!'"));
	EndIf;	
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function ReadString(pDLSys, pBytesRcv = 1)
	vReply = "";
	While pBytesRcv > 0 Do
		vChar = 0;
		pBytesRcv = pDLSys.Read(vChar, 1);
		If pBytesRcv > 0 Then
			vReply = vReply+Char(vChar);
		EndIf;
	EndDo;
	Return vReply;
EndFunction // ReadString

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr)
	vStr = Upper(pStr);
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
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString(pDoorLockSystemParameters)
	vStr = ""; // "4800,N,8,1" by default
	// Baudrate
	If pDoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(pDoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "4800";
	EndIf;
	// Parity
	If ValueIsFilled(pDoorLockSystemParameters.Parity) Then
		If pDoorLockSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Even") Then
			vStr = vStr + ",E";
		ElsIf pDoorLockSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Odd") Then
			vStr = vStr + ",O";
		ElsIf pDoorLockSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.None") Then
			vStr = vStr + ",N";
		ElsIf pDoorLockSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Mark") Then
			vStr = vStr + ",M";
		ElsIf pDoorLockSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Space") Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",E";
	EndIf;
	// Data length
	If ValueIsFilled(pDoorLockSystemParameters.DataBits) Then
		If pDoorLockSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
			vStr = vStr + ",8";
		ElsIf pDoorLockSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",7";
	EndIf;
	// Stop bits
	If ValueIsFilled(pDoorLockSystemParameters.StopBits) Then
		If pDoorLockSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits1") Then
			vStr = vStr + ",1";
		ElsIf pDoorLockSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits2") Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function pmConnect(pDevice, pDoorLockSystemParameters)
	// Fill system name
	vSystemName = String(pDevice.SystemName);
	// ACC:561-off	
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
		Try
			If Not ValueIsFilled(pDoorLockSystemParameters) Then
				Return Undefined;
			EndIf;
			
			// Build ActiveX object to work with
			If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
			   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
				vDLSys = New COMObject("SPort.SPortAx.1");
				// Set connection parameters
				vDLSys.InitString(GetCOMPortConnectionString(pDoorLockSystemParameters));
				// Open COM port
				vIsOpen = vDLSys.Open(TrimAll(pDoorLockSystemParameters.Port));
				If Not vIsOpen Then
					AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(pDoorLockSystemParameters.Port));
					Return Undefined;
				EndIf;
				// Set block mode
				vDLSys.BlockMode = True;
				// Setup timeouts
				vDLSys.TimeoutReadInterval = 15000;
				vDLSys.TimeoutReadTotalConstant = 1500;
				vDLSys.TimeoutReadTotalMultiplier = 15000;
				vDLSys.TimeoutWriteTotalConstant = 3000;
				vDLSys.TimeoutWriteTotalMultiplier = 100;
			ElsIf ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
			      pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.FileExchange") Then
				// Check that exchange folder is filled
				If IsBlankString(pDoorLockSystemParameters.ExchangeFolder) Then
					AddError(NStr("en='Exchange catalog is not defined!';ru='Каталог обмена не указан!';de='Der Austauschkatalog ist nicht angegeben!'"));
					Return Undefined;
				EndIf;
				// Check that exchange folder exists
				vDLSys = New File(TrimAll(pDoorLockSystemParameters.ExchangeFolder));
				If Not tcCommonFunctionOnClientServer.cmExists(vDLSys) Then
					AddError(NStr("en='Failed to open catalog: ';ru='Каталог обмена не найден! Проверьте путь: ';de='Austauschkatalog nicht gefunden! Prüfen Sie den Pfad:'") + TrimAll(pDoorLockSystemParameters.ExchangeFolder));
					Return Undefined;
				EndIf;
				// Check that path is folder
				If Not vDLSys.IsDirectory() Then
					AddError(NStr("en='Specify exchange catalog, not file!';ru='В качестве каталога обмена указан файл, а не директория!';de='Als Austauschkatalog wurde eine Datei und kein Ordner angegeben!'"));
					Return Undefined;
				EndIf;
				// Build exchange folder name
				vExchangeFolder = TrimAll(vDLSys.FullName);
				vExchangeFolder = StrReplace(vExchangeFolder, "/", "\");
				If Right(vExchangeFolder, 1) <> "\" Then
					vExchangeFolder = vExchangeFolder + "\";
				EndIf;
				// Check user rights to write/delete files to the exchange folder
				Try
					vTmpFile = New TextDocument();
					vTmpFile.AddLine("Testing user rights...");
					vTmpFileName = String(New UUID()) + ".txt";
					vTmpFile.Write(vExchangeFolder + vTmpFileName, "US-ASCII");
					DeleteFiles(vExchangeFolder + vTmpFileName);
				Except
					AddError(NStr("en='Write/delete files in the exchange catalog error! Error description: ';ru='Ошибка доступа к каталогу обмена! Описание ошибки: ';de='Fehler bei Zugang zum Austauschkatalog! Fehlerbeschreibung: '") + ErrorDescription());
					Return Undefined;
				EndTry;
			Else
				AddError(NStr("ru = 'Подключение по протоколам TCP и USB не поддерживается системой электронных замков " + vSystemName + "!'; 
							  |en = '" + vSystemName + " door lock system do not support TCP or USB connection!';
							  |de = '" + vSystemName + " door lock system do not support TCP or USB connection!'"));
				Return Undefined;
			EndIf;
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; 
						  |en = '" + vSystemName + " door lock system connection error: ';
						  |de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF  
	// ACC:561-on
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters)
	Try
		If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
		   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
			pDLSys.Close();
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system disconnect error: '; de = '" + pDevice.SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pCommandCode, pDevice, pParameters, pDoorLockSystemParameters, pAdd = False, pRCList)
	If pDoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				If pDoorLockSystemParameters.WriteTrack2 Then
					vTrack2 = Format(tcOnServer.cmGetAttributeByRef(vIDCardRef, "Identifier"), "ND=12; NFD=0; NZ=; NLZ=; NG=");
					pDta = pDta + "12" + vTrack2;
					// Change command code
					If pCommandCode = "001" Then
						pCommandCode = "003"; // New card with track 2 data
					Else
						pCommandCode = "063"; // Additional card with track 2 data
					EndIf;
				EndIf;
			Else
				vErrorCode = pRCList.RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = pRCList.RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return pRCList.RC_OK;
EndFunction // AddTrack2

// -----------------------------------------------------------------------------
Function WriteCommand2File(pDLSys, pReadTimeout = 30, pEncoderNumber, pCommandCode, pDta, pDevice, pRCList, pCharList)
	// Format encoder number and source address   
	// ACC:561-off
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Get command length
	vCommandLength = "031";
	If pCommandCode = "003" Or pCommandCode = "063" Then
		vCommandLength = "045";
	EndIf;
	// Build command string for the RS232 interface
	vCmd = vCommandLength; // Command length
	vCmd = vCmd + vEncoderNumber; // Destination address
	vCmd = vCmd + pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + "#"; // End of command data
	vCmd = pCharList.STX + vCmd + HexLRC(vCmd) + pCharList.ETX;
	// Build exchange folder name
	vExchangeFolder = TrimAll(pDLSys.FullName);
	vExchangeFolder = StrReplace(vExchangeFolder, "/", "\");
	If Right(vExchangeFolder, 1) <> "\" Then
		vExchangeFolder = vExchangeFolder + "\";
	EndIf;
	// Purge exchange folder
	Try
		DeleteFiles(vExchangeFolder + "KEYCASH1.DAT");
		DeleteFiles(vExchangeFolder + "ANSCASH1.DAT");
	Except
	EndTry;
	// Write command to the exchange file and get reply
	vCmdText = New TextDocument();
	vCmdText.SetText(vCmd);
	vCmdText.Write(vExchangeFolder + "KEYCASH1.DAT", "US-ASCII");
	// Read reply for 30 seconds
	vReply = "";
	vCurrentDate = tcOnServer.cmGetServerCurrentSessionDate();
	While (tcOnServer.cmGetServerCurrentSessionDate() - vCurrentDate) <= pReadTimeout Do
		// Check file with reply
		vReplyFile = New File(vExchangeFolder + "ANSCASH1.DAT");
		If tcCommonFunctionOnClientServer.cmExists(vReplyFile) And vReplyFile.IsFile() Then
			vCmdReply = New TextDocument();
			vCmdReply.Read(vExchangeFolder + "ANSCASH1.DAT", "US-ASCII");
			vReply = vCmdReply.GetText();
			Break;
		EndIf;
	EndDo;
	If IsBlankString(vReply) Then
		Return pRCList.RC_NO_CONNECTION;
	ElsIf StrLen(vReply) <> 7 Then
		Return pRCList.RC_WRONG_REPLY;
	Else
		vOperationStatus = Mid(vReply, 4, 1);
		If vOperationStatus = "1" Then
			Return pRCList.RC_NO_OPERATOR_CARD_IN_CARD_ENCODER;
		ElsIf vOperationStatus = "2" Then
			Return pRCList.RC_BAD_DATA_ON_TRACK2;
		ElsIf vOperationStatus = "3" Then
			Return pRCList.RC_CARD_ERROR;
		ElsIf vOperationStatus = "4" Then
			Return pRCList.RC_WRONG_UNIT_NUMBER;
		ElsIf vOperationStatus = "5" Then
			Return pRCList.RC_NO_CONNECTION_TO_CARD_ENCODER;
		ElsIf vOperationStatus = "6" Then
			Return pRCList.RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER;
		ElsIf vOperationStatus = "7" Then
			Return pRCList.RC_TIMEOUT_ERROR;
		ElsIf vOperationStatus = "8" Then
			Return pRCList.RC_NO_DEFINED_ROOM;
		EndIf;
	EndIf;        
	// ACC:561-on
	// Return success
	Return pRCList.RC_OK;
EndFunction // WriteCommand2File

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 3000, pEncoderNumber, pCommandCode, pDta, pDevice, pRCList, pCharList)
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Get command length
	vCommandLength = "031";
	If pCommandCode = "003" Or pCommandCode = "063" Then
		vCommandLength = "045";
	EndIf;
	// Build command string for the RS232 interface
	vCmd = vCommandLength; // Command length
	vCmd = vCmd + vEncoderNumber; // Destination address
	vCmd = vCmd + pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + "#"; // End of command data
	vCmd = pCharList.STX + vCmd + HexLRC(vCmd) + pCharList.ETX;
	// Send command and get acknowledgement
	For i = 1 To 3 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = ReadString(pDLSys, 1);
			If vReply = pCharList.ACK Then
				Break;
			Else
				If vReply <> pCharList.NAK Then
					Return pRCList.RC_NO_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return pRCList.RC_NO_CONNECTION;
		EndIf;
	EndDo;
	pDLSys.PurgeQueue();
	If vReply = pCharList.NAK Then
		Return pRCList.RC_DATA_ERROR;
	EndIf;
	// Return success
	Return pRCList.RC_OK;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pCommandCode, pDta, pDoorLockSystemParameters, pDevice, pRCList, pCharList)
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 3000, pEncoderNumber, pCommandCode, pDta, pDevice, pRCList, pCharList);
	ElsIf ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
		pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.FileExchange") Then
		// Using TCP/IP interface
		vErrorCode = WriteCommand2File(pDLSys, 30, pEncoderNumber, pCommandCode, pDta, pDevice, pRCList, pCharList);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function HexLRC(pStr)
	vBinLRC = "00000000";
	For i = 1 To StrLen(pStr) Do
		vBinLRC = XOR(vBinLRC, Dec2Bin(CharCode(Mid(pStr, i, 1))));
	EndDo;
	Return Bin2Hex(vBinLRC);
EndFunction // HexLRC

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
Function Bin2Hex(Val pBin)
	vHex = "";
	// Build conversion map
	vHexStruct = New Map();
	vHexStruct.Insert("0000", "0");
	vHexStruct.Insert("0001", "1");
	vHexStruct.Insert("0010", "2");
	vHexStruct.Insert("0011", "3");
	vHexStruct.Insert("0100", "4");
	vHexStruct.Insert("0101", "5");
	vHexStruct.Insert("0110", "6");
	vHexStruct.Insert("0111", "7");
	vHexStruct.Insert("1000", "8");
	vHexStruct.Insert("1001", "9");
	vHexStruct.Insert("1010", "A");
	vHexStruct.Insert("1011", "B");
	vHexStruct.Insert("1100", "C");
	vHexStruct.Insert("1101", "D");
	vHexStruct.Insert("1110", "E");
	vHexStruct.Insert("1111", "F");
	// Convert binary string to the length divided by 4
	vLen = StrLen(pBin);
	vNewLen = Int(vLen/4);
	If vNewLen <> vLen/4 Then
		vNewLen = vNewLen + 1;
	EndIf;
	vNewLen = vNewLen*4;
	pBin = Format(Number(pBin), "ND=" + vNewLen + "; NFD=0; NZ=; NLZ=; NG=");
	For i = 1 To vNewLen/4 Do
		vHex = vHex + vHexStruct.Get(Mid(pBin, 1+4*(i-1), 4));
	EndDo;
	Return vHex;
EndFunction // cmBin2Hex

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_UNKNOWN", 49);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 56);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", -2);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_NO_ID_CARD", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_NO_OPERATOR_CARD_IN_CARD_ENCODER", 201);
	vErrorList.Insert("RC_BAD_DATA_ON_TRACK2", 202);
	vErrorList.Insert("RC_CARD_ERROR", 203);
	vErrorList.Insert("RC_WRONG_UNIT_NUMBER", 204);
	vErrorList.Insert("RC_NO_CONNECTION_TO_CARD_ENCODER", 205);
	vErrorList.Insert("RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER", 206);
	vErrorList.Insert("RC_TIMEOUT_ERROR", 207);
	vErrorList.Insert("RC_NO_DEFINED_ROOM", 208);
	vErrorList.Insert("RC_DATA_ERROR", 209);
	vErrorList.Insert("RC_NOT_SUPPORTED", -9999);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function GetCharList()
	vCharList = New Structure();
	vCharList.Insert("ENQ", Char(5));
	vCharList.Insert("ACK", Char(6));
	vCharList.Insert("NAK", Char(21));
	vCharList.Insert("STX", Char(2));
	vCharList.Insert("ETX", Char(3));
	vCharList.Insert("DLE", Char(16));
	Return vCharList; 
EndFunction // GetErrorList


#EndRegion

