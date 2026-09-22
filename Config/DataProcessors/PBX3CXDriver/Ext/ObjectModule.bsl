Var TCPIP;
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;
Var TIMEOUT;
Var EventsArr;

// -----------------------------------------------------------------------------
Var STX;
Var ETX;
Var ENQ;
Var ACK;
Var NAK;
Var SP;

// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

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
	If Port = 0 Then
		Port = 51000;
	EndIf;
	If IsBlankString(Address) Then
		Address = "127.0.0.1";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Start interface client
	pmRunInterfaceClient(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Procedure pmRunInterfaceClient(pIsInteractive = False) Export
	If (Not IsServer And ValueIsFilled(Address) And Port <> 0) Or (IsServer And Port <> 0) Then
		If IsRunning And (tcOnServer.cmGetServerCurrentSessionDate() - Timestamp) < 120 Then
			Return;
		EndIf;
		IsRunning = True;
		StopInterface = False;
		Timestamp = tcOnServer.cmGetServerCurrentSessionDate();
		pmSaveDataProcessorAttributes();
		// Create client ActiveX object
		Try
		    TCPIP = New COMObject("SocketTools.SocketWrench.10");
			// Load license
			vErrorCode = TCPIP.Initialize(CSWSOCK10_LICENSE_KEY);
		Except
			TCPIP = New COMObject("SocketTools.SocketWrench.6");
			// Load license
			vErrorCode = TCPIP.Initialize(CSWSOCK6_LICENSE_KEY);
		EndTry;
		// Initialize parameters
		TCPIP.Blocking = True;
		TCPIP.Timeout = TIMEOUT; // 10 seconds blocking read timeout by default		
		While Connect() Or Not StopInterface Do
			ReadBuff();
			ProcessEventsFromPMS();
			While TCPIP.Connected And Not TCPIP.IsClosed And Not StopInterface Do
				DoMainProcessingCycle();
				ReadBuff();
				ProcessEventsFromPMS();
				pmLoadDataProcessorAttributes();
				If StopInterface Then
					Break;
				EndIf;
			EndDo;
			If StopInterface Then
				Break;
			EndIf;
		EndDo;
		vErrorCode = TCPIP.Disconnect();
		If vErrorCode <> 0 Then
			DoMessage(NStr("en = 'PBX server disconnect error: '; de = 'Fehler beim Trennen des PBX-Servers: '; ru = 'Ошибка отключения от сервера PBX: '") + vErrorCode, MessageStatus.Attention);
		EndIf;  
		IsRunning = False;
		StopInterface = False;
		Timestamp = Undefined;
		pmSaveDataProcessorAttributes();
	Else
		DoMessage(NStr("en = 'Server connection parameters are missing...'; de = 'Server-Verbindung Parameter fehlen...'; ru = 'Не указаны параметры подключения к серверу PBX...'"));
	EndIf;
EndProcedure // pmRunInterfaceClient

// -----------------------------------------------------------------------------
Function Connect()
	vResult = True;
	If Not TCPIP.Connected Or TCPIP.IsClosed Then
		vErrorCode = 0;
		If Not IsServer Then
			vErrorCode = TCPIP.Connect(StrReplace(Address, " ", ""), Port);	
		ElsIf Not TCPIP.Listening Then  
			vErrorCode = TCPIP.Listen("0.0.0.0", Port);		
		EndIf;
		If vErrorCode <> 0 Then
			DoMessage(NStr("en = 'PBX server was not found: '; de = 'PBX server was not found: '; ru = 'Не найден PBX сервер: '") + vErrorCode + " - " + TCPIP.LastErrorString, MessageStatus.Attention);
			vResult = False;
		ElsIf IsServer And TCPIP.Listening Then
			vErrorCode = -1;
			While vErrorCode <> 0 Do
				pmLoadDataProcessorAttributes();
				If StopInterface Then
					vResult = False;
					Break;
				EndIf;
				vErrorCode = TCPIP.Accept(TCPIP.Handle);
			EndDo;
		ElsIf IsServer And Not TCPIP.Listening Then
			vResult = False;	
		EndIf;
		If vResult And DebugMode Then
			DoMessage("PBX -> Connection successfull");
		EndIf;
	EndIf;
	Return vResult;
EndFunction // Connect

// -----------------------------------------------------------------------------
Function ReadBuff()
	vReply = "";
	vBuffStr = "";
	vBytesRcv = 1;
	While vBytesRcv > 0 Do
		vBytesRcv = TCPIP.Read(vReply, 1);
		If vBytesRcv > 0 Then
			If vReply = ACK Or vReply = NAK Then
				Break;	
			ElsIf vReply = STX Then
				vBuffStr = vReply; 
				While vReply <> ETX And vBytesRcv > 0 Do
					vBytesRcv = TCPIP.Read(vReply, 1);
					If vBytesRcv > 0 Then
						vBuffStr = vBuffStr + vReply; 
					EndIf;
				EndDo;
				EventsArr.Add(vBuffStr);
				If DebugMode Then
					DoMessage("PBX -> Data received: " + GetDataPresentation(vBuffStr));
				EndIf;
				vReply = "";
				vBuffStr = "";	
			EndIf;
			vReply = "";
			vBuffStr = "";
		EndIf;
	EndDo;
	Return vReply;
EndFunction // Read

// -----------------------------------------------------------------------------
Function GetDataPresentation(Val pStr)
	pStr = StrReplace(pStr, ACK,"[ACK]");
	pStr = StrReplace(pStr, NAK,"[NAK]");
	pStr = StrReplace(pStr, ENQ,"[ENQ]");
	pStr = StrReplace(pStr, STX,"[STX]");
	pStr = StrReplace(pStr, ETX,"[ETX]");
	Return pStr;
EndFunction // GetDataPresentation

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
	Return vStr;
EndFunction // Transliterate
 
// -----------------------------------------------------------------------------
Function GetCHKIMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vData = STX + "CHK1" + SP + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetCHKIMessage

// -----------------------------------------------------------------------------
Function GetCHKOMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vData = STX + "CHK0" + SP + vExtensionNumber + ETX;
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
Function GetGNSTMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) And ValueIsFilled(pEventRow.ParentDoc.Guest) Then
				vGuest = pEventRow.ParentDoc.Guest;
				vGuestName = Left(Transliterate(TrimAll(vGuest.FirstName)), 20);
			EndIf;
			While StrLen(vGuestName) < 21 Do
				vGuestName = SP + vGuestName;	
			EndDo;
	
			vData = STX + "NAM0" + SP + vGuestName + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetGNSTMessage
 
// -----------------------------------------------------------------------------
Function GetGNCLMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			vGuestName = "";
			While StrLen(vGuestName) < 21 Do
				vGuestName = SP + vGuestName;	
			EndDo;
	
			vData = STX + "NAM0" + SP + vGuestName + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetCHKOGNSTMessage
   
// -----------------------------------------------------------------------------
Function GetWKPSMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vWakeUpTime = Format(pEventRow.MessageDateTime, "DF=HHmm");
			
			vData = STX + "WKP" + vWakeUpTime + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetSWKUMessage
 
// -----------------------------------------------------------------------------
Function GetWKPCMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vWakeUpTime = SP + SP + SP + SP;
			
			vData = STX + "WKP" + vWakeUpTime + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetCWKUMessage
 
// -----------------------------------------------------------------------------
Function GetDNDSMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If ValueIsFilled(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vData = STX + "DND1" + SP + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetMLONMessage
 
// -----------------------------------------------------------------------------
Function GetDNDCMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vExtensionNumber = Left(TrimAll(vPhoneNumber), 5);
			While StrLen(vExtensionNumber) < 5 Do
				vExtensionNumber = SP + vExtensionNumber;	
			EndDo;
			
			vData = STX + "DND0" + SP + vExtensionNumber + ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetMLOFMessage

// -----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined)
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage(TrimAll(CurrentSessionDate()) + " " + pMsg, vMsgStatus);
	WriteLogEvent("3CX.PBX", ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() Export
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.Hotel AS Hotel,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.RoomInterfaceType AS RoomInterfaceType,
	|	RoomInterfaceStatus.Remarks AS Remarks,
	|	RoomInterfaceStatus.IsProcessed AS IsProcessed,
	|	RoomInterfaceStatus.IsCanceled AS IsCanceled,
	|	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	|	RoomInterfaceStatus.MessageIsDelivered AS MessageIsDelivered,
	|	RoomInterfaceStatus.MessageDeliveryDateTime AS MessageDeliveryDateTime,
	|	RoomInterfaceStatus.Number AS Number,
	|	RoomInterfaceStatus.Date AS Date,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Author AS Author,
	|	RoomInterfaceStatus.CancellationAuthor AS CancellationAuthor,
	|	RoomInterfaceStatus.CancellationDate AS CancellationDate,
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
	|	AND CASE
	|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				THEN RoomInterfaceStatus.Hotel = &qHotel
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPBX", Enums.InterfaceTypes.Phone);
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -----------------------------------------------------------------------------
Procedure ProcessesEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		vSuccess = False;
		vData = "";
		vEventName = "";
		
		If StrLen(TrimAll(vEventRow.TurnOnParameters)) < 4 Then
			Continue; 	
		ElsIf Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "CHKI" Then
			vData = GetCHKIMessage(vEventRow);
			vEventName = "Check In";
		ElsIf vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "CHKO" Then
			vData = GetCHKOMessage(vEventRow);
			vEventName = "Check Out";
		ElsIf Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "GNST" Then
			vData = GetGNSTMessage(vEventRow);
			vExtraName = "Name Set";	
		ElsIf vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "GNCL" Then 
			vData = GetGNCLMessage(vEventRow);
			vEventName = "Name Clear";
		ElsIf Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "WKPS" Then
			vData = GetWKPSMessage(vEventRow);
			vEventName = "Wake Up Set";	
		ElsIf vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "WKPC" Then
			vData = GetWKPCMessage(vEventRow);
			vEventName = "Wake Up Clear";	
		ElsIf Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "DNDS" Then
			vData = GetDNDSMessage(vEventRow);
			vEventName = "DND Set";		
		ElsIf vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "DNDC" Then
			vData = GetDNDCMessage(vEventRow);
			vEventName = "DND Clear";	
		EndIf;
		
		If ValueIsFilled(vData) And ValueIsFilled(vEventName) Then 
			vSuccess = ProcessingEvents(vData, vEventName);
		EndIf;
		
		// Set processed status to the interface record
		If vSuccess Then
			vStsObj = vEventRow.Ref.GetObject();
			vStsObj.IsProcessed = True;
			vStsObj.Write(DocumentWriteMode.Write);
		EndIf;
	EndDo;
EndProcedure // ProcessCheckInEvents

// -----------------------------------------------------------------------------
Function ProcessingEvents(pData, pProcessName)
	vSuccess = False;
	If TCPIP.Write(ENQ, 1) = -1 Then
		DoMessage("PMS -> PBX. Unable to send [ENQ] to PBX!", MessageStatus.Attention);
		Raise TCPIP.LastErrorString;
	Else
		vResponse = ReadBuff();
		If Not ValueIsFilled(vResponse) Then
			DoMessage("PBX -> PMS. No reply from [ENQ]!", MessageStatus.Attention);
			Raise TCPIP.LastErrorString;
		Else
			If vResponse = NAK Then
				vMsg = "Transmission error, or that the system is busy"; 
				DoMessage(vMsg, MessageStatus.Attention);
				Raise vMsg;	
			EndIf;
		EndIf;
	EndIf;
	For i = 1 To 4 Do
		If TCPIP.Write(pData, StrLen(pData)) = -1 Then
			DoMessage("PMS -> PBX. Unable to send " + pProcessName + " data to PBX!", MessageStatus.Attention);
			Raise TCPIP.LastErrorString;
		Else
			vResponse = ReadBuff();
			If Not ValueIsFilled(vResponse) Then
				DoMessage("PBX -> PMS. No reply from " + pProcessName + "!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				If vResponse = ACK Then 
					vSuccess = True;
					Break;
				Else
					DoMessage("PBX -> PMS. Wrong reply to keep alive: " + GetDataPresentation(vResponse), MessageStatus.Attention);	
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return vSuccess;
EndFunction // ProcessingResponse

// -----------------------------------------------------------------------------
Function GetRoomByCode(Val pStr)
	vRoom = Catalogs.Rooms.EmptyRef();
	
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Room AS Room
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	NOT PhoneNumbers.DeletionMark
	|	AND NOT PhoneNumbers.IsFolder
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|	AND CASE
	|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				THEN PhoneNumbers.Owner = &qHotel
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	PhoneNumbers.Room.SortCode,
	|	PhoneNumbers.SortCode,
	|	PhoneNumbers.Code";
	vQry.SetParameter("qHotel", Hotel);
	vQry.SetParameter("qPhoneNumber", pStr);
	vPhoneNumbers = vQry.Execute().Unload();
	
	If vPhoneNumbers.Count() = 0 Then
		DoMessage(NStr("en='Phone number is not found for extension code '; ru='Не найден номер телефона по extension коду '; de='Telefonnummer ist nicht für Extension Code gefunden - '") + TrimAll(pStr), MessageStatus.Attention);
	ElsIf vPhoneNumbers.Count() > 1 Then
		DoMessage(NStr("en='Multiple phone numbers are found for extension code '; ru='Несколько номеров телефонов найдено по extension коду '; de='Mehrere Telefonnummern für Extension Code gefunden - '") + TrimAll(pStr), MessageStatus.Attention);
	Else
		vRoom = vPhoneNumbers.Get(0).Room; 	
	EndIf;
	
	Return vRoom;
EndFunction // GetRoomByCode

// -----------------------------------------------------------------------------
Function GetRoomStatus(Val pStr)
	vRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	
	If cmIsNumber(pStr) Then
		vPBXPhoneNumber = Number(pStr);
		If vPBXPhoneNumber > 0 Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	RoomStatuses.Ref AS RoomStatus
			|FROM
			|	Catalog.RoomStatuses AS RoomStatuses
			|WHERE
			|	RoomStatuses.PBXCode = &qPBXPhoneNumber
			|	AND NOT RoomStatuses.DeletionMark
			|	AND NOT RoomStatuses.IsFolder
			|	AND CASE
			|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
			|				THEN RoomStatuses.Hotel = &qHotel
			|			ELSE TRUE
			|		END
			|
			|ORDER BY
			|	RoomStatuses.SortCode";
			vQry.SetParameter("qHotel", Hotel);
			vQry.SetParameter("qPBXPhoneNumber", vPBXPhoneNumber);
			vQryRes = vQry.Execute().Unload();
			If vQryRes.Count() > 0 Then
				vRoomStatus = vQryRes.Get(0).RoomStatus;	
			EndIf;	
		EndIf;
	EndIf;
	
	Return vRoomStatus;
EndFunction // GetRoomStatus

// -----------------------------------------------------------------------------
Procedure SetRoomStatus(pRoom, pRoomStatus, pOperationTime = Undefined)
	If pOperationTime = Undefined Then
		pOperationTime = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(pRoom) And ValueIsFilled(pRoomStatus) Then
		If DebugMode Then
			DoMessage("PBX -> Room to be updated is: " + pRoom + ", status to be set is: " + pRoomStatus, MessageStatus.Information);
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
						DoMessage("PBX -> Room status update will be skipped because operation time " + pOperationTime + " is earlier then last room status change time " + vLastStatusRow.Period, MessageStatus.Information);
					EndIf;
					Return;
				ElsIf vLastStatusRow.RoomStatus = vRoomObj.Owner.OccupiedRoomStatus Then
					If DebugMode Then
						DoMessage("PBX -> Room status update will be skipped because current room status is occupied!", MessageStatus.Information);
					EndIf;
					Return;
				EndIf;
			EndIf;

			// Update room status
			vRoomObj.RoomStatus = pRoomStatus;
			vRoomObj.Write();
			
			// Add record to the room status change history
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser, "PBX -> PMS");
		Else
			If DebugMode Then
				DoMessage("PBX -> Current room status is the same as the one to be set!", MessageStatus.Information);
			EndIf;
		EndIf;
	Else
		If DebugMode Then
			If Not ValueIsFilled(pRoom) Then
				DoMessage("PBX -> Room is not defined!", MessageStatus.Attention);
			ElsIf Not ValueIsFilled(pRoomStatus) Then
				DoMessage("PBX -> Room status is not defined!", MessageStatus.Attention);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetRoomStatus

// -----------------------------------------------------------------------------
Procedure ProcessEventsFromPMS()
	vOperationTime = CurrentSessionDate();
	While EventsArr.Count() > 0 Do
		vFullData = EventsArr[0]; 
		If DebugMode Then
			DoMessage("PBX -> Message parsed from pos " + GetDataPresentation(vFullData));
		EndIf;
		vData = TrimAll(StrReplace(StrReplace(vFullData, STX, ""), ETX, ""));
		If Left(vData, 3) = "STS" And StrLen(vData) = 10 Then
			// Change room status to Cleaned Vacant
			DoMessage("PBX -> Set room status to Cleaned Vacant. Message data: " + GetDataPresentation(vFullData), MessageStatus.Information);
			vRoomNumberStr = StrReplace(Mid(vData, 6, 5), SP, ""); 
			vRoomStatusCode = Mid(vData, 4, 1);
			vRoom = GetRoomByCode(vRoomNumberStr);
			If ValueIsFilled(vRoom) Then
				vRoomStatus = GetRoomStatus(vRoomStatusCode);
				If ValueIsFilled(vRoomStatus) Then
					// Skip updating room status if it was set after phone call time
					SetRoomStatus(vRoom, vRoomStatus, vOperationTime);
				Else
					DoMessage("PBX -> ailed to get room status by code: " + GetDataPresentation(vRoomStatusCode));
				EndIf;
			Else
				DoMessage("PBX -> Failed to find room by its code: " + GetDataPresentation(vRoomNumberStr));
			EndIf;
		Else
			// Process message
			If DebugMode Then
				DoMessage("PBX -> Command received and ignored. Message data: " + GetDataPresentation(vFullData), MessageStatus.Information);
			EndIf;
		EndIf;
		EventsArr.Delete(0);
	EndDo;
EndProcedure // ProcessEventsFromPMSi

// -----------------------------------------------------------------------------
Procedure DoMainProcessingCycle()
	IsRunning = True;
	Timestamp = CurrentSessionDate();
	pmSaveDataProcessorAttributes();
	// Get all active room interface events that need to be processed
	vActiveEvents = GetActiveRoomInterfaceEvents();
	Try
		ProcessesEvents(vActiveEvents);
	Except
	EndTry;
EndProcedure // DoMainProcessingCycle

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();
TIMEOUT = 10;
EventsArr = New Array();

// -----------------------------------------------------------------------------
STX = Char(2);
ETX = Char(3);
ENQ = Char(5);
ACK = Char(6);
NAK = Char(21);
SP  = Char(32);