
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
	If IsBlankString(DataExchangeFile) Then
		DataExchangeFile = "c:\Barsum\Calls\Phone.txt";
	EndIf;
	If MultiplyFactor = 0 Then
		MultiplyFactor = 1;
	EndIf;
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Hotel) Then
		If Not ValueIsFilled(DataExchangeFileCurrency) Then
			DataExchangeFileCurrency = Hotel.BaseCurrency;
		EndIf;
		If Not ValueIsFilled(PhoneCallsService) Then
			PhoneCallsService = Hotel.PhoneCallService;
		EndIf;
	EndIf;
	If CallTimeMonthStartPosition = 0 Then
		CallTimeMonthStartPosition = 14;
	EndIf;
	If CallTimeDayStartPosition = 0 Then
		CallTimeDayStartPosition = 11;
	EndIf;
	If CallTimeHourStartPosition = 0 Then
		CallTimeHourStartPosition = 23;
	EndIf;
	If CallTimeMinuteStartPosition = 0 Then
		CallTimeMinuteStartPosition = 26;
	EndIf;
	If CallDurationInMinutesStartPosition = 0 Then
		CallDurationInMinutesStartPosition = 29;
		CallDurationInMinutesLength = 4;
	EndIf;
	If CallFromStartPosition = 0 Then
		CallFromStartPosition = 17;
		CallFromLength = 4;
	EndIf;
	If CallToStartPosition = 0 Then
		CallToStartPosition = 46;
		CallToLength = 18;
	EndIf;
	If CallAmountStartPosition = 0 Then
		CallAmountStartPosition = 33;
		CallAmountLength = 12;
	EndIf;
	If CallTypeStartPosition = 0 And CallTypeLength = 0 Then
		CallTypeStartPosition = 64;
		CallTypeLength = 1;
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
Procedure pmLoadPhoneCalls(pIsInteractive = False) Export
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
	// Check parameters
	If IsBlankString(DataExchangeFile) Then
		vMessage = NStr("ru='Не указан файл с телефонными разговорами!';de='Die Datei mit Telefongesprächen ist nicht angegeben!';en='Calls interface file is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	vCallsFile = New File(TrimAll(DataExchangeFile));
	If Not tcCommonFunctionOnClientServer.cmExists(vCallsFile) Then
		vMessage = NStr("ru='Файл с телефонными разговорами не найден!';de='Datei mit Telefongesprächen wurde nicht gefunden!';en='Calls interface file is not found!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
		EndIf;
		Return;
	EndIf;
	If Not ValueIsFilled(MultiplyFactor) Then
		vMessage = NStr("ru='Не указан коэффициент умножения цены!';de='Der Preismultiplikationskoeffizient ist nicht angegeben!';en='Price multiplication factor is not set up!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	// Rename file to be processed
	vCallsFileFullName = TrimAll(HistoryCatalog) + vCallsFile.BaseName + Format(CurrentSessionDate(), "DF=_yyyy-MM-dd_HH-mm") + ".txt";
	vNumOfTries = 100;
	While vNumOfTries > 0 Do
		Try
			MoveFile(vCallsFile.FullName, vCallsFileFullName);
			Break;
		Except
			vNumOfTries = vNumOfTries - 1;
		EndTry;
	EndDo;
	If vNumOfTries = 0 Then
		vMessage = NStr("ru = 'Не удалось переместить файл с телефонными разговорами в папку истории!'; 
		                |de = 'Failed to move calls file to the history catalog!';
		                |en = 'Failed to move calls file to the history catalog!'");
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), Undefined, vMessage);
		If pIsInteractive Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Return;
		Else
			Raise vMessage;
		EndIf;
	EndIf;
	
	// Check parameters
	If CallTimeMonthStartPosition = 0 Then
		CallTimeMonthStartPosition = 14;
	EndIf;
	If CallTimeDayStartPosition = 0 Then
		CallTimeDayStartPosition = 11;
	EndIf;
	If CallTimeHourStartPosition = 0 Then
		CallTimeHourStartPosition = 23;
	EndIf;
	If CallTimeMinuteStartPosition = 0 Then
		CallTimeMinuteStartPosition = 26;
	EndIf;
	If CallDurationInMinutesStartPosition = 0 Then
		CallDurationInMinutesStartPosition = 29;
		CallDurationInMinutesLength = 4;
	EndIf;
	If CallFromStartPosition = 0 Then
		CallFromStartPosition = 17;
		CallFromLength = 4;
	EndIf;
	If CallToStartPosition = 0 Then
		CallToStartPosition = 46;
		CallToLength = 18;
	EndIf;
	If CallAmountStartPosition = 0 Then
		CallAmountStartPosition = 33;
		CallAmountLength = 12;
	EndIf;

	// Initialize employee operations table
	vOperations = New ValueTable();
	vOperations.Columns.Add("From", cmGetStringTypeDescription());
	vOperations.Columns.Add("Room", cmGetCatalogTypeDescription("Rooms"));
	vOperations.Columns.Add("Code", cmGetNumberTypeDescription(13, 0));
	vOperations.Columns.Add("To", cmGetNumberTypeDescription(13, 0));
	vOperations.Columns.Add("Time", cmGetDateTimeTypeDescription());
	vOperations.Columns.Add("CallData", cmGetStringTypeDescription());
	
	// Open calls file
	vCount = 0;
	If Not IsBlankString(LineDelimeterChar) And Left(TrimAll(LineDelimeterChar), 1) = "#" Then
		vDelimeterChars = "";
		vDelCharCodes = StrSplit(TrimAll(LineDelimeterChar), "#", False);
		For Each vDelChar In vDelCharCodes Do
			vDelimeterChars = vDelimeterChars + Char(Number(TrimAll(vDelChar)));
		EndDo;
		vCalls = New TextReader(vCallsFileFullName, TextEncoding.ANSI, vDelimeterChars);
	Else
		vCalls = New TextReader(vCallsFileFullName, TextEncoding.ANSI);
	EndIf;
	vCallsStr = vCalls.ReadLine();
	While vCallsStr <> Undefined Do
		Try
			vCount = vCount + 1;
				
			// Parse calls fields
			If CallTimeYearStartPosition = 0 Then
				vCallTime = Date(GetYear(Number(Mid(vCallsStr, CallTimeMonthStartPosition, 2))), 
				                 Number(Mid(vCallsStr, CallTimeMonthStartPosition, 2)), 
				                 Number(Mid(vCallsStr, CallTimeDayStartPosition, 2)), 
				                 Number(Mid(vCallsStr, CallTimeHourStartPosition, 2)),
				                 Number(Mid(vCallsStr, CallTimeMinuteStartPosition, 2)),
				                 0);
			Else
				If CallTimeYearLength = 4 Then
					vCallTime = Date(Number(Mid(vCallsStr, CallTimeYearStartPosition, CallTimeYearLength)), 
					                 Number(Mid(vCallsStr, CallTimeMonthStartPosition, 2)), 
					                 Number(Mid(vCallsStr, CallTimeDayStartPosition, 2)), 
					                 Number(Mid(vCallsStr, CallTimeHourStartPosition, 2)),
					                 Number(Mid(vCallsStr, CallTimeMinuteStartPosition, 2)),
					                 0);
				ElsIf CallTimeYearLength = 2 Then
					vCallTime = Date((2000 + Number(Mid(vCallsStr, CallTimeYearStartPosition, CallTimeYearLength))), 
					                 Number(Mid(vCallsStr, CallTimeMonthStartPosition, 2)), 
					                 Number(Mid(vCallsStr, CallTimeDayStartPosition, 2)), 
					                 Number(Mid(vCallsStr, CallTimeHourStartPosition, 2)),
					                 Number(Mid(vCallsStr, CallTimeMinuteStartPosition, 2)),
					                 0);
				Else
					Raise NStr("en='Failed to get call start time!'; de='Failed to get call start time!'; ru='Не удалось получить дату и время начала звонка!'");
				EndIf;
			EndIf;
			If CallDurationInHoursStartPosition = 0 And CallDurationInSecondsStartPosition = 0 Then
				vCallDurationInMins = Number(Mid(vCallsStr, CallDurationInMinutesStartPosition, CallDurationInMinutesLength));
				vCallDuration = vCallDurationInMins;
				vCallDurationInSecs = 0;
			Else
				vCallDurationInHours = Number(Mid(vCallsStr, CallDurationInHoursStartPosition, 2));
				vCallDurationInMinutes = Number(Mid(vCallsStr, CallDurationInMinutesStartPosition, CallDurationInMinutesLength));
				vCallDurationInSeconds = Number(Mid(vCallsStr, CallDurationInSecondsStartPosition, 2));
				vCallDurationInSecs = vCallDurationInHours*3600 + vCallDurationInMinutes*60 + vCallDurationInSeconds;
				vCallDuration = Round(vCallDurationInSecs/60, 7);
				vCallDurationInMins = Int(vCallDurationInSecs/60);
				vCallDurationInSecs = vCallDurationInSecs - vCallDurationInMins*60;
			EndIf;
			vCallFrom = TrimAll(Mid(vCallsStr, CallFromStartPosition, CallFromLength));
			vCallTo = TrimAll(Mid(vCallsStr, CallToStartPosition, CallToLength));
			vCallCode = "";
			If CallAccountCodeStartPosition <> 0 Then
				vCallCode = TrimAll(Mid(vCallsStr, CallAccountCodeStartPosition, CallAccountCodeLength));
			EndIf;
			vCallSum = 0;
			vCallSumStr = TrimAll(Mid(vCallsStr, CallAmountStartPosition, CallAmountLength));
			If Not IsBlankString(vCallSumStr) Then
				vCallSum = Number(vCallSumStr);
			EndIf;
			vCallRegion = "";
			If CallRegionStartPosition <> 0 Then
				vCallRegion = TrimAll(Mid(vCallsStr, CallRegionStartPosition, CallRegionLength));
			EndIf;
			vCallMode = "";
			If CallModeStartPosition <> 0 Then
				vCallMode = TrimAll(Mid(vCallsStr, CallModeStartPosition, CallModeLength));
			EndIf;
			vCallType = "";
			If CallTypeStartPosition <> 0 Then
				vCallType = TrimAll(Mid(vCallsStr, CallTypeStartPosition, CallTypeLength));
			EndIf;
			vCallDescription = TrimAll(vCallRegion + " #") + TrimAll(vCallTo) + " - " + Format(vCallTime, "DF='dd.MM.yyyy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "''";
			
			// Build call data presentation string
			vCallData = Format(vCallTime, "DF='dd.MM.yyyy HH:mm'") + ", " + vCallDurationInMins + "'" + vCallDurationInSecs + "'', " + vCallFrom + " > " + vCallTo + " " + vCallRegion;
			
			// Check call date
			If vCallTime > '19000101' And vCallTime < EndOfDay('21000101') Then
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
					WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Note, vPhoneNumber.Metadata(), vPhoneNumber, vMessage);
					If pIsInteractive Then
						tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Important);
					EndIf;
				EndIf;		
				
				// Check if room is filled
				vSkipLoading = False;
				If LoadCallsFromRoomsOnly Then
					If Not ValueIsFilled(vPhoneNumber.Room) Then
						// Skip this call cause this phone number do not have reference to the room
						vSkipLoading = True;
					EndIf;
				Endif;
				
				// Try to create interface document
				If Not vSkipLoading Then
					vSkipLoading = True;
					
					vCallToNumber = 0;
					If cmIsNumber(vCallTo) Then
						vCallToNumber = Number(vCallTo);
					EndIf;
					
					If vCallSum > 0 Then
						vSkipLoading = False;
						
						// Write phone call to the database
						WritePhoneCall(vPhoneNumber, vCallTime, vCallDuration, vCallFrom, vCallTo, vCallSum, vCallRegion, vCallMode, vCallType, vCallDescription, vCallData, pIsInteractive);
					ElsIf DoOperationsRegistration And
						  ValueIsFilled(vPhoneNumber.Room) And 
						  (Not IsBlankString(vCallCode) Or ChangeRoomStatusPBXCode <> 0 Or ValueIsFilled(cmGetRoomStatusByPBXPhoneNumber(vCallToNumber))) Then
						vSkipLoading = False;
						
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
						vOpRow.Time = vCallTime;
						vOpRow.CallData = TrimAll(vCallCode + " - " + vCallData);
					EndIf;
				EndIf;
			Else
				vMessage = NStr("en='Wrong date and time!';ru='Неправильный формат даты и времени!';de='Falsches Datum- und Zeitformat!'") + Chars.LF + vCallData;
				WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
				If pIsInteractive Then
					tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
				EndIf;
			EndIf;
		Except
			vMessage = ErrorDescription();
			WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
			If pIsInteractive Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Attention);
			Else
				Raise vMessage;
			EndIf;
		EndTry;
		
		// Go to the next call
		vCallsStr = vCalls.ReadLine();
		
		// Check user interrupt processing
		If pIsInteractive Then
			#IF CLIENT THEN
				UserInterruptProcessing();
			#ENDIF
		EndIf;
	EndDo;
	
	// Process employee operations
	If vOperations.Count() > 0 Then
		ProcessEmployeeOperations(vOperations, pIsInteractive);
	EndIf;
	
	// Clear old files from the history
	ClearHistoryFiles();
	
	// Log that processing is finished
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("ru = 'Конец выполнения процедуры загрузки телефонных разговоров. Загружено " + vCount + " записей.'; en = 'End of loading phone calls. " + vCount + " calls were loaded.'; de = 'End of loading phone calls. " + vCount + " calls were loaded.'"));
EndProcedure // pmLoadPhoneCalls

#EndRegion

#Region Private

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
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
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
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
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
			If vStds.Count() > 0 then
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
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
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
				WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='DataProcessor.LoadPhoneCallsFromBarsum'"), EventLogLevel.Warning, ThisObject.Metadata(), , vMessage);
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
Function GetYear(pMonth)
	vYear = Year(CurrentSessionDate());
	vMonth = Month(CurrentSessionDate());
	If vMonth < pMonth Then
		vYear = vYear - 1;
	EndIf;
	Return vYear;
EndFunction // GetYear

// -----------------------------------------------------------------------------
Procedure WritePhoneCall(pPhoneNumber, pCallTime, pCallDuration, pCallFrom, pCallTo, pCallSum, pCallRegion, pCallMode, pCallType, pCallDescription, pCallData, pIsInteractive)
	// Check should we skip this phone number
	If Not IsBlankString(PhonesToIgnore) Then
		If Find(PhonesToIgnore, pCallTo) > 0 Then
			Return;
		EndIf;
	EndIf;
	
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
		WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Note, vRecordPhoneCallObj.Folio.Metadata(), vRecordPhoneCallObj.Folio, vMessage);
	EndIf;
	
	// Process folio
	vRecordPhoneCallObj.pmFillByFolio();
	vRecordPhoneCallObj.pmRecalculateSums();
		
	// Fill call type and region
	vRecordPhoneCallObj.PhoneCallRegion = pCallRegion;
	If IsBlankString(pCallType) Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Internal;
	ElsIf pCallType = "L" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Local;
		If ValueIsFilled(LocalPhoneCallsService) Then
			vRecordPhoneCallObj.PhoneCallService = LocalPhoneCallsService;
		EndIf;
	ElsIf pCallType = "Z" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Cellular;
		If ValueIsFilled(CellularPhoneCallsService) Then
			vRecordPhoneCallObj.PhoneCallService = CellularPhoneCallsService;
		EndIf;
	ElsIf pCallType = "N" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.Intercountry;
		If ValueIsFilled(IntercountryPhoneCallsService) Then
			vRecordPhoneCallObj.PhoneCallService = IntercountryPhoneCallsService;
		EndIf;
	ElsIf pCallType = "I" Then
		vRecordPhoneCallObj.PhoneCallType = Enums.PhoneCallTypes.International;
		If ValueIsFilled(InternationalPhoneCallsService) Then
			vRecordPhoneCallObj.PhoneCallService = InternationalPhoneCallsService;
		EndIf;
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
	WriteLogEvent(NStr("en='DataProcessor.LoadPhoneCallsFromBarsum'; de='DataProcessor.LoadPhoneCallsFromBarsum'; ru='Обработка.ЗагрузкаТелефонныхРазговоровИзБарсум'"), EventLogLevel.Information, ThisObject.Metadata(), vRecordPhoneCallObj.Ref, vMessage);
	If pIsInteractive Then
		tcCommonFunctionOnClientServer.TextMessage(vMessage, MessageStatus.Information);
	Endif;
EndProcedure // WritePhoneCall

// -----------------------------------------------------------------------------
Procedure ClearHistoryFiles()
	If NumberOfFilesInHistory = 0 Then
		Return;
	EndIf;
	vFilesList = New ValueList();
	vFiles = FindFiles(TrimAll(HistoryCatalog), "phone_????-??-??_??-??.txt");
	For Each vFile In vFiles Do
		vFilesList.Add(vFile, vFile.Name);
	EndDo;
	vFilesList.SortByPresentation(SortDirection.Asc);
	vFilesListCount = vFilesList.Count();
	If vFilesListCount > NumberOfFilesInHistory Then
		For Each vFilesItem In vFilesList Do
			If vFilesListCount <= NumberOfFilesInHistory Then
				Break;
			EndIf;
			vFile = vFilesItem.Value;
			DeleteFiles(vFile.FullName);
			vFilesListCount = vFilesListCount - 1;
		EndDo;
	EndIf;
EndProcedure // ClearHistoryFiles


#EndRegion
