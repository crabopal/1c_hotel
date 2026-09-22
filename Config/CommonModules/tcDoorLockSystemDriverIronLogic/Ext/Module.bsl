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
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,GetDataPresentation(pErrorText));
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function GetDataPresentation(Val pStr)
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
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function GetCardUID(pReply, pChar)
	vCardUID = pReply;
	vIdIsFound = Find(vCardUID, pChar["SEP"]);
	If vIdIsFound > 0 Then
		If StrLen(TrimAll(Left(vCardUID, vIdIsFound - 1))) < 3 Then
			vCardUID = Mid(vCardUID, vIdIsFound + 1);
			vIdIsFound = Find(vCardUID, pChar["SEP"]);
			If vIdIsFound > 0 Then
				vCardUID = Left(vCardUID, vIdIsFound - 1);
			EndIf;
		Else
			vCardUID = Left(vCardUID, vIdIsFound - 1);
		EndIf;		
	EndIf;
	Return TrimAll(vCardUID);
EndFunction // GetCardUID

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="", pChar)
	If pDelimeter = "" Then
		pDelimeter = pChar["SEP"];//Char(124);
	EndIf;
	vWord = "";
	vPos = Find(pStr, pDelimeter);
	If vPos > 0 Then
		vWord = Left(pStr, vPos-1);
		pStr = TrimL(Right(pStr, StrLen(pStr) - vPos));
	Else
		vWord = TrimL(pStr);
		pStr = "";
	EndIf;
	Return vWord;
EndFunction // GetNextWord

// -----------------------------------------------------------------------------
Function StrToDate(pStrDate)
	If Not IsBlankString(pStrDate) And StrLen(pStrDate) >= 19 Then
		Try
		vDate = Date(Number(Mid(pStrDate,16,4)),Number(Mid(pStrDate,13,2)),Number(Mid(pStrDate,10,2)),Number(Mid(pStrDate,1,2)),Number(Mid(pStrDate,4,2)),Number(Mid(pStrDate,7,2)));
		Return vDate;
		Except
		EndTry;
	EndIf;
	Return '00010101';
EndFunction

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
	vStr = ""; // "9600,N,8,1,P" by default
	// Baudrate
	If pDoorLockSystemParameters.BaudRate > 0 Then
		vStr = vStr + Format(pDoorLockSystemParameters.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
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
	// Hardware flow control always
	vStr = vStr + ",P";
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function RS232Acknowledgement(pDLSys, pChar)
	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(pChar["ENQ"]);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 3000;
		vReply = pDLSys.ReadStr();
		If vReply = pChar["ACK"] Then
			Return True;
		ElsIf vReply = pChar["NAK"] Then
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
Function pmConnect(pDevice, pDoorLockSystemParameters, pChar)
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
				vDLSys.TimeoutReadTotalConstant = 3000;
				vDLSys.TimeoutReadTotalMultiplier = 100;
				vDLSys.TimeoutWriteTotalConstant = 3000;
				vDLSys.TimeoutWriteTotalMultiplier = 100;
				// Send/receive acknowledgement
				If Not RS232Acknowledgement(vDLSys, pChar) Then
					AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + vSystemName + "!'; en = 'Acknowledgement with system " + vSystemName + " failed!'; de = 'Acknowledgement with system " + vSystemName + " failed!'"));
					vDLSys.Close();
					Return Undefined;
				EndIf;
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
				vErrorCode = vDLSys.Connect(TrimAll(pDoorLockSystemParameters.ServerName), Number(TrimAll(pDoorLockSystemParameters.Port)));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " system server was not found: '; de = '" + vSystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf;     
			EndIf;
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + vSystemName + ": '; 
						  |en = '" + vSystemName + " door lock system connection error: ';
						  |de = '" + vSystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters)
	vSystemName = String(pDevice.SystemName);
	Try
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
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pSourceAddress, pCommandCode, pDta, pReply, pDevice, pRC, pChar)
	vSystemName = String(pDevice.SystemName);
	vErrorCode = pRC["RC_OK"];
	pReply = "";
	// Format source address
	vSourceAddress = TrimAll(pSourceAddress);
	// Build command string for the RS232 interface
	vCmd = pChar["STX"];
	// Add source address only if it is not blank, assuming that 
	// if PC Id was not specified then Iron Logic PMS-Server is not used
	If Not IsBlankString(vSourceAddress) Then	
		vCmd = vCmd + pChar["SEP"] + vSourceAddress;
	EndIf;
	vCmd = vCmd + pChar["SEP"] + pCommandCode; // Command code
	vPrefixLen = StrLen(vCmd); // Length of command prefix
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + pChar["SEP"] + pChar["ETX"];
	vCmd = vCmd + CharLRC(vCmd);
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys, pChar) Then
		Return pRC["RC_NO_REPLY"];
	EndIf;
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 3000;
	For i = 1 To 3 Do
		vPQRes = pDLSys.PurgeQueue();
		vBytesSent = pDLSys.WriteStr(vCmd);
		If vBytesSent > 0 Then
			vReply = pDLSys.ReadStr();
			If vReply = pChar["ACK"] Then
				Break;
			Else
				If vReply <> pChar["NAK"] Then
					Return pRC["RC_NO_REPLY"];
				EndIf;
				pDLSys.PurgeQueue();
			EndIf;
		Else
			Return pRC["RC_NO_CONNECTION"];
		EndIf;
	EndDo;
	pDLSys.PurgeQueue();
	If vReply = pChar["NAK"] Then
		Return pRC["RC_SYNTAX_ERROR"];
	EndIf;
	// Read command reply message
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pDLSys.ReadStr();
		If Not IsBlankString(pReply) Then
			// Check LRC
			If CheckCharLRC(Mid(pReply, 2)) Then
				vBytesSent = pDLSys.WriteStr(pChar["ACK"]);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pDLSys.WriteStr(pChar["NAK"]);
				pDLSys.TimeoutReadTotalConstant = 3000;
			EndIf;
		Else
			Return pRC["RC_NO_REPLY"];
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = pRC["RC_WRONG_REPLY"];
	Else
		// Retreive return code
		vRCCode = Right(Left(pReply, vPrefixLen), 2);
		If vRCCode <> pCommandCode Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + vSystemName + ": '; en = '" + vSystemName + " system error: '; de = '" + vSystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRCCode, pRC);
		Else
			// Retreive reply data
			If StrLen(pReply) > (vPrefixLen + 3) Then
				pReply = Mid(pReply, vPrefixLen + 2, StrLen(pReply) - (vPrefixLen + 3));
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pSourceAddress, pCommandCode, pDta, pReply, pDevice, pRC, pChar)
	vSystemName = String(pDevice.SystemName);
	vErrorCode = pRC["RC_OK"];
	pReply = "";
	// Format source address
	vSourceAddress = TrimAll(pSourceAddress);
	// Build command string for the TCP interface
	vCmd = pChar["STX"];
	// Add source address only if it is not blank, assuming that 
	// if PC Id was not specified then Iron Logic PMS-Server is not used
	If Not IsBlankString(vSourceAddress) Then	
		vCmd = vCmd + pChar["SEP"] + vSourceAddress;
	EndIf;
	vCmd = vCmd + pChar["SEP"] + pCommandCode; // Command code
	vPrefixLen = StrLen(vCmd); // Length of command prefix
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + pChar["SEP"] + pChar["ETX"];
	vCmd = vCmd + CharLRC(vCmd);
	// Send command
	pDLSys.Timeout = 3;
	For i = 1 To 3 Do
		vFRes = pDLSys.Flush();
		If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
			vReply = "";
			If pDLSys.Read(vReply, 1) <> -1 Then
				If vReply = pChar["ACK"] Then
					Break;
				Else
					If vReply <> pChar["NAK"] Then
						Return pRC["RC_NO_REPLY"];
					EndIf;
				EndIf;
			Else
				AddError(NStr("en='Read command confirmation error: ';ru='Ошибка получения подтверждения команды: ';de='Fehler bei der Einholung der Befehlbestätigung: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
				Return pRC["RC_NO_CONNECTION"];
			EndIf;
		Else
			AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pRC["RC_NO_CONNECTION"];
		EndIf;
	EndDo;
	// Read command reply message
	vReadOK = False;
	pDLSys.Timeout = pReadTimeout;
	For i = 1 To 3 Do
		pReply = "";
		If pDLSys.Read(pReply, 1024) <> -1 Then
			If Not IsBlankString(pReply) Then
				// Check LRC
				If CheckCharLRC(Mid(pReply, 2)) Then
					If pDLSys.Write(pChar["ACK"], 1) <> -1 Then
						vReadOK = True;
						Break;
					Else
						AddError(NStr("en='Write command reply confirmation error: ';ru='Ошибка отправки подтверждения чтения ответа: ';de='Fehler beim Versenden der Lesebestätigung der Antwort: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
						Return pRC["RC_NO_CONNECTION"];
					EndIf;
				Else
					pDLSys.Write(pChar["NAK"], 1);
					pDLSys.Timeout = 3;
				EndIf;
			Else
				Return pRC["RC_NO_REPLY"];
			EndIf;
		Else
			AddError(NStr("en='Read command reply error: ';ru='Ошибка чтения ответа на команду: ';de='Fehler beim Lesen der Antwort auf den Befehl: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return pRC["RC_NO_CONNECTION"];
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = pRC["RC_WRONG_REPLY"];
	Else
		// Retreive return code
		vRCCode = Right(Left(pReply, vPrefixLen), 2);
		If vRCCode <> pCommandCode Then
			AddError(NStr("ru = 'Ошибка системы эл. замков " + vSystemName + ": '; en = '" + vSystemName + " system error: '; de = '" + vSystemName + " system error: '") + pReply + " <- " + vCmd);
			vErrorCode = GetErrorCode(vRCCode, pRC);
		Else
			 //Retreive reply data
			If StrLen(pReply) > (vPrefixLen + 3) Then
				pReply = Mid(pReply, vPrefixLen + 2, StrLen(pReply) - (vPrefixLen + 3));
			Else
				pReply = "";
			EndIf;
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pAdd = False, pCardVersion=0, pCommonDoors="", pDoorLockSystemParameters, pDevice, pParameters, pRC, pChar)
	vTrack2Data = "place::0";
	If pDoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				If pDoorLockSystemParameters.WriteTrack2 Then
					If Not IsBlankString(vTrack2Data) Then
						vTrack2Data = vTrack2Data + ",";
					EndIf;
					vTrack2Data = "card_id::" + TrimAll(vIDCardRef.Identifier);
				EndIf;
			Else
				vErrorCode = pRC["RC_NO_ID_CARD"];
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = pRC["RC_NO_FOLIO"];
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys, pDevice, pDoorLockSystemParameters);
			Return vErrorCode;
		EndIf;
	EndIf;
	If pCardVersion <> 0 Then
		If Not IsBlankString(vTrack2Data) Then
			vTrack2Data = vTrack2Data + ",";
		EndIf;
		vTrack2Data = vTrack2Data + "guest_card_version::" + Format(pCardVersion, "ND=3; NFD=; NZ=; NG=");
	EndIf;
	If pCommonDoors <> "" Then
		If Not IsBlankString(vTrack2Data) Then
			vTrack2Data = vTrack2Data + ",";
		EndIf;
		vTrack2Data = vTrack2Data + "common_doors::" + Format(Bin2Dec(pCommonDoors), "NFD=; NZ=; NG=");
	EndIf;
	pDta = pDta + pChar["SEP"] + vTrack2Data;
	Return pRC["RC_OK"];
EndFunction // AddTrack2

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pSourceAddress, pDta, pReply, pDoorLockSystemParameters, pDevice, pRC, pChar)
	// Define command code
	vCommandCode = "CX";
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, pReply, pDevice, pRC, pChar);
	Else
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, pReply, pDevice, pRC, pChar);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, pErrorMessage) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRC = GetErrorList();
	vChar = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters, vChar);
	If vDLSys = Undefined Then
		Return vRC["RC_NO_CONNECTION"];
	EndIf;

	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = Left(TrimR(vLockCode), 18);
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
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return vRC["RC_ROOM_WITHOUT_DOOR_LOCK"];
	EndIf;
	vDta = vChar["SEP"] + vRoomCode;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	vCurrentDate = tcOnServer.cmGetServerCurrentSessionDate();
	If BegOfDay(vCheckInDate) < BegOfDay(vCurrentDate) Then
		vCheckInDate = BegOfDay(vCurrentDate) + Hour(vCurrentDate) * 3600;
	EndIf;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + vChar["SEP"] + Format(vCheckInDate,"DF=dd/MM/yyyy");
	vDta = vDta + vChar["SEP"] + Format(vCheckInDate,"DF=HH:mm");
	vDta = vDta + vChar["SEP"] + Format(vCheckOutDate,"DF=dd/MM/yyyy");
	vDta = vDta + vChar["SEP"] + Format(vCheckOutDate,"DF=HH:mm");
	// Authorizations
	vCommonDoorsBitMap = "";
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"); 
		If ValueIsFilled(vAssignedAuthorizations) Then
			vMergeWithDefault = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault"); 
			If vMergeWithDefault Then
				vCommonDoorsBitMap = TrimAll(vAssignedAuthorizations) + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
			Else
				vCommonDoorsBitMap = TrimAll(vAssignedAuthorizations);
			EndIf;
		Else
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);	
		EndIf;
	Else
		vCommonDoorsBitMap = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	vDta = vDta + vChar["SEP"];
	// Keypad PIN code is not supported
	vDta = vDta + vChar["SEP"];
	// Card operation.
	vDta = vDta + vChar["SEP"] + "RP";
	// Leave operators name blank to use generic PMS operator
	vOperatorName = "";
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then 
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"); 
			vOperatorName = Left(Transliterate(TrimAll(vDoorLockSystemLogin)), 10);
		EndIf;	
	EndIf;
	vDta = vDta + vChar["SEP"] + vOperatorName;
	// encoder number
	vDta = vDta + vChar["SEP"];
	// Track 1 data
	vDta = vDta + vChar["SEP"];
	// Add tack 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, False, vDoorLockSystemParameters.CardVersion, vCommonDoorsBitMap, vDoorLockSystemParameters, pDevice, pParameters, vRC, vChar);
	If vErrorCode <> vRC["RC_OK"] Then
		Return vErrorCode;
	Else
		vSourceAddress = "";
		If Not IsBlankString(vDoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		If vDoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + "1";//Return ID Card
		EndIf;
		vReply = "";
		vErrorCode = MakeNewKey(vDLSys, vSourceAddress, vDta, vReply, vDoorLockSystemParameters, pDevice, vRC, vChar);
		
		If vErrorCode <> vRC["RC_OK"] Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If vDoorLockSystemParameters.ReturnCardUID AND ValueIsFilled(pParameters.Folio) Then
				vCardUID = GetCardUID(vReply, vChar);
				If ValueIsFilled(vCardUID) Then
					vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
					If ValueIsFilled(vIdentificationCard) Then
						pParameters.IdentificationCard = vIdentificationCard;
					EndIf;
				EndIf;
			EndIf;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", CurrentDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
		EndIf;
			
		pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pSourceAddress, pDta, pReply, pDoorLockSystemParameters, pDevice, pRC, pChar)
	// Define command code
	vCommandCode = "CG";
	// Choose transport
	If ValueIsFilled(pDoorLockSystemParameters.ConnectionType) And
	   pDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, pReply, pDevice, pRC, pChar);
	Else
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, pReply, pDevice, pRC, pChar);
	EndIf;
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	vRC = GetErrorList();
	vChar = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters, vChar);
	If vDLSys = Undefined Then
		Return vRC["RC_NO_CONNECTION"];
	EndIf;
	
	// Build command data string
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If vDoorLockSystemParameters.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If ValueIsFilled(vLockCode) Then
				vRoomCode = Left(TrimR(vLockCode), 18);
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
			If ValueIsFilled(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return vRC["RC_ROOM_WITHOUT_DOOR_LOCK"];
	EndIf;
	vDta = vChar["SEP"] + vRoomCode;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	vCurrentDate = tcOnServer.cmGetServerCurrentSessionDate();
	If BegOfDay(vCheckInDate) < BegOfDay(vCurrentDate) Then
		vCheckInDate = BegOfDay(vCurrentDate) + Hour(vCurrentDate) * 3600;
	EndIf;
	If vDoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - vDoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If vDoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + vDoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + vChar["SEP"] + Format(vCheckInDate,"DF=dd/MM/yyyy");
	vDta = vDta + vChar["SEP"] + Format(vCheckInDate,"DF=HH:mm");
	vDta = vDta + vChar["SEP"] + Format(vCheckOutDate,"DF=dd/MM/yyyy");
	vDta = vDta + vChar["SEP"] + Format(vCheckOutDate,"DF=HH:mm");
	// Authorizations
	vCommonDoorsBitMap = "";
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations"); 
		If ValueIsFilled(vAssignedAuthorizations) Then
			vMergeWithDefault = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "MergeWithDefault"); 
			If vMergeWithDefault Then
				vCommonDoorsBitMap = TrimAll(vAssignedAuthorizations) + TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
			Else
				vCommonDoorsBitMap = TrimAll(vAssignedAuthorizations);
			EndIf;
		Else
			vCommonDoorsBitMap = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);	
		EndIf;
	Else
		vCommonDoorsBitMap = TrimAll(vDoorLockSystemParameters.AssignedAuthorizations);
	EndIf;
	vDta = vDta + vChar["SEP"];
	// Keypad PIN code is not supported
	vDta = vDta + vChar["SEP"];
	// Card operation. Indicates if, once the operation has ended, the card must be ejected
	vDta = vDta + vChar["SEP"] + "RP";
	// Leave operators name blank to use generic PMS operator
	vOperatorName = "";
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then 
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"); 
			vOperatorName = Left(Transliterate(TrimAll(vDoorLockSystemLogin)), 10);
		EndIf;	
	EndIf;
	vDta = vDta + vChar["SEP"] + vOperatorName;
	// encoder number
	vDta = vDta + vChar["SEP"];
	// Track 1 data
	vDta = vDta + vChar["SEP"];
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, False, vDoorLockSystemParameters.CardVersion, vCommonDoorsBitMap, vDoorLockSystemParameters, pDevice, pParameters, vRC, vChar);
	If vErrorCode <> vRC["RC_OK"] Then
		Return vErrorCode;
	Else
		vSourceAddress = "";
		If ValueIsFilled(vDoorLockSystemParameters.PCId) Then
			vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
		EndIf;
		
		// Call API
		If vDoorLockSystemParameters.ReturnCardUID Then
			vDta = vDta + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + vChar["SEP"] + "1"; //Return ID Card
		EndIf;
		vReply = "";
		vErrorCode = AddKey(vDLSys, vSourceAddress, vDta, vReply, vDoorLockSystemParameters, pDevice, vRC, vChar);
		If vErrorCode <> vRC["RC_OK"] Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If vDoorLockSystemParameters.ReturnCardUID AND ValueIsFilled(pParameters.Folio) Then
				vCardUID = GetCardUID(vReply, vChar);
				If ValueIsFilled(vCardUID) Then
					vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID);
					If ValueIsFilled(vIdentificationCard) Then
						pParameters.IdentificationCard = vIdentificationCard;
					EndIf;
				EndIf;
			EndIf;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", CurrentDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, 1);
		EndIf;
		
		pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
		Return vErrorCode;
	EndIf;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmRegisterNewCard(pCardData, pIsMaster = False, pParameters) Export
	vRC = GetErrorList();
	// Add/get client identification card
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Add/get client identification card
	If ValueIsFilled(pParameters.Folio) Then
		// Get card identifier
		vCardID = tcOnServer.GetCardIdentifier(pCardData);
		// Register card
		vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardID, tcOnServer.GetClientIdentificationCardById(vCardID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, CurrentDate(), pParameters.CheckOutDate, True);
		If Not ValueIsFilled(vIdentificationCard) Then
			AddError(NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"));
			Return vRC["RC_NO_ID_CARD"];
		ElsIf TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "Identifier")) <> vCardID Then
			AddError(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
			Return vRC["RC_ONLY_ONE_ACTIVE_CARD_ALLOWED"];
		Else
			If pParameters.Property("IdentificationCard") Then
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		// Check should we update is master folio flag
		tcDoorLocksAtServer.UpdateMasterFolioFlag(pParameters.Folio, pIsMaster);
	Else
		AddError(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return vRC["RC_NO_FOLIO"];
	EndIf;
	Return vRC["RC_OK"];
EndFunction // pmRegisterNewCard

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pSourceAddress, pDta, pCardDesc, vDoorLockSystemParameters, pDevice, pRC, pChar)
	vErrorCode = pRC["RC_OK"];
	pCardDesc = "";
	vReply = "";
	// Define command
	vCommandCode = "RC";
	If ValueIsFilled(vDoorLockSystemParameters.ConnectionType) And
	   vDoorLockSystemParameters.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Send command using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 60000, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRC, pChar);
	Else
		// Send command using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 60, pSourceAddress, vCommandCode, pDta, vReply, pDevice, pRC, pChar);
	EndIf;
	// Retrieve card data
	If vErrorCode = pRC["RC_OK"] Then
		pCardDesc = vReply;
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	vDoorLockSystemParameters = tcDoorLocksAtServer.GetDoorLockSystemConnectionParameters(pDevice.DoorLockSystemConnectionParameters);
	If TypeOf(vDoorLockSystemParameters) <> Type("Structure") Then
		vDoorLockSystemParameters = New Structure("Hotel", pDevice.Hotel);
	ElsIf Not vDoorLockSystemParameters.Property("Hotel") Then
		vDoorLockSystemParameters.Insert("Hotel", pDevice.Hotel);	
	EndIf;
	vRC = GetErrorList();
	vChar = GetCharList();
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice, vDoorLockSystemParameters, vChar);
	If vDLSys = Undefined Then
		Return vRC["RC_NO_CONNECTION"];
	EndIf;
	
	// Build parameters
	vEncoderNumber = TrimAll(vDoorLockSystemParameters.EncoderNumber);
	vSourceAddress = "";
	If ValueIsFilled(vDoorLockSystemParameters.PCId) Then
		vSourceAddress = TrimAll(vDoorLockSystemParameters.PCId);
	EndIf;
	
	// Build command data string
	vDta = "";
	// format
	vDta = vDta + vChar["SEP"] + "T";
	// Read track 3
	vDta = vDta + vChar["SEP"] + "3";
	// Card should be ejected
	vDta = vDta + vChar["SEP"] + "EF";
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vSourceAddress, vDta, vCardDesc, vDoorLockSystemParameters, pDevice, vRC, vChar);
	If vErrorCode <> vRC["RC_OK"] Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc, vDoorLockSystemParameters, vChar);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice, vDoorLockSystemParameters);
	
	Return vErrorCode;	
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc, pDoorLockSystemParameters, pChar)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardRoom2", "");
	vCardData.Insert("CardRoom3", "");
	vCardData.Insert("CardRoom4", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("AssignedAuthorizations", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardOperator", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
		
	// Get reply type
	vCardGIUD = GetNextWord(pCardDesc,, pChar);
	// Card parameters
	vWord = GetNextWord(pCardDesc,, pChar);
	sepChar = Char(124);
	pos = StrFind(vWord,"room");
	If pos > 0 Then
		vRoom = Mid(vWord,pos+6);
		pos2 = StrFind(vRoom, sepChar);
		If pos2 > 0 Then
			vCardData.CardRoom = Mid(vRoom,0,pos2-1);
		Else
			vCardData.CardRoom = vRoom;
		EndIf;
	EndIf;
	name = "starttime::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		vDate = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(vDate, sepChar);
		If pos2 > 0 Then
			vDate = Mid(vDate,0,pos2-1);
		EndIf;
		vCardData.CardCheckInDate = StrToDate(vDate);
	EndIf;
	name = "endtime::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		vDate = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(vDate, sepChar);
		If pos2 > 0 Then
			vDate = Mid(vDate,0,pos2-1);
		EndIf;
		vCardData.CardCheckOutDate = StrToDate(vDate);
	EndIf;
	//place
	//guest_card_version
	//common_doors
	name = "common_doors::";
	pos = StrFind(vWord,name);
	If pos > 0 Then
		curValue = Mid(vWord,pos+StrLen(name));
		pos2 = StrFind(curValue, sepChar);
		If pos2 > 0 Then
			vCardData.AssignedAuthorizations = Mid(curValue,0,pos2-1);
		Else
			vCardData.AssignedAuthorizations = curValue;
		EndIf;
	EndIf;

	// Try to retrieve card authorizations
	If ValueIsFilled(vCardData.AssignedAuthorizations) Then
		vAuthRef = tcDoorLocksAtServer.FindAuthorizations(pDoorLockSystemParameters.Hotel, vCardData.AssignedAuthorizations);
		If ValueIsFilled(vAuthRef) Then
			vCardData.CardAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Code")) + " - " + TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Description"));
		EndIf;
	EndIf;
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vRC = GetErrorList();
	If pRC = vRC["RC_NO_CONNECTION"] Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + pSystemName + "!';
		            |en = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = vRC["RC_UNKNOWN"] Then
		Return(NStr("en='Unknown error! See error log for details.';ru='Неизвестная ошибка! Дополнительная информация сохранена в системном логе.';de='Unbekannter Fehler! Zusätzliche Information ist im Systemlog gespeichert.'"));
	ElsIf pRC = vRC["RC_DEVICE_TIME_OUT"] Then
		Return(NStr("en='The reader/writer has been waiting too long for a card!';ru='Закончилось время ожидания карты энкодером!';de='Die Wartezeit für die Karte am Encoder ist abgelaufen!'"));
	ElsIf pRC = vRC["RC_NO_GUEST_PREVIOUSLY_CHECKED_IN"] Then
		Return(NStr("en='No checked in guests in the room! Make new key card instead.';ru='В номере нет размещенных гостей! Выдайте гостю новую карту.';de='In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = vRC["RC_WRONG_ROOM"] Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = vRC["RC_NO_REPLY"] Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		            |de = '" + pSystemName + " system is not responding!'; 
		            |en = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = vRC["RC_WRONG_REPLY"] Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + pSystemName + " system replied with unknown format!'; 
		            |en = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = vRC["RC_ROOM_WITHOUT_DOOR_LOCK"] Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = vRC["RC_NO_FOLIO"] Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = vRC["RC_NO_ID_CARD"] Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = vRC["RC_SYNTAX_ERROR"] Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = vRC["RC_NO_COMMUNICATION"] Then
		Return(NStr("ru = 'Энкодер не отвечает (возможно выключен или не подключен)!'; 
		            |de = 'The encoder does not answer (failure in the communications or switched off)!'; 
		            |en = 'The encoder does not answer (failure in the communications or switched off)!'"));
	ElsIf pRC = vRC["RC_COMMAND_NOT_APPLICABLE"] Then
		Return(NStr("en='Not validated! The command cannot be accomplished because either the related room cannot be recognized, or the command is not applicable.';ru='Ошибка проверки команды! Возможно номер указан не верно или команда не применима в текущий момент.';de='Fehler bei der Prüfung des Befehls! Möglicherweise ist das Zimmer falsch angegeben oder der Befehl kann zu diesem Zeitpunkt nicht angewendet werden.'"));
	ElsIf pRC = vRC["RC_CARD_FORMAT_ERROR"] Then
		Return(NStr("en='Card inserted wrongly or without magnetic stripe!';ru='Не правильно вставлена карта или карта без магнитной полосы!';de='Die Karte wurde falsch eingesetzt oder hat kein Magnetstreifen!'"));
	ElsIf pRC = vRC["RC_GENERAL_READ_ERROR"] Then
		Return(NStr("en='General Reading error. The reading operation is not successful!';ru='Ошибка чтения карты. Прочитать данные с карты не удалось!';de='Fehler beim Lesen der Karte. Die Daten konnten nicht von der Karte gelesen werden!'"));
	ElsIf pRC = vRC["RC_GENERAL_ENCODING_ERROR"] Then
		Return(NStr("en='General Encoding error. The encoding operation is not successful!';ru='Ошибка кодирования карты. Не удалось записать данные на карту!';de='Fehler der Kartencodierung. Die Daten konnten nicht auf die Karte geschrieben werden!'"));
	ElsIf pRC = vRC["RC_ONLY_ONE_ACTIVE_CARD_ALLOWED"] Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	EndIf;	
EndFunction // pmGetErrorDescription

// -----------------------------------------------------------------------------
Function GetErrorCode(pRCCode, pRC)
	vErrorCode = pRC["RC_UNKNOWN"];
	If pRCCode = "E2" Then
		vErrorCode = pRC["RC_SYNTAX_ERROR"];
	ElsIf pRCCode = "E1" Then
		vErrorCode = pRC["RC_COMMAND_NOT_APPLICABLE"];
	ElsIf pRCCode = "EA" Then
		vErrorCode = pRC["RC_NO_COMMUNICATION"];
	ElsIf pRCCode = "E3" Then
		vErrorCode = pRC["RC_CARD_FORMAT_ERROR"];
	ElsIf pRCCode = "EE" Then
		vErrorCode = pRC["RC_GENERAL_READ_ERROR"];
	ElsIf pRCCode = "EF" Then
		vErrorCode = pRC["RC_GENERAL_ENCODING_ERROR"];
	ElsIf pRCCode = "EU" Then
		vErrorCode = pRC["RC_WRONG_ROOM"];
	ElsIf pRCCode = "E8" Then
		vErrorCode = pRC["RC_DEVICE_TIME_OUT"];
	ElsIf pRCCode = "ED" Then
		vErrorCode = pRC["RC_NO_GUEST_PREVIOUSLY_CHECKED_IN"];
	EndIf;
	Return vErrorCode;
EndFunction // GetErrorCode

// -----------------------------------------------------------------------------
Function GetErrorList()
	vErrorList = New Structure();
	vErrorList.Insert("RC_NO_CONNECTION", -1);
	vErrorList.Insert("RC_OK", 0);
	vErrorList.Insert("RC_UNKNOWN", 100);
	vErrorList.Insert("RC_NO_FOLIO", 101);
	vErrorList.Insert("RC_NO_ID_CARD", 102);
	vErrorList.Insert("RC_NO_REPLY", 103);
	vErrorList.Insert("RC_WRONG_REPLY", 104);
	vErrorList.Insert("RC_SYNTAX_ERROR", 105);
	vErrorList.Insert("RC_NO_COMMUNICATION", 106);
	vErrorList.Insert("RC_COMMAND_NOT_APPLICABLE", 107);
	vErrorList.Insert("RC_CARD_FORMAT_ERROR", 108);
	vErrorList.Insert("RC_GENERAL_READ_ERROR", 109);
	vErrorList.Insert("RC_GENERAL_ENCODING_ERROR", 110);
	vErrorList.Insert("RC_DEVICE_TIME_OUT", 111);
	vErrorList.Insert("RC_NO_GUEST_PREVIOUSLY_CHECKED_IN", 112);
	vErrorList.Insert("RC_WRONG_ROOM", 113);
	vErrorList.Insert("RC_ROOM_WITHOUT_DOOR_LOCK", 114);
	vErrorList.Insert("RC_ONLY_ONE_ACTIVE_CARD_ALLOWED", 95);
	Return vErrorList; 
EndFunction // GetErrorList

// -----------------------------------------------------------------------------
Function GetCharList()
	vCharList = New Structure();
	vCharList.Insert("SEP", Char(1110));
	vCharList.Insert("ENQ", Char(5));
	vCharList.Insert("ACK", Char(6));
	vCharList.Insert("NAK", Char(21));
	vCharList.Insert("STX", Char(2));
	vCharList.Insert("ETX", Char(3));
	vCharList.Insert("DLE", Char(16));
	Return vCharList; 
EndFunction // GetErrorList
