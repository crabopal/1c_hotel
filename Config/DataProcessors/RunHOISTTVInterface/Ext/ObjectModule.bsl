Var ATS;
Var Hoist;
Var ENQ;
Var STX;
Var ETX;
Var EOT;
Var NAK;
Var ACK;

Var TVDriver;

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
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If IsBlankString(Port) Then
		Port = "COM2";
	EndIf;
	If IsBlankString(InitString) Then
		InitString = "9600,N,8,1";
	EndIf;
	
	// Switch to COM port
	rMessage = "";
	vHoist = Connect(Port, InitString, rMessage);
	If vHoist = Undefined Then
		WriteLogText(NStr("en='Failed to connect! '; de='Failed to connect! '; ru='Ошибка подключения! '")+rMessage, "HOIST");
		Return;
	EndIf;
	WriteLogText(NStr("en='Port '; de='Port '; ru='Порт '")+Port+" "+InitString+NStr("en=' IS OPENED'; de=' IS OPENED'; ru=' ОТКРЫТ'"), "HOIST");
	Progress = 0;
	vTimer = 0;
	While True Do
		Progress = ?(Progress > 1000, 0, Progress + 1);
		// HOIST
		WaitABit();
		vTVReply = vHoist.ReadStr();
		vTVReply = CheckENQ(vTVReply);
		WriteLogText("Reply: " + ClearStr(vTVReply), "HOIST");
		If NOT IsBlankString(vTVReply) And StrLen(vTVReply) > 1 Then
			ParseTVMessage(vHoist, vTVReply);
		Else
			If vTVReply = ENQ Then
				WaitABit();
				vHoist.WriteStr(ACK);
				WriteLogText("Write: "+ClearStr(ACK), "HOIST");
			EndIf;
			SendTVMessages(vHoist);
		EndIf;
		#IF CLIENT THEN
			UserInterruptProcessing();
		#ENDIF
	EndDo;
	TVDriver.pmDisconnect(vHoist);
	TVDriver = Undefined;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function CheckENQ(str)
	If IsBlankString(str) Then
		Return "";
	EndIf;	
	vMsg = Left(str,1);
	i=2;
	While i<=StrLen(str) Do
		c = Mid(str,i,1);
		If c <> ENQ Then
			vMsg = vMsg+c;
		EndIf;
		i = i+1;
	EndDo;
	Return vMsg;	
EndFunction // CheckENQ

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
Function Connect(pPort, pInitString, rMessage)
	TVDriver = DataProcessors.HOISTPayTVDriver.Create();
	TVDriver.Port = pPort;
	TVDriver.InitString = pInitString;
	vTVConnection = TVDriver.pmConnect();
	Return vTVConnection;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure ParseTVMessage(pTVConnection, pReply)
	If StrLen(pReply) = 1 Then
		If pReply = ENQ Then
			WaitABit();
			pTVConnection.WriteStr(ACK);
			WriteLogText("Write: "+ClearStr(ACK), "HOIST");
			WaitABit();
			pReply = pTVConnection.ReadStr();
			WriteLogText("Reply: "+ClearStr(pReply), "HOIST");
			If StrLen(pReply) < 1 Then
				Return;
			EndIf;
		EndIf;		
	EndIf;	
	WaitABit();
	pTVConnection.WriteStr(ACK);
	WriteLogText("Write: "+ClearStr(ACK), "HOIST");
	rMessage = "";
	TVDriver.pmParseMessage(pTVConnection, pReply, Hotel, rMessage);
EndProcedure // ParseTVMessage

// -----------------------------------------------------------------------------
Procedure SendTVMessages(pTVConnection)
	vQ = New Query;
	vQ.Text = "SELECT
	          |	RoomInterfaceStatus.Ref,
	          |	RoomInterfaceStatus.DeletionMark,
	          |	RoomInterfaceStatus.Number,
	          |	RoomInterfaceStatus.Date,
	          |	RoomInterfaceStatus.Posted,
	          |	RoomInterfaceStatus.Hotel,
	          |	RoomInterfaceStatus.Room,
	          |	RoomInterfaceStatus.RoomInterfaceType,
	          |	RoomInterfaceStatus.Remarks,
	          |	RoomInterfaceStatus.Author,
	          |	RoomInterfaceStatus.CancellationAuthor,
	          |	RoomInterfaceStatus.CancellationDate,
	          |	RoomInterfaceStatus.IsProcessed,
	          |	RoomInterfaceStatus.IsCanceled,
	          |	RoomInterfaceStatus.Presentation,
	          |	RoomInterfaceStatus.PointInTime
	          |FROM
	          |	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	          |WHERE
	          |	(NOT RoomInterfaceStatus.IsProcessed)
	          |	AND (NOT RoomInterfaceStatus.DeletionMark)
	          |	AND RoomInterfaceStatus.RoomInterfaceType.InterfaceType = &qInterfaceType";
	vQ.SetParameter("qInterfaceType", Enums.InterfaceTypes.TV);
	qR = vQ.Execute();
	If qR.IsEmpty() Then
		Return;
	EndIf;
	selQ = qR.Select();
	While selQ.Next() Do
		rMessage = "";
		vSuccess = TVDriver.pmProcess(pTVConnection, selQ.Ref, rMessage);
		If vSuccess Then
			vDocObj = selQ.Ref.GetObject();
			vDocObj.IsProcessed = true;
			vDocObj.Write(DocumentWriteMode.Write);
		EndIf;
		WriteLogText(rMessage, "HOIST");
		#IF CLIENT THEN
			UserInterruptProcessing();
		#ENDIF
	EndDo;	
EndProcedure // SendTVMessages
	
// -----------------------------------------------------------------------------
Procedure WriteLogText(pText, pInterfaceName)
	If StrLen(pText) < 9 Then
		Return;
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage("" + CurrentSessionDate() + " " + pInterfaceName + ": " + TrimAll(pText));
	WriteLogEvent(NStr("en='Interface.HOIST';ru='Интерфейс.HOIST';de='Interface.HOIST'"), EventLogLevel.Information, , , pText);
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
STX = Char(2);
ETX = Char(3);
EOT = Char(4);
ENQ = Char(5);
NAK = Char(15);
ACK = Char(6);
