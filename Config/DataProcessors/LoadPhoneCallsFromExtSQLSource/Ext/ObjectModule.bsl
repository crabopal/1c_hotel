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
	If IsBlankString(SQLConnectionString) Then
		SQLConnectionString = "Driver=SQL Server;Server=<ServerName>;Uid=<UserName>;Pwd=<Pwd>;DataBase=<DataBaseName>;";
	EndIf;
	If IsBlankString(SQLSelect) Then
		SQLSelect = "SELECT 
					|	PhoneCalls.ID AS CallID, 
					|	PhoneCalls.StartDateTime AS CallDateTime, 
					|	NULL AS CallDate, 
					|	NULL AS CallTime, 
					|	PhoneCalls.DurationInSeconds AS CallDuration, 
		            |	PhoneCalls.InternalNumber AS CallFrom, 
		            |	NULL AS CallAccountCode, 
					|	PhoneCalls.ExternalNumber AS CallTo, 
					|	PhoneCalls.Prefix AS CallPrefix, 
					|	PhoneCalls.AreaCode AS CallRegion, 
					|	PhoneCalls.SumInRub AS CallSum, 
					|	NULL AS CallType
					|FROM 
					|	TTape AS PhoneCalls
					|WHERE
					|	PhoneCalls.ID > &1
					|ORDER BY
					|	CallID";
	EndIf;
	If MultiplyFactor = 0 Then
		MultiplyFactor = 1;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(SourceCurrency) Then
			SourceCurrency = Hotel.BaseCurrency;
		EndIf;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Load phone calls
	pmLoadPhoneCalls(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
Function AddTime(pDate, pTime)
	vHours = Int(pTime/3600);
	vMinutes = Round((pTime - vHours*3600)/60, 0);
	Return BegOfday(pDate) + vHours*3600 + vMinutes*60;
EndFunction // AddTime

// -----------------------------------------------------------------------------
Procedure SetRoomStatus(pRoomStatus, pEmployee, pOpRow, pIsInteractive)
	Try
		// Skip if room is not set
		If Not ValueIsFilled(pOpRow.Room) Then
			Return;
		EndIf;
		// Skip updating status if it is equal to the new one
		If pOpRow.Room.RoomStatus = pRoomStatus Then
			Return;
		EndIf;
		// Skip updating room status if it was set after phone call time
		vRoomObj = pOpRow.Room.GetObject();
		vLastStatus = vRoomObj.pmGetRoomStatusHistoryState('39991231235959');
		If vLastStatus.Count() > 0 Then
			vLastStatusRow = vLastStatus.Get(0);
			If pOpRow.Time < vLastStatusRow.Period Then
				Return;
			ElsIf vLastStatusRow.RoomStatus = vRoomObj.Owner.OccupiedRoomStatus Then
				Return;
			EndIf;
		EndIf;
		
		// Update room status
		vRoomObj.RoomStatus = pRoomStatus;
		vRoomObj.Write();
		
		// Add record to the room status change history
		vRoomObj.pmWriteToRoomStatusChangeHistory(pOpRow.Time, ?(ValueIsFilled(pEmployee), pEmployee, SessionParameters.CurrentUser), TrimAll(pOpRow.CallData));
	Except
		vMessage = NStr("en='Failed to update room status! Error description: ';ru='Не удалось установить статус номера! Описание ошибки: ';de='Der Zimmerstatus konnte nicht festgelegt werden! Fehlerbeschreibung: '") + ErrorDescription() + Chars.LF + pOpRow.CallData;
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromWintariff32';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзWinTariff32';de='DataProcessor.LoadPhoneCallsFromWintariff32'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
	EndTry;
EndProcedure // SetRoomStatus

// -----------------------------------------------------------------------------
Procedure WriteEndOfOperation(pEmployee, pOperation, pOpRow, pIsInteractive)
	Try
		// Try to find pending employee operation
		vEmpOpRef = cmGetPendingEmployeeOperation(pEmployee, pOperation, pOpRow.Time, pOpRow.Room);
		If ValueIsFilled(vEmpOpRef) Then
			// Update employee operation document
			vEmpOpObj = vEmpOpRef.GetObject();
			// Fill operation end time and duration
			vEmpOpObj.OperationEndTime = cm0SecondShift(pOpRow.Time);
			vEmpOpObj.Duration = vEmpOpObj.pmGetOperationDuration();
			// Fill remarks with call data
			vEmpOpObj.Remarks = TrimR(vEmpOpObj.Remarks) + Chars.LF + pOpRow.CallData;
			// Post document
			vEmpOpObj.Write(DocumentWriteMode.Posting);
		Else
			// Assume that employee has missed codes and this is start of operation
			WriteStartOfOperation(pEmployee, pOperation, pOpRow, pIsInteractive);
		EndIf;
	Except
		vMessage = NStr("en='Failed to write end of employee operation! Error description: ';ru='Не удалось записать конец работы сотрудника! Описание ошибки: ';de='Das Ender der Arbeitszeit des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '") + ErrorDescription() + Chars.LF + pOpRow.CallData;
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromWintariff32';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзWinTariff32';de='DataProcessor.LoadPhoneCallsFromWintariff32'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
	EndTry;
EndProcedure // WriteEndOfOperation

// -----------------------------------------------------------------------------
Procedure WriteStartOfOperation(pEmployee, pOperation, pOpRow, pIsInteractive)
	Try
		// Check if there is such operation already. Skip loading if found
		vEmpOperations = cmGetEmployeeOperation(pEmployee, pOperation, pOpRow.Time);
		If vEmpOperations.Count() = 0 Then
			// Create new employee operation document
			vEmpOpObj = Documents.EmployeeOperation.CreateDocument();
			vEmpOpObj.SetTime(AutoTimeMode.CurrentOrLast);
			vEmpOpObj.Hotel = pOpRow.Room.Owner;
			vEmpOpObj.pmFillAttributesWithDefaultValues();
			// Fill employee and operation
			vEmpOpObj.Employee = pEmployee;
			vEmpOpObj.Operation = pOperation;
			vEmpOpObj.Room = pOpRow.Room;
			vEmpOpObj.OperationStartTime = cm1SecondShift(pOpRow.Time);
			// Retrieve room resources
			vRoomAttrs = vEmpOpObj.Room.GetObject().pmGetRoomAttributes(?(ValueIsFilled(vEmpOpObj.OperationStartTime), vEmpOpObj.OperationStartTime, vEmpOpObj.Date));
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
			If vStds.Count() > 0 Then
				vStdsRow = vStds.Get(0);
				vEmpOpObj.RoomSpace = vStdsRow.RoomSpace;
				vEmpOpObj.Price = vStdsRow.Price;
			EndIf;
			// Fill operation articles consumption standards table
			vEmpOpObj.Articles.Clear();
			vEmpOpObj.pmFillArticles();
			// Fill remarks with call data
			vEmpOpObj.Remarks = pOpRow.CallData;
			// Post document
			vEmpOpObj.Write(DocumentWriteMode.Posting);
		EndIf;
	Except
		vMessage = NStr("en='Failed to write start of employee operation! Error description: ';ru='Не удалось записать начало работы сотрудника! Описание ошибки: ';de='Der Arbeitsbeginn des Mitarbeiters konnte nicht geschrieben werden! Fehlerbeschreibung: '") + ErrorDescription() + Chars.LF + pOpRow.CallData;
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromWintariff32';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзWinTariff32';de='DataProcessor.LoadPhoneCallsFromWintariff32'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
	EndTry;
EndProcedure // WriteStartOfOperation

// -----------------------------------------------------------------------------
Procedure AddOperationsHistoryRecord(pOpRow, pIsInteractive)
	// Assume that this is start of the operation
	vIsStart = True;
	
	// Try to find employee by accound code
	vEmployee = cmGetEmployeeByPBXAccountCode(pOpRow.Code);
	
	// Try to find operation by target phone number
	vOperation = cmGetOperationByPBXPhoneNumber(pOpRow.To, vIsStart);
	
	// Try to find room status by target phone number
	vRoomStatus = cmGetRoomStatusByPBXPhoneNumber(pOpRow.To);
	
	// Try to get operation from room status code
	If pOpRow.To <> 0 And pOpRow.To = ChangeRoomStatusPBXCode Then
		If ValueIsFilled(pOpRow.Room) Then
			vCurrentRoomStatus = pOpRow.Room.RoomStatus;
			If ValueIsFilled(vCurrentRoomStatus) Then
				If ValueIsFilled(vCurrentRoomStatus.Operation) Then
					vOperation = vCurrentRoomStatus.Operation;
				EndIf;
				If ValueIsFilled(vCurrentRoomStatus.NextRoomStatus) Then
					vRoomStatus = vCurrentRoomStatus.NextRoomStatus;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// If operation and employee are found then try to find started operation
	vDoStart = False;
	If ValueIsFilled(vEmployee) And ValueIsFilled(vOperation) Then
		// Try to find pending employee operation
		vEmpOpRef = cmGetPendingEmployeeOperation(vEmployee, vOperation, pOpRow.Time, pOpRow.Room);
		If ValueIsFilled(vEmpOpRef) Then
			vIsStart = False;
			If vEmpOpRef.Room <> pOpRow.Room Then
				vDoStart = True;
			EndIf;
		EndIf;
	Else
		// If we failed to get both employee and operation then assume that 
		// employee and operation is coded in the account code
		vStruct = cmGetEmployeeAndOperationByPBXCode(pOpRow.Code);
		If Not ValueIsFilled(vStruct.Employee) Or Not ValueIsFilled(vStruct.Operation) Then
			vStruct = cmGetEmployeeAndOperationByPBXCode(pOpRow.To);
		EndIf;
		If ValueIsFilled(vStruct.Employee) And ValueIsFilled(vStruct.Operation) Then
			// Fill employee
			vEmployee = vStruct.Employee;
			// Fill operation
			vOperation = vStruct.Operation;
			// Fill room status
			vRoomStatus = vStruct.RoomStatus;
			// Check if this is operation start
			If vStruct.IsOperationStart Then
				// This is start of operation
				vIsStart = True;
			ElsIf vStruct.IsOperationEnd Then
				// This is end of operation
				vIsStart = False;
			Else
				// This is wrong settings condition. Write log message and skip operation
				vMessage = NStr("en='Employee PBX codes settings have wrong operation start/end flags!';ru='В настройках кодов АТС сотрудников не указаны флаги начала/окончания работы!';de='In der Code-Einstellungen der Mitarbeiter-telefonanlagen wurden keine Fahnen für den Arbeitsbeginn/das Arbeitsende angegeben!'") + Chars.LF + pOpRow.CallData;
				WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromWintariff32';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзWinTariff32';de='DataProcessor.LoadPhoneCallsFromWintariff32'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
				Return;
			EndIf;
		EndIf;
	EndIf;		

	// Add operation to the employee operations history
	If ValueIsFilled(vEmployee) And ValueIsFilled(vOperation) Then
		If vIsStart Then
			// Add operation start record
			WriteStartOfOperation(vEmployee, vOperation, pOpRow, pIsInteractive);
		Else
			WriteEndOfOperation(vEmployee, vOperation, pOpRow, pIsInteractive);
			If vDoStart Then
				// Add operation start record
				WriteStartOfOperation(vEmployee, vOperation, pOpRow, pIsInteractive);
			EndIf;
		EndIf;
	EndIf;

	// Set room status if necessary
	If ValueIsFilled(vRoomStatus) Then
		SetRoomStatus(vRoomStatus, vEmployee, pOpRow, pIsInteractive);
	EndIf;
EndProcedure // AddOperationsHistoryRecord

// -----------------------------------------------------------------------------
Procedure ProcessEmployeeOperations(pOperations, pIsInteractive)
	// Sort operations by time
	pOperations.GroupBy("From,Room,Code,To,Time,CallData",);
	pOperations.Sort("Time,From,Code,To");
	// Save operations to the operations history
	For Each vOpRow In pOperations Do
		 AddOperationsHistoryRecord(vOpRow, pIsInteractive);
	EndDo;
EndProcedure // ProcessEmployeeOperations
	
// -----------------------------------------------------------------------------
Procedure pmLoadPhoneCalls(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If IsBlankString(SQLConnectionString) Then
		vMessage = NStr("ru='Не указана строка с параметрами подключения к SQL базе!';de='Die Zeile mit den Anschlussparametern an die SQL-Basis angegeben!';en='SQL database connection string is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If IsBlankString(SQLSelect) Then
		vMessage = NStr("ru='Не указано SQL выражение для отбора данных по не загруженным телефонным разговорам!';de='Die SQL-Anweisung für die Auswahl von Daten zu den nicht geladenen Telefongesprächen ist nicht angegeben!';en='SQL expression to retrieve unloaded phone calls data is not specified!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	If Not ValueIsFilled(MultiplyFactor) Then
		vMessage = NStr("ru='Не указан коэффициент умножения цены!';de='Der Preismultiplikationskoeffizient ist nicht angegeben!';en='Price multiplication factor is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	// Initialize table with phone calls data
	vCalls = New ValueTable();
	vCalls.Columns.Add("CallID", cmGetNumberTypeDescription(19, 0));
	vCalls.Columns.Add("CallDateTime", cmGetDateTimeTypeDescription());
	vCalls.Columns.Add("CallDate", cmGetDateTypeDescription());
	vCalls.Columns.Add("CallTime", cmGetDateTimeTypeDescription());
	vCalls.Columns.Add("CallDuration", cmGetNumberTypeDescription(10, 0));
	vCalls.Columns.Add("CallFrom", cmGetStringTypeDescription());
	vCalls.Columns.Add("CallCode", cmGetStringTypeDescription());
	vCalls.Columns.Add("CallTo", cmGetStringTypeDescription());
	vCalls.Columns.Add("CallPrefix", cmGetStringTypeDescription());
	vCalls.Columns.Add("CallSum", cmGetNumberTypeDescription(17, 2));
	vCalls.Columns.Add("CallRegion", cmGetStringTypeDescription());
	vCalls.Columns.Add("CallType", cmGetStringTypeDescription());
	
	// Initialize employee operations table
	vOperations = New ValueTable();
	vOperations.Columns.Add("From", cmGetStringTypeDescription());
	vOperations.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vOperations.Columns.Add("Code", cmGetNumberTypeDescription(13, 0));
	vOperations.Columns.Add("To", cmGetNumberTypeDescription(13, 0));
	vOperations.Columns.Add("Time", cmGetDateTimeTypeDescription());
	vOperations.Columns.Add("CallData", cmGetStringTypeDescription());

	// Try to connect to the database server and retrieve value table with phone calls to be loaded
	Try
		vSQlConn = New COMObject("ADODB.Connection"); 
		vSQlConn.ConnectionString = TrimAll(SQLConnectionString);
		vSQlConn.Open();
		
		// Insert last loaded call ID to the select expression
		vSQLSelect = StrReplace(TrimAll(SQLSelect), "&1", Format(LastCallRecordNumber, "ND=19; NFD=1; NDS=.; NG="));
		
		// Run SQL expression to get data
		vRS = New COMObject("ADODB.Recordset"); 
		vRS.Open(vSQLSelect, vSQLConn);
		
		// Fill value table with data retrieved
		While vRS.EOF() = 0 Do
			vRow = vCalls.Add();
			
			vRow.CallID = vRS.Fields("CallID").Value;
			vRow.CallDateTime = vRS.Fields("CallDateTime").Value;
			vRow.CallDate = vRS.Fields("CallDate").Value;
			vRow.CallTime = vRS.Fields("CallTime").Value;
			vRow.CallDuration = vRS.Fields("CallDuration").Value;
			vRow.CallFrom = TrimAll(vRS.Fields("CallFrom").Value);
			vRow.CallCode = TrimAll(vRS.Fields("CallAccountCode").Value);
			vRow.CallTo = TrimAll(vRS.Fields("CallTo").Value);
			vRow.CallPrefix = TrimAll(vRS.Fields("CallPrefix").Value);
			vRow.CallSum = vRS.Fields("CallSum").Value;
			vRow.CallRegion = TrimAll(vRS.Fields("CallRegion").Value);
			vRow.CallType = TrimAll(vRS.Fields("CallType").Value);

			// Retrieve next row
			vRS.MoveNext(); 
		EndDo;
		
		vRS.Close(); 
		vSQLConn.Close();
	Except
		vMessage = ErrorDescription();
		
		// Try close recordset and connection
		Try
			vRS.Close();
		Except
		EndTry;
		Try
			vSQLConn.Close();
		Except
		EndTry;
		
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndTry;
	
	// Open calls file
	vCount = 0;
	If vCalls.Count() > 0 Then
		For Each vCallsRow In vCalls Do
			Try
				vCount = vCount + 1;
				
				// Parse calls fields
				vCallID = vCallsRow.CallID;
				vCallDateTime = vCallsRow.CallDateTime;
				If Not ValueIsFilled(vCallDateTime) Then
					vCallDateTime = vCallsRow.CallDate;
					vCallDateTime = AddTime(vCallDateTime, vCallsRow.CallTime);
				EndIf;
				vCallDurationInSecs = vCallsRow.CallDuration; // Assume it is in seconds
				vCallDuration = Round(vCallDurationInSecs/60, 7);
				vCallDurationInMins = Int(vCallDurationInSecs/60);
				vCallDurationInSecs = vCallDurationInSecs - vCallDurationInMins*60;
				vCallFrom = vCallsRow.CallFrom;
				vCallCode = vCallsRow.CallCode;
				vCallTo = vCallsRow.CallTo;
				If Not IsBlankString(vCallsRow.CallPrefix) Then
					vCallTo = Right(vCallsRow.CallPrefix, 1) + vCallTo;
				EndIf;
				vCallSum = vCallsRow.CallSum;
				vCallRegion = vCallsRow.CallRegion;
				vCallType = vCallsRow.CallType;
				
				// Build call description string
				vCallDescription  = TrimAll(vCallRegion + " #") + TrimAll(vCallTo) + " - " + Format(vCallDateTime, "DF='dd.MM.yy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "''";
				
				// Build call data presentation string
				vCallData = Format(vCallDateTime, "DF='dd.MM.yy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "'', " + vCallFrom + " > " + vCallTo + " " + vCallRegion;
				
				// Check call sum and date
				If vCallDateTime > '19000101' And vCallDateTime < EndOfDay('21000101') Then
					// Try to find from phone number
					vPhoneNumber = cmGetPhoneNumber(vCallFrom, Hotel);
					If vPhoneNumber = Undefined Then
						vPhoneNumberObj = Catalogs.PhoneNumbers.CreateItem();
						vPhoneNumberObj.Description = vCallFrom;
						vPhoneNumberObj.PhoneNumber = vCallFrom;
						vPhoneNumberObj.Remarks = NStr("en='New! Created by load phone calls procedure.';ru='Новый! Добавлен при загрузке.';de='Neu! Hinzugefügt beim Lasen.'");
						vPhoneNumberObj.Owner = Hotel;
						vPhoneNumberObj.Parent = NewPhoneNumbersFolder;
						vPhoneNumberObj.Write();
						vPhoneNumber = vPhoneNumberObj.Ref;
						
						vMessage= NStr("en='New phone number!';ru='Новый телефонный номер!';de='Neue Telefonnummer!'") + Chars.LF + vCallData;
						WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Note, vPhoneNumber.Metadata(), vPhoneNumber, vMessage);
						If pIsInteractive Then
							tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Important);
						EndIf;
					EndIf;
					
					// Check if room is filled
					If LoadCallsFromRoomsOnly Then
						If Not ValueIsFilled(vPhoneNumber.Room) Then
							// Skip this call cause this phone number do not have reference to the room
							Continue;
						EndIf;
					EndIf;
					
					vCallToNumber = 0;
					If cmIsNumber(vCallTo) Then
						vCallToNumber = Number(vCallTo);
					EndIf;
					
					// Try to create interface document
					If vCallSum > 0 Then
						WritePhoneCall(vPhoneNumber, vCallDateTime, vCallDuration, vCallFrom, vCallTo, vCallSum, vCallRegion, vCallType, vCallDescription, vCallData, pIsInteractive);
					ElsIf DoOperationsRegistration And
						  ValueIsFilled(vPhoneNumber.Room) And 
						  (Not IsBlankString(vCallCode) Or ChangeRoomStatusPBXCode <> 0 Or ValueIsFilled(cmGetRoomStatusByPBXPhoneNumber(vCallToNumber))) Then
						// Add record to the employee operations table
						vOpRow = vOperations.Add();
						vOpRow.From = vCallFrom;
						vOpRow.Room = vPhoneNumber.Room;
						If cmIsNumber(vCallCode) Then
							vOpRow.Code = Number(vCallCode);
						Else
							vOpRow.Code = 0;
						EndIf;
						vOpRow.To = vCallToNumber;
						vOpRow.Time = vCallDateTime;
						vOpRow.CallData = TrimAll(vCallCode + " - " + vCallData);
					Else
						Continue;
					EndIf;
					
					// Save data for the last loaded call
					LastCallTime = vCallDateTime;
					LastCallPhoneNumber = vCallFrom;
					LastCallRecordNumber = vCallID;
					
					If pIsInteractive Then
						// Save current data processor attributes
						pmSaveDataProcessorAttributes();
					EndIf;
				Else
					vMessage = NStr("en='Wrong date and time!';ru='Неправильный формат даты и времени!';de='Falsches Datum- und Zeitformat!'") + Chars.LF + vCallData;
					WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
					EndIf;
				EndIf;
			Except
				vMessage = ErrorDescription();
				WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				Else
					Raise vMessage;
				EndIf;
			EndTry;
			
			// Check user interrupt processing
			If pIsInteractive Then
				#IF CLIENT THEN
					UserInterruptProcessing();
				#ENDIF
			EndIf;
		EndDo;
	EndIf;
	
	// Process employee operations
	If vOperations.Count() > 0 Then
		ProcessEmployeeOperations(vOperations, pIsInteractive);
	EndIf;
	
	// Send message with last loaded call data
	If LastCallRecordNumber <> 0 Then
		vMessage = NStr("en = 'Stop loading at record #" + TrimAll(LastCallRecordNumber) + " with 
							  |call date & time " + Format(LastCallTime, "DF='dd.MM.yyyy HH:mm'") + " from " + TrimAll(LastCallPhoneNumber) + "'; 
		                |de = 'Stop loading at record #" + TrimAll(LastCallRecordNumber) + " with 
							  |call date & time " + Format(LastCallTime, "DF='dd.MM.yyyy HH:mm'") + " from " + TrimAll(LastCallPhoneNumber) + "'; 		
						|ru = 'Загрузка прекращена на записи #" + TrimAll(LastCallRecordNumber) + " с 
							  |датой и временем " + Format(LastCallTime, "DF='dd.MM.yyyy HH:mm'") + " с тел. номера " + TrimAll(LastCallPhoneNumber) + "'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
		EndIf;
	EndIf;
	// Save current data processor attributes
	pmSaveDataProcessorAttributes();
	
	// Log that processing is finished
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("ru = 'Конец выполнения процедуры загрузки телефонных разговоров. Загружено " + vCount + " записей.'; en = 'End of loading phone calls. " + vCount + " calls were loaded.'; de = 'End of loading phone calls. " + vCount + " calls were loaded.'"));
EndProcedure // pmLoadPhoneCalls

// -----------------------------------------------------------------------------
Procedure WritePhoneCall(pPhoneNumber, pCallDateTime, pCallDuration, pCallFrom, pCallTo, pCallSum, pCallRegion, pCallType, pCallDescription, pCallData, pIsInteractive)
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
	vRecordPhoneCallObj.Hotel = Hotel;
	vRecordPhoneCallObj.pmFillAuthorAndDate();
	vRecordPhoneCallObj.SetNewNumber();
	vRecordPhoneCallObj.pmFillAttributesWithDefaultValues();
	
	// Fill call sum, duration and price
	vRecordPhoneCallObj.Sum = pCallSum;
	vRecordPhoneCallObj.Price = vCallPrice;
	vRecordPhoneCallObj.Quantity = pCallDuration;
	
	// Fill currency attributes
	vRecordPhoneCallObj.Currency = SourceCurrency;
	vRecordPhoneCallObj.CurrencyExchangeRate = cmGetCurrencyExchangeRate(vRecordPhoneCallObj.Hotel, vRecordPhoneCallObj.Currency, vRecordPhoneCallObj.ExchangeRateDate);
	
	// Fill call attributes
	vRecordPhoneCallObj.PhoneCallDate = pCallDateTime;
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
		vFolios = cmGetActiveRoomFolios(Hotel, vRecordPhoneCallObj.Room, Hotel.FolioCurrency);
		If vFolios.Count() > 0 Then
			vRow = vFolios.Get(0);
			vRecordPhoneCallObj.Folio = vRow.Folio;
		EndIf;
	EndIf;
	// Create new empty one
	If Not ValueIsFilled(vRecordPhoneCallObj.Folio) Then
		vFolioObj = Documents.Folio.CreateDocument();
		vFolioObj.Hotel = Hotel;
		vFolioObj.pmFillAttributesWithDefaultValues();
		vFolioObj.Room = vRecordPhoneCallObj.Room;
		vFolioObj.Description = NStr("en='Phone calls from vacant rooms';ru='Телефонные разговоры из свободных номеров';de='Telefongespräche aus freien Zimmern'");
		vFolioObj.Write(DocumentWriteMode.Write);
		
		vRecordPhoneCallObj.Folio = vFolioObj.Ref;
		
		vMessage = NStr("ru = 'Создано фолио: " + String(vRecordPhoneCallObj.Folio) + "'; 
		                |de = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'; 
						|en = 'Folio " + String(vRecordPhoneCallObj.Folio) + " was created'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Note, vRecordPhoneCallObj.Folio.Metadata(), vRecordPhoneCallObj.Folio, vMessage);
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
	vRecordPhoneCallObj.pmFillPhoneCallType();
	
	// Fill remarks
	vRecordPhoneCallObj.Remarks = pCallDescription;
	
	// Post current document
	vRecordPhoneCallObj.Write(DocumentWriteMode.Posting);
				
	// Log current state
	vMessage = NStr("ru = 'Создан документ: " + String(vRecordPhoneCallObj.Ref) + "'; 
	                |de = 'Document " + String(vRecordPhoneCallObj.Ref) + " was created'; 
	                |en = 'Document " + String(vRecordPhoneCallObj.Ref) + " was created'") + Chars.LF + pCallData;
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromExtSQLSource';ru='Обработка.ЗагрузкаТелефонныхРазговоровИзВнешнегоSQLИсточника';de='DataProcessor.LoadPhoneCallsFromExtSQLSource'"), EventLogLevel.Information, ThisObject.Metadata(), vRecordPhoneCallObj.Ref, vMessage);
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
	Endif;
EndProcedure // WritePhoneCall
