
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
Var RC_ROOM_WITHOUT_DOOR_LOCK Export; // Room without door lock
Var RC_NO_FOLIO Export; // No folio
Var RC_NO_ID_CARD Export; // No id card
Var RC_NO_REPLY Export; // No reply
Var RC_WRONG_REPLY Export; // Wrong reply
Var RC_DATA_ERROR Export; // Data error
Var RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Export; // One card

Var ERROR_DESCRIPTION;

// -----------------------------------------------------------------------------
Var SystemName;

// -----------------------------------------------------------------------------
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY; 

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pAdditional	 - Boolean	 - Additional key
// 
// Returns:
//  String - Error code 
//
Function pmNewKey(pAdditional = False) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
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
	vDta = "GR" + vRoomCode + ";";
	// Check in date
	If ValueIsFilled(ParentDoc) And TypeOf(ParentDoc) = Type("DocumentRef.Reservation") Then
		vCheckInDate = CheckInDate;
		If DoorLockSystemParameters.SubtractMinutes <> 0 Then
			vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
		EndIf;
		vDta = vDta + "CI" + Format(vCheckInDate, "DF=yyyyMMddHHmm") + ";";
	EndIf;
	// Check out date
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vDta = vDta + "CO" + Format(vCheckOutDate, "DF=yyyyMMddHHmm") + ";";
	// Number of keys
	vDta = vDta + "NC" + Format(NumberOfKeys, "ND=2; NFD=0; NZ=; NLZ=; NG=") + ";";
	// Authorizations
	vDoorLockSystemAuthorization = DoorLockSystemAuthorization;
	If Not ValueIsFilled(vDoorLockSystemAuthorization) And ValueIsFilled(Room) Then
		vDoorLockSystemAuthorization = Room.DoorLockSystemAuthorization;
	EndIf;
	If ValueIsFilled(vDoorLockSystemAuthorization) Then
		// Common rooms
		If Not IsBlankString(vDoorLockSystemAuthorization.AssignedAuthorizations) Then
			vDta = vDta + "CR" + TrimAll(vDoorLockSystemAuthorization.AssignedAuthorizations) + ";";
		EndIf;
		// User group
		vUserGroup = TrimAll(DoorLockSystemParameters.UserGroup);
		If Not IsBlankString(vDoorLockSystemAuthorization.UserGroup) Then
			vUserGroup = TrimAll(vDoorLockSystemAuthorization.UserGroup);
		EndIf;
		If Not IsBlankString(vUserGroup) Then
			vDta = vDta + "UG" + vUserGroup + ";";
		EndIf;
	Else
		// Common rooms
		vAssignedAuthorizations = TrimAll(DoorLockSystemParameters.AssignedAuthorizations);
		If Not IsBlankString(vAssignedAuthorizations) Then
			vDta = vDta + "CR" + TrimAll(vAssignedAuthorizations) + ";";
		EndIf;
		// User group
		vUserGroup = TrimAll(DoorLockSystemParameters.UserGroup);
		If Not IsBlankString(vUserGroup) Then
			vDta = vDta + "UG" + vUserGroup + ";";
		EndIf;
	EndIf;
	// Issued by
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		vCurrentUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vCurrentUser.EmployeePreferences) Then
			vEmployeePreferences = vCurrentUser.EmployeePreferences;
			If Not IsBlankString(vEmployeePreferences.DoorLockSystemLogin) Then
				vDta = vDta + "IO" + TrimAll(vEmployeePreferences.DoorLockSystemLogin) + ";";
			EndIf;
			If Not IsBlankString(vEmployeePreferences.DoorLockSystemPassword) Then
				vDta = vDta + "OP" + TrimAll(vEmployeePreferences.DoorLockSystemPassword) + ";";
			EndIf;
		Else
			vDta = vDta + "IO" + TrimAll(vCurrentUser.Code) + ";";
		EndIf;
		If Not IsBlankString(vCurrentUser.FirstName) Then
			vDta = vDta + "OF" + TrimAll(vCurrentUser.FirstName) + ";";
		EndIf;
		If Not IsBlankString(vCurrentUser.LastName) Then
			vDta = vDta + "OS" + TrimAll(vCurrentUser.LastName) + ";";
		EndIf;
	EndIf;
	// Issued to
	If ValueIsFilled(Guest) Then
		vDta = vDta + "UI" + Transliterate(TrimAll(Guest.Code)) + ";";
		If Not IsBlankString(Guest.FirstName) Then
			vDta = vDta + "UF" + Transliterate(TrimAll(Guest.FirstName)) + ";";
		EndIf;
		If Not IsBlankString(Guest.LastName) Then
			vDta = vDta + "US" + Transliterate(TrimAll(Guest.LastName)) + ";";
		EndIf;
	EndIf;
	// Key card type
	vKeyCardType = TrimAll(DoorLockSystemParameters.KeyCardType);
	If Not IsBlankString(vDoorLockSystemAuthorization.KeyCardType) And cmIsNumber(TrimAll(vDoorLockSystemAuthorization.KeyCardType)) Then
		vKeyCardType = TrimAll(vDoorLockSystemAuthorization.KeyCardType);
	EndIf;
	If Not IsBlankString(vKeyCardType) Then
		vDta = vDta + "CT" + vKeyCardType + ";";
	EndIf;
	
	// Query card id if neccessary
	If DoorLockSystemParameters.ReturnCardUID Then
		vDta = vDta + "SR" + "?" + ";";
	EndIf;
	
	// Add track 2 data if necessary
	vErrorCode = AddTrack2(vDLSys, vDta, False);
	If vErrorCode <> RC_OK Then
		Return vErrorCode;
	Else
		vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
		If IsBlankString(vEncoderNumber) Then
			vEncoderNumber = "0";
		EndIf;
		
		// Call API
		vReply = "";
		vErrorCode = MakeNewKey(vDLSys, vEncoderNumber, vCommandCode, vDta, vReply);
		If vErrorCode <> RC_OK Then
			AddError(NStr("en='Error issuing key card: ';ru='Ошибка выдачи карты: ';de='Fehler bei der Kartenausstellung: '") + vErrorCode);
		Else
			If DoorLockSystemParameters.ReturnCardUID Then
				vCardIdentifier = TrimAll(GetCardUID(vReply));
				If Not IsBlankString(vCardIdentifier) Then
					IdentificationCard = cmGetClientIdentificationCard(vCardIdentifier, cmGetClientIdentificationCardById(vCardIdentifier), ParentDoc, Folio, Guest, Room, CurrentSessionDate(), CheckOutDate, True, vCardIdentifier);
				EndIf;
			EndIf;
			If Not pAdditional Then
				WriteLogEvent(NStr("en='DoorLockSystem.KeyIssued';ru='СистемаЭлектронныхЗамков.ВыданКлюч';de='DoorLockSystem.KeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				cmWriteKeyCardSecuritySystemEvent("NEW", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
			Else
				WriteLogEvent(NStr("en='DoorLockSystem.AdditionalKeyIssued';ru='СистемаЭлектронныхЗамков.ВыданДополнительныйКлюч';de='DoorLockSystem.AdditionalKeyIssued'"), EventLogLevel.Information, , , NStr("en='Key card issued: ';ru='Выдан ключ-карта: ';de='Kartenschlüssel wurde ausgehändigt:'") + TrimAll(Room) + ", " + Format(CheckInDate, "DF='dd.MM.yyyy HH:mm'") + " - " + Format(CheckOutDate, "DF='dd.MM.yyyy HH:mm'") + ", " + vDta);
				cmWriteKeyCardSecuritySystemEvent("ADD", ?(ValueIsFilled(IdentificationCard), TrimAll(IdentificationCard.CardUID), ""), Room, vDta, CurrentSessionDate(), vCheckOutDate, ParentDoc, Guest, NumberOfKeys);
			EndIf;
		EndIf;
		
		pmDisconnect(vDLSys);
		Return vErrorCode;
	EndIf;
EndFunction //  pmNewKey

// -----------------------------------------------------------------------------
// 
// Returns:
//  String - Error code 
//
Function pmAddKey() Export
	Return pmNewKey(True);
EndFunction //  pmAddKey 

// -----------------------------------------------------------------------------
//
// Parameters:
//  pCardData	 - Structure - Card data 
//  pIsMaster	 - Boolean	 - Is master
// 
// Returns:
//  String - Error code 
//
Function pmRegisterNewCard(pCardData, pIsMaster = False) Export
	// Add/get client identification card
	If ValueIsFilled(Folio) Then
		// Get card identifier
		vCardID = cmGetCardIdentifier(pCardData);
		// Register card
		IdentificationCard = cmGetClientIdentificationCard(vCardID, cmGetClientIdentificationCardById(vCardID), ParentDoc, Folio, Guest, Room, CurrentSessionDate(), CheckOutDate, True);
		If Not ValueIsFilled(IdentificationCard) Then
			AddError(NStr("en='Failed to register client identification card!';ru='Не удалось зарегистрировать карту идентификации клиента!';de='Die Kundenidentifikationskarte konnte nicht registriert werden!'"));
			Return RC_NO_ID_CARD;
		ElsIf TrimAll(IdentificationCard.Identifier) <> vCardID Then
			AddError(NStr("en='Folio may have only one active identification card!';ru='По лицевому счету может быть только одна действующая карта!';de='Zu dem Personenkonto kann es nur eine gültige Karte geben!'"));
			Return RC_ONLY_ONE_ACTIVE_CARD_ALLOWED;
		EndIf;
		// Check should we update is master folio flag
		If ValueIsFilled(Folio) Then
			If Folio.IsMaster <> pIsMaster Then
				vFolioObj = Folio.GetObject();
				vFolioObj.IsMaster = pIsMaster;
				vFolioObj.Write(DocumentWriteMode.Write);
				// Try to set folio client default charging rules
				If ValueIsFilled(Folio.Client) And Not ValueIsFilled(Folio.Room) And Not ValueIsFilled(Folio.GuestGroup) Then
					vClientObj = Folio.Client.GetObject();
					If ValueIsFilled(Folio.Hotel) Then
						vClientObj.ChargingRules.Clear();
						vClientObj.pmCreateFolios(Folio.Hotel, CurrentSessionDate());
						If vClientObj.ChargingRules.Count() > 0 Then
							vCRRow = vClientObj.ChargingRules.Get(0);
							vOldFolio = vCRRow.ChargingFolio;
							vCRRow.ChargingFolio = Folio;
							vClientObj.Write();
							// Try to mark old folio as deleted
							If ValueIsFilled(vOldFolio) Then
								vOldFolioObj = vOldFolio.GetObject();
								vOldFolioObj.SetDeletionMark(True);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	Else
		AddError(NStr("en='Folio is not specified!';ru='Не указан лицевой счет, на который регистрировать карту идентификации клиента!';de='Das Personenkonto ist nicht angegeben, auf das die Kundenidentifikationskarte registriert werden soll!'"));
		Return RC_NO_FOLIO;
	EndIf;
	Return RC_OK;
EndFunction //  pmRegisterNewCard

// -----------------------------------------------------------------------------
//
// Parameters:
//  rCardData	 - Structure - Card data
// 
// Returns:
//  String - Error code 
//
Function pmVerify(rCardData) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	// Connect
	vDLSys = pmConnect();
	If vDLSys = Undefined Then
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Command code
	vCommandCode = "CCB;";
	
	// Build parameters
	vEncoderNumber = TrimAll(DoorLockSystemParameters.EncoderNumber);
	If IsBlankString(vEncoderNumber) Then
		vEncoderNumber = "0";
	EndIf;
	
	// Build command data
	vDta = "";
	// Card id 
	vDta = vDta + "SR?;";
	
	// Call API
	vReply = "";
	vErrorCode = Verify(vDLSys, vEncoderNumber, vCommandCode, vDta, vReply);
	If vErrorCode <> RC_OK Then
		AddError(NStr("en='Error reading key card: ';ru='Ошибка чтения карты: ';de='Fehler beim Lesen der Karte: '") + vErrorCode);
	Else
		// Parse returned data
		rCardData = pmParseCardDescription(vReply);
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
	ElsIf pRC = RC_DATA_ERROR Then
		Return(NStr("en='Data error!';ru='Ошибка в данных!';de='Datenfehler!'"));
	ElsIf pRC = RC_ONLY_ONE_ACTIVE_CARD_ALLOWED Then
		Return(NStr("en='Only one active card is allowed!';ru='Может быть только одна действующая карта!';de='Es kann nur eine gültige Karte geben!'"));
	Else
		Return ERROR_DESCRIPTION;
	EndIf;		
EndFunction //  pmGetErrorDescription

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
EndFunction //  Transliterate

// -----------------------------------------------------------------------------
Procedure AddError(pErrorText)
	WriteLogEvent(NStr("en='DoorLockSystem.Error';ru='СистемаЭлектронныхЗамков.Ошибка';de='СистемаЭлектронныхЗамков.Ошибка'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "9600,E,8,1" by default
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
	Return vStr;		
EndFunction //  GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function pmConnect()
	// Fill system name
	SystemName = "AssaAbloy";
	
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
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			Try
			    vDLSys = New COMObject("SocketTools.SocketWrench.10");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK10_LICENSE_KEY);
			Except
				vDLSys = New COMObject("SocketTools.SocketWrench.6");
				// Load license
				vErrorCode = vDLSys.Initialize(CSWSOCK6_LICENSE_KEY);
			EndTry;
			If vErrorCode <> 0 Then
				AddError(NStr("en='SocketTools.SocketWrench component initialization error: ';ru='Ошибка инициализации компоненты SocketTools.SocketWrench! Код ошибки: ';de='Fehler bei der Initialisierung der Komponente SocketTools.SocketWrench! Fehlercode: '") + vErrorCode);
				Return Undefined;
			EndIf;     
			vDLSys.Blocking = True;
			vDLSys.Timeout = 30; // 30 seconds blocking read timeout by default
			vErrorCode = vDLSys.Connect(TrimAll(DoorLockSystemParameters.ServerName), ?(IsBlankString(DoorLockSystemParameters.Port), 4000, Number(TrimAll(DoorLockSystemParameters.Port))));
			If vErrorCode <> 0 Then
				AddError(NStr("ru = 'Не найден сервер системы электронных замков " + SystemName + ": '; en = '" + SystemName + " system server was not found: '; de = '" + SystemName + " system server was not found: '") + vErrorCode);
				Return Undefined;
			EndIf;
		Else
			AddError(NStr("ru = 'Подключение по протоколам отличным от TCP и RS232 не поддерживается системами электронных замков " + SystemName + "!'; 
						  |en = '" + SystemName + " door lock system do support TCP or RS232 connection only!';
						  |de = '" + SystemName + " door lock system do support TCP or RS232 connection only!'"));
			Return Undefined;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы электронных замков " + SystemName + ": '; 
					  |en = '" + SystemName + " door lock system connection error: ';
					  |de = '" + SystemName + " door lock system connection error: '") + ErrorDescription());
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
		ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
		      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
			If pDLSys <> Undefined Then
				// Close TCP/IP socket
				vErrorCode = pDLSys.Disconnect();
				If vErrorCode <> 0 Then
					AddError(NStr("ru = 'Ошибка отключения от сервера эл. замков " + SystemName + ": '; en = '" + SystemName + " server disconnect error: '; de = '" + SystemName + " server disconnect error: '") + vErrorCode);
					Return;
				EndIf;
			EndIf;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы эл. замков " + SystemName + ": '; en = '" + SystemName + " system disconnect error: '; de = '" + SystemName + " system disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
Function AddTrack2(pDLSys, pDta, pAdd = False)
	If DoorLockSystemParameters.WriteTrack2 Then
		// Add/get client identification card
		If ValueIsFilled(Folio) Then
			vIDCardRef = cmGetClientIdentificationCard("", Undefined, ParentDoc, Folio, Guest, Room, CurrentSessionDate(), CheckOutDate, pAdd);
			If ValueIsFilled(vIDCardRef) Then
				// Track 2 data: CardIdentifier
				vTrack2 = Format(vIDCardRef.Identifier, "ND=12; NFD=0; NZ=; NLZ=; NG=");
				pDta = pDta + "T2" + vTrack2 + ";";
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
EndFunction //  AddTrack2

// -----------------------------------------------------------------------------
Function CallRS232Command(pDLSys, pReadTimeout = 3000, pEncoderNumber, pCommandCode, pDta, rReply = "")
	ERROR_DESCRIPTION = "";
	
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
	vCmd = STX + vCmd + cmHexLRC(STX + vCmd) + ETX;
	
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
						ERROR_DESCRIPTION = Mid(vReply, vErrTextPos + 3);
						vEndOfErrorTextPos = Find(ERROR_DESCRIPTION, ";");
						If vEndOfErrorTextPos > 0 Then
							ERROR_DESCRIPTION = Left(ERROR_DESCRIPTION, vEndOfErrorTextPos - 1);
						EndIf;
					EndIf;
					AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
					Return vRCCode2;
				EndIf;
			Else
				AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
				pDLSys.PurgeQueue();
				Return RC_WRONG_REPLY;
			EndIf;
		ElsIf vReply <> NAK Then
			AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
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
EndFunction //  CallRS232Command

// -----------------------------------------------------------------------------
Function CallTCPCommand(pDLSys, pReadTimeout = 60, pEncoderNumber, pCommandCode, pDta, rReply = "")
	ERROR_DESCRIPTION = "";
	
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
	vSourceAddress = TrimAll(DoorLockSystemParameters.PCId);
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
							ERROR_DESCRIPTION = Mid(vReply, vErrTextPos + 3);
							vEndOfErrorTextPos = Find(ERROR_DESCRIPTION, ";");
							If vEndOfErrorTextPos > 0 Then
								ERROR_DESCRIPTION = Left(ERROR_DESCRIPTION, vEndOfErrorTextPos - 1);
							EndIf;
						EndIf;
						AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
						Return vRCCode2;
					EndIf;
				Else
					AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
					Return RC_WRONG_REPLY;
				EndIf;
			ElsIf vReply <> NAK Then
				AddError(NStr("en='Reply is: ';ru='Ответ: ';de='Antwort: '") + vReply);
				Return RC_WRONG_REPLY;
			EndIf;
		Else
			AddError(NStr("en='Read command result error: ';ru='Ошибка получения результата команды: ';de='Fehlgeschlagen Befehl Ergebnis erhalten: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
			Return RC_NO_CONNECTION;
		EndIf;
	Else
		AddError(NStr("en='Write command error: ';ru='Ошибка отправки команды: ';de='Fehler beim Versenden des Befehls: '") + pDLSys.LastError + " - " + pDLSys.LastErrorString);
		Return RC_NO_CONNECTION;
	EndIf;
	
	// Clear returned data from
	rReply = Mid(vReply, vRCCodePos + 4);
	
	Return RC_OK;
EndFunction //  CallTCPCommand

// -----------------------------------------------------------------------------
Function MakeNewKey(pDLSys, pEncoderNumber, pCommandCode, pDta, rReply)
	If ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	   DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Using RS232 interface
		vErrorCode = CallRS232Command(pDLSys, 3000, pEncoderNumber, pCommandCode, pDta, rReply);
	ElsIf ValueIsFilled(DoorLockSystemParameters.ConnectionType) And
	      DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		// Using TCP interface
		vErrorCode = CallTCPCommand(pDLSys, 30, pEncoderNumber, pCommandCode, pDta, rReply);
	EndIf;
	Return vErrorCode;
EndFunction //  MakeNewKey

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
EndFunction //  GetNextWord

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
EndFunction //  GetDate

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
		pCardData.CardID = cmGetCardIdentifier(ParceCardUIDCode(Right(pWord,StrLen(pWord)-2)));
		vIDCardRef = cmGetClientIdentificationCardById(pCardData.CardID);
		If ValueIsFilled(vIDCardRef) And ValueIsFilled(vIDCardRef.Client) Then
			pCardData.CardFullName = TrimAll(vIDCardRef.Client.FullName);
			pCardData.CardAuthorizations = pCardData.CardFullName + ?(IsBlankString(pCardData.CardAuthorizations), "", "; " + pCardData.CardAuthorizations);
		EndIf;
	EndIf;	
EndProcedure //  FillParameter

// -----------------------------------------------------------------------------
Function pmParseCardDescription(Val pCardDesc)
	vCardData = New Structure();
	vCardData.Insert("CardRoom", "");
	vCardData.Insert("CardCheckInDate", '00010101');
	vCardData.Insert("CardCheckOutDate", '00010101');
	vCardData.Insert("CardLastName", "");
	vCardData.Insert("CardFirstName", "");
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
EndFunction //  pmParseCardDescription

// -----------------------------------------------------------------------------
Function Verify(pDLSys, pEncoderNumber, pCommandCode, pData, rReply)
	vErrorCode = RC_OK;
	rReply = "";
	If DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.RS232 Then
		// Send command and process reply
		vErrorCode = CallRS232Command(pDLSys, 60000, pEncoderNumber, pCommandCode, pData, rReply);
	ElsIf DoorLockSystemParameters.ConnectionType = Enums.ConnectionTypes.TCPIP Then
		// Using TCP/IP interface
		vErrorCode = CallTCPCommand(pDLSys, 30, pEncoderNumber, pCommandCode, pData, rReply);
	EndIf;
	// Retrieve card data
	If vErrorCode = RC_UNKNOWN Then
		// Card was not recognized
		vErrorCode = RC_OK;
	EndIf;
	Return vErrorCode;
EndFunction //  Verify

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
EndFunction //  GetCardUID

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
RC_UNKNOWN = -49;
RC_ROOM_WITHOUT_DOOR_LOCK = -2;
RC_NO_FOLIO = -101;
RC_NO_ID_CARD = -102;
RC_NO_REPLY = -103;
RC_WRONG_REPLY = -104;
RC_DATA_ERROR = -209;
RC_ONLY_ONE_ACTIVE_CARD_ALLOWED = -3;

ERROR_DESCRIPTION = "";

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

#EndRegion


