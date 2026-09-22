
#Region Public

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
			vRC = vFR.GetDeviceInfo(10);
			If vRC = 1 Then
				rMessage = NStr("ru='Закончилась бумага!'; en='Out of paper!'; de='Out of paper!'");
				Disconnect(vFR);
				Return True;
			EndIf;
			// Check session 24 hours limit
			vRC = vFR.GetDeviceInfo(14);
			If vRC = 1 Then
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
			// Do cash income
			vRC = vFR.StartDocument(4, 1, 0, GetUserName());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			vRC = vFR.Tender(pSum*100, 8, "", "");
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
				Return False;
			EndIf;
			vRC = vFR.GetDeviceOpt(2);
			If vRC = 1 Then
				vRC = vFR.EndDocument();
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
					Return False;
				EndIf;
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
			// Do cash outcome
			vRC = vFR.StartDocument(5, 1, 0, GetUserName());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			vRC = vFR.Tender(pSum*100, 8, "", "");
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
				Return False;
			EndIf;
			vRC = vFR.GetDeviceOpt(2);
			If vRC = 1 Then
				vRC = vFR.EndDocument();
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
					Return False;
				EndIf;
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
			vRC = vFR.PrintReport(1);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do report
			vRC = vFR.PrintReport(2);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintDeviceHourXReport'; de='CashRegister.PrintDeviceHourXReport'; ru='ККМ.ПечатьПочасовогоХОтчетаПоФР'"), rMessage);
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
			If Not CloseOpenCheque(vFR, rMessage) Then
				Return False;
			EndIf;
			// Do report
			vRC = vFR.PrintReport(3);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
				Return False;
			EndIf;	
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			Try
				vFR.OpenDrawer();
			Except
			EndTry;
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
			vRC = vFR.GetDeviceInfo(4);
			If vRC = -1 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				Return False;
			EndIf;
			If vRC = 0 Тогда
				rMessage = NStr("ru = 'Смена уже закрыта!'; en = 'Session is already closed!'; de = 'Session is already closed!'");
				// Disconnect
				Disconnect(vFR);
				Return False;
			Else
				vRC = vFR.EndSession();
				If vRC <> 0 And vRC <> -4 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), rMessage);
				EndIf;
				// Log cash register operation
				WriteLogEvent(NStr("en='CashRegister.CloseSession'; de='CashRegister.CloseSession'; ru='ККМ.ЗакрытьСессию'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
				// Open drawer
				Try
					vFR.OpenDrawer();
				Except
				EndTry;
			EndIf;
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
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage) Export
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
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			// Open cheque
			If pSum >= 0 Then
				vRC = vFR.StartDocument(1, vDepartment, 0, GetUserName());
			Else
				vRC = vFR.StartDocument(6, vDepartment, 0, GetUserName());
			EndIf;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			// Print payment number
			If pSum >= 0 Then
				vPrintStr = "#" + TrimAll(pObj.Number);
				If Not IsBlankString(rDepartmentName) Then
					vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
				EndIf;
				vRC = vFR.ItemEx(1000, pSum*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum >= 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), pObj.VATRate.NoVAT, False);
					If vNoVAT Then
						vPrintStr = GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"));
					Else
						vPrintStr = GetString(NStr("ru='В т.ч. НДС ';en='Incl. VAT ';en='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="));
					EndIf;
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"));
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			// Add payment
			If pSum >= 0 Then
				vRC = vFR.Tender(pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
			Else
				vRC = vFR.Tender(-pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
			EndIf;
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
				Return False;
			EndIf;
			// Close cheque
			vRC = vFR.GetDeviceOpt(2);
			If vRC = 1 Then
				vRC = vFR.EndDocument();
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj);
			// Clear extra strings
			Try
				vFR.ClearExtraStrings();
			Except
			EndTry;
			// Open drawer
			Try
				vFR.OpenDrawer();
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
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined) Export
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
			// Get document cash department number and description
			vDepartment = GetDepartment(pObj, rDepartmentName);
			// Open cheque
			If pSum >= 0 Then
				vRC = vFR.StartDocument(1, vDepartment, 0, GetUserName());
			Else
				vRC = vFR.StartDocument(6, vDepartment, 0, GetUserName());
			EndIf;
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Print payment number
			If pSum >= 0 Then
				If NOT CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						vDepartment = 1;
						vPrintStr = "";
						If ValueIsFilled(vSrvRow.Service) Then
							vDepartment = GetDepartment(vSrvRow.Service, rDepartmentName);
							vPrintStr = GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
						EndIf;
						vRC = vFR.ItemEx(1000, vSrvRow.Amount*100, vPrintStr, GetTaxGroup(vSrvRow), vDepartment);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
					EndDo;
				Else
					If pObj.PaymentSections.Count() > 0 Then
						If Not CashRegister.PrintFolioHeader Then
							vPrintStr = "#" + TrimAll(pObj.Number);
							vRC = vFR.Item(1000, 0, vPrintStr, 0);
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
						If Not CashRegister.DoNotPrintPaymentSections Then
							For Each vPSRow In pObj.PaymentSections Do
								If vPSRow.Sum = 0 Then
									Continue;
								EndIf;
								
								// Get document cash department number and description
								vDepartment = GetDepartment(vPSRow, rDepartmentName);
								vPrintStr = GetString(rDepartmentName);
								vRC = vFR.ItemEx(1000, vPSRow.Sum*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
								If vRC <> 0 Then
									CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
									Return False;
								EndIf;
							EndDo;
						Else
							vAmount = 0;
							For Each vPSRow In pObj.PaymentSections Do
								If vPSRow.Sum = 0 Then
									Continue;
								EndIf;
								vAmount = vAmount + vPSRow.Sum;
							EndDo;
							
							// Get document cash department number and description
							vDepartment = GetDepartment(vPSRow, rDepartmentName);
							vPrintStr = NStr("en='Services';ru='Услуги';de='Dienstleistungen'");
							vRC = vFR.ItemEx(1000, vAmount *100, vPrintStr, GetTaxGroup(pObj), vDepartment);
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
								Return False;
							EndIf;
						EndIf;
					Else
						vPrintStr = NStr("en='Services';ru='Услуги';de='Dienstleistungen'");
						If Not CashRegister.PrintFolioHeader Then
							vPrintStr = "#" + TrimAll(pObj.Number);
						EndIf;
						If Not IsBlankString(rDepartmentName) Then
							If Not CashRegister.PrintFolioHeader Then
								vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
							Else
								vPrintStr = GetString(rDepartmentName);
							EndIf;
						EndIf;
						vRC = vFR.ItemEx(1000, pSum*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
							Return False;
						EndIf;
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
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru='НДС включён в сумму';en='Amount includes VAT';de='Betrag inkl. MwSt.'"));
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
			EndIf;
			// Add payment
			If pSum >= 0 Then
				vRC = vFR.Tender(pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
			Else
				vRC = vFR.Tender(-pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
			EndIf;
			If vRC <> 0 Then
				CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
				Return False;
			EndIf;
			// Close cheque
			vRC = vFR.GetDeviceOpt(2);
			If vRC = 1 Then
				vRC = vFR.EndDocument();
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
					Return False;
				EndIf;
			EndIf;
			// Log cash register operation
			LogCashPayment(vFR, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj);
			// Clear extra strings
			Try
				vFR.ClearExtraStrings();
			Except
			EndTry;
			// Open drawer
			Try
				vFR.OpenDrawer();
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
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	// Try to connect
	vFR = Connect(rMessage);
	If vFR = Undefined Then
		Return False;
	Else // Cash register was connected
		// Check session 24 hours limit
		vRC = vFR.GetDeviceInfo(14);
		If vRC = 1 Then
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Disconnect(vFR);
				Return False;
			EndIf;
		EndIf;
		// Check paper
		vRC = vFR.GetDeviceInfo(10);
		If vRC = 1 Then
			rMessage = NStr("ru='В ККМ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check printer
		vRC = vFR.GetDeviceInfo(9);
		If vRC = 1 Then
			rMessage = NStr("ru='Ошибка принтера чеков!'; en='Cheque printer error!'; de='Cheque printer error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		// Check memory
		vRC = vFR.GetDeviceInfo(11);
		If vRC = 1 Then
			rMessage = NStr("ru='Фискальная память заполнена!'; en='Fiscal memory is full!'; de='Fiscal memory is full!'");
			Disconnect(vFR);
			Return False;
		EndIf;
		vRC = vFR.GetDeviceInfo(12);
		If vRC = 1 Then
			rMessage = NStr("ru='Ошибка фискальной памяти!'; en='Fiscal memory error!'; de='Fiscal memory error!'");
			Disconnect(vFR);
			Return False;
		EndIf;
	EndIf;
	// Disconnect
	Disconnect(vFR);
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage) Export
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
				// Get document cash department number and description
				vDepartment = GetDepartment(pObj, rDepartmentName);
				// Open cheque
				vRC = vFR.StartDocument(2, vDepartment, 0, GetUserName());
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				// Print sections
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						vPrintStr = "#" + TrimAll(pObj.Number);
						vRC = vFR.Item(1000, 0, vPrintStr, 0);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
					If Not CashRegister.DoNotPrintPaymentSections Then
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							
							// Get document cash department number and description
							vDepartment = GetDepartment(vPSRow, rDepartmentName);
							vPrintStr = GetString(rDepartmentName);
							vRC = vFR.ItemEx(1000, vPSRow.Sum*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
							If vRC <> 0 Then
								CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
								Return False;
							EndIf;
						EndDo;
					Else
						vAmount = 0;
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							Else
								vAmount = vAmount + vPSRow.Sum;
							EndIf;
						EndDo;
						
						// Get document cash department number and description
						vDepartment = GetDepartment(vPSRow, rDepartmentName);
						vPrintStr = "#" + TrimAll(pObj.Number);
						vRC = vFR.ItemEx(1000, vAmount*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
						If vRC <> 0 Then
							CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
							Return False;
						EndIf;
					EndIf;
				Else
					// Print payment number
					vPrintStr = "#" + TrimAll(pObj.Number);
					If Not IsBlankString(rDepartmentName) Then
						vPrintStr = GetString(TrimR(vPrintStr) + " - " + rDepartmentName);
					EndIf;
					vRC = vFR.ItemEx(1000, pSum*100, vPrintStr, GetTaxGroup(pObj), vDepartment);
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
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					vPrintStr = GetString(NStr("ru='НДС включён в сумму';en='Amount includes VAT';de='Betrag inkl. MwSt.'"));
					vRC = vFR.Item(1000, 0, vPrintStr, 0);
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				// Add payment
				If pSum >= 0 Then
					vRC = vFR.Tender(pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
				Else
					vRC = vFR.Tender(-pSum*100, GetPaymentType(pObj), TrimAll(pObj.ReferenceNumber), TrimAll(pObj.AuthorizationCode));
				EndIf;
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
					Return False;
				EndIf;
				// Close cheque
				vRC = vFR.GetDeviceOpt(2);
				If vRC = 1 Then
					vRC = vFR.EndDocument();
					If vRC <> 0 Then
						CancelCheque(vRC, vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
						Return False;
					EndIf;
				EndIf;
				// Log cash register operation
				LogCashPaymentAnnulation(vFR, NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj);
				// Clear extra strings
				Try
					vFR.ClearExtraStrings();
				Except
				EndTry;
				// Open drawer
				Try
					vFR.OpenDrawer();
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
				// Open text document
				vRC = vFR.StartDocument(3, 1, 0, GetUserName());
				If vRC <> 0 Then
					ProcessResultCode(vRC, vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
					Return False;
				EndIf;
				// Print all strings in the array
				vRC = PrintSlipLines(vFR, pSlipTextArr, False);
				If vRC <> 0 Then
					CancelCheque(vRC, vFR, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"), rMessage);
					Return False;
				EndIf;
				// Close text document
				vRC = vFR.EndDocument();
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

#EndRegion

#Region Private

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
Function GetUserName()
	Return ?(ValueIsFilled(SessionParameters.CurrentUser), TrimAll(SessionParameters.CurrentUser.Description), "");
EndFunction // GetUserName

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
		#IF CLIENT THEN
			Try
				AttachAddIn("KKS.Spark617TF");
				vFR = New("AddIn.SparkTF");
			Except
				LoadAddIn("SparkAx3.dll");
				vFR = New("AddIn.SparkTF");
			EndTry;
		#ELSE
			vFR = New("AddIn.SparkTF");
		#ENDIF
		// Apply connection parameters
		// Access password
		If Not IsBlankString(CashRegister.AccessPassword) Then
			vRC = vFR.SetAccessKey(TrimR(CashRegister.AccessPassword));
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
				Return Undefined;
			EndIf;
		EndIf;
		// COM port
		vPortNumber = GetPortNumber();
		If vPortNumber > 0 Then
			vRC = vFR.SetDeviceOpt(1, vPortNumber);
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
				Return Undefined;
			EndIf;
		EndIf;
		// Use cashing
		vRC = vFR.SetDeviceOpt(2, 1);
		If vRC <> 0 Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
			Return Undefined;
		EndIf;
		// Do not print taxes and number of items
		vFR.SetDeviceOpt(3, 0);
		vFR.SetDeviceOpt(4, 0);
		vFR.SetDeviceOpt(5, 0);
		vFR.SetDeviceOpt(6, 0);
		vFR.SetDeviceOpt(7, 0);
		vFR.SetDeviceOpt(8, 0);
		// Write log file
		If CashRegister.WriteLogFile Then
			vRC = vFR.SetDriverOpt(1, 1);
		Else
			vRC = vFR.SetDriverOpt(1, 0);
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
		// Set current user
		vRC = vFR.GetDeviceInfo(4);
		If vRC <> 0 Then
			vRC = vFR.SetClerk(GetUserName());
			If vRC <> 0 Then
				ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
				Return Undefined;
			EndIf;
		EndIf;
		// Switch off printing of customer ID
		vRC = vFR.SetDescriptorText(80, NStr("ru = 'Платежный'; en = 'Payment'; de = 'Payment'"));
		If vRC <> 0 Then
			ProcessResultCode(vRC, vFR, NStr("en='CashRegister.Connect'; de='CashRegister.Connect'; ru='ККМ.Подключение'"), rMessage);
			Return Undefined;
		EndIf;
		vRC = vFR.SetExtraDocData(0, 0, 0, NStr("ru = 'документ'; en = 'document'; de = 'document'"));
		If vRC <> 0 Then
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
	vRC = pFR.GetDeviceInfo(102);
	If vRC = -1 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"), rMessage);
		Return False;
	EndIf;
	If vRC <> 0 Тогда
		vRC = pFR.CancelDocument();		
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
	vRC = pFR.GetDeviceInfo(4);
	If vRC = -1 Then
		ProcessResultCode(vRC, pFR, NStr("en='CashRegister.OpenSession'; de='CashRegister.OpenSession'; ru='ККМ.ОткрытьСессию'"), rMessage);
		Return False;
	EndIf;
	If vRC = 0 Тогда
 		// Check time difference between workstation and cash register and correct 
		// device time if difference is more then 5 minutes
		If Not CheckTimeDifference(pFR, rMessage) Then
			// Disconnect
			Disconnect(pFR);
			Return False;
		EndIf;
		vRC = pFR.StartSession(GetUserName(), Number(CashRegister.Code));
		If vRC <> 0 Then
			ProcessResultCode(vRC, pFR, NStr("en='CashRegister.OpenSession'; de='CashRegister.OpenSession'; ru='ККМ.ОткрытьСессию'"), rMessage);
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // OpenSession

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.GetErrorComment(pRC));
	If pRC = 33 Then
		rMessage = NStr("en='Cash register session is closed! Open it by cash income operation for example!'; de='Cash register session is closed! Open it by cash income operation for example!'; ru='Смена не открыта. Выполните внесение денежных средств!'");
	EndIf;
	tcCommonFunctionOnClientServer.UserMessage(rMessage);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure CancelCheque(pRC, pFR, pFunction, rMessage)
	rMessage = TrimAll(pFR.GetErrorComment(pRC));
	tcCommonFunctionOnClientServer.UserMessage(rMessage);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pRC + ", result description: " + rMessage);
	Try
		vRC = pFR.CancelDocument();		
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
	vFRDateNum = pFR.GetDeviceInfo(31);
	If vFRDateNum > 0 Then
		vFRDateStr = Format(vFRDateNum, "ND=6; NFD=0; NZ=; NLZ=; NG=");
		vFRTimeNum = pFR.GetDeviceInfo(30);
		If vFRTimeNum > 0 Then
			vFRTimeStr = Format(vFRTimeNum, "ND=6; NFD=0; NZ=; NLZ=; NG=");
			vFRDate = Date(2000 + Number(Right(vFRDateStr, 2)), Number(Mid(vFRDateStr, 3, 2)), Number(Left(vFRDateStr, 2)), Number(Left(vFRTimeStr, 2)), Number(Mid(vFRTimeStr, 3, 2)), Number(Right(vFRTimeStr, 2)));
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
Procedure LogCashPayment(pFR, pFunction, pObj)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек'; en=' cheque was issued'; de=' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFR, pFunction, pObj)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with amount ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек аннуляции'; en=' storno cheque was issued'; de=' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Function PrintSlipLines(pFR, pSlipTextArr, pInCheque = False)
	For Each vStr In pSlipTextArr Do
		If pInCheque Then
			vRC = pFR.AddExtraString(vStr);
		Else
			vRC = pFR.TextLine(vStr);
		EndIf;
		If vRC <> 0 Then
			Return vRC;
		EndIf;
	EndDo;
	Return 0;
EndFunction // PrintSlipLines

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(pFR, pObj)
	// Header start delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.AddExtraString(vStr);
	// Folio #
	vStr = GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr.'") + cmGetDocumentNumberPresentation(pObj.Folio.Number));
	vRC = pFR.AddExtraString(vStr);
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		vStr = GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(pObj.Folio.Room));
		vRC = pFR.AddExtraString(vStr);
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.Return")) And ValueIsFilled(pObj.Payer) Then
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Payer));
		Else
			vStr = GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(pObj.Folio.Client));
		EndIf;
		vRC = pFR.AddExtraString(vStr);
	EndIf;
	// Guest group
	vStr = GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(pObj.GuestGroup));
	vRC = pFR.AddExtraString(vStr);
	// Document
	vStr = GetString(NStr("ru='Док.  № '; en='Doc.  # '; de='Doc.  # '") + cmGetDocumentNumberPresentation(pObj.Number));
	vRC = pFR.AddExtraString(vStr);
	// Cashier
	vStr = GetString(NStr("ru='Кассир: '; en='Cashier '; de='Kassierer '") + TrimAll(SessionParameters.CurrentUser.Description));
	vRC = pFR.AddExtraString(vStr);
	// Header end delimeter
	vStr = GetString("-----------------------------------------------------------------------");
	vRC = pFR.AddExtraString(vStr);
EndProcedure // PrintFolioHeader

#EndRegion
