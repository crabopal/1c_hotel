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
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	vTaxSystemDec = 0;
	rTaxSystem = Undefined;
	If ValueIsFilled(pObj.PaymentSection) And ValueIsFilled(pObj.PaymentSection.TaxationSystem) Then
		rTaxSystem = pObj.PaymentSection.TaxationSystem;
	ElsIf TypeOf(pObj.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pObj.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.TaxationSystem) Then
				rTaxSystem = vPaymentSection.TaxationSystem;
				Break;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pObj.Company) And ValueIsFilled(pObj.Company.TaxationSystem) Then
		rTaxSystem = pObj.Company.TaxationSystem;
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		vTaxSystemByte = "00000000";
		If rTaxSystem = Enums.TaxationSystems.Common Then
			vTaxSystemByte = "00000001";
		ElsIf rTaxSystem = Enums.TaxationSystems.SimplifiedIncome Then
			vTaxSystemByte = "00000010";
		ElsIf rTaxSystem = Enums.TaxationSystems.SimplifiedIncomeMinusOutcome Then
			vTaxSystemByte = "00000100";
		ElsIf rTaxSystem = Enums.TaxationSystems.UnifiedTaxOnImputedIncome Then
			vTaxSystemByte = "00001000";
		ElsIf rTaxSystem = Enums.TaxationSystems.UnifiedAgriculturalTax Then
			vTaxSystemByte = "00010000";
		ElsIf rTaxSystem = Enums.TaxationSystems.PatentTaxationSystem Then
			vTaxSystemByte = "00100000";
		EndIf;
		vTaxSystemDec = cmBin2Dec(vTaxSystemByte);
	EndIf;
	Return vTaxSystemDec;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate, pRowVATRate = Undefined, pDocObj = Undefined)
	vTaxGroupCode = 0;
	
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		rVATRate = pObj.VATRate;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vTaxGroupCode;
	EndIf;

	vRateDate = Undefined;
	If (TypeOf(pDocObj) = Type("DocumentObject.Return") Or TypeOf(pDocObj) = Type("DocumentRef.Return")) And ValueIsFilled(pDocObj.Payment) Then
		vRateDate = tcOnServer.cmGetAttributeByRef(pDocObj.Payment, "Date");
	EndIf;
	
	vVATRateParams = Undefined;
	If ValueIsFilled(vRateDate) Then
		vVATRateParams = tcCashRegisters.GetVATRateParams(rVATRate, vRateDate);
	EndIf;
	
	If vVATRateParams <> Undefined Then
		vTaxRate = vVATRateParams.TaxRate;
		vNoVAT = vVATRateParams.NoVAT;
		vTaxGroup = vVATRateParams.TaxGroup;
	Else
		vTaxRate = rVATRate.TaxRate;
		vNoVAT = rVATRate.NoVAT;
		vTaxGroup = rVATRate.TaxGroup;
	EndIf;
	
	If vNoVAT Then
		vTaxGroupCode = 4;
	ElsIf vTaxRate = 0 Then
		vTaxGroupCode = 3;
	ElsIf vTaxRate = 5 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 9;
		Else
			vTaxGroupCode = 7;
		EndIf;
	ElsIf vTaxRate = 7 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 10;
		Else
			vTaxGroupCode = 8;
		EndIf;
	ElsIf vTaxRate = 10 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 6;
		Else
			vTaxGroupCode = 2;
		EndIf;
	ElsIf vTaxRate = 20 Or vTaxRate = 18 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 5;
		Else
			vTaxGroupCode = 1;
		EndIf;
	ElsIf vTaxRate = 22 Then
		If vTaxGroup > 4 Then
			vTaxGroupCode = 12;
		Else
			vTaxGroupCode = 11;
		EndIf;
	Else
		vTaxGroupCode = vTaxGroup;
	EndIf;
	Return vTaxGroupCode;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function Connect(rMessage, pAskPwd = False)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vProgID = "AddIn.DrvFR";
		vDriverDLL = "DrvFR.dll";
		If CashRegister.CashRegisterModel = "Addin.KKTDrv" Then
			vProgID = "Addin.KKTDrv";
			vDriverDLL = "KKTDrv.dll";
		EndIf;
		
		Try
			vFR = New COMObject(vProgID);
		Except
			#IF CLIENT THEN
				Try
					AttachAddIn(vProgID);
					vFR = New(vProgID);
				Except
					LoadAddIn(vDriverDLL);
					vFR = New(vProgID);
				EndTry;
			#ELSE
				vFR = New COMObject(vProgID);
			#ENDIF
		EndTry;
		
		vFR.UseIPAddress = False;
		
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
			vPassword = vFR.Password;
			If ValueIsFilled(CashRegister.CashRegisterPassword) Then
				vFR.Password = TrimR(CashRegister.CashRegisterPassword);
			ElsIf ValueIsFilled(CashRegister.AccessPassword) Then
				vFR.Password = TrimR(CashRegister.AccessPassword);
			EndIf;
			
			vCashier = SessionParameters.CurrentUser;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				
				vFR.TableNumber = 2;
				vFR.RowNumber = 30;
				vFR.FieldNumber = 2;
				vFR.ValueOfFieldString = vCashierName;
				vFR.WriteTable();
			EndIf;
			
			vFR.Password = vPassword;
			
			DisableMapping22(vFR, CashRegister);
			
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
Function CheckPaper(pFR, pFunction, rMessage)
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
EndFunction // CheckPaper

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR)
	If pFR.ECRMode = 8 Then
		// Close cheque with sys admin password
		pFR.ResetECR();
		If pFR.ResultCode = 89 Then
			vPassword = pFR.Password;
			If ValueIsFilled(CashRegister.CashRegisterPassword) Then
				pFR.Password = TrimR(CashRegister.CashRegisterPassword);
			ElsIf ValueIsFilled(CashRegister.AccessPassword) Then
				pFR.Password = TrimR(CashRegister.AccessPassword);
			EndIf;
			pFR.SysAdminCancelCheck();
			pFR.Password = vPassword;
			pFR.ResetECR();
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
		pFR.FNCancelDocument();
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
	pFR.GetECRStatus();
	If CheckResultCode(pFR.ResultCode) Then
		If pFR.ECRAdvancedMode = 5 Then
			cmWait(5);
			pFR.GetECRStatus();
			If CheckResultCode(pFR.ResultCode) Then
				If pFR.ECRAdvancedMode = 5 Then
					cmWait(5);	
				EndIf;
			Else
				ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
				Return False;		
			EndIf;
		EndIf;
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверкаВремени'"), rMessage);
		Return False;	
	EndIf;
	
	
	vCurDate = CurrentSessionDate();
	
	// Set device date
	pFR.Date = BegOfDay(vCurDate);
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
	pFR.Time = BegOfDay(pFR.Time) + ((Hour(vCurDate) * 3600) + (Minute(vCurDate) * 60) + (Second(vCurDate)));
	pFR.SetTime();
	If Not CheckResultCode(pFR.ResultCode) Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.GetECRStatus();
	If CheckResultCode(pFR.ResultCode) Then
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
			rMessage = NStr("en='Check date in the cash register!'; de='Check date in the cash register!'; ru='Проверьте дату в ККМ!'");
			Return False;
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
			// Start close session
			vFR.FNBeginCloseSession();
			// Set cashier name
			vCashier = SessionParameters.CurrentUser;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.TagNumber = 1021;
					vFR.TagType = 7;
					vFR.TagValueStr = vCashierName;
					vFR.FNSendTag();
					
					// Set TIN
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.TagNumber = 1203;
						vFR.TagType = 7;
						vFR.TagValueStr	= vEmployeeTIN;
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			// Close session
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
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
		Try       
			vBreakOpenNewSession = False;
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vFR, rMessage) Then
				tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Time setting error in cash register'; de = 'Zeiteinstellungsfehler in der Registrierkassen'; ru = 'Ошибка установки времени в ККМ'")); 	
				vBreakOpenNewSession = True;
			EndIf;
			// Open new session
			If Not CashRegister.DoNotOpenNewSessionAfterZReport And Not vBreakOpenNewSession Then
				vFR.GetECRStatus();
				If CheckResultCode(vFR.ResultCode) Then
					If vFR.ECRAdvancedMode = 5 Then
						cmWait(5);	
					EndIf;
				Else
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
					tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error opening shift in cash register'; de = 'Fehler beim Öffnen der Schicht in der Registrierkasse'; ru = 'Ошибка открытия смены в ККМ'")); 	
					vBreakOpenNewSession = True;	
				EndIf;
				If Not vBreakOpenNewSession Then
					vFR.FNBeginOpenSession();
					// Set cashier name
					If ValueIsFilled(vCashier) Then
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
					vFR.OpenSession();
					If Not CheckResultCode(vFR.ResultCode) Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
						tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error opening shift in cash register'; de = 'Fehler beim Öffnen der Schicht in der Registrierkasse'; ru = 'Ошибка открытия смены в ККМ'")); 	
					EndIf;
				EndIf;
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
		EndTry;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage, True);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Check if paper is present
			If Not CheckPaper(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage) Then
				Disconnect(vFR);
				Return False;
			EndIf;			
			// Close open cheque if any
			CloseOpenCheque(vFR);
			// Print report
			vFR.FNBuildCalculationStateReport();
			If Not CheckResultCode(vFR.ResultCode) Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
			If pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.CalculationSign = 3;
				Else
					vFR.CalculationSign = 1;
				EndIf;
				vFR.FNBeginCorrectionReceipt();
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.CheckType = 2;
				Else
					vFR.CheckType = 0;
				EndIf;
				If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
					// Do not print cheque on paper
					vFR.TableNumber			= 17;			
					vFR.FieldNumber			= 7;
					vFR.ValueOfFieldInteger = 1;
					vFR.WriteTable();
				EndIf;
				vFR.OpenCheck();
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				// Correction type
				If pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder") Then
					vFR.CorrectionType = 1;
				Else
					vFR.CorrectionType = 0;
				EndIf;
				vChequeAttributes.CorrectionType = pCorrectionType;
				// Fill remarks, order date and number
				If ValueIsFilled(pCorrectionDocumentDate) Or Not IsBlankString(pCorrectionDocumentNumber) Then
					vFR.TagID = 0;
					vFR.TagNumber = 1174;
					vFR.FNBeginSTLVTag();
					If ValueIsFilled(pCorrectionDocumentDate) Then
						vFR.TagNumber = 1178;
						vFR.TagType = 6;
						vFR.TagValueDateTime = pCorrectionDocumentDate;
						vFR.FNAddTag();
						vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
					EndIf;
					If Not IsBlankString(pCorrectionDocumentNumber) Then
						vFR.TagNumber = 1179;
						vFR.TagType = 7;
						vFR.TagValueStr = TrimAll(pCorrectionDocumentNumber);
						vFR.FNAddTag();
						vChequeAttributes.CorrectionDocumentNumber = TrimAll(pCorrectionDocumentNumber);
					EndIf;
					vFR.FNSendSTLVTag();
				EndIf;
			EndIf;				
			
			If vFR.ECRSoftDate > Date(2025, 8, 1) Then
				If pObj.PaymentMethod.IsViaInternetAcquiring Then
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 1;
					vFR.FNSendTag();
					
					vHotelSite = "";
					If Not IsBlankString(CashRegister.PaymentAddress) Then
						vHotelSite = TrimAll(CashRegister.PaymentAddress);
					EndIf;
					
					If IsBlankString(vHotelSite) And ValueIsFilled(pObj.Hotel) Then
						vHotelSite = tcOnServer.cmGetAttributeByRef(pObj.Hotel, "Site");
					EndIf;
					
					If IsBlankString(vHotelSite) Then
						rMessage = NStr("en = 'The hotel website is not specified in the hotel settings (required to specify the payment location in the check)'; de = 'Die Hotelwebsite ist in den Hoteleinstellungen nicht angegeben (erforderlich, um den Zahlungsort im Scheck anzugeben)'; ru = 'В настройка гостинцы не указан сайт отеля (требуется для указания места расчёта в чеке)'");
						Disconnect(vFR);
						Return False;
					EndIf;
					
					vFR.TagNumber = 1187;
					vFR.TagType = 7;
					vFR.TagValueStr = vHotelSite;
					vFR.FNSendTag();
				Else
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 0;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
			// Send client e-mail
			vEMail = "";
			vPayer = Undefined;
			If TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
				If ValueIsFilled(pObj.AccountingCustomer) Then
					vPayer = pObj.AccountingCustomer;
				EndIf;
			EndIf;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					vEMail = TrimAll(vPayer.EMail);
				EndIf;
			EndIf;
			If Not IsBlankString(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.CustomerEmail = vEMail;
				vFR.FNSendCustomerEmail();
				vChequeAttributes.BuyerAddress = vEMail;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			If vTaxSystemCode > 0 Then
				vFR.TaxType = vTaxSystemCode;
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.TagNumber = 1021;
					vFR.TagType = 7;
					vFR.TagValueStr = vCashierName;
					vFR.FNSendTag();
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vCashierTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vCashierTIN) Then
						vFR.TagNumber = 1203;
						vFR.TagType = 7;
						vFR.TagValueStr	= vCashierTIN;
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vFR.TagNumber = 1256;
					vFR.FNBeginSTLVTag();
					vTagID = vFR.TagID;
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNAddTag();
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNAddTag(); 
					
					vFR.FNSendSTLVTag();
				Else
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNSendTag();
					
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
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
			If Not pIsCorrection Or pIsCorrection And CashRegister.FiscalDataFormatVersions <> Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
				vFR.StringForPrinting = "#" + TrimAll(pObj.Number);
				
				// Operation type
				If pSum < 0 Then
					vFR.CheckType = 2;
				Else
					vFR.CheckType = 1;
				EndIf;
				
				// Department and cheque postion
				vFR.Department = 0;
				If Not CashRegister.DoNotPrintPaymentSections Then
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.Department = pObj.PaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						EndIf;
					EndIf;
				EndIf;
				
				// Cheque position extra attributes
				// Payment item sign
				vItemTypeRef = cmGetChequeItemType(pObj, Undefined, pObj.PaymentSection);
				vItemType = cmGetChequeItemTypeValue(vItemTypeRef);
				vFR.PaymentItemSign = vItemType;
				
				// Payment type sign
				vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
				vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
				vFR.PaymentTypeSign = vPaymentMode;
				If pObj.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					// This is advance settlement
					Raise NStr("en='Advance settlements are not supported for customer payments!'; ru='Зачет аванса в платежах контрагента не поддерживается!'; de='Nicht unterstützt'");
				EndIf;
				
				// Add tax
				vVATRate = Undefined;
				vVATSum = 0;
				If ValueIsFilled(pObj.PaymentSection) And ValueIsFilled(pObj.PaymentSection.VATRate) Then
					vFR.Tax1 = GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj);
				Else
					vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
				EndIf;
				vVATSum = pObj.VATSum;
				vFR.TaxValue = vVATSum;
				vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
				vFR.TaxValueEnabled = True;
				cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
				
				vFR.Price = ?(pSum < 0, -pSum, pSum);
				vFR.Quantity = 1;
				vFR.Summ1 = vFR.Price;
				vFR.Summ1Enabled = True;  
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vFR.MeasureUnit = GetUnitPiece(Undefined);
				EndIf;
				vFR.FNOperation(); 
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
			
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			If vTypeClose = 16 Then
				vFR.Summ16 = vCloseSum;
			ElsIf vTypeClose = 6 Then
				vFR.Summ6 = vCloseSum;
			ElsIf vTypeClose = 5 Then
				vFR.Summ5 = vCloseSum;
			ElsIf vTypeClose = 4 Then
				vFR.Summ4 = vCloseSum;
			ElsIf vTypeClose = 3 Then
				vFR.Summ3 = vCloseSum;
			ElsIf vTypeClose = 2 Then
				vFR.Summ2 = vCloseSum;
			Else
				vOpenDrawer = True;
				vFR.Summ1 = vCloseSum;
			EndIf;
			
			If Not pIsCorrection Then
				vFR.FNCloseCheckEx();
			Else
				// Fill VAT
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
					If pObj.VATRate.TaxRate = 18 Then
						vFR.Summ7 = pObj.VATSum;
					ElsIf pObj.VATRate.TaxRate = 20 Then
						vFR.Summ7 = pObj.VATSum;
					ElsIf pObj.VATRate.TaxRate = 10 Then
						vFR.Summ8 = pObj.VATSum;
					ElsIf pObj.VATRate.NoVAT Then
						vFR.Summ10 = pObj.VATSum;
					ElsIf pObj.VATRate.TaxRate = 0 Then
						vFR.Summ9 = pObj.VATSum;
					Else
						vFR.Summ11 = pObj.VATSum;
					EndIf;
				EndIf;
				vFR.FNBuildCorrectionReceipt2();
			EndIf;
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			If pSum < 0 Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			EndIf;
			vFR.FNGetStatus();
			vChequeAttributes.ChequeSequenceNumber = vFR.DocumentNumber;
			vChequeAttributes.ChequeDateTime = vFR.Date + (vFR.Time - BegOfDay(vFR.Time));
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
			vChequeAttributes.ChequeFiscalNumber = Format(Number(vFR.FiscalSignAsString), "ND=10; NFD=; NLZ=; NG=");
			vFR.FNGetCurrentSessionParams();
			vChequeAttributes.CashDayChequeNumber = vFR.ReceiptNumber;
			vChequeAttributes.CashDay = vFR.SessionNumber;
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj, vChequeAttributes);
			
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
	vIsPrepayment = False;
	
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
			If pIsCorrection Then
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.CalculationSign = 3;
				Else
					vFR.CalculationSign = 1;
				EndIf;
				vFR.FNBeginCorrectionReceipt();
			Else
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.CheckType = 2;
				Else
					vFR.CheckType = 0;
				EndIf;
				If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
					// Do not print cheque on paper
					vFR.TableNumber			= 17;			
					vFR.FieldNumber			= 7;
					vFR.ValueOfFieldInteger = 1;
					vFR.WriteTable();
				EndIf;
				vFR.OpenCheck();
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				// Correction type
				If pCorrectionType = Enums.CorrectionChequeTypes.ByOrder Then
					vFR.CorrectionType = 1;
				Else
					vFR.CorrectionType = 0;
				EndIf;
				vChequeAttributes.CorrectionType = pCorrectionType;
				
				// Fill remarks, order date and number
				vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
				If ValueIsFilled(vCorrectionDocumentDate) Then
					vFR.TagNumber = 1178;
					vFR.TagType = 6;
					vFR.TagValueDateTime = vCorrectionDocumentDate;
					vFR.FNSendTag();
					vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
				Else
					rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
					|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
					|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
					Return False;
				EndIf;
				
				vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
				vFR.TagNumber = 1179;
				vFR.TagType = 7;
				vFR.TagValueStr = vCorrectionDocumentNumber;
				vFR.FNSendTag();
				vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
			EndIf;				
			
			// Print FPD of the base cheque if return
			If pObj.CorrectionOfIncorrectCheque Then
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					// Get payment cheque attributes
					vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
					If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
						vFR.TagNumber = 1192;
						vFR.TagType = 7;
						vFR.TagValueStr = TrimAll(vPaymentAttrs.ChequeFiscalNumber);
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			If vFR.ECRSoftDate > Date(2025, 8, 1) Then
				If pObj.PaymentMethod.IsViaInternetAcquiring Then
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 1;
					vFR.FNSendTag();
					
					vHotelSite = "";
					If Not IsBlankString(CashRegister.PaymentAddress) Then
						vHotelSite = TrimAll(CashRegister.PaymentAddress);
					EndIf;
					
					If IsBlankString(vHotelSite) And ValueIsFilled(pObj.Hotel) Then
						vHotelSite = tcOnServer.cmGetAttributeByRef(pObj.Hotel, "Site");
					EndIf;
					
					If IsBlankString(vHotelSite) Then
						rMessage = NStr("en = 'The hotel website is not specified in the hotel settings (required to specify the payment location in the check)'; de = 'Die Hotelwebsite ist in den Hoteleinstellungen nicht angegeben (erforderlich, um den Zahlungsort im Scheck anzugeben)'; ru = 'В настройка гостинцы не указан сайт отеля (требуется для указания места расчёта в чеке)'");
						Disconnect(vFR);
						Return False;
					EndIf;
					
					vFR.TagNumber = 1187;
					vFR.TagType = 7;
					vFR.TagValueStr = vHotelSite;
					vFR.FNSendTag();
				Else
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 0;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
			// Send client e-mail
			vEMail = "";
			vPayer = Undefined;
			If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) Then
				If ValueIsFilled(pObj.Payer) Then
					vPayer = pObj.Payer;
				EndIf;
			EndIf;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					vEMail = TrimAll(vPayer.EMail);
				EndIf;
			EndIf;
			If Not IsBlankString(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.CustomerEmail = vEMail;
				vFR.FNSendCustomerEmail();
				vChequeAttributes.BuyerAddress = vEMail;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			If vTaxSystemCode > 0 Then
				vFR.TaxType = vTaxSystemCode;
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.TagNumber = 1021;
					vFR.TagType = 7;
					vFR.TagValueStr = vCashierName;
					vFR.FNSendTag();
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vCashierTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vCashierTIN) Then
						vFR.TagNumber = 1203;
						vFR.TagType = 7;
						vFR.TagValueStr	= vCashierTIN;
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vFR.TagNumber = 1256;
					vFR.FNBeginSTLVTag();
					vTagID = vFR.TagID;
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNAddTag();
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNAddTag(); 
					
					vFR.FNSendSTLVTag();
				Else
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNSendTag();
					
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
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
			If Not pIsCorrection Or pIsCorrection And CashRegister.FiscalDataFormatVersions <> Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
				If Not CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						// Operation type
						vFR.CheckType = 1;
						
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
						
						// Cheque position extra attributes
						// Payment item sign
						vItemTypeRef = cmGetChequeItemType(pObj, vSrvRow.Service, vPaymentSection);
						vItemType = cmGetChequeItemTypeValue(vItemTypeRef);
						vFR.PaymentItemSign = vItemType;
						
						// Payment type sign
						vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
						vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
						vFR.PaymentTypeSign = vPaymentMode;
						
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
							vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj);
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vFR.TaxValue = cmCalculateVATSum(vVATRate, vSrvRow.Amount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
						Else
							vFR.TaxValue = cmCalculateVATSum(vVATRate, vSrvRow.Amount, pObj.Date);
						EndIf;
						vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
						vFR.TaxValueEnabled = True;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vFR.TaxValue);
						
						// Do sale
						vFR.Summ1 = vSrvRow.Amount;
						vFR.Summ1Enabled = True;
						vItemQuantity = vSrvRow.Quantity;
						vItemPrice = vSrvRow.Price;
						tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
						vFR.Price = vItemPrice;
						vFR.Quantity = vItemQuantity;
						If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vFR.MeasureUnit = GetUnitPiece(vSrvRow.Service);
						EndIf;
						vFR.FNOperation();  
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
						
						If ValueIsFilled(vSrvRow.Service) Then
							vService = vSrvRow.Service;
							// Commissioner mark
							vIsAgentService = vService.IsAgentService;
							If vIsAgentService Then
								// Commissioner attribute
								vFR.TagNumber = 1222;
								vFR.TagType = 0; // Int
								vFR.TagValueInt = 32; // 32 - Commissioner; 64 - other agent
								vFR.FNSendTagOperation();
								// Principal
								vPrincipal = vService.Principal;
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									// Commissioner TIN
									If Not IsBlankString(vPrincipalTIN) Then
										vFR.TagNumber = 1226;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalTIN;
										vFR.FNSendTagOperation();
									EndIf;
									If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
										vFR.TagID = 0;
										vFR.TagNumber = 1224;
										vFR.FNBeginSTLVTag();
										// Principal name
										vFR.TagNumber = 1225;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalName;
										vFR.FNAddTag();
										// Principal phone
										vFR.TagNumber = 1171;
										vFR.TagType = 7;
										vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
										vFR.FNAddTag();
										vFR.FNSendSTLVTagOperation();
									EndIf;
								EndIf;
							EndIf;
							// Item code
							vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vService, "CashRegisterItemCode"));
							If Not IsBlankString(vCashRegisterItemCode) Then
								vFR.MarkingType = 17677; //EAN-13
								vFR.BarCode = vCashRegisterItemCode;
								vFR.FNSendItemCodeData();
							EndIf;
							// Excise
							If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
								vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vService.ExciseDutyType, pObj.Date, vService.Volume, vItemQuantity);
								If vExciseAmount <> 0 Then
									vFR.TagNumber = 1229;
									vFR.TagType = 3;
									vFR.TagValueLength = 6;
									vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
									vFR.FNSendTagOperation();
								EndIf;
							EndIf;
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
						
						vPSRows = cmGetPrintableChequePositions(pObj, vIsPrepayment, CashRegister.AlwaysUseAveragePrice);
						
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
								
								// Operation type
								If vSectionAmount < 0 Then
									vFR.CheckType = 2;
								Else
									vFR.CheckType = 1;
								EndIf;
								
								// Department and cheque postion
								vPaymentSection = Undefined;
								vFR.Department = 0;
								vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Услуги гостиницы'");
								If ValueIsFilled(vPSRow.Item) Then
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vPaymentSection = vPSRow.PaymentSection;
										vFR.Department = vPaymentSection.Code;
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
								ElsIf ValueIsFilled(vPSRow.ChequeService) Then
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vPaymentSection = vPSRow.PaymentSection;
										vFR.Department = vPaymentSection.Code;
									EndIf;
									vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vPaymentSection = vPSRow.PaymentSection;
									vFR.Department = vPaymentSection.Code;
									vFR.StringForPrinting = GetString(vPaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								Else
									If vSectionAmount >=0 Then
										vFR.StringForPrinting = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vFR.StringForPrinting = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
								EndIf;
								
								// Cheque position extra attributes
								// Payment item sign
								vItemTypeRef = cmGetChequeItemType(pObj, vPSRow.ChequeService, vPaymentSection, vIsPrepayment);
								vItemType = cmGetChequeItemTypeValue(vItemTypeRef);
								vFR.PaymentItemSign = vItemType;
								
								// Payment type sign
								vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPaymentSection), vIsPrepayment);
								vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
								vFR.PaymentTypeSign = vPaymentMode;
								
								// Add tax
								vVATRate = Undefined;
								vVATSum = 0;
								If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
									vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								vVATSum = vPSRow.VATSum;
								vFR.TaxValue = vVATSum;
								vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
								vFR.TaxValueEnabled = True;
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
								
								// Do sale
								If vSectionAmount >= 0 Then
									vFR.Summ1 = vSectionAmount;
								Else
									vFR.Summ1 = -vSectionAmount;
								EndIf;
								vFR.Summ1Enabled = True;
								vItemPrice = 0;
								vItemQuantity = 0;
								If ValueIsFilled(vPSRow.ChequeService) Then
									If vPSRow.ChequeServiceQuantity <> 0 Then
										vItemQuantity = vPSRow.ChequeServiceQuantity;
										vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									Else
										vItemQuantity = 1;
									EndIf;
									vItemPrice = Round(vFR.Summ1 / vItemQuantity, 2);
								Else
									vItemQuantity = 1;
									vItemPrice = vFR.Summ1;
								EndIf;
								tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
								vFR.Price = vItemPrice;
								vFR.Quantity = vItemQuantity;
								If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
									vFR.MeasureUnit = GetUnitPiece(vPSRow.ChequeService);
								EndIf;
								vFR.FNOperation();
								If Not CheckResultCode(vFR.ResultCode) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;	
								
								If ValueIsFilled(vPSRow.ChequeService) Then
									vChequeService = vPSRow.ChequeService;
									// Commissioner mark
									vIsAgentService = vChequeService.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vFR.TagNumber = 1222;
										vFR.TagType = 0; // Int
										vFR.TagValueInt = 32; // 32 - Commissioner; 64 - other agent
										vFR.FNSendTagOperation();
										// Principal
										vPrincipal = vChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											// Commissioner TIN
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.TagNumber = 1226;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalTIN;
												vFR.FNSendTagOperation();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.TagID = 0;
												vFR.TagNumber = 1224;
												vFR.FNBeginSTLVTag();
												// Principal name
												vFR.TagNumber = 1225;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalName;
												vFR.FNAddTag();
												// Principal phone
												vFR.TagNumber = 1171;
												vFR.TagType = 7;
												vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
												vFR.FNAddTag();
												vFR.FNSendSTLVTagOperation();
											EndIf;
										EndIf;
									EndIf;
									// Item code
									vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vChequeService, "CashRegisterItemCode"));
									If Not IsBlankString(vCashRegisterItemCode) Then
										vFR.MarkingType = 17677; //EAN-13
										vFR.BarCode = vCashRegisterItemCode;
										vFR.FNSendItemCodeData();
									EndIf;
									// Excise
									If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
										vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vChequeService.ExciseDutyType, pObj.Date, vChequeService.Volume, vItemQuantity);
										If vExciseAmount <> 0 Then
											vFR.TagNumber = 1229;
											vFR.TagType = 3;
											vFR.TagValueLength = 6;
											vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
											vFR.FNSendTagOperation();
										EndIf;
									EndIf;
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
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vSectionAmount = -vSectionAmount;
								EndIf;
								
								// Operation type
								If vSectionAmount < 0 Then
									vFR.CheckType = 2;
								Else
									vFR.CheckType = 1;
								EndIf;
								
								// Department and cheque postion
								vPaymentSection = Undefined;
								vFR.Department = 0;
								vFR.StringForPrinting = "";
								If ValueIsFilled(vPSRow.Item) Then
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vPaymentSection = vPSRow.PaymentSection;
										vFR.Department = vPaymentSection.Code;
									EndIf;
									vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
								ElsIf ValueIsFilled(vPSRow.ChequeService) Then
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
								
								// Cheque position extra attributes
								// Payment item sign
								vItemTypeRef = cmGetChequeItemType(pObj, vPSRow.ChequeService, vPaymentSection, vIsPrepayment);
								vItemType = cmGetChequeItemTypeValue(vItemTypeRef);
								vFR.PaymentItemSign = vItemType;
								
								// Payment type sign
								vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPaymentSection), vIsPrepayment);
								vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
								vFR.PaymentTypeSign = vPaymentMode;
								
								// Add tax
								vVATRate = Undefined;
								vVATSum = 0;
								If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
									vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								vVATSum = vPSRow.VATSum;
								vFR.TaxValue = vVATSum;
								vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
								vFR.TaxValueEnabled = True;
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
								
								// Do sale
								If vSectionAmount >= 0 Then
									vFR.Summ1 = vSectionAmount;
								Else
									vFR.Summ1 = -vSectionAmount;
								EndIf;
								vFR.Summ1Enabled = True;
								vItemPrice = 0;
								vItemQuantity = 0;
								If ValueIsFilled(vPSRow.ChequeService) Then
									If vPSRow.ChequeServiceQuantity <> 0 Then
										vItemQuantity = vPSRow.ChequeServiceQuantity;
										vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									Else
										vItemQuantity = 1;
									EndIf;
									vItemPrice = Round(vFR.Summ1 / vItemQuantity, 2);
								Else
									vItemQuantity = 1;
									vItemPrice = vFR.Summ1;
								EndIf;
								tcCashRegisters.ChequeItemAttributesCorrection(vFR.Summ1, vItemQuantity, 6, vItemPrice, vItemQuantity);
								vFR.Price = vItemPrice;
								vFR.Quantity = vItemQuantity;
								If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
									vFR.MeasureUnit = GetUnitPiece(vPSRow.ChequeService);
								EndIf;
								vFR.FNOperation();
								If Not CheckResultCode(vFR.ResultCode) Then
									CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;	
								
								If ValueIsFilled(vPSRow.ChequeService) Then
									vChequeService = vPSRow.ChequeService;
									// Commissioner mark
									vIsAgentService = vChequeService.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vFR.TagNumber = 1222;
										vFR.TagType = 0; // Int
										vFR.TagValueInt = 32; // 32 - Commissioner; 64 - other agent
										vFR.FNSendTagOperation();
										// Principal
										vPrincipal = vChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											// Commissioner TIN
											If Not IsBlankString(vPrincipalTIN) Then
												vFR.TagNumber = 1226;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalTIN;
												vFR.FNSendTagOperation();
											EndIf;
											If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
												vFR.TagID = 0;
												vFR.TagNumber = 1224;
												vFR.FNBeginSTLVTag();
												// Principal name
												vFR.TagNumber = 1225;
												vFR.TagType = 7;
												vFR.TagValueStr = vPrincipalName;
												vFR.FNAddTag();
												// Principal phone
												vFR.TagNumber = 1171;
												vFR.TagType = 7;
												vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
												vFR.FNAddTag();
												vFR.FNSendSTLVTagOperation();
											EndIf;
										EndIf;
									EndIf;
									// Item code
									vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vChequeService, "CashRegisterItemCode"));
									If Not IsBlankString(vCashRegisterItemCode) Then
										vFR.MarkingType = 17677; //EAN-13
										vFR.BarCode = vCashRegisterItemCode;
										vFR.FNSendItemCodeData();
									EndIf;
									// Excise
									If vItemType = 2 Or vItemType = 30 Or vItemType = 31 Then
										vExciseAmount = tcCashRegisters.GetChequeItemExciseValue(vChequeService.ExciseDutyType, pObj.Date, vChequeService.Volume, vItemQuantity);
										If vExciseAmount <> 0 Then
											vFR.TagNumber = 1229;
											vFR.TagType = 3;
											vFR.TagValueLength = 6;
											vFR.TagValueVLN = Format(vExciseAmount * 100, "NFD=0; NZ=; NG=");
											vFR.FNSendTagOperation();
										EndIf;
									EndIf;
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
							
							// Operation type
							If vAmount < 0 Then
								vFR.CheckType = 2;
							Else
								vFR.CheckType = 1;
							EndIf;
							
							// Department and cheque postion
							vFR.Department = 0;
							vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
							
							// Cheque position extra attributes
							// Payment item sign
							vItemType = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
							vFR.PaymentItemSign = vItemType;
							
							// Payment type sign
							vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
							vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
							vFR.PaymentTypeSign = vPaymentMode;
							
							// Add tax
							vVATRate = Undefined;
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
							vFR.TaxValue = vVATAmount;
							vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
							vFR.TaxValueEnabled = True;
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATAmount);
							
							// Do sale
							vFR.Quantity = 1;
							If vAmount >= 0 Then
								vFR.Price = vAmount;
							Else
								vFR.Price = -vAmount;
							EndIf;
							If vAmount >= 0 Then
								vFR.Summ1 = vAmount;
							Else
								vFR.Summ1 = -vAmount;
							EndIf;
							vFR.Summ1Enabled = True;
							If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
								vFR.MeasureUnit = GetUnitPiece(Undefined);
							EndIf;
							vFR.FNOperation();
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
						
						// Operation type
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vFR.CheckType = 2;
						Else
							vFR.CheckType = 1;
						EndIf;
						
						// Department and cheque postion
						vPaymentSection = Undefined;
						vFR.Department = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vPaymentSection = pObj.PaymentSection;
							vFR.Department = vPaymentSection.Code;
							If CashRegister.PrintPaymentSectionNamesInCheques Then
								If Not CashRegister.PrintFolioHeader Then
									vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + vPaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								Else
									vFR.StringForPrinting = GetString(vPaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								EndIf;
							EndIf;
						EndIf;
						
						// Cheque position extra attributes
						// Payment item sign
						vItemTypeRef = cmGetChequeItemType(pObj, Undefined, vPaymentSection);
						vItemType = cmGetChequeItemTypeValue(vItemTypeRef);
						vFR.PaymentItemSign = vItemType;
						
						// Payment type sign
						vPaymentModeRef = cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection);
						vPaymentMode = cmGetChequePaymentModeTypeValue(vPaymentModeRef);
						vFR.PaymentTypeSign = vPaymentMode;
						
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
							vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, , pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
						EndIf;
						vFR.TaxValue = pObj.VATSum;
						vFR["TaxValue"+vFR.Tax1] = vFR.TaxValue;
						vFR.TaxValueEnabled = True;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, pObj.VATSum);
						
						// Do sale
						vFR.Quantity = 1;
						If pSum >= 0 Then
							vFR.Price = pSum;
						Else
							vFR.Price = -pSum;
						EndIf;
						If pSum >= 0 Then
							vFR.Summ1 = pSum;
						Else
							vFR.Summ1 = -pSum;
						EndIf;
						vFR.Summ1Enabled = True;
						If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vFR.MeasureUnit = GetUnitPiece(Undefined);
						EndIf;
						vFR.FNOperation();
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
			
			vFR.Summ1 = 0; vFR.Summ2 = 0; vFR.Summ3 = 0; vFR.Summ4 = 0; vFR.Summ5 = 0; vFR.Summ6 = 0; vFR.Summ7 = 0; vFR.Summ8 = 0; vFR.Summ9 = 0; vFR.Summ10 = 0; vFR.Summ11 = 0; vFR.Summ12 = 0; vFR.Summ13 = 0; vFR.Summ14 = 0; vFR.Summ15 = 0; vFR.Summ16 = 0;
			
			If pObj.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
				vFR.Summ14 = vCloseSum;
				vChequeAttributes.Sum = vCloseSum;
			Else
				If vTypeClose = 16 Then
					vFR.Summ16 = vCloseSum;
				ElsIf vTypeClose = 6 Then
					vFR.Summ6 = vCloseSum;
				ElsIf vTypeClose = 5 Then
					vFR.Summ5 = vCloseSum;
				ElsIf vTypeClose = 4 Then
					vFR.Summ4 = vCloseSum;
				ElsIf vTypeClose = 3 Then
					vFR.Summ3 = vCloseSum;
				ElsIf vTypeClose = 2 Then
					vFR.Summ2 = vCloseSum;
				Else
					vOpenDrawer = True;
					vFR.Summ1 = vCloseSum;
				EndIf;
			EndIf;
			
			If Not pIsCorrection Then
				vFR.FNCloseCheckEx();
			Else
				// Fill VAT
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
					If pObj.PaymentSections.Count() > 0 Then
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum <> 0 Then
								If ValueIsFilled(vPSRow.VATRate) And vPSRow.VATRate.TaxRate = 18 Then
									vFR.Summ7 = vFR.Summ7 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And vPSRow.VATRate.TaxRate = 20 Then
									vFR.Summ7 = vFR.Summ7 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And vPSRow.VATRate.TaxRate = 10 Then
									vFR.Summ8 = vFR.Summ8 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And vPSRow.VATRate.NoVAT Then
									vFR.Summ10 = vFR.Summ10 + vPSRow.VATSum;
								ElsIf ValueIsFilled(vPSRow.VATRate) And vPSRow.VATRate.TaxRate = 0 Then
									vFR.Summ9 = vFR.Summ9 + vPSRow.VATSum;
								Else
									vFR.Summ11 = vFR.Summ11 + vPSRow.VATSum;
								EndIf;
							EndIf;
						EndDo;
					ElsIf ValueIsFilled(pObj.VATRate) Then
						If pObj.VATRate.TaxRate = 18 Then
							vFR.Summ7 = pObj.VATSum;
						ElsIf pObj.VATRate.TaxRate = 20 Then
							vFR.Summ7 = pObj.VATSum;
						ElsIf pObj.VATRate.TaxRate = 10 Then
							vFR.Summ8 = pObj.VATSum;
						ElsIf pObj.VATRate.NoVAT Then
							vFR.Summ10 = pObj.VATSum;
						ElsIf pObj.VATRate.TaxRate = 0 Then
							vFR.Summ9 = pObj.VATSum;
						Else
							vFR.Summ11 = pObj.VATSum;
						EndIf;
					EndIf;
				EndIf;
				vFR.FNBuildCorrectionReceipt2();
			EndIf;
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			If TypeOf(pObj) = Type("DocumentObject.Return") Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			EndIf;
			vFR.FNGetStatus();
			vChequeAttributes.ChequeSequenceNumber = vFR.DocumentNumber;
			vChequeAttributes.ChequeDateTime = vFR.Date + (vFR.Time - BegOfDay(vFR.Time));
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
			vChequeAttributes.ChequeFiscalNumber = Format(Number(vFR.FiscalSignAsString), "ND=10; NFD=; NLZ=; NG=");
			vFR.FNGetCurrentSessionParams();
			vChequeAttributes.CashDayChequeNumber = vFR.ReceiptNumber;
			vChequeAttributes.CashDay = vFR.SessionNumber;
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj, vChequeAttributes);
			
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
Procedure LogCashPayment(pFR, pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	NStr("en=' with amount ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	vIsPrepayment = False;
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				// Do not print cheque on paper
				vFR.TableNumber			= 17;			
				vFR.FieldNumber			= 7;
				vFR.ValueOfFieldInteger = 1;
				vFR.WriteTable();
			EndIf;
			vFR.OpenCheck();
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			If vFR.ECRSoftDate > Date(2025, 8, 1) Then
				If pObj.PaymentMethod.IsViaInternetAcquiring Then
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 1;
					vFR.FNSendTag();
					
					vHotelSite = "";
					If Not IsBlankString(CashRegister.PaymentAddress) Then
						vHotelSite = TrimAll(CashRegister.PaymentAddress);
					EndIf;
					
					If IsBlankString(vHotelSite) And ValueIsFilled(pObj.Hotel) Then
						vHotelSite = tcOnServer.cmGetAttributeByRef(pObj.Hotel, "Site");
					EndIf;
					
					If IsBlankString(vHotelSite) Then
						rMessage = NStr("en = 'The hotel website is not specified in the hotel settings (required to specify the payment location in the check)'; de = 'Die Hotelwebsite ist in den Hoteleinstellungen nicht angegeben (erforderlich, um den Zahlungsort im Scheck anzugeben)'; ru = 'В настройка гостинцы не указан сайт отеля (требуется для указания места расчёта в чеке)'");
						Disconnect(vFR);
						Return False;
					EndIf;
					
					vFR.TagNumber = 1187;
					vFR.TagType = 7;
					vFR.TagValueStr = vHotelSite;
					vFR.FNSendTag();
				Else
					vFR.TagNumber = 1125;
					vFR.TagType = 0;
					vFR.TagValueInt = 0;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
			// Send client e-mail
			vEMail = "";
			vPayer = Undefined;
			If TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
				If ValueIsFilled(pObj.AccountingCustomer) Then
					vPayer = pObj.AccountingCustomer;
				EndIf;
			ElsIf (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) Then
				If ValueIsFilled(pObj.Payer) Then
					vPayer = pObj.Payer;
				EndIf;
			EndIf;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					vEMail = TrimAll(vPayer.EMail);
				EndIf;
			EndIf;
			If Not IsBlankString(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.CustomerEmail = vEMail;
				vFR.FNSendCustomerEmail();
				vChequeAttributes.BuyerAddress = vEMail;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			If vTaxSystemCode > 0 Then
				vFR.TaxType = vTaxSystemCode;
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.TagNumber = 1021;
					vFR.TagType = 7;
					vFR.TagValueStr = vCashierName;
					vFR.FNSendTag();
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.TagNumber = 1203;
						vFR.TagType = 7;
						vFR.TagValueStr	= TrimAll(vEmployeeTIN);
						vFR.FNSendTag();
					EndIf;
				EndIf;
			EndIf;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vFR.TagNumber = 1256;
					vFR.FNBeginSTLVTag();
					vTagID = vFR.TagID;
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNAddTag();
					
					vFR.TagID = vTagID;
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNAddTag(); 
					
					vFR.FNSendSTLVTag();
				Else
					vFR.TagNumber = 1227;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerName;
					vFR.FNSendTag();
					
					vFR.TagNumber = 1228;
					vFR.TagType = 7;
					vFR.TagValueStr = vPayerTIN;
					vFR.FNSendTag();
				EndIf;
			EndIf;
			
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
				
				vPSRows = cmGetPrintableChequePositions(pObj, vIsPrepayment, CashRegister.AlwaysUseAveragePrice);
				
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
						If ValueIsFilled(vPSRow.Item) Then
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
							vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
						ElsIf ValueIsFilled(vPSRow.ChequeService) Then
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
							vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						Else
							vFR.StringForPrinting = NStr("en='Hotel services'; de='Hotel Dienstleistungen'; ru='Гостиничные услуги'");
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(vPaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
							EndIf;
						EndIf;
						
						vVATRate = Undefined;
						vVATSum = 0;
						If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
							vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
						EndIf;
						vVATSum = vPSRow.VATSum;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
						
						vItemQuantity = 0;
						vItemPrice = 0;
						If ValueIsFilled(vPSRow.ChequeService) Then
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vItemQuantity = vPSRow.ChequeServiceQuantity;
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
							Else
								vItemQuantity = 1;
							EndIf;
							vItemPrice = Round(vSectionAmount / vItemQuantity, 2);
						Else
							vItemQuantity = 1;
							vItemPrice = vSectionAmount;
						EndIf;
						tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 6, vItemPrice, vItemQuantity);
						vFR.Price = vItemPrice;
						vFR.Quantity = vItemQuantity;
						vFR.ReturnSale();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;	
						
						If ValueIsFilled(vPSRow.ChequeService) Then
							vChequeService = vPSRow.ChequeService;
							// Commissioner mark
							vIsAgentService = vChequeService.IsAgentService;
							If vIsAgentService Then
								// Commissioner attribute
								vFR.TagNumber = 1222;
								vFR.TagType = 0; // Int
								vFR.TagValueInt = 32; // 32 - Commissioner; 64 - other agent
								vFR.FNSendTagOperation();
								// Principal
								vPrincipal = vChequeService.Principal;
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									// Commissioner TIN
									If Not IsBlankString(vPrincipalTIN) Then
										vFR.TagNumber = 1226;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalTIN;
										vFR.FNSendTagOperation();
									EndIf;
									If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
										vFR.TagID = 0;
										vFR.TagNumber = 1224;
										vFR.FNBeginSTLVTag();
										vTagID = vFR.TagID;
										// Principal name
										vFR.TagNumber = 1225;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalName;
										vFR.FNAddTag();
										// Principal phone
										vFR.TagNumber = 1171;
										vFR.TagType = 7;
										vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
										vFR.FNAddTag();
										vFR.FNSendSTLVTagOperation();
									EndIf;
								EndIf;
							EndIf;
							// Item code
							vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vChequeService, "CashRegisterItemCode"));
							If Not IsBlankString(vCashRegisterItemCode) Then
								vFR.MarkingType = 17677; //EAN-13
								vFR.BarCode = vCashRegisterItemCode;
								vFR.FNSendItemCodeData();
							EndIf;
						EndIf;
					EndDo;
				ElsIf Not CashRegister.DoNotPrintPaymentSections Then
					pSum  = 0;
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
						If ValueIsFilled(vPSRow.Item) Then
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
							vFR.StringForPrinting = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
						ElsIf ValueIsFilled(vPSRow.ChequeService) Then
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
							EndIf;
							vFR.StringForPrinting = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						Else
							vFR.StringForPrinting = NStr("en='0'; de='0'; ru='0'");
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vPaymentSection = vPSRow.PaymentSection;
								vFR.Department = vPaymentSection.Code;
								vFR.StringForPrinting = GetString(vPaymentSection.Code);
							EndIf;
						EndIf;
						
						// Add tax
						vVATRate = Undefined;
						vVATSum = 0;
						If ValueIsFilled(vPaymentSection) And ValueIsFilled(vPaymentSection.VATRate) Then
							vFR.Tax1 = GetTaxGroup(vPaymentSection, vVATRate, vPSRow.VATRate, pObj);
						Else
							vFR.Tax1 = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
						EndIf;
						vVATSum = vPSRow.VATSum;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATSum);
						
						vItemQuantity = 0;
						vItemPrice = 0;
						If ValueIsFilled(vPSRow.ChequeService) Then
							If vPSRow.ChequeServiceQuantity <> 0 Then
								vItemQuantity = vPSRow.ChequeServiceQuantity;
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
							Else
								vItemQuantity = 1;
							EndIf;
							vItemPrice = Round(vSectionAmount / vItemQuantity, 2);
						Else
							vItemQuantity = 1;
							vItemPrice = vSectionAmount;
						EndIf;
						tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 6, vItemPrice, vItemQuantity);
						vFR.Price = vItemPrice;
						vFR.Quantity = vItemQuantity;
						vFR.ReturnSale();
						If Not CheckResultCode(vFR.ResultCode) Then
							CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;	
						
						If ValueIsFilled(vPSRow.ChequeService) Then
							vChequeService = vPSRow.ChequeService;
							// Commissioner mark
							vIsAgentService = vChequeService.IsAgentService;
							If vIsAgentService Then
								// Commissioner attribute
								vFR.TagNumber = 1222;
								vFR.TagType = 0; // Int
								vFR.TagValueInt = 32; // 32 - Commissioner; 64 - other agent
								vFR.FNSendTagOperation();
								// Principal
								vPrincipal = vChequeService.Principal;
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									// Commissioner TIN
									If Not IsBlankString(vPrincipalTIN) Then
										vFR.TagNumber = 1226;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalTIN;
										vFR.FNSendTagOperation();
									EndIf;
									If Not IsBlankString(vPrincipalName) And Not IsBlankString(vPrincipalPhone) Then
										vFR.TagID = 0;
										vFR.TagNumber = 1224;
										vFR.FNBeginSTLVTag();
										// Principal name
										vFR.TagNumber = 1225;
										vFR.TagType = 7;
										vFR.TagValueStr = vPrincipalName;
										vFR.FNAddTag();
										// Principal phone
										vFR.TagNumber = 1171;
										vFR.TagType = 7;
										vFR.TagValueStr = SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone);
										vFR.FNAddTag();
										vFR.FNSendSTLVTagOperation();
									EndIf;
								EndIf;
							EndIf;
							// Item code
							vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vChequeService, "CashRegisterItemCode"));
							If Not IsBlankString(vCashRegisterItemCode) Then
								vFR.MarkingType = 17677; //EAN-13
								vFR.BarCode = vCashRegisterItemCode;
								vFR.FNSendItemCodeData();
							EndIf;
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
						vAmount = vAmount + vPSRow.Sum;
						vVATAmount = vVATAmount + vPSRow.VATSum;
					EndDo;
					If vAmount < 0 Then
						Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
					EndIf;
					
					vFR.Department = 0;
					vFR.StringForPrinting = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
					
					// Add tax
					vVATRate = Undefined;
					vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
					cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vVATAmount);
					
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
						vFR.StringForPrinting = GetString(TrimR(vFR.StringForPrinting) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
					EndIf;
				EndIf;
				
				// Add tax
				vVATRate = Undefined;
				If ValueIsFilled(pObj.PaymentSection) And ValueIsFilled(pObj.PaymentSection.VATRate) Then
					vFR.Tax1 = GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj);
				Else
					vFR.Tax1 = GetTaxGroup(pObj, vVATRate, , pObj);
				EndIf;
				cmSetChequeVATAmount(vChequeAttributes, vVATRAte, pObj.VATSum);
				
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
			vFR.Summ5 = 0;
			vFR.Summ6 = 0;
			vFR.Summ16 = 0;
			
			vTypeClose = 0;
			If ValueIsFilled(pObj.PaymentMethod) Then
				vTypeClose = pObj.PaymentMethod.CashRegisterChequeCloseType;
			EndIf;
			
			vOpenDrawer = False;
			If vTypeClose = 16 Then
				vFR.Summ16 = pSum;
			ElsIf vTypeClose = 6 Then
				vFR.Summ6 = pSum;
			ElsIf vTypeClose = 5 Then
				vFR.Summ5 = pSum;
			ElsIf vTypeClose = 4 Then
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
			vFR.FNCloseCheckEx();
			If Not CheckResultCode(vFR.ResultCode) Then
				CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			vFR.FNGetStatus();
			vChequeAttributes.ChequeSequenceNumber = vFR.DocumentNumber;
			vChequeAttributes.ChequeDateTime = vFR.Date + (vFR.Time - BegOfDay(vFR.Time));
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.SerialNumber;
			vChequeAttributes.ChequeFiscalNumber = Format(Number(vFR.FiscalSignAsString), "ND=10; NFD=; NLZ=; NG=");
			vFR.FNGetCurrentSessionParams();
			vChequeAttributes.CashDayChequeNumber = vFR.ReceiptNumber;
			vChequeAttributes.CashDay = vFR.SessionNumber;
			
			// Log cash register operation
			LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj, vChequeAttributes);
			
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
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	NStr("ru = ' пробит кассовый чек аннуляции'; en = ' storno cheque was issued'; de = ' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
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
	pFR.StringQuantity = 4 + CashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
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
	pFR.StringQuantity = 4 + CashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
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
					vFR.FNBeginOpenSession();
					// Set cashier name
					vCashier = SessionParameters.CurrentUser;
					If ValueIsFilled(vCashier) Then
						vCashierName = tcCashRegisters.GetCashierName(vCashier);
						If Not IsBlankString(vCashierName) Then
							vFR.TagNumber = 1021;
							vFR.TagType = 7;
							vFR.TagValueStr = vCashierName;
							vFR.FNSendTag();
							
							// Set TIN
							vEmployeeTIN = TrimAll(vCashier.TIN);
							If Not IsBlankString(vEmployeeTIN) Then
								vFR.TagNumber = 1203;
								vFR.TagType = 7;
								vFR.TagValueStr	= vEmployeeTIN;
								vFR.FNSendTag();
							EndIf;
						EndIf;
					EndIf;
					// Open session
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
						vStr = StrReplace(vStr, "&Cashier", TrimAll(pObj.Author));
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
				vFR.StringQuantity = 6 + CashRegister.NumberOfExtraLinesOfPaperRunBeforeCut;
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
		If Not CashRegister.IgnoreEndOfPaperError And vFR.ReceiptRibbonIsPresent = 0 Then
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

// -----------------------------------------------------------------------------
Function GetUnitPiece(pService)
	If ValueIsFilled(pService) Then
		vSUnit = tcOnServer.cmGetAttributeByRef(pService, "Unit");
		If IsBlankString(vSUnit) Or TrimAll(Catalogs.Units.Piece) = vSUnit Then
			Return 0;
		ElsIf TrimAll(Catalogs.Units.Gram) = vSUnit Then
			Return 10;
		ElsIf TrimAll(Catalogs.Units.Kilogram) = vSUnit Then
			Return 11;
		ElsIf TrimAll(Catalogs.Units.Litre) = vSUnit Then
			Return 41;
		ElsIf TrimAll(Catalogs.Units.Mililitre) = vSUnit Then
			Return 40;
		ElsIf TrimAll(Catalogs.Units.Night) = vSUnit Then
			Return 70;
		ElsIf TrimAll(Catalogs.Units.Minute) = vSUnit Then
			Return 72;
		ElsIf TrimAll(Catalogs.Units.Hour) = vSUnit Then
			Return 71;
		ElsIf TrimAll(Catalogs.Units.Megabyte) = vSUnit Then
			Return 81;
		Else
			Return 0;
		EndIf;
	Else
		Return 255;
	EndIf;
EndFunction // GetUnitPiece

// -----------------------------------------------------------------------------
Procedure DisableMapping22(pFR, pArrCashRegister)
	vPassword = pFR.Password;
	If ValueIsFilled(pArrCashRegister.CashRegisterPassword) Then
		pFR.Password = TrimR(pArrCashRegister.CashRegisterPassword);
	ElsIf ValueIsFilled(pArrCashRegister.AccessPassword) Then
		pFR.Password = TrimR(pArrCashRegister.AccessPassword);
	EndIf;
	
	pFR.TableNumber = 17;
	pFR.RowNumber = 1;
	pFR.FieldNumber = 71;
	pFR.ValueOfFieldInteger = 2;
	pFR.WriteTable();
	
	pFR.Password = vPassword;
EndProcedure // DisableMapping22
