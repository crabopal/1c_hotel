Var RC_24_HOURS_LIMIT;
Var RC_NO_PAPER;
Var RC_CHECK_IS_OPEN;
Var RC_CONFIRM_DATE;
Var RC_WRONG_CHEQUE_TYPE;

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
		vPortNumber = Number(Mid(vPort, 4, StrLen(vPort)-3));
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetPortNumber8()
	vPort = TrimAll(CashRegister.Port);
	If vPort = "" Then
		Return 1001; //COM1 by default
	ElsIf vPort = "АТОЛ USB" Then
		Return 67;
	ElsIf vPort = "TCP/IP (клиент)" Then
		Return 99;
	ElsIf vPort = "UDP/IP" Then
		Return 110;
	Else
		vPortNumber = 1000 + Number(Mid(vPort, 4, StrLen(vPort)-3));
		Return vPortNumber;
	EndIf;
EndFunction // GetPortNumber8

// -----------------------------------------------------------------------------
Function GetBaudRate()
	vBaudRate = CashRegister.BaudRate;
	If vBaudRate = 1200 Then
		Return 3;
	ElsIf vBaudRate = 2400 Then
		Return 4;
	ElsIf vBaudRate = 4800 Then
		Return 5;
	ElsIf vBaudRate = 9600 Then
		Return 7;
	ElsIf vBaudRate = 38400 Then
		Return 12;
	ElsIf vBaudRate = 57600 Then
		Return 14;
	ElsIf vBaudRate = 115200 Then
		Return 18;
	ElsIf vBaudRate = 0 Then
		Return 7; // 9600 by default
	EndIf;		
	Return 0;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function GetUserPassword(pAskAlways = False)
	vPassword = "";
	If Not pAskAlways Then
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
		vFrm.SelDescription = NStr("ru='Пожалуйста введите пароль ККМ...'; 
		                           |de='Input cash register password please...';
		                           |en='Input cash register password please...'");
		Return vFrm.DoModal();
	Else
		Return vPassword;
	EndIf;
EndFunction // GetUserPassword

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vAddInName = "AddIn.FprnM45";
		If CashRegister.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 Then
			vAddInName = "AddIn.FprnM8";
		EndIf;
		#IF CLIENT THEN
			Try
				AttachAddIn(vAddInName);
				vFR = New(vAddInName);
			Except
				LoadAddIn("FPrnM1C.dll");
				vFR = New(vAddInName);
			EndTry;
		#ELSE
			vFR = New COMObject(vAddInName);
		#ENDIF
		// Set active logical device
		If CashRegister.UseLogicalDevice And CashRegister.LogicalDeviceNumber > 0 Then
			vFR.CurrentDeviceNumber = CashRegister.LogicalDeviceNumber;
		EndIf;
		If CashRegister.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 Then
			If vFR.CurrentDeviceNumber = 0 Then
				vFR.AddDevice();
			EndIf;
		EndIf;
		// Apply connection parameters
		If Not IsBlankString(CashRegister.CashRegisterModel) Then
			vFR.Model = Number(CashRegister.CashRegisterModel);
		EndIf;
		If Not IsBlankString(CashRegister.AccessPassword) Then
			vFR.UseAccessPassword = 1;
			vFR.AccessPassword = TrimR(CashRegister.AccessPassword);
		Else
			vFR.UseAccessPassword = 0;
		EndIf;
		vPortNumber = 1;
		If CashRegister.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 Then
			vPortNumber = GetPortNumber8();
		Else
			vPortNumber = GetPortNumber();
		EndIf;
		vBaudRate = GetBaudRate();
		If vPortNumber > 0 Then
			vFR.PortNumber = vPortNumber;
		EndIf;
		If vBaudRate > 0 Then
			vFR.BaudRate = vBaudRate;
		EndIf;
		If Not IsBlankString(CashRegister.Address) Then
			If CashRegister.CashRegisterDriver = Enums.CashRegisterDrivers.AtolCommonCashRegisterDriver8 And 
			  (TrimAll(CashRegister.Port) = "TCP/IP (клиент)" Or TrimAll(CashRegister.Port) = "UDP/IP") Then
				vFR.HostAddress = TrimAll(CashRegister.Address);
			Else
				vFR.MachineName = TrimAll(CashRegister.Address);
			EndIf;
		EndIf;
		If CashRegister.WriteLogFile Then
			vFR.WriteLogFile = 1;
		Else
			vFR.WriteLogFile = 0;
		EndIf;
		// Do model check for each operation
		vFR.ModelCheck = 1;
		// Try to enable device
		vFR.DeviceEnabled = 1;
		// Check result code
		If vFR.ResultCode <> 0 Then
			// Error connecting to the device
			rMessage = TrimAll(vFR.ResultDescription);
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
		pFR.ResetMode();
		pFR.DeviceEnabled = 0;
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR, pPasswordKKM="", pOpenSessionIfClosed = False)
	// Connect
	If pFR.DeviceEnabled = 0 Then
		pFR.DeviceEnabled = 1;
	EndIf;

	// Get advanced mode
	If pFR.Mode = 1 Then
		pFR.GetStatus();		
		If pFR.ResultCode = 0 Then
			If pFR.CheckState > 0 Then
				pFR.CancelCheck();
			ElsIf pFR.CheckPaperPresent = 0 Then
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cheque ribbon is almost over!'; de='Scheck Band ist fast vorbei!'; ru='В ККМ заканчивается бумага!'"), MessageStatus.Attention);
			EndIf;
			If pOpenSessionIfClosed And CashRegister.DoNotOpenNewSessionAfterZReport Then
				If pFR.SessionOpened = 0 Then
					// Open session
					pFR.Password = pPasswordKKM;
					pFR.OpenSession();
					cmWait(5);
				EndIf;
			EndIf;
		EndIf;
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
			vFR.Mode = 1;
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			// Get error description
			If vFR.ResultCode <> 0 Then
				rMessage = TrimAll(vFR.ResultDescription);
			EndIf;
			// Get set mode status
			If vFR.ResultCode = 0 Or 
			   vFR.ResultCode = RC_24_HOURS_LIMIT Or 
			   vFR.ResultCode = RC_NO_PAPER Then
				Disconnect(vFR);
				Return True;
			ElsIf vFR.ResultCode = RC_CHECK_IS_OPEN Then
				// Try to close check
				CloseOpenCheque(vFR);
				Disconnect(vFR);
				Return True;
			Else
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
	rMessage = TrimAll(pFR.ResultDescription);
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.ResultCode + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.ResultDescription);
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
Function SetDeviceTime(pFR, rMessage)
	// Connect
	If pFR.DeviceEnabled = 0 Then
		pFR.DeviceEnabled = 1;
	EndIf;
	
	// Set device date
	pFR.Day = Day(CurrentSessionDate());
	pFR.Month = Month(CurrentSessionDate());
	pFR.Year = Year(CurrentSessionDate());
	pFR.SetDate();
	If pFR.ResultCode <> 0 Then
		If pFR.ResultCode = RC_CONFIRM_DATE Then
			// Confirm date change
			pFR.SetDate();
			If pFR.ResultCode <> 0 Then
				ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
				Return False;
			EndIf;
		Else
			ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
			Return False;
		EndIf;
	EndIf;
	
	// Set device time
	pFR.Hour = Hour(CurrentSessionDate());
	pFR.Minute = Minute(CurrentSessionDate());
	pFR.Second = Second(CurrentSessionDate());
	pFR.SetTime();
	If pFR.ResultCode <> 0 Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.GetStatus();
	If pFR.ResultCode = 0 Then
		vFRDate = Date(pFR.Year, pFR.Month, pFR.Day, pFR.Hour, pFR.Minute, pFR.Second);
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
			Raise NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, True);
			// Set mode and password
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;	
			// Do cash income
			vFR.Summ = pSum;
			vFR.CashIncome();
			If vFR.ResultCode <> 0 Then
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, True);
			// Set mode
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;	
			// Do cash outcome
			vFR.Summ = pSum;
			vFR.CashOutcome();
			If vFR.ResultCode <> 0 Then
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
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 2;
			vFRPassword = GetUserPassword(True);
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 2;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
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
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 2;
			vFRPassword = GetUserPassword(True);
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 10;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
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
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Do report
			vFR.Mode = 3;
			vFRPassword = GetUserPassword(True);
			If vFRPassword = Undefined Then
				Raise NStr("ru = 'Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; en='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			vFR.ReportType = 1;
			vFR.Report();
			If vFR.ResultCode <> 0 Then
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
				vFR.Mode = 1;
				vFR.Caption = "";
				vFR.Password = "";
				vFR.OpenSession();
				tcOnServer.Wait(5);
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, True);
			
			// Check demo mode
			If vFR.IsDemo = 1 Then
				Raise NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			EndIf;
			
			// Set mode
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;	
			
			// Open cheque
			If pSum >= 0 Then
				vFR.CheckType = 1;
			Else
				vFR.CheckType = 2;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vFR.CheckMode = 1; // Do not print cheque on paper
			Else
				vFR.CheckMode = 0;
			EndIf;
			vFR.OpenCheck();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText));
					// Print cheque header
					vFR.PrintHeader();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Print payment number and section
			vFR.Name = "#" + TrimAll(pObj.Number);
			vFR.Department = 0;
			If Not CashRegister.DoNotPrintPaymentSections Then
				If ValueIsFilled(pObj.PaymentSection) Then
					vFR.Department = pObj.PaymentSection.Code;
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						vFR.Name = GetString(TrimR(vFR.Name) + " - " + pObj.PaymentSection.Description);
					EndIf;
				EndIf;
			EndIf;
			
			// Add tax
			vVATRate = Undefined;
			vVATSum = 0;
			vFR.Quantity = 1;
			vFR.Price = ?(pSum >= 0, pSum, -pSum);
			
			// Add position
			If pSum >= 0 Then
				vFR.Registration();
			Else
				vFR.Return();
			EndIf;
			If vFR.ResultCode <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;	
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vFR.Caption = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vFR.Caption = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.Caption = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vFR.TypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			Else
				vFR.TypeClose = 0;
			EndIf;
			vOpenDrawer = False;
			If vFR.TypeClose = 0 Then
				vOpenDrawer = True;
			EndIf;
			vFR.CloseCheck();
			If vFR.ResultCode <> 0 Then
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, True);
			
			// Check demo mode
			If vFR.IsDemo = 1 Then
				Raise NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			EndIf;
			
			// Set mode
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;	
			
			// Open cheque
			If pSum >= 0 Then
				vFR.CheckType = 1;
			Else
				vFR.CheckType = 2;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vFR.CheckMode = 1; // Do not print cheque on paper
			Else
				vFR.CheckMode = 0;
			EndIf;
			vFR.OpenCheck();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;	
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText));
					// Print cheque header
					vFR.PrintHeader();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Print services
			If Not CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
				For Each vSrvRow In pServices Do
					// Fill item attributes
					vPaymentSection = Undefined;
					vFR.Department = 0;
					vFR.Name = "";
					If ValueIsFilled(vSrvRow.Service) Then
						vFR.Name = GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						If ValueIsFilled(vSrvRow.PaymentSection) Then
							vPaymentSection = vSrvRow.PaymentSection;
							vFR.Department = vPaymentSection.Code;
						EndIf;
					EndIf;
					vFR.Quantity = vSrvRow.Quantity;
					vFR.Price = vSrvRow.Price;
					// Do registration
					vFR.Registration();
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndDo;
			Else
				// Print number and sections
				If pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vFR.Caption = "#" + TrimAll(pObj.Number);
						vFR.PrintString();
						If vFR.ResultCode <> 0 Then
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
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = vPSRow.PaymentSection.Code;
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = vPSRow.PaymentSection.Code;
								vFR.Name = GetString(vPSRow.PaymentSection.Description);
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							Else
								vFR.Department = 0;
								If vSectionAmount >=0 Then
									vFR.Name = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
								Else
									vFR.Name = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
								EndIf;
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							EndIf;
							// Do registration
							If vSectionAmount >= 0 Then
								vFR.Registration();
							Else
								vFR.Return();
							EndIf;
							If vFR.ResultCode <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
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
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = vPSRow.PaymentSection.Code;
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = vPSRow.PaymentSection.Code;
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							Else
								vFR.Department = 0;
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
							EndIf;
							// Do registration
							If vSectionAmount >= 0 Then
								vFR.Registration();
							Else
								vFR.Return();
							EndIf;
							If vFR.ResultCode <> 0 Then
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
								vVATAmount = vVATAmount - vPSRow.VATSum;
							Else
								vAmount = vAmount + vPSRow.Sum;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndIf;
						EndDo;
						// Print name, price and quantity
						vFR.Department = 0;
						vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						vFR.Quantity = 1;
						vFR.Price = ?(vAmount >= 0, vAmount, -vAmount);
						// Do registration
						If vAmount >= 0 Then
							vFR.Registration();
						Else
							vFR.Return();
						EndIf;
						If vFR.ResultCode <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
				Else
					vVATAmount = pObj.VATSum;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vVATAmount = -vVATAmount;
					EndIf;
					// Print name, price and quantity
					vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
					If Not CashRegister.PrintFolioHeader Then
						vFR.Name = "#" + TrimAll(pObj.Number);
					EndIf;
					vFR.Department = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.Department = pObj.PaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							If CashRegister.PrintFolioHeader Then
								vFR.Name = GetString(pObj.PaymentSection.Description);
							Else
								vFR.Name = GetString(TrimR(vFR.Name) + " - " + pObj.PaymentSection.Description);
							EndIf;
						EndIf;
					EndIf;
					vFR.Quantity = 1;
					vFR.Price = ?(pSum >= 0, pSum, -pSum);
					// Do registration
					If pSum >= 0 Then
						vFR.Registration();
					Else
						vFR.Return();
					EndIf;
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;	
				EndIf;
			EndIf;
			
			// Print VAT sum as string if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vFR.Caption = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vFR.Caption = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.Caption = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
				vFR.PrintString();
				If vFR.ResultCode <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vFR.TypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			Else
				vFR.TypeClose = 0;
			EndIf;
			vOpenDrawer = False;
			If vFR.TypeClose = 0 Then
				vOpenDrawer = True;
			EndIf;
			vFR.CloseCheck();
			If vFR.ResultCode <> 0 Then
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
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			If pSum > 0 Then
				vFRPassword = GetUserPassword(True);
				If vFRPassword = Undefined Then
					Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
				EndIf;
				
				// Close open cheque if any
				CloseOpenCheque(vFR, vFRPassword, True);
				// Check demo mode
				If vFR.IsDemo = 1 Then
					Raise NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
				EndIf;
				
				// Set mode
				vFR.Mode = 1;
				vFR.Password = vFRPassword;
				vFR.SetMode();
				If vFR.ResultCode <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;	
				
				// Open cheque
				vUseReturn = False;
				vFR.CheckType = 3;
				vFR.OpenCheck();
				If vFR.ResultCode = RC_WRONG_CHEQUE_TYPE Then
					vUseReturn = True;
					vFR.CheckType = 2;
					vFR.OpenCheck();
				EndIf;
				If vFR.ResultCode <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Print slip if payment was made by credit card
				If CashRegister.PrintSlipInCheque Then
					If Not IsBlankString(pObj.AnnulationSlipText) Then
						PrintSlipLines(vFR, cmGetTextLinesArray(pObj.AnnulationSlipText));
						// Print cheque header
						vFR.PrintHeader();
						If vFR.ResultCode <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndIf;
				
				// Cheque folio header
				If CashRegister.PrintFolioHeader Then
					PrintFolioHeader(vFR, pObj);
				EndIf;
				
				// Print document number and sections
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vFR.Caption = "#" + TrimAll(pObj.Number);
						vFR.PrintString();
						If vFR.ResultCode <> 0 Then
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
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							If vSectionAmount < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = vPSRow.PaymentSection.Code;
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = vPSRow.PaymentSection.Code;
								vFR.Name = GetString(vPSRow.PaymentSection.Description);
								vFR.Quantity = 1;
								vFR.Price = vSectionAmount;
							Else
								vFR.Department = 0;
								vFR.Name = NStr("en='Advance return for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат предоплаты за гостиничные услуги'");
								vFR.Quantity = 1;
								vFR.Price = vSectionAmount;
							EndIf;
							// Do annulation
							If vUseReturn Then
								vFR.Return();
							Else
								vFR.Annulate();
							EndIf;
							If vFR.ResultCode <> 0 Then
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
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							If vSectionAmount < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.Department = vPSRow.PaymentSection.Code;
								Else
									vFR.Department = 0;
								EndIf;
								vFR.Name = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								vFR.Quantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vFR.Price = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.Department = vPSRow.PaymentSection.Code;
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = vSectionAmount;
							Else
								vFR.Department = 0;
								vFR.Name = "";
								vFR.Quantity = 1;
								vFR.Price = vSectionAmount;
							EndIf;
							// Do annulation
							If vUseReturn Then
								vFR.Return();
							Else
								vFR.Annulate();
							EndIf;
							If vFR.ResultCode <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
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
								vVATAmount = vVATAmount - vPSRow.VATSum;
							Else
								vAmount = vAmount + vPSRow.Sum;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndIf;
						EndDo;
						If vAmount < 0 Then
							Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
						EndIf;
						// Print name, price and quantity
						vFR.Department = 0;
						vFR.Name = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						vFR.Quantity = 1;
						vFR.Price = vAmount;
						// Do annulation
						If vUseReturn Then
							vFR.Return();
						Else
							vFR.Annulate();
						EndIf;
						If vFR.ResultCode <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				Else
					vVATAmount = pObj.VATSum;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vVATAmount = -vVATAmount;
					EndIf;
					vAmount = pSum;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vAmount = -vAmount;
					EndIf;
					If vAmount < 0 Then
						Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
					EndIf;
					// Print name, price and quantity
					vFR.Name = "#" + TrimAll(pObj.Number);
					vFR.Department = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.Department = pObj.PaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							vFR.Name = GetString(TrimR(vFR.Name) + " - " + pObj.PaymentSection.Description);
						EndIf;
					EndIf;
					vFR.Quantity = 1;
					vFR.Price = vAmount;
					// Do annulation
					If vUseReturn Then
						vFR.Return();
					Else
						vFR.Annulate();
					EndIf;
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vFR.Caption = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vFR.Caption = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vFR.PrintString();
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.Caption = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
					vFR.PrintString();
					If vFR.ResultCode <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			
				// Close cheque
				If ValueIsFilled(pObj.PaymentMethod) Then
					vFR.TypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
				Else
					vFR.TypeClose = 0;
				EndIf;
				vOpenDrawer = False;
				If vFR.TypeClose = 0 Then
					vOpenDrawer = True;
				EndIf;
				vFR.CloseCheck();
				If vFR.ResultCode <> 0 Then
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
			Else
				Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulateCheque

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек аннуляции'; en=' storno cheque was issued'; de=' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(pFR, pSlipTextArr)
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.TextWrap = 0;
		pFR.Caption = vStr;
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
	// Print second slip for the client
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-8<--------------------------------------------------------------------");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.TextWrap = 0;
	pFR.Caption = " ";
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	pFR.PartialCut();
	pFR.TextWrap = 0;
	pFR.Caption = NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'");
	pFR.PrintString();
	If pFR.ResultCode <> 0 Then
		Return;
	EndIf;
	For Each vStr In pSlipTextArr Do
		pFR.TextWrap = 0;
		pFR.Caption = vStr;
		pFR.PrintString();
		If pFR.ResultCode <> 0 Then
			Return;
		EndIf;
	EndDo;
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, True);
			// Check demo mode
			If vFR.IsDemo = 1 Then
				Raise NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			EndIf;
			// Set mode
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			// Print all strings in the array
			PrintSlipLines(vFR, pSlipTextArr);
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			// Print cheque header
			vFR.PrintHeader();
			If vFR.ResultCode <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			vFR.FullCut();
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
	// Header start delimeter
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-----------------------------------------------------------------------");
	pFR.PrintString();
	// Folio #
	pFR.TextWrap = 0;
	pFR.Caption = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + cmGetDocumentNumberPresentation(pObj.Folio.Number));
	pFR.PrintString();
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		pFR.TextWrap = 0;
		pFR.Caption = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(pObj.Folio.Room)); 
		pFR.PrintString();
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		pFR.TextWrap = 0;
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.Caption = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer));
		Else
			pFR.Caption = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Folio.Client));
		EndIf;
		pFR.PrintString();
	EndIf;
	// Guest group
	pFR.TextWrap = 0;
	pFR.Caption = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup)); 
	pFR.PrintString();
	// Document
	pFR.TextWrap = 0;
	pFR.Caption = GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + cmGetDocumentNumberPresentation(pObj.Number));
	pFR.PrintString();
	// Header end delimeter
	pFR.TextWrap = 0;
	pFR.Caption = GetString("-----------------------------------------------------------------------"); 
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
			vFRPassword = GetUserPassword();
			If vFRPassword = Undefined Then
				Raise NStr("ru='Пароль ККМ должен быть указан!'; en='User cash register password should be entered!'; de='Benutzerkassen Passwort eingegeben werden!'");
			EndIf;
			
			// Close open cheque if any
			CloseOpenCheque(vFR, vFRPassword, False);
			
			// Set mode
			vFR.Mode = 1;
			vFR.Password = vFRPassword;
			vFR.SetMode();
			If vFR.ResultCode <> 0 And vFR.ResultCode <> -3822 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
				Return False;
			EndIf;
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = cmGetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vFR.PrintHeader();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj);
						If vFR.ResultCode <> 0 Then
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
					vFR.TextWrap = 0;
					vFR.Caption = GetString(vStr);
					vFR.PrintString();
					If vFR.ResultCode <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vFR.PrintHeader();
				If vFR.ResultCode <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			Else
				For s = 0 To 5 Do
					vFR.Caption = " ";
					vFR.PrintString();
				EndDo;
			EndIf;
			
			// Cut off cheque
			vFR.FullCut();
			
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
		// Check demo mode
		If vFR.IsDemo = 1 Then
			rMessage = NStr("ru='Не обнаружен ключ защиты драйвера ККМ фирмы Атол!'; en='Atol cash register driver dongle was not found!'; de='Atol cash register driver dongle was not found!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Retrieve cash register state
		vFR.GetCurrentMode();
		If vFR.ResultCode = RC_24_HOURS_LIMIT Then
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		ElsIf vFR.ResultCode <> 0 Then
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check paper
		If vFR.OutOfPaper = 1 Then
			rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check cheque printer
		If vFR.PrinterConnectionFailed = 1 Then
			rMessage = NStr("ru='ККМ не может установить связь с принтером чеков!'; en='Cash register failes to connect to the cheque printer!'; de='Cash register failes to connect to the cheque printer!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		If vFR.PrinterMechanismError = 1 Then
			rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		If vFR.PrinterOverheatError = 1 Then
			rMessage = NStr("ru='Перегрев принтера чеков! Повторите попытку позже.'; en='Cheque printer overheated! Wait a while and try again.'; de='Cheque printer overheated! Wait a while and try again.'");
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

// -----------------------------------------------------------------------------
RC_24_HOURS_LIMIT = -3822;
RC_NO_PAPER = -3807;
RC_CHECK_IS_OPEN = -3802;
RC_CONFIRM_DATE = -3893;
RC_WRONG_CHEQUE_TYPE = -3932;