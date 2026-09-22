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
	tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='DoorLockSystem.Error'"), "Warning", , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString(pDevice)
	vStr = ""; // "9600,E,8,1" by default
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
		vStr = vStr + ",E";
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
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function pmConnect(pDevice)
	If Not ValueIsFilled(pDevice.Ref) Then
		Return Undefined;
	EndIf;
	
	vDLSys = Undefined;
	#IF NOT MobileClient THEN
		Try
			// Build ActiveX object to work with
			If ValueIsFilled(pDevice.ConnectionType) And
			   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
				vDLSys = New COMObject("SPort.SPortAx.1");
				// Set connection parameters
				vDLSys.InitString(GetCOMPortConnectionString(pDevice));
				// Open COM port
				vIsOpen = vDLSys.Open(TrimAll(pDevice.Port));
				If Not vIsOpen Then
					AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden:'") + TrimAll(pDevice.Port));
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
			ElsIf ValueIsFilled(pDevice.ConnectionType) And
			      pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
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
				vDLSys.Timeout = 30; // 30 seconds blocking read timeout by default
				vErrorCode = vDLSys.Connect(TrimAll(pDevice.ServerName), ?(IsBlankString(pDevice.Port), 4000, Number(TrimAll(pDevice.Port))));
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Не найден сервер системы электронных замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system server was not found: '; de = '" + pDevice.SystemName + " system server was not found: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
					Return Undefined;
				EndIf;
			Else
				AddError(NStr("ru = 'Подключение по протоколам отличным от TCP и RS232 не поддерживается системами электронных замков " + pDevice.SystemName + "!'; 
							  |en = '" + pDevice.SystemName + " door lock system do support TCP or RS232 connection only!';
							  |de = '" + pDevice.SystemName + " door lock system do support TCP or RS232 connection only!'"));
				Return Undefined;
			EndIf;
		Except
			AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + pDevice.SystemName + ": '; 
						  |en = '" + pDevice.SystemName + " door lock system connection error: ';
						  |de = '" + pDevice.SystemName + " door lock system connection error: '") + ErrorDescription());
			Return Undefined;
		EndTry;
	#ENDIF
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys, pDevice)
	Try
		If ValueIsFilled(pDevice.ConnectionType) And
		   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
			pDLSys.Close();
		ElsIf ValueIsFilled(pDevice.ConnectionType) And
		      pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
			If pDLSys <> Undefined Then
				// Close TCP/IP socket
				vErrorCode = pDLSys.Disconnect();
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " server disconnect error: '; de = '" + pDevice.SystemName + " server disconnect error: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
					Return;
				EndIf;
			EndIf;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + pDevice.SystemName + ": '; en = '" + pDevice.SystemName + " system disconnect error: '; de = '" + pDevice.SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDevice, pParameters, pDta, pAdd = False)
	RC_OK = 0;
	RC_NO_FOLIO = -101;
	RC_NO_ID_CARD = -102;
	
	If pDevice.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(pParameters.Folio) Then
			vIDCardRef = tcOnServer.GetClientIdentificationCard("", Undefined, pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, CurrentDate(), pParameters.CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				If pParameters.Property("IdentificationCard") Then
					pParameters.IdentificationCard = vIDCardRef;
				EndIf;
				// Track 2 data: CardIdentifier
				vTrack2 = Format(tcOnServer.cmGetAttributeByRef(vIDCardRef, "Identifier"), "ND=12; NFD=0; NZ=; NLZ=; NG=");
				pDta = pDta + "T2" + vTrack2 + ";";
			Else
				vErrorCode = RC_NO_ID_CARD;
				AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
				pmDisconnect(pDLSys, pDevice);
				Return vErrorCode;
			EndIf;
		Else
			vErrorCode = RC_NO_FOLIO;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
			pmDisconnect(pDLSys, pDevice);
			Return vErrorCode;
		EndIf;
	EndIf;
	Return RC_OK;
EndFunction // AddTrack2

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pDevice, pReadTimeout = 3000, pEncoderNumber, pCommandCode, pDta, rReply = "", rErrorDescription = "")
	ACK = Char(6);
	NAK = Char(21);
	STX = Char(2);
	ETX = Char(3);
	
	RC_OK = 0;
	RC_NO_REPLY = -103;
	RC_WRONG_REPLY = -104;
	RC_NO_CONNECTION = -1;
	RC_DATA_ERROR = -209;
	
	rErrorDescription = "";
	
	// Build command string for the RS232 interface
	vCmd = "";
	// Command code
	vCmd = vCmd + pCommandCode;
	// Answer mode synchronous
	vCmd = vCmd + "AM1;";
	// Encoder number
	If Not IsBlankString(pEncoderNumber) Then
		vCmd = vCmd + "EA" + pEncoderNumber + ";";
	EndIf;
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = STX + vCmd + tcDoorLocksAtServer.HexLRC(STX + vCmd) + ETX;
	
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
	
	// Read reply
	vReply = pDLSys.ReadStr();
	If Not IsBlankString(vReply) Then
		If Left(vReply, 2) = "CC" Then
			// Check return code
			vRCCodePos = Find(vReply, ";RC");
			If vRCCodePos > 0 Then
				vRCCode1 = Mid(vReply, vRCCodePos + 3, 1);
				vRCCode2 = Mid(vReply, vRCCodePos + 3, 2);
				If pCommandCode <> "CCB;" And vRCCode1 <> "0" Or pCommandCode = "CCB;" And vRCCode2 <> "13" Then
					vErrTextPos = Find(vReply, ";ET");
					If vErrTextPos > 0 Then
						rErrorDescription = Mid(vReply, vErrTextPos + 3);
						vEndOfErrorTextPos = Find(rErrorDescription, ";");
						If vEndOfErrorTextPos > 0 Then
							rErrorDescription = Left(rErrorDescription, vEndOfErrorTextPos - 1);
						EndIf;
					EndIf;
					Return vRCCode2;
				EndIf;
			Else
				pDLSys.PurgeQueue();
				Return RC_WRONG_REPLY;
			EndIf;
		ElsIf vReply <> NAK Then
			pDLSys.PurgeQueue();
			Return RC_WRONG_REPLY;
		EndIf;
	Else
		pDLSys.PurgeQueue();
		Return RC_NO_REPLY;
	EndIf;
	
	// Clear returned data from
	rReply = Mid(vReply, vRCCodePos + 4);
	
	// Return success
	Return RC_OK;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pDevice, pReadTimeout = 60, pEncoderNumber, pCommandCode, pDta, rReply = "", rErrorDescription = "")
	NAK = Char(21);
	
	RC_OK = 0;
	RC_WRONG_REPLY = -104;
	RC_NO_CONNECTION = -1;
	
	rErrorDescription = "";
	
	// Build command string for the TCP interface
	vCmd = "";
	// Command code
	vCmd = vCmd + pCommandCode;
	// Answer mode synchronous
	vCmd = vCmd + "AM1;";
	// Encoder number
	If Not IsBlankString(pEncoderNumber) Then
		vCmd = vCmd + "EA" + pEncoderNumber + ";";
	EndIf;
	// Source address
	vSourceAddress = TrimAll(pDevice.PCId);
	If Not IsBlankString(vSourceAddress) Then
		vCmd = vCmd + "TA" + vSourceAddress;
	EndIf;
	// Command data tags
	vCmd = vCmd + pDta;
	// Command start and end chars
	vCmd = vCmd + Chars.CR + Chars.LF;
	
	// Send command and get acknowledgement
	vReply = "";
	vRCCodePos = 0;
	If pDLSys.Write(vCmd, StrLen(vCmd)) <> -1 Then
		If pDLSys.Read(vReply, 1024) <> -1 Then
			If Left(vReply, 2) = "CC" Then
				// Check return code
				vRCCodePos = Find(vReply, ";RC");
				If vRCCodePos > 0 Then
					vRCCode1 = Mid(vReply, vRCCodePos + 3, 1);
					vRCCode2 = Mid(vReply, vRCCodePos + 3, 2);
					If pCommandCode <> "CCB;" And vRCCode1 <> "0" Or pCommandCode = "CCB;" And vRCCode2 <> "13" Then
						vErrTextPos = Find(vReply, ";ET");
						If vErrTextPos > 0 Then
							rErrorDescription = Mid(vReply, vErrTextPos + 3);
							vEndOfErrorTextPos = Find(rErrorDescription, ";");
							If vEndOfErrorTextPos > 0 Then
								rErrorDescription = Left(rErrorDescription, vEndOfErrorTextPos - 1);
							EndIf;
						EndIf;
						Return vRCCode2;
					EndIf;
				Else
					Return RC_WRONG_REPLY;
				EndIf;
			ElsIf vReply <> NAK Then
				Return RC_WRONG_REPLY;
			EndIf;
		Else
			Return RC_NO_CONNECTION;
		EndIf;
	Else
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Clear returned data from
	rReply = Mid(vReply, vRCCodePos + 4);
	
	Return RC_OK;
EndFunction // CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pDevice, pEncoderNumber, pCommandCode, pDta, rReply, rErrorDescription = "")
	If ValueIsFilled(pDevice.ConnectionType) And
	   pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, pDevice, 3000, pEncoderNumber, pCommandCode, pDta, rReply, rErrorDescription);
	ElsIf ValueIsFilled(pDevice.ConnectionType) And
	      pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		// Using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, pDevice, 30, pEncoderNumber, pCommandCode, pDta, rReply, rErrorDescription);
	EndIf;
	Return vErrorCode;
EndFunction // MakeNewKey

// -----------------------------------------------------------------------------
Function pmNewKey(pDevice, pParameters, rErrorMessage = "", pAdditional = False) Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Command code
	vCommandCode = "";
	If pAdditional Then
		vCommandCode = "CCA;JR1;";
	Else
		vCommandCode = "CCA;";
	EndIf;
	
	// Build command data string starting from room
	vRoomCode = TrimR(pParameters.Room);
	If ValueIsFilled(pParameters.Room) Then
		If pDevice.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(pParameters.Room, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(pDevice.DefaultRoom) Then
		vRoom = pDevice.DefaultRoom;
		vRoomCode = TrimR(tcOnServer.cmGetAttributeByRef(vRoom, "Description"));
		If pDevice.UseRoomLockCodes Then
			vLockCode = tcOnServer.cmGetAttributeByRef(vRoom, "LockCode");
			If Not IsBlankString(vLockCode) Then
				vRoomCode = TrimR(vLockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		Return RC_ROOM_WITHOUT_DOOR_LOCK;
	EndIf;
	vDta = "GR" + vRoomCode + ";";
	// Check in date
	If ValueIsFilled(pParameters.ParentDoc) And TypeOf(pParameters.ParentDoc) = Type("DocumentRef.Reservation") Then
		vCheckInDate = pParameters.CheckInDate;
		If pDevice.SubtractMinutes <> 0 Then
			vCheckInDate = vCheckInDate - pDevice.SubtractMinutes*60;
		EndIf;
		vDta = vDta + "CI" + Format(vCheckInDate, "DF=yyyyMMddHHmm") + ";";
	EndIf;
	// Check out date
	vCheckOutDate = pParameters.CheckOutDate;
	If pDevice.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + pDevice.AddMinutes*60;
	EndIf;
	vDta = vDta + "CO" + Format(vCheckOutDate, "DF=yyyyMMddHHmm") + ";";
	// Number of keys
	vDta = vDta + "NC" + Format(pParameters.NumberOfKeys, "ND=2; NFD=0; NZ=; NLZ=; NG=") + ";";
	// Authorizations
	vDoorLockSystemAuthorization = Undefined;
	If pParameters.Property("DoorLockSystemAuthorization") Then
		vDoorLockSystemAuthorization = pParameters.DoorLockSystemAuthorization;
	EndIf;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(pParameters.Room) Then
		vDoorLockSystemAuthorization = tcOnServer.cmGetAttributeByRef(pParameters.Room, "DoorLockSystemAuthorization");
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		// Common rooms
		vAssignedAuthorizations = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "AssignedAuthorizations");
		If Not IsBlankString(vAssignedAuthorizations) Then
			vDta = vDta + "CR" + TrimAll(vAssignedAuthorizations) + ";";
		EndIf;
		// User group
		vUserGroup = TrimAll(pDevice.UserGroup);
		vDoorLockSystemAuthorizationUserGroup = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "UserGroup");
		If Not IsBlankString(vDoorLockSystemAuthorizationUserGroup) Then
			vUserGroup = TrimAll(vDoorLockSystemAuthorizationUserGroup);
		EndIf;
		If Not IsBlankString(vUserGroup) Then
			vDta = vDta + "UG" + vUserGroup + ";";
		EndIf;
	Else
		// Common rooms
		vAssignedAuthorizations = TrimAll(pDevice.AssignedAuthorizations);
		If Not IsBlankString(vAssignedAuthorizations) Then
			vDta = vDta + "CR" + TrimAll(vAssignedAuthorizations) + ";";
		EndIf;
		// User group
		vUserGroup = TrimAll(pDevice.UserGroup);
		If Not IsBlankString(vUserGroup) Then
			vDta = vDta + "UG" + vUserGroup + ";";
		EndIf;
	EndIf;
	// Issued by
	vCurrentUser = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurrentUser) Then
		vEmployeePreferences = tcOnServer.cmGetAttributeByRef(vCurrentUser, "EmployeePreferences");
		If ValueIsFilled(vEmployeePreferences) Then
			vEmployeePreferencesDoorLockSystemLogin = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemLogin");
			If Not IsBlankString(vEmployeePreferencesDoorLockSystemLogin) Then
				vDta = vDta + "IO" + TrimAll(vEmployeePreferencesDoorLockSystemLogin) + ";";
			EndIf;
			vEmployeePreferencesDoorLockSystemPassword = tcOnServer.cmGetAttributeByRef(vEmployeePreferences, "DoorLockSystemPassword");
			If Not IsBlankString(vEmployeePreferencesDoorLockSystemPassword) Then
				vDta = vDta + "OP" + TrimAll(vEmployeePreferencesDoorLockSystemPassword) + ";";
			EndIf;
		Else
			vCurrentUserCode = tcOnServer.cmGetAttributeByRef(vCurrentUser, "Code");
			vDta = vDta + "IO" + TrimAll(vCurrentUserCode) + ";";
		EndIf;
		vCurrentUserFirstName = tcOnServer.cmGetAttributeByRef(vCurrentUser, "FirstName");
		If Not IsBlankString(vCurrentUserFirstName) Then
			vDta = vDta + "OF" + TrimAll(vCurrentUserFirstName) + ";";
		EndIf;
		vCurrentUserLastName = tcOnServer.cmGetAttributeByRef(vCurrentUser, "LastName");
		If Not IsBlankString(vCurrentUserLastName) Then
			vDta = vDta + "OS" + TrimAll(vCurrentUserLastName) + ";";
		EndIf;
	EndIf;
	// Issued to
	If ValueIsFilled(pParameters.Guest) Then
		vGuestCode = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "Code");
		vDta = vDta + "UI" + Transliterate(TrimAll(vGuestCode)) + ";";
		vGuestFirstName = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "FirstName");
		If Not IsBlankString(vGuestFirstName) Then
			vDta = vDta + "UF" + Transliterate(TrimAll(vGuestFirstName)) + ";";
		EndIf;
		vGuestLastName = tcOnServer.cmGetAttributeByRef(pParameters.Guest, "LastName");
		If Not IsBlankString(vGuestLastName) Then
			vDta = vDta + "US" + Transliterate(TrimAll(vGuestLastName)) + ";";
		EndIf;
	EndIf;
	// Key card type
	vKeyCardType = TrimAll(pDevice.KeyCardType);
	vDoorLockSystemAuthorizationKeyCardType = tcOnServer.cmGetAttributeByRef(vDoorLockSystemAuthorization, "KeyCardType");
	If Not IsBlankString(vDoorLockSystemAuthorizationKeyCardType) And tcOnServer.IsNumber(TrimAll(vDoorLockSystemAuthorizationKeyCardType)) Then
		vKeyCardType = TrimAll(vDoorLockSystemAuthorizationKeyCardType);
	EndIf;
	If Not IsBlankString(vKeyCardType) Then
		vDta = vDta + "CT" + vKeyCardType + ";";
	EndIf;
	
	// Query card id if neccessary
	If pDevice.ReturnCardUID Then
		vDta = vDta + "SR" + "?" + ";";
	EndIf;
	
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, pDevice, pParameters, vDta, False);
	If vErrorCode = RC_OK Then
		vEncoderNumber = TrimAll(pDevice.EncoderNumber);
		If IsBlankString(vEncoderNumber) Then
			vEncoderNumber = "0";
		EndIf;
		
		// Call API
		vReply = "";
		vErrorDescription = "";
		vErrorCode = MakeNewKey(vDLSys, pDevice, vEncoderNumber, vCommandCode, vDta, vReply, vErrorDescription);
		If vErrorCode <> RC_OK Then
			If Not IsBlankString(vErrorDescription) Then
				rErrorMessage = vErrorDescription;
			EndIf;
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode + " - " + ?(IsBlankString(vErrorDescription), pmGetErrorDescription(vErrorCode, pDevice.SystemName), vErrorDescription));
		Else
			vIdentificationCard = Undefined;
			If pParameters.Property("IdentificationCard") Then
				vIdentificationCard = pParameters.IdentificationCard;
				If pDevice.ReturnCardUID Then
					vCardIdentifier = TrimAll(GetCardUID(vReply));
					If Not IsBlankString(vCardIdentifier) Then
						vIdentificationCard = tcOnServer.GetClientIdentificationCard(vCardIdentifier, tcOnServer.GetClientIdentificationCardById(vCardIdentifier), pParameters.ParentDoc, pParameters.Folio, pParameters.Guest, pParameters.Room, CurrentDate(), pParameters.CheckOutDate, True, vCardIdentifier);
						If ValueIsFilled(vIdentificationCard) Then
							pParameters.IdentificationCard = vIdentificationCard;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Not pAdditional Then
				tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt: '") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
				tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", CurrentDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
			Else
				tcOnServer.cmWriteLogEventAtServer(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), "Information", , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(pParameters.Room) + ", " + Format(pParameters.CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(pParameters.CheckOutDate, "DF='dd.MM.yyyy HH:mm'"));
				tcDoorLocksAtServer.WriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(vIdentificationCard), TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "CardUID")), ""), pParameters.Room, "", CurrentDate(), vCheckOutDate, pParameters.ParentDoc, pParameters.Guest, pParameters.NumberOfKeys);
			EndIf;
		EndIf;
		
		pmDisconnect(vDLSys, pDevice);
	EndIf;
	
	Return vErrorCode;
EndFunction // pmNewKey

// -----------------------------------------------------------------------------
Function pmAddKey(pDevice, pParameters, rErrorMessage = "") Export
	Return pmNewKey(pDevice, pParameters, rErrorMessage, True);
EndFunction // pmAddKey 

// -----------------------------------------------------------------------------
Function GetNextWord(pStr, pDelimeter="")
	If pDelimeter = "" Then
		pDelimeter = ";";
	EndIf;
	vWord = "";
	vPos = Find(pStr, pDelimeter);
	If vPos > 0 Then
		vWord = Left(pStr, vPos-1);
		pStr = TrimAll(Right(pStr, StrLen(pStr) - vPos));
	Else
		vWord = TrimAll(pStr);
		pStr = "";
	EndIf;
	Return vWord;
EndFunction // GetNextWord

// -----------------------------------------------------------------------------
Function GetDate(pDate)
	Try
		If Not IsBlankString(pDate) And StrLen(pDate) = 12 Then
			Return Date(pDate + "00");
		Else
			Return '00010101';
		EndIf;
	Except
		Return '00010101';
	EndTry;
EndFunction // GetDate

// -----------------------------------------------------------------------------
Procedure FillParameter(pCardData, pWord)
	If StrLen(pWord) <=1 Then
		Return;
	EndIf;
	vCommand = Left(pWord, 2);
	If vCommand = "GR" Then
		pCardData.CardRoom = Right(pWord,StrLen(pWord)-2);
	ElsIf vCommand = "UF" Then
	   pCardData.CardFirstName = Right(pWord,StrLen(pWord)-2);	
	ElsIf vCommand = "US" Then
		pCardData.CardLastName = Right(pWord,StrLen(pWord)-2);
	ElsIf vCommand = "CI" Then
		pCardData.CardCheckInDate = GetDate(Right(pWord,StrLen(pWord)-2));
	ElsIf vCommand = "CO" Then
		pCardData.CardCheckOutDate = GetDate(Right(pWord,StrLen(pWord)-2));
	ElsIf vCommand = "CR" Then
		pCardData.CardAuthorizations = Right(pWord,StrLen(pWord)-2);
	ElsIf vCommand = "SR" Then
		pCardData.CardID = tcOnServer.GetCardIdentifier(ParceCardUIDCode(Right(pWord,StrLen(pWord)-2)));
		vIDCardRef = tcOnServer.GetClientIdentificationCardById(pCardData.CardID);
		If ValueIsFilled(vIDCardRef) Then
			vClient = tcOnServer.cmGetAttributeByRef(vIDCardRef, "Client");
			If ValueIsFilled(vClient) Then
				pCardData.CardFullName = TrimAll(tcOnServer.cmGetAttributeByRef(vClient, "FullName"));
				pCardData.CardAuthorizations = pCardData.CardFullName + ?(IsBlankString(pCardData.CardAuthorizations), "", "; " + pCardData.CardAuthorizations);
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // FillParameter

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("ReplyType", "");
	vCardData.Insert("ReplyDescription", "");
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
	vCardData.Insert("IsCardValidCode", "");
	vCardData.Insert("IsCardValidDescription", "");
	vCardData.Insert("CardCopyNumber", "");
	vCardData.Insert("CardTrack1", "");
	vCardData.Insert("CardTrack2", "");
	vCardData.Insert("CardAuthorizations", "");
	vCardData.Insert("CardID", "");
	vCardData.Insert("CardFullName", "");
	
	// Parse all fields
	vDataLen = StrLen(pCardDesc);
	While vDataLen > 0 Do
		vWord = GetNextWord(pCardDesc);
		vDataLen = StrLen(pCardDesc);
		FillParameter(vCardData,vWord);
	EndDo;
		
	// Return card data
	Return vCardData;
EndFunction // pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pDevice, pEncoderNumber, pCommandCode, pData, rReply)
	RC_OK = 0;
	RC_UNKNOWN = -49;
	
	vErrorCode = RC_OK;
	rReply = "";
	If pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.RS232") Then
		// Send command and process reply
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pCommandCode, pData, rReply);
	ElsIf pDevice.ConnectionType = PredefinedValue("Enum.ConnectionTypes.TCPIP") Then
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, pDevice, 30, pEncoderNumber, pCommandCode, pData, rReply);
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_UNKNOWN Then
		// Card was not recognized
		vErrorCode = RC_OK;
	EndIf;
	Return vErrorCode;
EndFunction // Verify

// -----------------------------------------------------------------------------
Function pmVerify(rCardData, pDevice, pParameters) Export
	RC_OK = 0;
	RC_NO_CONNECTION = -1;
	
	If pParameters.Property("IdentificationCard") Then
		pParameters.IdentificationCard = PredefinedValue("Catalog.IdentificationCards.EmptyRef");
	EndIf;
	
	// Connect
	vDLSys = pmConnect(pDevice);
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Command code
	vCommandCode = "CCB;";
	
	// Build parameters
	vEncoderNumber = TrimAll(pDevice.EncoderNumber);
	If IsBlankString(vEncoderNumber) Then
		vEncoderNumber = "0";
	EndIf;
	
	// Build command data
	vDta = "";
	// Card id 
	vDta = vDta + "SR?;";
	
	// Call API
	vReply = "";
	vErrorCode = Verify(vDLSys, pDevice, vEncoderNumber, vCommandCode, vDta, vReply);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode + " - " + pmGetErrorDescription(vErrorCode, pDevice.SystemName));
	Else
		// Parse returned data
		rCardData = pmParseCardDescription(vReply);
	EndIf;
	
	// Disconnect
	pmDisconnect(vDLSys, pDevice);
	
	Return vErrorCode;
EndFunction // pmVerify

// -----------------------------------------------------------------------------
Function pmRegisterNewCard(pCardData, pIsMaster = False, pParameters) Export
	RC_OK = 0;
	RC_NO_FOLIO = -101;
	RC_NO_ID_CARD = -102;
	RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = -3;
	
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
			Return RC_NO_ID_CARD;
		ElsIf TrimAll(tcOnServer.cmGetAttributeByRef(vIdentificationCard, "Identifier")) <> vCardID Then
			AddError(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
			Return RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
		Else
			If pParameters.Property("IdentificationCard") Then
				pParameters.IdentificationCard = vIdentificationCard;
			EndIf;
		EndIf;
		// Check should we update is master folio flag
		tcDoorLocksAtServer.UpdateMasterFolioFlag(pParameters.Folio, pIsMaster);
	Else
		AddError(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return RC_NO_FOLIO;
	EndIf;
	Return RC_OK;
EndFunction // pmRegisterNewCard

// -----------------------------------------------------------------------------
Function GetCardUID(pReply)
	vCardUID = "";
	vIdIsFound = Find(pReply, ";SR");
	If vIdIsFound > 0 Then
		vCardUID = Mid(pReply, vIdIsFound + 3);
		vSepIsFound = Find(vCardUID, ";");
		If vSepIsFound > 1 Then
			vCardUID = Left(vCardUID, vSepIsFound - 1);
		EndIf;
		// Remove FF from the end of ID
		i = StrLen(vCardUID);
		While i > 0 And Mid(vCardUID, i - 1, 2) = "FF" Do
			i = i - 2;
			vCardUID = Left(vCardUID, i);
		EndDo;
		// Move first 6 bytes to the end of ID if ID length is 14 bytes
		If StrLen(vCardUID) = 14 Then
			vCardUID = Mid(vCardUID, 7, 8) + Left(vCardUID, 6);
		EndIf;
	EndIf;
	Return vCardUID;
EndFunction // GetCardUID

// -----------------------------------------------------------------------------
Function ParceCardUIDCode(pCardUID)
	vCardUID = pCardUID;
	// Remove FF from the end of ID
	i = StrLen(vCardUID);
	While i > 0 And Mid(vCardUID, i - 1, 2) = "FF" Do
		i = i - 2;
		vCardUID = Left(vCardUID, i);
	EndDo;
	// Move first 6 bytes to the end of ID if ID length is 14 bytes
	If StrLen(vCardUID) = 14 Then
		vCardUID = Mid(vCardUID, 7, 8) + Left(vCardUID, 6);
	EndIf;
	Return vCardUID;
EndFunction //  ParceCardUIDCode()

// -----------------------------------------------------------------------------
Function pmGetErrorDescription(pRC, pSystemName) Export
	RC_NO_CONNECTION = -1;
	RC_OK = 0;
	RC_UNKNOWN = -49;
	RC_ROOM_WITHOUT_DOOR_LOCK = -2;
	RC_NO_FOLIO = -101;
	RC_NO_ID_CARD = -102;
	RC_NO_REPLY = -103;
	RC_WRONG_REPLY = -104;
	RC_DATA_ERROR = -209;
	RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = -3;
	
	If pRC = RC_NO_CONNECTION Then
		Return(NStr("ru = 'Не удалось установить соединение с системой " + pSystemName + "!'; 
		            |en = 'Failed to connect to the door locks system " + pSystemName + "!';
					|de = 'Failed to connect to the door locks system " + pSystemName + "!'"));
	ElsIf pRC = RC_UNKNOWN Then
		Return(NStr("en='Unknown error! It is possible that client name has forbidden characters.';ru='Неизвестная ошибка! Возможно в ФИО гостя встретились запрещенные символы.';de='Unbekannter Fehler! Möglicherweise kommen im Namen und Vornamen des Gastes nicht zulässige Symbole vor.'"));
	ElsIf pRC = RC_NO_REPLY Then
		Return(NStr("ru = 'Система " + pSystemName + " не отвечает!'; 
		            |en = '" + pSystemName + " system is not responding!';
					|de = '" + pSystemName + " system is not responding!'"));
	ElsIf pRC = RC_WRONG_REPLY Then
		Return(NStr("ru = 'От системы " + pSystemName + " получен ответ в неизвестном формате!'; 
		            |en = '" + pSystemName + " system replied with unknown format!';
					|de = '" + pSystemName + " system replied with unknown format!'"));
	ElsIf pRC = RC_ROOM_WITHOUT_DOOR_LOCK Then
		Return(NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'"));
	ElsIf pRC = RC_NO_FOLIO Then
		Return(NStr("en='Failed to register client identification card! Cause: Folio is not set.';ru='Ошибка регистрации карты идентификации клиента! Причина: не указано фолио.';de='Fehler bei der Erfassung der Kundenidentifikationskarte! Ursache: Folio nicht angegeben.'"));
	ElsIf pRC = RC_NO_ID_CARD Then
		Return(NStr("en='Failed to register client identification card!';ru='Ошибка регистрации карты идентификации клиента!';de='Fehler bei der Erfassung der Kundenidentifikationskarte!'"));
	ElsIf pRC = RC_DATA_ERROR Then
		Return(NStr("en='Data error!';ru='Ошибка в данных!';de='Datenfehler!'"));
	ElsIf pRC = RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	Else
		Return "";
	EndIf;		
EndFunction // pmGetErrorDescription
