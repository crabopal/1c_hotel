
#Region Variables

Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

// -----------------------------------------------------------------------------
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknown
Var RC_DEVICE_TIME_OUT Export; // Device time out
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id car
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_NO_OPERATOR_CARD_IN_CARD_ENCODER Export; // No Operator card in card encoder
Var RC_BAD_DATA_ON_TRACK2 Export; // Bad data on track2
Var RC_CARD_ERROR Export; // Card error
Var RC_WRONG_UNIT_NUMBER Export; // Wrong unit number
Var RC_NO_CONNECTION_TO_CARD_ENCODER Export; // No connection
Var RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER Export; // Illegal function or room number
Var RC_TIMEOUT_ERROR Export; // Time out error
Var RC_NO_DEFINED_ROOM Export; // No defined room
Var RC_DATA_ERROR Export; // Data error

// -----------------------------------------------------------------------------
Var SystemName;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAdditional	 - Boolean	 - Is additional key
// 
// Returns:
//  String - Error code
//
Function pmNewKey(pAdditional = False) Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Default command code
	If Not pAdditional Then
		vCommandCode = "001";
	Else
		vCommandCode = "061";
	EndIf;
	
	// Build command data string starting from room
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
	vDta = Format(Number(vRoomCode), "ND=5; NFD=0; NZ=; NLZ=; NG=");
	// Nights
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vNights = Round((BegOfDay(vCheckOutDate) - BegOfDay(CurrentSessionDate()))/(24*3600), 0);
	If vNights < 0 Then
		Raise NStr("en='Check-out date is earlier then current date!';ru='Дата выезда раньше текущей даты!';de='Das Abreisedatum liegt vor dem aktuellen Datum!'");
	EndIf;
	vDta = vDta + Format(vNights, "ND=3; NFD=0; NZ=; NLZ=; NG=");
	// Check-out hour
	vCheckOutHour = Hour(vCheckOutDate);
	vDta = vDta + Format(vCheckOutHour, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Number of keys
	vDta = vDta + Format(NumberOfKeys, "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
		// Common rooms
		If StrLen(TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations)) >= 2 Then 
			vDta = vDta + Left(TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations), 2);
		Else
			vDta = vDta + "00";
		EndIf;
		// Suite-info
		If StrLen(TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations)) >= 4 Then 
			vDta = vDta + Mid(TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations), 3, 2);
		Else
			vDta = vDta + "00";
		EndIf;
	Else
		vDta = vDta + "0000";
	EndIf;
	// Issued by
	If ValueIsFilled(SessionParameters.CurrentUser) And 
	   ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
		If Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vDta = vDta + Format(Number(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin)), "ND=3; NFD=0; NZ=; NLZ=; NG=");
		Else
			vDta = vDta + "000";
		EndIf;
	Else
		vDta = vDta + "000";
	EndIf;
	// Issued to
	If ValueIsFilled(Guest) Then
		If Not IsBlankString(Guest.LastName) Then
			vDta = vDta + Left(Transliterate(TrimAll(Guest.LastName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
		If Not IsBlankString(Guest.FirstName) Then
			vDta = vDta + Left(Transliterate(TrimAll(Guest.FirstName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
		If Not IsBlankString(Guest.SecondName) Then
			vDta = vDta + Left(Transliterate(TrimAll(Guest.SecondName)), 1);
		Else
			vDta = vDta + "0";
		EndIf;
	Else
		vDta = vDta + "000";
	EndIf;
	
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, vCommandCode, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vCommandCode, vDta);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If Not pAdditional Then
				WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
			Else
				WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				cmWriteKeyCardSecuritySystemEvent("ADD", "", Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
			EndIf;
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	Return pmNewKey(True);
EndFunction // pmAddKey 
	
// -----------------------------------------------------------------------------
//
// Parameters:
//  pRC	 - String - Return code
// 
// Returns:
//  String - Error description
//
Function pmGetErrorDescription(pRC) Export
	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + SystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + SystemName + "!';
					|de = 'Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + SystemName + " не отвечает!'; 
		            |en = '" + SystemName + " system is not responding!';
					|de = '" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |en = '" + SystemName + " system replied with unknown format!';
					|de = '" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_NO_OPERATOR_CARD_IN_CARD_ENCODER Then
		Return(NStr("en='No operator card in the encoder!';ru='Нет карты оператора в энкодере!';de='Es gibt keine Betreiberkarte im Encoder!'"));
	ElsIf pRC = RC_BAD_DATA_ON_TRACK2 Then
		Return(NStr("en='Second track data eror!';ru='Ошибка в данных второй дорожки!';de='Fehler in den Daten der zweiten Spur!'"));
	ElsIf pRC = RC_CARD_ERROR Then
		Return(NStr("en='Card error!';ru='Ошибка карты!';de='Kartenfehler!'"));
	ElsIf pRC = RC_WRONG_UNIT_NUMBER Then
		Return(NStr("en='Wrong unit number!';ru='Неправильный номер юнита!';de='Falsche Unit-Nummer!'"));
	ElsIf pRC = RC_NO_CONNECTION_TO_CARD_ENCODER Then
		Return(NStr("en='No connection to the card encoder!';ru='Нет связи с энкодером карт!';de='Es gibt keine Verbindung mit dem Kartenencoder!'"));
	ElsIf pRC = RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER Then
		Return(NStr("en='Illegal function or room number!';ru='Запрещенная функция или номер комнаты!';de='Verbotene Funktion oder Zimmernummer!'"));
	ElsIf pRC = RC_TIMEOUT_ERROR Then
		Return(NStr("en='Timeout error!';ru='Вышло время ожидания завершения операции!';de='Die Wartezeit für das Schließen der Operation ist abgelaufen!'"));
	ElsIf pRC = RC_NO_DEFINED_ROOM Then
		Return(NStr("en='No defined room!';ru='Не указан номер комнаты!';de='Die Zimmernummer ist nicht angegeben!'"));
	ElsIf pRC = RC_DATA_ERROR Then
		Return(NStr("en='Data error!';ru='Ошибка в данных!';de='Datenfehler!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

#EndRegion

#Region Private

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
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='СистемаЭлектронныхЗамков.Ошибка'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "4800,N,8,1" by default
	// Baudrate
	If DoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(DoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "4800";
	EndIf;
	// Parity
	If ValueIsFilled(DoorLockSystemParameters.Parity) Then
		If DoorLockSystemParameters.Parity = Enums.ParityTypes.Even Then
			vStr = vStr + ",E";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Odd Then
			vStr = vStr + ",O";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.None Then
			vStr = vStr + ",N";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Mark Then
			vStr = vStr + ",M";
		ElsIf DoorLockSystemParameters.Parity = Enums.ParityTypes.Space Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",E";
	EndIf;
	// Data length
	If ValueIsFilled(DoorLockSystemParameters.DataBits) Then
		If DoorLockSystemParameters.DataBits = Enums.DataBits.Bits8 Then
			vStr = vStr + ",8";
		ElsIf DoorLockSystemParameters.DataBits = Enums.DataBits.Bits7 Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",7";
	EndIf;
	// Stop bits
	If ValueIsFilled(DoorLockSystemParameters.StopBits) Then
		If DoorLockSystemParameters.StopBits = Enums.StopBits.Bits1 Then
			vStr = vStr + ",1";
		ElsIf DoorLockSystemParameters.StopBits = Enums.StopBits.Bits2 Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "TimeLox 2300";
	
	Try
		If Not ValueIsFilled(DoorLockSystemParameters) Then
			Return Undefined;
		EndIf;
		
		// Build ActiveX object to work with
		vDLSys = Undefined;
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			vDLSys = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			vDLSys.InitString(GetCOMPortConnectionString());
			// Open COM port
			vIsOpen = vDLSys.Open(TrimAll(DoorLockSystemParameters.Port));
			If Not vIsOpen Then
				AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(DoorLockSystemParameters.Port));
				Return Undefined;
			EndIf;
			// Set block mode
			vDLSys.BlockMode = True;
			// Setup timeouts
			vDLSys.TimeoutReadInterval = 1000;
			vDLSys.TimeoutReadTotalConstant = 3000;
			vDLSys.TimeoutReadTotalMultiplier = 100;
			vDLSys.TimeoutWriteTotalConstant = 3000;
			vDLSys.TimeoutWriteTotalMultiplier = 100;
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.FileExchange Then
			// Check that exchange folder is filled
			If IsBlankString(DoorLockSystemParameters.ExchangeFolder) Then
				AddError(NStr("en='Exchange catalog is not defined!';ru='Каталог обмена не указан!';de='Der Austauschkatalog ist nicht angegeben!'"));
				Return Undefined;
			EndIf;
			// Check that exchange folder exists
			vDLSys = New File(TrimAll(DoorLockSystemParameters.ExchangeFolder));
			If Not tcCommonFunctionOnClientServer.cmExists(vDLSys) Then
				AddError(NStr("en='Failed to open catalog: ';ru='Каталог обмена не найден! Проверьте путь: ';de='Austauschkatalog nicht gefunden! Prüfen Sie den Pfad:'") + TrimAll(DoorLockSystemParameters.ExchangeFolder));
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
			AddError(NStr("ru = 'Подключение по протоколам TCP и USB не поддерживается системой электронных замков " + SystemName + "!'; 
						  |en = '" + SystemName + " door lock system do not support TCP or USB connection!';
						  |de = '" + SystemName + " door lock system do not support TCP or USB connection!'"));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
					  |en = '" + SystemName + " door lock system connection error: ';
					  |de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			pDLSys.Close();
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pCommandCode, pAdd = False)
	If DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				If DoorLockSystemParameters.WriteTrack2 Then
					vTrack2 = Format(vIDCardRef.Identifier, "ND=12; NFD=0; NZ=; NLZ=; NG=");
					pDta = pDta + "12" + vTrack2;
					// Change command code
					If pCommandCode = "001" Then
						pCommandCode = "003"; // New card with track 2 data
					Else
						pCommandCode = "063"; // Additional card with track 2 data
					EndIf;
				EndIf;
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return RC_OK;
EndFunction // AddTrack2

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 3000, pEncoderNumber, pCommandCode, pDta)
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
	vCmd = STX + vCmd + cmHexLRC(vCmd) + ETX;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = ACK Then
				Break;
			Else
				If vReply <> NAK Then
					Return RC_NO_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	pDLSys.PurgeQueue();
	If vReply = NAK Then
		Return RC_DATA_ERROR;
	EndIf;
	// Return success
	Return RC_OK;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function WriteCommand2File(pDLSys, pReadTimeout = 30, pEncoderNumber, pCommandCode, pDta)
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
	vCmd = STX + vCmd + cmHexLRC(vCmd) + ETX;
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
	vCurrentDate = CurrentSessionDate();
	While (CurrentSessionDate() - vCurrentDate) <= pReadTimeout Do
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
		Return RC_NO_CONNECTION;
	ElsIf StrLen(vReply) <> 7 Then
		Return RC_WRONG_REPLY;
	Else
		vOperationStatus = Mid(vReply, 4, 1);
		If vOperationStatus = "1" Then
			Return RC_NO_OPERATOR_CARD_IN_CARD_ENCODER;
		ElsIf vOperationStatus = "2" Then
			Return RC_BAD_DATA_ON_TRACK2;
		ElsIf vOperationStatus = "3" Then
			Return RC_CARD_ERROR;
		ElsIf vOperationStatus = "4" Then
			Return RC_WRONG_UNIT_NUMBER;
		ElsIf vOperationStatus = "5" Then
			Return RC_NO_CONNECTION_TO_CARD_ENCODER;
		ElsIf vOperationStatus = "6" Then
			Return RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER;
		ElsIf vOperationStatus = "7" Then
			Return RC_TIMEOUT_ERROR;
		ElsIf vOperationStatus = "8" Then
			Return RC_NO_DEFINED_ROOM;
		EndIf;
	EndIf;
	// Return success
	Return RC_OK;
EndFunction // WriteCommand2File

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pCommandCode, pDta)
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 3000, pEncoderNumber, pCommandCode, pDta);
	ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.FileExchange Then
		// Using file exchange folder
		vErrorCode = WriteCommand2File(pDLSys, 30, pEncoderNumber, pCommandCode, pDta);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 0;
RC_UNKNOWN = 49;
RC_DEVICE_TIME_OUT = 56;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_WRONG_REPLY = 104;
RC_NO_OPERATOR_CARD_IN_CARD_ENCODER = 201;
RC_BAD_DATA_ON_TRACK2 = 202;
RC_CARD_ERROR = 203;
RC_WRONG_UNIT_NUMBER = 204;
RC_NO_CONNECTION_TO_CARD_ENCODER = 205;
RC_ILLEGAL_FUNCTION_OR_ROOM_NUMBER = 206;
RC_TIMEOUT_ERROR = 207;
RC_NO_DEFINED_ROOM = 208;
RC_DATA_ERROR = 209;

#EndRegion
