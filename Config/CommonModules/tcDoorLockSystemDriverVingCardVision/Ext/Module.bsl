// -----------------------------------------------------------------------------
Function Transliterate(Val pStr, pAlways = False, pDoGuestNamesTransliteration = True)
	If pAlways = Undefined Then
		pAlways = False;
	EndIf;
	vStr = Upper(pStr);
	If pDoGuestNamesTransliteration Or pAlways Then
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
Procedure AddError(pErrorText)
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"),"Warning",,,pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;

	// Fill system name
	vSystemName = pDevice.SystemName;
		
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
		Try
			// Build ActiveX object to work with
			If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
				vDLSys = New COMObject("SPort.SPortAx.1");
				// Set connection parameters
				vDLSys.InitString(GetCOMPortConnectionString(pDevice));
				// Open COM port
				vIsOpen = vDLSys.Open(TrimAll(pDevice.Port));
				If Not vIsOpen Then
					AddError(NStr("en = 'Failed to open port: '; ru = 'Не удалось открыть порт: '; de = 'Der Port konnte nicht geöffnet werden: '") + TrimAll(pDevice.Port));
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
				If Not RS232Acknowledgement(vDLSys) Then
					AddError(NStr("ru = 'Не удалось получить подтверждение установки связи с системой " + vSystemName + "!'; 
					              |de = 'Acknowledgement with system " + vSystemName + " failed!'; 
					              |en = 'Acknowledgement with system " + vSystemName + " failed!'"));
					vDLSys.Close();
					Return Undefined;
				EndIf;
			ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
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
				vDLSys.Timeout = 30; // 30 seconds blocking read timeout by default
				vErrorCode = vDLSys.Connect(TrimAll(pDevice.ServerName), ?(IsBlankString(TrimAll(pDevice.Port)), 3015, Number(TrimAll(pDevice.Port))));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; 
					              |de = '" + vSystemName + " system server was not found: '; 
					              |en = '" + vSystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf; 
				// Call PMSifRegister
				If Not PMSifRegister(vDLSys, 30, pDevice) Then
					AddError(NStr("ru = 'Ошибка регистрации на сервере Vision! Возможно неверно указан код лицензии.'; 
								  |en = 'Failed to register at Vision server! PMS license code is possibly wrong.'; 
								  |de = 'Failed to register at Vision server! PMS license code is possibly wrong.'"));
					Return Undefined;
				EndIf;  
			ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.VisionIntDll") Then
				vDLSys = New COMObject("VisionInt.Vision.1");
				vErrorCode = vDLSys.VCConnect(pDevice.ServerName);
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + vSystemName + ": '; en = '" + vSystemName + " system server was not found: '; de = '" + vSystemName + " system server was not found: '") + vErrorCode);
					Return Undefined;
				EndIf;     
				vErrorCode = vDLSys.VCRegister(TrimAll(pDevice.LicenseCode), "1CHOTEL");
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Ошибка регистрации на сервере системы электронных замков " + vSystemName + ": '; 
								  |en = 'Registration error at " + vSystemName + " server: '; 
								  |de = 'Registration error at " + vSystemName + " server: '") + vErrorCode);
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
Procedure pmDisconnect(pDLSys,pDevice)
	vSystemName = pDevice.SystemName;
	Try
		If ValueIsFilled(pDevice.ConnectionType) And
		   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
			pDLSys.Close();
		Else
			vErrorCode = pDLSys.Disconnect();
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + vSystemName + ": '; 
				              |de = '" + vSystemName + " server disconnect error: '; 
				              |en = '" + vSystemName + " server disconnect error: '") + vErrorCode);
				Return;
			EndIf;  
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + vSystemName + ": '; 
		              |de = '" + vSystemName + " system disconnect error: '; 
		              |en = '" + vSystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString(pDevice)
	vStr = ""; // "9600,N,8,1,P" by default
	// Baudrate
	If pDevice.BaudRate > 0 Then
		vStr = vStr + Format(pDevice.BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
	EndIf;
	// Parity
	If ValueIsFilled(pDevice.Parity) Then
		If pDevice.Parity = PredefinedValue("Enum.ParityTypes.Even") Then
			vStr = vStr + ",E";
		ElsIf pDevice.Parity = PredefinedValue("Enum.ParityTypes.Odd") Then
			vStr = vStr + ",O";
		ElsIf pDevice.Parity = PredefinedValue("Enum.ParityTypes.None") Then
			vStr = vStr + ",N";
		ElsIf pDevice.Parity = PredefinedValue("Enum.ParityTypes.Mark") Then
			vStr = vStr + ",M";
		ElsIf pDevice.Parity = PredefinedValue("Enum.ParityTypes.Space") Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",N";
	EndIf;
	// Data length
	If ValueIsFilled(pDevice.DataBits) Then
		If pDevice.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
			vStr = vStr + ",8";
		ElsIf pDevice.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
	EndIf;
	// Stop bits
	If ValueIsFilled(pDevice.StopBits) Then
		If pDevice.StopBits = PredefinedValue("Enum.StopBits.Bits1") Then
			vStr = vStr + ",1";
		ElsIf pDevice.StopBits = PredefinedValue("Enum.StopBits.Bits2") Then
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
Function RS232Acknowledgement(pDLSys)
	ENQ = Char(5);
	ACK = Char(6);
	NAK = Char(21);

	// Send ENQ and wait for ACK
	vBytesSent = pDLSys.WriteStr(ENQ);
	If vBytesSent = 1 Then
		pDLSys.TimeoutReadTotalConstant = 3000;
		vReply = pDLSys.ReadStr();
		If vReply = ACK Then
			Return True;
		ElsIf vReply = NAK Then
			AddError(NStr("en = 'NAK received on acknowledgement!'; ru = 'При подтверждении связи получен NAK!'; de = 'Bei der Bestätigung der Verbindung NAK erhalten!'"));
		Else
			AddError(NStr("en = 'Wrong reply received on acknowledgement: '; ru = 'При подтверждении связи получен символ: '; de = 'Bei der Bestätigung der Verbindung Symbol erhalten: '") + vReply);
		EndIf;
	Else
		AddError(NStr("en = 'Wrong number of bytes sent on acknowledgement: '; ru = 'При подтверждении связи отправлено байт: '; de = 'Bei der Bestätigung der Verbindung Byte versendet: '") + vBytesSent);
	EndIf;
	Return False;
EndFunction // RS232Acknowledgement

// -----------------------------------------------------------------------------
Function SPMSifHdr(pCommand, pBodySize)
	ui32Synch1 = Char(85) + Char(85) + Char(85) + Char(85);
	ui32Synch2 = Char(1028) + Char(1028) + Char(1028) + Char(1028);

	vHdr = "";
	// uint32 ui32Synch1;	/* Message synch1 = 0x55555555 */
	vHdr = vHdr + ui32Synch1;
	// uint32 ui32Synch2;	/* Message synch2 = 0xaaaaaaaa */
	vHdr = vHdr + ui32Synch2;
	// uint16 ui16Version;	/* Header format version = 1   */
	vHdr = vHdr + Char(1);
	// uint32 ui32Cmd;	    /* Command				       */
	vHdr = vHdr + Char(0) + Char(pCommand);
	// uint32 ui32BodySize;	/* Size of message body        */
	vMap = GetByte2CharIndexMap();
	vHexBodySize = Bin2Hex(Dec2Bin(pBodySize));
	If StrLen(vHexBodySize) = 1 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0) + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 2 Then
		vHdr = vHdr + Char(0) + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 3 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 4 Then
		vHdr = vHdr + Char(0) + Char(0);
	ElsIf StrLen(vHexBodySize) = 5 Then
		vHexBodySize = "0" + vHexBodySize;
		vHdr = vHdr + Char(0);
	ElsIf StrLen(vHexBodySize) = 6 Then
		vHdr = vHdr + Char(0);
	ElsIf StrLen(vHexBodySize) = 7 Then
		vHexBodySize = "0" + vHexBodySize;
	EndIf;
	For i = 1 To StrLen(vHexBodySize)/2 Do
		vHexByte = Mid(vHexBodySize, i, 2);
		vHdr = vHdr + Char(vMap.Get(vHexByte));
	EndDo;
	vHdr = vHdr + ?(pCommand = 4, Char(2), Char(0)) + Char(0) + Char(0);
	// Return
	Return vHdr;
EndFunction // SPMSifHdr

// -----------------------------------------------------------------------------
// Description: Returns binary string representing positive decimal number
// Parameters: Decimal number
// Return value: Binary number presentation as string
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
EndFunction // cmDec2Bin

// -----------------------------------------------------------------------------
// Description: Returns positive decimal number representing binary string
// Parameters: Binary number presentation as string
// Return value: Decimal number
// -----------------------------------------------------------------------------
Function Bin2Dec(pBin) Export
	vDec = 0;
	vLen = StrLen(pBin);
	For i = 1 To vLen Do
		vDec = vDec + Number(Mid(pBin, i, 1)) * Pow(2, (vLen - i));
	EndDo;
	Return vDec;
EndFunction // cmBin2Dec

// -----------------------------------------------------------------------------
// Description: Returns binary string representing binary XOR with two binary numbers
// Parameters: First binary number presentation, Second binary number presentation
// Return value: XOR result binary presentation as string
// -----------------------------------------------------------------------------
Function XOR(Val pBin1, Val pBin2) Export
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
EndFunction // cmXOR

// -----------------------------------------------------------------------------
Function AddTrack1And2(pDLSys, pDta, pAdd = False, pDevice, pParameters)
	SEP = Char(30);
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_NO_CONNECTION = -1;
	RC_OK = 48;

	If pDevice.WriteTrack1 Or pDevice.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, pAdd, , , pDevice.IdentificationCardType);
			vIDCardArr = tcOnServer.cmGetAtributeAsArray(vIDCardRef);
			If ValueIsFilled(vIDCardRef) Then
				pParameters.IdentificationCard = vIDCardRef;
				// Track 1 data: CardIdentifier^FolioNumber^Room^ClientFullName^CheckInDate^CheckOutDate
				If pDevice.WriteTrack1 Then
					vTrack1 = TrimAll(vIDCardArr.Identifier) + "^" +
					          ?(ValueIsFilled(vIDCardArr.Folio), Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Folio,"Number")), True,pDevice.DoGuestNamesTransliteration), "") + "^" + 
					          ?(ValueIsFilled(vIDCardArr.Room), Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Room,"Description")), True, pDevice.DoGuestNamesTransliteration), "") + "^" + 
					          ?(ValueIsFilled(vIDCardArr.Client), Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(vIDCardArr.Client,"FullName")), True, pDevice.DoGuestNamesTransliteration), "") + "^" + 
					          Format(vIDCardRef.DateTimeFrom, "DF='yyMMdd'") + "^" + 
					          Format(vIDCardRef.DateTimeTo, "DF='yyMMdd'");
					pDta = pDta + SEP + "1" + Left(vTrack1, ?(pDevice.Track1Length > 0, pDevice.Track1Length, 76));
				EndIf;
				// Track 2 data: CardIdentifier
				If pDevice.WriteTrack2 Then
					vTrack2 = TrimAll(vIDCardArr.Identifier);
					pDta = pDta + SEP + "2" + Left(vTrack2, 37);
				EndIf;
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
				pmDisconnect(pDLSys, pDevice);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
			pmDisconnect(pDLSys, pDevice);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return RC_OK;
EndFunction // AddTrack1And2	

// -----------------------------------------------------------------------------
Function PMSifEncodeKcdRmt(pDLSys, pReadTimeout, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, pDta, rReply)
	ui32Synch1 = Char(85) + Char(85) + Char(85) + Char(85);
	ui32Synch2 = Char(1028) + Char(1028) + Char(1028) + Char(1028);

	rReply = "";
	// Build header
	vHdr = SPMSifHdr(4, 53);
	// Build message string
	vMsg = vHdr;
	// Dta[512]
	vMsg = vMsg + GetNullTerminatingString(pDta, 513);
	// dd[3]
	vMsg = vMsg + GetNullTerminatingString(pEncoderNumber, 3);
	// ss[3]
	vMsg = vMsg + GetNullTerminatingString(pSourceAddress, 3);
	// Debug
	vMsg = vMsg + Char(0) + Char(0) + Char(0) + Char(0);
	// szOpID[10]
	vMsg = vMsg + GetNullTerminatingString(TrimAll(pOpId), 10);
	// szOpFirst[16]
	vMsg = vMsg + GetNullTerminatingString(TrimAll(pOpFirstName), 16);
	// szOpLast[16]
	vMsg = vMsg + GetNullTerminatingString(TrimAll(pOpLastName), 16);
	// Send PMSifEncodeKcdRmt message
	vReply = "";
	pDLSys.Timeout = pReadTimeout;
	vBytesSent = pDLSys.Write(vMsg, 583);
	If vBytesSent <> -1 Then
		If pDLSys.Read(vReply, 583) <> -1 Then
			If StrLen(vReply) >= StrLen(vHdr) And 
			   Mid(vReply, 1, 4) = ui32Synch1 And 
			   Mid(vReply, 5, 4) = ui32Synch2 Then
				rReply = Mid(vReply, 19);
				Return True;
			Else
				AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + vReply);
			EndIf;
		Else
			AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("ru = 'Ошибка отправки команды на сервер Vision PMS interface: '; en = 'Vision PMS interface server sending command error: '; de = 'Vision PMS interface server sending command error: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	// Close TCP/IP socket
	vErrorCode = pDLSys.Disconnect();
	pDLSys = Undefined;
	// Return failure
	Return False;
EndFunction // PMSifEncodeKcdRmt

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 60000, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, pCommandCode, pDta, pWithRetention = "", pReply, pSystemName)
	pReply = "";
	ACK = Char(6);
	NAK = Char(21);
	STX = Char(2);
	ETX = Char(3);
	RC_NO_REPLY = 103;
	RC_NO_CONNECTION = -1;
	RC_OK = 48;
	RC_SYNTAX_ERROR = 105;
	RC_WRONG_REPLY = 104;
	
	vErrorCode = RC_OK;
	
	// Build command string for the RS232 interface
	vCmd = pEncoderNumber; // Destination address
	vCmd = vCmd + pSourceAddress; // Source address
	vCmd = vCmd + pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	vCmd = vCmd + ETX;
	vCmd = STX + vCmd + HexLRC(vCmd);
	
	// Send acknowledgement
	If Not RS232Acknowledgement(pDLSys) Then
		Return RC_NO_REPLY;
	EndIf;
	
	// Send command and get acknowledgement
	pDLSys.TimeoutReadTotalConstant = 3000;
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
		Return RC_SYNTAX_ERROR;
	EndIf;
	
	// Read command reply message
	vReadOK = False;
	pDLSys.TimeoutReadTotalConstant = pReadTimeout;
	For i = 1 To 3 Do
		pReply = pDLSys.ReadStr();
		If Not IsBlankString(pReply) Then
			// Check LRC
			pReply = StrReplace(pReply, STX, "");
			If CheckHexLRC(pReply) Then
				vBytesSent = pDLSys.WriteStr(ACK);
				vReadOK = True;
				Break;
			Else
				vBytesSent = pDLSys.WriteStr(NAK);
			EndIf;
		Else
			Return RC_NO_REPLY;
		EndIf;
	EndDo;
	If Not vReadOK Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		// Retreive return code
		vErrorCode = CharCode(Mid(pReply, 5, 1));
		// Retreive reply data
		If StrLen(pReply) > 8 Then
			pReply = Mid(pReply, 6, StrLen(pReply) - 8);
		Else
			pReply = "";
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, pCommandCode, pDta, pWithRetention = "", pReply, pSystemName)
	RC_WRONG_REPLY = 104;
	
	// Build command string for the TCP/IP interface
	vCmd = pCommandCode; // Command code
	vCmd = vCmd + pDta; // Command data
	
	// Send command
	If Not PMSifEncodeKcdRmt(pDLSys, pReadTimeout, pEncoderNumber, pSourceAddress, pOpId, pOpFirstName, pOpLastName, vCmd, pReply) Then
		vErrorCode = RC_WRONG_REPLY;
	Else
		vErrorCode = RC_WRONG_REPLY;
		// Retreive reply data
		If StrLen(pReply) > 2 Then
			// Retreive return code
			vErrorCode = CharCode(Mid(pReply, 1, 1));
			// Remove command code
			pReply = Mid(pReply, 3);
		Else
			pReply = "";
		EndIf;
	EndIf;
	Return vErrorCode;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "") Export
	pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	
	SEP = Char(30);
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = 114;
	RC_OK = 48;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION; 
	EndIf;
	
	// Build command data string
	vRoom = pParameters.Room;
	vRoomCode = TrimR(vRoom);
	If ValueIsFilled(vRoom) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		vRoom = pDevice.DefaultRoom;
		pParameters.Room = vRoom;
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom,"LockCode");
		If pDevice.UseRoomLockCodes Then
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
		
	vDta = SEP + "R" + vRoomCode;
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(vRoom) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(vRoom,"DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAtributeAsArray(vDoorLockSystemAuthorization);
	EndIf;	
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.KeyCardType) Then
		vDta = vDta + SEP + "T" + TrimAll(vDoorLockSystemAuthorization.KeyCardType);
	Else
		vDta = vDta + SEP + "T" + TrimAll(pDevice.KeyCardType);
	EndIf;
	If ValueIsFilled(pParameters.Guest) Then
		vDta = vDta + SEP + "F" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "FirstName")));
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName")));
	Else
		vDta = vDta + SEP + "F";
		vDta = vDta + SEP + "N";		
	EndIf;
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + pDevice.UserGroup;
	EndIf;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	// Number of keys
	If pParameters.Property("NumberOfKeys") And TypeOf(pParameters.NumberOfKeys) = Type("Number") And 
	   pParameters.NumberOfKeys > 1 Then
		vDta = vDta + SEP + "C" + Format(pParameters.NumberOfKeys, "ND=2; NFD=0; NG=");
	EndIf;
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False, pDevice, pParameters);
	If vErrorCode <> RC_OK Then // RC_OK = 0
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If pDevice.ReturnCardUID Then
			vDta = vDta + SEP + "S";
		EndIf;
		// Get encoder number
		vEncoderNumber = TrimAll(pDevice.EncoderNumber);
		vOpId = "PMS";
		vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vOpId = Left(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"), 9);
		EndIf;
		vOpFirstName = Left(tcOnServer.cmGetCurrentUserAttribute("FirstName"), 15);
		vOpLastName = Left(tcOnServer.cmGetCurrentUserAttribute("LastName"), 15);
		vSourceAddress = "00";
		If Not IsBlankString(pDevice.PCId) Then
			vSourceAddress = TrimAll(pDevice.PCId);
		EndIf;
		pParameters.Insert("CardUID", "");
		// Call API
		vErrorCode = MakeNewKey(vDLSys, vSourceAddress, vEncoderNumber, vOpId,  vOpFirstName, vOpLastName, vDta, pDevice, pParameters);
		If vErrorCode <> RC_OK Then // RC_OK = 0
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			vErrorCode = 0;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoom) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", pParameters.CardUID, vRoom, "", vCheckInDate, vCheckOutDate, pParameters.FolioNumber, pParameters.Guest);
		EndIf;
		
		pmDisconnect(vDLSys,pDevice);
		Return vErrorCode;
	EndIf;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pDta, pDevice, pParameters)
	// Define default command code equal to "Check Out Old, Check In New"
	If BegOfDay(pParameters.CheckInDate) > BegOfDay(CurrentDate()) Then
		vCommandCode = "G";
	Else
		vCommandCode = "I";
	EndIf;
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vSourceAddress = Format(Number(TrimAll(pSourceAddress)), "ND=2; NFD=0; NZ=; NLZ=; NG=");

	// Choose transport
	If ValueIsFilled(pDevice.ConnectionType) And
	   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, "", vReply, pDevice.SystemName);
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, "", vReply, pDevice.SystemName);
		// Save card UID
		If Not IsBlankString(vReply) And pDevice.ReturnCardUID Then
			vCardUID = tcOnClient.RemoveNonASCIIChars(GetCardUID(vReply));
			pParameters.CardUID = vCardUID;
			If pDevice.DoNotIssuedIdentificationCards = False Then
				If ValueIsFilled(pParameters.IdentificationCard) Then
					tcOnServer.cmWriteAttributeCatalogByRef(pParameters.IdentificationCard, New Structure("CardUID", vCardUID));
				Else
					pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID, , pDevice.IdentificationCardType);
				EndIf;
			EndIf;
		EndIf;
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.VisionIntDll") Then
		// Using VisionInt.dll interface
		vErrorCode = pDLSys.VCMakeNewKey(pSourceAddress, vEncoderNumber, vSourceAddress, pOpLastName, pDta);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function AddKey(pDLSys, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pDta, pDevice, pParameters)
	// Define default command code equal to "Check Out Old, Check In New"
	If BegOfDay(pParameters.CheckInDate) > BegOfDay(CurrentDate()) Then
		vCommandCode = "G";
	Else
		vCommandCode = "H";
	EndIf;
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vSourceAddress = Format(Number(TrimAll(pSourceAddress)), "ND=2; NFD=0; NZ=; NLZ=; NG=");

	// Choose transport
	If ValueIsFilled(pDevice.ConnectionType) And
	   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, "", vReply, pDevice.SystemName);
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 60, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, pDta, "", vReply, pDevice.SystemName);
		// Save card UID
		If Not IsBlankString(vReply) And pDevice.ReturnCardUID Then
			vCardUID = tcOnClient.RemoveNonASCIIChars(GetCardUID(vReply));
			pParameters.CardUID = vCardUID; 
			If pDevice.DoNotIssuedIdentificationCards = False Then
				If ValueIsFilled(pParameters.IdentificationCard) Then
					tcOnServer.cmWriteAttributeCatalogByRef(pParameters.IdentificationCard, New Structure("CardUID", vCardUID));
				Else
					pParameters.IdentificationCard = tcOnServer.GetClientIdentificationCard(vCardUID, tcOnServer.GetClientIdentificationCardById(vCardUID), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, pParameters.CheckInDate, pParameters.CheckOutDate, True, vCardUID, , pDevice.IdentificationCardType);
				EndIf;
			EndIf;
		EndIf;
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.VisionIntDll") Then
		// Using VisionInt.dll interface
		vErrorCode = pDLSys.VCMakeNewKey(pSourceAddress, vEncoderNumber, vSourceAddress, pOpLastName, pDta);	
	EndIf;
	
	Return vErrorCode;
EndFunction // AddKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	//pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	
	SEP = Char(30);
	RC_NO_CONNECTION = -1;
	RC_OK = 48;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION; 
	EndIf;
	
	// Build command data string
	vRoom = pParameters.Room;
	vRoomCode = TrimR(vRoom);
	If ValueIsFilled(vRoom) Then
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		vRoom = pDevice.DefaultRoom;
		pParameters.Room = vRoom;
		vRoomLockCode = tcOnServer.cmGetAttributeByRef(vRoom,"LockCode");
		If pDevice.UseRoomLockCodes Then
			If Not IsBlankString(vRoomLockCode) Then
				vRoomCode = TrimR(vRoomLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return 114; //RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = SEP + "R" + vRoomCode;
	// Authorizations
	vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And
	   ValueIsFilled(vRoom) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(vRoom,"DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAtributeAsArray(vDoorLockSystemAuthorization);
	EndIf;	
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.KeyCardType) Then
		vDta = vDta + SEP + "T" + TrimAll(vDoorLockSystemAuthorization.KeyCardType);
	Else
		vDta = vDta + SEP + "T" + TrimAll(pDevice.KeyCardType);
	EndIf;
	If ValueIsFilled(pParameters.Guest) Then
		vDta = vDta + SEP + "F" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "FirstName")));
		vDta = vDta + SEP + "N" + Transliterate(TrimAll(tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName")));
	Else
		vDta = vDta + SEP + "F";
		vDta = vDta + SEP + "N";		
	EndIf;
	// User group (authorizations)
	If ValueIsFilled(vDoorLockSystemAuthorization) And 
	   Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
		vDta = vDta + SEP + "U" + vDoorLockSystemAuthorization.UserGroup;
	Else
		vDta = vDta + SEP + "U" + pDevice.UserGroup;
	EndIf;
	// Check in and check out dates
	vCheckInDate = pParameters.CheckInDate;
	If pDevice.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
	EndIf;
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + SEP + "D" + Format(vCheckInDate,"DF=yyyyMMddHHmm");
	vDta = vDta + SEP + "O" + Format(vCheckOutDate,"DF=yyyyMMddHHmm");
	
	// Add tack 1 and track 2 data if necessary
	vErrorCode = AddTrack1And2(vDLSys, vDta, False,pDevice,pParameters);
	If vErrorCode <> RC_OK Then // RC_OK = 0
		Return vErrorCode;
	Else
		// Ask interface to return key card unique ID
		If pDevice.ReturnCardUID Then
			vDta = vDta + SEP + "S";
		EndIf;
		// Get encoder number
		vEncoderNumber = TrimAll(pDevice.EncoderNumber);
		vOpId = "PMS";
		vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vOpId = Left(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"), 9);
		EndIf;
		vOpFirstName = Left(tcOnServer.cmGetCurrentUserAttribute("FirstName"), 15);
		vOpLastName = Left(tcOnServer.cmGetCurrentUserAttribute("LastName"), 15);
		vSourceAddress = "00";
		If Not IsBlankString(pDevice.PCId) Then
			vSourceAddress = TrimAll(pDevice.PCId);
		EndIf;
		pParameters.Insert("CardUID", "");
		// Call API
		vErrorCode = AddKey(vDLSys, vSourceAddress, vEncoderNumber, vOpId,  vOpFirstName, vOpLastName, vDta, pDevice, pParameters);
		If vErrorCode <> RC_OK Then // RC_OK = 0
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			vErrorCode = 0;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(vRoom) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
			tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", pParameters.CardUID, vRoom, "", vCheckInDate, vCheckOutDate, pParameters.FolioNumber, pParameters.Guest);
		EndIf;
		
		pmDisconnect(vDLSys,pDevice);
		Return vErrorCode;
	EndIf;
EndFunction // pmAddKey

// -----------------------------------------------------------------------------
Function pmVerify(pCardData, pDevice, pParameters) Export
	SEP = Char(30);
	RC_NO_CONNECTION = -1;
	RC_UNKNOWN = 49;
	RC_OK = 48;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION; 
	EndIf;
	
	// Get encoder number
	vEncoderNumber = TrimAll(pDevice.EncoderNumber);
	vOpId = "PMS";
	vEmployeePreferences = tcOnServer.cmGetCurrentUserAttribute("EmployeePreferences");
	If ValueIsFilled(vEmployeePreferences) Then
		vOpId = Left(tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin"), 9);
	EndIf;
	vOpFirstName = Left(tcOnServer.cmGetCurrentUserAttribute("FirstName"), 15);
	vOpLastName = Left(tcOnServer.cmGetCurrentUserAttribute("LastName"), 15);
	vSourceAddress = "00";
	If Not IsBlankString(pDevice.PCId) Then
		vSourceAddress = TrimAll(pDevice.PCId);
	EndIf;
	
	// Call API
	vCardDesc = "";
	vErrorCode = Verify(vDLSys, vSourceAddress, vEncoderNumber, vOpId, vOpFirstName, vOpLastName, vCardDesc, pDevice);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		pCardData = pmParseCardDescription(vCardDesc, pDevice.Hotel);
		vErrorCode = 0;
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pSourceAddress, pEncoderNumber, pOpId, pOpFirstName, pOpLastName, pCardDesc, pDevice)
	RC_OK = 48;
	RC_UNKNOWN = 49;
	
	// Define default command code equal to "Check card"
	vCommandCode = "E";
	vErrorCode = RC_OK;
	pCardDesc = "";
	// Format encoder number and source address
	vEncoderNumber = Format(Number(TrimAll(pEncoderNumber)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	vSourceAddress = Format(Number(TrimAll(pSourceAddress)), "ND=2; NFD=0; NZ=; NLZ=; NG=");
	// Choose transport
	If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Send command and process reply
		vReply = "";
		vErrorCode = CallRS232Command(pDLSys, 60000, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, "", "", vReply, pDevice.SystemName);
		// Retrieve card data
		If vErrorCode = RC_OK Then
			pCardDesc = vReply;
		ElsIf vErrorCode = RC_UNKNOWN Then
			// Card was not recognized
			vErrorCode = RC_OK;
		EndIf;
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		// Using TCP/IP interface
		vReply = "";
		vErrorCode = CallTCPCommand(pDLSys, 30, vEncoderNumber, vSourceAddress, pOpId, pOpFirstName, pOpLastName, vCommandCode, "", "", vReply, pDevice.SystemName);
		// Retrieve card data
		If vErrorCode = RC_OK Then
			pCardDesc = vReply;
		ElsIf vErrorCode = RC_UNKNOWN Then
			// Card was not recognized
			vErrorCode = RC_OK;
		EndIf;
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.VisionIntDll") Then
		// Using VisionInt.dll interface
		pCardDesc = pDLSys.VCVerify(vSourceAddress, vEncoderNumber, pOpFirstName, pOpLastName);
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc, pHotel)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("CardType", "");
	vCardData.Insert("CardUserGroup", "");
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
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
	
	vDataLen = StrLen(pCardDesc);
	While vDataLen > 0 Do
		vWord = GetNextWord(pCardDesc);
		vDataLen = StrLen(pCardDesc);
		FillParameter(vCardData, vWord);
	EndDo;

	// Try to retrieve card authorizations
	vAuthRef = tcOnServer.qmFindAuthorizations(pHotel, vCardData.AssignedAuthorizations);
	If ValueIsFilled(vAuthRef) Then
		vCardData.CardAuthorizations = TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Code")) + " - " + TrimAll(tcOnServer.cmGetAttributeByRef(vAuthRef, "Description"));
	EndIf;

	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	SEP = Char(30);
	If pDelimeter = "" Then
		pDelimeter = SEP;
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
Function GetDate(pDateStr)
	Try
		If Not IsBlankString(pDateStr) Then
			If StrLen(pDateStr) > 11 Then
				vHour = Mid(pDateStr,9, 2);
				vMinute = Mid(pDateStr,11, 2);
				vDay = Mid(pDateStr, 7, 2);
				vMonth = Mid(pDateStr, 5, 2);
				vYear = Mid(pDateStr, 1, 4);
			ElsIf StrLen(pDateStr) > 8 Then
				vHour = Mid(pDateStr, 2);
				vMinute = Mid(pDateStr, 3, 2);
				vDay = Mid(pDateStr, 5, 2);
				vMonth = Mid(pDateStr, 7, 2);
				vYear = "20" + Mid(pDateStr, 9, 2);
			Else
				vHour = Left(pDateStr, 2);
				vMinute = "0";
				vDay = Mid(pDateStr, 3, 2);
				vMonth = Mid(pDateStr, 5, 2);
				vYear = "20" + Mid(pDateStr, 7, 2);
			EndIf;
			Return Date(Number(vYear), Number(vMonth), Number(vDay), Number(vHour), Number(vMinute), 0);
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction // GetDate

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	vSystemName = pSystemName;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_OK = 48;
	RC_UNKNOWN = 49;
	RC_NO_VISION = 50;
	RC_DEVICE_IS_BUSY = 53;
	RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK = 54;
	RC_DEVICE_TIME_OUT = 56;
	RC_NO_GUEST_PREVIOUSLY_CHECKED_IN = 57;
	RC_WRONG_CHECK_IN_TIME = 68;
	RC_WRONG_CHECK_OUT_TIME = 79;
	RC_WRONG_ROOM = 82;
	RC_NO_FOLIO = 101;
	RC_NO_ID_CARD = 102;
	RC_NO_REPLY = 103;
	RC_WRONG_REPLY = 104;
	RC_SYNTAX_ERROR = 105;
	RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = 95;

	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + vSystemName + "!'; 
		            |de = 'Failed to connect to the door locks system " + vSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + vSystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = RC_DEVICE_IS_BUSY Then
		Return(NStr("ru = 'Энкодер карт используется другим приложением!'; 
		            |de = 'Cards encoder is in use by another application!';
		            |en = 'Cards encoder is in use by another application!'"));
	ElsIf pRC = RC_NO_MORE_ROOM_FOR_CARDS_IN_LOCK Then
		Return(NStr("ru = 'На номер уже выписано максимальное число дополнительных карт!'; 
		            |de = 'Maximum number of key cards is reached for the room!'; 
		            |en = 'Maximum number of key cards is reached for the room!'"));
	ElsIf pRC = RC_NO_GUEST_PREVIOUSLY_CHECKED_IN Then
		Return(NStr("en='No checked in guests in the room! Make new key card instead.';ru='В номере нет размещенных гостей! Выдайте гостю новую карту.';de='In diesem Zimmer sind keine Gäste untergebracht! Geben Sie dem Gast eine neue Karte heraus.'"));
	ElsIf pRC = RC_WRONG_CHECK_IN_TIME Then
		Return(NStr("ru = 'Неверно указано время заезда!'; 
		            |de = 'Check in time is wrong!'; 
		            |en = 'Check in time is wrong!'"));
	ElsIf pRC = RC_WRONG_CHECK_OUT_TIME Then
		Return(NStr("ru = 'Неверно указано время выезда!'; 
		            |de = 'Check out time is wrong!';
		            |en = 'Check out time is wrong!'"));
	ElsIf pRC = RC_WRONG_ROOM Then
		Return(NStr("en='Room is wrong!';ru='Номер комнаты указан неверно!';de='Die Zimmernummer ist falsch!'"));
	ElsIf pRC = RC_NO_VISION Then
		Return(NStr("ru = 'Не запущен VISION!'; 
		            |de = 'VISION is not started!'; 
		            |en = 'VISION is not started!'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + vSystemName + " не отвечает!'; 
		            |de = '" + vSystemName + " system is not responding!'; 
		            |en = '" + vSystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + vSystemName + " получен ответ в неизвестном формате!'; 
		            |de = '" + vSystemName + " system replied with unknown format!'; 
		            |en = '" + vSystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_DEVICE_TIME_OUT Then
		Return(NStr("en='Device time-out!';
		            |de='Device time-out!';
			        |ru='Время ожидания карты истекло!'"));
	ElsIf pRC = RC_SYNTAX_ERROR Then
		Return(NStr("en='The message is not correct (unknown command, nonsense parameters, prohibited characters, ...)!';ru='Неверный формат команды (возможно встретились запрещенные символы)!';de='Falsches Befehlformat (möglicherweise kommen verbotene Symbole vor)!'"));
	ElsIf pRC = RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	EndIf;		
EndFunction // pmGetErrorDescription

// -----------------------------------------------------------------------------
Procedure FillParameter(pCardData, pWord)
	If StrLen(pWord) <=1 Then
		Return;
	EndIf;
	vCommand = Left(pWord, 1);
	If vCommand = "R" Then
		pCardData.CardRoom = Right(pWord,StrLen(pWord)-1);
	ElsIf vCommand = "L" Then
		pCardData.CardRoom2 = GetNextWord(pWord, ",");
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom3 = GetNextWord(pWord, ",");
		EndIf;
		If Not IsBlankString(pWord) Then
			pCardData.CardRoom4 = GetNextWord(pWord, ",");
		EndIf;
	ElsIf vCommand = "T" Then
		pCardData.CardType = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "F" Then
	   pCardData.CardFirstName = Right(pWord,StrLen(pWord)-1);
	   pCardData.CardFullName = TrimAll(pCardData.CardLastName)+" "+TrimAll(pCardData.CardFirstName);
	ElsIf vCommand = "N" Then
		pCardData.CardLastName = Right(pWord,StrLen(pWord)-1);
		pCardData.CardFullName = TrimAll(pCardData.CardLastName)+" "+TrimAll(pCardData.CardFirstName);
	ElsIf vCommand = "U" Then
		pCardData.CardUserGroup = Right(pWord,StrLen(pWord)-1);	
	ElsIf vCommand = "D" Then
		pCardData.CardCheckInDate = GetDate(Right(pWord,StrLen(pWord)-1));	
	ElsIf vCommand = "O" Then
		pCardData.CardCheckOutDate = GetDate(Right(pWord,StrLen(pWord)-1));		
	ElsIf vCommand = "S" Then
		vCardIdentifier = "";
		pCardData.CardID = GetCardIdentifier(Right(pWord,StrLen(pWord)-1));
		If StrLen(pCardData.CardID) = 14 Then
			vCardIdentifier = TrimAll(Mid(pCardData.CardID, 7)) + TrimAll(Left(pCardData.CardID, 6));
		Else
			vCardIdentifier = TrimAll(pCardData.CardID);
		EndIf;
		If Not IsBlankString(vCardIdentifier) Then
			vIDCardRef = tcOnServer.cmGetCatalogItemRefByAttribute("IdentificationCards","Identifier",false,pCardData.CardID);
			If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.Client) Then
				pCardData.CardFullName = tcOnServer.cmGetAttributeByRef(vIDCardRef.Client,"FullName");
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // FillParameter

// -----------------------------------------------------------------------------
Function GetCardIdentifier(pCardData) 
	vCardID = pCardData;
	If StrLen(pCardData) > 3 Then
		// Remove prefix and suffix chars
		If Right(pCardData, 3) = "+++" Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 3);
		ElsIf Right(pCardData, 2) = "?," Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 2);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 186 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Left(pCardData, 1) = ";" And Mid(pCardData, 14, 1) = "?" Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Upper(Right(pCardData, 7)) = "NO CARD" And StrLen(TrimAll(pCardData)) > 7 Then
			vCardID = TrimAll(Left(TrimAll(pCardData), StrLen(TrimAll(pCardData)) - 7));
		EndIf;
	Else
		vCardID = "";
	EndIf;
	Return vCardID;
EndFunction // cmGetCardIdentifier

// -----------------------------------------------------------------------------
// Description: Returns map to get char index value for the appropriate hex byte
// Parameters: None
// Return value: Char/Index Map
// -----------------------------------------------------------------------------
Function GetByte2CharIndexMap()
	vMap = New Map();
	
	vMap.Insert("00", 0);
	vMap.Insert("01", 1);
	vMap.Insert("02", 2);
	vMap.Insert("03", 3);
	vMap.Insert("04", 4);
	vMap.Insert("05", 5);
	vMap.Insert("06", 6);
	vMap.Insert("07", 7);
	vMap.Insert("08", 8);
	vMap.Insert("09", 9);
	vMap.Insert("0A", 10);
	vMap.Insert("0B", 11);
	vMap.Insert("0C", 12);
	vMap.Insert("0D", 13);
	vMap.Insert("0E", 14);
	vMap.Insert("0F", 15);
	
	vMap.Insert("10", 16);
	vMap.Insert("11", 17);
	vMap.Insert("12", 18);
	vMap.Insert("13", 19);
	vMap.Insert("14", 20);
	vMap.Insert("15", 21);
	vMap.Insert("16", 22);
	vMap.Insert("17", 23);
	vMap.Insert("18", 24);
	vMap.Insert("19", 25);
	vMap.Insert("1A", 26);
	vMap.Insert("1B", 27);
	vMap.Insert("1C", 28);
	vMap.Insert("1D", 29);
	vMap.Insert("1E", 30);
	vMap.Insert("1F", 31);
	
	vMap.Insert("20", 32);
	vMap.Insert("21", 33);
	vMap.Insert("22", 34);
	vMap.Insert("23", 35);
	vMap.Insert("24", 36);
	vMap.Insert("25", 37);
	vMap.Insert("26", 38);
	vMap.Insert("27", 39);
	vMap.Insert("28", 40);
	vMap.Insert("29", 41);
	vMap.Insert("2A", 42);
	vMap.Insert("2B", 43);
	vMap.Insert("2C", 44);
	vMap.Insert("2D", 45);
	vMap.Insert("2E", 46);
	vMap.Insert("2F", 47);
	
	vMap.Insert("30", 48);
	vMap.Insert("31", 49);
	vMap.Insert("32", 50);
	vMap.Insert("33", 51);
	vMap.Insert("34", 52);
	vMap.Insert("35", 53);
	vMap.Insert("36", 54);
	vMap.Insert("37", 55);
	vMap.Insert("38", 56);
	vMap.Insert("39", 57);
	vMap.Insert("3A", 58);
	vMap.Insert("3B", 59);
	vMap.Insert("3C", 60);
	vMap.Insert("3D", 61);
	vMap.Insert("3E", 62);
	vMap.Insert("3F", 63);
	
	vMap.Insert("40", 64);
	vMap.Insert("41", 65);
	vMap.Insert("42", 66);
	vMap.Insert("43", 67);
	vMap.Insert("44", 68);
	vMap.Insert("45", 69);
	vMap.Insert("46", 70);
	vMap.Insert("47", 71);
	vMap.Insert("48", 72);
	vMap.Insert("49", 73);
	vMap.Insert("4A", 74);
	vMap.Insert("4B", 75);
	vMap.Insert("4C", 76);
	vMap.Insert("4D", 77);
	vMap.Insert("4E", 78);
	vMap.Insert("4F", 79);
	
	vMap.Insert("50", 80);
	vMap.Insert("51", 81);
	vMap.Insert("52", 82);
	vMap.Insert("53", 83);
	vMap.Insert("54", 84);
	vMap.Insert("55", 85);
	vMap.Insert("56", 86);
	vMap.Insert("57", 87);
	vMap.Insert("58", 88);
	vMap.Insert("59", 89);
	vMap.Insert("5A", 90);
	vMap.Insert("5B", 91);
	vMap.Insert("5C", 92);
	vMap.Insert("5D", 93);
	vMap.Insert("5E", 94);
	vMap.Insert("5F", 95);
	
	vMap.Insert("60", 96);
	vMap.Insert("61", 97);
	vMap.Insert("62", 98);
	vMap.Insert("63", 99);
	vMap.Insert("64", 100);
	vMap.Insert("65", 101);
	vMap.Insert("66", 102);
	vMap.Insert("67", 103);
	vMap.Insert("68", 104);
	vMap.Insert("69", 105);
	vMap.Insert("6A", 106);
	vMap.Insert("6B", 107);
	vMap.Insert("6C", 108);
	vMap.Insert("6D", 109);
	vMap.Insert("6E", 110);
	vMap.Insert("6F", 111);
	
	vMap.Insert("70", 112);
	vMap.Insert("71", 113);
	vMap.Insert("72", 114);
	vMap.Insert("73", 115);
	vMap.Insert("74", 116);
	vMap.Insert("75", 117);
	vMap.Insert("76", 118);
	vMap.Insert("77", 119);
	vMap.Insert("78", 120);
	vMap.Insert("79", 121);
	vMap.Insert("7A", 122);
	vMap.Insert("7B", 123);
	vMap.Insert("7C", 124);
	vMap.Insert("7D", 125);
	vMap.Insert("7E", 126);
	vMap.Insert("7F", 127);
	
	vMap.Insert("80", 1026);
	vMap.Insert("81", 1027);
	vMap.Insert("82", 8218);
	vMap.Insert("83", 1107);
	vMap.Insert("84", 8222);
	vMap.Insert("85", 8230);
	vMap.Insert("86", 8224);
	vMap.Insert("87", 8225);
	vMap.Insert("88", 8364);
	vMap.Insert("89", 8240);
	vMap.Insert("8A", 1033);
	vMap.Insert("8B", 8249);
	vMap.Insert("8C", 1034);
	vMap.Insert("8D", 1036);
	vMap.Insert("8E", 1035);
	vMap.Insert("8F", 1039);
	
	vMap.Insert("90", 1106);
	vMap.Insert("91", 8216);
	vMap.Insert("92", 8217);
	vMap.Insert("93", 8220);
	vMap.Insert("94", 8221);
	vMap.Insert("95", 8226);
	vMap.Insert("96", 8211);
	vMap.Insert("97", 8212);
	vMap.Insert("98", 152);
	vMap.Insert("99", 8482);
	vMap.Insert("9A", 1113);
	vMap.Insert("9B", 8250);
	vMap.Insert("9C", 1114);
	vMap.Insert("9D", 1116);
	vMap.Insert("9E", 1115);
	vMap.Insert("9F", 1119);
	
	vMap.Insert("A0", 160);
	vMap.Insert("A1", 1038);
	vMap.Insert("A2", 1118);
	vMap.Insert("A3", 1032);
	vMap.Insert("A4", 164);
	vMap.Insert("A5", 1168);
	vMap.Insert("A6", 166);
	vMap.Insert("A7", 167);
	vMap.Insert("A8", 1025);
	vMap.Insert("A9", 169);
	vMap.Insert("AA", 1028);
	vMap.Insert("AB", 171);
	vMap.Insert("AC", 172);
	vMap.Insert("AD", 173);
	vMap.Insert("AE", 174);
	vMap.Insert("AF", 1031);
	
	vMap.Insert("B0", 176);
	vMap.Insert("B1", 177);
	vMap.Insert("B2", 1030);
	vMap.Insert("B3", 1110);
	vMap.Insert("B4", 1169);
	vMap.Insert("B5", 181);
	vMap.Insert("B6", 182);
	vMap.Insert("B7", 183);
	vMap.Insert("B8", 1105);
	vMap.Insert("B9", 8470);
	vMap.Insert("BA", 1108);
	vMap.Insert("BB", 187);
	vMap.Insert("BC", 1112);
	vMap.Insert("BD", 1029);
	vMap.Insert("BE", 1109);
	vMap.Insert("BF", 1111);
	
	vMap.Insert("C0", 1040);
	vMap.Insert("C1", 1041);
	vMap.Insert("C2", 1042);
	vMap.Insert("C3", 1043);
	vMap.Insert("C4", 1044);
	vMap.Insert("C5", 1045);
	vMap.Insert("C6", 1046);
	vMap.Insert("C7", 1047);
	vMap.Insert("C8", 1048);
	vMap.Insert("C9", 1049);
	vMap.Insert("CA", 1050);
	vMap.Insert("CB", 1051);
	vMap.Insert("CC", 1052);
	vMap.Insert("CD", 1053);
	vMap.Insert("CE", 1054);
	vMap.Insert("CF", 1055);
	
	vMap.Insert("D0", 1056);
	vMap.Insert("D1", 1057);
	vMap.Insert("D2", 1058);
	vMap.Insert("D3", 1059);
	vMap.Insert("D4", 1060);
	vMap.Insert("D5", 1061);
	vMap.Insert("D6", 1062);
	vMap.Insert("D7", 1063);
	vMap.Insert("D8", 1064);
	vMap.Insert("D9", 1065);
	vMap.Insert("DA", 1066);
	vMap.Insert("DB", 1067);
	vMap.Insert("DC", 1068);
	vMap.Insert("DD", 1069);
	vMap.Insert("DE", 1070);
	vMap.Insert("DF", 1071);
	
	vMap.Insert("E0", 1072);
	vMap.Insert("E1", 1073);
	vMap.Insert("E2", 1074);
	vMap.Insert("E3", 1075);
	vMap.Insert("E4", 1076);
	vMap.Insert("E5", 1077);
	vMap.Insert("E6", 1078);
	vMap.Insert("E7", 1079);
	vMap.Insert("E8", 1080);
	vMap.Insert("E9", 1081);
	vMap.Insert("EA", 1082);
	vMap.Insert("EB", 1083);
	vMap.Insert("EC", 1084);
	vMap.Insert("ED", 1085);
	vMap.Insert("EE", 1086);
	vMap.Insert("EF", 1087);
	
	vMap.Insert("F0", 1088);
	vMap.Insert("F1", 1089);
	vMap.Insert("F2", 1090);
	vMap.Insert("F3", 1091);
	vMap.Insert("F4", 1092);
	vMap.Insert("F5", 1093);
	vMap.Insert("F6", 1094);
	vMap.Insert("F7", 1095);
	vMap.Insert("F8", 1096);
	vMap.Insert("F9", 1097);
	vMap.Insert("FA", 1098);
	vMap.Insert("FB", 1099);
	vMap.Insert("FC", 1100);
	vMap.Insert("FD", 1101);
	vMap.Insert("FE", 1102);
	vMap.Insert("FF", 1103);
	
	Return vMap;
EndFunction // cmGetByte2CharIndexMap

// -----------------------------------------------------------------------------
// Description: Returns hex string representing binary string
// Parameters: Binary number presentation as string
// Return value: Hex number presentation as string
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
// Description: Checks longitudinal redundancy check sum for the input 
//              character string. Last two chars of string are assumed to be 
//              input check sum to be compared with new calculated one.
// Parameters: Character string to process
// Return value: True if check sum is right, false if not
// -----------------------------------------------------------------------------
Function CheckHexLRC(pStr) 
	vNewHexLRC = HexLRC(Left(pStr, StrLen(pStr)-2));
	vInpHexLRC = Right(pStr, 2);
	If vNewHexLRC = vInpHexLRC Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // cmCheckHexLRC

// -----------------------------------------------------------------------------
// Description: Calculates hex number returned as string representing 
//              longitudinal redundancy check sum for the input character string
// Parameters: Character string to process
// Return value: 2 LRC chars
// -----------------------------------------------------------------------------
Function HexLRC(pStr) 
	vBinLRC = "00000000";
	For i = 1 To StrLen(pStr) Do
		vBinLRC = XOR(vBinLRC, Dec2Bin(CharCode(Mid(pStr, i, 1))));
	EndDo;
	Return Bin2Hex(vBinLRC);
EndFunction // cmHexLRC

// -----------------------------------------------------------------------------
// Description: Returns null terminating string of given length
// Parameters: String to be encoded, Target string length
// Return value: Right padded with blanks to the specified length null terminating string
// -----------------------------------------------------------------------------
Function GetNullTerminatingString(pStr, pLen) 
	vStr = "";
	vStrLen = StrLen(pStr);
	If vStrLen >= (pLen - 1) Then
		vStr = Left(pStr, (pLen - 1)) + Char(0);
	Else
		vStr = pStr;
		For i = 1 To (pLen - vStrLen - 1) Do
			vStr = vStr + Char(0);
		EndDo;
		vStr = vStr + Char(0);
	EndIf;		
	Return vStr;
EndFunction // GetNullTerminatingString

// -----------------------------------------------------------------------------
Function PMSifRegister(pDLSys, pReadTimeout = 60, pDevice)
	ui32Synch1 = Char(85) + Char(85) + Char(85) + Char(85);
	ui32Synch2 = Char(1028) + Char(1028) + Char(1028) + Char(1028);
	nRetOK = Char(0) + Char(0) + Char(0) + Char(0);
	
	// Build message string
	vHdr = SPMSifHdr(1, 44);
	vMsg = vHdr + GetNullTerminatingString(TrimAll(pDevice.LicenseCode), 20);
	vMsg = vMsg + GetNullTerminatingString("1CHOTEL", 20);
	vMsg = vMsg + nRetOK;
	// Send PMSifRegister message
	vReply = "";
	pDLSys.Timeout = pReadTimeout;
	vBytesSent = pDLSys.Write(vMsg, 62);
	If vBytesSent <> -1 Then
		If pDLSys.Read(vReply, 62) <> -1 Then
			If StrLen(vReply) >= StrLen(vHdr) And 
			   Mid(vReply, 1, 4) = ui32Synch1 And 
			   Mid(vReply, 5, 4) = ui32Synch2 Then
				nRet = Right(vReply, 4);
				If nRet = nRetOK Then
					Return True;
				Else
					AddError(NStr("ru = 'При регистрации на сервере Vision PMS interface получен код ошибки: '; en = 'Error return code received after Vision PMS interface server registration: '; de = 'Error return code received after Vision PMS interface server registration: '") + nRet);
				EndIf;
			Else
				AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + vReply);
			EndIf;
		Else
			AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		EndIf;
	Else
		AddError(NStr("ru = 'Ошибка регистрации на сервере Vision PMS interface: '; en = 'Vision PMS interface server registration error: '; de = 'Vision PMS interface server registration error: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
	EndIf;
	// Close TCP/IP socket
	vErrorCode = pDLSys.Disconnect();
	pDLSys = Undefined;
	// Return failure
	Return False;
EndFunction // PMSifRegister

// -----------------------------------------------------------------------------
Function GetCardUID(pReply)
 	SEP = Char(0);
	vCardUID = "";
	vIdIsFound = Find(pReply, "S");
	If vIdIsFound > 0 Then
		vCardUID = Mid(pReply, vIdIsFound + 1);
		If Left(vCardUID,1) = SEP Then
			Return "";
		EndIf;	
		vSepIsFound = Find(vCardUID, SEP);
		If vSepIsFound > 1 Then
			vCardUID = Left(vCardUID, vSepIsFound - 1);
		EndIf;
	EndIf;
	If StrLen(vCardUID) = 14 Then
		vCardUID = TrimAll(Mid(vCardUID, 7, 8)) + TrimAll(Left(vCardUID, 6));
	ElsIf StrLen(vCardUID) = 16 Then 	
		vBuffer = GetBinaryDataBufferFromHexString(vCardUID);
		vCardUID = GetHexStringFromBinaryDataBuffer(vBuffer.Reverse());
	Else
		vCardUID = TrimAll(vCardUID);
	EndIf;
	Return vCardUID;
EndFunction // GetCardUID