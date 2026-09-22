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
Function GetBaudRate()
	vRate = CashRegister.BaudRate;
	If vRate = 0 Then
		Return 19200; //default rate
	Else
		Return vRate;
	EndIf;
EndFunction // GetPortNumber

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj)
	If ValueIsFilled(pObj.VATRate) Then
		Return pObj.VATRate.TaxGroup;
	Else
		Return 0;
	EndIf;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vFR = New COMObject("ArtSoft.DatecsFP3530T");
		// Apply connection parameters
		// COM port
		vPortNumber = GetPortNumber();
		vBoudRate = GetBaudRate();
		// Write log file
		If CashRegister.WriteLogFile Then
			vFR.Debugger(true); 
		Else
			vFR.Debugger(false); 
		EndIf;
		If CashRegister.Timeout > 0 Then
			vFR.SetReadTimeout(CashRegister.Timeout);
		EndIf;

		vFR.OpenPort(vPortNumber,vBoudRate);
		If vFR.LastError <> 0 Then
			ProcessResultCode(vFR.LastError,vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
			Return Undefined;
		EndIf;
		// OK
		Return vFR;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pFR)
	Try
		pFR.ClosePort();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function CloseOpenCheque(pFR, rMessage)
	// Get cash register state info
	pFR.GetFiscalClosureStatus(False);
	vRC = pFR.LastError;
	If vRC <> 0 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"), rMessage);
		Return False;
	EndIf;
	If pFR.s1 = 1 Then
		pFR.CancelReceipt();		
		vRC = pFR.LastError;
		If vRC <> 0 Then
			ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"), rMessage);
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // CloseOpenCheque

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected, so try to check it state
		Try
			// Check paper
			vFR.GetDiagnosticInfo(false);
			rMessage = "v."+vFR.s1+","+vFR.s2+",<"+vFR.s3+">,"+vFR.s4+",№:"+vFR.s5+","+vFR.s6; 
			// Close connection
			Disconnect(vFR);
			Return True;
		Except
			rMessage = ErrorDescription();
			Disconnect(vFR);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.LastErrorText);
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.GetErrorComment(pRC));
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Try
		pFR.CancelReceipt();
		vRC = pFR.LastError;
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	rMessage = TrimAll(ErrorDescription());
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function SetDeviceTime(pFR, rMessage)
	// Set device date
	pFR.SetDateTime(Format(CurrentSessionDate(),"DF=dd.MM.yy"), Format(CurrentSessionDate(),"DF=HH:mm"));
	vRC = pFR.LastError;
	If vRC <> 0 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do cash income
			vFR.InOut(pSum);
			vRC = vFR.LastError;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do cash income
			vFR.InOut(-pSum);
			vRC = vFR.LastError;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do report
			vPass = GetDevicePassword();
			vFR.XReport(vPass);
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage) Export
	rMessage = NStr("ru='Печать почасового отчета не поддерживается драйвером!'; en='Hourly X Report is not supported by driver!'; de='Hourly X Report is not supported by driver!'");
	Return False;
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do report
			vPass = GetDevicePassword();
			vFR.ZReport(vPass);
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmCloseSession(rMessage) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Close open cheque if any
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Close session if open
			vPass = GetDevicePassword();
			vFR.ZReport(vPass);
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCloseSession

// -----------------------------------------------------------------------------
Function GetDepartment(pObj, rDepartmentName) 
	vDepartment = 0;
	rDepartmentName = "";
	If ValueIsFilled(pObj.PaymentSection) Then
		vDepartment = pObj.PaymentSection.Code;
		If CashRegister.PrintPaymentSectionNamesInCheques Then
			rDepartmentName = TrimAll(pObj.PaymentSection.Description);
		EndIf;
	Else
		rDepartmentName = NStr("en='Services';ru='Услуги';de='Dienstleistungen'");
	EndIf;
	Return vDepartment;
EndFunction // GetDepartment

// -----------------------------------------------------------------------------
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage) Export
	Var rDepartmentName;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), True);
					If vRC <> 0 Then
						ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			//Set articles prices
			vDevicePassword = GetDevicePassword();
			rDepartmentName = "";
			vDepartment = GetDepartment(pObj, rDepartmentName);
			vTaxGroup = GetTaxGroup(pObj.PaymentSection);
			vFR.SetArticle(vDepartment, vTaxGroup, 1, pSum, vDevicePassword, rDepartmentName);
			
			vOperator = GetOperator();
			vPassword = GetPassword();
			vPlaceNumber = GetPlaceNumber();
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;

			// Open cheque
			If pSum >= 0 Then
				vFR.OpenFiscalReceipt(vOperator, vPassword, vPlaceNumber);
			Else
				vFR.OpenReturnReceipt(vOperator, vPassword, vPlaceNumber);
			EndIf;
			If vFR.LastError <> 0 Then
				ProcessResultCode(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				vFR.CancelReceipt();
				Disconnect(vFR);
				Return False;
			EndIf;
			
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			// Print payment number
			If pSum >= 0 Then
				vPrintStr = "#" + TrimAll(pObj.Number);
				vFR.PrintFiscalText(vPrintStr);
				
				vFR.RegistrItem(vDepartment, 1, 0, 0);
				If vFR.LastError <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum >= 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vPrintStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vPrintStr = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vFR.PrintFiscalText(vPrintStr);
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; de = 'Betrag inkl. MwSt.'"));
					vFR.PrintFiscalText(vPrintStr);
				EndIf;
			EndIf;
			// Add payment
			vPayMode = GetPaymentMode(pObj.PaymentMethod);
			vFR.Total(, vPayMode, pSum);
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Close cheque
			vFR.CloseFiscalReceipt();
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCustomerPaymentCheque

// -----------------------------------------------------------------------------
Function GetOperator()
	Return 1;
EndFunction // GetOperator

// -----------------------------------------------------------------------------
Function GetPassword()
	vPass = "0000";
	If ValueIsFilled(SessionParameters.CurrentUser) Then
		If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) Then
			If ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences.CashRegisterPassword) Then
				vPass = TrimAll(SessionParameters.CurrentUser.EmployeePreferences.CashRegisterPassword);
			EndIf;
		EndIf;
	EndIf;
	If vPass = "0000" And ValueIsFilled(CashRegister) And Not IsBlankString(CashRegister.CashRegisterPassword) Then
		vPass = TrimAll(CashRegister.CashRegisterPassword);
	EndIf;
	Return vPass;
EndFunction // GetPassword

// -----------------------------------------------------------------------------
Function GetDevicePassword()
	vPass = "0000";
	If ValueIsFilled(CashRegister.AccessPassword) Then
		vPass = TrimAll(CashRegister.AccessPassword);
	EndIf;
	Return vPass;
EndFunction // GetDevicePassword

// -----------------------------------------------------------------------------
Function GetPlaceNumber()
	Return 1;
EndFunction // GetPlaceNumber

// -----------------------------------------------------------------------------
Function GetPaymentMode(vPaymentMethod)
	If ValueIsFilled(vPaymentMethod) Then
		Return vPaymentMethod.CashRegisterChequeCloseType;
	EndIf;
	Return 1;
EndFunction // GetPaymentMode

// -----------------------------------------------------------------------------
Procedure SetArticles(pFR, pObj)
	vPass = GetDevicePassword();
	
	If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
	   pObj.PaymentSections.Count() > 0 Then
		For Each vPSRow In pObj.PaymentSections Do
			If vPSRow.Sum = 0 Then
				Continue;
			EndIf;
			// Get document cash department number and description
			rDepartmentName = "";
			vDepartment = GetDepartment(vPSRow,rDepartmentName);
			vTaxGroup = GetTaxGroup(vPSRow);
			pFR.SetArticle(vDepartment, vTaxGroup, 1, vPSRow.Sum, vPass, rDepartmentName);
		EndDo;
	Else
		rDepartmentName = "";
		vDepartment = GetDepartment(pObj, rDepartmentName);
		vTaxGroup = GetTaxGroup(pObj.PaymentSection);
		pFR.SetArticle(vDepartment, vTaxGroup, 1, pObj.Sum, vPass, rDepartmentName);
	EndIf;
EndProcedure // SetArticles

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined) Export
	Var rDepartmentName;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), True);
					If vRC <> 0 Then
						ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			//Set articles prices
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			
			SetArticles(vFR, pObj);
			vOperator = GetOperator();
			vPassword = GetPassword();
			vPlaceNumber = GetPlaceNumber();

			// Open cheque
			If pSum = 0 Then
				vFR.PrintNullCheck();
				Return True;
			ElsIf pSum > 0 Then
				vFR.OpenFiscalReceipt(vOperator, vPassword, vPlaceNumber);
			Else
				vFR.OpenReturnReceipt(vOperator, vPassword, vPlaceNumber);
			EndIf;
			If vFR.LastError <> 0 Then
				ProcessResultCode(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				vFR.CancelReceipt();
				Disconnect(vFR);
				Return False;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			// Print payment number
			If pSum >= 0 Then
				If pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vFR.PrintFiscalText(vPrintStr);
					EndIf;
					For Each vPSRow In pObj.PaymentSections Do
						If vPSRow.Sum = 0 Then
							Continue;
						EndIf;
						
						// Get document cash department number and description
						vDepartment = GetDepartment(vPSRow, rDepartmentName);
						vPrintStr = GetString(rDepartmentName);
						// продажа товара на ККМ
						vFR.RegistrItem(vDepartment, 1, 0, 0);
						If vFR.LastError <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndDo;
				Else
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vFR.PrintFiscalText(vPrintStr);
					EndIf;
					vDepartment = GetDepartment(pObj, rDepartmentName);
					vFR.RegistrItem(vDepartment, 1, 0, 0);
					If vFR.LastError <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum >= 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vPrintStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vPrintStr = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; en = 'Inkl. VAT '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vFR.PrintFiscalText(vPrintStr);
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Amount includes VAT'; de = 'Betrag inkl. MwSt.'"));
					vFR.PrintFiscalText(vPrintStr);
				EndIf;
			EndIf;
			// Add payment
			vPayMode = GetPaymentMode(pObj.PaymentMethod);
			vFR.Total(, vPayMode, pSum);
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Close cheque
			vFR.CloseFiscalReceipt();
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj);
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Procedure LogCashPayment(pFR, pFunction, pObj)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de='für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage) Export
	Var rDepartmentName;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		If pSum < 0 Then
			Raise NStr("ru = 'Анулирование не поддерживается для возвратов!'; en = 'Annulation is not supported for returns!'; de = 'Annulation is not supported for returns!'");
		EndIf;
		// Cash register was connected
		Try
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), True);
					If vRC <> 0 Then
						ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			// Set articles prices
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			
			SetArticles(vFR, pObj);
			vOperator = GetOperator();
			vPassword = GetPassword();
			vPlaceNumber = GetPlaceNumber();

			// Open cheque
			vFR.OpenReturnReceipt(vOperator, vPassword, vPlaceNumber);
			If vFR.LastError <> 0 Then
				ProcessResultCode(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				vFR.CancelReceipt();
				Disconnect(vFR);
				Return False;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			
			// Print payment number
			If pSum >= 0 Then
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vFR.PrintFiscalText(vPrintStr);
					EndIf;
					For Each vPSRow In pObj.PaymentSections Do
						If vPSRow.Sum = 0 Then
							Continue;
						EndIf;
						
						// Get document cash department number and description
						vDepartment = GetDepartment(vPSRow, rDepartmentName);
						vPrintStr = GetString(rDepartmentName);
						// продажа товара на ККМ
						vFR.RegistrItem(vDepartment, 1, 0, 0);
						If vFR.LastError <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndDo;
				Else
					vPrintStr = NStr("en='Services';ru='Услуги';de='Dienstleistungen'");
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vFR.PrintFiscalText(vPrintStr);
					EndIf;
					vFR.RegistrItem(vDepartment, 1, 0, 0);
					If vFR.LastError <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum >= 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vPrintStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vPrintStr = GetString(NStr("ru = 'В т.ч. НДС '; en = 'Incl. VAT '; de = 'Inkl. VAT '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vFR.PrintFiscalText(vPrintStr);
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru = 'НДС включён в сумму'; en = 'Sum includes VAT'; de = 'Betrag inkl. MwSt.'"));
					vFR.PrintFiscalText(vPrintStr);
				EndIf;
			EndIf;
			
			// Add payment
			vPayMode = GetPaymentMode(pObj.PaymentMethod);
			vFR.Total(, vPayMode, pSum);
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Close cheque
			vFR.CloseFiscalReceipt();
			If vFR.LastError <> 0 Then
				CancelCheque(vFR.LastError, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Log cash register operation
			LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj);
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulateCheque

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de='für einen Betrag von'") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек аннуляции'; en = ' storno cheque was issued'; de = ' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Function PrintSlipLines(pFR, pSlipTextArr, pInCheque = False)
	//Open non fiscal document
	pFR.OpenNonfiscalReceipt();
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		pFR.PrintNonfiscalText(vStr);
	EndDo;
	// Print second slip for the client
	pFR.PrintNonfiscalText("");
	vStr = GetString("-8<--------------------------------------------------------------------");
	pFR.PrintNonfiscalText(vStr);
	vStr = NStr("ru = 'ДЛЯ КЛИЕНТА'; en = 'FOR THE CLIENT'; de = 'FÜR DEN KUNDEN'");
	pFR.PrintNonfiscalText(vStr);
	For Each vStr In pSlipTextArr Do
		pFR.PrintNonfiscalText(vStr);
	EndDo;
	pFR.CloseNonfiscalReceipt();
	vRC = pFR.LastError;
	If vRC <> 0 Then
		Return vRC;
	EndIf;
	Return 0;
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Print all strings in the array
			vRC = PrintSlipLines(vFR, pSlipTextArr, False);
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj)
	// Header start delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.PrintFiscalText(vStr);
	// Folio #
	vStr = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + cmGetDocumentNumberPresentation(pObj.Folio.Number));
	vRC = pFR.PrintFiscalText(vStr);
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		vStr = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer: '") + TrimAll(pObj.Folio.Room));
		vRC = pFR.PrintFiscalText(vStr);
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) And ValueIsFilled(pObj.Payer) Then
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer));
		Else
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Folio.Client));
		EndIf;
		vRC = pFR.PrintFiscalText(vStr);
	EndIf;
	// Guest group
	vStr = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup));
	vRC = pFR.PrintFiscalText(vStr);
	// Document
	vStr = GetString(NStr("ru = 'Док.  № '; en = 'Doc.  # '; de = 'Dok. Nr.'") + cmGetDocumentNumberPresentation(pObj.Number));
	vRC = pFR.PrintFiscalText(vStr);
	// Cashier
	vStr = GetString(NStr("ru = 'Кассир: '; en = 'Cashier '; de = 'Kassierer '") + TrimAll(SessionParameters.CurrentUser.Description));
	vRC = pFR.PrintFiscalText(vStr);
	// Header end delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.PrintFiscalText(vStr);
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	Return True;
EndFunction // pmIsReadyToPrint
