
#Region Public

// -----------------------------------------------------------------------------
Function pmSetCashier(pCode, pPwd, pName, rMessage) Export
	vResult = True;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		vResult = False;
	Else
		vRC = vFR.SetCashier(Format(pCode, "ND=2; NFD=; NZ=; NLZ=; NG="), Left(pPwd, 5), pName);
		If vRC <> 0 Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.SetCashier'; de='CashRegister.SetCashier'; ru='ККМ.УстановкаКассира'"), rMessage);
			vResult = False;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // pmSetCashier

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
			vRC = vFR.ChkPrn();
			If vRC = 1 Or vRC = -1 Then
				rMessage = NStr("ru='Закончилась бумага!'; en='Out of paper!'; de='Out of paper!'");
				Disconnect(vFR);
				Return True;
			EndIf;
			// Check session 24 hours limit
			vRC = vFR.ChkShift();
			If vRC = -4 Then
				rMessage = NStr("ru='Текущая смена превысила лимит в 24 часа! Необходимо снять Z-отчет.'; en='Current session is out of 24 hours limit! You have to run Z-Report.'; de='Current session is out of 24 hours limit! You have to run Z-Report.'");
				Disconnect(vFR);
				Return True;
			EndIf;
			// Close currently open check if any
			If Not CloseOpenCheque(vFR, rMessage) Then
				Disconnect(vFR);
				Return True;
			EndIf;
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
			// Open session if neccessary
			If Not OpenSession(vFR, rMessage) Then
				Return False;
			EndIf;
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			// Do cash income
			vRC = vFR.CashIn(8, Format(pSum*100, "ND=10; NFD=; NZ=; NLZ=; NG="));
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
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
			// Open session if neccessary
			If Not OpenSession(vFR, rMessage) Then
				Return False;
			EndIf;
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			// Do cash outcome
			vRC = vFR.CashOut(8, Format(pSum*100, "ND=10; NFD=; NZ=; NLZ=; NG="));
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
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
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;
			// Do report
			vRC = vFR.TotalRep();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
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
	Return pmCloseSession(rMessage);
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			
			// Open free text cheque
			vRC = vFR.StartFreeDoc();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
				Return False;
			EndIf;
			
			// Report header
			vStr = "    ОТЧЕТ О ТЕКУЩЕМ СОСТОЯНИИ РАСЧЕТОВ";
			vRC = vFR.PrintText(0, GetString(vStr));
			
			// Report body
			vStr = "  НЕПОДТВЕРЖДЕННЫЕ ДОКУМЕНТЫ:";
			vRC = vFR.PrintText(0, GetString(vStr));
			vStr = "  КОЛ-ВО: " + vFR.GetTextDeviceInfo(15);
			vRC = vFR.PrintText(0, GetString(vStr));
			vStr = "  ДАТА ПЕРВОГО ДОК-ТА: " + Left(vFR.GetTextDeviceInfo(17), 10);
			vRC = vFR.PrintText(0, GetString(vStr));
			
			// End free cheque
			vRC = vFR.EndFreeDoc();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
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
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	Var rDepartmentName;
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
			
			// Open session if neccessary
			If Not OpenSession(vFR, rMessage) Then
				Return False;
			EndIf;
			
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			vChequeAttributes.FDFVersion = "1.0";
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				rMessage = NStr("ru='Чеки коррекции не поддерживаются драйвером ККМ!'; en='Correction cheques are not supported by driver!'; de='Correction cheques are not supported by driver!'");
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			vRC = vFR.SetTaxSystem(vTaxSystemCode);
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			vChequeAttributes.TaxationSystem = vTaxSystem;
			
			// Set cashier name
			vCashierName = Left(TrimAll(pObj.Author), 64);
			If Not IsBlankString(vCashierName) Then
				vChequeAttributes.CashierName = vCashierName;
			EndIf;
			
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			
			// Open cheque
			If pSum >= 0 Then
				vRC = vFR.StartDocSB(1);
			Else
				vRC = vFR.StartDocSB(2);
			EndIf;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			vRC = vFR.PrintExtraDocData2("", "", "", vCashierName);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// VAT rate
			vVATRate = Undefined;
			vTaxTypeNumber = 0;
			If ValueIsFilled(pObj.PaymentSection) Then
				vTaxTypeNumber = GetTaxGroup(pObj.PaymentSection);
				vVATRate = pObj.PaymentSection.VATRate;
			Else
				vTaxTypeNumber = GetTaxGroup(pObj);
				vVATRate = pObj.VATRate;
			EndIf;
			cmSetChequeVATAmount(vChequeAttributes, vVATRate, ?(pVATSum < 0, -pVATSum, pVATSum));
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), True);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Print payment number
			vPrintStr = "#" + TrimAll(pObj.Number);
			If Not IsBlankString(rDepartmentName) Then
				vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
			EndIf;
			vRC = vFR.Item(1000, ?(pSum < 0, -pSum, pSum)*100, vPrintStr, vTaxTypeNumber);
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vStr = "";
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vStr = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vRC = vFR.PrintText(0, vStr);
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vStr = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
				vRC = vFR.PrintText(0, vStr);
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
			If Not IsBlankString(vEMail) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vRC = vFR.AddReq(16, vEMail);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			vChequeAttributes.BuyerAddress = vEMail;
			
			// Add payment
			vRC = vFR.AddPay(GetPaymentType(pObj), Format(?(pSum < 0, -pSum, pSum)*100, "ND=10; NFD=; NZ=; NLZ=; NG="));
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			// Close document
			vRC = vFR.EndDocSB();
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			If pSum >= 0 Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			EndIf;
			vChequeAttributes.CashDayChequeNumber = Number(vFR.GetTextDeviceInfo(3));
			vChequeAttributes.CashDay = Number(vFR.GetTextDeviceInfo(8)) + 1;
			vChequeAttributes.ChequeSequenceNumber = vFR.GetTextDeviceInfo(10);
			vChequeDateTime = vFR.GetTextDeviceInfo(11);
			vChequeAttributes.ChequeDateTime = Date(Number(Mid(vChequeDateTime, 7, 4)), Number(Mid(vChequeDateTime, 4, 2)), Number(Left(vChequeDateTime, 2)), Number(Mid(vChequeDateTime, 12, 2)), Number(Mid(vChequeDateTime, 15, 2)), 0);
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.GetTextDeviceInfo(14);
			vChequeAttributes.ChequeFiscalNumber = vFR.GetTextDeviceInfo(18);
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj, vChequeAttributes);
			
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCustomerPaymentCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	Var rDepartmentName;
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
			
			// Open session if neccessary
			If Not OpenSession(vFR, rMessage) Then
				Return False;
			EndIf;
			
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			vChequeAttributes.FDFVersion = "1.0";
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				rMessage = NStr("ru='Чеки коррекции не поддерживаются драйвером ККМ!'; en='Correction cheques are not supported by driver!'; de='Correction cheques are not supported by driver!'");
				Disconnect(vFR);
				Return False;
			EndIf;				
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
			vRC = vFR.SetTaxSystem(vTaxSystemCode);
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			vChequeAttributes.TaxationSystem = vTaxSystem;
			
			// Set cashier name
			vCashierName = Left(TrimAll(pObj.Author), 64);
			If Not IsBlankString(vCashierName) Then
				vChequeAttributes.CashierName = vCashierName;
			EndIf;
			
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			
			// Open cheque
			If pSum >= 0 Then
				vRC = vFR.StartDocSB(1);
			Else
				vRC = vFR.StartDocSB(2);
			EndIf;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			vRC = vFR.PrintExtraDocData2("", "", "", vCashierName);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.SlipText), True);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vFR, pObj);
			EndIf;
			
			// Print payment
			If Not pIsCorrection Then
				If NOT CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						vDepartment = 1;
						vPrintStr = "";
						If ValueIsFilled(vSrvRow.Service) Then
							vDepartment = GetDepartment(vSrvRow.Service, rDepartmentName);
							vPrintStr = GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						EndIf;
						If vSrvRow.Amount > 0 Then
							vItemQuantity = ?(vSrvRow.Quantity = 0, 1, vSrvRow.Quantity);
							vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
							vItemPrice = 0;
							tcCashRegisters.ChequeItemAttributesCorrection(vSrvRow.Amount, vItemQuantity, 3, vItemPrice, vItemQuantity);
							vRC = vFR.Item(vItemQuantity*1000, vItemPrice*100, vPrintStr, GetTaxGroup(vSrvRow));
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
					EndDo;
				Else
					If pObj.PaymentSections.Count() > 0 Then
						If Not CashRegister.PrintFolioHeader Then
							vPrintStr = "#" + TrimAll(pObj.Number);
							vRC = vFR.PrintText(0, vPrintStr);
						EndIf;
						vPSRows = cmGetPrintableChequePositions(pObj, , CashRegister.AlwaysUseAveragePrice);
						If Not CashRegister.DoNotPrintPaymentSections Then
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									pSum = pSum - vPSRow.Sum;
									Continue;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								vSectionVATAmount = vPSRow.VATSum;
								If vSectionAmount < 0 Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								
								// Get document cash department number and description
								rDepartmentName = "";
								vDepartment = GetDepartment(vPSRow, rDepartmentName);
								
								// VAT rate
								vVATRate = Undefined;
								vTaxTypeNumber = 0;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vTaxTypeNumber = GetTaxGroup(vPSRow.PaymentSection);
									vVATRate = vPSRow.PaymentSection.VATRate;
								Else
									vTaxTypeNumber = GetTaxGroup(pObj);
									vVATRate = pObj.VATRate;
								EndIf;
								cmSetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								
								// Print name, price and quantity
								vRC = 0;
								If ValueIsFilled(vPSRow.ChequeService) Then
									If vSectionAmount > 0 Then
										vPrintStr = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
										vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
										vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
										vItemPrice = 0;
										tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
										vRC = vFR.Item(vItemQuantity*1000, vItemPrice*100, vPrintStr, vTaxTypeNumber);
									EndIf;
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									If Not CashRegister.PrintPaymentSectionNamesInCheques Then 
										vPrintStr = GetString(TrimAll(vPSRow.PaymentSection.Code));
									Else
										vPrintStr = GetString(rDepartmentName);
									EndIf;
									vItemAmount = ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount);
									vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
								Else
									If vSectionAmount >=0 Then
										vPrintStr = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
									Else
										vPrintStr = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
									EndIf;
									vItemAmount = ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount);
									vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
								EndIf;
								If vRC <> 0 Then
									CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
							EndDo;
						Else
							vAmount = 0;
							vVATAmount = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									pSum = pSum - vPSRow.Sum;
									Continue;
								EndIf;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vAmount = vAmount - vPSRow.Sum;
									vVATAmount = vVATAmount - vPSRow.VATSum;
								Else
									vAmount = vAmount + vPSRow.Sum;
									vVATAmount = vVATAmount + vPSRow.VATSum;
								EndIf;
							EndDo;
							
							// Get document cash department number and description
							rDepartmentName = "";
							vDepartment = GetDepartment(pObj, rDepartmentName);
							
							// VAT rate
							vVATRate = Undefined;
							vTaxTypeNumber = 0;
							If ValueIsFilled(pObj.PaymentSection) Then
								vTaxTypeNumber = GetTaxGroup(pObj.PaymentSection);
								vVATRate = pObj.PaymentSection.VATRate;
							Else
								vTaxTypeNumber = GetTaxGroup(pObj);
								vVATRate = pObj.VATRate;
							EndIf;
							cmSetChequeVATAmount(vChequeAttributes, vVATRate, pObj.VATSum);
							
							// Print name, price and quantity
							vRC = 0;
							If ValueIsFilled(pObj.PaymentSection) Then
								If Not CashRegister.PrintPaymentSectionNamesInCheques Then 
									vPrintStr = GetString(TrimAll(pObj.PaymentSection.Code));
								Else
									vPrintStr = GetString(rDepartmentName);
								EndIf;
								vItemAmount = ?(vAmount >=0, vAmount, -vAmount);
								vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
							Else
								If vAmount >=0 Then
									vPrintStr = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
								Else
									vPrintStr = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
								EndIf;
								vItemAmount = ?(vAmount >=0, vAmount, -vAmount);
								vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
							EndIf;
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
					Else
						// VAT rate
						vVATRate = Undefined;
						vTaxTypeNumber = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vTaxTypeNumber = GetTaxGroup(pObj.PaymentSection);
							vVATRate = pObj.PaymentSection.VATRate;
						Else
							vTaxTypeNumber = GetTaxGroup(pObj);
							vVATRate = pObj.VATRate;
						EndIf;
						cmSetChequeVATAmount(vChequeAttributes, vVATRate, pObj.VATSum);
						
						// Item
						vPrintStr = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						If Not CashRegister.PrintFolioHeader Then
							vPrintStr = GetString("#" + TrimAll(pObj.Number));
						EndIf;
						If ValueIsFilled(pObj.PaymentSection) Then
							If Not CashRegister.PrintFolioHeader Then
								vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
							Else
								vPrintStr = GetString(rDepartmentName);
							EndIf;
						EndIf;
						vRC = vFR.Item(1000, ?(pSum < 0, -pSum, pSum)*100, vPrintStr, vTaxTypeNumber);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vStr = "";
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
				If vNoVAT Then
					vStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
				Else
					vStr = GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
				EndIf;
				vRC = vFR.PrintText(0, vStr);
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				vStr = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
				vRC = vFR.PrintText(0, vStr);
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
			If Not IsBlankString(vEMail) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
				vRC = vFR.AddReq(16, vEMail);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			vChequeAttributes.BuyerAddress = vEMail;
			
			// Add payment
			vRC = vFR.AddPay(GetPaymentType(pObj), Format(?(pSum < 0, -pSum, pSum)*100, "ND=10; NFD=; NZ=; NLZ=; NG="));
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Close document
			vRC = vFR.EndDocSB();
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Get current cheque attributes
			If pSum >= 0 Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			EndIf;
			vChequeAttributes.CashDayChequeNumber = Number(vFR.GetTextDeviceInfo(3));
			vChequeAttributes.CashDay = Number(vFR.GetTextDeviceInfo(8)) + 1;
			vChequeAttributes.ChequeSequenceNumber = vFR.GetTextDeviceInfo(10);
			vChequeDateTime = vFR.GetTextDeviceInfo(11);
			vChequeAttributes.ChequeDateTime = Date(Number(Mid(vChequeDateTime, 7, 4)), Number(Mid(vChequeDateTime, 4, 2)), Number(Left(vChequeDateTime, 2)), Number(Mid(vChequeDateTime, 12, 2)), Number(Mid(vChequeDateTime, 15, 2)), 0);
			vChequeAttributes.FiscalStorageFactoryNumber = vFR.GetTextDeviceInfo(14);
			vChequeAttributes.ChequeFiscalNumber = vFR.GetTextDeviceInfo(18);
			
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj, vChequeAttributes);
			
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
			
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
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	Var rDepartmentName;
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else
		// Cash register was connected
		Try
			If pSum > 0 Then
				// Close open cheque if any
				If Not CloseOpenCheque(vFR, rMessage) Then
					Return False;
				EndIf;
				
				// Open session if neccessary
				If Not OpenSession(vFR, rMessage) Then
					Return False;
				EndIf;
				
				// Set cashier
				vRC = vFR.RegCashier(GetUserPassword());
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Initialize cheque attributes used to send online cheque by sms or e-mail
				vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
				vChequeAttributes.FDFVersion = "1.0";
				
				// Set correction type
				vChequeAttributes.IsCorrection = pIsCorrection;
				If pIsCorrection Then
					rMessage = NStr("ru='Чеки коррекции не поддерживаются драйвером ККМ!'; en='Correction cheques are not supported by driver!'; de='Correction cheques are not supported by driver!'");
					Disconnect(vFR);
					Return False;
				EndIf;				
				
				// Set taxation system
				vTaxSystem = Undefined;
				vTaxSystemCode = GetTaxationSystemCode(pObj, vTaxSystem);
				vRC = vFR.SetTaxSystem(vTaxSystemCode);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				vChequeAttributes.TaxationSystem = vTaxSystem;
				
				// Set cashier name
				vCashierName = Left(TrimAll(pObj.Author), 64);
				If Not IsBlankString(vCashierName) Then
					vChequeAttributes.CashierName = vCashierName;
				EndIf;
				
				// Get document cash department number and description
				vDepartment = GetDepartment(pObj, rDepartmentName);
				
				// Open cheque
				vRC = vFR.StartDocSB(2);
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				vRC = vFR.PrintExtraDocData2("", "", "", vCashierName);
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Print slip if payment was made by credit card
				If CashRegister.PrintSlipInCheque Then
					If Not IsBlankString(pObj.AnnulationSlipText) Then
						vRC = PrintSlipLines(vFR, cmGetTextLinesArray(pObj.AnnulationSlipText), True);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				EndIf;
				
				// Cheque folio header
				If CashRegister.PrintFolioHeader Then
					PrintFolioHeader(vFR, pObj);
				EndIf;
				
				// Print sections
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vRC = vFR.PrintText(0, vPrintStr);
					EndIf;
					vPSRows = cmGetPrintableChequePositions(pObj, , CashRegister.AlwaysUseAveragePrice);
					If Not CashRegister.DoNotPrintPaymentSections Then
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								pSum = pSum - vPSRow.Sum;
								Continue;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							vSectionVATAmount = vPSRow.VATSum;
							
							// Get document cash department number and description
							rDepartmentName = "";
							vDepartment = GetDepartment(vPSRow, rDepartmentName);
							
							// VAT rate
							vVATRate = Undefined;
							vTaxTypeNumber = 0;
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vTaxTypeNumber = GetTaxGroup(vPSRow.PaymentSection);
								vVATRate = vPSRow.PaymentSection.VATRate;
							Else
								vTaxTypeNumber = GetTaxGroup(pObj);
								vVATRate = pObj.VATRate;
							EndIf;
							cmSetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
							
							// Print name, price and quantity
							vRC = 0;
							If ValueIsFilled(vPSRow.ChequeService) Then
								If vSectionAmount > 0 Then
									vPrintStr = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									vItemPrice = 0;
									tcCashRegisters.ChequeItemAttributesCorrection(vSectionAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
									vRC = vFR.Item(vItemQuantity*1000, vItemPrice*100, vPrintStr, vTaxTypeNumber);
								EndIf;
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								If Not CashRegister.PrintPaymentSectionNamesInCheques Then 
									vPrintStr = GetString(TrimAll(vPSRow.PaymentSection.Code));
								Else
									vPrintStr = GetString(rDepartmentName);
								EndIf;
								vItemAmount = ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount);
								vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
							Else
								If vSectionAmount >=0 Then
									vPrintStr = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
								Else
									vPrintStr = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
								EndIf;
								vItemAmount = ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount);
								vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
							EndIf;
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
								Return False;
							EndIf;
						EndDo;
					Else
						vAmount = 0;
						vVATAmount = 0;
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								pSum = pSum - vPSRow.Sum;
								Continue;
							EndIf;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vAmount = vAmount - vPSRow.Sum;
								vVATAmount = vVATAmount - vPSRow.VATSum;
							Else
								vAmount = vAmount + vPSRow.Sum;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndIf;
						EndDo;
						
						// Get document cash department number and description
						rDepartmentName = "";
						vDepartment = GetDepartment(pObj, rDepartmentName);
						
						// VAT rate
						vVATRate = Undefined;
						vTaxTypeNumber = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vTaxTypeNumber = GetTaxGroup(pObj.PaymentSection);
							vVATRate = pObj.PaymentSection.VATRate;
						Else
							vTaxTypeNumber = GetTaxGroup(pObj);
							vVATRate = pObj.VATRate;
						EndIf;
						cmSetChequeVATAmount(vChequeAttributes, vVATRate, pObj.VATSum);
						
						// Print name, price and quantity
						vRC = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							If Not CashRegister.PrintPaymentSectionNamesInCheques Then 
								vPrintStr = GetString(TrimAll(pObj.PaymentSection.Code));
							Else
								vPrintStr = GetString(rDepartmentName);
							EndIf;
							vItemAmount = ?(vAmount >=0, vAmount, -vAmount);
							vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
						Else
							If vAmount >=0 Then
								vPrintStr = GetString(NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
							Else
								vPrintStr = GetString(NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
							EndIf;
							vItemAmount = ?(vAmount >=0, vAmount, -vAmount);
							vRC = vFR.Item(1000, vItemAmount*100, vPrintStr, vTaxTypeNumber);
						EndIf;
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				Else
					// VAT rate
					vVATRate = Undefined;
					vTaxTypeNumber = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vTaxTypeNumber = GetTaxGroup(pObj.PaymentSection);
						vVATRate = pObj.PaymentSection.VATRate;
					Else
						vTaxTypeNumber = GetTaxGroup(pObj);
						vVATRate = pObj.VATRate;
					EndIf;
					cmSetChequeVATAmount(vChequeAttributes, vVATRate, pObj.VATSum);
					
					// Item
					vPrintStr = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = GetString("#" + TrimAll(pObj.Number));
					EndIf;
					If ValueIsFilled(pObj.PaymentSection) Then
						If Not CashRegister.PrintFolioHeader Then
							vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
						Else
							vPrintStr = GetString(rDepartmentName);
						EndIf;
					EndIf;
					vRC = vFR.Item(1000, ?(pSum < 0, -pSum, pSum)*100, vPrintStr, vTaxTypeNumber);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum >= 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vPrintStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vPrintStr = GetString(NStr("ru='В т.ч. НДС ';en='Incl. VAT ';de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vRC = vFR.PrintText(0, vPrintStr);
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru='НДС включён в сумму';en='Amount includes VAT';de='Betrag inkl. MwSt.'"));
					vRC = vFR.PrintText(0, vPrintStr);
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
				If Not IsBlankString(vEMail) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vRC = vFR.AddReq(16, vEMail);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				vChequeAttributes.BuyerAddress = vEMail;
				
				// Add payment
				vRC = vFR.AddPay(GetPaymentType(pObj), Format(?(pSum < 0, -pSum, pSum)*100, "ND=10; NFD=; NZ=; NLZ=; NG="));
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				// Close document
				vRC = vFR.EndDocSB();
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				
				// Get current cheque attributes
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
				vChequeAttributes.CashDayChequeNumber = Number(vFR.GetTextDeviceInfo(3));
				vChequeAttributes.CashDay = Number(vFR.GetTextDeviceInfo(8)) + 1;
				vChequeAttributes.ChequeSequenceNumber = vFR.GetTextDeviceInfo(10);
				vChequeDateTime = vFR.GetTextDeviceInfo(11);
				vChequeAttributes.ChequeDateTime = Date(Number(Mid(vChequeDateTime, 7, 4)), Number(Mid(vChequeDateTime, 4, 2)), Number(Left(vChequeDateTime, 2)), Number(Mid(vChequeDateTime, 12, 2)), Number(Mid(vChequeDateTime, 15, 2)), 0);
				vChequeAttributes.FiscalStorageFactoryNumber = vFR.GetTextDeviceInfo(14);
				vChequeAttributes.ChequeFiscalNumber = vFR.GetTextDeviceInfo(18);
				
				// Log cash register operation
				LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj, vChequeAttributes);
				
				// Open drawer
				Try
					vFR.OpenCDrw();
				Except
				EndTry;
				
				// Disconnect
				Disconnect(vFR);
				Return True;
			Else
				Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
			EndIf;
		Except
			ProcessException(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulateCheque

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
			vRC = vFR.ChkShift();
			If vRC <> -3 And vRC <> -4 And vRC <> -2 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				Return False;
			ElsIf vRC = -2 Then
				rMessage = NStr("ru = 'Смена уже закрыта!'; en = 'Session is already closed!'; de = 'Session is already closed!'");
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				Return True;
			EndIf;
			// Set cashier
			vRC = vFR.RegCashier(GetUserPassword());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				Return False;
			EndIf;
			// Close session
			vRC = vFR.CloseShift();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				Return False;
			EndIf;
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			Try
				vFR.OpenCDrw();
			Except
			EndTry;
			// Open new session
			If Not CashRegister.DoNotOpenNewSessionAfterZReport Then
				If Not OpenSession(vFR, rMessage) Then
					Return False;
				EndIf;
			Else
	 			// Check time difference between workstation and cash register and correct 
				// device time if difference is more then 5 minutes
				If Not CheckTimeDifference(vFR, rMessage) Then
					// Disconnect
					Disconnect(vFR);
					Return False;
				EndIf;
			EndIf;
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
			// Open session if neccessary
			If Not OpenSession(vFR, rMessage) Then
				Return False;
			EndIf;
			For i = 1 To 2 Do
				// Print 2 copies of slip
				// Print all strings in the array
				vRC = PrintSlipLines(vFR, pSlipTextArr, False);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
					Return False;
				EndIf;
			EndDo;			
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
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Check session 24 hours limit
		vRC = vFR.ChkShift();
		If vRC = -4 Then
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		EndIf;
		// Check paper
		vRC = vFR.ChkPrn();
		If vRC = 1 Or vRC = -1 Then
			rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		ElsIf vRC <> 0 And vRC <> 2 And vRC <> -2 Then
			rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check FN
		vRC = vFR.ChkFS();
		If vRC = 3 Or vRC = -3 Then
			rMessage = NStr("ru='Ошибка фискальной памяти!'; en='Fiscal memory error!'; de='Fiscal memory error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check SFDO
		vRC = vFR.ChkSFDO();
		If vRC = 1 Or vRC = -1 Then
			rMessage = NStr("ru='Сервис связи с ОФД недоступен!'; en='OFD connection service is not available!'; de='OFD connection service is not available!'");
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			
			// Open free text cheque
			vRC = vFR.StartFreeDoc();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
				Return False;
			EndIf;
			
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			
			// Convert cheque template to the array of strings
			vTextArr = cmGetTextLinesArray(pChequeTemplate);
			
			// Print first slip for the hotel
			i = 0;
			For Each vStr In vTextArr Do
				i = i + 1;
				If vStr = "&Cliche" And i = 1 Then
					vRC = PrintHeader(vFR);
					If vRC <> 0 Then
						ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf vStr = "&Cliche" And i = vTextArr.Count() Then
					//vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vFR, pObj);
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
					If vStr = "" Then
						vStr = " ";
					EndIf;
					vRC = vFR.PrintText(0, GetString(vStr));
				EndIf;
			EndDo;
			
			// Print cliche
			If vDoPrintClicheAtEnd Then
				vRC = PrintHeader(vFR);
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			
			// End free cheque
			vRC = vFR.EndFreeDoc();
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
				Return False;
			EndIf;
			
			// Disconnect
			Disconnect(vFR);
			Return True;
		Except
			ProcessException(vFR, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetString(pStr)
	If CashRegister.ChequeWidth > 0 Then
		Return Left(pStr, CashRegister.ChequeWidth);
	Else
		Return Left(pStr, 42);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Function GetUserPassword()
	vCassirPassword = "11111";
	If ValueIsFilled(SessionParameters.CurrentUser) And 
	   ValueIsFilled(SessionParameters.CurrentUser.EmployeePreferences) And 
	   Not IsBlankString(SessionParameters.CurrentUser.EmployeePreferences.CashRegisterPassword) Then
		vCassirPassword = Format(Number(TrimAll(SessionParameters.CurrentUser.EmployeePreferences.CashRegisterPassword)), "ND=5; NFD=; NZ=; NLZ=; NG=");
	ElsIf ValueIsFilled(CashRegister) And Not IsBlankString(CashRegister.CashRegisterPassword) Then
		vCassirPassword = Format(Number(TrimAll(CashRegister.CashRegisterPassword)), "ND=5; NFD=; NZ=; NLZ=; NG=");
	EndIf;
	Return Left(vCassirPassword, 5);
EndFunction // GetUserPassword

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj)
	If ValueIsFilled(pObj.VATRate) Then
		Return pObj.VATRate.TaxGroup;
	Else
		Return 0;
	EndIf;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function GetTaxationSystemCode(pObj, rTaxSystem = Undefined)
	vTaxSystemByte = 0;
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
		If rTaxSystem = Enums.TaxationSystems.Common Then
			vTaxSystemByte = 0;
		ElsIf rTaxSystem = Enums.TaxationSystems.SimplifiedIncome Then
			vTaxSystemByte = 1;
		ElsIf rTaxSystem = Enums.TaxationSystems.SimplifiedIncomeMinusOutcome Then
			vTaxSystemByte = 2;
		ElsIf rTaxSystem = Enums.TaxationSystems.UnifiedTaxOnImputedIncome Then
			vTaxSystemByte = 3;
		ElsIf rTaxSystem = Enums.TaxationSystems.UnifiedAgriculturalTax Then
			vTaxSystemByte = 4;
		ElsIf rTaxSystem = Enums.TaxationSystems.PatentTaxationSystem Then
			vTaxSystemByte = 5;
		EndIf;
	EndIf;
	Return vTaxSystemByte;
EndFunction // GetTaxationSystemCode

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vFR = New COMObject("UDSpark.FPSpark");
		// Apply connection parameters
		// Access password
		If Not IsBlankString(CashRegister.AccessPassword) Then
			vRC = vFR.SetAccessKey(TrimAll(CashRegister.AccessPassword));
		Else
			vRC = vFR.SetAccessKey("111111");
		EndIf;
		If vRC <> 0 Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
			Return Undefined;
		EndIf;
		// Try to enable device
		vRC = vFR.InitDevice();
		If vRC <> 0 Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
			Return Undefined;
		EndIf;
		// Check connection to cash register
		vPrinterDateTime = vFR.GetTextDeviceInfo(4);
		If IsBlankString(vPrinterDateTime) Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
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
		pFR.DeinitDevice();
		pFR = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function CloseOpenCheque(pFR, rMessage)
	// Get cash register state info
	vRC = pFR.ChkFS();
	If vRC <> 0 Тогда
		If vRC <> -1 And vRC <> 1 Then
			ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"), rMessage);
			Return False;
		Else
			vRC = pFR.CancelDoc();
		EndIf;
		If vRC <> 0 Then
			ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"), rMessage);
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // CloseOpenCheque

// -----------------------------------------------------------------------------
Function OpenSession(pFR, rMessage)
	// Get cash register state info
	vRC = pFR.ChkShift();
	If vRC = -4 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.OpenSession'; de='CashRegister.OpenSession'; ru='ККМ.ОткрытьСессию'"), rMessage);
		Return False;
	EndIf;
	If vRC = -2 Тогда
 		// Check time difference between workstation and cash register and correct 
		// device time if difference is more then 5 minutes
		If Not CheckTimeDifference(pFR, rMessage) Then
			// Disconnect
			Disconnect(pFR);
			Return False;
		EndIf;
		vRC = pFR.OpenShift(Number(TrimAll(CashRegister.Code)), GetUserPassword());
		If vRC <> 0 Then
			ProcessResultCode(vRC, pFR, NStr("en='CashRegister.OpenSession'; de='CashRegister.OpenSession'; ru='ККМ.ОткрытьСессию'"), rMessage);
			Return False;
		EndIf;
	ElsIf vRC <> -3 Тогда
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.OpenSession'; de='CashRegister.OpenSession'; ru='ККМ.ОткрытьСессию'"), rMessage);
		Return False;
	EndIf;
	Return True;
EndFunction // OpenSession

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.GetExtendedErrorComment(pRC));
	tcCommonFunctionOnClientServer.UserMessage(rMessage);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.GetExtendedErrorComment(pRC));
	tcCommonFunctionOnClientServer.UserMessage(rMessage);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Try
		vRC = pFR.CancelDoc();
	Except
	EndTry;
	Disconnect(pFR);
EndProcedure // CancelCheque

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	rMessage = TrimAll(ErrorDescription());
	tcCommonFunctionOnClientServer.UserMessage(rMessage);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function SetDeviceTime(pFR, rMessage)
	// Set device date
	vRC = pFR.SetDate(Day(CurrentSessionDate()), Month(CurrentSessionDate()), Year(CurrentSessionDate()));
	If vRC <> 0 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	EndIf;
	
	// Set device time
	vRC = pFR.SetTime(Hour(CurrentSessionDate()), Minute(CurrentSessionDate()), Second(CurrentSessionDate()));
	If vRC <> 0 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pFR, rMessage)
	vFRDateTimeStr = pFR.GetTextDeviceInfo(4);
	If Not IsBlankString(vFRDateTimeStr) Then
		vFRDateStr = Left(vFRDateTimeStr, 8);
		vFRTimeStr = Right(vFRDateTimeStr, 8);
		vFRDate = Date(2000 + Number(Right(vFRDateStr, 2)), Number(Mid(vFRDateStr, 4, 2)), Number(Left(vFRDateStr, 2)), Number(Left(vFRTimeStr, 2)), Number(Mid(vFRTimeStr, 4, 2)), Number(Right(vFRTimeStr, 2)));
		If BegOfDay(CurrentSessionDate()) = BegOfDay(vFRDate) Then
			vTimeDiff = CurrentSessionDate() - vFRDate;
			If vTimeDiff < 0 Then 
				vTimeDiff = -vTimeDiff;
			EndIf;
			If vTimeDiff > 300 Then // > 5 minutes
				// Set current date and time
				vRC = pFR.SetDate(Day(CurrentSessionDate()), Month(CurrentSessionDate()), Year(CurrentSessionDate()));
				If vRC = 0 Then
					vRC = pFR.SetTime(Hour(CurrentSessionDate()), Minute(CurrentSessionDate()), Second(CurrentSessionDate()));
				EndIf;
				If vRC <> 0 Then
					ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				EndIf;
			EndIf;
		Else
			// Date is different, need to set correct date manually
			rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function GetDepartment(pObj, rDepartmentName) 
	vDepartment = 1;
	rDepartmentName = "";
	If Not CashRegister.DoNotPrintPaymentSections Then
		If ValueIsFilled(pObj.PaymentSection) Then
			vDepartment = pObj.PaymentSection.Code;
			If CashRegister.PrintPaymentSectionNamesInCheques Then
				rDepartmentName = TrimAll(pObj.PaymentSection.Description);
			EndIf;
		EndIf;
	EndIf;
	Return vDepartment;
EndFunction // GetDepartment

// -----------------------------------------------------------------------------
Function GetPaymentType(pObj) 
	vPaymentType = 8;
	If ValueIsFilled(pObj.PaymentMethod) Then
		If pObj.PaymentMethod.CashRegisterChequeCloseType > 0 Then
			vPaymentType = pObj.PaymentMethod.CashRegisterChequeCloseType;
		EndIf;
	EndIf;
	Return vPaymentType;
EndFunction // GetPaymentType

// -----------------------------------------------------------------------------
Procedure LogCashPayment(pFR, pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек'; en=' cheque was issued'; de=' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with amount ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек аннуляции'; en=' storno cheque was issued'; de=' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Function PrintSlipLines(pFR, pSlipTextArr, pInCheque = False)
	If Not pInCheque Then
		vRC = pFR.StartFreeDoc();
		If vRC <> 0 Then
			Return vRC;
		EndIf;
	EndIf;
	For Each vStr In pSlipTextArr Do
		vRC = pFR.PrintText(0, vStr);
	EndDo;
	If Not pInCheque Then
		vRC = pFR.EndFreeDoc();
		If vRC <> 0 Then
			Return vRC;
		EndIf;
	EndIf;
	Return 0;
EndFunction // PrintSlipLines

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj)
	// Header start delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.PrintText(0, vStr);
	// Folio #
	vStr = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr.'") + cmGetDocumentNumberPresentation(pObj.Folio.Number));
	vRC = pFR.PrintText(0, vStr);
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		vStr = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(pObj.Folio.Room));
		vRC = pFR.PrintText(0, vStr);
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) And ValueIsFilled(pObj.Payer) Then
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer));
		Else
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Folio.Client));
		EndIf;
		vRC = pFR.PrintText(0, vStr);
	EndIf;
	If TypeOf(pObj) = Type("Structure") Then
		// Guest group
		vStr = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.Folio.GuestGroup));
		vRC = pFR.PrintText(0, vStr);
	Else
		// Guest group
		vStr = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup));
		vRC = pFR.PrintText(0, vStr);
		// Document
		vStr = GetString(NStr("ru='Док.  № '; en='Doc.  # '; de='Doc.  # '") + cmGetDocumentNumberPresentation(pObj.Number));
		vRC = pFR.PrintText(0, vStr);
	EndIf;
	// Header end delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.PrintText(0, vStr);
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Function PrintHeader(pFR)
	vCompanyObj = CashRegister.Owner.GetObject();
	vCompanyLegacyName = vCompanyObj.pmGetCompanyPrintName(SessionParameters.CurrentLanguage);
	vRC = pFR.PrintText(0, GetString(vCompanyLegacyName));
	vCompanyLegacyAddress = vCompanyObj.pmGetCompanyLegacyAddressPresentation(SessionParameters.CurrentLanguage);
	vRC = pFR.PrintText(0, GetString(vCompanyLegacyAddress));
	vRC = pFR.PrintText(0, GetString("================================================================================"));
	Return 0;
EndFunction // PrintHeader
 
#EndRegion
