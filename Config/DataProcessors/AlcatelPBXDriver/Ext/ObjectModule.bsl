
#Region Variables

Var SerialConnector;

// -----------------------------------------------------------------------------
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;
Var XON;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If PBXSerialPort = 0 Then
		PBXSerialPort = 1;
	EndIf;
	If BaudRate = 0 Then
		BaudRate = 9600;
	EndIf;
	If Not ValueIsFilled(Parity) Then
		Parity = Enums.ParityTypes.Even;
	EndIf;
	If Not ValueIsFilled(DataBits) Then
		DataBits = Enums.DataBits.Bits8;
	EndIf;
	If Not ValueIsFilled(StopBits) Then
		StopBits = Enums.StopBits.Bits1;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF NOT MobileClient THEN
		If PBXSerialPort <> 0 Then
			If IsRunning And (tcOnServer.cmGetServerCurrentSessionDate() - Timestamp) < 120 Then
				Return;
			EndIf;
			IsRunning = True;
			StopInterface = False;
			Timestamp = tcOnServer.cmGetServerCurrentSessionDate();
			pmSaveDataProcessorAttributes();
			// Build connector object
			SerialConnector = New COMObject("SPort.SPortAx.1");
			// Set connection parameters
			SerialConnector.InitString(GetCOMPortConnectionString());
			// Open COM port
			vIsOpen = SerialConnector.Open("COM" + Format(PBXSerialPort, "NFD=0; NG="));
			If Not vIsOpen Then
				vError = NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + Format(PBXSerialPort, "NFD=0; NG=");
				DoMessage(vError, MessageStatus.Attention);
				SerialConnector = Undefined;
				IsRunning = False;
				StopInterface = False;
				Timestamp = Undefined;
				pmSaveDataProcessorAttributes();
				Return;
			EndIf;
			// Set block mode
			SerialConnector.BlockMode = true;
			// Setup timeouts
			SerialConnector.TimeoutReadInterval = 100;
			SerialConnector.TimeoutReadTotalConstant = 100;
			SerialConnector.TimeoutReadTotalMultiplier = 100;
			SerialConnector.TimeoutWriteTotalConstant = 100;
			SerialConnector.TimeoutWriteTotalMultiplier = 100;
			// Send/receive acknowledgement
			If Not Acknowledgement() Then
				vError = NStr("ru='Не удалось получить подтверждение установки связи с АТС!'; 
				              |en='Handshake with PBX system has failed!';
				              |de='Handshake mit PBX-system ist fehlgeschlagen!'");
				DoMessage(vError, MessageStatus.Attention);
				SerialConnector = Undefined;
				IsRunning = False;
				StopInterface = False;
				Timestamp = Undefined;
				pmSaveDataProcessorAttributes();
				Return;
			EndIf;
			If DebugMode Then
				DoMessage("PMS -> PBX. Connection successfull");
			EndIf;
			// Go to main processing cycle
			While DoMainProcessingCycle() Do
				cmWait(3);
				pmLoadDataProcessorAttributes();
				If StopInterface Then
					Break;
				EndIf;
				If pIsInteractive Then
					IsRunning = False;
					pmSaveDataProcessorAttributes();
				EndIf;
			EndDo;
			SerialConnector.Close();
			DoMessage("PMS -> PBX. Disconnected");
			IsRunning = False;
			StopInterface = False;
			Timestamp = Undefined;
			pmSaveDataProcessorAttributes();
		Else
			DoMessage(NStr("en='PBX system connection port is missing...'; ru='Не указан порт подключения к PBX...'; de='PBX System Anschluss port fehlt...'"), MessageStatus.Attention);
		EndIf;
	#ENDIF
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined)
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage(TrimAll(CurrentSessionDate()) + " " + pMsg, vMsgStatus);
	WriteLogEvent("Ericsson.CIL4", ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Function GetCOMPortConnectionString()
	vStr = ""; // "9600,E,8,1,X" by default
	// Baudrate
	If BaudRate > 0 Then
		vStr = vStr + Format(BaudRate, "ND=6; NFD=0; NZ=; NG=");
	Else
		vStr = vStr + "9600";
	EndIf;
	// Parity
	If ValueIsFilled(Parity) Then
		If Parity = Enums.ParityTypes.Even Then
			vStr = vStr + ",E";
		ElsIf Parity = Enums.ParityTypes.Odd Then
			vStr = vStr + ",O";
		ElsIf Parity = Enums.ParityTypes.None Then
			vStr = vStr + ",N";
		ElsIf Parity = Enums.ParityTypes.Mark Then
			vStr = vStr + ",M";
		ElsIf Parity = Enums.ParityTypes.Space Then
			vStr = vStr + ",S";
		EndIf;
	Else
		vStr = vStr + ",E";
	EndIf;
	// Data length
	If ValueIsFilled(DataBits) Then
		If DataBits = Enums.DataBits.Bits8 Then
			vStr = vStr + ",8";
		ElsIf DataBits = Enums.DataBits.Bits7 Then
			vStr = vStr + ",7";
		EndIf;
	Else
		vStr = vStr + ",8";
	EndIf;
	// Stop bits
	If ValueIsFilled(StopBits) Then
		If StopBits = Enums.StopBits.Bits1 Then
			vStr = vStr + ",1";
		ElsIf StopBits = Enums.StopBits.Bits2 Then
			vStr = vStr + ",2";
		EndIf;
	Else
		vStr = vStr + ",1";
	EndIf;
	vStr = vStr + ",X";
	Return vStr;		
EndFunction // GetCOMPortConnectionString

// -----------------------------------------------------------------------------
Function ReadString()
	SerialConnector.TimeoutReadTotalConstant = 3000;
	vReply = "";
	vBytesRcv = 1;
	While vBytesRcv > 0 Do
		vChar = 0;
		vBytesRcv = SerialConnector.Read(vChar, 1);
		If vBytesRcv > 0 Then
			vReply = vReply+Char(vChar);
		EndIf;
	EndDo;
	Return vReply;
EndFunction // ReadString

// -----------------------------------------------------------------------------
Function GetDataPresentation(Val pStr)
	pStr = StrReplace(pStr,ACK,"<ACK>");
	pStr = StrReplace(pStr,NAK,"<NAK>");
	pStr = StrReplace(pStr,ENQ,"<ENQ>");
	pStr = StrReplace(pStr,STX,"<STX>");
	pStr = StrReplace(pStr,ETX,"<ETX>");
	pStr = StrReplace(pStr,DLE,"<DLE>");
	Return pStr;
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function Acknowledgement()
	// Send ENQ and wait for ACK
	vCmd = ENQ;
	vReply = "";
	If DebugMode Then
		DoMessage("PMS -> PBX. " + GetDataPresentation(vCmd));
	EndIf;
	vBytesSent = SerialConnector.WriteStr(ENQ);
	If vBytesSent = 1 Then
		vReply = ReadString();
		If Not IsBlankString(vReply) Then
			If DebugMode Then
				DoMessage("PBX -> PMS. " + GetDataPresentation(vReply));
			EndIf;
			If vReply = ACK Then
				Return True;
			ElsIf vReply = NAK Then
				DoMessage(NStr("en='NAK received on acknowledgement!';ru='При подтверждении связи получен NAK!';de='Bei der Bestätigung der Verbindung NAK erhalten!'"), MessageStatus.Attention);
			EndIf;
		EndIf;
		vBytesSent = SerialConnector.WriteStr("T");
		If vBytesSent = 1 Then
			SerialConnector.TimeoutReadTotalConstant = 1000;
			vReply = ReadString();
			If IsBlankString(vReply) Then
				DoMessage(NStr("en='PBX is not responding';ru='АТС не отвечает';de='PBX reagiert nicht!'") + vReply, MessageStatus.Attention);
			ElsIf vReply = "T" Or vReply = "t" Then
				Return True;
			Else
				DoMessage(NStr("en='Wrong reply received on acknowledgement: ';ru='При подтверждении связи получен символ: ';de='Bei der Bestätigung der Verbindung Symbol erhalten:'") + vReply, MessageStatus.Attention);
			EndIf;
		Else
			DoMessage(NStr("en='PBX is not responding';ru='АТС не отвечает';de='PBX reagiert nicht!'") + vReply, MessageStatus.Attention);
		EndIf;
	Else
		DoMessage(NStr("en='Wrong number of bytes sent on acknowledgement: ';ru='При подтверждении связи отправлено байт: ';de='Bei der Bestätigung der Verbindung Byte versendet:'") + vBytesSent, MessageStatus.Attention);
	EndIf;
	Return False;
EndFunction // Acknowledgement

// -----------------------------------------------------------------------------
Function Transliterate(pStr)
	vStr = pStr;
	vStr = StrReplace(vStr, "А", "A");
	vStr = StrReplace(vStr, "Б", "B");
	vStr = StrReplace(vStr, "В", "V");
	vStr = StrReplace(vStr, "Г", "G");
	vStr = StrReplace(vStr, "Д", "D");
	vStr = StrReplace(vStr, "Е", "E");
	vStr = StrReplace(vStr, "Ё", "E");
	vStr = StrReplace(vStr, "Ж", "Zh");
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
	vStr = StrReplace(vStr, "Ч", "Ch");
	vStr = StrReplace(vStr, "Ш", "Sh");
	vStr = StrReplace(vStr, "Щ", "Sch");
	vStr = StrReplace(vStr, "Ь", "'");
	vStr = StrReplace(vStr, "Ы", "Yi");
	vStr = StrReplace(vStr, "Ъ", "");
	vStr = StrReplace(vStr, "Э", "E");
	vStr = StrReplace(vStr, "Ю", "Yu");
	vStr = StrReplace(vStr, "Я", "Ya");
	vStr = StrReplace(vStr, "а", "a");
	vStr = StrReplace(vStr, "б", "b");
	vStr = StrReplace(vStr, "в", "v");
	vStr = StrReplace(vStr, "г", "g");
	vStr = StrReplace(vStr, "д", "d");
	vStr = StrReplace(vStr, "е", "e");
	vStr = StrReplace(vStr, "ё", "e");
	vStr = StrReplace(vStr, "ж", "zh");
	vStr = StrReplace(vStr, "з", "z");
	vStr = StrReplace(vStr, "и", "i");
	vStr = StrReplace(vStr, "й", "y");
	vStr = StrReplace(vStr, "к", "k");
	vStr = StrReplace(vStr, "л", "l");
	vStr = StrReplace(vStr, "м", "m");
	vStr = StrReplace(vStr, "н", "n");
	vStr = StrReplace(vStr, "о", "o");
	vStr = StrReplace(vStr, "п", "p");
	vStr = StrReplace(vStr, "р", "r");
	vStr = StrReplace(vStr, "с", "s");
	vStr = StrReplace(vStr, "т", "t");
	vStr = StrReplace(vStr, "у", "u");
	vStr = StrReplace(vStr, "ф", "f");
	vStr = StrReplace(vStr, "х", "h");
	vStr = StrReplace(vStr, "ц", "c");
	vStr = StrReplace(vStr, "ч", "ch");
	vStr = StrReplace(vStr, "ш", "sh");
	vStr = StrReplace(vStr, "щ", "sch");
	vStr = StrReplace(vStr, "ь", "'");
	vStr = StrReplace(vStr, "ы", "yi");
	vStr = StrReplace(vStr, "ъ", "");
	vStr = StrReplace(vStr, "э", "e");
	vStr = StrReplace(vStr, "ю", "yu");
	vStr = StrReplace(vStr, "я", "ya");
	vStr = StrReplace(vStr, "Ā", "A");
	vStr = StrReplace(vStr, "ā", "a");
	vStr = StrReplace(vStr, "Č", "C");
	vStr = StrReplace(vStr, "č", "c");
	vStr = StrReplace(vStr, "Ē", "E");
	vStr = StrReplace(vStr, "ē", "e");
	vStr = StrReplace(vStr, "Ģ", "G");
	vStr = StrReplace(vStr, "ģ", "g");
	vStr = StrReplace(vStr, "Ī", "I");
	vStr = StrReplace(vStr, "ī", "i");
	vStr = StrReplace(vStr, "Ķ", "K");
	vStr = StrReplace(vStr, "ķ", "k");
	vStr = StrReplace(vStr, "Ļ", "L");
	vStr = StrReplace(vStr, "ļ", "l");
	vStr = StrReplace(vStr, "Ņ", "N");
	vStr = StrReplace(vStr, "ņ", "n");
	vStr = StrReplace(vStr, "Š", "S");
	vStr = StrReplace(vStr, "š", "s");
	vStr = StrReplace(vStr, "Ū", "U");
	vStr = StrReplace(vStr, "ū", "u");
	vStr = StrReplace(vStr, "Ž", "Z");
	vStr = StrReplace(vStr, "ž", "z");
	Return vStr;
EndFunction // Transliterate

// -----------------------------------------------------------------------------
Function PadWithBlanks(pTxt, pLen)
	vTxt = TrimAll(pTxt);
	vLen = StrLen(vTxt);
	If vLen < pLen Then
		While vLen < pLen Do
			vTxt = vTxt + " ";
			vLen = vLen + 1;
		EndDo;
	ElsIf vLen > pLen Then
		vTxt = Left(vTxt, pLen);
	EndIf;
	Return vTxt;
EndFunction // PadWithBlanks

// -----------------------------------------------------------------------------
// Check-in guest
// -----------------------------------------------------------------------------
Function GetCHKIMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			// Name and period
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) Then
				vDoc = pEventRow.ParentDoc;
				If ValueIsFilled(vDoc.Guest) Then
					vGuest = vDoc.Guest;
					vGuestName = TrimAll(TrimAll(vGuest.FirstName) + ?(IsBlankString(vGuest.SecondName), "", " " + TrimAll(vGuest.SecondName)) + " " + TrimAll(vGuest.LastName));
					vGuestName = Left(Transliterate(vGuestName), 128);
				EndIf;
			EndIf;		
			// Build command string
			vData = "A" + Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + "0" + 
			        PadWithBlanks(vGuestName, 20) + " " + " " + "   " + "    " + "  " + "         " + "0" + 
					"     " + " ";
		Else
			DoMessage(NStr("en='Phone number is not specified for the room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for the room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for the room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetCHKIMessage
 
// -----------------------------------------------------------------------------
// Update guest data
// -----------------------------------------------------------------------------
Function GetUPDGMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			// Name and period
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) Then
				vDoc = pEventRow.ParentDoc;
				If ValueIsFilled(vDoc.Guest) Then
					vGuest = vDoc.Guest;
					vGuestName = TrimAll(TrimAll(vGuest.FirstName) + ?(IsBlankString(vGuest.SecondName), "", " " + TrimAll(vGuest.SecondName)) + " " + TrimAll(vGuest.LastName));
					vGuestName = Left(Transliterate(vGuestName), 128);
				EndIf;
			EndIf;		
			// Build command string
			vData = "M" + Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + "0" + 
			        PadWithBlanks(vGuestName, 20) + " " + " " + "   " + "    " + "  " + "         " + "0" + 
					"     " + " ";
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetUPDGMessage
 
// -----------------------------------------------------------------------------
// Check-out guest
// -----------------------------------------------------------------------------
Function GetCHKOMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			// Build command string
			vData = "D" + Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=");
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetCHKOMessage

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref,
	|	RoomInterfaceStatus.Hotel,
	|	RoomInterfaceStatus.Room,
	|	RoomInterfaceStatus.RoomInterfaceType,
	|	RoomInterfaceStatus.Remarks,
	|	RoomInterfaceStatus.IsProcessed,
	|	RoomInterfaceStatus.IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number,
	|	RoomInterfaceStatus.Date,
	|	RoomInterfaceStatus.ParentDoc,
	|	RoomInterfaceStatus.Author,
	|	RoomInterfaceStatus.CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters AS TurnOnParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters AS TurnOffParameters,
	|	RoomInterfaceStatus.RoomInterfaceType.InterfaceType AS InterfaceType
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qPBX
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckInDate IS NULL 
	|	AND RoomInterfaceStatus.ParentDoc.CheckInDate <= &qEndOfCurrentDate
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckOutDate IS NULL 
	|	AND RoomInterfaceStatus.ParentDoc.CheckOutDate >= &qBegOfCurrentDate
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qPBX", Enums.InterfaceTypes.Phone);
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -----------------------------------------------------------------------------
Procedure ProcessCheckInEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "CHKI" Then
			vSuccess = False;
			// Build message for PBX
			vData = GetCHKIMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PBX. CHKIN message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			
			// Send command to the PBX
			If Not IsBlankString(vData) Then
				vError = "";
				If SendReceiveCommand(vData, vError) Then
					// Set processed status to the interface record
					vStsObj = vEventRow.Ref.GetObject();
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write);
					cmWait(1);
				Else
					DoMessage("PMS -> PBX. CHKIN message. Data NOT written! Error: " + vError, MessageStatus.Attention);
					cmWait(2);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckInEvents

// -----------------------------------------------------------------------------
Procedure ProcessCheckOutEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "CHKO" Then
			vSuccess = False;
			// Build check-out message for PBX
			vData = GetCHKOMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PBX. CHKOUT message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			
			// Send command to the PBX
			If Not IsBlankString(vData) Then
				vError = "";
				If SendReceiveCommand(vData, vError) Then
					// Set processed status to the interface record
					vStsObj = vEventRow.Ref.GetObject();
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write);
					cmWait(1);
				Else
					DoMessage("PMS -> PBX. CHKOUT message. Data NOT written! Error: " + vError, MessageStatus.Attention);
					cmWait(2);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckOutEvents

// -----------------------------------------------------------------------------
Procedure ProcessSetGuestNameEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "UPDG" Then
			vSuccess = False;
			// Build message for PBX
			vData = GetUPDGMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PBX. UPDGUEST message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			
			// Send command to the PBX
			If Not IsBlankString(vData) Then
				vError = "";
				If SendReceiveCommand(vData, vError) Then
					// Set processed status to the interface record
					vStsObj = vEventRow.Ref.GetObject();
					vStsObj.IsProcessed = True;
					vStsObj.Write(DocumentWriteMode.Write);
					cmWait(1);
				Else
					DoMessage("PMS -> PBX. UPDGUEST message. Data NOT written! Error: " + vError, MessageStatus.Attention);
					cmWait(2);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessSetGuestNameEvents

// -----------------------------------------------------------------------------
Function GetEmployee(pPBXAccountCode)
	vEmployee = Undefined;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Employees.Ref
	|FROM
	|	Catalog.Employees AS Employees
	|WHERE
	|	NOT Employees.DeletionMark
	|	AND NOT Employees.IsFolder
	|	AND (Employees.Hotel = &qHotel
	|			OR Employees.Hotel = &qEmptyHotel)
	|	AND Employees.PBXAccountCode = &qPBXAccountCode
	|
	|ORDER BY
	|	Employees.SortCode,
	|	Employees.Description";
	vQry.SetParameter("qPBXAccountCode", pPBXAccountCode);
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vEmployees = vQry.Execute().Unload();
	If vEmployees.Count() > 0 Then
		vEmployee = vEmployees.Get(0).Ref;
	EndIf;
	Return vEmployee;
EndFunction // GetEmployee

// -----------------------------------------------------------------------------
Procedure SetRoomStatus(pRoom, pRoomStatus, pEmpCode="", pOperationTime = Undefined)
	If pOperationTime = Undefined Then
		pOperationTime = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(pRoom) And ValueIsFilled(pRoomStatus) Then
		If DebugMode Then
			DoMessage("PBX -> PMS. Room to be updated is: " + pRoom + ", status to be set is: " + pRoomStatus, MessageStatus.Information);
		EndIf;
		// Skip updating status if it is equal to the new one
		If pRoom.RoomStatus <> pRoomStatus Then
			// Skip updating room status if it was set after phone call time
			vRoomObj = pRoom.GetObject();
			vLastStatus = vRoomObj.pmGetRoomStatusHistoryState('39991231235959');
			If vLastStatus.Count() > 0 Then
				vLastStatusRow = vLastStatus.Get(0);
				If pOperationTime < vLastStatusRow.Period Then
					If DebugMode Then
						DoMessage("PBX -> PMS. Room status update will be skipped because operation time " + pOperationTime + " is earlier then last room status change time " + vLastStatusRow.Period, MessageStatus.Information);
					EndIf;
					Return;
				ElsIf vLastStatusRow.RoomStatus = vRoomObj.Owner.OccupiedRoomStatus Then
					If DebugMode Then
						DoMessage("PBX -> PMS. Room status update will be skipped because current room status is occupied!", MessageStatus.Information);
					EndIf;
					Return;
				EndIf;
			EndIf;

			// Update room status
			vRoomObj.RoomStatus = pRoomStatus;
			vRoomObj.Write();
			// Get employee code
			vEmployee = Undefined;
			If Not IsBlankString(pEmpCode) And cmIsNumber(pEmpCode) Then
				vPBXAccountCode = Number(pEmpCode);
				vEmployee = GetEmployee(vPBXAccountCode);
				If DebugMode Then
					DoMessage("PBX -> PMS. Employee responsible is " + TrimAll(vEmployee), MessageStatus.Information);
				EndIf;
			EndIf;
			// Add record to the room status change history
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "PBX -> PMS");
		Else
			If DebugMode Then
				DoMessage("PBX -> PMS. Current room status is the same as the one to be set!", MessageStatus.Information);
			EndIf;
		EndIf;
	Else
		If DebugMode Then
			If Not ValueIsFilled(pRoom) Then
				DoMessage("PBX -> PMS. Room is not defined!", MessageStatus.Attention);
			ElsIf Not ValueIsFilled(pRoomStatus) Then
				DoMessage("PBX -> PMS. Room status is not defined!", MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetRoomStatus

// -----------------------------------------------------------------------------
Function ProcessCallEventFromPBX(pData)
	vSuccess = True;
	// Check message type
	vMsgType = Mid(pData, 2, 1);
	If vMsgType = "J" Then
		vData = Mid(pData, 2, 64);
		If DebugMode Then
			DoMessage("PBX -> PMS. Call data received: " + GetDataPresentation(vData));
		EndIf;
		// Save call data to the calls logging file
		If Not IsBlankString(CallsLoggingFile) Then
			Try
				vTextWriter = New TextWriter(CallsLoggingFile, , , True);
				vTextWriter.WriteLine(vData);
				vTextWriter.Close();
			Except
				DoMessage("PBX -> PMS. Error writing call data to the log file: " + cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
				vSuccess = False;
			EndTry;
		EndIf;
	ElsIf vMsgType = "C" Then
		vData = Mid(pData, 2, 11);
		If DebugMode Then
			DoMessage("PBX -> PMS. Room status change: " + GetDataPresentation(vData));
		EndIf;
		vOperationTime = CurrentSessionDate();
		// Parse message
		vPhoneNumberStr = TrimAll(Mid(vData, 2, 5));
		vEmployeeCode = TrimAll(Mid(vData, 7, 4));
		vRoomStatusCode = TrimAll(Mid(vData, 11, 1));
		// Update room status
		vRoomStatus = Undefined;
		If Not IsBlankString(vPhoneNumberStr) Then
			vRoom = cmGetRoomByPhoneNumber(vPhoneNumberStr);
			If ValueIsFilled(vRoom) Then
				vRoomStatus = GetRoomStatus(vRoom, vRoomStatusCode);
				If ValueIsFilled(vRoomStatus) Then
					// Skip updating room status if it was set after phone call time
					SetRoomStatus(vRoom, vRoomStatus, vEmployeeCode, vOperationTime);
				Else
					DoMessage("PBX -> PMS. Failed to get room status by code: " + GetDataPresentation(vRoomStatusCode));
					vSuccess = False;
				EndIf;
			Else
				DoMessage("PBX -> PMS. Failed to get room by phone number: " + GetDataPresentation(vPhoneNumberStr));
				vSuccess = False;
			EndIf;
		Else
			DoMessage("PBX -> PMS. Failed to find room in message data!");
			vSuccess = False;
		EndIf;
	Else
		If DebugMode Then
			DoMessage("PBX -> PMS. Data received: " + GetDataPresentation(pData));
		EndIf;
		DoMessage("PBX -> PMS. Unsupported message type for calls data message. Message type received is: " + vMsgType, MessageStatus.Attention);
		vSuccess = False;
	EndIf;
	Return vSuccess;
EndFunction // ProcessCallEventFromPBX

// -----------------------------------------------------------------------------
Function GetRoomStatus(pRoom, pRoomStatusCode)
	vRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	vRoomStatusCode = Number(pRoomStatusCode);
	vRoomStatus = cmGetRoomStatusByPBXPhoneNumber(vRoomStatusCode);
	Return vRoomStatus;
EndFunction // GetRoomStatus

// -----------------------------------------------------------------------------
Function DoMainProcessingCycle()
	vReturn = True;
	// Update is running state
	pmLoadDataProcessorAttributes();
	If StopInterface Then
		Return False;
	EndIf;
	IsRunning = True;
	Timestamp = tcOnServer.cmGetServerCurrentSessionDate();
	pmSaveDataProcessorAttributes();
	// Get all active room interface events that need to be processed
	If Not SkipProcessingOfRoomInterfaceServices Then
		vActiveEvents = GetActiveRoomInterfaceEvents();
		Try
			// Process check-in events
			ProcessCheckInEvents(vActiveEvents);
			// Process check-out events
			ProcessCheckOutEvents(vActiveEvents);
			// Process set guest names
			ProcessSetGuestNameEvents(vActiveEvents);
		Except
			DoMessage("Error: " + cmGetRootErrorDescription(ErrorInfo()), MessageStatus.Attention);
			Return False;
		EndTry;
	EndIf;
	// Read events from PBX
	vReturn = ProcessCallLoggingDataFromPBX();
	Return vReturn;
EndFunction // DoMainProcessingCycle

// -----------------------------------------------------------------------------
Function ProcessCallLoggingDataFromPBX()
	vSuccess = False;
	// Read event from PBX
	vData = ReadString();
	If StrLen(vData) > 0 Then
		vSuccess = ProcessCallEventFromPBX(vData);
		If vSuccess Then
			DoMessage("PMS. Record successfully processed!", MessageStatus.Information);
			vBytesSent = SerialConnector.WriteStr(ACK);
			If DebugMode Then
				If vBytesSent = 1 Then
					DoMessage("PMS -> PBX. ACK was sent!", MessageStatus.Information);
				Else
					DoMessage("PMS -> PBX. Failed to confirm that record successfully processed!", MessageStatus.Attention);
				EndIf;
			EndIf;
		Else
			DoMessage("PMS. Error processing call data!", MessageStatus.Attention);
		EndIf;
	Else
		vSuccess = True;
		DoMessage("PBX -> PMS. No phone call data received as an answer to NAK!", MessageStatus.Attention);
	EndIf;
	Return vSuccess;
EndFunction // ProcessCallLoggingDataFromPBX

// -----------------------------------------------------------------------------
Function SendReceiveCommand(Val pData, rError)
	vSuccess = False;
	rError = "";
	// Control characters
	pData = STX + pData;
	pData = pData + cmHexCSUM(pData) + ETX;
	// Handshake
	If SerialConnector.WriteStr(ENQ) = -1 Then
		rError = "Unable to send handshake command to PBX!";
	Else
		vChar = ReadString();
		If StrLen(vChar) > 0 Then
			If vChar = ACK Then
				// Command
				If SerialConnector.WriteStr(pData) = -1 Then
					rError = "Failed to send <ACK>!";
				Else
					// Check reply
					vChar = ReadString();
					If vChar = ACK Then
						vSuccess = True;
						If DebugMode Then
							DoMessage("PBX -> PMS. Reply: " + GetDataPresentation(vChar));
						EndIf;
					Else
						If Not IsBlankString(vChar) Then
							DoMessage("PBX -> PMS. Reply: " + GetDataPresentation(vChar));
						EndIf;
						rError = "Command rejected by PBX!";
					EndIf;
				EndIf;
			Else
				rError = "Handshake rejected by PBX!";
			EndIf;
		Else
			rError = "No answer to handshake from PBX!";
		EndIf;
	EndIf;
	Return vSuccess;
EndFunction // SendReceiveCommand


#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
STX = Char(2);
ETX = Char(3);
DLE = Char(16);
XON = Char(17);

#EndRegion

