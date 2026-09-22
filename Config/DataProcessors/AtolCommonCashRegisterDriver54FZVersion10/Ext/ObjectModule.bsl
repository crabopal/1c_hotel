
// -----------------------------------------------------------------------------
Function GetString(pStr)
	If CashRegister.ChequeWidth > 0 Then
		Return Left(pStr, CashRegister.ChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Function GetPort(pFR)
	vPort = TrimAll(CashRegister.Port);
	If vPort = "АТОЛ USB" Then
		Return pFR.LIBFPTR_PORT_USB;
	ElsIf vPort = "TCP/IP (клиент)" Then
		Return pFR.LIBFPTR_PORT_TCPIP;
	Else
		Return pFR.LIBFPTR_PORT_COM; 
	EndIf;
EndFunction // GetPort

// -----------------------------------------------------------------------------
Function GetBaudRate(pFR)
	vBaudRate = CashRegister.BaudRate;
	If vBaudRate = 1200 Then
		Return pFR.LIBFPTR_PORT_BR_1200;
	ElsIf vBaudRate = 2400 Then
		Return pFR.LIBFPTR_PORT_BR_2400;
	ElsIf vBaudRate = 4800 Then
		Return pFR.LIBFPTR_PORT_BR_4800;
	ElsIf vBaudRate = 9600 Then
		Return pFR.LIBFPTR_PORT_BR_9600;
	ElsIf vBaudRate = 19200 Then
		Return pFR.LIBFPTR_PORT_BR_19200;
	ElsIf vBaudRate = 38400 Then
		Return pFR.LIBFPTR_PORT_BR_38400;
	ElsIf vBaudRate = 57600 Then
		Return pFR.LIBFPTR_PORT_BR_57600;
	ElsIf vBaudRate = 115200 Then
		Return pFR.LIBFPTR_PORT_BR_115200;
	ElsIf vBaudRate = 230400 Then
		Return pFR.LIBFPTR_PORT_BR_230400;
	ElsIf vBaudRate = 460800 Then
		Return pFR.LIBFPTR_PORT_BR_460800;
	ElsIf vBaudRate = 921600 Then
		Return pFR.LIBFPTR_PORT_BR_921600;
	Else
		Return pFR.LIBFPTR_PORT_BR_9600;	
	EndIf;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	rTaxSystem = Undefined;
	vTaxSystemChar = "";
	vPaymentSection = pObj.PaymentSection;
	If ValueIsFilled(vPaymentSection) Then
		rTaxSystem = vPaymentSection.TaxationSystem;
	ElsIf TypeOf(pObj.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pObj.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) Then
				rTaxSystem = vPaymentSection.TaxationSystem;
				If ValueIsFilled(rTaxSystem) Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pObj.Company) Then
		rTaxSystem = pObj.Company.TaxationSystem;
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemChar = "LIBFPTR_TT_OSN";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemChar = "LIBFPTR_TT_USN_INCOME";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemChar = "LIBFPTR_TT_USN_INCOME_OUTCOME";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemChar = "LIBFPTR_TT_ENVD";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemChar = "LIBFPTR_TT_ESN";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemChar = "LIBFPTR_TT_PATENT";
		EndIf;			
	EndIf;
	Return vTaxSystemChar;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate, pRowVATRate = Undefined, pDocObj = Undefined)
	vAtolTaxGroup = "LIBFPTR_TAX_DEPARTMENT";
	
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		rVATRate = pObj.VATRate;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vAtolTaxGroup;
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
		vAtolTaxGroup = "LIBFPTR_TAX_NO";
	ElsIf vTaxRate = 0 Then
		vAtolTaxGroup = "LIBFPTR_TAX_VAT0";
	ElsIf vTaxRate = 5 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT105";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT5";
		EndIf;
	ElsIf vTaxRate = 7 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT107";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT7";
		EndIf;
	ElsIf vTaxRate = 10 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT110";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT10";
		EndIf;
	ElsIf vTaxRate = 18 Then 
		vAtolTaxGroup = "LIBFPTR_TAX_VAT18";
	ElsIf vTaxRate = 20 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT120";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT20";
		EndIf;
	ElsIf vTaxRate = 22 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT122";
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT22";
		EndIf;
	Else
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "LIBFPTR_TAX_VAT1" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		Else
			vAtolTaxGroup = "LIBFPTR_TAX_VAT" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vAtolTaxGroup;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function GetUserPassword(pAskAlways = False)
	vPassword = "";
	Return vPassword;
EndFunction // GetUserPassword

// -----------------------------------------------------------------------------
Function GetOtherTypeClose(pCashRegisterChequeCloseType, vOpenDrawer) 
	vCloseTypeClose = "LIBFPTR_PT_CASH";
	If pCashRegisterChequeCloseType = 0 Then
		vCloseTypeClose = "LIBFPTR_PT_CASH";
		vOpenDrawer = True;
	ElsIf pCashRegisterChequeCloseType = 1 Then
		vCloseTypeClose = "LIBFPTR_PT_ELECTRONICALLY";	
	ElsIf pCashRegisterChequeCloseType = 2 Then
		vCloseTypeClose = "LIBFPTR_PT_PREPAID";	
	ElsIf pCashRegisterChequeCloseType = 3 Then
		vCloseTypeClose = "LIBFPTR_PT_CREDIT";	
	ElsIf pCashRegisterChequeCloseType = 4 Then
		vCloseTypeClose = "LIBFPTR_PT_OTHER";	
	ElsIf pCashRegisterChequeCloseType = 5 Then
		vCloseTypeClose = "LIBFPTR_PT_6";	
	ElsIf pCashRegisterChequeCloseType = 6 Then
		vCloseTypeClose = "LIBFPTR_PT_7";	
	ElsIf pCashRegisterChequeCloseType = 7 Then
		vCloseTypeClose = "LIBFPTR_PT_8";	
	ElsIf pCashRegisterChequeCloseType = 8 Then
		vCloseTypeClose = "LIBFPTR_PT_9";	
	ElsIf pCashRegisterChequeCloseType = 9 Then
		vCloseTypeClose = "LIBFPTR_PT_10";	
	EndIf;
	Return vCloseTypeClose;
EndFunction // GetOtherTypeClose

// -----------------------------------------------------------------------------
Function Connect(rMessage)
// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vFR = New COMObject("AddIn.Fptr10");
		
		// Apply connection parameters
		If ValueIsFilled(CashRegister.CashRegisterModel) Then
			vModel = "";
			Execute("vModel = TrimAll(vFR." + TrimAll(CashRegister.CashRegisterModel) + ");");
			If ValueIsFilled(vModel) Then
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, vModel);
			Else
				vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, TrimAll(vFR.LIBFPTR_MODEL_ATOL_AUTO));	
			EndIf;
		Else
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_MODEL, TrimAll(vFR.LIBFPTR_MODEL_ATOL_AUTO));
		EndIf;
		If ValueIsFilled(CashRegister.AccessPassword) Then
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_ACCESS_PASSWORD, CashRegister.AccessPassword);	
		EndIf;
		If ValueIsFilled(CashRegister.CashRegisterPassword) Then
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_USER_PASSWORD, TrimAll(CashRegister.CashRegisterPassword));
		EndIf;
		vFR.setSingleSetting(vFR.LIBFPTR_SETTING_PORT, TrimAll(GetPort(vFR)));
		If TrimAll(CashRegister.Port) = "TCP/IP (клиент)" Then
			If ValueIsFilled(CashRegister.Address) Then
				vAddress = StrSplit(CashRegister.Address, ":", False);
				If vAddress.Count() = 2 Then
					vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPADDRESS, TrimAll(vAddress[0]));
					vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPPORT, TrimAll(vAddress[1]));
				Else
					vFR.setSingleSetting(vFR.LIBFPTR_SETTING_IPADDRESS, TrimAll(CashRegister.Address));	
				EndIf;
			EndIf;
		ElsIf TrimAll(CashRegister.Port) <> "АТОЛ USB" Then
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_COM_FILE, TrimAll(CashRegister.Port));
			vFR.setSingleSetting(vFR.LIBFPTR_SETTING_BAUDRATE, TrimAll(GetBaudRate(vFR)));
		EndIf;
		vFR.applySingleSettings();
		// Check result code
		If vFR.open() = 0 Then
			// OK
			Return vFR;			
		Else
			// Error connecting to the device
			rMessage = TrimAll(vFR.errorDescription());
			Return Undefined;
		EndIf;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		If pFR.close() <> 0 Then
			tcCommonFunctionOnClientServer.TextMessage(TrimAll(pFR.errorDescription()));
		EndIf;
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Procedure CloseOpenCheque(pFR, pPasswordKKM="", pOpenSessionIfClosed = False, pIgnoreEndOfPaperError = False)
	// Connect
	If Not pFR.isOpened() Then
		pFR.open();
	EndIf;
	pFR.setParam(pFR.LIBFPTR_PARAM_DATA_TYPE, pFR.LIBFPTR_DT_STATUS);
	// Get advanced mode
	If pFR.queryData() = 0 Then		
		If pFR.getParamInt(pFR.LIBFPTR_PARAM_RECEIPT_TYPE) <> pFR.LIBFPTR_RT_CLOSED  Then
			pFR.cancelReceipt();
		ElsIf Not pIgnoreEndOfPaperError And Not pFR.getParamBool(pFR.LIBFPTR_PARAM_RECEIPT_PAPER_PRESENT) Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='Cheque ribbon is almost over!'; de='Scheck Band ist fast vorbei!'; ru='В ККМ заканчивается бумага!'"), MessageStatus.Attention);
		EndIf;
		If pOpenSessionIfClosed And CashRegister.DoNotOpenNewSessionAfterZReport Then
			If pFR.getParamInt(pFR.LIBFPTR_PARAM_SHIFT_STATE) = pFR.LIBFPTR_SS_CLOSED Then
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						pFR.setParam(1021, vCashierName);
						
						// Set TIN
						vEmployeeTIN = TrimAll(vCashier.TIN);
						If Not IsBlankString(vEmployeeTIN) Then
							pFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				// Open session
				pFR.operatorLogin();
				pFR.openShift();
				tcOnServer.Wait(5);
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
	Else // Cash register was connected
		// Retrieve cash register state
		vFR.setParam(vFR.LIBFPTR_PARAM_DATA_TYPE, vFR.LIBFPTR_DT_STATUS);
    	If vFR.queryData() = 0 Then
			If vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_STATE) = vFR.LIBFPTR_SS_EXPIRED Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			// Check paper
			If Not vFR.getParamBool(vFR.LIBFPTR_PARAM_RECEIPT_PAPER_PRESENT) Then
				rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			//Check cheque printer
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_CONNECTION_LOST) Then
				rMessage = NStr("ru='ККМ не может установить связь с принтером чеков!'; en='Cash register failes to connect to the cheque printer!'; de='Cash register failes to connect to the cheque printer!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_ERROR) Then
				rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_OVERHEAT) Then
				rMessage = NStr("ru='Перегрев принтера чеков! Повторите попытку позже.'; en='Cheque printer overheated! Wait a while and try again.'; de='Cheque printer overheated! Wait a while and try again.'");
				Disconnect(vFR);
				Return False;
			EndIf;
		Else
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.errorDescription());
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.errorCode() + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.errorDescription());
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.errorCode() + ", result description: " + rMessage);
	Try
		pFR.cancelReceipt();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure CancelNonfiscalCheque(pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.errorDescription());
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pFR.errorCode() + ", result description: " + rMessage);
	Try
		pFR.endNonfiscalDocument();
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
	If Not pFR.isOpened() Then
		pFR.open();
	EndIf;
	
    pFR.setParam(pFR.LIBFPTR_PARAM_DATE_TIME, CurrentSessionDate());
	If pFR.writeDateTime() <> 0 Then
		ProcessResultCode(pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	pFR.setParam(pFR.LIBFPTR_PARAM_DATA_TYPE, pFR.LIBFPTR_DT_STATUS);
	If pFR.queryData() = 0 Then
		vFRDate = pFR.getParamDateTime(pFR.LIBFPTR_PARAM_DATE_TIME);
		If BegOfDay(CurrentDate()) = BegOfDay(vFRDate) Then
			vTimeDiff = CurrentDate() - vFRDate;
			If vTimeDiff < 0 Then 
				vTimeDiff = -vTimeDiff;
			EndIf;
			If vTimeDiff > 300 Then // > 5 minutes
				// Set current time
				Return SetDeviceTime(pFR, rMessage);
			EndIf;
		Else
			// Date is different, need to set correct date manually
			rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
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
			Disconnect(vFR);
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
			// Close open cheque if any
			CloseOpenCheque(vFR, GetUserPassword(), True, CashRegister.IgnoreEndOfPaperError);

			// Do cash income
			vFR.setParam(vFR.LIBFPTR_PARAM_SUM,  pSum);
			If vFR.cashIncome() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.openDrawer();
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
			// Close open cheque if any
			CloseOpenCheque(vFR, GetUserPassword(), True, CashRegister.IgnoreEndOfPaperError);
	
			// Do cash outcome
			vFR.setParam(vFR.LIBFPTR_PARAM_SUM, pSum);
			If vFR.cashOutcome() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;	
			
			// Open drawer
			Try
				vFR.openDrawer();
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
			CloseOpenCheque(vFR, , , CashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_X);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			Try
				vFR.openDrawer();
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
			CloseOpenCheque(vFR, , , CashRegister.IgnoreEndOfPaperError);
			// Do report
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_HOURS);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"),  ,  ,  , rMessage);
			// Open drawer
			Try
				vFR.openDrawer();
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
			CloseOpenCheque(vFR, , , CashRegister.IgnoreEndOfPaperError);
			// Set cashier name
			vCashier = tcOnServer.cmGetCurrentUserAttribute();
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.setParam(1021, vCashierName);
					// Set TIN
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.setParam(1203, vEmployeeTIN);
					EndIf;
				EndIf;
			EndIf;
			
			// Close session
			vFR.operatorLogin();
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_CLOSE_SHIFT);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			Try
				vFR.openDrawer();
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
				// Set cashier name
				If ValueIsFilled(vCashier) Then
					If Not IsBlankString(vCashierName) Then
						vFR.setParam(1021, vCashierName);					
						// Set TIN
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				// Open session
				vFR.operatorLogin();
				vFR.openShift();
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
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , CashRegister.IgnoreEndOfPaperError);
			// Do report	
			vFR.setParam(vFR.LIBFPTR_PARAM_REPORT_TYPE, vFR.LIBFPTR_RT_OFD_EXCHANGE_STATUS);
			If vFR.report() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), , , , rMessage);
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
			// Close open cheque if any
			CloseOpenCheque(vFR, GetUserPassword(), True, CashRegister.IgnoreEndOfPaperError);
			
			vVersion = vFR.version();
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If ValueIsFilled(pObj.SlipText) Then
					If Not PrintSlipLines(vFR, tcOnServer.GetTextLinesArray(pObj.SlipText), rMessage) Then
						Return False;	
					EndIf;
				EndIf;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			If pIsCorrection Then
				If ValueIsFilled(pCorrectionDocumentDate) Or ValueIsFilled(pCorrectionDocumentNumber) Then
					If ValueIsFilled(pCorrectionDocumentDate) Then
						vFR.setParam(1178, (pCorrectionDocumentDate - '19700101'));
						vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
					EndIf;
					If ValueIsFilled(pCorrectionDocumentNumber) Then
						vFR.setParam(1179, Right(TrimAll(pCorrectionDocumentNumber), 32));
						vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
					EndIf;
					vFR.utilFormTlv();
					vCorrectionInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
				EndIf;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.setParam(1021, vCashierName);
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.setParam(1203, vEmployeeTIN);
					EndIf;
				EndIf;
			EndIf;
			vFR.operatorLogin();
				
			// Open cheque
			If Not pIsCorrection Then
				If pSum >= 0 Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN);
				EndIf;
			Else
				If pSum >= 0 Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_CORRECTION);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN_CORRECTION);
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, True);
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, False);
			EndIf;
						
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vFR.setParam(1173, ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0));
				vChequeAttributes.CorrectionType = pCorrectionType;
				If vCorrectionInfo <> Undefined Then
					vFR.setParam(1174, vCorrectionInfo);
				EndIf;
			EndIf;				
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemName = GetTaxationSystemCode(pObj, vTaxSystem);
			If ValueIsFilled(vTaxSystemName) Then
				vTaxSystemCode = Undefined;
				Execute("vTaxSystemCode = vFR." + TrimAll(vTaxSystemName) + ";");
				If vTaxSystemCode <> Undefined Then 
					vFR.setParam(1055, vTaxSystemCode);
					vChequeAttributes.TaxationSystem = vTaxSystem;
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
				vFR.setParam(1008, vEMail);
			EndIf;
			vChequeAttributes.BuyerAddress = vEMail;
			
			// Payer name and TIN
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
				vFR.setParam(1227, vPayerName);
				vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
			EndIf;
			
			If vVersion >= "10.10.7.0" Then
				If pObj.PaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(1125, True);
					
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
					
					vFR.setParam(1187, vHotelSite);
				Else
					vFR.setParam(1125, False);
				EndIf;
			EndIf;
			
			If vFR.openReceipt() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Begin format 1.05 item
			// Print payment number and section
			vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
			vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
			vCommodityName = "#" + TrimAll(pObj.Number); 
			vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
			If Not CashRegister.DoNotPrintPaymentSections Then
				If ValueIsFilled(pObj.PaymentSection) Then
					vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, pObj.PaymentSection.Code);
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						vCommodityName = GetString(TrimR(vCommodityName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
					EndIf;
				EndIf;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
			// Add tax
			vVATRate = Undefined;
			vVATSum = 0;
			vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
			vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum >= 0, pSum, -pSum));
			vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum >= 0, pSum, -pSum));
			If ValueIsFilled(pObj.PaymentSection) Then
				Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj) + ");");
			Else
				Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
			EndIf;
			vVATSum = pObj.VATSum;
			vTaxSum = cmCalculateVATSum(vVATRAte, ?(pSum >= 0, pSum, -pSum), pObj.Date); 
			vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0); 
			cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSum);
			
			// Fill format 1.05 attributes and end item
			vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
			vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
			If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
				vFR.setParam(2108, GetUnitPiece(Undefined));	
			EndIf;
			If vFR.registration() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;	
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
				EndIf;
				If vFR.printText() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));
				If vFR.printText() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			vOpenDrawer = False;
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vPaymentMethod = pObj.PaymentMethod;
				If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_PREPAID);
				ElsIf vPaymentMethod.IsByCash Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
					vOpenDrawer = True;
				ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_ELECTRONICALLY);
				Else
					Execute("vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR." + GetOtherTypeClose(vPaymentMethod.CashRegisterChequeCloseType, vOpenDrawer) + ");");
				EndIf;
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
				vOpenDrawer = True;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_SUM, ?(pSum > 0, pSum, -pSum));
			If vFR.payment() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			If vFR.closeReceipt() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;			
			// Get current cheque attributes
			If pSum >= 0 Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_DOCUMENTS_COUNT_IN_SHIFT);
   			vFR.fnQueryData();
			vChequeAttributes.CashDayChequeNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENTS_COUNT);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FN_INFO);
   			vFR.fnQueryData();
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_SERIAL_NUMBER);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_LAST_DOCUMENT);
    		vFR.fnQueryData();			
			vChequeAttributes.ChequeSequenceNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
			vChequeAttributes.ChequeFiscalNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_FISCAL_SIGN);
			vChequeAttributes.ChequeDateTime = vFR.getParamDateTime(vFR.LIBFPTR_PARAM_DATE_TIME);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_SHIFT);
    		vFR.fnQueryData();
			vChequeAttributes.CashDay = vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_NUMBER);
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj, vChequeAttributes);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.openDrawer();
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
			// Close open cheque if any
			CloseOpenCheque(vFR, GetUserPassword(), True, CashRegister.IgnoreEndOfPaperError);
			
			vVersion = vFR.version();
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					If Not PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), rMessage) Then
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);

			vCorrectionInfo = Undefined;
			If pIsCorrection Then
				vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
				If ValueIsFilled(vCorrectionDocumentDate) Then
					vFR.setParam(1178, vCorrectionDocumentDate - '19700101');
					vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
				Else
					rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
					                |ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
									|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
					Return False;
				EndIf;

				vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
				vFR.setParam(1179, Right(vCorrectionDocumentNumber, 32));
				vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;

				vFR.utilFormTlv();
				vCorrectionInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
			EndIf;
			
			// Payer name and TIN
			vPayerInfo = Undefined;
			If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
				vPayerName = "";
				vPayerTIN = "";
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
					vFR.setParam(1227, vPayerName);
					vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
					vFR.utilFormTlv();
					vPayerInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE); 
				EndIf;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vFR.setParam(1021, vCashierName);
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vFR.setParam(1203, vEmployeeTIN);
					EndIf;
				EndIf;
			EndIf;
			vFR.operatorLogin();
			
			// Open cheque
			If Not pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL);
				EndIf;
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN_CORRECTION);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_CORRECTION);
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, True);
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, False);
			EndIf;
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vFR.setParam(1173, ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0));
				vChequeAttributes.CorrectionType = pCorrectionType;
				If vCorrectionInfo <> Undefined Then
					vFR.setParam(1174, vCorrectionInfo);
				EndIf;
			EndIf;				
			
			// Print FPD of the base cheque if return
			If pObj.CorrectionOfIncorrectCheque Then
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					// Get payment cheque attributes
					vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
					If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
						vFR.setParam(1192, TrimAll(vPaymentAttrs.ChequeFiscalNumber));
					EndIf;
				EndIf;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemName = GetTaxationSystemCode(pObj, vTaxSystem);
			If ValueIsFilled(vTaxSystemName) Then
				vTaxSystemCode = Undefined;
				Execute("vTaxSystemCode = vFR." + TrimAll(vTaxSystemName) + ";");
				If vTaxSystemCode <> Undefined Then 
					vFR.setParam(1055, vTaxSystemCode);
					vChequeAttributes.TaxationSystem = vTaxSystem;
				EndIf;
			EndIf;
						
			// Transfer client e-mail
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
			If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vFR.setParam(1008, vEMail);
			EndIf;
			vChequeAttributes.BuyerAddress = vEMail;
			
			// Payer name and TIN
			If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
				If vPayerInfo <> Undefined Then
					vFR.setParam(1256, vPayerInfo);	
				EndIf;
			Else
				vPayerName = "";
				vPayerTIN = "";
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
					vFR.setParam(1227, vPayerName);
					vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
				EndIf;	
			EndIf;
			
			If vVersion >= "10.10.7.0" Then
				If pObj.PaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(1125, True);
					
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
					
					vFR.setParam(1187, vHotelSite);
				Else
					vFR.setParam(1125, False);
				EndIf;
			EndIf;
			
			If vFR.openReceipt() <> 0 Then
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
						
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Print services
			If Not pIsCorrection Or pIsCorrection And CashRegister.FiscalDataFormatVersions <> Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
				If Not CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						// Begin format 1.05 item 
						// Commissioner mark
						If ValueIsFilled(vSrvRow.Service) Then
							vIsAgentService = vSrvRow.Service.IsAgentService;
							If vIsAgentService Then
								// Principal
								vPrincipal = vSrvRow.Service.Principal;
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									vSuplierInfo = Undefined;
									If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
										vFR.setParam(1225, vPrincipalName);
										vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
										vFR.utilFormTlv();
	   									vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
									EndIf;
									If ValueIsFilled(vPrincipalTIN) Then
										vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
									EndIf;
									If vSuplierInfo <> Undefined Then 
										vFR.setParam(1224, vSuplierInfo);
									EndIf;
								EndIf;
								// Commissioner attribute
								vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER);
							EndIf;
							// Item code
							vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "CashRegisterItemCode"));
							If Not IsBlankString(vCashRegisterItemCode) Then
								If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
									vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
								Else
									vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
								EndIf;
							EndIf;
						EndIf;
						// Fill item attributes
						vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
						vPaymentSection = Undefined;
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
						vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, "");
						If ValueIsFilled(vSrvRow.Service) Then
							vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage)));
							If ValueIsFilled(vSrvRow.PaymentSection) Then
								vPaymentSection = vSrvRow.PaymentSection;
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPaymentSection.Code);
							EndIf;
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSrvRow.Amount);
						vItemQuantity = vSrvRow.Quantity;
						vItemPrice = vSrvRow.Price;
						tcCashRegisters.ChequeItemAttributesCorrection(vSrvRow.Amount, vItemQuantity, 3, vItemPrice, vItemQuantity);
						vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
						vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) Then
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj) + ");");
						Else
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj) + ");");
						EndIf;
						vTaxSumm = Undefined;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vTaxSumm = cmCalculateVATSum(vVATRAte, vSrvRow.Amount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
						Else
							vTaxSumm = cmCalculateVATSum(vVATRAte, vSrvRow.Amount, pObj.Date);
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						v1212 = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vSrvRow.Service, vSrvRow.PaymentSection));
						vFR.setParam(1212, v1212);
						If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
							// Fill excise value
							If ValueIsFilled(vSrvRow.Service) Then
								vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(vSrvRow.Service.ExciseDutyType, pObj.Date, vSrvRow.Service.Volume, vItemQuantity));
							EndIf;
						EndIf;
						vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
						If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vFR.setParam(2108, GetUnitPiece(vSrvRow.Service));	
						EndIf;
						If vFR.registration() <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndDo;
				Else
					// Print number and sections
					If pObj.PaymentSections.Count() > 0 Then
						If Not CashRegister.PrintFolioHeader Then
							vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, "#" + TrimAll(pObj.Number)); 
							If vFR.printText() <> 0 Then
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
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Begin format 1.05 item 
								// Print name, price and quantity
								vSumm = 0;
								vItemQuantity = 1;
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = vPSRow.ChequeService.IsAgentService;
									If vIsAgentService Then
										// Principal
										vPrincipal = vPSRow.ChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											vSuplierInfo = Undefined;
											If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
												vFR.setParam(1225, vPrincipalName);
												vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
												vFR.utilFormTlv();
			   									vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
											EndIf;
											If ValueIsFilled(vPrincipalTIN) Then
												vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
											EndIf;
											If vSuplierInfo <> Undefined Then 
												vFR.setParam(1224, vSuplierInfo);
											EndIf;
										EndIf;
										// Commissioner attribute
										vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER);
									EndIf;
									// Item code
									vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode"));
									If Not IsBlankString(vCashRegisterItemCode) Then
										If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
											vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
										Else
											vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item)));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage)));
									EndIf;
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									vSumm = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage)));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vSumm = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									If vSectionAmount >=0 Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vSumm = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
								Else
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
								EndIf;
								vTaxSumm = Undefined;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
								Else
									vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, pObj.Date);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
								// Fill format 1.05 attributes and end item
								v1212 = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.setParam(1212, v1212);
								If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(vPSRow.ChequeService.ExciseDutyType, pObj.Date, vPSRow.ChequeService.Volume, vItemQuantity));
									EndIf;
								EndIf;
								vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment)));
								If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
									vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
								EndIf;
								If vFR.registration() <> 0 Then
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
								vSumm = 0;
								// Begin format 1.05 item 
								// Print name, price and quantity 
								vItemQuantity = 1;
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = vPSRow.ChequeService.IsAgentService;
									If vIsAgentService Then
										// Principal
										vPrincipal = vPSRow.ChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											vSuplierInfo = Undefined;
											If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
												vFR.setParam(1225, vPrincipalName);
												vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
												vFR.utilFormTlv();
			   									vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
											EndIf;
											If ValueIsFilled(vPrincipalTIN) Then
												vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
											EndIf;
											If vSuplierInfo <> Undefined Then 
												vFR.setParam(1224, vSuplierInfo);
											EndIf;
										EndIf;
										// Commissioner attribute
										vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER);
									EndIf;
									// Item code
									vCashRegisterItemCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode"));
									If Not IsBlankString(vCashRegisterItemCode) Then
										If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
											vFR.setParam(vFR.LIBFPTR_PARAM_PRODUCT_CODE, vCashRegisterItemCode);	
										Else
											vFR.setParamStrHex(1162, tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item)));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage)));
									EndIf;
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
									tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
									vSumm = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount); 
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, TrimAll(vPSRow.PaymentSection.Code));
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vSumm = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
									If vSectionAmount >=0 Then
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
									vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
									vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount));
									vSumm = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
								Else
									Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
								EndIf;
								vTaxSumm = 0;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
								Else
									vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, pObj.Date);
								EndIf;
								vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
								// Fill format 1.05 attributes and end item
								v1212 = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vFR.setParam(1212, v1212);
								If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vFR.setParam(1229, tcCashRegisters.GetChequeItemExciseValue(vPSRow.ChequeService.ExciseDutyType, pObj.Date, vPSRow.ChequeService.Volume, vItemQuantity));
									EndIf;
								EndIf;
								vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment)));
								If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
									vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
								EndIf;
								If vFR.registration() <> 0 Then
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
							// Begin format 1.05 item 
							// Print name, price and quantity
							vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
							vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
							vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'"));
							vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
							vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(vAmount >= 0, vAmount, -vAmount));
							vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(vAmount >= 0, vAmount, -vAmount));
							// Add tax
							vVATRate = Undefined;
							Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
							vTaxSumm = 0;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vTaxSumm = cmCalculateVATSum(vVATRAte, ?(vAmount >= 0, vAmount, -vAmount), ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
							Else
								vTaxSumm = cmCalculateVATSum(vVATRAte, ?(vAmount >= 0, vAmount, -vAmount), pObj.Date);
							EndIf;
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
							vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
							If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
								vFR.setParam(2108, GetUnitPiece(Undefined));	
							EndIf;
							If vFR.registration() <> 0 Then
								CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;	
						EndIf;
					Else
						vVATAmount = pObj.VATSum;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vVATAmount = -vVATAmount;
						EndIf;
						// Begin format 1.05 item 
						// Print name, price and quantity
						vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
						vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						If Not CashRegister.PrintFolioHeader Then
							vCommodityName = "#" + TrimAll(pObj.Number);
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
						If ValueIsFilled(pObj.PaymentSection) Then
							vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, pObj.PaymentSection.Code);
							If CashRegister.PrintPaymentSectionNamesInCheques Then
								If CashRegister.PrintFolioHeader Then
									vCommodityName = GetString(pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								Else
									vCommodityName = GetString(TrimR(vCommodityName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								EndIf;
							EndIf;
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
						vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
						vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum >= 0, pSum, -pSum));
						vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum >= 0, pSum, -pSum));
						// Add tax
						vVATRate = Undefined;
						Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
						vTaxSumm = 0;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vTaxSumm = cmCalculateVATSum(vVATRAte, ?(pSum >= 0, pSum, -pSum), ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
						Else
							vTaxSumm = cmCalculateVATSum(vVATRAte, ?(pSum >= 0, pSum, -pSum), pObj.Date);
						EndIf;
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
						vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
						If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vFR.setParam(2108, GetUnitPiece(Undefined));	
						EndIf;
						If vFR.registration() <> 0 Then
							CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;	
					EndIf;
				EndIf;
				
				// Print VAT sum as string if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
					Else
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
					EndIf;
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			Else // Correction cheque
				vVATAmount = pObj.VATSum;
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vVATAmount = -vVATAmount;
				EndIf;
				// Begin format 1.05 item 
				// Print name, price and quantity
				vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
				vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
				vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
				If Not CashRegister.PrintFolioHeader Then
					vCommodityName = "#" + TrimAll(pObj.Number);
				EndIf;
				vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
				If ValueIsFilled(pObj.PaymentSection) Then
					vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, pObj.PaymentSection.Code);
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						If CashRegister.PrintFolioHeader Then
							vCommodityName = GetString(pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						Else
							vCommodityName = GetString(TrimR(vCommodityName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						EndIf;
					EndIf;
				EndIf;
				vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
				vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
				vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, ?(pSum >= 0, pSum, -pSum));
				vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, ?(pSum >= 0, pSum, -pSum));
				// Add tax
				vVATRate = Undefined;
				Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
				vTaxSumm = 0;
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vTaxSumm = cmCalculateVATSum(vVATRAte, ?(pSum >= 0, pSum, -pSum), ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
				Else
					vTaxSumm = cmCalculateVATSum(vVATRAte, ?(pSum >= 0, pSum, -pSum), pObj.Date);
				EndIf;
				vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
				cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
				// Fill format 1.05 attributes and end item
				vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
				vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
				If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vFR.setParam(2108, GetUnitPiece(Undefined));	
				EndIf;
				If vFR.registration() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;	
			EndIf;
			
			vOpenDrawer = False;
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vPaymentMethod = pObj.PaymentMethod;
				If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_PREPAID);
				ElsIf vPaymentMethod.IsByCash Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
					vOpenDrawer = True;
				ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_ELECTRONICALLY);
				Else
					Execute("vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR." + GetOtherTypeClose(vPaymentMethod.CashRegisterChequeCloseType, vOpenDrawer) + ");");
				EndIf;
			Else
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
				vOpenDrawer = True;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_SUM, ?(pSum > 0, pSum, -pSum));
			If vFR.payment() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;

			If vFR.closeReceipt() <> 0 Then
				CancelCheque(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			EndIf;
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_DOCUMENTS_COUNT_IN_SHIFT);
   			vFR.fnQueryData();
			vChequeAttributes.CashDayChequeNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENTS_COUNT);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FN_INFO);
   			vFR.fnQueryData();
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_SERIAL_NUMBER);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_LAST_DOCUMENT);
    		vFR.fnQueryData();			
			vChequeAttributes.ChequeSequenceNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
			vChequeAttributes.ChequeFiscalNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_FISCAL_SIGN);
			vChequeAttributes.ChequeDateTime = vFR.getParamDateTime(vFR.LIBFPTR_PARAM_DATE_TIME);
			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_SHIFT);
    		vFR.fnQueryData();
			vChequeAttributes.CashDay = vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_NUMBER);
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj, vChequeAttributes);
			
			// Open drawer
			Try
				If vOpenDrawer Then
					vFR.openDrawer();
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
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
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
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			If pSum > 0 Then
				// Close open cheque if any
				CloseOpenCheque(vFR, GetUserPassword(True), True, CashRegister.IgnoreEndOfPaperError);
				
				vVersion = vFR.version();
				
				// Print slip if payment was made by credit card
				If CashRegister.PrintSlipInCheque Then
					If Not IsBlankString(pObj.AnnulationSlipText) Then
						If Not PrintSlipLines(vFR, cmGetTextLinesArray(pObj.AnnulationSlipText), rMessage) Then
							Return False;
						EndIf;
					EndIf;
				EndIf;
				
				// Initialize cheque attributes used to send online cheque by sms or e-mail
				vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
				vCorrectionInfo = Undefined;
				If pIsCorrection Then
					If ValueIsFilled(pCorrectionDocumentDate) Or ValueIsFilled(pCorrectionDocumentNumber) Then
						If ValueIsFilled(pCorrectionDocumentDate) Then
							vFR.setParam(1178, (pCorrectionDocumentDate - '19700101'));
							vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
						EndIf;
						If ValueIsFilled(pCorrectionDocumentNumber) Then
							vFR.setParam(1179, Right(TrimAll(pCorrectionDocumentNumber), 32));
							vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
						EndIf;
						vFR.utilFormTlv();
						vCorrectionInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
					EndIf;
				EndIf;

				// Set cashier name
				vCashier = pObj.Author;
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					If Not IsBlankString(vCashierName) Then
						vFR.setParam(1021, vCashierName);
						vChequeAttributes.CashierName = vCashierName;
						
						// Set TIN
						vEmployeeTIN = TrimAll(vCashier.TIN);
						If Not IsBlankString(vEmployeeTIN) Then
							vFR.setParam(1203, vEmployeeTIN);
						EndIf;
					EndIf;
				EndIf;
				vFR.operatorLogin();
				
				// Open cheque
				vUseReturn = True;
				If Not pIsCorrection Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_TYPE, vFR.LIBFPTR_RT_SELL_RETURN_CORRECTION);
				EndIf;
				
				If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, True);
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_RECEIPT_ELECTRONICALLY, False);
				EndIf;
					
				// Set correction type
				vChequeAttributes.IsCorrection = pIsCorrection;
				If pIsCorrection Then
					vFR.setParam(1173, ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), 1, 0));
					vChequeAttributes.CorrectionType = pCorrectionType;
					If vCorrectionInfo <> Undefined Then
						vFR.setParam(1174, vCorrectionInfo);
					EndIf;
				EndIf;				
								
				// Set taxation system
				vTaxSystem = Undefined;
				vTaxSystemName = GetTaxationSystemCode(pObj, vTaxSystem);
				If ValueIsFilled(vTaxSystemName) Then
					vTaxSystemCode = Undefined;
					Execute("vTaxSystemCode = vFR." + TrimAll(vTaxSystemName) + ";");
					If vTaxSystemCode <> Undefined Then 
						vFR.setParam(1055, vTaxSystemCode);
						vChequeAttributes.TaxationSystem = vTaxSystem;
					EndIf;
				EndIf;
								
				// Transfer client e-mail
				vEMail = "";
				vPayer = Undefined;
				If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) Then
					If ValueIsFilled(pObj.Payer) Then
						vPayer = pObj.Payer;
					EndIf;
				ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
					If ValueIsFilled(pObj.AccountingCustomer) Then
						vPayer = pObj.AccountingCustomer;
					EndIf;
				EndIf;
				If ValueIsFilled(vPayer) Then
					If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
						vEMail = TrimAll(vPayer.EMail);
					EndIf;
				EndIf;
				If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vFR.setParam(1008, vEMail);
				EndIf;
				vChequeAttributes.BuyerAddress = vEMail;
				
				// Payer name and TIN
				vPayerName = "";
				vPayerTIN = "";
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				If ValueIsFilled(vPayerTIN) And ValueIsFilled(vPayerName) Then
					vFR.setParam(1227, vPayerName);
					vFR.setParam(1228, ?(StrLen(vPayerTIN) = 10, vPayerTIN + "  ", vPayerTIN));
				EndIf;
				
				If vVersion >= "10.10.7.0" Then
					If pObj.PaymentMethod.IsViaInternetAcquiring Then
						vFR.setParam(1125, True);
						
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
						
						vFR.setParam(1187, vHotelSite);
					Else
						vFR.setParam(1125, False);
					EndIf;
				EndIf;
				
				If vFR.openReceipt() <> 0 Then
					ProcessResultCode(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Cheque folio header
				If CashRegister.PrintFolioHeader Then
					PrintFolioHeader(vFR, pObj);
				EndIf;
				
				// Print document number and sections
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, "#" + TrimAll(pObj.Number));
						If vFR.printText() <> 0 Then
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
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							If vSectionAmount < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							vSumm = 0;
							// Begin format 1.05 item 
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								// Commissioner mark
								vIsAgentService = vPSRow.ChequeService.IsAgentService;
								If vIsAgentService Then
									// Principal
									vPrincipal = vPSRow.ChequeService.Principal;
									If ValueIsFilled(vPrincipal) Then
										vPrincipalTIN = TrimAll(vPrincipal.TIN);
										vPrincipalName = TrimAll(vPrincipal.LegacyName);
										vPrincipalPhone = TrimAll(vPrincipal.Phone);
										vSuplierInfo = Undefined;
										If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
											vFR.setParam(1225, vPrincipalName);
											vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
											vFR.utilFormTlv();
		   									vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
										EndIf;
										If ValueIsFilled(vPrincipalTIN) Then
											vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
										EndIf;
										If vSuplierInfo <> Undefined Then 
											vFR.setParam(1224, vSuplierInfo);
										EndIf;
									EndIf;
									// Commissioner attribute
									vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER);
								EndIf;
								// Item main attributes
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
								EndIf;
								If ValueIsFilled(vPSRow.Item) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item)));
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage)));
								EndIf;
								vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
								vItemPrice = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
								vSumm = vSectionAmount; 
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
								vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage)));
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vSectionAmount);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								vSumm = vSectionAmount;
							Else
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
								vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Advance return for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат предоплаты за гостиничные услуги'"));
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vSectionAmount);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								vSumm = vSectionAmount;
							EndIf;
							// Add tax
							vVATRate = Undefined;
							If ValueIsFilled(vPSRow.PaymentSection) Then
								Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
							Else
								Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
							EndIf;
							vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, pObj.Date);
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment)));
							vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment)));
							If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
								vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
							EndIf;
							If vFR.registration() <> 0 Then
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
							// Begin format 1.05 item 
							// Print name, price and quantity
							If ValueIsFilled(vPSRow.ChequeService) Then
								// Commissioner mark
								vIsAgentService = vPSRow.ChequeService.IsAgentService;
								If vIsAgentService Then
									// Principal
									vPrincipal = vPSRow.ChequeService.Principal;
									If ValueIsFilled(vPrincipal) Then
										vPrincipalTIN = TrimAll(vPrincipal.TIN);
										vPrincipalName = TrimAll(vPrincipal.LegacyName);
										vPrincipalPhone = TrimAll(vPrincipal.Phone);
										vSuplierInfo = Undefined;
										If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
											vFR.setParam(1225, vPrincipalName);
											vFR.setParam(1171, SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
											vFR.utilFormTlv();
		   									vSuplierInfo = vFR.getParamByteArray(vFR.LIBFPTR_PARAM_TAG_VALUE);
										EndIf;
										If ValueIsFilled(vPrincipalTIN) Then
											vFR.setParam(1226, ?(StrLen(vPrincipalTIN) = 10, vPrincipalTIN + "  ", vPrincipalTIN));
										EndIf;
										If vSuplierInfo <> Undefined Then 
											vFR.setParam(1224, vSuplierInfo);
										EndIf;
									EndIf;
									// Commissioner attribute
									vFR.setParam(1222, vFR.LIBFPTR_AT_ANOTHER);
								EndIf;
								// Item main attributes
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
								EndIf;
								If ValueIsFilled(vPSRow.Item) Then
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item)));
								Else
									vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage)));
								EndIf;
								vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
								vItemPrice = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vItemPrice);
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, vItemQuantity);
								vSumm = vSectionAmount;
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, vPSRow.PaymentSection.Code);
								vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, TrimAll(vPSRow.PaymentSection.Code));
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vSectionAmount);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								vSumm = vSectionAmount;
							Else
								vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
								vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Advance return for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат предоплаты за гостиничные услуги'"));
								vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
								vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vSectionAmount);
								vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vSectionAmount);
								vSumm = vSectionAmount;
							EndIf;
							vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
							// Add tax
							vVATRate = Undefined;
							If ValueIsFilled(vPSRow.PaymentSection) Then
								Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj) + ");");
							Else
								Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj) + ");");
							EndIf;
							vTaxSumm = cmCalculateVATSum(vVATRAte, vSumm, pObj.Date);
							vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment)));
							vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment)));
							If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
								vFR.setParam(2108, GetUnitPiece(vPSRow.ChequeService));	
							EndIf;
							If vFR.registration() <> 0 Then
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
						// Begin format 1.05 item 
						// Print name, price and quantity
						vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
						vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'"));
						vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
						vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vAmount);
						vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vAmount);
						// Add tax
						vVATRate = Undefined;
						Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
						vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
						vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
						vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
						If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vFR.setParam(2108, GetUnitPiece(Undefined));	
						EndIf;
						If vFR.registration() <> 0 Then
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
					// Begin format 1.05 item 
					// Print name, price and quantity
					vFR.setParam(vFR.LIBFPTR_PARAM_CHECK_SUM, False);
					vFR.setParam(vFR.LIBFPTR_PARAM_TAX_MODE, vFR.LIBFPTR_TM_POSITION);
					vCommodityName = "#" + TrimAll(pObj.Number);
					vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, 0);
					If ValueIsFilled(pObj.PaymentSection) Then
						vFR.setParam(vFR.LIBFPTR_PARAM_DEPARTMENT, pObj.PaymentSection.Code);
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							vCommodityName = GetString(TrimR(vCommodityName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						EndIf;
					EndIf;
					vFR.setParam(vFR.LIBFPTR_PARAM_COMMODITY_NAME, vCommodityName);
					vFR.setParam(vFR.LIBFPTR_PARAM_QUANTITY, 1);
					vFR.setParam(vFR.LIBFPTR_PARAM_PRICE, vAmount);
					vFR.setParam(vFR.LIBFPTR_PARAM_POSITION_SUM, vAmount);
					// Add tax
					Execute("vFR.setParam(vFR.LIBFPTR_PARAM_TAX_TYPE, vFR." + GetTaxGroup(pObj, vVATRate, , pObj) + ");");
					vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
					vFR.setParam(vFR.LIBFPTR_PARAM_TAX_SUM, 0);
					cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
					// Fill format 1.05 attributes and end item
					vFR.setParam(1212, cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined)));
					vFR.setParam(1214, cmGetChequePaymentModeTypeValue(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
					If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
						vFR.setParam(2108, GetUnitPiece(Undefined));	
					EndIf;
					If vFR.registration() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
					Else
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
					EndIf;
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));
					If vFR.printText() <> 0 Then
						CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				
				vOpenDrawer = False;
				// Close cheque
				If ValueIsFilled(pObj.PaymentMethod) Then
					vPaymentMethod = pObj.PaymentMethod;
					If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
						vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_PREPAID);
					ElsIf vPaymentMethod.IsByCash Then
						vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
						vOpenDrawer = True;
					ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
						vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_ELECTRONICALLY);
					Else
						Execute("vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR." + GetOtherTypeClose(vPaymentMethod.CashRegisterChequeCloseType, vOpenDrawer) + ");");
					EndIf;
				Else
					vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_TYPE, vFR.LIBFPTR_PT_CASH);
					vOpenDrawer = True;
				EndIf;
				
				vFR.setParam(vFR.LIBFPTR_PARAM_PAYMENT_SUM, ?(pSum > 0, pSum, -pSum));
				If vFR.payment() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				If vFR.closeReceipt() <> 0 Then
					CancelCheque(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Get current cheque attributes
				vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_DOCUMENTS_COUNT_IN_SHIFT);
	   			vFR.fnQueryData();
				vChequeAttributes.CashDayChequeNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENTS_COUNT);
				
				vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FN_INFO);
	   			vFR.fnQueryData();
				vChequeAttributes.FiscalStorageFactoryNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_SERIAL_NUMBER);
				
				vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_LAST_DOCUMENT);
	    		vFR.fnQueryData();			
				vChequeAttributes.ChequeSequenceNumber = vFR.getParamInt(vFR.LIBFPTR_PARAM_DOCUMENT_NUMBER);
				vChequeAttributes.ChequeFiscalNumber = vFR.getParamString(vFR.LIBFPTR_PARAM_FISCAL_SIGN);
				vChequeAttributes.ChequeDateTime = vFR.getParamDateTime(vFR.LIBFPTR_PARAM_DATE_TIME);
				
				vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_SHIFT);
	    		vFR.fnQueryData();
				vChequeAttributes.CashDay = vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_NUMBER);
				
				// Log cash register operation
				LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj, vChequeAttributes);
				
				// Open drawer
				Try
					If vOpenDrawer Then
						vFR.openDrawer();
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
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек аннуляции'; en=' storno cheque was issued'; de=' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Function PrintSlipLines(pFR, pSlipTextArr, rMessage)
	If pFR.beginNonfiscalDocument() = 0 Then
		// Print first slip for the hotel
		For Each vStr In pSlipTextArr Do
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, vStr);
			If pFR.printText() <> 0 Then
				CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		EndDo;
		pFR.setParam(pFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
		pFR.endNonfiscalDocument();
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
		Return False;
	EndIf;
	If pFR.beginNonfiscalDocument() = 0 Then
		// Print second slip for the client
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'"));
		If pFR.printText() <> 0 Then
			CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndIf;
		For Each vStr In pSlipTextArr Do
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, vStr);
			If pFR.printText() <> 0 Then
				CancelNonfiscalCheque(pFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
		EndDo;
		pFR.setParam(pFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
		pFR.endNonfiscalDocument();
	Else
		ProcessResultCode(pFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // PrintSlipLines

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pObj, rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			CloseOpenCheque(vFR, , , CashRegister.IgnoreEndOfPaperError);

			If Not PrintSlipLines(vFR, pSlipTextArr, rMessage) Then
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
	// Header start delimeter
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString("-----------------------------------------------------------------------"));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Folio #                                                                      
	vFolioRef = pObj.Folio;
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + tcOnServer.GetDocumentNumberPresentation(vFolioRef.Number)));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(vFolioRef.Room.Description))); 
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.printText();
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer.Description)));
		Else
			pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(vFolioRef.Client.Description)));
		EndIf;
		pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
		pFR.printText();
	EndIf;
	// Guest group
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup.Code))); 
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Document                                                                 
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(pObj.Number)));
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
	// Header end delimeter
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT, GetString("-----------------------------------------------------------------------")); 
	pFR.setParam(pFR.LIBFPTR_PARAM_TEXT_WRAP, pFR.LIBFPTR_TW_NONE);
	pFR.printText();
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
			// Close open cheque if any
			CloseOpenCheque(vFR, GetUserPassword(), False, CashRegister.IgnoreEndOfPaperError);
			
			If vFR.beginNonfiscalDocument() = 0 Then
				vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
				
				// Convert cheque template to the array of strings
				vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
				
				// Print all strings in the array
				vDoPrintClicheAtEnd = False;
				
				// Print first slip for the hotel
				vNum = 0;
				For Each vStr In vTextArr Do
					vNum = vNum + 1;
					If vStr = "&Cliche" And vNum = 1 Then
						If vFR.printCliche() <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					ElsIf vStr = "&Cliche" And vNum = vTextArr.Count() Then
						vDoPrintClicheAtEnd = True;
						Continue;
					ElsIf vStr = "&FolioHeader" Then
						Try
							PrintFolioHeader(vFR, pObj);
						Except
						EndTry;
					Else
						vStr = StrReplace(vStr, "&Type", vChequeType);
						vStr = StrReplace(vStr, "&CurrentDate", Format(CurrentDate(), "DF=dd.MM.yyyy"));
						vStr = StrReplace(vStr, "&CurrentTime", Format(CurrentDate(), "DF=HH:mm"));
						Try
							vStr = StrReplace(vStr, "&Document", ?(pSum >= 0, "Предварительный счет", "Возврат по платежу") + " № " + TrimAll(pObj.Number));
						Except
						EndTry;
						Try
							vStr = StrReplace(vStr, "&Hotel", tcCashRegisters.GetHotelPrintName(pObj.Hotel));
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
						vStr = GetString(vStr); 
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT, vStr);
						vFR.setParam(vFR.LIBFPTR_PARAM_TEXT_WRAP, vFR.LIBFPTR_TW_NONE);
						If vFR.printText() <> 0 Then
							ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndDo;
				
				// Print cliche
				If vDoPrintClicheAtEnd Then
					If vFR.printCliche() <> 0 Then
						ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				Else
					For s = 0 To 5 Do
						vFR.printText();
					EndDo;
				EndIf;
				
				// Cut off cheque
				vFR.setParam(vFR.LIBFPTR_PARAM_CUT_TYPE, vFR.LIBFPTR_CT_FULL);
				vFR.cut();
				vFR.setParam(vFR.LIBFPTR_PARAM_PRINT_FOOTER, False);
				vFR.endNonfiscalDocument();
				// Disconnect
				Disconnect(vFR);
				Return True;		
			Else
				ProcessResultCode(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);	
			EndIf;
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
		vFR.setParam(vFR.LIBFPTR_PARAM_DATA_TYPE, vFR.LIBFPTR_DT_STATUS);
    	If vFR.queryData() = 0 Then
			If vFR.getParamInt(vFR.LIBFPTR_PARAM_SHIFT_STATE) = vFR.LIBFPTR_SS_EXPIRED Then
				If Not pSkip24HoursLimitWarning Then
					rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
					Disconnect(vFR);
					Return False;
				EndIf;
			EndIf;
			// Check paper
			If Not CashRegister.IgnoreEndOfPaperError And Not vFR.getParamBool(vFR.LIBFPTR_PARAM_RECEIPT_PAPER_PRESENT) Then
				rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			//Check cheque printer
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_CONNECTION_LOST) Then
				rMessage = NStr("ru='ККМ не может установить связь с принтером чеков!'; en='Cash register failes to connect to the cheque printer!'; de='Cash register failes to connect to the cheque printer!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_ERROR) Then
				rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
				Disconnect(vFR);
				Return False;
			EndIf;
			If vFR.getParamBool(vFR.LIBFPTR_PARAM_PRINTER_OVERHEAT) Then
				rMessage = NStr("ru='Перегрев принтера чеков! Повторите попытку позже.'; en='Cheque printer overheated! Wait a while and try again.'; de='Cheque printer overheated! Wait a while and try again.'");
				Disconnect(vFR);
				Return False;
			EndIf;
		Else
			rMessage = NStr("ru='Ошибка получения состояния ККМ!'; en='Failed to check cash register state!'; de='Failed to check cash register state!'");
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
			vFR.openDrawer();
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
Function pmGetFDF(rMessage) Export
	vFDF = Undefined;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return Undefined;
	Else 
		// Open drawer
		Try			
			vFR.setParam(vFR.LIBFPTR_PARAM_FN_DATA_TYPE, vFR.LIBFPTR_FNDT_FFD_VERSIONS);
			vFR.fnQueryData();  
			
			If vFR.GetParamInt(vFR.LIBFPTR_PARAM_FFD_VERSION) = vFR.LIBFPTR_FFD_1_2 Then
				vFDF = Enums.FiscalDataFormatVersions.FDF_1_2;	
			ElsIf vFR.GetParamInt(vFR.LIBFPTR_PARAM_FFD_VERSION) = vFR.LIBFPTR_FFD_1_1 Then
				vFDF = Enums.FiscalDataFormatVersions.FDF_1_1;					
			Else
				vFDF = Enums.FiscalDataFormatVersions.FDF_1_0_5;	
			EndIf;
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return Undefined;
		EndTry;		
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return vFDF;	
EndFunction // pmGetFDF

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
EndFunction // CheckUnitPiece
