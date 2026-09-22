
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number - Sum
//  pVATSum			 - Number - Vat sum
//  pObj			 - DocumentObject - Document object 
//  rMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			// Check amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта операции!'; en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'");
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(vArrPaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType,"Code"))));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vPC.SParam("Amount", pSum * 100);
				// Do payment
				If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
					vRC = vPC.NFun(4010); // Close preauthorization
				Else
					vRC = vPC.NFun(4000); // Payment
				EndIf; 
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003);
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			Else
				vAnnulated = False;
				// Try to fill payment RRN
				vPC.SParam("RRN", "");
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
						vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
						If Not ValueIsFilled(vPayment) Then
							Break;
						EndIf;
					EndDo;
					If ValueIsFilled(vPayment) Then
						vPaymentReferenceNumber = tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber");
						If Not IsBlankString(vPaymentReferenceNumber) Then
							vPC.SParam("RRN", vPaymentReferenceNumber);
						EndIf;
					EndIf;
				EndIf;
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
				// Set amount
				vPC.SParam("Amount", -pSum * 100);
				// Do return
				vRC = vPC.NFun(4002);
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003); 
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			EndIf;
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				// Is not supported because of security concerns
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			Try
				pObj.TerminalNumber = vPC.GParamString("TermNum");
				pObj.MerchantID  = vPC.GParamString("MerchNum");
				// Fill card type
				vCardName = TrimAll(vPC.GParamString("CardName"));
				vCardType = TrimAll(vPC.GParamString("CardType"));
				vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vCardName, vCardType);
				If ValueIsFilled(vCardTypeRef) Then
					pObj.CardType = vCardTypeRef;
				EndIf;
			Except 
			EndTry;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			// Rollback operation
			If vCardOperationWasDone Then
				vRC = vPC.NFun(6004); 
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number - Sum
//  pObj			 - DocumentObject - Document object 
//  rMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			// Check amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
			EndIf;
			If pSum < 0 Then
				Raise NStr("ru = 'Сумма операции должна быть больше 0!'; en = 'Operation amount should be positive!'; de = 'Betriebsbetrag sollte positiv sein!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта операции!'; en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'");
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(vArrPaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType,"Code"))));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Do operation
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			// Set amount
			vPC.SParam("Amount", pSum * 100);
			// Do payment
			vRC = vPC.NFun(4009);
			If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Set unconfirmed mode
			vRC = vPC.NFun(6003);
			vCardOperationWasDone = True;
			// Get Reference number, Authorization code
			vReferenceNumber = vPC.GParamString("RRN");
			vAuthorizationCode = vPC.GParamString("AuthCode");
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				// Is not support in ThinClient 
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			// Rollback operation
			If vCardOperationWasDone Then
				vRC = vPC.NFun(6004); 
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number - Sum
//  pObj			 - DocumentObject - Document object 
//  rMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			// Check amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта операции!'; en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'");
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(vArrPaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType,"Code"))));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Set RNN
			vPC.SParam("RRN", pObj.ReferenceNumber);
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vPC.SParam("Amount", 0);  //set sum =0 for cancelled preauthorization
				vRC = vPC.NFun(4010); 
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003);
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,vMessage);
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			EndIf;
			// Change preauthorization status if there are no erros
			pObj.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
			pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" +  vReferenceNumber + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.AuthorOfCancellation = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			pObj.DateOfCancellation =  tcOnServer.cmGetServerCurrentSessionDate();
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  pValue					 - String	 - Password
//  pAdditionalParameters	 - Strucrure - Params
// 
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.Message;
	If Not pValue = Undefined Then
		vDriver.pmPrintSlip(pAdditionalParameters.SlipTextArr, pAdditionalParameters.CashRegister, vMessage, pValue.Password, pAdditionalParameters.OneCopyOnly);
		If vMessage <> "" Then
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
		EndIf; 
	EndIf;
EndProcedure // AfterInputCashRegisterPassword()

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage		 - String	 - Errors
//  pCashRegister	 - Structure - Params cash register
//  pPaymentTerminal - Structure - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister, pPaymentTerminal) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vCashRegisterArr = pCashRegister;
	Else 
		vCashRegisterArr =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;

	If TypeOf(pPaymentTerminal) = Type("Structure") Then  
		vPaymentTerminalArr = pPaymentTerminal;
	Else 
		vPaymentTerminalArr =  tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	EndIf;

	// Try to connect
	vPC = Connect(rMessage, vPaymentTerminalArr);
	If vPC = Undefined Then
		Return False;
	Else
		vUCList = New ValueList();
		vUCList.Add(6002, NStr("en='X-Report'; ru='X-Отчет'; de='X-Bericht'"));
		vUCList.Add(6000, NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
		vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverSberbankSBRF, New Structure("PC, CashRegisterArr, PaymentTerminalArr", vPC, vCashRegisterArr, vPaymentTerminalArr)));
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
//
// Parameters:
//  vUCItem		 - ValueList - Selected values
//  vExtraParams - Strucrure - Params 
//
Procedure AfterServiceFunctionsMenuSelection(vUCItem, vExtraParams) Export
	If vUCItem <> Undefined Then
		If vUCItem.Value = 6002 Then
			PrintXReport(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		ElsIf vUCItem.Value = 6000 Then
			ReconcileTotals(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		EndIf;
	EndIf;
EndProcedure // AfterServiceFunctionsMenuSelection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 - ComObject, Undefined - Driver
//  pCashRegister	 - Structure - Params Cash register 
//  pPaymentTerminal - Structure - Params payment terminal 
//  pResult			 - Boolean - Result operation
//
Procedure ReconcileTotals(pPC = Undefined, pCashRegister, pPaymentTerminal, pResult = True) Export
	rMessage = "";
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vCashRegisterArr = pCashRegister;
	Else 
		vCashRegisterArr =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;
	If TypeOf(pPaymentTerminal) = Type("Structure") Then  
		vPaymentTerminalArr = pPaymentTerminal;
	Else 
		vPaymentTerminalArr =  tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	EndIf;
	Try
		vPC = pPC;
		If vPC = Undefined Then
			vPC = Connect(rMessage, vPaymentTerminalArr);
		EndIf;
		If vPC = Undefined Then
			pResult = False;
			ShowMessageBox(,StrTemplate(NStr("en = 'Terminal connection error!
			|Error: %1'; de = 'Terminalverbindungsfehler!
			|Fehler: %1'; ru = 'Ошибка подключения к терминалу!
			|Error: %1'"), rMessage));
			Return;
		Else
			// Bank day settlement
			vRC = vPC.NFun(6000);
			If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				ShowMessageBox(,StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));

				pResult = False;
				Return;
			EndIf;
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
			// Print end of day slip
			If Not vPaymentTerminalArr.PrintSlipInCheque And 
				Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
				Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vCashRegisterArr, True);
			EndIf;
			// Success
			ShowMessageBox(, NStr("en='Totals reconcilation (Z-report) operation completed successfully!'; de='Totals reconcilation (Z-bericht) operation completed successfully!'; ru='Операция сверки итогов (Z-отчет) выполнена успешно!'"));
		EndIf;
	Except
		rMessage = ErrorDescription();
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
		// Disconnect
		Disconnect(vPC);
		pResult = False;
		ShowMessageBox(,StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));
	EndTry;
EndProcedure // ReconcileTotals

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 	- ComObject - Driver
//  pCashRegisterArr	- Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure PrintXReport(pPC, pCashRegisterArr, pPaymentTerminalArr) Export
	rMessage = "";
	Try
		// X report
		vRC = pPC.NFun(6002);
		If Not ProcessResultCode(pPC, vRC, NStr("en='CreditCardProcessingSystem.XReport'; de='CreditCardProcessingSystem.XReport'; ru='СистемаПроцессингаКредитныхКарт.XОтчет'"), rMessage) Then
			Return;
		EndIf;
		// Get slip
		vOutSlip = GetOperationSlipCheque(pPC);
		// Print end of day slip
		If Not pPaymentTerminalArr.PrintSlipInCheque And 
		   Not pPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
		   Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegisterArr, True);
		EndIf;
		// Success
		ShowMessageBox(,NStr("en='X-report operation completed successfully!'; de='X-bericht operation completed successfully!'; ru='Операция печати X-отчета выполнена успешно!'"));
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en='CreditCardProcessingSystem.XReport'; de='CreditCardProcessingSystem.XReport'; ru='СистемаПроцессингаКредитныхКарт.XОтчет'"), rMessage);
		// Disconnect
		Disconnect(pPC);
	EndTry;
EndProcedure // PrintXReport

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetErrorDescription(pPC,pRC)
	vMessage = "";
	Try
		vMessage = pPC.GParamString("LastError");
	Except
		vMessage = NStr("en='Error description is unknown! Error code is '; de='Fehlerbeschreibung ist nicht bekannt! Der Fehlercode ist '; ru='Описание ошибки не найдено! Код ошибки '");
	EndTry;
	If vMessage = "" Then
		If pRC = 4334 Then
			vMessage = NStr("en = 'The card is not read. Either wait loop card interrupted by pressing ESC, or just expired timeout'; ru = 'Карта не считана. Либо цикл ожидания карты прерван нажатием клавиши ESC, либо просто истек таймаут'; de = 'Die Karte wird nicht gelesen. Warten Sie entweder Schleifenkarte mit ESC abgebrochen, oder einfach abgelaufen Timeout'");
		ElsIf pRC = 4134 Then
			vMessage = NStr("en = 'For too long have not been performed on the results of verification of the terminal (more than 5 days have passed since the last)'; ru = 'Слишком долго не выполнялась сверка итогов на терминале (прошло более 5 дней с момента последней операции)'; de = 'Viel zu lange habe nicht über die Ergebnisse der Überprüfung der Klemme durchgeführt wurde (mehr als 5 Tage seit dem letzten übergeben)'");
		EndIf;	
	EndIf;	
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function Connect(rMessage,pArrPaymentTerminal)
	// Reset return status
	rMessage = "";
	// Try to create external component
	#IF NOT MobileClient THEN
		Try
			vPC = New COMObject("SBRFSRV.Server");
			// Get connection parameters
			ConnectionParameters = ParseConnectionParameters(pArrPaymentTerminal.ConnectionParameters);
			If ConnectionParameters <> Undefined Then
				SetConnectionParameters(vPC,ConnectionParameters);
			EndIf;
			// Clear parameters
			vPC.Clear();
			// OK
			Return vPC;
		Except
			rMessage = ErrorDescription();
			Return Undefined;
		EndTry;
	#ELSE
		Return Undefined;
	#ENDIF
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	Try
		pPC.Clear();
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		// Nothing to configure
	EndIf;
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC,pConnectionParameters)
	If pConnectionParameters <> Undefined Then
		// Nothing to configure
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function ProcessResultCode(pFR, pRC, pFunction, rMessage)
	If pRC <> 0 Then
		rMessage = "Result code: " + pRC + ", " + NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pFR,pRC);
		Disconnect(pFR);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Function GetTextLinesArray(pTextStr) 
	vTxtArr = New Array;
	If Not IsBlankString(pTextStr) Then
		vTxt = New TextDocument();
		vTxt.SetText(pTextStr);
		For i = 1 To vTxt.LineCount() Do
			vStr = vTxt.GetLine(i);
			vTxtArr.Add(vStr);
		EndDo;
	EndIf;
	Return vTxtArr;
EndFunction // cmGetTextLinesArray

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Error",,, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function GetOperationSlipCheque(pPC)
	vSlipCheque = pPC.GParamString("Cheque");
	vTildaSPos = Find(vSlipCheque, "~S");
	If vTildaSPos >= (Int(StrLen(vSlipCheque)/2) - 9) Then
		vSlipCheque = Left(vSlipCheque, vTildaSPos - 1);
	Else
		vChar1Pos = Find(vSlipCheque, Char(1));
		If vChar1Pos >= (Int(StrLen(vSlipCheque)/2) - 9) Then
			vSlipCheque = Left(vSlipCheque, vChar1Pos - 1);
		EndIf;
	EndIf;
	Return vSlipCheque;
EndFunction // GetOperationSlipCheque

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pCashRegister, pOneCopyOnly = False)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,pCashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
		                  |de='Input cash register password please...';
		                  |en='Input cash register password please...'");
		If IsBlankString(vPasswordKKM) Then
			pCancel = True;
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverSberbankSBRF, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
			// Ask for password
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion),,,,,vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		ShowMessageBox(,Nstr("en = 'Printing is not supported for this cash register!'; ru = 'Печать на ленте не поддерживается для вашей ККМ!'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;	
EndProcedure // PrintSlipDocument

#EndRegion

