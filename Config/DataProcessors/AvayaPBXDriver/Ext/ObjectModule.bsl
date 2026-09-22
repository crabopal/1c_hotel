
#Region Variables

Var SerialConnector;
Var Iterator;
Var MessageCount;
Var LastResponse;
Var TimeLastRequestStatusInquiry;
Var MessageACK;
Var MessageNAK;
Var DataArray;
Var TimeStartLog;

// -----------------------------------------------------------------------------
Var ENQ;
Var ACK;
Var NAK;
Var STX;
Var ETX;
Var DLE;

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
		PBXSerialPort = 4;
	EndIf;
	If BaudRate = 0 Then
		BaudRate = 9600;
	EndIf;
	If Not ValueIsFilled(Parity) Then
		Parity = Enums.ParityTypes.None;
	EndIf;
	If Not ValueIsFilled(DataBits) Then
		DataBits = Enums.DataBits.Bits8;
	EndIf;
	If Not ValueIsFilled(StopBits) Then
		StopBits = Enums.StopBits.Bits1;
	EndIf;
	If TimeoutReadInterval = 0 Then
		TimeoutReadInterval = 500;	
	EndIf;
	If TimeoutReadTotalMultiplier = 0 Then
		TimeoutReadTotalMultiplier = 500;	
	EndIf;
	If TimeoutReadTotalConstant = 0 Then
		TimeoutReadTotalConstant = 1;	
	EndIf;
	If TimeoutWriteTotalConstant = 0 Then
		TimeoutWriteTotalConstant = 100;	
	EndIf;
	If TimeoutWriteTotalMultiplier = 0 Then
		TimeoutWriteTotalMultiplier = 100;	
	EndIf;
	If Not ValueIsFilled(CallsLoggingFile) Then
		CallsLoggingFile = "";
	EndIf;
	If LogCleaning = "0" Or LogCleaning = "" Then
		LogCleaning = "1";
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
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
		// Openg COM port
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
		SerialConnector.BlockMode = True;
		// Setup timeouts
		SerialConnector.TimeoutReadInterval = TimeoutReadInterval;
		SerialConnector.TimeoutReadTotalMultiplier = TimeoutReadTotalMultiplier;
		SerialConnector.TimeoutReadTotalConstant = TimeoutReadTotalConstant;
		SerialConnector.TimeoutWriteTotalConstant = TimeoutWriteTotalConstant;
		SerialConnector.TimeoutWriteTotalMultiplier = TimeoutWriteTotalMultiplier;
		// Send/receive acknowledgement
		Iterator = 0;
		vSuccess = False;
		While Not StopInterface Do
			If CurrentSessionDate() >= TimeLastRequestStatusInquiry  + 8 Then 
				vSuccess = SendKeepAliveMessage();
			EndIf;
			If vSuccess Then
				ReadString();	
			EndIf;
			While vSuccess And DataArray.Count() > 0 Do
				ProcessEventFromPBX(DataArray[0]);
				DataArray.Delete(0);
			EndDo;
			CheckLogСleaning();
			pmLoadDataProcessorAttributes();
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
	If ValueIsFilled(CallsLoggingFile) Then
		WriteLogAtFile(pMsg, "");
	EndIf;
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Function CharLRC(pStrArr, pStart = 0)
	vSeed = "00000000";
	For i = pStart To pStrArr.Count() - 2 Do
		vChar = cmDec2Bin(NumberFromHexString("0x" + pStrArr[i]));
		vSeed = cmXOR(vSeed, vChar);
	EndDo;
	Return Dec2Hex(cmBin2Dec(vSeed));
EndFunction // cmCharLRC

// -----------------------------------------------------------------------------
Function CheckCharLRC(pStrArr)
	vInpCharLRC = pStrArr[pStrArr.Count() - 1];
	vNewCharLRC = CharLRC(pStrArr, 1);
	If vNewCharLRC = vInpCharLRC Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // CheckCharLRC

// -----------------------------------------------------------------------------
Function HexLRC(pStrArr, pStart = 0)
	vBinLRC = "00000000";
	For i = pStart To pStrArr.Count() - 1 Do
		vBinLRC = cmXOR(vBinLRC, cmDec2Bin(NumberFromHexString("0x" + pStrArr[i])));
	EndDo;
	Return cmBin2Hex(vBinLRC);
EndFunction // HexLRC

// -----------------------------------------------------------------------------
Function CheckLRC(pData)
	vResult = True;
	If CheckCharLRC(pData) Then
		vBytesSent = WriteByte(MessageACK);
		LastResponse = ACK; 
	Else
		vBytesSent = WriteByte(MessageNAK);	
		LastResponse = NAK;
	EndIf;
	If Not vBytesSent > 0 And DebugMode Then
		DoMessage("PMS -> PBX. Failed to send NAK to keep alive message", MessageStatus.Attention);
	EndIf;
	Return vResult;	
EndFunction // CheckLRC

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
Function GetDataPresentation(Val pStrArr)
	vStrArr = New Array(); 
	For i = 0 To pStrArr.Count() - 1 Do
		vStrArr.Add("[" + TrimAll(pStrArr[i]) + "]");	
	EndDo;
	vStr = StrConcat(vStrArr);
	Return vStr;
EndFunction // GetDataPresentation

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
Procedure SetRoomStatus(pRoom, pRoomStatus, pEmpCode, pOperationTime = Undefined)
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
Function GetRoomByCode(Val pStr)
	vRoom = cmGetRoomByCode(pStr, Hotel, "AVAYA");
	If Not ValueIsFilled(vRoom) And Left(pStr, 1) = "0" Then
		pStr = Mid(pStr, 2);
		vRoom = cmGetRoomByCode(pStr, Hotel, "AVAYA");
	EndIf;
	Return vRoom;
EndFunction // GetRoomByCode

// -----------------------------------------------------------------------------
Function Dec2Hex(Val pValue)
	vResult = "";
	vValue = Int(pValue);
	If vValue > 0 Then
		While vValue > 0 Do
    		vResult = Mid("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", vValue % 16 + 1, 1) + vResult;
  			vValue = Int(vValue/16) ;
     	EndDo;		
	Else
		vResult = "0";	
	EndIf;
	If StrLen(vResult) > 0 And StrLen(vResult) % 2 <> 0 Then
		vResult = "0" + vResult;	
	EndIf;
	Return vResult;
EndFunction // Dec2Hex

// -----------------------------------------------------------------------------
Function ProcessCallEventFromPBX(Val pData)
	vSuccess = True;
	If DebugMode Then
		DoMessage("PBX -> PMS. Call data received: " + GetDataPresentation(pData));
	EndIf;
	// Room status change
	vOperationTime = CurrentSessionDate();     
	// Parse message
	
	vDataStructura = ParseData(pData);
		
	// Update room status
	vRoomStatus = Undefined;
	If ValueIsFilled(vDataStructura.RoomNumber) Then
		vRoom = GetRoomByCode(vDataStructura.RoomNumber);
		If ValueIsFilled(vRoom) Then
			vRoomStatus = GetRoomStatus(vDataStructura.PBXCode);
			If ValueIsFilled(vRoomStatus) Then
				// Skip updating room status if it was set after phone call time
				SetRoomStatus(vRoom, vRoomStatus, vDataStructura.EmployeeNumber, vOperationTime);
			Else
				DoMessage("PBX -> PMS. Failed to get room status by code: NextRoomStatus for the room" + vDataStructura.RoomNumber);
				vSuccess = False;
			EndIf;
		Else
			DoMessage("PBX -> PMS. Failed to find room by its code: " + vDataStructura.RoomNumber);
			vSuccess = False;
		EndIf;
	Else
		If DebugMode Then
			DoMessage("PBX -> PMS. No room number was found!", MessageStatus.Attention);
		EndIf;
	EndIf;
	Return vSuccess;
EndFunction // ProcessEventFromPBX

// -----------------------------------------------------------------------------
Function GetRoomStatus(pPBXCode)	
	vRoomStatus = Catalogs.RoomStatuses.EmptyRef();
	vPBXCode = ?(cmIsNumber(pPBXCode), Number(pPBXCode), 0);
	If vPBXCode > 0 Then 
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
		|	AND (RoomStatuses.Hotel = &qHotel
		|			OR RoomStatuses.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|
		|ORDER BY
		|	RoomStatuses.SortCode";
		vQry.SetParameter("qHotel", Hotel);
		vQry.SetParameter("qPBXPhoneNumber", vPBXCode);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vRoomStatus = vQryRes.Get(0).RoomStatus;	
		EndIf;	
	EndIf;
	Return vRoomStatus;
EndFunction // GetRoomStatus

// -----------------------------------------------------------------------------
Function GetCommandByteArray(pCmdHex)
	vBytesArray = New Array();
	For Each vByte In pCmdHex Do
		vBytesArray.Add(NumberFromHexString("0x" + vByte));
	EndDo;
	Return vBytesArray;
EndFunction // GetCommandByteArray

// -----------------------------------------------------------------------------
Function SendKeepAliveMessage()
	vSuccess = False;
	vCmd = GetStatusInquiryMessage();
	For i = 1 To 4 Do
		TimeLastRequestStatusInquiry = CurrentSessionDate();
		vBytesSent = WriteByte(vCmd);
		If vBytesSent > 0 Then
			vReply = ReadString();
			If vReply.Count() > 0 Then 
				If vReply[0] = ACK Then
					vSuccess = True;
					Break;
				Else
					If DebugMode Then
						DoMessage("PBX -> PMS. Wrong reply to keep alive: " + GetDataPresentation(vReply), MessageStatus.Attention);
					EndIf;
					Continue;
				EndIf;
			Else
				If DebugMode Then
					DoMessage("PBX -> PMS. No phone data received as an answer!", MessageStatus.Attention);
				EndIf;
			EndIf;
		Else
			If DebugMode Then
				DoMessage("PMS -> PBX. Unable to send keep alive data to PBX!", MessageStatus.Attention);
			EndIf;		
		EndIf;
		cmWait(8);
	EndDo;
	Return vSuccess;
EndFunction // SendKeepAliveMessage

// -----------------------------------------------------------------------------
Procedure ProcessEventFromPBX(pData)
	If pData.Count() > 0 Then
		If pData[1] = "31" Then 
			vStatus = "8";
			If ProcessCallEventFromPBX(pData) Then
				vStatus = "9";		
			EndIf;
			vCmd = GetResponseHousekeeperStatusMessage(pData, vStatus);
			For i = 1 To 4 Do
				vBytesSent = WriteByte(vCmd);
				If vBytesSent > 0 Then
					vReplyHS = ReadString();
					If vReplyHS.Count() > 0 Then
						If vReplyHS[0] = ACK Then
							Break;	
						EndIf;
					Else
						If DebugMode Then
							DoMessage("PBX -> PMS. No reply to keep alive message was received", MessageStatus.Information);
						EndIf;
					EndIf;
				Else
					If DebugMode Then
						DoMessage("PMS -> PBX. Failed to confirm that record successfully processed!", MessageStatus.Attention);
					EndIf;
				EndIf;
			EndDo;
		Else
			If DebugMode Then
				DoMessage("PBX -> Command received and ignored. Message data: " + GetDataPresentation(pData), MessageStatus.Information);
			EndIf;	
			If Not vBytesSent > 0 And DebugMode Then
				DoMessage("PMS -> PBX. Failed to confirm that record successfully processed!", MessageStatus.Attention);
			EndIf;	
		EndIf;
	EndIf;
EndProcedure // ProcessEventFromPBX

// -----------------------------------------------------------------------------
Function WriteByte(pCmd)
	If ValueIsFilled(CallsLoggingFile) Then
		WriteLogAtFile(GetDataPresentation(pCmd), "Send: ");
	EndIf;
	vCmdBytesArray = GetCommandByteArray(pCmd);
	vVaiant = New COMSafeArray(vCmdBytesArray, "VT_VARIANT", vCmdBytesArray.Count());
	vBytesWritten = SerialConnector.WriteVariant(vVaiant); 
	Return vBytesWritten;
EndFunction // WriteByte

// -----------------------------------------------------------------------------
Function ReadString()
	vReplayList = New ValueList();
	vReply = New Array();
	vChar = 0;
	vBytesRcv = 1;
	While vBytesRcv > 0 Do
		vBytesRcv = SerialConnector.Read(vChar, 1);
		If vBytesRcv > 0 Then
			vReply.Add(Dec2Hex(vChar));
			If vChar = 5 Then 
				If LastResponse = ACK Then
					vBytesSent = WriteByte(MessageACK);
				Else
					vBytesSent = WriteByte(MessageNAK);	
				EndIf;
				vReply.Clear();
			ElsIf vChar = 6 Or vChar = 21 Then
				Break;	
			ElsIf vChar = 2 Then
				vNextByte = False;
				vLastChar = vChar;
				While (vNextByte Or vChar <> 3) And vBytesRcv > 0 Do
					vBytesRcv = SerialConnector.Read(vChar, 1);
					If Not vNextByte And vChar = 16 Then
						vNextByte = True;	
					ElsIf vNextByte And (vLastChar <> 16 Or (vLastChar = 16 And vChar = 16)) Then 
						vNextByte = False;	
					EndIf;
					If vBytesRcv > 0 Then
						vLastChar = vChar;
						vReply.Add(Dec2Hex(vChar));
					EndIf;
				EndDo;
				vBytesRcv = SerialConnector.Read(vChar, 1);
				If vBytesRcv > 0 Then
					vReply.Add(Dec2Hex(vChar));	
				EndIf;
				If vReply.Count() > 0 And ValueIsFilled(CallsLoggingFile) Then
					WriteLogAtFile(GetDataPresentation(vReply), "Received: ");
				EndIf;
				If CheckLRC(vReply) Then
					If vReply[1] = "31" Then 
						vReplayList.LoadValues(vReply);
						DataArray.Add(vReplayList.UnloadValues());
						vReplayList.Clear();
					EndIf;
				EndIf;
				vReply.Clear();
			EndIf;
		EndIf;
	EndDo;
	If vReply.Count() > 0 And ValueIsFilled(CallsLoggingFile) Then
		WriteLogAtFile(GetDataPresentation(vReply), "Received: ");
	EndIf;
	Return vReply;
EndFunction // ReadString

// -----------------------------------------------------------------------------
Function GetCodeData(Val HexCode)
	Return Right(HexCode, 1); 
EndFunction // GetCodeData

// -----------------------------------------------------------------------------
Function ParseData(Val pData)
	vDataStructure = New Structure("PBXCode, RoomNumber, EmployeeNumber", "", "", "");
	vDataStructure.PBXCode = GetCodeData(pData[2]);
	vRoomNumber = "";
	vCountHex = 0;
	i = 3;
	While vCountHex < 3 And i < pData.Count() Do
		If pData[i] = "10" And i + 1 < pData.Count() Then
			vRoomNumber = StrReplace(pData[i + 1], "F", "") + vRoomNumber;
			i = i + 2;
		Else
			vRoomNumber = StrReplace(pData[i], "F", "") + vRoomNumber;
			i = i + 1;
		EndIf;
		vCountHex = vCountHex + 1;
	EndDo;
	vDataStructure.RoomNumber = vRoomNumber;
	
	vEmployeeNumber = "";
	vCountHex = 0;
	While vCountHex < 3 And i < pData.Count() Do
		If pData[i] = "10" And i + 1 < pData.Count() Then
			vEmployeeNumber = StrReplace(pData[i + 1], "F", "") + vEmployeeNumber;
			i = i + 2;
		Else
			vEmployeeNumber = StrReplace(pData[i], "F", "") + vEmployeeNumber;
			i = i + 1;
		EndIf;
		vCountHex = vCountHex + 1;
	EndDo;
	vDataStructure.EmployeeNumber = vEmployeeNumber;
	Return vDataStructure;
EndFunction // ParseData

// -----------------------------------------------------------------------------
Function GetMessageCount()
	If Iterator >= 10 Then
		Iterator = 0;	
	EndIf;
	Return MessageCount[Iterator];
EndFunction // GetMessageCount

// -----------------------------------------------------------------------------
Function GetStatusInquiryMessage()
	vMessage = New Array();
	vMessage.Add("02");
	vMessage.Add("70");
	vMessage.Add(GetMessageCount() + "F");
	vMessage.Add("FF");
	vMessage.Add("03");
	vMessage.Add(HexLRC(vMessage, 1));
	Iterator = Iterator + 1;
	Return vMessage;
EndFunction // StatusInquiryMessage

// -----------------------------------------------------------------------------
Function GetResponseHousekeeperStatusMessage(Val pRequest, pStatus)
	vMessage = New Array();
	For i = 0 To pRequest.Count() - 2 Do
		If i = 2 Then
			vMessage.Add(GetMessageCount() + pStatus);
		Else
			vMessage.Add(pRequest[i]);	
		EndIf;
	EndDo;
	vMessage.Add(HexLRC(vMessage, 1));
	Iterator = Iterator + 1;
	Return vMessage;
EndFunction // GetResponseHousekeeperStatusMessage

// -----------------------------------------------------------------------------
Procedure WriteLogAtFile(pStr, pTypeMsg = "Send: ")
	If ValueIsFilled(pStr) Then
		vLogFile = New TextWriter(CallsLoggingFile + "\1C_PMS_Log.txt", TextEncoding.UTF8, , True);
		vLogFile.WriteLine(TrimAll(Format(CurrentSessionDate(), "DF=dd.MM.yy hh:mm:ss")) + ": " + pTypeMsg + pStr);
		vLogFile.Close();
	EndIf;
EndProcedure // WriteLogAtFile

// -----------------------------------------------------------------------------
Procedure CheckLogСleaning()
	If ValueIsFilled(CallsLoggingFile) Then
		If LogCleaning <> "0" And LogCleaning <> "" Then
			vCurDate = CurrentSessionDate();
			If (LogCleaning = "1" And BegOfDay(vCurDate) <> BegOfDay(TimeStartLog)) Or 
			   (LogCleaning = "2" And BegOfWeek(vCurDate) <> BegOfWeek(TimeStartLog)) Or 
			   (LogCleaning = "3" And BegOfMonth(vCurDate) <> BegOfMonth(TimeStartLog)) Then
				vLogFile = New TextWriter(CallsLoggingFile + "\1C_PMS_Log.txt", TextEncoding.UTF8, , False);
				vLogFile.Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CheckLogСleaning

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
STX = "02";
ETX = "03";
ENQ = "05";
ACK = "06";
DLE = "10";
NAK = "15";

DataArray = New Array();

TimeLastRequestStatusInquiry = CurrentSessionDate();
TimeStartLog = CurrentSessionDate();

LastResponse = NAK; 

MessageACK = New Array();
MessageACK.Add(ACK);

MessageNAK = New Array();
MessageNAK.Add(NAK);

MessageCount = New Map();
MessageCount.Insert(0, "2");
MessageCount.Insert(1, "3");
MessageCount.Insert(2, "4");
MessageCount.Insert(3, "5");
MessageCount.Insert(4, "6");
MessageCount.Insert(5, "7");
MessageCount.Insert(6, "8");
MessageCount.Insert(7, "9");
MessageCount.Insert(8, "A");
MessageCount.Insert(9, "B");

#EndRegion
