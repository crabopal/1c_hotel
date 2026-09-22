// -----------------------------------------------------------------------------
Function GetString(pStr)
	If CashRegister.ChequeWidth > 0 Then
		Return Left(pStr, CashRegister.ChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Function GetPortNumber()
	vPort = TrimAll(CashRegister.Port);
	If vPort = "" Then
		Return 1; //COM1 by default
	Else
		vPortNumber = 0;
		If Upper(Left(vPort, 3)) = "COM" Then
			vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
		ElsIf cmIsNumber(vPort) Then
			vPortNumber = Number(vPort);
		EndIf;
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetBaudRate()
	vBaudRate = CashRegister.BaudRate;
	If vBaudRate = 2400 Then
		Return 0;
	ElsIf vBaudRate = 4800 Then
		Return 1;
	ElsIf vBaudRate = 9600 Then
		Return 2;
	ElsIf vBaudRate = 19200 Then
		Return 3;
	ElsIf vBaudRate = 38400 Then
		Return 4;
	ElsIf vBaudRate = 57600 Then
		Return 5;
	ElsIf vBaudRate = 115200 Then
		Return 6;
	ElsIf vBaudRate = 0 Then
		Return 6;
	EndIf;		
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function GetUserPassword(pAskPwd = False)
	vPassword = "";
	If Not pAskPwd Then
		vUser = SessionParameters.CurrentUser;
		If ValueIsFilled(vUser) Then
			If ValueIsFilled(vUser.EmployeePreferences) Then
				vPassword = TrimAll(vUser.EmployeePreferences.CashRegisterPassword);
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vPassword) And ValueIsFilled(CashRegister) And Not IsBlankString(CashRegister.CashRegisterPassword) Then
		vPassword = TrimAll(CashRegister.CashRegisterPassword);
	EndIf;
	// If password was not set then ask user to enter it
	If IsBlankString(vPassword) Then
		vFrm = GetCommonForm("InputCashRegisterPassword");
		vFrm.SelPassword = vPassword;
		vFrm.SelDescription = NStr("ru = 'Пожалуйста введите пароль ККМ...'; 
		                           |de = 'Input cash register password please...'; 
		                           |en = 'Input cash register password please...'");
		Return vFrm.DoModal();
	Else
		Return vPassword;
	EndIf;
EndFunction // GetUserPassword

// -----------------------------------------------------------------------------
Function Connect(rMessage, pAskPwd = False)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		#IF CLIENT THEN
			Try
				AttachAddIn("AddIn.DrvFR");
				vFR = New("AddIn.DrvFR");
			Except
				LoadAddIn("DrvFR.dll");
				vFR = New("AddIn.DrvFR");
			EndTry;
		#ELSE
			vFR = New COMObject("AddIn.DrvFR");
		#ENDIF
		// Set active logical device
		If CashRegister.UseLogicalDevice And CashRegister.LogicalDeviceNumber > 0 Then
			vFR.LDNumber = CashRegister.LogicalDeviceNumber;
			vFR.SetActiveLD();
		EndIf;
		// Set cash register password
		vFRPassword = GetUserPassword(pAskPwd);
		If vFRPassword = Undefined Then
			Raise NStr("ru = 'Пароль ККМ должен быть указан!'; en = 'User cash register password should be entered!'; de = 'User cash register password should be entered!'");
		EndIf;
		vFR.Password = vFRPassword;
		// Apply connection parameters
		If Not IsBlankString(CashRegister.DriverProtocol) And TrimAll(CashRegister.DriverProtocol) = "1" Then
			vFR.ProtocolType = 1;
		EndIf;
		If Not IsBlankString(CashRegister.ConnectionType) And cmIsNumber(TrimAll(CashRegister.ConnectionType)) Then
			vFR.ConnectionType = Number(TrimAll(CashRegister.ConnectionType));
		EndIf;
		vPortNumber = GetPortNumber();
		vBaudRate = GetBaudRate();
		If vPortNumber > 0 Then
			If vFR.ConnectionType = 6 Then
				vFR.TCPPort = vPortNumber;
			Else
				vFR.ComNumber = vPortNumber;
			EndIf;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(CashRegister.Address) Тогда
			vAddress = StrSplit(CashRegister.Address, ":", False);
			If vAddress.Count() = 2 Then
				vFR.ComputerName = TrimAll(TrimAll(vAddress[0]));
				vFR.TCPPort = Number(TrimAll(vAddress[1]));
			Else
				vFR.ComputerName = TrimAll(CashRegister.Address);
			EndIf;
		EndIf;
		If Not IsBlankString(CashRegister.OFDServer) Тогда
			vFR.OFDServer = TrimAll(CashRegister.OFDServer);
		EndIf;
		If CashRegister.OFDPort <> 0 Тогда
			vFR.OFDPort = CashRegister.OFDPort;
		EndIf;
		If CashRegister.OFDPollPeriod <> 0 Тогда
			vFR.OFDPollPeriod = CashRegister.OFDPollPeriod;
		EndIf;
		// Try to enable device
		vFR.Connect();
		// Check result code
		If vFR.ResultCode <> 0 Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultCodeDescription);
			Return Undefined;
		Else
			// OK
			Return vFR;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		pFR.Disconnect();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function CheckPaper(pFR,pFunction,rMessage)
	If pFR.ECRAdvancedMode = 0 Then
		Return True;
	ElsIf pFR.ECRAdvancedMode = 3 Then
		pFR.ContinuePrint();
		Return True;
	Else
		rMessage = pFR.ECRAdvancedModeDescription;
		WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Mode: " + pFR.ECRAdvancedMode + ", description: " + rMessage);
		Return false;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR)
	If pFR.ECRMode = 8 Тогда
		// Close cheque with sys admin password
		vPassword = pFR.Password;
		pFR.Password = TrimR(CashRegister.AccessPassword);
		pFR.ContinuePrint();
		pFR.ResetECR();
		pFR.Password = vPassword;
	EndIf;
EndProcedure // CloseOpenCheque

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected, so try to set up registration mode for it
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.CheckConnection'; de='CashRegister.CheckConnection'; ru='ККМ.ПроверкаСвязи'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// Read ECR status
			vFR.GetECRStatus();
			// Check status
			If vFR.ECRMode = 0 Or // Working status 
			   vFR.ECRMode = 1 Or // Data processing 
			   vFR.ECRMode = 2 Or // Open session, 24 hours not finished
			   vFR.ECRMode = 3 Or // Open session, 24 hours finished
			   vFR.ECRMode = 4 Then // Closed session
			    vFR.Beep();
				rMessage = vFR.ECRModeDescription;
				Disconnect(vFR);
				Return True;
			ElsIf vFR.ECRMode = 8 Then
				// Try to close check
				CloseOpenCheque(vFR);
				Disconnect(vFR);
				Return True;
			Else
				rMessage = vFR.ECRModeDescription;
				Disconnect(vFR);
				Return False;
			EndIf;			
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultCodeDescription);
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultCodeDescription);
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Try
		pFR.CancelCheck();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function CheckResultCode(pResultCode)
	If (pResultCode <> 0) And (pResultCode <> -1) And (pResultCode <> -4) And (pResultCode <> -5) And (pResultCode <> -6) Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // CheckResultCode

// -----------------------------------------------------------------------------
Function SetDeviceTime(pFR, rMessage)
	// Set device date
	pFR.Date = CurrentSessionDate();
	pFR.SetDate();
	If Not CheckResultCode(pFR.ResultCode) Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		// Get ECR mode to check do we need to confirm date change
		pFR.GetShortECRStatus();
		If Not CheckResultCode(pFR.ResultCode) Then
			ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
			Return False;
		Else
			If pFR.ECRMode = 6 Then
				// Confirm date change
				pFR.ConfirmDate();
				If Not CheckResultCode(pFR.ResultCode) Then
					ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
					Return False;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	// Set device time
	pFR.TimeStr = Format(CurrentSessionDate(), "DF=HH:mm:ss");
	pFR.SetTime();
	If Not CheckResultCode(pFR.ResultCode) Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.GetECRStatus();
	If Not CheckResultCode(pFR.ResultCode) Then
		vFRDate = pFR.Date;
		vFRDate = vFRDate + Number(Left(pFR.TimeStr, 2)) * 3600 + Number(Mid(pFR.TimeStr, 4, 2)) * 60 + Number(Mid(pFR.TimeStr, 7, 2));
		If BegOfDay(CurrentSessionDate()) = BegOfDay(vFRDate) Then
			vTimeDiff = CurrentSessionDate() - vFRDate;
			If vTimeDiff < 0 Then 
				vTimeDiff = -vTimeDiff;
			EndIf;
			If vTimeDiff > 300 Then // > 5 minutes
				// Set current time
				Return SetDeviceTime(pFR, rMessage);
			EndIf;
		Else
			// Date is different, need to set correct date manually
			Raise NStr("en='Check date in the cash register!'; de='Check date in the cash register!'; ru='Проверьте дату в ККМ!'");
		EndIf;
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage) Export
	vResult = True;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		vResult = False;
	Else
		// Cash register was connected
		Try
			// Set cash register time to the current one
			vResult = SetDeviceTime(vFR, rMessage);
			// Disconnect
			If vResult Then
				Disconnect(vFR);
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
			vResult = False;
		EndTry;
	EndIf;
	Return vResult;
EndFunction // pmSetDeviceTime

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash income
			vFR.Summ1 = pSum;
			vFR.CashIncome();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Do cash outcome
			vFR.Summ1 = pSum;
			vFR.CashOutcome();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage, True);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Print report
			vFR.PrintReportWithoutCleaning();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage) Export
	rMessage = NStr("ru = 'Печать почасового отчета не поддерживается драйвером!'; en = 'Hourly X Report is not supported by driver!'; de = 'Hourly X Report is not supported by driver!'");
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage, True);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// check if the session is already closed
			If vFR.ECRMode = 4 Then
				//session is closed
				rMessage = NStr("ru = 'Смена уже закрыта!'; en = 'Session is already closed!'; de = 'Session is already closed!'");
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, rMessage);
				Return False;
			EndIf;
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Print report
			vFR.PrintReportWithCleaning();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vFR, rMessage) Then
				Return False;
			EndIf;
			// Open new session
			If Not CashRegister.DoNotOpenNewSessionAfterZReport Then
				vFR.OpenSession();
			EndIf;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage) Export
	rMessage = NStr("en='Not supported!'; ru='Не поддерживается!'; de='Not supported!'");
	Return False;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function pmCloseSession(rMessage) Export
	Return pmPrintZReport(rMessage);
EndFunction // pmCloseSession

// -----------------------------------------------------------------------------
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
				
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Open cheque
			If pSum < 0 Then
            	vFR.CheckType = 2;
			Else
            	vFR.CheckType = 0;
			EndIf;
            vFR.OpenCheck();
			
			// Print cheque
			vFR.UseJournalRibbon = 1;
			vFR.UseReceiptRibbon = 1;
			
			vFR.Tax1 = 0; vFR.Tax2 = 0; vFR.Tax3 = 0; vFR.Tax4 = 0;
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;

			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText));
					// Print cheque header
					vFR.PrintHeader();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Print number and section
			If Not pIsCorrection Then
				vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
				
				// Department and cheque postion
				vFR.Department = 0;
				If Not CashRegister.DoNotPrintPaymentSections Then
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.Department = pObj.PaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + pObj.PaymentSection.Description);
						EndIf;
					EndIf;
				EndIf;
				
				vFR.Price = ?(pSum < 0, -pSum, pSum);
				vFR.Quantity = 1;
				If pSum >= 0 Then
					vFR.Sale();
				Else
					vFR.ReturnSale();
				EndIf;
				If Not CheckResultCode(vFR.ResultCode) Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;	
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vFR.StringForPrinting = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vFR.PrintString();
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.StringForPrinting = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; de = 'Betrag ist mit MwSt.'"));
					vFR.PrintString();
				EndIf;
			EndIf;
			
			// Close cheque
			vTypeClose = 0;
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			EndIf;
			vCloseSum = pSum;
			If pSum < 0 Then
				vCloseSum = -pSum;
			EndIf;
						
			vOpenDrawer = False;
			vFR.StringForPrinting = "";
			
			If vTypeClose = 4 Then
				vFR.Summ4 = vCloseSum;
			ElsIf vTypeClose = 3 Then
				vFR.Summ3 = vCloseSum;
			ElsIf vTypeClose = 2 Then
				vFR.Summ2 = vCloseSum;
			Else
				vOpenDrawer = True;
				vFR.Summ1 = vCloseSum;
			EndIf;
			vFR.CloseCheck();
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.OpenDrawer();
				EndIf;
			Except
			EndTry;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCustomerPaymentCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Open cheque
			If pSum < 0 Then
            	vFR.CheckType = 2;
			Else
            	vFR.CheckType = 0;
			EndIf;
            vFR.OpenCheck();
			
			// Print cheque
			vFR.UseJournalRibbon = 1;
			vFR.UseReceiptRibbon = 1;
			
			vFR.Tax1 = 0; vFR.Tax2 = 0; vFR.Tax3 = 0; vFR.Tax4 = 0;
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText));
					// Print cheque header
					vFR.PrintHeader();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Print number and sections
			If Not CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
				For Each vSrvRow In pServices Do
					// Department and cheque postion
					vPaymentSection = Undefined;
					vFR.Department = 0;
					vFR.StringForPrinting = "";
					If ValueIsFilled(vSrvRow.Service) Then
						vFR.StringForPrinting = GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						If ValueIsFilled(vSrvRow.Service.PaymentSection) Then
							vPaymentSection = vSrvRow.Service.PaymentSection;
							vFR.Department = vPaymentSection.Code;
						EndIf;
					EndIf;
					
					// Do sale
					vFR.Quantity = vSrvRow.Quantity;
					vFR.Price = vSrvRow.Price;
					vFR.Sale();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndDo;
			Else
				If pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
						vFR.PrintString();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
					
					vPSRows = cmGetPrintableChequePositions(pObj, , CashRegister.AlwaysUseAveragePrice);
					
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						pSum = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
							EndIf;
							
							// Department and cheque postion
							vPaymentSection = Undefined;
							vFR.Department = 0;
							vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Услуги гостиницы'");
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vPaymentSection = vPSRow.PaymentSection;
									vFR.Department = vPaymentSection.Code;
								EndIf;
								vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(vPaymentSection.Description);
							Else
								If vSectionAmount >=0 Then
									vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
								Else
									vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
								EndIf;
							EndIf;
					
							// Do sale
							If ValueIsFilled(vPSRow.ChequeService) Then
								If vPSRow.ChequeServiceQuantity <> 0 Then
									vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 6);
								Else
									vFR.Quantity = 1;
								EndIf;
								If vSectionAmount >= 0 Then
									vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.Sale();
								Else
									vFR.Price = Round(-vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(-vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.ReturnSale();
								EndIf;
							Else
								vFR.Quantity = 1;
								If vSectionAmount >= 0 Then
									vFR.Price = vSectionAmount;
									vFR.Sale();
								Else
									vFR.Price = -vSectionAmount;
									vFR.ReturnSale();
								EndIf;
							EndIf;
							If Not CheckResultCode(vFR.ResultCode) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndDo;
					ElsIf Not CashRegister.DoNotPrintPaymentSections Then
						pSum = 0;
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
							EndIf;
							
							// Department and cheque postion
							vPaymentSection = Undefined;
							vFR.Department = 0;
							vFR.StringForPrinting = "";
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vPaymentSection = vPSRow.PaymentSection;
									vFR.Department = vPaymentSection.Code;
								EndIf;
								vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(TrimAll(vPaymentSection.Code));
							Else
								If vSectionAmount >=0 Then
									vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
								Else
									vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
								EndIf;
							EndIf;
							
							// Do sale
							If ValueIsFilled(vPSRow.ChequeService) Then
								If vPSRow.ChequeServiceQuantity <> 0 Then
									vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 6);
								Else
									vFR.Quantity = 1;
								EndIf;
								If vSectionAmount >= 0 Then
									vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.Sale();
								Else
									vFR.Price = Round(-vSectionAmount / vFR.Quantity, 2);
									If vFR.Price <> 0 Then
										vFR.Quantity = Round(-vSectionAmount / vFR.Price, 6);
									EndIf;
									vFR.ReturnSale();
								EndIf;
							Else
								vFR.Quantity = 1;
								If vSectionAmount >= 0 Then
									vFR.Price = vSectionAmount;
									vFR.Sale();
								Else
									vFR.Price = -vSectionAmount;
									vFR.ReturnSale();
								EndIf;
							EndIf;
							If Not CheckResultCode(vFR.ResultCode) Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndDo;
					Else
						vAmount = 0;
						vVATAmount = 0;
						pSum = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Continue;
							Else
								pSum = pSum + vPSRow.Sum;
							EndIf;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vAmount = vAmount - vPSRow.Sum;
							Else
								vAmount = vAmount + vPSRow.Sum;
							EndIf;
							vVATAmount = vVATAmount + vPSRow.VATSum;
						EndDo;
						
						// Department and cheque postion
						vFR.Department = 0;
						vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
						
						// Do sale
						vFR.Quantity = 1;
						If vAmount >= 0 Then
							vFR.Price = vAmount;
							vFR.Sale();
						Else
							vFR.Price = -vAmount;
							vFR.ReturnSale();
						EndIf;
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
				Else
					vFR.StringForPrinting = NStr("en='Hotel services';ru='Услуги гостиницы';de='Hoteldienstleistungen'");
					If Not CashRegister.PrintFolioHeader Then
						vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
					EndIf;
					
					// Department and cheque postion
					vPaymentSection = Undefined;
					vFR.Department = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vPaymentSection = pObj.PaymentSection;
						vFR.Department = vPaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							If Not CashRegister.PrintFolioHeader Then
								vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + vPaymentSection.Description);
							Else
								vFR.StringForPrinting = GetString(vPaymentSection.Description);
							EndIf;
						EndIf;
					EndIf;
					
					// Do sale
					vFR.Quantity = 1;
					If pSum >= 0 Then
						vFR.Price = pSum;
						vFR.Sale();
					Else
						vFR.Price = -pSum;
						vFR.ReturnSale();
					EndIf;
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
			EndIf;
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vFR.StringForPrinting = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vFR.PrintString();
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.StringForPrinting = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; de = 'Betrag ist mit MwSt.'"));
				vFR.PrintString();
			EndIf;
			
			// Close cheque
			vTypeClose = 0;
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			EndIf;
			vCloseSum = pSum;
			If pSum < 0 Then
				vCloseSum = -pSum;
			EndIf;
			
			vOpenDrawer = False;
			vFR.StringForPrinting = "";
			
			If vTypeClose = 4 Then
				vFR.Summ4 = vCloseSum;
			ElsIf vTypeClose = 3 Then
				vFR.Summ3 = vCloseSum;
			ElsIf vTypeClose = 2 Then
				vFR.Summ2 = vCloseSum;
			Else
				vOpenDrawer = True;
				vFR.Summ1 = vCloseSum;
			EndIf;				
			vFR.CloseCheck();
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.OpenDrawer();
				EndIf;
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Procedure LogCashPayment(pFR, pFunction, pObj)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with amount ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	// Try to connect
	vFR = Connect(rMessage, True);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Open cheque
           	vFR.CheckType = 2;
            vFR.OpenCheck();
			
			// Print cheque
			vFR.UseJournalRibbon = 1;
			vFR.UseReceiptRibbon = 1;
		
			vFR.Tax1 = 0;
			vFR.Tax2 = 0;
			vFR.Tax3 = 0;
			vFR.Tax4 = 0;

			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText));
					// Print cheque header
					vFR.PrintHeader();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Print number and sections
			If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
			   pObj.PaymentSections.Count() > 0 Then
				If Not CashRegister.PrintFolioHeader Then
					vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
				
				vPSRows = cmGetPrintableChequePositions(pObj, , CashRegister.AlwaysUseAveragePrice);
				
				If CashRegister.PrintPaymentSectionNamesInCheques Then
					pSum = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							pSum = pSum + vPSRow.Sum;
						EndIf;
						vSectionAmount = vPSRow.Sum;
						If vSectionAmount < 0 Then
							Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
						EndIf;
						
						vPaymentSection = Undefined;
						vFR.Department = 0;
						If ValueIsFilled(vPSRow.ChequeService) Then
							vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
						Else
							vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(vPaymentSection.Description);
							EndIf;
						EndIf;
						
						If ValueIsFilled(vPSRow.ChequeService) Then
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 3);
							Else
								vFR.Quantity = 1;
							EndIf;
							vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
							If vFR.Price <> 0 Then
								vFR.Quantity = Round(vSectionAmount / vFR.Price, 3);
							EndIf;
						Else
							vFR.Quantity = 1;
							vFR.Price = vSectionAmount;
						EndIf;
						
						vFR.ReturnSale();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;	
					EndDo;
				ElsIf Not CashRegister.DoNotPrintPaymentSections Then
					pSum = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							pSum = pSum + vPSRow.Sum;
						EndIf;
						vSectionAmount = vPSRow.Sum;
						If vSectionAmount < 0 Then
							Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
						EndIf;
						
						vPaymentSection = Undefined;
						vFR.Department = 0;
						vFR.StringForPrinting = "";
						If ValueIsFilled(vPSRow.PaymentSection) Then
							vPaymentSection = vPSRow.PaymentSection;
							vFR.Department = vPaymentSection.Code;
						EndIf;
						If ValueIsFilled(vPSRow.ChequeService) Then
							vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
						Else
							vFR.StringForPrinting = NStr("en='0'; de='0'; ru='0'");
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(vPaymentSection.Code);
							EndIf;
						EndIf;
						
						If ValueIsFilled(vPSRow.ChequeService) Then
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vFR.Quantity = Round(vPSRow.ChequeServiceQuantity, 3);
							Else
								vFR.Quantity = 1;
							EndIf;
							vFR.Price = Round(vSectionAmount / vFR.Quantity, 2);
							If vFR.Price <> 0 Then
								vFR.Quantity = Round(vSectionAmount / vFR.Price, 3);
							EndIf;
						Else
							vFR.Quantity = 1;
							vFR.Price = vSectionAmount;
						EndIf;
						
						vFR.ReturnSale();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;	
					EndDo;
				Else
					vAmount = 0;
					vVATAmount = 0;
					pSum  = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							pSum = pSum + vPSRow.Sum;
						EndIf;
						vAmount = vAmount + vPSRow.Sum;
						vVATAmount = vVATAmount + vPSRow.VATSum;
					EndDo;
					If vAmount < 0 Then
						Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
					EndIf;
						
					vFR.Department = 0;
					vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
					
					vFR.Quantity = 1;
					vFR.Price = vAmount;
					vFR.ReturnSale();
					If Not CheckResultCode(vFR.ResultCode) Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
			Else
				vAmount = pSum;
				If vAmount < 0 Then
					Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
				EndIf;
				vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
				vFR.Department = 0;
				
				If ValueIsFilled(pObj.PaymentSection) Then
					vFR.Department = pObj.PaymentSection.Code;
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + pObj.PaymentSection.Description);
					EndIf;
				EndIf;
				
				vFR.Quantity = 1;
				vFR.Price = vAmount;
				
				vFR.ReturnSale();
				If Not CheckResultCode(vFR.ResultCode) Then
					CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;	
			EndIf;
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vFR.StringForPrinting = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vFR.StringForPrinting = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vFR.PrintString();
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.StringForPrinting = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; en = 'Betrag ist mit MwSt.'"));
				vFR.PrintString();
			EndIf;
			
			// Close cheque
			vFR.Summ1 = 0;
			vFR.Summ2 = 0;
			vFR.Summ3 = 0;
			vFR.Summ4 = 0;
			
			vTypeClose = 0;
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			EndIf;
						
			vOpenDrawer = False;
			If vTypeClose = 4 Then
				vFR.Summ4 = pSum;
			ElsIf vTypeClose = 3 Then
				vFR.Summ3 = pSum;
			ElsIf vTypeClose = 2 Then
				vFR.Summ2 = pSum;
			Else
				vOpenDrawer = True;
				vFR.Summ1 = pSum;
			EndIf;
			vFR.StringForPrinting = "";
			vFR.CloseCheck();
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Log cash register operation
			LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.OpenDrawer();
				EndIf;
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulateCheque

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек аннуляции'; en = ' storno cheque was issued'; de = ' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(pFR, pSlipTextArr)
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = Left(vStr, ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	// Print second slip for the client
	pFR.StringForPrinting = " ";
	pFR.PrintString();
	pFR.StringForPrinting = Left("-8<--------------------------------------------------------------------", 
	                   ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
	pFR.PrintString();
	pFR.StringQuantity = 4;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	// Print cliche
	pFR.StringForPrinting = NStr("ru = 'ДЛЯ КЛИЕНТА'; en = 'FOR THE CLIENT'; de = 'FOR THE CLIENT'");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(CashRegister.Owner.LegacyName), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(CashRegister.Owner.TIN) + "/" + TrimAll(CashRegister.Owner.KPP)), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
	For Each vStr In pSlipTextArr Do
		pFR.StringForPrinting = Left(vStr, ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	pFR.StringQuantity = 4;
	pFR.FeedDocument();
	pFR.CutType = True;
	pFR.CutCheck();
	// Print cliche
	pFR.PrintCliche();
	If pFR.ResultCode <> 0 Then
		pFR.StringForPrinting = Left(TrimAll(CashRegister.Owner.LegacyName), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='TIN/KPP '; ru='ИНН/КПП '; de='TIN/KPP '") + (TrimAll(CashRegister.Owner.TIN) + "/" + TrimAll(CashRegister.Owner.KPP)), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left(NStr("en='WELKOME'; ru='ДОБРО ПОЖАЛОВАТЬ'; de='WELKOME'"), ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
		pFR.StringForPrinting = Left("=======================================================================", ?(CashRegister.ChequeWidth=0, 24, CashRegister.ChequeWidth));
		pFR.PrintString();
	EndIf;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pObj, rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			// Open session if is closed
			If CashRegister.DoNotOpenNewSessionAfterZReport Then
				If vFR.ECRMode = 4 Тогда
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					Else
						cmWait(5);
					EndIf;
				EndIf;
			EndIf;
			
			// Print all strings in the array
			PrintSlipLines(vFR, pSlipTextArr);
			If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj)
	pFR.UseJournalRibbon=0; 
	pFR.UseReceiptRibbon=1;
	// Header start delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------");
	pFR.PrintString();
	// Folio #
	pFR.StringForPrinting = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio # '") + cmGetDocumentNumberPresentation(pObj.Folio.Number));
	pFR.PrintString();
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		pFR.StringForPrinting = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer: '") + TrimAll(pObj.Folio.Room)); 
		pFR.PrintString();
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer)); 
		Else
			pFR.StringForPrinting = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Folio.Client));
		EndIf;
		pFR.PrintString();
	EndIf;
	// Guest group
	pFR.StringForPrinting = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup)); 
	pFR.PrintString();
	// Document
	pFR.StringForPrinting = GetString(NStr("ru = 'Док.  № '; en = 'Doc.  # '; de = 'Dok. No '") + cmGetDocumentNumberPresentation(pObj.Number));
	pFR.PrintString();
	// Header end delimeter
	pFR.StringForPrinting = GetString("-----------------------------------------------------------------------"); 
	pFR.PrintString();
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = cmGetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			vFR.UseJournalRibbon=0; 
			vFR.UseReceiptRibbon=1;
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vFR.PrintCliche();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj);
						If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					Except
					EndTry;
				Else
					vStr = StrReplace(vStr, "&Type", vChequeType);
					vStr = StrReplace(vStr, "&CurrentDate", Format(CurrentSessionDate(), "DF=dd.MM.yyyy"));
					vStr = StrReplace(vStr, "&CurrentTime", Format(CurrentSessionDate(), "DF=HH:mm"));
					Try
						vStr = StrReplace(vStr, "&Document", ?(pSum >= 0, "Предварительный счет", "Возврат по платежу") + " № " + TrimAll(pObj.Number));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Hotel", TrimAll(pObj.Hotel.GetObject().pmGetHotelPrintName(SessionParameters.CurrentLanguage)));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Currency", TrimAll(pObj.PaymentCurrency));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&VATRate", TrimAll(pObj.VATRate));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Cashier", tcCashRegisters.GetCashierName(pObj.Author));
					Except
					EndTry;
					vStr = StrReplace(vStr, "&Amount", Format(?(pSum < 0, -pSum, pSum), "NFD=2"));
					vFR.StringForPrinting = GetString(vStr);
					vFR.PrintString();
					If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vFR.PrintCliche();
				If Not CheckResultCode(vFR.ResultCode) And vFR.ResultCode <> 126 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			Else
				vFR.StringQuantity = 6;
				vFR.FeedDocument();
			EndIf;
			
			// Cut off cheque
			vFR.CutType = True;
			vFR.CutCheck();
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Retrieve cash register state
		vFR.GetECRStatus();
		If vFR.ECRMode = 3 Then // Open session, 24 hours finished
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru = 'Смена превысила 24 часа!'; en = '24 hours open session limit exceeded!'; de = '24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		ElsIf vFR.ResultCode <> 0 Then
			rMessage = NStr("ru = 'Ошибка получения состояния ККМ!'; en = 'Failed to check cash register state!'; de = 'Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check paper
		If vFR.ReceiptRibbonIsPresent = 0 Then
			rMessage = NStr("ru = 'В ККМ закончилась чековая лента!'; en = 'Cash register is out of paper!'; de = 'Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmOpenDrawer(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			vFR.OpenDrawer();
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.OpenDrawer'; de='CashRegister.OpenDrawer'; ru='ККМ.ОткрытьЯщик'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmOpenDrawer
