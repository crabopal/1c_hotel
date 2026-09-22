#Region Variables

Var TCPIP;
Var CSTOOLS6_LICENSE_KEY;
Var CSTOOLS10_LICENSE_KEY;
Var IsConnected;
Var Timer;
Var LastError;
Var STX;
Var ETX;
Var SP;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameters 
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	// Get reference to the DataProcessor catalog item
	vDP = DataProcessor;
	If ValueIsFilled(vDP) Then
		vDO = vDP.GetObject();
		vDO.Read();
		// 1. Apply static parameters if are filled
		vStatic = vDO.StaticParameters.Get();
		If vStatic <> Undefined Then
			// Static parameters are simple structure
			FillPropertyValues(ThisObject, vStatic);
			// Load data processor tabular parts
			For Each vTP In ThisObject.Metadata().TabularSections Do
				Try
					ThisObject[vTP.Name].Load(vStatic["TP_" + vTP.Name]);
				Except
				EndTry;
			EndDo;
		EndIf;
		// 2. Call default attributes initialization procedure if static parameters were not set 
		If vStatic = Undefined Then
			// Fill attributes with default values
			pmFillAttributesWithDefaultValues();
		EndIf;
	Else
		// Fill attributes with default values
		pmFillAttributesWithDefaultValues();
	EndIf;
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	If Port = 0 Then
		Port = 51000;
	EndIf;
	If MultiplyFactor = 0 Then
		MultiplyFactor = 1;
	EndIf;
	If TimerForCheckEvents = 0 Then
		TimerForCheckEvents = 30;	
	EndIf;
	If TimerReportForNoConnection = 0 Then
		TimerReportForNoConnection = 3600;	
	EndIf;
	If ValueIsFilled(InteractionParameters) And ValueIsFilled(InteractionParameters.Hotel) Then
		If Not ValueIsFilled(DataExchangeFileCurrency) Then
			DataExchangeFileCurrency = InteractionParameters.Hotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(PhoneCallsService) Then
			PhoneCallsService = InteractionParameters.Hotel.PhoneCallService;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameters
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	If UseHTTP Then
		If Not InteractionParameters.FullSynchronizationIsActive Then
			RunHTTP(pParameter);
		EndIf;
	Else
		RunTCP();
	EndIf;
EndProcedure // pmRun

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBody	 - String	 - Body
//  pHeaders - Map		 - Headers
//  rSuccess - Boolean	 - Success
//  rMessage - String	 - Message
//  pVersion - String	 - Version
// 
// Returns:
//  String, Structure - Result
//
Function HTTPRequest(pBody, pHeaders, rSuccess, rMessage, pVersion) Export 
	vResult = New Structure("Data", "");
	If pBody = "Ping" Then  
		// Connection test 	
	ElsIf pBody = "Connect" Then
		SendLinkStart = False;
		IsLinkAlive = False;
		SendLinkEnd = False;
		LinkRecords.Clear();
		pmSaveDataProcessorAttributes();
		ProcessEventsFromFIAS(STX + DataProcessors.FIASDriver.GetLinkStart(CurrentSessionDate()) + ETX, True, vResult.Data);
	ElsIf pBody = "Disconnect" Then
		SendLinkStart = False;
		IsLinkAlive = False;
		LinkRecords.Clear();
		pmSaveDataProcessorAttributes();
	Else
		ProcessEventsFromFIAS(pBody, True, vResult.Data);
	EndIf;
	Return ?(pVersion = "2", vResult.Data, vResult);  
EndFunction // HTTPRequest

// --------------------------------------------------------------------------------
//
Procedure SynchronizationAtServer() Export
	vCount = 0;
	While InteractionParameters.FullSynchronizationIsActive And vCount <> 12 Do
		cmWait(5);
		vCount = vCount + 1;
	EndDo;
	ChangeFlagFullSynchronizationIsActive(True); 
	Try
		ProcessesEvents(GetActiveRoomInterfaceEvents());
		If WriteBuff(DataProcessors.FIASDriver.GetResyncStart(CurrentSessionDate()), "Database Resync start") Then
			ProcessesSyncEvents(GetSyncData());
			WriteBuff(DataProcessors.FIASDriver.GetResyncEnd(CurrentSessionDate()), "Database Resync end")
		EndIf;
	Except
		vErrorInfo = ErrorDescription(); 
		ChangeFlagFullSynchronizationIsActive(False);
		Raise vErrorInfo;
	EndTry;
	ChangeFlagFullSynchronizationIsActive(False);
EndProcedure // SynchronizationAtServer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ChangeFlagFullSynchronizationIsActive(pFullSynchronizationIsActive)
	vObj = InteractionParameters.GetObject();
	vObj.FullSynchronizationIsActive = pFullSynchronizationIsActive;
	vObj.Write();
EndProcedure // ChangeFlagFullSynchronizationIsActive

// -----------------------------------------------------------------------------
Procedure FillLinkRecords(pLinkRecordCommand, pLinkRecordParameter)
	If Not ValueIsFilled(pLinkRecordCommand) Or (StrLen(pLinkRecordParameter) > 0 And StrLen(pLinkRecordParameter) % 2 <> 0) Then
		Return;	
	EndIf;
	i = 1;
	pmLoadDataProcessorAttributes();
	If StrLen(pLinkRecordParameter) > 0 Then
		While i <= StrLen(pLinkRecordParameter) - 1 Do
			vParameter = Mid(pLinkRecordParameter, i, 2); 
			vLinkRecordsArr = LinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", pLinkRecordCommand, vParameter));
			If vLinkRecordsArr.Count() = 0 Then
				vNewRow = LinkRecords.Add();
				vNewRow.LinkRecordCommand = pLinkRecordCommand;
				vNewRow.LinkRecordParameter = vParameter;
			EndIf;
			i = i + 2;
		EndDo;
	Else
		vLinkRecordsArr = LinkRecords.FindRows(New Structure("LinkRecordCommand, LinkRecordParameter", pLinkRecordCommand, ""));
		If vLinkRecordsArr.Count() = 0 Then
			vNewRow = LinkRecords.Add();
			vNewRow.LinkRecordCommand = pLinkRecordCommand;
			vNewRow.LinkRecordParameter = "";	
		EndIf;
	EndIf;
	pmSaveDataProcessorAttributes();
EndProcedure // FillLinkRecords

// -----------------------------------------------------------------------------
Procedure DoMessage(pMsg, pMsgStatus = Undefined, pRequest = "", pResponse = "", pFunctionName = "")
	vFunctionName = "FIAS";
	If ValueIsFilled(pFunctionName) Then
		vFunctionName = pFunctionName; 	
	EndIf;
	vMsgStatus = MessageStatus.Information;
	If pMsgStatus <> Undefined Then
		vMsgStatus = pMsgStatus;
	EndIf;
	If vMsgStatus = MessageStatus.Attention Then 
		WriteLogEvent(vFunctionName, ?(vMsgStatus = MessageStatus.Attention, EventLogLevel.Error, EventLogLevel.Information), , , pMsg);
		If ValueIsFilled(EmployeeForNotification) Then
			If ValueIsFilled(EmployeeForNotification.Phones) Then
				// send SMS
				vPhones = TrimAll(EmployeeForNotification.Phones);
				vErrorDescription = "";
				vMessageId = "";
				SMS.SendMessage(pMsg, vPhones,,,,,,, vErrorDescription, vMessageId);
			EndIf;
			If ValueIsFilled(EmployeeForNotification.EMail) Then
				// send e-mail
				vSubject = TrimAll(vMsgStatus) + ": " + TrimAll(InteractionParameters.Description);
				vEmail = EmployeeForNotification.EMail;
				vErrorMessage = "";
				JobsScheduled.cmSendTextByEMail(vSubject, pMsg, vEMail,, vErrorMessage);
			EndIf;
			// send telegram
			Catalogs.ChatBots.BotNotify(InteractionParameters.Hotel, EmployeeForNotification, pMsg);
		EndIf;
	EndIf;
	If ValueIsFilled(InteractionParameters) Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFunctionName, ?(vMsgStatus = MessageStatus.Attention, Enums.ExternalSystemEventTypes.Error, Enums.ExternalSystemEventTypes.Info), pRequest, pResponse, pMsg);
	EndIf;
EndProcedure // DoMessage

// -----------------------------------------------------------------------------
Procedure SetRoomStatus(pRoom, pRoomStatus, pEmpCode, pOperationTime = Undefined)
	If pOperationTime = Undefined Then
		pOperationTime = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(pRoom) And ValueIsFilled(pRoomStatus) Then
		If InteractionParameters.DebugMode Then
			DoMessage(NStr("en = 'FIAS -> Room to be updated is: '; de = 'FIAS -> Der zu aktualisierende Zimmer ist: '; ru = 'FIAS -> Номер, подлежащий обновлению: '") + pRoom + NStr("en = ', status to be set is: '; de = ', zu setzender Status ist:'; ru = ', устанавливаемый статус: '") + pRoomStatus, MessageStatus.Information,,, "FIASDriver.SetRoomStatus");
		EndIf;
		// Skip updating status if it is equal to the new one
		If pRoom.RoomStatus <> pRoomStatus Then
			// Skip updating room status if it was set after phone call time
			vRoomObj = pRoom.GetObject();
			vLastStatus = vRoomObj.pmGetRoomStatusHistoryState('39991231235959');
			If vLastStatus.Count() > 0 Then
				vLastStatusRow = vLastStatus.Get(0);
				If pOperationTime < vLastStatusRow.Period Then
					If InteractionParameters.DebugMode Then
						DoMessage(NStr("en = 'FIAS -> Room status update will be skipped because operation time '; de = 'FIAS -> Zimmerstatusaktualisierung wird wegen Betriebszeit übersprungen '; ru = 'FIAS -> Обновление статуса номера будет пропущено, т.к. время работы '") + pOperationTime + NStr("en = ' is earlier than last room status change time '; de = ' liegt vor der letzten Änderung des Zimmerstatus '; ru = ' раньше, чем время последнего изменения статуса комнаты '") + vLastStatusRow.Period, MessageStatus.Information,,, "FIASDriver.SetRoomStatus");
					EndIf;
					Return;
				ElsIf vLastStatusRow.RoomStatus = vRoomObj.Owner.OccupiedRoomStatus Then
					If InteractionParameters.DebugMode Then
						DoMessage(NStr("en = 'FIAS -> Room status update will be skipped because current room status is occupied!'; de = 'FIAS -> Zimmerstatusaktualisierung wird übersprungen, da aktueller Zimmerstatus belegt ist!'; ru = 'FIAS -> Обновление статуса комнаты будет пропущено, так как текущий статус номера занят!'"), MessageStatus.Information,,, "FIASDriver.SetRoomStatus");
					EndIf;
					Return;
				EndIf;
			EndIf;
			// Update room status
			vRoomObj.RoomStatus = pRoomStatus;
			vRoomObj.Write();
			// Get employee code
			vEmployee = Undefined;
			If ValueIsFilled(pEmpCode) Then
				vEmployee = GetObjectRefByExternalSystemCode("Employees", pEmpCode);
				If ValueIsFilled(vEmployee) Then
					If InteractionParameters.DebugMode Then
						DoMessage(NStr("en = 'FIAS -> Employee responsible is '; de = 'FIAS -> Verantwortlicher Mitarbeiter ist '; ru = 'FIAS -> Ответственный сотрудник '") + TrimAll(vEmployee), MessageStatus.Information,,, "FIASDriver.SetRoomStatus");
					EndIf;
				EndIf;
			EndIf;
			// Add record to the room status change history
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), ?(ValueIsFilled(vEmployee), vEmployee, SessionParameters.CurrentUser), "FIAS -> PMS");
		Else
			If InteractionParameters.DebugMode Then
				DoMessage(NStr("en = 'FIAS -> This room status has already been set!'; de = 'FIAS -> Dieser Zimmerstatus wurde bereits gesetzt!'; ru = 'FIAS -> Данный статус комнаты уже установлен!'"), MessageStatus.Information,,, "FIASDriver.SetRoomStatus");
			EndIf;
		EndIf;
	Else
		If InteractionParameters.DebugMode Then
			If Not ValueIsFilled(pRoom) Then
				DoMessage(NStr("en = 'FIAS -> Room is not defined!'; de = 'FIAS -> Zimmer ist nicht definiert!'; ru = 'FIAS -> Номер не определен!'"), MessageStatus.Attention,,, "FIASDriver.SetRoomStatus");
			ElsIf Not ValueIsFilled(pRoomStatus) Then
				DoMessage(NStr("en = 'FIAS -> Room status is not defined!'; de = 'FIAS -> Zimmerstatus ist nicht definiert!'; ru = 'FIAS -> Статус номера не определен!'"), MessageStatus.Attention,,, "FIASDriver.SetRoomStatus");
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SetRoomStatus

// -----------------------------------------------------------------------------
Function GetDateTime(pDate = "00010101", pTime, pIsOnlyTime = False)
	vDateTime = '00010101';
	Try
		vDateTime = Date(?(Not pIsOnlyTime, Left(Format(CurrentSessionDate(), "DF=yyyy"), 2), "") + TrimAll(pDate) + TrimAll(pTime)); 
	Except
		vDateTime = '00010101';	
	EndTry;
	Return vDateTime;
EndFunction // GetDateTime

// -----------------------------------------------------------------------------
Function GetCodeDescription(pCode)
	vCodeDescription = "";
	If pCode = "AA" Then
		vCodeDescription = "Virtual Number already assigned";	
	ElsIf pCode = "AN" Then
		vCodeDescription = "Virtual Number not found";
	ElsIf pCode = "BM" Then
		vCodeDescription = "Balance mismatch";
	ElsIf pCode = "BY" Then
		vCodeDescription = "Telephone / Encoder Busy";
	ElsIf pCode = "CD" Then
		vCodeDescription = "Check-out date is not today";
	ElsIf pCode = "CO" Then
		vCodeDescription = "Posting denied because overwriting the CreditLimit is not allowed";
	ElsIf pCode = "DE" Then
		vCodeDescription = "Wakeup/Key has been deleted";
	ElsIf pCode = "DM" Then
		vCodeDescription = "Sum of subtotals doesn't match TotalAmount";
	ElsIf pCode = "DN" Then
		vCodeDescription = "Request denied";
	ElsIf pCode = "FX" Then
		vCodeDescription = "Guest  not allowed this feature";
	ElsIf pCode = "IA" Then
		vCodeDescription = "Invalid account";
	ElsIf pCode = "NA" Then
		vCodeDescription = "Night Audit";
	ElsIf pCode = "NF" Then
		vCodeDescription = "Feature not enabled or Check-out process not running";
	ElsIf pCode = "NG" Then
		vCodeDescription = "Guest not found";
	ElsIf pCode = "NM" Then
		vCodeDescription = "Message/Locator not found";
	ElsIf pCode = "NP" Then
		vCodeDescription = "Posting denied for this guest (NoPost flag has been set)";
	ElsIf pCode = "NR" Then
		vCodeDescription = "No Response";
	ElsIf pCode = "OK" Then
		vCodeDescription = "Command or request completed successfully";
	ElsIf pCode = "RF" Then
		vCodeDescription = "Referral";
	ElsIf pCode = "RY" Then
		vCodeDescription = "Retry";
	ElsIf pCode = "SV" Then
		vCodeDescription = "Wakeup has been sent to external system";
	ElsIf pCode = "UR" Then
		vCodeDescription = "Unprocessable request, this request cannot be carried out , no retry";
	EndIf;
	Return vCodeDescription;
EndFunction // GetCodeDescription

// -----------------------------------------------------------------------------
Function GetPhoneNumber(pRoom, pPhoneNumber)
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	PhoneNumbers.Ref AS Ref
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	NOT PhoneNumbers.IsFolder
	|	AND NOT PhoneNumbers.DeletionMark
	|	AND PhoneNumbers.Owner = &qHotel
	|	AND PhoneNumbers.PhoneNumber = &qPhoneNumber
	|	AND PhoneNumbers.Room = &qRoom";
	vQry.SetParameter("qHotel", InteractionParameters.Hotel);
	vQry.SetParameter("qPhoneNumber", TrimAll(pPhoneNumber));
	vQry.SetParameter("qRoom", pRoom);
	Result = vQry.Execute().Unload();
	
	vPhoneNumberRef = Catalogs.PhoneNumbers.EmptyRef();
	If Result.Count() > 0 Then
		vPhoneNumberRef = Result.Get(0).Ref;
	EndIf;
	
	Return vPhoneNumberRef;
EndFunction // GetPhoneNumber

// -----------------------------------------------------------------------------
Function CheckNotUploadPhoneCalls(pPhoneNumber)
	vQuery = New Query();
	vQuery.Text = 
	"SELECT
	|	PhoneNumbers.Ref AS Ref
	|FROM
	|	Catalog.PhoneNumbers AS PhoneNumbers
	|WHERE
	|	PhoneNumbers.PhoneNumber = &qPhoneNumber
	|	AND PhoneNumbers.NotUploadPhoneCalls
	|	AND NOT PhoneNumbers.IsFolder
	|	AND NOT PhoneNumbers.DeletionMark
	|	AND PhoneNumbers.Room = VALUE(Catalog.Rooms.EmptyRef)
	|	AND PhoneNumbers.Owner = &qHotel
	|
	|GROUP BY
	|	PhoneNumbers.Ref";
	vQuery.SetParameter("qPhoneNumber", TrimAll(pPhoneNumber));
	vQuery.SetParameter("qHotel", InteractionParameters.Hotel);
	Return Not vQuery.Execute().IsEmpty()
EndFunction // CheckNotUploadPhoneCalls

// -----------------------------------------------------------------------------
Function CheckTimer()
	vResult = True;
	If IsConnected And Timer <> Undefined Then
		If Timer.IsEnabled And Not Timer.TimerEnd Then
			vResult = False;	
		EndIf;	
	EndIf;
	Return vResult;
EndFunction // CheckTimer

// -----------------------------------------------------------------------------
Procedure StartTimer(pSeconds)
	If IsConnected And Timer <> Undefined And pSeconds > 0 Then
		If Not Timer.IsEnabled And Timer.TimerEnd Then
			Timer.StartTimer(pSeconds);	
		EndIf;	
	EndIf;
EndProcedure // StartTimer

// -----------------------------------------------------------------------------
Function CheckErrorTCP()
	vIsError = False;
	If TCPIP.LastError <> 10060 And TCPIP.LastError <> 12001 And TCPIP.LastError <> 0 Then
		If Not StopInterface Then  
			pmLoadDataProcessorAttributes();
			StopInterface = True;
			pmSaveDataProcessorAttributes();
			DoMessage(NStr("en = 'Background job terminated due to error: '; de = 'Hintergrundjob wegen Fehler abgebrochen: '; ru = 'Завершение фонового задания из-за ошибки: '") + TCPIP.LastErrorString, MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
		EndIf;
		vIsError = True;
	EndIf;
	Return vIsError;
EndFunction // CheckErrorTCP 

// -----------------------------------------------------------------------------
Procedure ClearValueTable()	
	pmLoadDataProcessorAttributes();
	LinkRecords.Clear();
	pmSaveDataProcessorAttributes();
EndProcedure // ClearValueTable

// -----------------------------------------------------------------------------
Procedure RunTCP()
	If Port <> 0 And ValueIsFilled(InteractionParameters) Then
		pmLoadDataProcessorAttributes();
		IsRunning = True;
		StopInterface = False;  
		IsLinkAlive = False; 
		SendLinkStart = False;
		SendLinkEnd = False;
		Timestamp = CurrentSessionDate();
		LinkRecords.Clear();
		pmSaveDataProcessorAttributes();
		IsConnected = AttachAddIn("DataProcessor.FIASDriver.Template.Timer", "Native", AddInType.Native);
		If IsConnected Then
			Timer = New("AddIn.Native.Timer"); 
		EndIf;
		vErrorCode = 0;
		// Create client ActiveX object
		Try
			TCPIP = New COMObject("SocketTools.SocketWrench.10");
			// Load license
			vErrorCode = TCPIP.Initialize(CSTOOLS10_LICENSE_KEY);
		Except
			TCPIP = New COMObject("SocketTools.SocketWrench.6");
			// Load license
			vErrorCode = TCPIP.Initialize(CSTOOLS6_LICENSE_KEY);
		EndTry;
		If vErrorCode <> 0 Then
			DoMessage(NStr("en = 'Licensing error: '; de = 'Lizenzierungsfehler: '; ru = 'Ошибка лицензирования: '") + vErrorCode, MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
		Else
			Try
				While Connect() Or Not StopInterface Do
					If Not TCPIP.Connected Or TCPIP.IsClosed Then
						Continue;	
					EndIf;
					TCPIP.Blocking = False;
					TCPIP.Timeout = 0;
					ClearValueTable();
					SendLinkStart = False;
					pmSaveDataProcessorAttributes();
					While TCPIP.Connected And Not TCPIP.IsClosed And Not StopInterface Do				
						SendLinkEnd = False;
						pmSaveDataProcessorAttributes();
						While TCPIP.Connected And Not TCPIP.IsClosed And IsLinkAlive Do			
							If Not StopInterface Then
								ProcessesPriorityEvents();
								If CheckTimer() Then
									ProcessesEvents(GetActiveRoomInterfaceEvents());
									StartTimer(TimerForCheckEvents);
								EndIf;
							ElsIf Not SendLinkEnd Then 
								If WriteBuff(DataProcessors.FIASDriver.GetLinkEnd(CurrentSessionDate()), "Link End") Then
									SendLinkEnd = True;
									pmSaveDataProcessorAttributes();
								EndIf;
							EndIf;
							ReadBuff();
							If CheckErrorTCP() Then
								Break;	
							EndIf;   
							pmLoadDataProcessorAttributes();
						EndDo;
						If CheckErrorTCP() Then
							Break;	
						EndIf;
						IsLinkAlive = False;
						If Not SendLinkStart And Not StopInterface Then
							WriteBuff(DataProcessors.FIASDriver.GetLinkStart(CurrentSessionDate()), "Link Start");
							SendLinkStart = True;
						EndIf; 
						pmSaveDataProcessorAttributes();
						ReadBuff();
						If SendLinkEnd Then
							vErrorCode = TCPIP.Disconnect();	
							If vErrorCode <> 0 Then
								DoMessage(NStr("en = 'FIAS disconnect error: '; de = 'Fehler beim Trennen des FIAS: '; ru = 'Ошибка отключения от FIAS: '") + vErrorCode, MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
							EndIf; 
						EndIf;
						pmLoadDataProcessorAttributes();
						If StopInterface Then
							Break;
						EndIf;
					EndDo;
					If CheckErrorTCP() Then
						Break;	
					EndIf;
					pmLoadDataProcessorAttributes();
					If StopInterface Then
						Break;
					EndIf; 
				EndDo;
			Except
				vErrorMsg = ErrorDescription();
				DoMessage(NStr("en = 'Critical error: '; de = 'Kritischer Fehler: '; ru = 'Критическая ошибка: '") + vErrorMsg, MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
			EndTry;		
		EndIf;
		vErrorCode = TCPIP.Disconnect();
		If vErrorCode <> 0 Then
			DoMessage(NStr("en = 'FIAS disconnect error: '; de = 'Fehler beim Trennen des FIAS: '; ru = 'Ошибка отключения от FIAS: '") + vErrorCode, MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
		EndIf;
		pmLoadDataProcessorAttributes();
		IsRunning = False;
		IsConnected = False;
		IsLinkAlive = False; 
		SendLinkStart = False;
		SendLinkEnd = False;
		StopInterface = False;
		Timestamp = Undefined;
		If Timer <> Undefined Then
			Timer.StopTimer();
		EndIf;
		Timer = Undefined;
		LinkRecords.Clear();
		pmSaveDataProcessorAttributes();
	Else
		DoMessage(NStr("en = 'Connection parameters are missing...'; de = 'Verbindung Parameter fehlen...'; ru = 'Не указаны параметры подключения к FIAS...'"), MessageStatus.Attention,,, "FIASDriver.pmRunInterfaceClient");
	EndIf;	
EndProcedure // RunTCP

// -----------------------------------------------------------------------------
Function Connect()
	vResult = True;
	TCPIP.Blocking = True;
	If Not TCPIP.Connected Or TCPIP.IsClosed Then
		TCPIP.Timeout = 10; // 10 seconds blocking read timeout by default
		vErrorCode = 0;
		If Not TCPIP.Listening Then  
			vErrorCode = TCPIP.Listen("0.0.0.0", Port);		
		EndIf;
		If vErrorCode <> 0 Then
			DoMessage(NStr("en = 'FIAS was not found: '; de = 'FIAS was not found: '; ru = 'Не найден FIAS: '") + vErrorCode + " - " + TCPIP.LastErrorString, MessageStatus.Attention, "FIASDriver.Connect");
			vResult = False;
			CheckErrorTCP();
		ElsIf TCPIP.Listening Then
			TCPIP.Timeout = 60; // 10 seconds blocking read timeout by default
			vErrorCode = -1;
			StartTimer(TimerReportForNoConnection);
			While vErrorCode <> 0 And TCPIP.Listening Do
				pmLoadDataProcessorAttributes();
				If StopInterface Then
					vResult = False;
					Break;
				EndIf;
				vErrorCode = TCPIP.Accept(TCPIP.Handle);
				If vErrorCode <> 0 And Timer <> Undefined And CheckTimer() Then
					DoMessage(TrimAll(InteractionParameters.Description) + NStr("en = ': PMS -> no connections.'; de = ': PMS -> keine Verbindungen.'; ru = ': PMS -> нет подключений.'"), MessageStatus.Attention,,, "FIASDriver.Connect");
					StartTimer(TimerReportForNoConnection);
				EndIf;
			EndDo;
			If vErrorCode <> 0 Then
				vResult = False;	
			EndIf;
		Else
			vResult = False;	
		EndIf;
		If vResult And InteractionParameters.DebugMode Then
			DoMessage(NStr("en = 'FIAS -> Connection successfull!'; de = 'FIAS -> Verbindung erfolgreich!'; ru = 'FIAS -> Подключение прошло успешно!'"),,,, "FIASDriver.Connect");
		EndIf;
	EndIf;
	If Timer <> Undefined Then
		Timer.StopTimer();
	EndIf;
	Return vResult;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure ReadBuff()
	vReply = "";
	vBuffStr = "";
	vBytesRcv = 1;
	While TCPIP.IsReadable And vBytesRcv > 0 Do
		vBytesRcv = TCPIP.Read(vReply, 1024);
		If vBytesRcv > 0 Then
			vBuffStr = vBuffStr + vReply; 	
		EndIf;
	EndDo;
	vCommandArr = GetCommandArr(vBuffStr);
	For Each vCommandRow In vCommandArr Do
		ProcessEventsFromFIAS(vCommandRow);
		If InteractionParameters.DebugMode Then
			If Not IsLinkAlive Or IsLinkAlive And (StrFind(vCommandRow, "LS|") = 0 And StrFind(vCommandRow, "LA|") = 0) Then   
				DoMessage(NStr("en = 'FIAS -> Data received.'; de = 'FIAS -> Daten empfangen.'; ru = 'FIAS -> Полученные данные.'"),,,GetDataPresentation(vCommandRow), "FIASDriver.ReadBuff");
			EndIf;
		EndIf;
	EndDo;
EndProcedure // Read

// -----------------------------------------------------------------------------
Function GetCommandArr(pDataReceived)
	vCommandArr = New Array();
	If ValueIsFilled(pDataReceived) Then
		vStrArr = StrSplit(pDataReceived, ETX, True);
		For Each vStrRow In vStrArr Do
			vSTXPos = StrFind(vStrRow, STX);
			If vSTXPos > 0 Then
				vCommand = Right(vStrRow, StrLen(vStrRow) - vSTXPos);
				If ValueIsFilled(vCommand) Then
					vCommandArr.Add(vCommand);
				EndIf;
			EndIf;
			If vSTXPos > 1 Then
				If InteractionParameters.DebugMode Then 
					DoMessage(NStr("en = 'FIAS -> Data trash received.'; de = 'FIAS -> Daten empfangen.'; ru = 'FIAS -> Полученные данные.'"),,,GetDataPresentation(Left(vStrRow, vSTXPos)), "FIASDriver.GetCommandArr");
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	Return vCommandArr;
EndFunction // GetMessagePart

// -----------------------------------------------------------------------------
Function WriteBuff(pCommand, pEventName, pIsHTTPRequest = False, rResult = "")
	vResult = True; 
	vCommand = STX + pCommand + ETX;
	If pIsHTTPRequest Then
		rResult = rResult + vCommand;
	Else
		If UseHTTP Then 
			If DataProcessors.FIASDriver.SendQuery(InteractionParameters, vCommand) Then
				If InteractionParameters.DebugMode Then
					If Not IsLinkAlive Or IsLinkAlive And StrFind(pCommand, "LA|") = 0 Then
						DoMessage(NStr("en = 'PMS -> Data send.'; de = 'PMS -> Daten senden.'; ru = 'PMS -> Отправленные данных.'"),, GetDataPresentation(vCommand),, "FIASDriver.WriteBuff");
					EndIf;
				EndIf;	
			Else   
				DoMessage(NStr("en = 'PMS -> FIAS. Unable to send ['; de = 'PMS -> FIAS. Nicht möglich zu senden ['; ru = 'PMS -> FIAS. Невозможно отправить ['") + pEventName + NStr("en = '] command to FIAS!'; de = '] Befehl an FIAS!'; ru = '] команду в FIAS!'"), MessageStatus.Attention, GetDataPresentation(vCommand),, "FIASDriver.WriteBuff");
				vResult = False;
			EndIf;
		Else
			If TCPIP.IsWritable Then 
				LastError = TCPIP.LastError;
				If TCPIP.Write(vCommand, StrLen(vCommand)) = -1 Then
					DoMessage(NStr("en = 'PMS -> FIAS. Unable to send ['; de = 'PMS -> FIAS. Nicht möglich zu senden ['; ru = 'PMS -> FIAS. Невозможно отправить ['") + pEventName + NStr("en = '] command to FIAS!'; de = '] Befehl an FIAS!'; ru = '] команду в FIAS!'") + Chars.LF + NStr("en = 'Error: '; de = 'Error: '; ru = 'Ошибка: '") + TCPIP.LastErrorString, MessageStatus.Attention, GetDataPresentation(vCommand),, "FIASDriver.WriteBuff");
					vResult = False;
				Else
					If LastError <> TCPIP.LastError And TCPIP.LastError <> 0 Then
						DoMessage(NStr("en = 'PMS -> FIAS. Unable to send ['; de = 'PMS -> FIAS. Nicht möglich zu senden ['; ru = 'PMS -> FIAS. Невозможно отправить ['") + pEventName + NStr("en = '] command to FIAS!'; de = '] Befehl an FIAS!'; ru = '] команду в FIAS!'") + Chars.LF + NStr("en = 'Error: '; de = 'Error: '; ru = 'Ошибка: '") + TCPIP.LastErrorString, MessageStatus.Attention, GetDataPresentation(vCommand),, "FIASDriver.WriteBuff");
						vResult = False;
					Else
						If InteractionParameters.DebugMode Then
							If Not IsLinkAlive Or IsLinkAlive And StrFind(pCommand, "LA|") = 0 Then
								DoMessage(NStr("en = 'PMS -> Data send.'; de = 'PMS -> Daten senden.'; ru = 'PMS -> Отправленные данных.'"),, GetDataPresentation(vCommand),, "FIASDriver.WriteBuff");
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			Else
				DoMessage(NStr("en = 'Write buffer not available'; de = 'Schreibpuffer nicht verfügbar'; ru = 'Буфер записи недоступен'"), MessageStatus.Attention,,, "FIASDriver.ProcessesEvents"); 		
				vResult = False;
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // WriteBuff

// -----------------------------------------------------------------------------
Procedure RunHTTP(pParameter)
	If LinkRecords.Count() > 0 Then
		If pParameter <> Undefined Then
			ProcessesEventsCheckOutByRoom(pParameter);
		Else
			ProcessesEvents(GetActiveRoomInterfaceEvents());
		EndIf;
	EndIf;
EndProcedure // RunHTTP

// -----------------------------------------------------------------------------
Procedure ProcessesEventsCheckOutByRoom(pRooms)
	For Each vRoom In pRooms Do
		vData = DataProcessors.FIASDriver.GetGuestCheckOut(InteractionParameters, LinkRecords, Undefined, 0, vRoom, CurrentSessionDate(), False);
		
		If TypeOf(vData) = Type("Array") Then
			If vData.Count() > 0 Then
				For Each vDataRow In vData Do
					vSuccess = WriteBuff(vDataRow, "Guest Check-out"); 
					If Not vSuccess Then
						Break;	
					EndIf;
				EndDo;
			EndIf;
		Else
			vSuccess = WriteBuff(vData, "Guest Check-out");
		EndIf;
		
		If Not vSuccess Then
			Break;	
		EndIf;
	EndDo;
EndProcedure // ProcessesEventsCheckOutByRoom

// -----------------------------------------------------------------------------
Function GetActiveRoomInterfaceEvents() 
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS RoomInterfaceType,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.PeriodOfStayExtentionParameters AS PeriodOfStayExtentionParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.GuestNameChangeParameters AS GuestNameChangeParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.RoomChangeParameters AS RoomChangeParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.CommandToChangeExtraParameters AS CommandToChangeExtraParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.TurnOnParameters AS TurnOnParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.TurnOffParameters AS TurnOffParameters
	|INTO RoomInterfaceTypes
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomInterfaceTypes""
	|	AND VALUETYPE(ExternalSystemsObjectCodesMappings.ObjectRef) = TYPE(Catalog.RoomInterfaceTypes)
	|	AND NOT ExternalSystemsObjectCodesMappings.ObjectRef = VALUE(Catalog.RoomInterfaceTypes.EmptyRef)
	|
	|INDEX BY
	|	RoomInterfaceType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RoomInterfaceStatus.Ref AS Ref,
	|	RoomInterfaceStatus.ParentDoc AS ParentDoc,
	|	RoomInterfaceStatus.Room AS Room,
	|	RoomInterfaceStatus.GuestIndexInRoom AS GuestIndexInRoom,
	|	CASE
	|		WHEN NOT RoomInterfaceStatus.IsCanceled
	|			THEN CASE
	|					WHEN RoomInterfaceStatus.PeriodOfStayExtensionIsRequested
	|						THEN CAST(RoomInterfaceTypes.PeriodOfStayExtentionParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.GuestNameChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.GuestNameChangeParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.RoomChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.RoomChangeParameters AS STRING(100))
	|					WHEN RoomInterfaceStatus.ExtraParametersChangeIsRequested
	|						THEN CAST(RoomInterfaceTypes.CommandToChangeExtraParameters AS STRING(100))
	|					ELSE CAST(RoomInterfaceTypes.TurnOnParameters AS STRING(100))
	|				END
	|		ELSE CAST(RoomInterfaceTypes.TurnOffParameters AS STRING(100))
	|	END AS Command,
	|	RoomInterfaceStatus.ExtraParameters AS ExtraParameters,
	|	RoomInterfaceStatus.MessageDateTime AS MessageDateTime,
	|	RoomInterfaceStatus.Remarks AS Remarks,
	|	RoomInterfaceStatus.Number AS Number,
	|	RoomInterfaceStatus.RoomChangeIsRequested AS IsRoomChange,
	|	RoomInterfaceStatus.OldRoom AS OldRoom
	|FROM
	|	RoomInterfaceTypes AS RoomInterfaceTypes
	|		LEFT JOIN Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|		ON RoomInterfaceTypes.RoomInterfaceType = RoomInterfaceStatus.RoomInterfaceType
	|WHERE
	|	NOT RoomInterfaceStatus.DeletionMark
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckInDate IS NULL
	|	AND RoomInterfaceStatus.ParentDoc.CheckInDate <= &qEndOfCurrentDate
	|	AND NOT RoomInterfaceStatus.ParentDoc.CheckOutDate IS NULL
	|	AND RoomInterfaceStatus.ParentDoc.CheckOutDate >= &qBegOfCurrentDate
	|	AND CASE
	|			WHEN &qHotel <> VALUE(Catalog.Hotels.EmptyRef)
	|				THEN RoomInterfaceStatus.Hotel = &qHotel
	|			ELSE TRUE
	|		END
	|	AND NOT RoomInterfaceStatus.ParentDoc = VALUE(Document.Accommodation.EmptyRef)
	|	AND NOT RoomInterfaceStatus.IsProcessed
	|	AND NOT RoomInterfaceStatus.IsProcessingError
	|
	|ORDER BY
	|	RoomInterfaceStatus.PointInTime";
	vQry.SetParameter("qHotel", InteractionParameters.Hotel);
	vQry.SetParameter("qExternalSystemCode", InteractionParameters.InteractionID);
	vQry.SetParameter("qEndOfCurrentDate", EndOfDay(CurrentSessionDate()));
	vQry.SetParameter("qBegOfCurrentDate", BegOfDay(CurrentSessionDate()));
	Return vQry.Execute().Unload();
EndFunction // GetActiveRoomInterfaceEvents

// -----------------------------------------------------------------------------
Function GetSyncData()
	vQuery = New Query();
	vQuery.Text =
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectRef AS RoomInterfaceType,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.ApplyToAllRoomGuests AS ApplyToAllRoomGuests,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.TurnOnParameters AS TurnOnParameters,
	|	ExternalSystemsObjectCodesMappings.ObjectRef.TurnOffParameters AS TurnOffParameters
	|INTO RoomInterfaceTypes
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.Hotel = &qHotel
	|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""RoomInterfaceTypes""
	|	AND VALUETYPE(ExternalSystemsObjectCodesMappings.ObjectRef) = TYPE(Catalog.RoomInterfaceTypes)
	|	AND NOT ExternalSystemsObjectCodesMappings.ObjectRef = VALUE(Catalog.RoomInterfaceTypes.EmptyRef)
	|	AND ExternalSystemsObjectCodesMappings.ObjectRef.TurnOnParameters LIKE ""GI%""
	|	AND ExternalSystemsObjectCodesMappings.ObjectRef.TurnOffParameters LIKE ""GO%""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Rooms.Ref AS Room
	|INTO AllRooms
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND NOT Rooms.IsVirtual
	|	AND Rooms.Owner = &qHotel
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accommodations.Room AS Room,
	|	Accommodations.Ref AS Ref,
	|	Accommodations.Guest AS Guest,
	|	Accommodations.CheckInDate AS CheckInDate,
	|	Accommodations.CheckOutDate AS CheckOutDate,
	|	Accommodations.AccommodationTemplate AS AccommodationTemplate
	|INTO InhouseGuests
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.Hotel = &qHotel
	|	AND Accommodations.Posted
	|	AND Accommodations.AccommodationStatus.IsActive
	|	AND Accommodations.AccommodationStatus.IsInHouse
	|	AND BEGINOFPERIOD(Accommodations.CheckOutDate, DAY) >= &qBegOfCurrentDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllRooms.Room AS Room,
	|	InhouseGuests.Ref AS Accommodation,
	|	CASE
	|		WHEN InhouseGuests.Ref IS NULL
	|			THEN RoomInterfaceTypes.TurnOffParameters
	|		ELSE RoomInterfaceTypes.TurnOnParameters
	|	END AS Command
	|FROM
	|	AllRooms AS AllRooms
	|		LEFT JOIN InhouseGuests AS InhouseGuests
	|		ON AllRooms.Room = InhouseGuests.Room
	|		LEFT JOIN RoomInterfaceTypes AS RoomInterfaceTypes
	|		ON (RoomInterfaceTypes.ApplyToAllRoomGuests
	|				OR NOT RoomInterfaceTypes.ApplyToAllRoomGuests
	|					AND NOT InhouseGuests.AccommodationTemplate.Code IS NULL)
	|WHERE
	|	CASE
	|			WHEN NOT InhouseGuests.Ref IS NULL
	|				THEN NOT RoomInterfaceTypes.RoomInterfaceType IS NULL
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	AllRooms.Room.SortCode";
	vQuery.SetParameter("qHotel", InteractionParameters.Hotel);
	vQuery.SetParameter("qExternalSystemCode", InteractionParameters.InteractionID);
	vQuery.SetParameter("qBegOfCurrentDate", CurrentSessionDate());
	Return vQuery.Execute().Unload();
EndFunction // GetSyncData

// -----------------------------------------------------------------------------
Function GetDataPresentation(Val pStr)
	pStr = StrReplace(pStr, STX, "[STX]");
	pStr = StrReplace(pStr, ETX, "[ETX]");
	Return pStr;
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function GetRoomByCode(pRoomCode)
	// Find room by code
	vRoom = Catalogs.Rooms.EmptyRef();
	If ValueIsFilled(pRoomCode) Then  
		vRoom = GetObjectRefByExternalSystemCode("Rooms", TrimR(pRoomCode));
		If Not ValueIsFilled(vRoom) Then 
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Rooms.Ref
			|FROM
			|	Catalog.Rooms AS Rooms
			|WHERE
			|	Rooms.Description = &qRoomCode
			|	AND (NOT Rooms.DeletionMark)
			|	AND (NOT Rooms.IsFolder)
			|	AND Rooms.Owner = &qHotel";
			vQry.SetParameter("qRoomCode", pRoomCode);
			vQry.SetParameter("qHotel", InteractionParameters.Hotel);
			vRooms = vQry.Execute().Unload();
			If vRooms.Count() > 0 Then
				vRoom = vRooms.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	Return vRoom;
EndFunction // GetRoomByCode

// -----------------------------------------------------------------------------
Function GetObjectRefByExternalSystemCode(pObjectTypeName, pObjectExternalCode)
	vObjectRef = Undefined;
	If ValueIsFilled(pObjectExternalCode) Then
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	ExternalSystemsObjectCodesMappings.ObjectRef AS ObjectRef
		|FROM
		|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
		|WHERE
		|	(ExternalSystemsObjectCodesMappings.Hotel = &qHotel
		|			OR ExternalSystemsObjectCodesMappings.Hotel = VALUE(Catalog.Hotels.EmptyRef))
		|	AND ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
		|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = &qObjectTypeName
		|	AND ExternalSystemsObjectCodesMappings.ObjectExternalCode = &qObjectExternalCode";
		vQry.SetParameter("qHotel", InteractionParameters.Hotel);
		vQry.SetParameter("qExternalSystemCode", TrimAll(InteractionParameters.InteractionID));
		vQry.SetParameter("qObjectTypeName", TrimAll(pObjectTypeName));
		vQry.SetParameter("qObjectExternalCode", TrimAll(pObjectExternalCode));
		vObjects = vQry.Execute().Unload();
		If vObjects.Count() = 1 Then
			vObjectRef = vObjects.Get(0).ObjectRef;
		EndIf;
	EndIf;
	Return vObjectRef;
EndFunction // GetObjectRefByExternalSystemCode	

// -----------------------------------------------------------------------------
Function GetRoomInterfaceStatus(pAccommodation, pTurnOnParameters = "", pTurnOffParameters = "", pPeriodOfStayExtentionParameters = "", pGuestNameChangeParameters = "", pMessageTime = '00010101')
	vResult = Documents.RoomInterfaceStatus.EmptyRef();
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	RoomInterfaceStatus.Ref AS Ref
	|FROM
	|	Document.RoomInterfaceStatus AS RoomInterfaceStatus
	|WHERE
	|	CASE
	|			WHEN &qMessageDateTime <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN RoomInterfaceStatus.MessageDateTime = &qMessageDateTime
	|			ELSE TRUE
	|		END
	|	AND RoomInterfaceStatus.ParentDoc = &qParentDoc
	|	AND CASE
	|			WHEN &qTurnOnFilled <> """"
	|				THEN RoomInterfaceStatus.RoomInterfaceType.TurnOnParameters LIKE &qTurnOnParameters
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qTurnOffFilled <> """"
	|				THEN RoomInterfaceStatus.RoomInterfaceType.TurnOffParameters LIKE &qTurnOffParameters
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qPeriodOfStayExtentionParameters <> """"
	|				THEN RoomInterfaceStatus.RoomInterfaceType.PeriodOfStayExtentionParameters LIKE &qPeriodOfStayExtentionParameters
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qGuestNameChangeParameters <> """"
	|				THEN RoomInterfaceStatus.RoomInterfaceType.GuestNameChangeParameters LIKE &qGuestNameChangeParameters
	|			ELSE TRUE
	|		END
	|	AND NOT RoomInterfaceStatus.DeletionMark";
	
	vQuery.SetParameter("qParentDoc", 						pAccommodation);
	vQuery.SetParameter("qMessageDateTime", 				pMessageTime);
	vQuery.SetParameter("qTurnOnParameters", 				pTurnOnParameters);
	vQuery.SetParameter("qTurnOffParameters", 				pTurnOffParameters);
	vQuery.SetParameter("qPeriodOfStayExtentionParameters", pPeriodOfStayExtentionParameters);
	vQuery.SetParameter("qGuestNameChangeParameters", 		pGuestNameChangeParameters);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		vResult = vRow.Ref;
	EndDo;
	
	Return vResult;
EndFunction // GetRoomInterfaceStatus

// -----------------------------------------------------------------------------
Function GetAccommodationByRoomAndDate(pRoom, pDate = Undefined)
	vResult = Documents.Accommodation.EmptyRef();
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Accommodation.Ref AS Ref
	|FROM
	|	Document.Accommodation AS Accommodation
	|WHERE
	|	NOT Accommodation.DeletionMark
	|	AND Accommodation.Posted
	|	AND Accommodation.Room.Description = &qRoom
	|	AND Accommodation.Hotel = &qHotel
	|	AND Accommodation.AccommodationStatus.IsActive
	|	AND Accommodation.AccommodationStatus.IsInHouse
	|	AND (Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Room)
	|			OR Accommodation.AccommodationType.Type = VALUE(Enum.AccomodationTypes.Beds))
	|	AND CASE
	|			WHEN &qDate <> DATETIME(1, 1, 1, 0, 0, 0)
	|				THEN &qDate BETWEEN Accommodation.CheckInDate AND Accommodation.CheckOutDate
	|			ELSE TRUE
	|		END
	|	AND Accommodation.AccommodationTemplate <> VALUE(Catalog.AccommodationTemplates.EmptyRef)
	|
	|ORDER BY
	|	Accommodation.Date DESC";
	
	
	vQuery.SetParameter("qHotel", InteractionParameters.Hotel);	
	vQuery.SetParameter("qDate", pDate);
	vQuery.SetParameter("qRoom", pRoom);
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		vResult = vRow.Ref;	
	EndDo;
	
	Return vResult;
EndFunction // GetAccommodationByRoomAndDate

// -----------------------------------------------------------------------------
Procedure ProcessesPriorityEvents()			
	vRow = InformationRegisters.FIASPriorityEvents.Select(New Structure("InteractionParameters", InteractionParameters));
	While vRow.Next() Do
		If Not vRow.IsCommandSent And Not vRow.IsResponseReceived Then	
			vSuccess = False;
			vEventName = ""; 
			vData = "";
			
			vCommand = DataProcessors.FIASDriver.ParsResponse(vRow.Request);
			
			If vCommand["Command"] <> Undefined And vCommand.Count() > 0 Then
				If vCommand["Command"] = "KR" Or vCommand["Command"] = "KD" Or vCommand["Command"] = "KM" Or vCommand["Command"] = "KZ" Or vCommand["Command"] = "GI" Then
					vData = DataProcessors.FIASDriver.GetPriorityRequest(LinkRecords, vCommand["Command"], vCommand);
					If vCommand["Command"] = "KR" Then 
						vEventName = "Key request";
					ElsIf vCommand["Command"] = "KD" Then 
						vEventName = "Key delete";	
					ElsIf vCommand["Command"] = "KM" Then
						vEventName = "Key Data Change";	
					ElsIf vCommand["Command"] = "KZ" Then
						vEventName = "Key Read";
					ElsIf vCommand["Command"] = "GI" Then
						vEventName = "Guest Check-in";	
					EndIf; 
				EndIf;
			EndIf;
			
			If ValueIsFilled(vData) And ValueIsFilled(vEventName) Then
				vSuccess = WriteBuff(vData, vEventName);	
			EndIf;
			
			vRM = vRow.GetRecordManager();
			If vSuccess Then
				vRM.IsCommandSent = True;
				If vCommand["Command"] <> "GI" Then
					vRM.IsResponseReceived = False;
				Else
					vRM.IsResponseReceived = True;
					vRM.AnswerStatus = "OK";
				EndIf;
			Else
				vRM.IsCommandSent = True;
				vRM.IsResponseReceived = True;
				vRM.AnswerStatus = "ER";
			EndIf;
			vRM.Write(True);
		EndIf;	
	EndDo;
EndProcedure // ProcessesPriorityEvents

// -----------------------------------------------------------------------------
Procedure ProcessesEvents(pActiveEvents, pIsHTTPRequest = False, rResult = "")
	For Each vEventRow In pActiveEvents Do
		vSuccess = False;
		vIsError = False; 
		vErrorMsg = "";
		vDataMap = New Map();
		
		vCommand = vEventRow.Command;
		
		vRoom = Catalogs.Rooms.EmptyRef();
		vParentDoc = Documents.Accommodation.EmptyRef();
		If ValueIsFilled(vEventRow.ParentDoc) Then
			vParentDoc = vEventRow.ParentDoc; 	
		EndIf;
		If ValueIsFilled(vEventRow.Room) Then
			vRoom = vEventRow.Room; 	
		EndIf;
		
		vOldRoom = Catalogs.Rooms.EmptyRef();
		If vEventRow.IsRoomChange Then
			vOldRoom = vEventRow.OldRoom;
		EndIf;
		
		vGuestIndexInRoom = vEventRow.GuestIndexInRoom;
		
		vDataMap = DataProcessors.FIASDriver.ParsResponse(vCommand);
		
		If vDataMap.Count() > 0 And vDataMap["Command"] <> Undefined Then
			If StrFind(vDataMap["Command"], "GI") <> 0 Or StrFind(vDataMap["Command"], "GO") <> 0 Or StrFind(vDataMap["Command"], "GC") <> 0 Or StrFind(vDataMap["Command"], "RE") <> 0 Then
				If Not ValueIsFilled(vRoom) Then
					vErrorMsg = NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
				If Not ValueIsFilled(vParentDoc) Then
					vErrorMsg = vErrorMsg + NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
				If StrFind(vDataMap["Command"], "RE") <> 0 Then
					If Not ValueIsFilled(vDataMap["CS"]) And Not ValueIsFilled(vDataMap["DN"]) And Not ValueIsFilled(vDataMap["MR"]) And Not ValueIsFilled(vDataMap["TV"]) Then
						vErrorMsg = vErrorMsg + NStr("en = 'Command parameters not specified.'; de = 'Befehlsparameter nicht angegeben.'; ru = 'Параметры команды не указаны.'") + Chars.LF;
						vIsError = True;	
					EndIf;
				EndIf;
			ElsIf StrFind(vDataMap["Command"], "WR") <> 0 Or StrFind(vDataMap["Command"], "WC") <> 0 Then
				If Not ValueIsFilled(vRoom) Then
					vErrorMsg = NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
				If Not ValueIsFilled(vEventRow.MessageDateTime) Then
					vErrorMsg = vErrorMsg + NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf; 
			ElsIf StrFind(vDataMap["Command"], "KM") <> 0 Or StrFind(vDataMap["Command"], "KD") <> 0 Then
				If Not ValueIsFilled(vRoom) Then
					vErrorMsg = NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
				If Not ValueIsFilled(vParentDoc) Then
					vErrorMsg = vErrorMsg + NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;		
			Else
				vErrorMsg = NStr("en = 'Command not found.'; de = 'Befehl nicht gefunden.'; ru = 'Команда не найдена.'")  + Chars.LF;
				vIsError = True;
			EndIf;
		Else
			vErrorMsg = NStr("en = 'Command error'; de = 'Befehlsfehler'; ru = 'Ошибка команды'");
			vIsError = True;
		EndIf;	
		
		If vIsError Then
			If ValueIsFilled(vErrorMsg) Then 
				DoMessage(vErrorMsg + vEventRow.Ref, MessageStatus.Attention, vDataMap,, "FIASDriver.ProcessesEvents");
			EndIf;
			vStsObj = vEventRow.Ref.GetObject();
			vStsObj.IsProcessingError = True;
			vStsObj.ErrorMessage = vErrorMsg; 
			vStsObj.Write(DocumentWriteMode.Write);
			Continue;
		EndIf;	
		
		vCommandArr = StrSplit(vDataMap["Command"], ";", False); 
		
		For Each vRow In vCommandArr Do
			vData = New Array();
			vEventName = "";
			
			If vRow = "GI" Then
				vData = DataProcessors.FIASDriver.GetGuestCheckIn(InteractionParameters, LinkRecords, DoDataTransliteration, vParentDoc, vGuestIndexInRoom, vRoom, CurrentSessionDate(), vDataMap["MR"], vDataMap["NP"], vDataMap["TV"], vDataMap["VR"], False);
				vEventName = "Guest Check-in";
			ElsIf vRow = "GO" Then
				vData = DataProcessors.FIASDriver.GetGuestCheckOut(InteractionParameters, LinkRecords, vParentDoc, vGuestIndexInRoom, vRoom, CurrentSessionDate(), False);
				vEventName = "Guest Check-out";
			ElsIf vRow = "GC" Then
				vData = DataProcessors.FIASDriver.GetGuestCheckChange(InteractionParameters, LinkRecords, DoDataTransliteration, vParentDoc, vGuestIndexInRoom, vRoom, CurrentSessionDate(), vDataMap["MR"], vDataMap["NP"], vDataMap["TV"], vDataMap["VR"], vOldRoom);
				vEventName = "Guest data change";
			ElsIf vRow = "RE" Then
				vData = DataProcessors.FIASDriver.GetRoomEquipmentStatus(InteractionParameters, LinkRecords, vRoom, vParentDoc, vGuestIndexInRoom, vDataMap["CS"], vDataMap["DN"], vDataMap["ML"], vDataMap["MR"], vDataMap["TV"]);
				vEventName = "Room equipment status";
			ElsIf vRow = "WR" Then
				vData = DataProcessors.FIASDriver.GetWakeupRequest(InteractionParameters, LinkRecords, vRoom, vEventRow.MessageDateTime);
				vEventName = "Wakeup request";
			ElsIf vRow = "WC" Then
				vData = DataProcessors.FIASDriver.GetWakeupClear(InteractionParameters, LinkRecords, vRoom, vEventRow.MessageDateTime);
				vEventName = "Wakeup answer";
			ElsIf vRow = "KM" Then
				vData = DataProcessors.FIASDriver.GetKeyDataChange(InteractionParameters, LinkRecords, DoDataTransliteration, vParentDoc, vGuestIndexInRoom, vRoom, CurrentSessionDate(), ?(ValueIsFilled(vOldRoom), vOldRoom, vRoom), "BJ");
				vEventName = "Key Data Change";	
			ElsIf vRow = "KD" Then
				vData = DataProcessors.FIASDriver.GetKeyDelete(InteractionParameters, LinkRecords, vParentDoc, vGuestIndexInRoom, vRoom, CurrentSessionDate(), "BJ");
				vEventName = "Key Delete";
			EndIf;
			
			If TypeOf(vData) = Type("Array") Then
				If vData.Count() > 0 And ValueIsFilled(vEventName) Then
					For Each vDataRow In vData Do
						vSuccess = WriteBuff(vDataRow, vEventName, pIsHTTPRequest, rResult); 
						If Not vSuccess Then
							Break;	
						EndIf;
					EndDo;
				EndIf;
			Else
				vSuccess = WriteBuff(vData, vEventName, pIsHTTPRequest, rResult);	
			EndIf;
		EndDo;
		
		If Not vSuccess Then
			Break;	
		EndIf;
		
		// Set processed status to the interface record
		If vSuccess Then
			vStsObj = vEventRow.Ref.GetObject();
			vStsObj.IsProcessed = True;
			vStsObj.IsProcessingError = False;
			vStsObj.ErrorMessage = "";
			vStsObj.Write(DocumentWriteMode.Write);
			If vStsObj.IsProcessed And vStsObj.IsCanceled Then
				vStsObj.SetDeletionMark(True);	
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ProcessesEvents

// -----------------------------------------------------------------------------
Procedure ProcessEventsFromFIAS(pCommands, pIsHTTPRequest = False, rResult = "")
	vCommands = StrSplit(pCommands, ETX + STX, False);
	For Each vCommand In vCommands Do
		vData = DataProcessors.FIASDriver.ParsResponse(vCommand);
		If vData["Command"] <> Undefined Then
			If vData["Command"] = "LS" Then
				If IsLinkAlive Then
					WriteBuff(DataProcessors.FIASDriver.GetLinkAlive(CurrentSessionDate()), "Link Alive", pIsHTTPRequest, rResult);
				ElsIf Not SendLinkStart Then
					If WriteBuff(DataProcessors.FIASDriver.GetLinkStart(CurrentSessionDate()), "Link Start", pIsHTTPRequest, rResult) Then
						SendLinkStart = True;
						LinkRecords.Clear();
						pmSaveDataProcessorAttributes();
					EndIf;
				EndIf;
			ElsIf vData["Command"] = "LA" Then
				If WriteBuff(DataProcessors.FIASDriver.GetLinkAlive(CurrentSessionDate()), "Link Alive", pIsHTTPRequest, rResult) Then
					IsLinkAlive = True; 
					pmSaveDataProcessorAttributes();
				EndIf;
			ElsIf vData["Command"] = "LE" Then
				If Not SendLinkEnd Then
					If WriteBuff(DataProcessors.FIASDriver.GetLinkEnd(CurrentSessionDate()), "Link End", pIsHTTPRequest, rResult) Then
						SendLinkEnd = True;	
					EndIf;
				EndIf;  
				SendLinkStart = False;
				IsLinkAlive = False;
				LinkRecords.Clear();
				pmSaveDataProcessorAttributes();
			ElsIf vData["Command"] = "LR" Then
				FillLinkRecords(vData["RI"], vData["FL"]);
			ElsIf vData["Command"] = "LD" Then
				// Link description 
			ElsIf IsLinkAlive Then
				If vData["Command"] = "DR" Then
					vCount = 0;
					While InteractionParameters.FullSynchronizationIsActive And vCount <> 12 Do
						cmWait(5);
						vCount = vCount + 1;
					EndDo;
					ChangeFlagFullSynchronizationIsActive(True); 
					Try
						ProcessesEvents(GetActiveRoomInterfaceEvents(), pIsHTTPRequest, rResult);
						If WriteBuff(DataProcessors.FIASDriver.GetResyncStart(CurrentSessionDate()), "Database Resync start", pIsHTTPRequest, rResult) Then
							ProcessesSyncEvents(GetSyncData(), pIsHTTPRequest, rResult);	
							WriteBuff(DataProcessors.FIASDriver.GetResyncEnd(CurrentSessionDate()), "Database Resync end", pIsHTTPRequest, rResult)
						EndIf;
					Except
						vErrorInfo = ErrorDescription(); 
						ChangeFlagFullSynchronizationIsActive(False);
						Raise vErrorInfo;
					EndTry;
					ChangeFlagFullSynchronizationIsActive(False);
				ElsIf vData["Command"] = "RE" Then
					ProcessesRoomDataEvents(vData);
				ElsIf vData["Command"] = "WA" Then 
					SetWakeupAnswer(vData);
				ElsIf vData["Command"] = "PS" Then
					SetPostingSimple(vData, pIsHTTPRequest, rResult);
				ElsIf vData["Command"] = "KA" Or vData["Command"] = "KZ" Then
					ProcessesKeyDataEvents(vData, vCommand);	
				Else
					If InteractionParameters.DebugMode Then
						DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, GetDataPresentation(vCommand), "FIASDriver.ProcessEventsFromFIAS");
					EndIf;
				EndIf;
			Else
				If InteractionParameters.DebugMode Then
					DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, GetDataPresentation(vCommand), "FIASDriver.ProcessEventsFromFIAS");
				EndIf;	
			EndIf;
		Else
			If InteractionParameters.DebugMode Then
				DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, GetDataPresentation(vCommand), "FIASDriver.ProcessEventsFromFIAS");
			EndIf;	
		EndIf;	
	EndDo;
EndProcedure // ProcessEventsFromFIAS

// -----------------------------------------------------------------------------
Procedure ProcessesSyncEvents(pSyncDataList, pIsHTTPRequest = False, rResult = "")
	For Each vSyncData In pSyncDataList Do
		vSuccess = False;
		vEventName = "";
		vDataMap = New Map();	
		vErrorMsg = "";
		vIsError = False;
		vDataMap = DataProcessors.FIASDriver.ParsResponse(vSyncData.Command);
		
		If vDataMap.Count() > 0 And vDataMap["Command"] <> Undefined Then
			vRoom = Catalogs.Rooms.EmptyRef();
			If ValueIsFilled(vSyncData.Accommodation) And ValueIsFilled(vSyncData.Accommodation.Room) Then
				vRoom = vSyncData.Accommodation.Room; 	
			ElsIf ValueIsFilled(vSyncData.Room) Then
				vRoom = vSyncData.Room; 	
			EndIf;
			
			If StrFind(vDataMap["Command"], "GI") <> 0 Then
				If Not ValueIsFilled(vRoom) Then
					vErrorMsg = NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
				If Not ValueIsFilled(vSyncData.Accommodation) Then
					vErrorMsg = vErrorMsg + NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
			ElsIf StrFind(vDataMap["Command"], "GO") <> 0 Then
				If Not ValueIsFilled(vRoom) Then
					vErrorMsg = NStr("en = 'Room not specified.'; de = 'Zimmer nicht angegeben.'; ru = 'Номер не указан.'") + Chars.LF;
					vIsError = True;
				EndIf;
			Else
				vErrorMsg = NStr("en = 'Command not found.'; de = 'Befehl nicht gefunden.'; ru = 'Команда не найдена.'")  + Chars.LF;
				vIsError = True;
			EndIf;
		Else
			vErrorMsg = NStr("en = 'Command error'; de = 'Befehlsfehler'; ru = 'Ошибка команды'");
			vIsError = True;
		EndIf;
		
		If vIsError Then
			If ValueIsFilled(vErrorMsg) Then 
				DoMessage(vErrorMsg, MessageStatus.Attention,,, "FIASDriver.ProcessesSyncEvents");
			EndIf;
			Continue;
		EndIf;  
		
		vIndex = -1;
		vBase = vSyncData.Accommodation;
		If ValueIsFilled(vSyncData.Accommodation) Then
			vOneRoomGuests = cmGetOneRoomAccommodations(vBase.Room, vBase.GuestGroup, vBase.CheckInDate, vBase.CheckOutDate, vBase.Number);
			For Each vOneRoomGuestsRow In vOneRoomGuests Do
				If vOneRoomGuestsRow.Ref = vBase Then
					vIndex = vOneRoomGuests.IndexOf(vOneRoomGuestsRow) + 1;
					Break;
				EndIf;
			EndDo;
			If vIndex = -1 Then
				If vOneRoomGuests.Count() > 0 Then
					vIndex = vOneRoomGuests.Count() + 1;
				Else
					vIndex = 1;
				EndIf;
			EndIf;	
		EndIf;
		
		vDataArr = New Array;
		
		If StrFind(vDataMap["Command"], "GI") <> 0 Then
			vDataArr = DataProcessors.FIASDriver.GetGuestCheckIn(InteractionParameters, LinkRecords, DoDataTransliteration, vSyncData.Accommodation, vIndex, vRoom, CurrentSessionDate(), vDataMap["MR"], vDataMap["NP"], vDataMap["TV"], vDataMap["VR"], True);
			vEventName = "Guest Check-in sync";
		ElsIf StrFind(vDataMap["Command"], "GO") <> 0 Then
			vDataArr = DataProcessors.FIASDriver.GetGuestCheckOut(InteractionParameters, LinkRecords, vSyncData.Accommodation, vIndex, vRoom, CurrentSessionDate(), True);
			vEventName = "Guest Check-out sync";
		EndIf;
		
		If vDataArr.Count() > 0 And ValueIsFilled(vEventName) Then
			For Each vData In vDataArr Do
				vSuccess = WriteBuff(vData, vEventName, pIsHTTPRequest, rResult); 
				If Not vSuccess Then
					Break;	
				EndIf;   
			EndDo;
		EndIf;
	EndDo;
EndProcedure // ProcessesSyncEvents

// -----------------------------------------------------------------------------
Procedure ProcessesRoomDataEvents(pData)
	vOperationTime = CurrentSessionDate();
	If pData["RN"] <> Undefined And Not IgnoreRoomStatusChanges Then
		vCommandProcessed = False;
		vRoom = GetRoomByCode(pData["RN"]);
		If ValueIsFilled(vRoom) Then
			If pData["RS"] <> Undefined Then 
				If InteractionParameters.DebugMode Then
					DoMessage(NStr("en = 'FIAS -> Set room status.'; de = 'FIAS -> Zimmerstatus setzen.'; ru = 'FIAS -> Установить статус номера.'"), MessageStatus.Information,, pData, "FIASDriver.ProcessesRoomDataEvents");
				EndIf;
				vRoomStatus = GetObjectRefByExternalSystemCode("RoomStatuses", pData["RS"]); 
				If ValueIsFilled(vRoomStatus) Then
					// Skip updating room status if it was set after phone call time
					SetRoomStatus(vRoom, vRoomStatus, pData["ID"], vOperationTime);
				Else
					DoMessage(NStr("en = 'FIAS -> failed to get room status by code: '; de = 'FIAS -> Fehler beim Abrufen des Zimmerstatus per Code: '; ru = 'FIAS -> не удалось получить статус номера по коду: '") + GetDataPresentation(pData["RS"]), MessageStatus.Attention,, pData, "FIASDriver.ProcessesRoomDataEvents");
				EndIf;
				vCommandProcessed = True;
			EndIf;
			If pData["VM"] <> Undefined Then
				vPhoneNumber = GetPhoneNumber(vRoom, pData["RN"]);
				If ValueIsFilled(vPhoneNumber) Then
					vPhoneNumberObj = vPhoneNumber.GetObject();
					If pData["VM"] = "Y" Then
						vPhoneNumberObj.MessageWaiting = True;
					ElsIf pData["VM"] = "N" Then
						vPhoneNumberObj.MessageWaiting = False;	
					ElsIf StrLen(pData["VM"]) = 4 Then
						vUnread = TrimAll(Left(pData["VM"], 2));
						If ValueIsFilled(vUnread) And cmIsNumber(vUnread) Then
							If Number(vUnread) > 0 Then
								vPhoneNumberObj.MessageWaiting = True;	
							Else
								vPhoneNumberObj.MessageWaiting = False;	
							EndIf;
						EndIf;
					EndIf;
					vPhoneNumberObj.Write();
				EndIf;
				vCommandProcessed = True;
			EndIf;
			If Not vCommandProcessed Then
				If InteractionParameters.DebugMode Then
					DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, pData, "FIASDriver.ProcessesRoomDataEvents");
				EndIf;	
			EndIf;
		Else
			DoMessage(NStr("en = 'Failed to find room by its code: '; de = 'Zimmer konnte nicht anhand seines Codes gefunden werden: '; ru = 'Не удалось найти номер по коду: '") + GetDataPresentation(pData["RN"]), MessageStatus.Attention,, pData, "FIASDriver.ProcessesRoomDataEvents");
		EndIf;
	Else
		If InteractionParameters.DebugMode Then
			DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, pData, "FIASDriver.ProcessesRoomDataEvents");
		EndIf;	
	EndIf;
EndProcedure // ProcessesRoomDataEvents

// -----------------------------------------------------------------------------
Procedure SetWakeupAnswer(pData)
	If ValueIsFilled(pData["RN"]) And ValueIsFilled(pData["DA"]) And ValueIsFilled(pData["TI"]) And ValueIsFilled(pData["AS"]) Then
		vData = GetDateTime(pData["DA"], pData["TI"]);
		If ValueIsFilled(vData) Then
			vRoom = GetRoomByCode(pData["RN"]);
			If ValueIsFilled(vRoom) Then
				vAccommodation = GetAccommodationByRoomAndDate(vRoom, vData);
				If ValueIsFilled(vAccommodation) Then
					vRoomInterfaceStatus = GetRoomInterfaceStatus(vAccommodation, "WR%",,,, vData);
					If ValueIsFilled(vRoomInterfaceStatus) Then
						vRoomInterfaceStatusObj = vRoomInterfaceStatus.GetObject();
						vRoomInterfaceStatusObj.Remarks = vRoomInterfaceStatusObj.Remarks + Chars.LF + "Wakeup answer code: " + pData["AS"] + "; Description: " + GetCodeDescription(pData["AS"]);
						If pData["AS"] = "OK" or  pData["AS"] = "BY" Then
							vRoomInterfaceStatusObj.MessageIsDelivered 		= True;
							vRoomInterfaceStatusObj.MessageDeliveryDateTime = CurrentSessionDate();
						ElsIf AlertAboutWakeUpStatus Then
							vMessageObj 				= Documents.Message.CreateDocument();
							vMessageObj.Type			= Enums.MessageTypes.Message;
							vMessageObj.Date			= CurrentSessionDate();
							vMessageObj.ByObject 		= vAccommodation;
							If ValueIsFilled(vAccommodation.Hotel.ReservationDepartment) Then
								vMessageObj.ForDepartment = vAccommodation.Hotel.ReservationDepartment;
							EndIf;
							vMessageObj.Remarks = "Description: " + GetCodeDescription(pData["AS"]);
							vMessageObj.PopUp = True;
							vMessageObj.Write(DocumentWriteMode.Posting);
						EndIf;
						vRoomInterfaceStatusObj.Write();
					Else
						DoMessage(NStr("en = 'FIAS -> Failed to find room interface status by its accommodation and date.'; de = 'FIAS -> Der Status der Zimmerschnittstelle konnte nicht anhand der Unterkunft und des Datums gefunden werden.'; ru = 'FIAS -> Не удалось определить статус интерфейса номера по ее размещению и дате.'"), MessageStatus.Attention,, pData, "FIASDriver.SetWakeupAnswer");	
					EndIf;
				Else
					DoMessage(NStr("en = 'FIAS -> Failed to find Accommodation by its room '; de = 'FIAS -> Unterkunft nicht anhand des Zimmers gefunden '; ru = 'FIAS -> Не удалось найти размещение по номеру '") + GetDataPresentation(pData["RN"]) + NStr("en = 'and date '; de = 'und Datum '; ru = 'и дате' ") + Format(vData, "DF='dd.MM.yyyy hh:mm:ss'"), MessageStatus.Attention,, pData, "FIASDriver.SetWakeupAnswer");	
				EndIf;
			Else
				DoMessage(NStr("en = 'Failed to find room by its code: '; de = 'Zimmer konnte nicht anhand seines Codes gefunden werden: '; ru = 'Не удалось найти номер по коду: '") + GetDataPresentation(pData["RN"]), MessageStatus.Attention,, pData, "FIASDriver.SetWakeupAnswer");
			EndIf;
		Else
			DoMessage(NStr("en = 'FIAS -> Is date error: '; de = 'FIAS -> Ist Datumsfehler: '; ru = 'FIAS -> Ошибка даты: '") + GetDataPresentation(pData["DA"]) + GetDataPresentation(pData["TI"]), MessageStatus.Attention,, pData, "FIASDriver.SetWakeupAnswer");	
		EndIf;
	Else
		If InteractionParameters.DebugMode Then
			DoMessage(NStr("en = 'FIAS -> Command received and ignored.'; de = 'FIAS -> Befehl empfangen und ignoriert.'; ru = 'FIAS -> Команда получена и проигнорирована.'"), MessageStatus.Information,, pData, "FIASDriver.SetWakeupAnswer");
		EndIf;
	EndIf;
EndProcedure // SetWakeupAnswer

// -----------------------------------------------------------------------------
Procedure SetPostingSimple(pData, pIsHTTPRequest = False, rResult = "")
	If ValueIsFilled(pData["RN"]) And ValueIsFilled(pData["PT"]) And ValueIsFilled(pData["DA"]) And ValueIsFilled(pData["TI"]) Then
		vRoom = GetRoomByCode(pData["RN"]);
		If ValueIsFilled(vRoom) Then
			vDate = GetDateTime(pData["DA"], pData["TI"]);
			If ValueIsFilled(vDate) Then
				If pData["PT"] = "C" Then
					If UploadPhoneCalls Then
						vCallTime = vDate;
						vCallDurationInSecs = 0;
						If ValueIsFilled(pData["DU"]) Then
							vDurationDate = GetDateTime(, pData["DU"], True);
							If ValueIsFilled(vDurationDate) Then
								vCallDurationInSecs = vDurationDate - '00010101'; 	
							EndIf;
						EndIf;
						vCallDuration = Round(vCallDurationInSecs/60, 7);
						vCallDurationInMins = Int(vCallDurationInSecs/60);
						vCallDurationInSecs = vCallDurationInSecs - vCallDurationInMins*60;
						vCallFrom = TrimAll(pData["RN"]);
						vCallTo = "";
						If ValueIsFilled(pData["DD"]) Then
							vCallTo = TrimAll(pData["DD"]);
						EndIf;
						vCallSum = 0;
						If ValueIsFilled(pData["TA"]) And cmIsNumber(pData["TA"]) Then 
							vCallSum = Number(pData["TA"]);
						EndIf;
						vCallRegion = "";
						If ValueIsFilled(pData["CT"]) Then
							vCallRegion = TrimAll(pData["CT"]);
						EndIf;
						vCallType = "";
						If ValueIsFilled(pData["PC"]) Then
							vCallType = TrimAll(pData["PC"]);
						EndIf;
						vCallDescription  = TrimAll(vCallRegion + " #") + TrimAll(vCallTo) + " - " + Format(vCallTime, "DF='dd.MM.yyyy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "''";
						// Build call data presentation string
						vCallData = Format(vCallTime, "DF='dd.MM.yyyy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "'', " + vCallFrom + " > " + vCallTo + " " + vCallRegion;
						// Check call date
						If vCallTime > '19000101' And vCallTime < EndOfDay('21000101') Then
							// Try to find from phone number
							vPhoneNumber = GetPhoneNumber(vRoom, pData["RN"]);
							If Not ValueIsFilled(vPhoneNumber) Then
								vPhoneNumberObj = Catalogs.PhoneNumbers.CreateItem();
								vPhoneNumberObj.Room = vRoom;
								vPhoneNumberObj.Description = pData["RN"];
								vPhoneNumberObj.PhoneNumber = pData["RN"];
								vPhoneNumberObj.Remarks = NStr("en='New! Created by load phone calls procedure.';ru='Новый! Добавлен при загрузке.';de='Neu! Hinzugefügt beim Lasen.'");
								vPhoneNumberObj.Owner = InteractionParameters.Hotel;
								vPhoneNumberObj.Parent = NewPhoneNumbersFolder;
								vPhoneNumberObj.Write();
								vPhoneNumber = vPhoneNumberObj.Ref;
								DoMessage(NStr("en='New phone number!';ru='Новый телефонный номер!';de='Neue Telefonnummer!'") + Chars.LF + vCallData, MessageStatus.Information,, pData, "FIASDriver.SetPostingSimple");
							EndIf;
							If vCallSum > 0 Then
								// Write phone call to the database
								WritePhoneCall(vPhoneNumber, vCallTime, vCallDuration, vCallTo, vCallSum, vCallRegion, vCallType, vCallDescription, vCallData, pData);	
							EndIf;
							WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "OK", pData["P#"], pData["WS"], "", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
						Else
							DoMessage(NStr("en='Wrong date and time!';ru='Неправильный формат даты и времени!';de='Falsches Datum- und Zeitformat!'") + Chars.LF + vCallData, MessageStatus.Attention,, pData, "FIASDriver.SetPostingSimple");
							WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "RY", pData["P#"], pData["WS"], "INVALID DATE"), "Posting answer", pIsHTTPRequest, rResult);
						EndIf;
					Else
						WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "UR", pData["P#"], pData["WS"], "UPLOADING PHONE CALLS NOT ACTIVE", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
					EndIf;
				ElsIf pData["PT"] = "T" Then
					WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "UR", pData["P#"], pData["WS"], "NOT SUPPORTED", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);	
				ElsIf pData["PT"] = "M" Then
					WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "UR", pData["P#"], pData["WS"], "NOT SUPPORTED", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);	
				Else
					DoMessage(NStr("en = 'Unknown command type.'; de = 'Unbekannter Befehlstyp.'; ru = 'Неизвестный тип команды.'"), MessageStatus.Attention,, pData, "FIASDriver.SetPostingSimple");
					WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "RY", pData["P#"], pData["WS"], "INVALID TYPE", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
				EndIf;
			Else	
				DoMessage(NStr("en='Wrong date and time!';ru='Неправильный формат даты и времени!';de='Falsches Datum- und Zeitformat!'"), MessageStatus.Attention,, pData, "FIASDriver.SetPostingSimple");
				WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "RY", pData["P#"], pData["WS"], "INVALID DATE", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
			EndIf;
		ElsIf ValueIsFilled(pData["RN"]) And ValueIsFilled(pData["TA"]) And cmIsNumber(pData["TA"]) And Number(pData["TA"]) = 0 Then
			vPhoneNumber = GetPhoneNumber(Catalogs.Rooms.EmptyRef(), pData["RN"]);
			If Not ValueIsFilled(vPhoneNumber) Then 
				vPhoneNumberObj = Catalogs.PhoneNumbers.CreateItem();
				vPhoneNumberObj.Description = pData["RN"];
				vPhoneNumberObj.PhoneNumber = pData["RN"];
				vPhoneNumberObj.Remarks = NStr("en='New! Created by load phone calls procedure.';ru='Новый! Добавлен при загрузке.';de='Neu! Hinzugefügt beim Lasen.'");
				vPhoneNumberObj.Owner = InteractionParameters.Hotel;
				vPhoneNumberObj.Parent = NewPhoneNumbersFolder;
				vPhoneNumberObj.NotUploadPhoneCalls = True;
				vPhoneNumberObj.Write();
			ElsIf Not vPhoneNumber.NotUploadPhoneCalls Then
				vPhoneNumberObj = vPhoneNumber.GetObject();
				vPhoneNumberObj.NotUploadPhoneCalls = True;
				vPhoneNumberObj.Write();	
			EndIf;
			WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "UR", pData["P#"], pData["WS"], "NOT UPLOAD PHONE CALLS", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
		Else
			If CheckNotUploadPhoneCalls(pData["RN"]) Then
				WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "UR", pData["P#"], pData["WS"], "NOT UPLOAD PHONE CALLS", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);	
			Else
				DoMessage(NStr("en = 'Failed to find room by its code: '; de = 'Zimmer konnte nicht anhand seines Codes gefunden werden: '; ru = 'Не удалось найти номер по коду: '") + GetDataPresentation(pData["RN"]), MessageStatus.Attention,, pData, "FIASDriver.SetPostingSimple");
				WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "RY", pData["P#"], pData["WS"], "INVALID ROOM", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
			EndIf;
		EndIf;
	Else
		DoMessage(NStr("en = 'Command data error.'; de = 'Befehlsdatenfehler.'; ru = 'Ошибка данных команды.'"), MessageStatus.Attention,, pData, "FIASDriver.SetPostingSimple");
		WriteBuff(DataProcessors.FIASDriver.GetPostingAnswer(InteractionParameters, LinkRecords, pData["RN"], pData["DA"], pData["TI"], "RY", pData["P#"], pData["WS"], "INVALID DATA", "", "", "", "", ""), "Posting answer", pIsHTTPRequest, rResult);
	EndIf;
EndProcedure // SetPostingSimple

// -----------------------------------------------------------------------------
Procedure WritePhoneCall(pPhoneNumber, pCallTime, pCallDuration, pCallTo, pCallSum, pCallRegion, pCallType, pCallDescription, pCallData, pData)
	// Apply multiply factor to the sum
	vMultiplyFactor = MultiplyFactor;
	If ValueIsFilled(pPhoneNumber) Then
		If pPhoneNumber.MultiplyFactor > 0 Then
			vMultiplyFactor = pPhoneNumber.MultiplyFactor;
		EndIf;
	EndIf;
	pCallSum = Round(pCallSum * vMultiplyFactor, 2);
	
	// Calculate price
	vCallPrice = 0;
	If pCallDuration = 0 Then
		If pCallSum > 0 Тогда
			vCallPrice = pCallSum;
			pCallDuration = 1;
		EndIf;
	Else
		vCallPrice = Round(pCallSum/pCallDuration, 2);
	EndIf;
	pCallSum = Round(vCallPrice * pCallDuration, 2);
	
	// Create new interface document object
	vRecordPhoneCallObj = Documents.RecordPhoneCall.CreateDocument();
	vRecordPhoneCallObj.Hotel = InteractionParameters.Hotel;
	vRecordPhoneCallObj.pmFillAuthorAndDate();
	vRecordPhoneCallObj.SetNewNumber();
	vRecordPhoneCallObj.pmFillAttributesWithDefaultValues();
	
	// Fill default phone calls service
	If ValueIsFilled(PhoneCallsService) Then
		vRecordPhoneCallObj.PhoneCallService = PhoneCallsService;
	EndIf;
	
	// Fill call sum, duration and price
	vRecordPhoneCallObj.Sum = pCallSum;
	vRecordPhoneCallObj.Price = vCallPrice;
	vRecordPhoneCallObj.Quantity = pCallDuration;
	
	// Fill currency attributes
	vRecordPhoneCallObj.Currency = DataExchangeFileCurrency;
	vRecordPhoneCallObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vRecordPhoneCallObj.Hotel, vRecordPhoneCallObj.Currency, vRecordPhoneCallObj.ExchangeRateDate);
	
	// Fill call attributes
	vRecordPhoneCallObj.PhoneCallDate = pCallTime;
	vRecordPhoneCallObj.TargetPhoneNumber = pCallTo;
	
	// Try to find folio to charge to
	vRecordPhoneCallObj.PhoneNumber = pPhoneNumber;
	If ValueIsFilled(pPhoneNumber) Then 
		If ValueIsFilled(pPhoneNumber.PhoneCallService) Then
			vRecordPhoneCallObj.PhoneCallService = pPhoneNumber.PhoneCallService;
		EndIf;
		If ValueIsFilled(pPhoneNumber.PerCallService) Then
			vRecordPhoneCallObj.PerCallService = pPhoneNumber.PerCallService;
		EndIf;
	EndIf;
	vRecordPhoneCallObj.Room = vRecordPhoneCallObj.PhoneNumber.Room;
	If ValueIsFilled(vRecordPhoneCallObj.Room) Then
		If ValueIsFilled(vRecordPhoneCallObj.Room.Company) Then
			vRecordPhoneCallObj.Company = vRecordPhoneCallObj.Room.Company;
			If Not ValueIsFilled(vRecordPhoneCallObj.PhoneCallService) Then
				vRecordPhoneCallObj.VATRate = vRecordPhoneCallObj.Company.VATRate;
			EndIf;
			If Not ValueIsFilled(vRecordPhoneCallObj.PerCallService) Then
				vRecordPhoneCallObj.PerCallServiceVATRate = vRecordPhoneCallObj.Company.VATRate;
			EndIf;
		EndIf;
		vRecordPhoneCallObj.Folio = vRecordPhoneCallObj.pmGetFolioToChargeTo();
	EndIf;
	
	// Try to find active room folio
	If Not ValueIsFilled(vRecordPhoneCallObj.Folio) Then
		vFolios = cmGetActiveRoomFolios(InteractionParameters.Hotel, vRecordPhoneCallObj.Room, InteractionParameters.Hotel.FolioCurrency);
		If vFolios.Count() > 0 Then
			vRow = vFolios.Get(0);
			vRecordPhoneCallObj.Folio = vRow.Folio;
		EndIf;
	EndIf;
	// Create new empty one
	If Not ValueIsFilled(vRecordPhoneCallObj.Folio) Then
		vFolioObj = Documents.Folio.CreateDocument();
		vFolioObj.Hotel = InteractionParameters.Hotel;
		vFolioObj.pmFillAttributesWithDefaultValues();
		vFolioObj.Room = vRecordPhoneCallObj.Room;
		vFolioObj.Description = NStr("en='Phone calls from vacant rooms';ru='Телефонные разговоры из свободных номеров';de='Telefongespräche aus freien Zimmern'");
		vFolioObj.Write(DocumentWriteMode.Write);
		
		vRecordPhoneCallObj.Folio = vFolioObj.Ref;
		
		vMessage = NStr("ru = 'Создано фолио: " + String(vRecordPhoneCallObj.Folio) + "'; 
		|de = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'; 
		|en = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'");
		DoMessage(vMessage, MessageStatus.Information,, pData, "FIASDriver.WritePhoneCall");
	EndIf;
	
	// Process folio
	vRecordPhoneCallObj.pmFillByFolio();
	vRecordPhoneCallObj.pmRecalculateSums();
	
	// Fill call type and region
	If Not IsBlankString(pCallRegion) Then
		vRecordPhoneCallObj.PhoneCallRegion = pCallRegion;
	Else
		vRecordPhoneCallObj.pmFillPhoneCallRegion();
	EndIf;
	If pCallType = "I" Or pCallRegion = "International" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.International;
	ElsIf pCallType = "L" Or pCallRegion = "Local" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Local;
	ElsIf pCallType = "N" Or pCallRegion = "National" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Intercountry;
	ElsIf ValueIsFilled(HotelCityPhoneCode) And Left(pCallTo, StrLen(TrimAll(HotelCityPhoneCode))) = TrimAll(HotelCityPhoneCode) Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Local;
	Else
		vRecordPhoneCallObj.pmFillPhoneCallType();
	EndIf;
	
	// Fill remarks
	vRecordPhoneCallObj.Remarks = pCallDescription;
	
	// Post current document
	vRecordPhoneCallObj.Write(DocumentWriteMode.Posting);
	
	// Log current state
	vMessage = NStr("ru = 'Создан документ: " + String(vRecordPhoneCallObj.Ref) + "'; 
	|de = 'Document " + String(vRecordPhoneCallObj.Ref) + " was created'; 
	|en = 'Document " + String(vRecordPhoneCallObj.Ref) + " was created'") + Chars.LF + pCallData;
	DoMessage(vMessage, MessageStatus.Information,, pData, "FIASDriver.WritePhoneCall");
EndProcedure // WritePhoneCall

// -----------------------------------------------------------------------------
Procedure ProcessesKeyDataEvents(pData, pCommand)
	If ValueIsFilled(pData["AS"]) And (ValueIsFilled(pData["WS"]) Or ValueIsFilled(pData["KC"])) Then 
		vRow = InformationRegisters.FIASPriorityEvents.Select(New Structure("WorkstationID", pData["WS"]));
		If vRow.Next() Then
			vRM = vRow.GetRecordManager(); 
			vRM.Response = TrimAll(StrReplace(StrReplace(pCommand, STX, ""), ETX, ""));
			vRM.IsResponseReceived = True;
			vRM.AnswerStatus = pData["AS"];
			If pData["CT"] <> Undefined Then
				vRM.ClearText = pData["CT"]; 	
			EndIf; 
			vRM.Write(True);
		Else      
			vRow = InformationRegisters.FIASPriorityEvents.Select(New Structure("KeyCoder", pData["KC"]));
			If vRow.Next() Then
				vRM = vRow.GetRecordManager(); 
				vRM.Response = TrimAll(StrReplace(StrReplace(pCommand, STX, ""), ETX, ""));
				vRM.IsResponseReceived = True;
				vRM.AnswerStatus = pData["AS"];
				If pData["CT"] <> Undefined Then
					vRM.ClearText = pData["CT"]; 	
				EndIf; 
				vRM.Write(True);
			EndIf;
		EndIf;
	Else
		DoMessage(NStr("en = 'Command data error.'; de = 'Befehlsdatenfehler.'; ru = 'Ошибка данных команды.'"), MessageStatus.Attention,, pData, "FIASDriver.ProcessesKeyDataEvents");
	EndIf;
EndProcedure // ProcessesKeyDataEvents

#EndRegion 

#Region Initialize

CSTOOLS6_LICENSE_KEY = cmGetCSWSOCK6LicenseKey();
CSTOOLS10_LICENSE_KEY = cmGetCSWSOCK10LicenseKey(); 
Timer = Undefined;
IsConnected = False; 
STX = Char(2);
ETX = Char(3);
SP  = Char(124);

#EndRegion

