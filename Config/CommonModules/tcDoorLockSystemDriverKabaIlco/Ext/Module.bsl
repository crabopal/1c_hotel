// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

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
Function GetWord(pStr, pTag, pCharList)
	vWord = "";
	If Not IsBlankString(pStr) Then
		vTagPos = Find(pStr, pTag);
		If vTagPos > 0 And vTagPos < Strlen(pStr) Then
			vStr = TrimAll(Mid(pStr, vTagPos + 1));
			vSEPPos = Find(vStr, pCharList.SEP);
			If vSEPPos > 1 Then
				vWord = TrimAll(Left(vStr, vSEPPos - 1));
			ElsIf vSEPPos = 0 Then
				vWord = TrimAll(vStr);
			EndIf;
		EndIf;
	EndIf;
	Return vWord;
EndFunction // GetWord

// -----------------------------------------------------------------------------
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			If StrLen(pDateStr) = 16 Then
				vYear = Left(pDateStr, 4);
				vMonth = Mid(pDateStr, 6, 2);
				vDay = Mid(pDateStr, 9, 2);
				vHour = Mid(pDateStr, 12, 2);
				vMinute = Right(pDateStr, 2);
				Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinute), 0);
			Else
				Return '00010101';
			EndIf;
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction // GetDate

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
Function RS232Acknowledgement(pDLSys, pCharList)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(pCharList.ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 2000;
		vReply = pDLSys.ReadStr();
		If vReply = pCharList.ACK Then
			Return True;
		ElsIf vReply = pCharList.NAK Then
			AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en='Wrong number of bytes sent on acknowledgement: ';ru='При подтверждении связи отправлено байт: ';de='Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction // RS232Acknowledgement

// -----------------------------------------------------------------------------
Function GetErrorCode(pRC, pRCList)
	vErrorCode = pRCList.RC_UNKNOWN;
	If pRC = "Q" Then
		vErrorCode = pRCList.RC_SYNTAX_ERROR;
	ElsIf pRC = "R" Then
		vErrorCode = pRCList.RC_VALUE_INVALID;
	ElsIf pRC = "S" Then
		vErrorCode = pRCList.RC_ENCODER_ERROR;
	ElsIf pRC = "U" Then
		vErrorCode = pRCList.RC_ROOM_IS_MISSING;
	ElsIf pRC = "V" Then
		vErrorCode = pRCList.RC_TOO_MUCH_DATA;
	ElsIf pRC = "W" Then
		vErrorCode = pRCList.RC_WRONG_ROOM;
	ElsIf pRC = "X" Then
		vErrorCode = pRCList.RC_INVALID_AUTH;
	ElsIf pRC = "Y" Then
		vErrorCode = pRCList.RC_DEVICE_TIME_OUT;
	ElsIf pRC = "Z" Then
		vErrorCode = pRCList.RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "[" Then
		vErrorCode = pRCList.RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "\" Then
		vErrorCode = pRCList.RC_DATE_OUT_OF_RANGE;
	ElsIf pRC = "]" Then
		vErrorCode = pRCList.RC_NO_INNER_DOORS;
	ElsIf pRC = "^" Then
		vErrorCode = pRCList.RC_INVALID_EXPIRY_DATE;
	ElsIf pRC = "_" Then
		vErrorCode = pRCList.RC_CARD_SWYPE_ERROR;
	ElsIf pRC = "'" Then
		vErrorCode = pRCList.RC_NO_FOLIO_NUMBER;
	ElsIf pRC = "a" Then
		vErrorCode = pRCList.RC_OPERATION_ABORTED;
	ElsIf pRC = "d" Then
		vErrorCode = pRCList.RC_WRONG_ROOM;
	ElsIf pRC = "h" Then
		vErrorCode = pRCList.RC_FUNCTION_NOT_ENABLED;
	ElsIf pRC = "p" Then
		vErrorCode = pRCList.RC_WRONG_ENCODER_NUMBER;
	ElsIf pRC = "q" Then
		vErrorCode = pRCList.RC_DEVICE_IS_BUSY;
	ElsIf pRC = "t" Then
		vErrorCode = pRCList.RC_DEVICE_NOT_RESPONDING;
	ElsIf pRC = "u" Then
		vErrorCode = pRCList.RC_COMMUNICATION_FAILURE;
	EndIf;
	Return vErrorCode;
EndFunction // GetErrorCode

// -----------------------------------------------------------------------------
Function TCPAcknowledgement(pDLSys, pCharList)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.Write(pCharList.ENQ, 1);
	If vBytesSent <> -1 Then
		pDLSys.Timeout = 2;
		vReply = "";
		If pDLSys.Read(vReply, 1) <> -1 Then
			If vReply = pCharList.ACK Then
				Return True;
			ElsIf vReply = pCharList.NAK Then
				AddError(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"));
			Else
				AddError(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
			EndIf;
		Else
			AddError(NStr("en='Acknowledgement error: ';ru='Ошибка подтверждения связи: ';de='Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("en='Acknowledgement error: ';ru='Ошибка подтверждения связи: ';de='Fehler bei der Verbindungsbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	Return False;
EndFunction // TCPAcknowledgement

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString(pDoorLockSystemParameters)
	vStr = ""; // "19200,N,8,1" by default
	// Baudrate
	If pDoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(pDoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "19200";
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
		vStr = vStr + ",N";
	EndIf;
	// Data length
	If ValueIsFilled(pDoorLockSystemParameters.DataBits) Then
		If pDoorLockSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
			vStr = vStr + ",8";
		ElsIf pDoorLockSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
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
	// No flow control
	Return vStr;		
EndFunction // GetCOMPortConnectionString

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
			If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
			   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
				vDLSys = New COMObject("SPort.SPortAx.1");
				// Set connection parameters
				vDLSys.InitString(GetCOMPortConnectionString(pDoorLockSystemParameters));
				// Open COM port
				vIsOpen = vDLSys.Open(TrimAll(pDoorLockSystemParameters.Port));
				If Not vIsOpen Then
					AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(pDoorLockSystemParameters.Port));
					Return Undefined;
				EndIf;
				// Set block mode
				vDLSys.BlockMode = True;
				// Setup timeouts
				vDLSys.TimeoutReadInterval = 1000;
				vDLSys.TimeoutReadTotalConstant = 2000;
				vDLSys.TimeoutReadTotalMultiplier = 100;
				vDLSys.TimeoutWriteTotalConstant = 2000;
				vDLSys.TimeoutWriteTotalMultiplier = 100;
			Else
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
					AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
					Return Undefined;
				EndIf;     
				vDLSys.Blocking = True;
				vDLSys.Timeout = 60; // 60 seconds blocking read timeout by default
				vErrorCode = vDLSys.Connect(TrimAll(pDoorLockSystemParameters.ServerName), Number(?(IsBlankString(pDoorLockSystemParameters.Port), "10001", TrimAll(pDoorLockSystemParameters.Port))));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " system server was not found: '; de = '" + vSystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf;     
			EndIf;
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " door lock system connection error: '; de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters)
	Try
		vSystemName = String(pDevice.SystemName);
		If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
		   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
			pDLSys.Close();
		Else
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + vSystemName + ": '; en = '" + vSystemName + " server disconnect error: '; de = '" + vSystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + vSystemName + ": '; en = '" + vSystemName + " system disconnect error: '; de = '" + vSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pDevice, pParameters, pDoorLockSystemParameters, pRCList, pCharList)
	If pDoorLockSystemParameters.WriteTrack2 Then
		vSystemName = String(pDevice.SystemName);
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, False);
			If ValueIsFilled(vIDCardRef) Then
				tcDoorLocksAtServer.UpdateCardIdentifier(vIDCardRef);
				// Save identification card number
				pParameters.IdentificationCard = vIDCardRef;
				// Track 2 data: CardIdentifier
				vTrack2 = TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardRef, "Identifier"));
				pDta = pDta + "F202" + Left(vTrack2, 14) + pCharList.SEP;
			Else
				vErrorCode = pRCList.RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, vSystemName));
				pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = pRCList.RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, vSystemName));
			pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return pRCList.RC_OK;
EndFunction // AddTrack2

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pSourceAddress, pDta, pDoorLockSystemParameters, pDevice, pRCList, pCharList)
	// Define command code
	vCommandCode = "1";
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRCList, pCharList);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRCList, pCharList);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage) Export
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
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	// Room
	vDta = """" + vRoomCode + vCharList.SEP;
	// Number of key cards
	If pParameters.NumberOfKeys > 1 Then
		vDta = vDta + "&" + Format(pParameters.NumberOfKeys, "ND=3; NFD=0; NG=") + vCharList.SEP;
	Else
		vDta = vDta + "&1" + vCharList.SEP;
	EndIf;	
	// Key card type - new key card
	vDta = vDta + "%0" + vCharList.SEP;
	// Check in and check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + "$" + Format(vCheckOutDate, "DF='yyyy/MM/dd HH:mm'") + vCharList.SEP;
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	If (vCheckInDate - tcOnServer.cmGetServerCurrentSessionDate()) > 3600 Then
		vDta = vDta + "(" + Format(vCheckInDate, "DF='yyyy/MM/dd HH:mm'") + vCharList.SEP;
	EndIf;
	// Guest name
	vGuestName = "";
	If ValueIsFilled(pParameters.Guest) Then
		vGuestName = Left(Transliterate(TrimAll(pParameters.Guest), True, vDoorLockSystemParameters), 20);
	EndIf;
	If Not IsBlankString(vGuestName) Then
		vDta = vDta + " 2, " + vGuestName + vCharList.SEP;
	EndIf;
	// Operators data
	vOperatorLogin = "";
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin");
			If Not IsBlankString(vDoorLockSystemLogin) Then
				vOperatorLogin = Left(Transliterate(TrimAll(vDoorLockSystemLogin), True, vDoorLockSystemParameters), 3);
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(vOperatorLogin) Then
		vDta = vDta + "+" + vOperatorLogin + vCharList.SEP;
	EndIf;
	// Common area
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) Then
		If ValueIsFilled(vDoorLockSystemParameters) And 
		   Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) And 
		   tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
			vDta = vDta + ")" + TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) + vCharList.SEP + ")" + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations) + vCharList.SEP;
		Else
			vDta = vDta + ")" + TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) + vCharList.SEP;
		EndIf;
	Else
		If ValueIsFilled(vDoorLockSystemParameters) And Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) Then
			vDta = vDta + ")" + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations) + vCharList.SEP;
		EndIf;
	EndIf;
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, pDevice, pParameters, vDoorLockSystemParameters, vRCList, vCharList);
	If vErrorCode <> vRCList.RC_OK Then
		Return vErrorCode;
	Else
		// Get encoder number
		vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
		// Get source address
		vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
		
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vSourceAddress, vDta, vDoorLockSystemParameters, pDevice, vRCList, vCharList);
		If vErrorCode <> vRCList.RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
		Else
			For Each vItem In vCharList Do
				vDta = StrReplace(vDta, vItem.Value, "(" + vItem.Key + ")");  	
			EndDo;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", "", pParameters.Room, vDta, vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pEncoderNumber, pSourceAddress, pDta, pDoorLockSystemParameters, pDevice, pRCList, pCharList)
	// Define command code
	vCommandCode = "1";
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRCList, pCharList);
	Else
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRCList, pCharList);
	EndIf;
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
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
		Return vRCList.RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	// Room
	vDta = """" + vRoomCode + vCharList.SEP;
	// Number of key cards
	If pParameters.NumberOfKeys > 1 Then
		vDta = vDta + "&" + Format(pParameters.NumberOfKeys, "ND=3; NFD=0; NG=") + vCharList.SEP;
	Else
		vDta = vDta + "&1" + vCharList.SEP;
	EndIf;	
	// Key card type - additional
	vDta = vDta + "%1" + vCharList.SEP;
	// Check in and check out dates
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + "$" + Format(vCheckOutDate, "DF='yyyy/MM/dd HH:mm'") + vCharList.SEP;
	vCheckInDate = pParameters.CheckInDate;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	If (vCheckInDate - tcOnServer.cmGetServerCurrentSessionDate()) > 3600 Then
		vDta = vDta + "(" + Format(vCheckInDate, "DF='yyyy/MM/dd HH:mm'") + vCharList.SEP;
	EndIf;
	// Guest name
	vGuestName = "";
	If ValueIsFilled(pParameters.Guest) Then
		vGuestName = Left(Transliterate(TrimAll(pParameters.Guest), True, vDoorLockSystemParameters), 20);
	EndIf;
	If Not IsBlankString(vGuestName) Then
		vDta = vDta + " 2, " + vGuestName + vCharList.SEP;
	EndIf;
	// Operators data
	vOperatorLogin = "";
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin");
			If Not IsBlankString(vDoorLockSystemLogin) Then
				vOperatorLogin = Left(Transliterate(TrimAll(vDoorLockSystemLogin), True, vDoorLockSystemParameters), 3);
			EndIf;
		EndIf;
	EndIf;
	If Not IsBlankString(vOperatorLogin) Then
		vDta = vDta + "+" + vOperatorLogin + vCharList.SEP;
	EndIf;
	// Common area
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) Then
		If ValueIsFilled(vDoorLockSystemParameters) And 
		   Not IsBlankString(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) And 
		   tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault") Then
			vDta = vDta + ")" + TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) + vCharList.SEP + ")" + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations) + vCharList.SEP;
		Else
			vDta = vDta + ")" + TrimAll(tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations")) + vCharList.SEP;
		EndIf;
	Else
		If ValueIsFilled(vDoorLockSystemParameters) And 
		   Not IsBlankString(vDoorLockSystemParameters.AssignedAuthorizations) Then
			vDta = vDta + ")" + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations) + vCharList.SEP;
		EndIf;
	EndIf;
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, pDevice, pParameters, vDoorLockSystemParameters, vRCList, vCharList);
	If vErrorCode <> vRCList.RC_OK Then
		Return vErrorCode;
	Else
		// Get encoder number
		vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
		// Get source address
		vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
		
		// Call API
		vErrorCode = AddKey(vDLSys, vEncoderNumber, vSourceAddress, vDta, vDoorLockSystemParameters, pDevice, vRCList, vCharList);
		If vErrorCode <> vRCList.RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
		Else
			For Each vItem In vCharList Do
				vDta = StrReplace(vDta, vItem.Value, "(" + vItem.Key + ")");  	
			EndDo;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", "", pParameters.Room, vDta, vCheckInDate, vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
		EndIf;
		
		pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
		Return vErrorCode;
	EndIf;	
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmParseCardDescription(pCardDesc, pDevice, pCharList)
	
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", GetWord(pCardDesc, """", pCharList));
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "OK");
	vCardData.Insert("IsCardValidDescription", NStr("en='Guest card is valid!';ru='Действующая гостевая карта!';de='Gültige Gastkarte!'"));
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", GetWord(pCardDesc, ")", pCharList));
	vCardData.Insert("CardCheckInDate", "");
	vCardData.Insert("CardCheckOutDate", GetDate(GetWord(pCardDesc, "$", pCharList)));
	vCardData.Insert("CardOperator", "");
	vAuthRef = tcDoorLocksAtServer.FindAuthorizations(pDevice.Hotel, vCardData.AssignedAuthorizations);	
	vCardData.Insert("CardAuthorizations", ?(ValueIsFilled(vAuthRef),TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef,"Code")) + " - " + TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef,"Description")),""));
	vCardData.Insert("CardID", GetWord(pCardDesc, ",", pCharList));
	vCardData.Insert("CardFullName", );
	
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pEncoderNumber, pSourceAddress, pCommandCode, pDta, pReply, pDevice, pRCList, pCharList)
	vErrorCode = pRCList.RC_OK;
	vSystemName = String(pDevice.SystemName);
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If Not IsBlankString(vEncoderNumber) Then
		If vEncoderNumber < "01" Or vEncoderNumber > "24" Or StrLen(vEncoderNumber) <> 2 Then
			Return pRCList.RC_WRONG_ENCODER_NUMBER;
		EndIf;
	EndIf;
	vSourceAddress = TrimAll(pSourceAddress);
	If Not IsBlankString(vSourceAddress) Then
		If vSourceAddress < "00" Or vSourceAddress > "64" Or StrLen(vSourceAddress) <> 2 Then
			Return pRCList.RC_WRONG_SOURCE_ADDRESS;
		EndIf;
	EndIf;
	// Build command string for the RS232 interface
	vCmd = "";
	vMsgLength = 1;
	vShift = 2;
	// Encoder number
	If Not IsBlankString(vEncoderNumber) Then
		vCmd = vCmd + vEncoderNumber;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Source address
	If Not IsBlankString(vSourceAddress) Then
		vCmd = vCmd + vSourceAddress;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Command code
	vCmd = vCmd + pCommandCode;
	vMsgLength = vMsgLength + 1;
	// Message length
	vMsgLength = vMsgLength + 4 + StrLen(pDta) + 1 + 1;
	vCmd = vCmd + Format(vMsgLength, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = pCharList.STX + vCmd + pCharList.ETX;
	// Build command
	vCmd = vCmd + CharLRC(vCmd, False);
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys, pCharList) Then
		Return pRCList.RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 2000;
	For i = 1 To 3 Do
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = pCharList.ACK Then
				Break;
			Else
				If vReply = pCharList.DC1 Then
					Return pRCList.RC_DEVICE_IS_BUSY;
				ElsIf vReply <> pCharList.NAK Then
					AddError(NStr("en='DFU Reply is: ';ru='Ответ DFU: ';de='Antwort DFU: '") + vReply);
					Return pRCList.RC_WRONG_REPLY;
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return pRCList.RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Write end of transaction char
	vBytesSent = pDLSys.WriteStr(pCharList.SOF);
	// Purge RS232
	pDLSys.PurgeQueue();
	If vReply = pCharList.NAK Then
		Return pRCList.RC_SYNTAX_ERROR;
	EndIf;
	// Read command reply message
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pDLSys.ReadStr();
		If Not IsBlankString(pReply) Then
			// Skip ENQ
			If pReply = pCharList.ENQ Then
				// Send ACK and wait for reply
				vBytesSent = pDLSys.WriteStr(pCharList.ACK);
				pReply = pDLSys.ReadStr();
				If IsBlankString(pReply) Then
					Return pRCList.RC_NO_REPLY;
				EndIf;
			EndIf;
			// Check LRC
			If CheckCharLRC(pReply, False) Then
				vBytesSent = pDLSys.WriteStr(pCharList.ACK);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pDLSys.WriteStr(pCharList.NAK);
				pDLSys.TimeoutReadTotalConstant = 3000;
			EndIf;
		Else
			Return pRCList.RC_NO_REPLY;
		EndIf;
	EndDo;
	// Check returned data
	If Not vReadOK Then
		vErrorCode = pRCList.RC_WRONG_REPLY;
	Else
		// Retreive return code
		vCmdCode = Mid(pReply, vShift, 1);
		If vCmdCode = "4" Then
			vRC = Mid(pReply, vShift + 5, 1);
			If vRC <> "P" Then
				AddError(NStr("ru = 'Ошибка системы эл. замков " + vSystemName + ": '; en = '" + vSystemName + " system error: '; de = '" + vSystemName + " system error: '") + pReply + " <- " + vCmd);
				vErrorCode = GetErrorCode(vRC, pRCList);
			Else
				pReply = Mid(pReply, vShift + 5);
			EndIf;
		ElsIf vCmdCode = "3" Then
			pReply = Mid(pReply, vShift + 5);
		Else
			vErrorCode = pRCList.RC_WRONG_REPLY;
			// Retreive reply data
			vPrefixLen = 1;
			If StrLen(pReply) > (vPrefixLen + 1) Then
				pReply = Mid(pReply, vPrefixLen + 1, StrLen(pReply) - vPrefixLen - 1);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pSourceAddress, pCommandCode, pDta, pReply, pDevice, pRCList, pCharList)
	vErrorCode = pRCList.RC_OK;
	vSystemName = String(pDevice.SystemName);
	pReply = "";
	// Format encoder number and source address
	vEncoderNumber = TrimAll(pEncoderNumber);
	If Not IsBlankString(vEncoderNumber) Then
		If vEncoderNumber < "01" Or vEncoderNumber > "24" Or StrLen(vEncoderNumber) <> 2 Then
			Return pRCList.RC_WRONG_ENCODER_NUMBER;
		EndIf;
	EndIf;
	vSourceAddress = TrimAll(pSourceAddress);
	If Not IsBlankString(vSourceAddress) Then
		If vSourceAddress < "00" Or vSourceAddress > "64" Or StrLen(vSourceAddress) <> 2 Then
			Return pRCList.RC_WRONG_SOURCE_ADDRESS;
		EndIf;
	EndIf;
	// Build command string for the RS232 interface
	vCmd = "";
	vMsgLength = 1;
	vShift = 2;
	// Encoder number
	If Not IsBlankString(vEncoderNumber) Then
		vCmd = vCmd + vEncoderNumber;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Source address
	If Not IsBlankString(vSourceAddress) Then
		vCmd = vCmd + vSourceAddress;
		vMsgLength = vMsgLength + 2;
		vShift = vShift + 2;
	EndIf;
	// Command code
	vCmd = vCmd + pCommandCode;
	vMsgLength = vMsgLength + 1;
	// Message length
	vMsgLength = vMsgLength + 4 + StrLen(pDta) + 1 + 1;
	vCmd = vCmd + Format(vMsgLength, "ND=4; NFD=0; NZ=; NLZ=; NG=");
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = pCharList.STX + vCmd + pCharList.ETX;
	// Build command
	vCmd = vCmd + CharLRC(vCmd, False);
	// Send acknowledgement
	If Not TCPAcknowledgement(pDLSys, pCharList) Then
		Return pRCList.RC_NO_REPLY;
	EndIf;
	// Send command and get acknowledgement
	pDLSys.Timeout = 3;
	For i = 1 To 3 Do
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1) <> -1 Then
				If vReply = pCharList.ACK Then
					Break;
				Else
					If vReply = pCharList.DC1 Then
						Return pRCList.RC_DEVICE_IS_BUSY;
					ElsIf vReply <> pCharList.NAK Then
						AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
						Return pRCList.RC_WRONG_REPLY;
					EndIf;
				EndIf;
			Else
				AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return pRCList.RC_NO_CONNECTION;
			EndIf;
		Else
			AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pRCList.RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Write end of transaction char
	pDLSys.Write(pCharList.SOF, 1);
	// Read command reply message
	vReadOK = False;
	pDLSys.Timeout = pReadTimeout;
	For i = 1 To 3 Do
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Skip ENQ
				If pReply = pCharList.ENQ Then
					// Send ACK and wait for reply
					pDLSys.Write(pCharList.ACK, 1);
					If pDLSys.Read(pReply, 1024) <> -1 Then
						If IsBlankString(pReply) Then
							Return pRCList.RC_NO_REPLY;
						EndIf;
					Else
						AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return pRCList.RC_NO_CONNECTION;
					EndIf;
				EndIf;
				// Check LRC
				If CheckCharLRC(pReply, False) Then
					If pDLSys.Write(pCharList.ACK, 1) <> -1 Then
						vReadOK = True;
						Break;
					Else
						AddError(NStr("en='Write command reply confirmation error: ';ru='Ошибка отправки подтверждения чтения ответа: ';de='Fehler beim Versenden der Lesebestätigung der Antwort: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return pRCList.RC_NO_CONNECTION;
					EndIf;
				Else
					pDLSys.Write(pCharList.NAK, 1);
					pDLSys.Timeout = 3;
				EndIf;
			Else
				Return pRCList.RC_NO_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pRCList.RC_NO_CONNECTION;
		EndIf;
	EndDo;
	// Check returned data
	If Not vReadOK Then
		vErrorCode = pRCList.RC_WRONG_REPLY;
	Else
		// Read command code
		vCmdCode = Mid(pReply, vShift, 1);
		If vCmdCode = "4" Then
			// Retreive return code
			vRC = Mid(pReply, vShift + 5, 1);
			If vRC <> "P" Then
				AddError(NStr("ru = 'Ошибка системы эл. замков " + vSystemName + ": '; en = '" + vSystemName + " system error: '; de = '" + vSystemName + " system error: '") + pReply + " <- " + vCmd);
				vErrorCode = GetErrorCode(vRC, pRCList);
			Else
				pReply = Mid(pReply, vShift + 5);
			EndIf;
		ElsIf vCmdCode = "3" Then
			pReply = Mid(pReply, vShift + 5);
		Else
			vErrorCode = pRCList.RC_WRONG_REPLY;
			// Retreive reply data
			vPrefixLen = 1;
			If StrLen(pReply) > (vPrefixLen + 1) Then
				pReply = Mid(pReply, vPrefixLen + 1, StrLen(pReply) - vPrefixLen - 1);
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDoorLockSystemParameters, pEncoderNumber, pSourceAddress, pCardDesc, pDevice, pRCList, pCharList)
	vErrorCode = pRCList.RC_OK;
	pCardDesc = "";
	vReply = "";
	// Define command
	vCommandCode = "2";
	// Build command data
	vDta = "@" + """" + "$" + ")" + "," + pCharList.SEP;
	// Send command
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Send command using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pSourceAddress, vCommandCode, vDta, vReply, pDevice, pRCList, pCharList);
	Else
		// Send command using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pEncoderNumber, pSourceAddress, vCommandCode, vDta, vReply, pDevice, pRCList, pCharList);
	EndIf;
	// Retrieve card data
	If vErrorCode = pRCList.RC_OK Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRCList = GetErrorList();
	vCharList = GetCharList();
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters);
	If vDLSys = Undefined Then
		Return vRCList.RC_NO_CONNECTION;
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys,vDoorLockSystemParameters, vEncoderNumber, vSourceAddress, vCardDesc, pDevice, vRCList, vCharList);
	If vErrorCode <> vRCList.RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + Chars.LF + pmGetErrorDescription(vErrorCode, String(pDevice.SystemName)));
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc, pDevice, vCharList);
		
		// Guest client name from the client identification card
		If ValueIsFilled(vDoorLockSystemParameters) And vDoorLockSystemParameters.WriteTrack2 Then
			vIDCardRef = tcDoorLocksAtServer.GetIdentificationCardsRefByCardID(pCardData.CardID);
			If ValueIsFilled(vIDCardRef) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client")) Then
				pCardData.CardFullName = tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client.FullName");
			EndIf;
		EndIf;
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	
	Return vErrorCode;	
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vRCList = GetErrorList();
	If pRC = vRCList.RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + pSystemName + "!';
		            |en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = vRCList.RC_UNKNOWN Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = vRCList.RC_DEVICE_TIME_OUT Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = vRCList.RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = vRCList.RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		            |de = '" + pSystemName + " system is not responding!'; 
		            |en = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = vRCList.RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + pSystemName + " system replied with unknown format!'; 
		            |en = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRCList.RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRCList.RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRCList.RC_NO_FOLIO_NUMBER Then
		Return(NStr("en='No folio # found on keycard. Read keycard reply';ru='№ лицевого счета на карте не записан!';de='Die Personenkontonummer ist nicht auf der Karte gespeichert!'"));
	ElsIf pRC = vRCList.RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = vRCList.RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = vRCList.RC_DEVICE_IS_BUSY Then
		Return(NStr("en='The encoder has not already accomplished the previous task!';ru='Энкодер не закончил выполнение предыдущего задания!';de='Encoder hat die vorhergehende Aufgabe nicht beendet!'"));
	ElsIf pRC = vRCList.RC_WRONG_ENCODER_NUMBER Then
		Return(NStr("en='Encoder address should be empty or in range from 01 to 24!';ru='Номер (адрес) энкодера должен быть пустой или в диапазоне от 01 до 24!';de='Nummer (Adresse) des Encoders muss leer sein oder im Bereich von 01 bis 24 liegen!'"));
	ElsIf pRC = vRCList.RC_WRONG_SOURCE_ADDRESS Then
		Return(NStr("en='Workstation address should be empty or in range from 00 to 64!';ru='Номер (адрес) рабочей станции должен быть пустой или в диапазоне от 00 до 64!';de='Nummer (Adresse) der Arbeitsstation muss leer sein oder sich im Bereich von 00 bis 64 liegen!'"));
	ElsIf pRC = vRCList.RC_VALUE_INVALID Then
		Return(NStr("en='Illegal Field Type! Value invalid, out of range';ru='Неверный тип поля! Значение указано неверно или находится вне разрешенного диапазона';de='Falscher Feldtyp! Der Wert ist falsch angegeben oder befindet sich außerhalb des zugelassenen Bereichs'"));
	ElsIf pRC = vRCList.RC_ROOM_IS_MISSING Then
		Return(NStr("en='Room number was not specified in the command!';ru='Неверный тип поля! Значение указано неверно или находится вне разрешенного диапазона';de='Falscher Feldtyp! Der Wert ist falsch angegeben oder befindet sich außerhalb des zugelassenen Bereichs'"));
	ElsIf pRC = vRCList.RC_TOO_MUCH_DATA Then
		Return(NStr("ru = 'Display line data > 20 characters!'; 
		            |de = 'Display line data > 20 characters!'; 
		            |en = 'Display line data > 20 characters!'"));
	ElsIf pRC = vRCList.RC_ENCODER_ERROR Then
		Return(NStr("en='Encoder error!';ru='Ошибка энкодера!';de='Encoderfehler!'"));
	ElsIf pRC = vRCList.RC_INVALID_AUTH Then
		Return(NStr("en='Authorization # not between 1-120 or 161-200!';ru='Авторизационный код не в диапазонах 1-120 или 161-200!';de='Der Autorisierungscode liegt nicht in den Bereichen 1-120 oder 161-200!'"));
	ElsIf pRC = vRCList.RC_DATE_OUT_OF_RANGE Then
		Return(NStr("en='Pre-reg. Date Out of Range or Date > Expiry Date or Date < Creation Date!';ru='Pre-reg. Неверная дата или Дата > Дата окончания ключа или Дата < Дата создания!';de='Pre-reg. Falsches Datum oder Datum > Enddatum des Schlüssels oder Datum < Erstellungsdatum!'"));
	ElsIf pRC = vRCList.RC_INVALID_EXPIRY_DATE Then
		Return(NStr("en='Expiry date is invalid or less than creation date!';ru='Дата окончания действия ключа меньше чем дата выдачи или указана неверно!';de='Das Datum des Schlüsselgültigkeitsendes liegt vor dem Datum der Schlüsselausgabe oder wurde falsch angegeben!'"));
	ElsIf pRC = vRCList.RC_NO_INNER_DOORS Then
		Return(NStr("en='No inner door(s) specified for a common door!';ru='Для общей двери не указано ни одной внутренней двери!';de='Für die allgemeine Tür ist keine innere Tür angegeben!'"));
	ElsIf pRC = vRCList.RC_CARD_SWYPE_ERROR Then
		Return(NStr("en='Card swipe error or invalid guest keycard!';ru='Ошибка чтения карты или вставлена не гостевая карта!';de='Fehler beim Lesen der Karte oder die eingesetzte Karte ist keine Gästekarte!'"));
	ElsIf pRC = vRCList.RC_OPERATION_ABORTED Then
		Return(NStr("en='Card encoding or read was cancelled by user!';ru='Операция c картой прервана пользователем!';de='Die Operation mit der Karte wurde vom Nutzer unterbrochen!'"));
	ElsIf pRC = vRCList.RC_FUNCTION_NOT_ENABLED Then
		Return(NStr("en='Keycard read back feature is not enabled!';ru='Запрошенное с карты свойство не поддерживается!';de='Die von der Karte abgefragte Eigenschaft wird nicht unterstützt!'"));
	ElsIf pRC = vRCList.RC_DEVICE_NOT_RESPONDING Then
		Return(NStr("en='Encoder is not responding to command!';ru='Энкодер не отвечает на команды!';de='Encoder antwortet nicht auf Befehle!'"));
	ElsIf pRC = vRCList.RC_COMMUNICATION_FAILURE Then
		Return(NStr("en='Gateway interface to FDU failure!';ru='Нет связи между энкодером (FDU) и концентратором (gateway)!';de='Es gibt keine Verbindung zwischen dem Encoder (FDU) und dem Hub (Gateway)!'"));
	EndIf;	
EndFunction // pmGetErrorDescription

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_UNKNOWN", 100);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_NO_ID_CARD", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 111);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", 114);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_WRONG_ENCODER_NUMBER", 121);
	vErrorList.Insert("RC_WRONG_SOURCE_ADDRESS", 122);
	vErrorList.Insert("RC_DEVICE_IS_BUSY", 123);
	vErrorList.Insert("RC_SYNTAX_ERROR", 105);
	vErrorList.Insert("RC_VALUE_INVALID", 124);
	vErrorList.Insert("RC_ROOM_IS_MISSING", 125);
	vErrorList.Insert("RC_ENCODER_ERROR", 126);
	vErrorList.Insert("RC_TOO_MUCH_DATA", 127);
	vErrorList.Insert("RC_WRONG_ROOM", 113);
	vErrorList.Insert("RC_INVALID_AUTH", 128);
	vErrorList.Insert("RC_DATE_OUT_OF_RANGE", 130);
	vErrorList.Insert("RC_INVALID_EXPIRY_DATE", 131);
	vErrorList.Insert("RC_NO_INNER_DOORS", 132);
	vErrorList.Insert("RC_CARD_SWYPE_ERROR", 133);
	vErrorList.Insert("RC_NO_FOLIO_NUMBER", 134);
	vErrorList.Insert("RC_OPERATION_ABORTED", 135);
	vErrorList.Insert("RC_FUNCTION_NOT_ENABLED", 136);
	vErrorList.Insert("RC_DEVICE_NOT_RESPONDING", 138);
	vErrorList.Insert("RC_COMMUNICATION_FAILURE", 139);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function GetCharList()
	vCharList = New Structure();
	vCharList.Insert("SEP", Char(28));
	vCharList.Insert("ENQ", Char(5));
	vCharList.Insert("ACK", Char(6));
	vCharList.Insert("NAK", Char(21));
	vCharList.Insert("STX", Char(2));
	vCharList.Insert("ETX", Char(3));
	vCharList.Insert("DLE", Char(16));
	vCharList.Insert("DC1", Char(11));
	vCharList.Insert("SOF", Char(127));
	Return vCharList; 
EndFunction // GetErrorList
