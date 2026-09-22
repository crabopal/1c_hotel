Var TCPIP;
Var CSWSOCK6_LICENSE_KEY;
Var CSWSOCK10_LICENSE_KEY;

// -----------------------------------------------------------------------------
Var STX;
Var ETX;

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
	If PMSiPort = 0 Then
		PMSiPort = 51000;
	EndIf;
	If IsBlankString(PMSiAddress) Then
		PMSiAddress = "172.17.1.6";
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
	If Not IsBlankString(PMSiAddress) And PMSiPort <> 0 Then
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
		TCPIP.Timeout = 10; // 10 seconds blocking read timeout by default
		vErrorCode = TCPIP.Connect(StrReplace(PMSiAddress, " ", ""), PMSiPort);
		If vErrorCode <> 0 Then
			DoMessage(NStr("ru = 'Не найден PMSi сервер: '; en = 'PMSi server was not found: '") + vErrorCode + " - " + TCPIP.LastErrorString);
			TCPIP = Undefined;
			IsRunning = False;
			StopInterface = False;
			Timestamp = Undefined;
			pmSaveDataProcessorAttributes();
			Return;
		Else
			If DebugMode Then
				DoMessage("PMS -> PMSi. Connection successfull");
			EndIf;
		EndIf;     
		vData = "";
		If TCPIP.Read(vData, 1024) <> -1 Then
			vBreak = ProcessEventsFromPMSi(vData);
			If Not vBreak Then
				DoMessage("PMSi -> PMS. Reply to CONNECT. Unexpected data received: " + GetDataPresentation(vData), MessageStatus.Attention);
				TCPIP.Disconnect();
				TCPIP = Undefined;
				IsRunning = False;
				StopInterface = False;
				Timestamp = Undefined;
				pmSaveDataProcessorAttributes();
				Return;
			EndIf;
		Else
			If DebugMode Then
				DoMessage("PMSi -> PMS. Reply to CONNECT. Data NOT received!");
			EndIf;
		EndIf;
		// Go to main processing cycle
		While DoMainProcessingCycle() Do
			pmLoadDataProcessorAttributes();
			If StopInterface Then
				Break;
			EndIf;
			#IF CLIENT THEN
				IsRunning = False;
				pmSaveDataProcessorAttributes();
				UserInterruptProcessing();
			#ENDIF
		EndDo;
		vErrorCode = TCPIP.Disconnect();
		If vErrorCode <> 0 Then
			DoMessage(NStr("ru = 'Ошибка отключения от сервера PMSi: '; en = 'PMSi server disconnect error: '") + vErrorCode, MessageStatus.Attention);
		EndIf;  
		IsRunning = False;
		StopInterface = False;
		Timestamp = Undefined;
		pmSaveDataProcessorAttributes();
	Else
		DoMessage(NStr("en='Server connection parameters are missing...'; ru='Не указаны параметры подключения к серверу PMSi...'; de='Server-Verbindung Parameter fehlen...'"));
	EndIf;
EndProcedure // pmRunInterfaceClient

// -----------------------------------------------------------------------------
Function GetDataPresentation(pData) 
	Return StrReplace(StrReplace(pData, STX, "[STX]"), ETX, "[ETX]");
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function Transliterate(pStr)
	If Not DoTransliterate Then
		Return pStr;
	EndIf;
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
		If Not IsBlankString(vPhoneNumber) Then
			vCos1 = 0;
			vCos1Str = TrimAll(Mid(TrimAll(pEventRow.TurnOnParameters), 9));
			If Not IsBlankString(vCos1Str) Then
				vCos1 = Number(vCos1Str);
			EndIf;
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) And ValueIsFilled(pEventRow.ParentDoc.Guest) Then
				vGuest = pEventRow.ParentDoc.Guest;
				vGuestName = TrimAll(TrimAll(vGuest.FirstName) + " " + TrimAll(vGuest.SecondName) + " " + TrimAll(vGuest.LastName));
				If DoTransliterate Then
					vGuestName = Left(Transliterate(vGuestName), 128);
				Else
					vGuestName = Left(vGuestName, 128);
				EndIf;
			EndIf;		
			// Build command string
			vData = STX + "FOSCHKIN" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					Format(vCos1, "ND=3; NFD=0; NZ=; NLZ=; NG=") + " " + 
					cmAppendBlanks(vGuestName, 128) + 
					ETX;
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
Function GetGNSTMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) And ValueIsFilled(pEventRow.ParentDoc.Guest) Then
				vGuest = pEventRow.ParentDoc.Guest;
				vGuestName = TrimAll(TrimAll(vGuest.FirstName) + " " + TrimAll(vGuest.SecondName) + " " + TrimAll(vGuest.LastName));
				If DoTransliterate Then
					vGuestName = Left(Transliterate(vGuestName), 128);
				Else
					vGuestName = Left(vGuestName, 128);
				EndIf;
			EndIf;		
			// Build command string
			vData = STX + "FOSGN SET" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					cmAppendBlanks(vGuestName, 128) + 
					ETX;
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
Function GetCHKOGNSTMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vGuestName = "Room " + TrimAll(pEventRow.Room);
			// Build command string
			vData = STX + "FOSGN SET" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					cmAppendBlanks(vGuestName, 128) + 
					ETX;
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
Function GetCHKOMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vCos1 = 0;
			vCos1Str = TrimAll(Mid(TrimAll(pEventRow.TurnOffParameters), 9));
			If Not IsBlankString(vCos1Str) Then
				vCos1 = Number(vCos1Str);
			EndIf;
			vData = STX + "FOSCHKOUT" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					Format(vCos1, "ND=3; NFD=0; NZ=; NLZ=; NG=") + 
					ETX;
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
Function GetSCOSMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vCos1 = 0;
			vCos1Str = TrimAll(Mid(TrimAll(pEventRow.TurnOnParameters), 9));
			If Not IsBlankString(vCos1Str) Then
				vCos1 = Number(vCos1Str);
			EndIf;
			vGuestName = "";
			If ValueIsFilled(pEventRow.ParentDoc) And ValueIsFilled(pEventRow.ParentDoc.Guest) Then
				vGuest = pEventRow.ParentDoc.Guest;
				vGuestName = TrimAll(TrimAll(vGuest.FirstName) + " " + TrimAll(vGuest.SecondName) + " " + TrimAll(vGuest.LastName));
				If DoTransliterate Then
					vGuestName = Left(Transliterate(vGuestName), 128);
				Else
					vGuestName = Left(vGuestName, 128);
				EndIf;
			EndIf;		
			// Build command string
			vData = STX + "FOSCOS" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					Format(vCos1, "ND=3; NFD=0; NZ=; NLZ=; NG=") + " " + 
					cmAppendBlanks(vGuestName, 128) + 
					ETX;
		Else
			DoMessage(NStr("en='Phone number is not specified for room '; ru='Не указан телефон для номера '; de='Telefonnummer wird nicht für die Zimmer angegeben - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
		EndIf;
	ElsIf vPhoneNumbers.Count() > 1 Then 
		DoMessage(NStr("en='More then one phone number is defined for room '; ru='У номера определено более одного телефона! Номер '; de='Mehr als eine Telefonnummer für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	Else
		DoMessage(NStr("en='No phone numbers defined for room '; ru='У номера комнаты не указан телефонный номер! Номер '; de='Keine Telefonnummern für Zimmer definiert - '") + TrimAll(pEventRow.Room), MessageStatus.Attention);
	EndIf;
	Return vData;
EndFunction // GetSCOSMessage
 
// -----------------------------------------------------------------------------
Function GetSWKUMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vFlag = 0;
			vFlagStr = TrimAll(Mid(TrimAll(pEventRow.TurnOnParameters), 10));
			vWakeUpTime = Format(pEventRow.MessageDateTime, "DF=HH:mm:ss");
			// Build command string
			vData = STX + "FOSWT SET" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
					vWakeUpTime + " " + 
					vFlagStr + 
					ETX;
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
Function GetCWKUMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			// Build command string
			vData = STX + "FOSWT CLEAR" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + 
					ETX;
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
Function GetMLONMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vCallBackExtension = Number(TrimAll(Mid(TrimAll(pEventRow.TurnOnParameters), 17)));
			// Build command string
			vData = STX + "FOSMWL ON" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
			        Format(vCallBackExtension, "ND=5; NFD=0; NZ=; NLZ=; NG=") + 
					ETX;
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
Function GetMLOFMessage(pEventRow)
	vData = "";
	vRoomsList = New ValueList();
	vRoomsList.Add(pEventRow.Room);
	vPhoneNumbers = cmGetPhoneNumbersForRooms(vRoomsList);
	If vPhoneNumbers.Count() = 1 Then
		vPhoneNumber = Number(TrimAll(vPhoneNumbers.Get(0).PhoneNumber));
		If Not IsBlankString(vPhoneNumber) Then
			vCallBackExtension = "     ";
			// Build command string
			vData = STX + "FOSMWL OFF" + " " + 
			        Format(vPhoneNumber, "ND=5; NFD=0; NZ=; NLZ=; NG=") + " " + 
			        vCallBackExtension + 
					ETX;
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
	WriteLogEvent("Panasonic.PMSi", ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Function GetMessagePart(pDataReceived, rStartPos)
	If Not IsBlankString(pDataReceived) Then
		vStartPos = rStartPos;
		If vStartPos = 0 Then
			vStartPos = 1;
		EndIf;
		vSTXPos = Find(Mid(pDataReceived, vStartPos), STX);
		vSTXPos = vSTXPos + vStartPos - 1;
		If vSTXPos > 0 Then
			vETXPos = Find(Mid(pDataReceived, vSTXPos), ETX);
			vETXPos = vETXPos + vStartPos - 1;
			If vETXPos > 0 And vETXPos > vSTXPos Then
				vMessagePart = Mid(pDataReceived, vSTXPos, (vETXPos - vSTXPos + 1));
				If vETXPos > rStartPos Then
					rStartPos = vETXPos + 1;
					If Right(vMessagePart, 1) = ETX Then
						Return vMessagePart + "@";
					Else
						Return vMessagePart;
					EndIf;
				Else
					Return "";
				EndIf;
			Else
				Return "";
			EndIf;
		Else
			Return "";
		EndIf;
	Else
		Return "";
	EndIf;
EndFunction // GetMessagePart

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
			// Build message for PMSi
			vData = GetCHKIMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSCHKIN message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSCHKIN. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckInEvents

// -----------------------------------------------------------------------------
Procedure ProcessCheckOutEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "CHKO" Then
			vSuccess = False;
			// Build check-out message for PMSi
			vData = GetCHKOMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSCHKOUT message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSCHKOUT. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Change guest name to Room XXX
			vData = GetCHKOGNSTMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSGN SET message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSGN SET. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessCheckOutEvents

// -----------------------------------------------------------------------------
Procedure ProcessSetGuestNameEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "GNST" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetGNSTMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSGN SET message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSGN SET. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessSetGuestNameEvents

// -----------------------------------------------------------------------------
Procedure ProcessSetCOSEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "SCOS" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetSCOSMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSCOS message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSCOS. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessSetCOSEvents

// -----------------------------------------------------------------------------
Procedure ProcessSetWakeUpCallEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "SWKU" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetSWKUMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSWT SET message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSWT SET. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessSetWakeUpCallEvents

// -----------------------------------------------------------------------------
Procedure ProcessClearWakeUpCallEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "CWKU" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetCWKUMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSWT CLEAR message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSWT CLEAR. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessClearWakeUpCallEvents

// -----------------------------------------------------------------------------
Procedure ProcessMessageWaitingLampOnEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And Not vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOnParameters), 4) = "MLON" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetMLONMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSMWL ON message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSMWL ON. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessMessageWaitingLampOnEvents

// -----------------------------------------------------------------------------
Procedure ProcessMessageWaitingLampOffEvents(pActiveEvents)
	For Each vEventRow In pActiveEvents Do
		If vEventRow.InterfaceType = Enums.InterfaceTypes.Phone And vEventRow.IsCanceled And Left(TrimAll(vEventRow.TurnOffParameters), 4) = "MLOF" Then
			vSuccess = False;
			// Build message for PMSi
			vData = GetMLOFMessage(vEventRow);
			If DebugMode Then
				DoMessage("PMS -> PMSi. FOSMWL OFF message. Data going to be written: " + GetDataPresentation(vData));
			EndIf;
			If TCPIP.Write(vData, StrLen(vData)) = -1 Then
				DoMessage("PMS -> PMSi. Send FOSMWL OFF. Data NOT written!", MessageStatus.Attention);
				Raise TCPIP.LastErrorString;
			Else
				vSuccess = True;
			EndIf;
			// Set processed status to the interface record
			If vSuccess Then
				vStsObj = vEventRow.Ref.GetObject();
				vStsObj.IsProcessed = True;
				vStsObj.Write(DocumentWriteMode.Write);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessMessageWaitingLampOffEvents

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
Procedure SetRoomStatus(pData, pRoomStatus)
	vExtension = TrimAll(Mid(pData, 12, 5));
	// Try to find phone number by extension number
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref,
	|	PhoneNumbers.Room
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	NOT PhoneNumbers.DeletionMark
	|	AND NOT PhoneNumbers.IsFolder
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|
	|ORDER BY
	|	PhoneNumbers.Room.SortCode,
	|	PhoneNumbers.SortCode,
	|	PhoneNumbers.Code";
	vQry.SetParameter("qPhoneNumber", vExtension);
	vPhoneNumbers = vQry.Execute().Unload();
	If vPhoneNumbers.Count() = 0 Then
		DoMessage(NStr("en='Phone number is not found for extension code '; ru='Не найден номер телефона по extension коду '; de='Telefonnummer ist nicht für Extension Code gefunden - '") + TrimAll(vExtension), MessageStatus.Attention);
	ElsIf vPhoneNumbers.Count() > 1 Then
		DoMessage(NStr("en='Multiple phone numbers are found for extension code '; ru='Несколько номеров телефонов найдено по extension коду '; de='Mehrere Telefonnummern für Extension Code gefunden - '") + TrimAll(vExtension), MessageStatus.Attention);
	Else
		vPhoneNumbersRow = vPhoneNumbers.Get(0);
		vPhoneNumber = vPhoneNumbersRow.Ref;
		vRoom = vPhoneNumbersRow.Room;
		If ValueIsFilled(vRoom) Then
			// Skip updating status if it is equal to the new one
			If vRoom.RoomStatus <> pRoomStatus Then
				// Update room status
				vRoomObj = vRoom.GetObject();
				vRoomObj.RoomStatus = pRoomStatus;
				vRoomObj.Write();
				// Get employee code
				vEmployee = Undefined;
				vEmpCodeStr = TrimAll(Mid(pData, 17));
				If Not IsBlankString(vEmpCodeStr) And cmIsNumber(vEmpCodeStr) Then
					vPBXAccountCode = Number(vEmpCodeStr);
					vEmployee = GetEmployee(vPBXAccountCode);
				EndIf;
				// Add record to the room status change history
				vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "PBX -> PMS");
			EndIf;
		Else
			DoMessage(NStr("en='Room is empty for phone number '; ru='Не указан номер комнаты у телефона '; de='Zimmer ist leer für Telefonnummer - '") + TrimAll(vPhoneNumber), MessageStatus.Attention);
		EndIf;
	EndIf;
EndProcedure // SetRoomStatus

// -----------------------------------------------------------------------------
Procedure SetGatherDigitsRoomStatus(pData)
	vExtension = TrimAll(Mid(pData, 8, 5));
	// Try to find phone number by extension number
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref,
	|	PhoneNumbers.Room
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	NOT PhoneNumbers.DeletionMark
	|	AND NOT PhoneNumbers.IsFolder
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|
	|ORDER BY
	|	PhoneNumbers.Room.SortCode,
	|	PhoneNumbers.SortCode,
	|	PhoneNumbers.Code";
	vQry.SetParameter("qPhoneNumber", vExtension);
	vPhoneNumbers = vQry.Execute().Unload();
	If vPhoneNumbers.Count() = 0 Then
		DoMessage(NStr("en='Phone number is not found for extension code '; ru='Не найден номер телефона по extension коду '; de='Telefonnummer ist nicht für Extension Code gefunden - '") + TrimAll(vExtension), MessageStatus.Attention);
	ElsIf vPhoneNumbers.Count() > 1 Then
		DoMessage(NStr("en='Multiple phone numbers are found for extension code '; ru='Несколько номеров телефонов найдено по extension коду '; de='Mehrere Telefonnummern für Extension Code gefunden - '") + TrimAll(vExtension), MessageStatus.Attention);
	Else
		vPhoneNumbersRow = vPhoneNumbers.Get(0);
		vPhoneNumber = vPhoneNumbersRow.Ref;
		vRoom = vPhoneNumbersRow.Room;
		If ValueIsFilled(vRoom) Then
			// Read employee code from the data received
			vDigits = TrimAll(Mid(pData, 14, 3));
			// Get employee
			vEmployee = GetEmployee(Number(vDigits));
			// Get current room status 
			vCurrentRoomStatus = vRoom.RoomStatus;
			// Skip updating status if it is equal to the new one
			If ValueIsFilled(vCurrentRoomStatus.NextRoomStatus) Then
				// Update room status
				vRoomObj = vRoom.GetObject();
				vRoomObj.RoomStatus = vCurrentRoomStatus.NextRoomStatus;
				vRoomObj.Write();
				// Add record to the room status change history
				vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "PBX -> PMS");
			EndIf;
			// Process start operation and end operation
			If ValueIsFilled(vEmployee) And ValueIsFilled(vCurrentRoomStatus) And ValueIsFilled(vCurrentRoomStatus.Operation) Then
				vOperation = vCurrentRoomStatus.Operation;
				// Try to find pending employee operation
				vEmpOpRef = cmGetPendingEmployeeOperation(vEmployee, vOperation, CurrentSessionDate(), vRoom);
				If Not ValueIsFilled(vEmpOpRef) Then
					// Add operation start record
					WriteStartOfOperation(vEmployee, vOperation, vRoom);
				Else
					// End operation
					WriteEndOfOperation(vEmpOpRef);
					// Maid moved to another room and forgot to finish operation in previous room.
					If vEmpOpRef.Room <> vRoom Or vEmpOpRef.Operation <> vOperation Or (CurrentSessionDate() - vEmpOpRef.OperationStartTime)/(12*3600) > 12 Then
						WriteStartOfOperation(vEmployee, vOperation, vRoom);
					EndIf;
				EndIf;
			EndIf;
		Else
			DoMessage(NStr("en='Room is empty for phone number '; ru='Не указан номер комнаты у телефона '; de='Zimmer ist leer für Telefonnummer - '") + TrimAll(vPhoneNumber), MessageStatus.Attention);
		EndIf;
	EndIf;
EndProcedure // SetGatherDigitsRoomStatus

// -----------------------------------------------------------------------------
Procedure WriteEndOfOperation(pEmpOpRef)
	Try
		// Update employee operation document
		vEmpOpObj = pEmpOpRef.GetObject();
		// Fill operation end time and duration
		vEmpOpObj.OperationEndTime = CurrentSessionDate();
		vEmpOpObj.Duration = vEmpOpObj.pmGetOperationDuration();
		// Post document
		vEmpOpObj.Write(DocumentWriteMode.Posting);
	Except
		DoMessage(NStr("en='Failed to write end of employee operation! Error description: ';ru='Не удалось записать конец работы сотрудника! Описание ошибки: ';de='Das Ender der Arbeitszeit des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '") + ErrorDescription(), MessageStatus.Attention);
	EndTry;
EndProcedure // WriteEndOfOperation

// -----------------------------------------------------------------------------
Procedure WriteStartOfOperation(pEmployee, pOperation, pRoom)
	Try
		// Check if there is such operation already. Skip loading if found
		vEmpOperations = cmGetEmployeeOperation(pEmployee, pOperation, CurrentSessionDate());
		If vEmpOperations.Count() = 0 Then
			// Create new employee operation document
			vEmpOpObj = Documents.EmployeeOperation.CreateDocument();
			vEmpOpObj.SetTime(AutoTimeMode.CurrentOrLast);
			vEmpOpObj.Hotel = pRoom.Owner;
			vEmpOpObj.pmFillAttributesWithDefaultValues();
			// Fill employee and operation
			vEmpOpObj.Employee = pEmployee;
			vEmpOpObj.Operation = pOperation;
			vEmpOpObj.Room = pRoom;
			vEmpOpObj.OperationStartTime = CurrentSessionDate();
			// Retrieve room resources
			vRoomAttrs = vEmpOpObj.Room.GetObject().pmGetRoomAttributes(vEmpOpObj.OperationStartTime);
			For Each vRoomAttrsRow In vRoomAttrs Do
				vEmpOpObj.RoomType = vRoomAttrsRow.RoomType;
				Break;
			EndDo;
			// Get number of persons in the room for the operation start date
			vEmpOpObj.NumberOfPersons = vEmpOpObj.pmGetNumberOfPersons();
			// Fill operation start and end PBX codes
			vEmpOpObj.pmFillPBXCodes();
			// Get operation room space
			vStds = Catalogs.Operations.GetOperationStandards(vEmpOpObj.Operation, vEmpOpObj.Hotel, vEmpOpObj.RoomType, vEmpOpObj.Room, vEmpOpObj.Employee);
			If vStds.Count() > 0 then
				vStdsRow = vStds.Get(0);
				vEmpOpObj.RoomSpace = vStdsRow.RoomSpace;
				vEmpOpObj.Price = vStdsRow.Price;
			EndIf;
			// Fill operation articles consumption standards table
			vEmpOpObj.Articles.Clear();
			vEmpOpObj.pmFillArticles();
			// Fill remarks with call data
			vEmpOpObj.Remarks = "PBX -> PMS";
			// Post document
			vEmpOpObj.Write(DocumentWriteMode.Posting);
		EndIf;
	Except
		DoMessage(NStr("en='Failed to write start of employee operation! Error description: ';ru='Не удалось записать начало работы сотрудника! Описание ошибки: ';de='Der Arbeitsbeginn des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '") + ErrorDescription(), MessageStatus.Attention);
	EndTry;
EndProcedure // WriteStartOfOperation

// -----------------------------------------------------------------------------
Function ProcessEventsFromPMSi(pDataReceived)
	vReturn = True;
	If DebugMode Then
		DoMessage("PMSi -> PMS. Data received: " + GetDataPresentation(pDataReceived));
	EndIf;
	// Get message part
	rStartPos = 0;
	vSavStartPos = 0;
	vData = GetMessagePart(pDataReceived, rStartPos);
	While Not IsBlankString(vData) Do
		If DebugMode Then
			DoMessage("PMSi -> PMS. Message parsed from pos " + vSavStartPos + ": " + GetDataPresentation(vData));
		EndIf;
		vSavStartPos = rStartPos;
		If Find(vData, "PBXRCLNDV") > 0 Then
			// Change room status to Cleaned Vacant
			DoMessage("PMSi -> PMS. Set room status to Cleaned Vacant. Message data: " + GetDataPresentation(vData), MessageStatus.Information);
			SetRoomStatus(vData, Hotel.VacantRoomStatus);
		ElsIf Find(vData, "PBXRCLNDO") > 0 Then
			// Change room status to Cleaned Occupied
			DoMessage("PMSi -> PMS. Set room status to Cleaned Occupied. Message data: " + GetDataPresentation(vData), MessageStatus.Information);
			SetRoomStatus(vData, Hotel.OccupiedRoomStatus);
		ElsIf Find(vData, "PBXRWTINS") > 0 Then
			// Change room status to Inspection
			If ValueIsFilled(Hotel.RoomStatusInspection) Then
				DoMessage("PMSi -> PMS. Set room status to Inspection. Message data: " + GetDataPresentation(vData), MessageStatus.Information);
				SetRoomStatus(vData, Hotel.RoomStatusInspection);
			Else
				DoMessage("PMSi -> PMS. Set room status to Inspection but no Inspection status is defined! Message data: " + GetDataPresentation(vData), MessageStatus.Attention);
			EndIf;
		ElsIf Find(vData, "PBXGD ") > 0 Then
			DoMessage("PMSi -> PMS. Gather digits found! Message data: " + GetDataPresentation(vData), MessageStatus.Attention);
			SetGatherDigitsRoomStatus(vData);
		ElsIf Find(vData, "Welcome to the 1CHotel") > 0 Then
			DoMessage("PMSi -> PMS. Welcome to the PMSi.", MessageStatus.Information);
		ElsIf Find(vData, "PMSi is working") > 0 Then
			DoMessage("PMSi -> PMS. Connection is active.", MessageStatus.Information);
		Else
			// Process message
			If DebugMode Then
				DoMessage("PMSi -> PMS. Command received and ignored. Message data: " + GetDataPresentation(vData), MessageStatus.Information);
			EndIf;
		EndIf;
		// Get next message part
		vData = GetMessagePart(pDataReceived, rStartPos);
	EndDo;
	Return vReturn;
EndFunction // ProcessEventsFromPMSi

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
	vActiveEvents = GetActiveRoomInterfaceEvents();
	Try
		// Process check-in events
		ProcessCheckInEvents(vActiveEvents);
		// Process check-out events
		ProcessCheckOutEvents(vActiveEvents);
		// Process set guest names
		ProcessSetGuestNameEvents(vActiveEvents);
		// Process set COS events
		ProcessSetCOSEvents(vActiveEvents);
		// Process set wake-up call events
		ProcessSetWakeUpCallEvents(vActiveEvents);
		// Process clear wake-up call events
		ProcessClearWakeUpCallEvents(vActiveEvents);
		// Process message waiting lamp on events
		ProcessMessageWaitingLampOnEvents(vActiveEvents);
		// Process message waiting lamp off events
		ProcessMessageWaitingLampOffEvents(vActiveEvents);
	Except
		Return False;
	EndTry;
	// Read events from PMSi
	vData = "";
	If TCPIP.Read(vData, 1024) <> -1 Then
		If IsBlankString(vData) Then
			vReturn = False;
		Else
			vReturn = ProcessEventsFromPMSi(vData);
		EndIf;
	EndIf;
	Return vReturn;
EndFunction // DoMainProcessingCycle

// -----------------------------------------------------------------------------
CSWSOCK6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSWSOCK10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey();

// -----------------------------------------------------------------------------
STX = Char(2);
ETX = Char(3);

// -----------------------------------------------------------------------------
ActiveGuestMessages = New ValueList();
