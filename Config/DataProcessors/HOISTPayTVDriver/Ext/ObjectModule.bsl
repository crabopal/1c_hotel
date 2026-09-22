Var ENQ;
Var STX;
Var ETX;
Var EOT;
Var NAK;
Var ACK;

Var RC_NO_CONNECTION;
Var RC_OK;

// -----------------------------------------------------------------------------
Var SystemName;

// -----------------------------------------------------------------------------
Function BCC(pStr)
	#IF CLIENT THEN
		Return cmCharLRC(pStr, False);
	#ELSE
		Return cmCharLRC(pStr);
	#ENDIF
EndFunction // BCC

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
	tcCommonFunctionOnClientServer.TextMessage(""+CurrentSessionDate()+" "+SystemName+": "+pErrorText);
	WriteLogEvent(NStr("en='Interface.HOIST'; de='Interface.HOIST'; ru='Интерфейс.HOIST'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure // AddError

// -----------------------------------------------------------------------------
Function pmConnect() Export
	// Fill system name
	SystemName = "HOIST";
	Try
		// Check connection parameters
		If IsBlankString(Port) Then
			Return Undefined;
		EndIf;
		If IsBlankString(InitString) Then
			InitString = "9600,N,8,1";
		EndIf;
		// Build ActiveX object to work with
		vDLSys = New COMObject("SPort.SPortAx.1");
		// Set connection parameters
		vDLSys.InitString(TrimAll(InitString));
		// Open COM port
		vIsOpen = vDLSys.Open(TrimAll(Port));
		If Not vIsOpen Then
			AddError(NStr("en='Failed to open port: ';ru='Не удалось открыть порт: ';de='Der Port konnte nicht geöffnet werden: '") + TrimAll(Port));
			Return Undefined;
		EndIf;
		// Set block mode
		vDLSys.BlockMode = False;
		// Setup timeouts
		vDLSys.TimeoutReadInterval = 100;
		vDLSys.TimeoutReadTotalConstant = 300;
		vDLSys.TimeoutReadTotalMultiplier = 100;
		vDLSys.TimeoutWriteTotalConstant = 300;
		vDLSys.TimeoutWriteTotalMultiplier = 100;
	Except
		AddError(NStr("ru = 'Ошибка подключения системы " + SystemName + ": '; en = '" + SystemName + " system connection error: '; de = '" + SystemName + " system connection error: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vDLSys;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pDLSys) Export
	Try
		If pDLSys <> Undefined Then
			pDLSys.Close();
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка отключения от системы " + SystemName + ": '; en = '" + SystemName + " disconnect error: '; de = '" + SystemName + " disconnect error: '") + ErrorDescription());
	EndTry;
	pDLSys = Undefined;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function ClearStr(pStr)
	s = pStr;
	s = StrReplace(s,ACK,"{ACK}");	
	s = StrReplace(s,STX,"{STX}");
	s = StrReplace(s,ETX,"{ETX}");
	s = StrReplace(s,EOT,"{EOT}");
	s = StrReplace(s,ENQ,"{ENQ}");
	s = StrReplace(s,NAK,"{NAK}");
	Return s;
EndFunction // ClearStr

// -----------------------------------------------------------------------------
Procedure WriteLogText(pText)
	If StrLen(pText) < 9 Then
		Return;
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage(""+CurrentSessionDate()+" "+SystemName+": "+ClearStr(pText));		
EndProcedure // WriteLogText

// -----------------------------------------------------------------------------
Procedure WaitABit()
	vStartTime = CurrentSessionDate();
	vProbeTime = vStartTime;
	While (vProbeTime - vStartTime) = 0 Do
		vProbeTime = CurrentSessionDate();
	EndDo;
EndProcedure // WaitABit

// -----------------------------------------------------------------------------
Function CallRS232Command(RS232, pCmd, rMessage, pSendENQ = True)
	vErrorCode = RC_OK;
	vReply = "";
	// Wait 1 second to avoid RS232 buffer overflow
	WaitABit();
	// Add data block control characters
	vCmd = STX + pCmd + ETX + BCC(pCmd+ETX); 
	// Send command and get reply
	vReadOK = False;
	If pSendENQ Then
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Send {ENQ} to initiate connection
		vBytesSent = RS232.WriteStr(ENQ);
		WriteLogText("Write: "+ClearStr(ENQ));
		If vBytesSent > 0 Then
			// Wait 1 second to avoid RS232 buffer overflow
			WaitABit();
			// Read reply
			vReply = RS232.ReadStr();
			WriteLogText("Reply: "+ClearStr(vReply));
		Else
			rMessage = NStr("en='Failed to send {ENQ}!'; de='Failed to send {ENQ}!'; ru='Не удалось отправить {ENQ}!'");
			Return RC_NO_CONNECTION;
		EndIf;
		If vReply <> ACK Then
			rMessage = NStr("en='Wrong reply to the connection request. {ACK} was expected!'; de='Wrong reply to the connection request. {ACK} was expected!'; ru='Неверный ответ на запрос на соединение. Ожидал {ACK}!'");
		EndIf;
    EndIf;
	// Wait 1 second to avoid RS232 buffer overflow
	WaitABit();
	// Write command
	vBytesSent = RS232.WriteStr(vCmd);
	WriteLogText("Write: "+ClearStr(vCmd));
	If vBytesSent > 0 Then
		vData = 0;
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Read reply
		vReply = RS232.ReadStr();
		WriteLogText("Reply: "+ClearStr(vReply));
		If vReply = ACK Then
			vErrorCode = RC_OK;
		Else
			vErrorCode = vReply;
		EndIF;
	EndIf;
	rMessage = vErrorCode;
	Return vErrorCode;
EndFunction // CallRS232Command

// -----------------------------------------------------------------------------
Function pmCheckIn(pTVConnection, pRoomInterfaceDoc, pFlags, rMessage) Export
	vErrorCode = RC_OK;
	If Not ValueIsFilled(pRoomInterfaceDoc) Then
		Return False;
	EndIf;	
	Try	
		// Call API
		//   Date      RoomRefNo  Guest             DateOut   Flags    Lang
		//                                                    1234567 
		// 2129.10.199301230022143Katrin Hofmeister 30.10.19930111101#E0
		If ValueIsFilled(pRoomInterfaceDoc.ParentDoc) Then
			vCheckInDate = pRoomInterfaceDoc.ParentDoc.CheckInDate;
			vCheckOutDate = pRoomInterfaceDoc.ParentDoc.CheckOutDate;
			vGuest = pRoomInterfaceDoc.ParentDoc.Guest;
			vRefNo = Right(pRoomInterfaceDoc.ParentDoc.Number,7);
		Else
			vCheckInDate = pRoomInterfaceDoc.Date;
			vCheckOutDate = EndOfDay(vCheckInDate);
			vGuest = Catalogs.Clients.EmptyRef();
			vRefNo = Right(pRoomInterfaceDoc.Number,7);
		EndIf;
		
		vCmd = "21"; //command code, 21 = CheckIn
		vCmd = vCmd + Format(vCheckInDate,"DF=dd.MM.yyyy"); //Check-in date
		vRoomNumber = cmAppendLeftBlanks(TrimAll(pRoomInterfaceDoc.Room.Description),4);
		vCmd = vCmd + vRoomNumber; //Room
		vCmd = vCmd + vRefNo; //Reference number
		
		vGuestName = ?(ValueIsFilled(vGuest),Left(vGuest.FullName,40),"");
		vGuestName = Transliterate(vGuestName);
		vCmd = vCmd + cmAppendBlanks(vGuestName,40); //Guest
		vCmd = vCmd + Format(vCheckOutDate,"DF=dd.MM.yyyy"); //Check out date
		vCmd = vCmd + pFlags;
		//vCmd = vCmd + "0"; //Flag1 - permit express checkout
		//vCmd = vCmd + "0"; //Flag2 - permit to view bill 
		//vCmd = vCmd + "1"; //Flag3 - TV programm 
		//vCmd = vCmd + "1"; //Flag4 - standart video 
		//vCmd = vCmd + "1"; //Flag5 - adult video 
		//vCmd = vCmd + "0"; //Flag6 - seminar group video 0..F 
		//vCmd = vCmd + "0"; //Flag7 - switch-on TV 
		vCmd = vCmd + "#E";
		vCmd = vCmd + "3";//Language 0 - German,1 - English, 2 - Swedish, 3 - Italian, 4 - French
		// Send command
		vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage);
		If vErrorCode <> RC_OK Then
			rMessage = rMessage+Chars.CR+NStr("en='Error '; de='Error '; ru='Ошибка '")+vErrorCode;
			Return False;
		EndIf;
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Write end of transmission char
	 	vBytesSent = pTVConnection.WriteStr(EOT);
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды CheckIn " + SystemName + ": '; en = '" + SystemName + " system CheckIn command error: '; de = '" + SystemName + " system CheckIn command error: '") + ErrorDescription());
		Return false;
	EndTry;
	Return True;
EndFunction // pmCheckIn

// -----------------------------------------------------------------------------
Function pmUpdateCheckIn(pTVConnection, pRoomInterfaceDoc, pFlags, rMessage) Export
	vErrorCode = RC_OK;
	If Not ValueIsFilled(pRoomInterfaceDoc) Then
		Return False;
	EndIf;	
	Try	
		// Call API
		//   Date      RoomRefNo  Guest             DateOut   Flags    Lang
		//                                                    1234567 
		// 3129.10.199301230022143Katrin Hofmeister 30.10.19930111101#E0
		If ValueIsFilled(pRoomInterfaceDoc.ParentDoc) Then
			vCheckInDate = pRoomInterfaceDoc.ParentDoc.CheckInDate;
			vCheckOutDate = pRoomInterfaceDoc.ParentDoc.CheckOutDate;
			vGuest = pRoomInterfaceDoc.ParentDoc.Guest;
			vRefNo = Right(pRoomInterfaceDoc.ParentDoc.Number,7);
		Else
			vCheckInDate = pRoomInterfaceDoc.Date;
			vCheckOutDate = EndOfDay(vCheckInDate);
			vGuest = Catalogs.Clients.EmptyRef();
			vRefNo = Right(pRoomInterfaceDoc.Number,7);
		EndIf;
		
		vCmd = "31"; //command code, 21 = CheckIn
		vCmd = vCmd + Format(vCheckInDate,"DF=dd.MM.yyyy"); //Check-in date
		vRoomNumber = Number(pRoomInterfaceDoc.Room.Description);
		vCmd = vCmd + Format(vRoomNumber,"ND=4; NGS=; NLZ=; NG="); //Room
		vCmd = vCmd + vRefNo; //Reference number
		
		vGuestName = ?(ValueIsFilled(vGuest),Left(Transliterate(vGuest.FullName),40),"");
		vCmd = vCmd + cmAppendBlanks(vGuestName,40); //Guest
		vCmd = vCmd + Format(vCheckOutDate,"DF=dd.MM.yyyy"); //Check-out date
		vCmd = vCmd + pFlags;
		//vCmd = vCmd + "0"; //Flag1 - permit express checkout
		//vCmd = vCmd + "0"; //Flag2 - permit to view bill 
		//vCmd = vCmd + "1"; //Flag3 - TV programm 
		//vCmd = vCmd + "1"; //Flag4 - standart video 
		//vCmd = vCmd + "1"; //Flag5 - adult video 
		//vCmd = vCmd + "0"; //Flag6 - seminar group video 0..F 
		//vCmd = vCmd + "0"; //Flag7 - switch-on TV 
		vCmd = vCmd + "#E";
		vCmd = vCmd + "3"; //Language 0 - German,1 - English, 2 - Swedish, 3 - Italian, 4 - French
		// Send command
		vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage);
		If vErrorCode <> RC_OK Then
			rMessage = rMessage+Chars.CR+NStr("en='Error '; de='Error '; ru='Ошибка '")+vErrorCode;
			Return False;
		EndIf;
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды UpdateCheckIn " + SystemName + ": '; en = '" + SystemName + " system UpdateCheckIn command error: '; de = '" + SystemName + " system UpdateCheckIn command error: '") + ErrorDescription());
		Return False;
	EndTry;
	Return True;
EndFunction // pmUpdateCheckIn

// -----------------------------------------------------------------------------
Function pmCheckOut(pTVConnection, pRoomInterfaceDoc, rMessage) Export
	vErrorCode = RC_OK;
	If Not ValueIsFilled(pRoomInterfaceDoc) Then
		Return False;
	EndIf;	
	Try	
		// Call API
		//   Date
		// 1230.10.199301270022143
		vCmd = "12"; //Command code
		vCmd = vCmd + Format(pRoomInterfaceDoc.Date,"DF=dd.MM.yyyy"); //Check-out date
		vRoomNumber = Number(pRoomInterfaceDoc.Room.Description);
		vCmd = vCmd + Format(vRoomNumber,"ND=4; NGS=; NLZ=; NG="); //Room
		vRefNo = Right(pRoomInterfaceDoc.Number,7);
		vCmd = vCmd + vRefNo; //Reference number
		// Send command
		vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage);
		If vErrorCode <> RC_OK Then
			rMessage = NStr("en='Error '; de='Error '; ru='Ошибка '")+vErrorCode;
			Return False;
		EndIf;
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Write end of transmission char
	 	vBytesSent = pTVConnection.WriteStr(EOT);
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды CheckOut " + SystemName + ": '; en = '" + SystemName + " system CheckOut command error: '; de = '" + SystemName + " system CheckOut command error: '") + ErrorDescription());
		Return false;
	EndTry;
	Return True;
EndFunction // pmCheckOut

// -----------------------------------------------------------------------------
Function pmSetWakeUp(pTVConnection, pRoomInterfaceDoc, vCommand, rMessage)
	Try	
		// Call API
		// 1830.10.1993012707:15
		vCmd = "18"; //Command code, 18 = WakeUp
		vCmd = vCmd + Format(pRoomInterfaceDoc.MessageDateTime,"DF=dd.MM.yyyy"); //Wake up date
		vRoomNumber = Number(pRoomInterfaceDoc.Room.Description);
		vCmd = vCmd + Format(vRoomNumber,"ND=4; NGS=; NLZ=; NG="); //Room
		vCmd = vCmd + Format(pRoomInterfaceDoc.MessageDateTime,"DF=HH:mm"); //Wake up time
		// Send command
		vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage);
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды SetWakeUp " + SystemName + ": '; en = '" + SystemName + " system SetWakeUp command error: '; de = '" + SystemName + " system SetWakeUp command error: '") + ErrorDescription());
		Return False;
	EndTry;
	If vErrorCode <> RC_OK Then
		Return False;
	EndIf;
	Return True;
EndFunction // pmSetWakeUp

// -----------------------------------------------------------------------------
Function pmMessage(pTVConnection, pReply) Export
	Try
		// Call API
		// 2429.10.19930127002214315:20:08 Message text up to 34 chars
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Write acknowledgement char
		pTVConnection.WriteStr(ACK);
		pRoom = Format(Number(Mid(pReply,3,4)),"ND=4; NGS=; NG=");
		pRefNo = Mid(pReply,7,7);
		// Retrieve all messages that should be send to the HOIST
		vQ = New Query;
		vQ.Text = "SELECT
		          |	RoomInterfaceStatus.Ref,
		          |	RoomInterfaceStatus.ParentDoc,
		          |	RoomInterfaceStatus.Room,
		          |	RoomInterfaceStatus.Remarks,
		          |	RoomInterfaceStatus.Room.Description,
		          |	RoomInterfaceStatus.Date,
		          |	RoomInterfaceStatus.MessageDateTime
		          |FROM
		          |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
		          |WHERE
		          |	(NOT RoomInterfaceStatus.DeletionMark)
		          |	AND RoomInterfaceStatus.Room.Description = &qRoom
		          |	AND RoomInterfaceStatus.IsProcessed
		          |	AND RoomInterfaceStatus.ParentDoc.Number LIKE &qRefNo";
		vQ.SetParameter("qRoom", pRoom);
		vQ.SetParameter("qRefNo", "%"+pRefNo);
		vTMsg = vQ.Execute().Unload();
		If vTMsg.Count() = 0 Then
			Return True;
		EndIf;
		// Process all messages retreived
		For Each msg In vTMsg Do
			pText = TrimAll(msg.Remarks);
			vRoomNumber = Number(msg.RoomDescription);
			pRoom = Format(vRoomNumber,"ND=4; NGS=; NLZ=; NG="); //Room
			If ValueIsFilled(msg.MessageDateTime) Then
				pDate = Format(msg.MessageDateTime,"DF=dd.MM.yyyy");
				pTime = Format(msg.MessageDateTime,"DF=HH:mm:ss");
			Else
				pDate = Format(CurrentSessionDate(),"DF=dd.MM.yyyy");
				pTime = Format(CurrentSessionDate(),"DF=HH:mm:ss");
			EndIf;
			vMessageLen = StrLen(pText);
			
			// Try to connect to the system and prepare to send messages
			WaitABit();
			vBytesSent = pTVConnection.WriteStr(ENQ);
			WriteLogText("Write: "+ClearStr(ENQ));
			If vBytesSent > 0 Then
				WaitABit();
				vReply = pTVConnection.ReadStr();
				WriteLogText("Reply: "+ClearStr(vReply));
			Else
				rMessage = NStr("en='Failed to send {ENQ}!'; de='Failed to send {ENQ}!'; ru='Не удалось отправить {ENQ}!'");
				Return RC_NO_CONNECTION;
			EndIf;
			If vReply <> ACK Then
				rMessage = NStr("en='Wrong reply to the connection request. {ACK} was expected!'; de='Wrong reply to the connection request. {ACK} was expected!'; ru='Неверный ответ на запрос на соединение. Ожидал {ACK}!'");
			EndIF;
			
			While vMessageLen > 0 Do
				If vMessageLen > 34 Then
					vMessage = Left(pText,34);
					pText = Mid(pText,35);
					vMessageLen = StrLen(pText);
					
					vCmd = "24"; //command code, 24 = message block record
					vCmd = vCmd + pDate; //message date
					vCmd = vCmd + pRoom;
					vCmd = vCmd + pRefNo; //reference number
					vCmd = vCmd + pTime; //message time
					vCmd = vCmd + vMessage; //message	
					
					vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage, False);
				Else
					vMessageLen = 0;
					vMessage = pText;
					
					vCmd = "34"; //command code, 34 = message end record
					vCmd = vCmd + pDate; //message date
					vCmd = vCmd + pRoom; //room
					vCmd = vCmd + pRefNo; //reference number
					vCmd = vCmd + pTime; //message time
					vCmd = vCmd + vMessage; //message	
					
					vErrorCode = CallRS232Command(pTVConnection, vCmd, rMessage, False);
				EndIF;
			EndDo;
		EndDo;
		// Wait 1 second to avoid RS232 buffer overflow
		WaitABit();
		// Write end of transmission char
	 	vBytesSent = pTVConnection.WriteStr(EOT);
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды Message " + SystemName + ": '; en = '" + SystemName + " system Message command error: '; de = '" + SystemName + " system Message command error: '") + ErrorDescription());
		Return False;	
	EndTry;
	If vErrorCode <> RC_OK Then
		Return False;
	EndIF;
	Return True;
EndFunction // pmMessage

// -----------------------------------------------------------------------------
Function pmPrepareMessage(pTVConnection, pRoomInterfaceDoc, pCommand, rMessage) Export
	Try
		If Not ValueIsFilled(pRoomInterfaceDoc) Then
			Return False;
		EndIf;
		
		// Call API
		// 2429.10.19930127002214315:20:08 Message text up to 34
		pText = TrimAll(pRoomInterfaceDoc.Remarks);
		vRoomNumber = Number(pRoomInterfaceDoc.Room.Description);
		
		pRoom = Format(vRoomNumber,"ND=4; NGS=; NLZ=; NG="); //room
		
		pDate = Format(pRoomInterfaceDoc.Date,"DF=dd.MM.yyyy");
		pTime = Format(pRoomInterfaceDoc.Date,"DF=HH:mm:ss");
		vMessageLen = StrLen(pText);
		pRefNo = "0000000";
		If ValueIsFilled(pRoomInterfaceDoc.ParentDoc) Then
			vRefNo = Right(pRoomInterfaceDoc.ParentDoc.Number,7);
		EndIf;
		
		// Try to connect to the system and prepare to send messages
		WaitABit();
		vBytesSent = pTVConnection.WriteStr(ENQ);
		WriteLogText("Write: "+ClearStr(ENQ));
		If vBytesSent > 0 Then
			WaitABit();
			vReply = pTVConnection.ReadStr();
			WriteLogText("Reply: "+ClearStr(vReply));
		Else
			rMessage = NStr("en='Failed to send {ENQ}!'; de='Failed to send {ENQ}!'; ru='Не удалось отправить {ENQ}!'");
			Return RC_NO_CONNECTION;
		EndIf;
		If vReply <> ACK Then
			rMessage = NStr("en='Wrong reply to the connection request. {ACK} was expected!'; de='Wrong reply to the connection request. {ACK} was expected!'; ru='Неверный ответ на запрос на соединение. Ожидал {ACK}!'");
		EndIF;
		
		vCmd = "14"+pRoom+vRefNo;
		vSendCmd = STX + vCmd + ETX + BCC(vCmd+ETX);
		WaitABit();
		vBytesSent = pTVConnection.WriteStr(vSendCmd);
		WriteLogText("Write: "+ClearStr(vSendCmd));
		WaitABit();
		vReply = pTVConnection.ReadStr();
		WriteLogText("Reply: "+ClearStr(vReply));
		
		If vReply = ACK Then
			Return True;
		EndIf;	
	Except
		AddError(NStr("ru = 'Ошибка выполнения команды PrepareMessage " + SystemName + ": '; en = '" + SystemName + " system PrepareMessage command error: '; de = '" + SystemName + " system PrepareMessage command error: '") + ErrorDescription());
		Return False;	
	EndTry;
	Return False;
EndFunction // pmMessage

// -----------------------------------------------------------------------------
Function pmExpressWakeUp() Export
	Return False;
EndFunction // pmExpressWakeUp

// -----------------------------------------------------------------------------
Function pmShowBill() Export
	Return False;
EndFunction // pmShowBill

// -----------------------------------------------------------------------------
Function pmChargeService() Export
	Return False;
EndFunction // pmChargeService

// -----------------------------------------------------------------------------
Function GetDate(pDate,pTime)
	If IsBlankString(pDate) Then
		Return CurrentSessionDate();
	EndIf;
	//01.01.2010 14:20
	Return Date(Number(Mid(pDate,7,4)),Number(Mid(pDate,4,2)),Number(Mid(pDate,1,2)),Number(Mid(pTime,1,2)),Number(Mid(pTime,4,2)),0);
EndFunction // GetDate

// -----------------------------------------------------------------------------
Function GetRoom(pRoom,pHotel)
	vRoomDesc = Format(Number(pRoom),"ND=12; NGS=; NG=");
	Return Catalogs.Rooms.FindByDescription(vRoomDesc,true,,pHotel);	
EndFunction // GetRoom

// -----------------------------------------------------------------------------
Function GetService(pChannel,pHotel)
	vSrv = cmGetObjectRefByExternalSystemCode(pHotel, "HOIST", "Services", pChannel);
	If NOT ValueIsFilled(vSrv) Then
		vSrv = Catalogs.Services.FindByCode("430");
	EndIf;
	Return vSrv;
EndFunction // GetService

// -----------------------------------------------------------------------------
Function GetSum(pSum)
	If IsBlankString(pSum) Then
		Return 0;
	EndIf;
	pos = Find(pSum,".");
	vDecimal = 0;
	If pos >0 Then
		vMain    = Number(Left(pSum,pos-1)); 
		vDecimal = Number(Right(pSum,StrLen(pSum)-pos));
	EndIf;
	Return (vMain*100+vDecimal)/100;	
EndFunction // GetSum

// -----------------------------------------------------------------------------
Function GetServiceCurrency(pService, pHotel, pDate)
	If Not ValueIsFilled(pService) Then
		Return pHotel.FolioCurrency;
	EndIf;
	vServicePrices = pService.GetObject().pmGetServicePrices(pHotel, pDate);
	If vServicePrices.Count() > 0 Then
		Return vServicePrices.Get(0).Currency;
	EndIf;
	Return pHotel.FolioCurrency;
EndFunction // GetServiceCurrency

// -----------------------------------------------------------------------------
Function ExtractMessage(pStr)
	vMsg = "";
	vFlagMessageStarted = false;
	i=1;
	While i<=StrLen(pStr) Do
		c = Mid(pStr,i,1);
		If c = ETX Then
			Break;
		EndIf;
		If vFlagMessageStarted Then
			vMsg = vMsg+c;
		EndIf;
		If c = STX Then
			vFlagMessageStarted = true;
		EndIf;
		i=i+1;
	EndDo;
	Return vMsg;
EndFunction // ExtractMessage

// -----------------------------------------------------------------------------
Procedure pmSetTime(pTVConnection)
	// 0630.10.199308:02
	vCmd = "06"+Format(CurrentSessionDate(),"DF=dd.MM.yyyy")+Format(CurrentSessionDate(),"DF=HH:mm");
	rMessage = "";
	vErrCode = CallRS232Command(pTVConnection, vCmd, rMessage);
	WaitABit();
	pTVConnection.WriteStr(EOT);
EndProcedure // pmSetTime

// -----------------------------------------------------------------------------
Procedure pmParseMessage(pTVConnection, pReply, pHotel, rMessage) Export
	If pTVConnection = Undefined Then
		Return;
	EndIf;
	If IsBlankString(pReply) Then
		Return;
	EndIf;
	If Not ValueIsFilled(pHotel) Then
		pHotel = SessionParameters.CurrentHotel;
	EndIf;	
	Try
		If pReply = ACK Then
			rMessage = NStr("en='{ACK} was received!'; de='{ACK} was received!'; ru='Получен {ACK}!'");
			Return;
		EndIf;
		vMsgReply = ExtractMessage(pReply);
		If StrLen(vMsgReply) < 2 And StrLen(pReply) > 2 Then
			WaitABit();
			pTVConnection.WriteStr(NAK);			
			WriteLogText("Write: "+ClearStr(NAK));
			Return;
		EndIf;
		vCommandCode = Mid(vMsgReply,1,2);
		If vCommandCode = "53" Then
			WriteLogText("Rcv:Charge video service");
			If StrLen(vMsgReply) < 30 Then
				// NAK
				rMessage = NStr("en='Wrong message length <'; de='Wrong message length <'; ru='Неверная длина сообщения <'")+pReply+">";
				WaitABit();
				pTVConnection.WriteStr(NAK);			
				WriteLogText("Write: "+ClearStr(NAK));
			Else
				// 5329.10.1993012321:16   19.5002
				// charge bill
				vDate 	 = Mid(vMsgReply,3,10);
				vRoomName= Mid(vMsgReply,13,4);
				vTime 	 = Mid(vMsgReply,17,5);
				vPrice 	 = Mid(vMsgReply,22,8);
				vChannel = Mid(vMsgReply,30,2);
				// Check if this charge was already done
				vRoom 		 = GetRoom(vRoomName,pHotel);
				vServiceDate = GetDate(vDate,vTime);
				vQ = New Query;
				vQ.Text =
				"SELECT
				|	RecordRoomService.Ref,
				|	RecordRoomService.Posted,
				|	RecordRoomService.ServiceDate
				|FROM
				|	Document.RecordRoomService AS RecordRoomService
				|WHERE
				|	RecordRoomService.Room = &Room
				|	AND RecordRoomService.ServiceDate = &ServiceDate
				|	AND RecordRoomService.Posted";
				vQ.SetParameter("Room",vRoom);
				vQ.SetParameter("ServiceDate",vServiceDate);
				isNotCharged = vQ.Execute().IsEmpty();
				If isNotCharged Then
					vRoomSrv = Documents.RecordRoomService.CreateDocument();
					vRoomSrv.Hotel = pHotel;
					vRoomSrv.pmFillAttributesWithDefaultValues();
					vRoomSrv.Details		= "channel "+vChannel;
					vRoomSrv.ServiceDate	= vServiceDate;
					vRoomSrv.Room			= vRoom;
					vRoomSrv.RoomService    = GetService(vChannel,pHotel);
					vRoomSrv.Sum			= GetSum(vPrice);
					vRoomSrv.Quantity		= 1;
					vRoomSrv.VATSum			= cmCalculateVATSum(vRoomSrv.VATRate,vRoomSrv.Sum,vServiceDate);
					vRoomSrv.Currency		       = GetServiceCurrency(vRoomSrv.RoomService,pHotel,vRoomSrv.ServiceDate);
					vRoomSrv.Folio 			       = vRoomSrv.pmGetFolioToChargeTo();
					If Not ValueIsFilled(vRoomSrv.Folio) Then
						vF = Documents.Folio.CreateDocument();
						vF.pmFillAttributesWithDefaultValues();
						vF.Room = vRoomSrv.Room;
						vF.Remarks = ""+TrimAll(vRoomSrv.RoomService);
						vF.Write(DocumentWriteMode.Write);
						vRoomSrv.Folio = vF.Ref;
					EndIF;
					vRoomSrv.ExchangeRateDate	   = vRoomSrv.Date;
					vRoomSrv.CurrencyExchangeRate  = cmGetCurrencyExchangeRate(pHotel, vRoomSrv.Currency, vRoomSrv.ExchangeRateDate);
					vRoomSrv.FolioCurrency		   = vRoomSrv.Folio.FolioCurrency;
					vRoomSrv.FolioCurrencyExchangeRate = cmGetCurrencyExchangeRate(pHotel, vRoomSrv.FolioCurrency, vRoomSrv.ExchangeRateDate);
					vRoomSrv.SumInFolioCurrency    = cmConvertCurrencies(vRoomSrv.Sum, vRoomSrv.Currency, 0, vRoomSrv.FolioCurrency, 0, vRoomSrv.ExchangeRateDate, vRoomSrv.Hotel);
					vRoomSrv.VATSumInFolioCurrency = cmCalculateVATSum(vRoomSrv.VATRate,vRoomSrv.SumInFolioCurrency,vRoomSrv.Date); 
					vRoomSrv.Remarks 		= vRoomSrv.ServiceDate;
					vRoomSrv.Client			= vRoomSrv.Folio.Client;
					vRoomSrv.Company		= vRoomSrv.Folio.Company;
					vRoomSrv.RoomServiceChargeType = vChannel;
					vRoomSrv.Write(DocumentWriteMode.Posting);
					WaitABit();
					pTVConnection.WriteStr(ACK);
					WriteLogText("Write: "+ClearStr(ACK));
				EndIf;
			EndIf;
		ElsIf vCommandCode = "63" Then
			// 6301230022143 - bill calling, guest wants to see the bill
			// 2304.05.20100868014786401SERVICE NAME                      1050.00
			vRoom  = Mid(vMsgReply,4,4);
			vRefNo = Mid(vMsgReply,8,7);
			WaitABit();
			pTVConnection.WriteStr("23"+Format(CurrentSessionDate(),"DF=dd.MM.YYYY")+vRoom+vRefNo+"01"+cmAppendBlanks("SERVICE NOT AVAILABLE",32)+cmAppendLeftBlanks("0",6)+".00");
			WaitABit();
			pTVConnection.WriteStr(EOT);
		ElsIf vCommandCode = "62" Then
			// 6201270022143 287.70 - check out call, guest wants to make express checkout
		ElsIf vCommandCode = "54" Then
			// 5401270022143 - message call, guest asks if new messages exists
			WriteLogText("Rcv:Message call");
			pmMessage(pTVConnection,vMsgReply);
		ElsIf vCommandCode = "64" Then
			// 64002214329.10.199320:45:300127 - message confirmation.
			WriteLogText("Rcv:Message confirmation");
			vRefNo = Mid(vMsgReply,4,7);
			vDate  = Mid(vMsgReply,11,10);
			vTime  = Mid(vMsgReply,21,8);
			vRoom  = Mid(vMsgReply,29,4);
			vQ = New Query;
			vQ.Text = "SELECT
			          |	RoomInterfaceStatus.Number,
			          |	RoomInterfaceStatus.Ref,
			          |	RoomInterfaceStatus.Room,
			          |	RoomInterfaceStatus.Room.Description
			          |FROM
			          |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
			          |WHERE
			          |	RoomInterfaceStatus.Number LIKE &qRefNo
			          |	AND RoomInterfaceStatus.Room.Description = &qRoom";
			vQ.SetParameter("qRefNo","%"+vRefNo);
			vQ.SetParameter("qRoom",Format(Number(vRoom),"ND=4; NDS=; NGS=; NG="));
			resQ = vQ.Execute().Unload();
			If resQ.Count() > 0 Then
				vDoc = resQ.Get(0).Ref;
				vDocObj = vDoc.GetObject();
				vDocObj.IsCanceled = true;
				vDocObj.IsProcessed = true;
				vDocObj.CancellationDate = GetDate(vDate,vTime);
				vDocObj.CancellationAuthor = SessionParameters.CurrentUser;
				vDocObj.Write(DocumentWriteMode.Posting);
			EndIf;		
		ElsIf vCommandCode = "58" Then
			// 5830.10.1993012707:15:401	- wake-up confirmation
			WriteLogText("Rcv:Wake-up confirmation");
		ElsIf vCommandCode = "56" Then
		    // Hoist asks what time is it now?
			pmSetTime(pTVConnection);
		ElsIf vCommandCode = "91" Then
			// Data match request. Hoist whants to get all checked in rooms
		ElsIf vCommandCode = "57" Then
			// NAK record - a mistake
		ElsIf vCommandCode = "71" Then
			// Room status
			// 7129.08.1994012912:3007211
		ElsIf vCommandCode = "73" Then
			// 7329.08.1994012912:5074217 - minibar bill
		ElsIf vCommandCode = "75" Then
			// 7529.10.20000123 3:16025144 - TV error
			WriteLogText("Rcv:TV error");
		Else
			//unknown
		EndIf;
	Except
		rMessage = NStr("en='Error while parsing message <'; de='Error while parsing message <'; ru='Ошибка разбора сообщения <'")+vMsgReply+">"+Chars.CR+ErrorDescription();
		WriteLogEvent(NStr("en='Interface.HOIST'; de='Interface.HOIST'; ru='Интерфейс.HOIST'"), EventLogLevel.Error, , , rMessage);
		vErrorCode = NAK;
	EndTry;
	If vErrorCode = NAK Then
		WaitABit();
		pTVConnection.WriteStr(NAK);
		WriteLogText("Write: "+ClearStr(NAK));
	EndIf;
EndProcedure // pmParseMessage

// -----------------------------------------------------------------------------
Function pmProcess(pTVConnection,pRoomInterfaceDoc,rMessage) Export
	Try	
		If Not ValueIsFilled(pRoomInterfaceDoc) Then
			Return true;
		EndIf;
		vDocObj = pRoomInterfaceDoc.GetObject();
		vCommandParameters = "";
		If vDocObj.IsCanceled Then
			vCommandParameters = vDocObj.RoomInterfaceType.TurnOffParameters;
		Else
			vCommandParameters = vDocObj.RoomInterfaceType.TurnOnParameters;
		EndIf;
		If IsBlankString(vCommandParameters) Then
			Return True;
		EndIf;
		vGuestName = "";
		If ValueIsFilled(vDocObj.ParentDoc) Then
			vGuestName = TrimAll(vDocObj.ParentDoc.Guest);
		EndIf;
		vCommandCode = Left(vCommandParameters,2); 
		vCommand = Right(vCommandParameters,StrLen(vCommandParameters)-2);
		If vCommandCode = "21" Then
			// Check-in command
			Return pmCheckIn(pTVConnection,pRoomInterfaceDoc,vCommand,rMessage);
		ElsIf vCommandCode = "31" Then
			// Check-in update
			Return pmUpdateCheckIn(pTVConnection,pRoomInterfaceDoc,vCommand,rMessage);
		ElsIf vCommandCode = "12" Then
			// Check-out
			Return pmCheckOut(pTVConnection,pRoomInterfaceDoc,vCommand);
		ElsIf vCommandCode = "24" Then
			Return pmPrepareMessage(pTVConnection,pRoomInterfaceDoc,vCommand,rMessage);
		ElsIf vCommandCode = "44" Then
			// Delete messsage
		ElsIf vCommandCode = "18" Then
			// Wake-up
			Return pmSetWakeUp(pTVConnection,pRoomInterfaceDoc,vCommand,rMessage);
		Else
			rMessage = NStr("en='Unknown command!'; de='Unknown command!'; ru='Неизвестная команда!'");
			Return False;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return False;
	EndTry;
	Return True;
EndFunction // pmProcess

// -----------------------------------------------------------------------------
STX = Char(2);
ETX = Char(3);
EOT = Char(4);
ENQ = Char(5);
NAK = Char(21);
ACK = Char(6);

// -----------------------------------------------------------------------------
RC_NO_CONNECTION = -1;
RC_OK = 0;
