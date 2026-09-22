
#Region Variables

// -----------------------------------------------------------------------------
Var RC_SYSTEM_ERROR Export; // Syntax error
Var RC_NO_COMMUNICATION Export; // No commucation
Var RC_NO_CONNECTION Export; // No connection
Var RC_OK Export; // Ok
Var RC_UNKNOWN Export; // Unknown
Var RC_WRONG_ROOM Export; // Wrong room
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export;  // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_USER_CANCEL Export; // User cancel

// -----------------------------------------------------------------------------
Var SystemName;
Var ENQ;
Var STX;
Var ETX;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmNewKey() Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build 1 part of command data string
	vDta1 = "";
	// Guest
	If ValueIsFilled(Guest) Then
		vDta1 = vDta1 + cmAppendBlanks(Left(Transliterate(TrimAll(Guest.FirstName), True), 15), 15);
		vDta1 = vDta1 + cmAppendBlanks(Left(Transliterate(TrimAll(Guest.LastName), True), 15), 15);
	Else
		vDta1 = vDta1 + "               ";
		vDta1 = vDta1 + "               ";		
	EndIf;
	// Room
	vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room), True), 6), 6);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room.LockCode), True), 6), 6);
			Else
				vRoomCode = "      ";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room.LockCode), True), 6), 6);
			Else
				vRoomCode = "      ";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta1 = vDta1 + vRoomCode;
	// Check in and check out dates
	vCheckInDate = CurrentSessionDate(); // Always use current date and time
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta1 = vDta1 + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta1 = vDta1 + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	// Build 2 part of command data string
	vDta2 = "001"; // Always 1 card
	// Get track 2 data if necessary
	vTrack2 = "";
	vErrorCode = GetTrack2Data(vDLSys, vTrack2, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	EndIf;
	vDta2 = vDta2 + vTrack2;
	If IsBlankString(vTrack2) Then
		vDta2 = vDta2 + "          "; // 10 blanks
	Else
		vDta2 = vDta2 + "0000000000"; // Zero credits
	EndIf;
	// Additional rooms are not supported.
	vDta2 = vDta2 + ""; // Room 2
	vDta2 = vDta2 + ""; // Room 3
	vDta2 = vDta2 + ""; // Room 4
	
	// Call API
	vErrorCode = MakeNewKey(vDLSys, vDta1, vDta2);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, vDta1 + " " + vDta2, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta1 + ", " + vDta2);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build 1 part of command data string
	vDta1 = "";
	// Guest
	vDta1 = vDta1 + "***************";
	vDta1 = vDta1 + "***************";		
	// Room
	vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room), True), 6), 6);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room.LockCode), True), 6), 6);
			Else
				vRoomCode = "      ";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = cmAppendBlanks(Left(Transliterate(TrimAll(Room.LockCode), True), 6), 6);
			Else
				vRoomCode = "      ";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta1 = vDta1 + vRoomCode;
	
	// Check in and check out dates
	vCheckInDate = CurrentSessionDate(); // Always use current date and time
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta1 = vDta1 + "************";
	vDta1 = vDta1 + "            ";
	
	// Build 2 part of command data string
	vDta2 = "001"; // Always 1 card
	// Get track 2 data if necessary
	vTrack2 = "";
	vErrorCode = GetTrack2Data(vDLSys, vTrack2, True);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	EndIf;
	vDta2 = vDta2 + vTrack2;
	If IsBlankString(vTrack2) Then
		vDta2 = vDta2 + "          "; // 10 blanks
	Else
		vDta2 = vDta2 + "0000000000"; // Zero credits
	EndIf;
	// Additional rooms are not supported.
	vDta2 = vDta2 + ""; // Room 2
	vDta2 = vDta2 + ""; // Room 3
	vDta2 = vDta2 + ""; // Room 4
	
	// Call API
	vErrorCode = AddKey(vDLSys, vDta1, vDta2);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
	Else
		WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta1 + ", " + vDta2);
		cmWriteKeyCardSecuritySystemEvent("ADD", "", Room, vDta1 + " " + vDta2, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
	EndIf;
	
	pmDisconnect(vDLSys);
	Return vErrorCode;
EndFunction //  pmAddKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel					 - CatalogRef.Hotel	 - Ref 
//  pAssignedAuthorizations	 - String	 - Type
// 
// Returns:
//  CatalogRef.DoorLockSystemAuthorizations - Catalog ref or undefined 
//
Function pmFindAuthorizations(pHotel, pAssignedAuthorizations) Export
	vAuthRef = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	DoorLockSystemAuthorizations.Ref
	|FROM
	|	Catalog.DoorLockSystemAuthorizations AS DoorLockSystemAuthorizations
	|WHERE
	|	DoorLockSystemAuthorizations.AssignedAuthorizations = &qAssignedAuthorizations
	|	AND (DoorLockSystemAuthorizations.Hotel = &qHotel
	|			OR &qIsEmptyHotel)
	|	AND (NOT DoorLockSystemAuthorizations.DeletionMark)
	|	AND (NOT DoorLockSystemAuthorizations.IsFolder)
	|ORDER BY
	|	DoorLockSystemAuthorizations.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qIsEmptyHotel", Not ValueIsFilled(pHotel));
	vQry.SetParameter("qAssignedAuthorizations", pAssignedAuthorizations);
	vQryRes = vQry.Execute().Unload();
	If vQryRes.Count() = 1 Then
		vAuthRef = vQryRes.Get(0).Ref;
	EndIf;
	Return vAuthRef;
EndFunction //  pmFindAuthorizations

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
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Build 1 part of command data string
	vDta1 = "";
	// Guest
	vDta1 = vDta1 + "               "; // 15 blanks for the guest first name
	vDta1 = vDta1 + "               "; // 15 blanks for the guest last name	
	// Room
	vDta1 = vDta1 + "******";
	// Check in and check out dates
	vDta1 = vDta1 + "            ";
	vDta1 = vDta1 + "            ";
	
	// Build 2 part of command data string
	vDta2 = "   "; // Number of copies
	vDta2 = vDta2 + "                   "; // 19 blanks for the ID card number
	vDta2 = vDta2 + "          "; // 10 blanks for the credits
	vDta2 = vDta2 + ""; // 6 blanks for the 2 room
	vDta2 = vDta2 + ""; // 6 blanks for the 3 room
	vDta2 = vDta2 + ""; // 6 blanks for the 4 room
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vDta1, vDta2, vCardDesc);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys);
	
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
		Return(NStr("ru='Не удалось установить соединение с системой " + SystemName + "!'; 
		            |de='Failed to connect to the door locks system " + SystemName + "!'; 
		            |en='Failed to connect to the door locks system " + SystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru='Система " + SystemName + " не отвечает!'; 
		            |de='" + SystemName + " system is not responding!'; 
		            |en='" + SystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru='От системы " + SystemName + " получен ответ в неизвестном формате!'; 
		            |de='" + SystemName + " system replied with unknown format!'; 
		            |en='" + SystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_USER_CANCEL Then
		Return(NStr("en='Operation was canceled by user or operation timeout was reached!';ru='Операция отменена на энкодере или закончилось время ожидания!';de='Die Operation wurde am Encoder abgebrochen oder die Wartezeit ist abgelaufen!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_SYSTEM_ERROR Then
		Return(NStr("en='Internal system error!';ru='Внутренняя системная ошибка!';de='Interner Systemfehler!'"));
	ElsIf pRC = RC_NO_COMMUNICATION Then
		Return(NStr("ru='Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |de='The encoder does not answer (failure in the communications or switched off)!'; 
		            |en='The encoder does not answer (failure in the communications or switched off)!'"));
	EndIf;		
EndFunction //  pmGetErrorDescription

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If DoorLockSystemParameters.DoGuestNamesTransliteration Or pAlways Then
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
EndFunction //  Transliterate

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "9600,N,8,1,X" by default
	// Baudrate
	If DoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(DoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
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
		vStr = vStr + ",N";
	EndIf;
	// Data length
	If ValueIsFilled(DoorLockSystemParameters.DataBits) Then
		If DoorLockSystemParameters.DataBits = Enums.DataBits.Bits8 Then
			vStr = vStr + ",8";
		ElsIf DoorLockSystemParameters.DataBits = Enums.DataBits.Bits7 Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
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
	// Xon/Xoff flow control always
	vStr = vStr + ",X";
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "CISA";
	
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
				AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(DoorLockSystemParameters.Port));
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
		Else
			AddError(NStr("ru='Подключение по протоколу TCP не поддерживается системой электронных замков " + SystemName + "!'; en='" + SystemName + " door lock system do not support TCP connection!'; de='" + SystemName + " door lock system do not support TCP connection!'"));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru='Ошибка подключения системы электронных замков " + SystemName + ": '; en='" + SystemName + " door lock system connection error: '; de='" + SystemName + " door lock system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys)
	Try
		If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
			pDLSys.Close();
		EndIf;
	Except
		AddError(NStr("ru='Ошибка отключения от системы эл. замков " + SystemName + ": '; en='" + SystemName + " system disconnect error: '; de='" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function GetTrack2Data(pDLSys, rTrack2, pAdd = False)
	rTrack2 = "                   "; // Length 19 chars
	If DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				rTrack2 = cmAppendLeftBlanks(Format(Number(TrimAll(vIDCardRef.Identifier)), "ND=14; NFD=0; NZ=; NLZ=; NG="), 19);
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
EndFunction //  GetTrack2Data	

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC)
	vErrorCode = RC_UNKNOWN;
	If pRC = "01" Then
		vErrorCode = RC_SYSTEM_ERROR;
	ElsIf pRC = "08" Then
		vErrorCode = RC_NO_COMMUNICATION;
	ElsIf pRC = "33" Then
		vErrorCode = RC_WRONG_REPLY;
	ElsIf pRC = "45" Then
		vErrorCode = RC_NO_REPLY;
	ElsIf pRC = "46" Then
		vErrorCode = RC_USER_CANCEL;
	ElsIf pRC = "34" Then
		vErrorCode = RC_WRONG_ROOM;
	EndIf;
	Return vErrorCode;
EndFunction //  GetErrorCode

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pCommandCode, pDta1, pDta2, pReply)
	vErrorCode = RC_OK;
	pReply = "";
	
	// Format command parameters
	vHotelCode = Left(TrimAll(DoorLockSystemParameters.LicenseCode), 6);
	vAuthGranted1 = "00000000";
	vAuthGranted2 = "00000000";
	If Not IsBlankString(DoorLockSystemParameters.AssignedAuthorizations) And 
	   StrLen(TrimAll(DoorLockSystemParameters.AssignedAuthorizations)) = 16 Then
		vAuthGranted1 = Left(TrimAll(DoorLockSystemParameters.AssignedAuthorizations), 8);
		vAuthGranted2 = Right(TrimAll(DoorLockSystemParameters.AssignedAuthorizations), 8);
	EndIf;
	vSourceAddress = Left(TrimAll(DoorLockSystemParameters.PCId), 2);
	vEncoderNumber = Left(TrimAll(DoorLockSystemParameters.EncoderNumber), 2);
	vOperatorName = "0000";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
		   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin) Then
			vOperatorName = cmAppendBlanks(Left(Transliterate(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.DoorLockSystemLogin), True), 4), 4);
		EndIf;
	EndIf;
	
	// Build command string for the RS232 interface
	vCmd = cmAppendBlanks(vHotelCode, 6); // Hotel code
	vCmd = vCmd + "38"; // Constant
	vCmd = vCmd + pCommandCode; // Command code
	vCmd = vCmd + vAuthGranted2; // 2 group of additional authorizations
	vCmd = vCmd + vSourceAddress; // PC number
	vCmd = vCmd + "00"; // Constant
	vCmd = vCmd + vEncoderNumber; // Encoder number
	vCmd = vCmd + vOperatorName; // Operator's name
	// Append 1 command data block
	vCmd = vCmd + pDta1; // Command data (bytes 29 - 88)
	// Append 1 group of additional authorizations
	vCmd = vCmd + vAuthGranted1;
	// Append 2 command data block
	vCmd = vCmd + pDta2; // Command data (bytes 97 - 146)
	// Add data block control characters
	vCmd = STX + vCmd + cmHexCSUM(vCmd) + ETX;
	
	// Send command and get reply
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 2 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			pReply = pDLSys.ReadStr();
			If Not IsBlankString(pReply) Then
				// Skip Xon/Xoff flow control char
				If StrLen(pReply) = 1 And CharCode(pReply) = 17 Then
					pReply = pDLSys.ReadStr();
					If IsBlankString(pReply) Then
						Return RC_NO_REPLY;
					EndIf;
				EndIf;
				// Check CSUM
				If cmCheckHexCSUM(pReply) Then
					vReadOK = True;
				EndIf;
			Else
				Return RC_NO_REPLY;
			EndIf;
			If vReadOK Then
				Break;
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vRC = Mid(pReply, 12, 2);
		If vRC <> "00" Then
			AddError(NStr("ru='Ошибка системы эл. замков " + SystemName + ": '; en='" + SystemName + " system error: '; de='" + SystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRC);
		Else
			// Retreive reply data
			If pCommandCode = "02" Then
				pReply = Mid(pReply, 14, StrLen(pReply) - 16);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDta1, pDta2)
	// Define command code
	vCommandCode = "01";
	// Using RS232 interface
	vReply = "";
	vErrorCode = CallRS232Command(pDLSys, 60000, vCommandCode, pDta1, pDta2, vReply);
	Return vErrorCode;
EndFunction //  MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pDta1, pDta2)
	// Define command code
	vCommandCode = "03";
	// Using RS232 interface
	vReply = "";
	vErrorCode = CallRS232Command(pDLSys, 60000, vCommandCode, pDta1, pDta2, vReply);
	Return vErrorCode;
EndFunction //  AddKey

// -----------------------------------------------------------------------------
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			vYear = Left(pDateStr, 4);
			vMonth = Mid(pDateStr, 5, 2);
			vDay = Mid(pDateStr, 7, 2);
			vHour = Mid(pDateStr, 9, 2);
			vMinutes = Right(pDateStr, 2);
			Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinutes), 0);
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction //  GetDate

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("CardFirstName", "");
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardAuthorizations", "");
	
	// Card parameters
	vCardData.CardFirstName = TrimAll(Mid(pCardDesc, 17, 15));
	vCardData.CardLastName = TrimAll(Mid(pCardDesc, 32, 15));
	vCardData.CardRoom = TrimAll(Mid(pCardDesc, 47, 6));
	vCardData.CardCheckInDate = GetDate(Mid(pCardDesc, 53, 12));
	vCardData.CardCheckOutDate = GetDate(Mid(pCardDesc, 65, 12));
	vCardData.CardOperator = TrimAll(Mid(pCardDesc, 1, 4));
	vCardData.AssignedAuthorizations = Mid(pCardDesc, 77, 8) + Mid(pCardDesc, 6, 8);
	// Try to retrieve card authorizations
	vAuthRef = pmFindAuthorizations(DoorLockSystemParameters.Hotel, vCardData.AssignedAuthorizations);
	If ValueIsFilled(vAuthRef) Then
		vCardData.CardAuthorizations = TrimAll(vAuthRef.Code) + " - " + TrimAll(vAuthRef.Description);
	EndIf;
	
	Return vCardData;
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDta1, pDta2, pCardDesc)
	vErrorCode = RC_OK;
	pCardDesc = "";
	// Define command
	vCommandCode = "02";
	// Send command using RS232 interface
	vReply = "";
	vErrorCode = CallRS232Command(pDLSys, 60000, vCommandCode, pDta1, pDta2, vReply);
	// Retrieve card data
	If vErrorCode = RC_OK Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
STX = Char(2);
ETX = Char(3);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 0;
RC_UNKNOWN = 100;
RC_NO_FOLIO = 101;
RC_NO_ID_CARD = 102;
RC_NO_REPLY = 103;
RC_WRONG_REPLY = 104;
RC_SYSTEM_ERROR = 105;
RC_NO_COMMUNICATION = 106;
RC_WRONG_ROOM = 113;
RC_ROOM_WITHOUT_DOOR_LOCK = 114;
RC_USER_CANCEL = 115;

#EndRegion
