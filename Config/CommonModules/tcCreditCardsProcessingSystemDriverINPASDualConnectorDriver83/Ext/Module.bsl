
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pVATSum			 - Number	 - Vat sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vDeviceID = "";
	vPC = Connect(rMessage, pPaymentTerminal, vDeviceID);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма авторизации!'; en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Voice authorisation
			vCardNumber = "";
			vCardNumberRight4Digits = "";
			vCardDataEnc = "";
			vCardDataBin = "";
			vCardExpiryDate = "";
			vArrCreditCard = tcOnServer.cmGetAtributeAsArray(pObj.CreditCard);
			If ValueIsFilled(pObj.CreditCard) And Not IsBlankString(vArrCreditCard.CardNumber) Then 
				vCardNumber = TrimAll(vArrCreditCard.CardNumber);
				vCardNumberRight4Digits = Right(vCardNumber, 4);
				If Not IsBlankString(vArrCreditCard.CardDataEnc) Then
					vCardDataEnc = TrimAll(vArrCreditCard.CardDataEnc);
					vCardDataBin = TrimAll(vArrCreditCard.CardSecurityCode);
				EndIf;
			EndIf;
			// Fill operation currency code
			If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "AuthorizationCode"));
				vReferenceNumber = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"));
				vChequeNumber = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "TransactionID"));
				// Call processing
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				vOutSlip = "";
				If Not IsBlankString(vCardDataEnc) Then
					vCardNumber = vCardDataEnc;
					vRC = vPC.ЗавершитьПреавторизациюПоПлатежнойКарте(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				Else
					vRC = vPC.ЗавершитьПреавторизациюПоПлатежнойКарте(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				EndIf;
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), rMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , vMessage);
			Else
				If pSum > 0 Then
					// Call processing
					tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
					vOutSlip = "";
					vChequeNumber = "";
					vRC = vPC.ОплатитьПлатежнойКартой(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
						Return False;
					EndIf;
					// Log authorisation code and RRN
					vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
					tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , vMessage);
				Else      
					vAnnulated = False;
					// Call processing
					vPayment = Undefined;
					If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
						vPayment = pObj.Payment;
						If ValueIsFilled(vPayment) Then
							While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
								vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
								If Not ValueIsFilled(vPayment) Then
									Break;
								EndIf;
							EndDo;
						EndIf;
					ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
						vPayment = pObj.CustomerPayment;
					EndIf;
					If ValueIsFilled(vPayment) Then
						vReferenceNumber = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber"));
					Else
						Raise NStr("en='Return should be based on previous payment!'; de='Return should be based on previous payment!'; ru='Возврат должен быть на основании предыдущего платежа!'");
					EndIf;
					tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
					vChequeNumber = "";
					vOutSlip = "";
					vRC = vPC.ОтменитьПлатежПоПлатежнойКарте(vDeviceID, vCardNumber, -pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
					If ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"), rMessage) Then
						vAnnulated = True;
					EndIf;
					// If not annulated then return
					If Not vAnnulated Then
						vChequeNumber = "";
						vOutSlip = "";
						vRC = vPC.ВернутьПлатежПоПлатежнойКарте(vDeviceID, vCardNumber, -pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
						If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
							Return False;
						EndIf;
					EndIf;
					// Log authorisation code and RRN
					vMessage = NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'") + vAuthorizationCode + "/" + vReferenceNumber;
					tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , vMessage);
				EndIf;
			EndIf;
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				// Is not supported in ThinClient 
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
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vDeviceID = "";
	vPC = Connect(rMessage, pPaymentTerminal, vDeviceID);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
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
			
			vArrCreditCard = tcOnServer.cmGetAttributeByRef(pObj.CreditCard);
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) And Not IsBlankString(vArrCreditCard.CardNumber) Then 
				vCardNumber = TrimAll(vArrCreditCard.CardNumber);
			EndIf;
			
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			
			// Call processing
			vChequeNumber = "";
			vRC = vPC.ПреавторизацияПоПлатежнойКарте(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
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
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vDeviceID = "";
	vPC = Connect(rMessage, pPaymentTerminal, vDeviceID);
	If vPC = Undefined Then
		Return False;
	Else
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
			vArrCreditCard = tcOnServer.cmGetAttributeByRef(pObj.CreditCard);
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) And Not IsBlankString(vArrCreditCard.CardNumber) Then 
				vCardNumber = TrimAll(vArrCreditCard.CardNumber);
			EndIf;
			// Call processing
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + pSum);
			vChequeNumber = "";
			vOutSlip = "";
			vRC = vPC.ОтменитьПреавторизациюПоПлатежнойКарте(vDeviceID, vCardNumber, pObj.Sum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), , , , vMessage);
			// Save main authorization attributes to the payment document
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vReferenceNumber;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
			pObj.AuthorOfCancellation = tcOnServer.cmGetCurrentUserAttribute();
			pObj.DateOfCancellation = CurrentDate();
			
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
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
//  rMessage		 - String	 - Errors
//  pCashRegister	 - Structure - Params cash register
//  pPaymentTerminal - Structure - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister, pPaymentTerminal) Export
	vUCList = New ValueList;
	vUCList.Add(2, NStr("en = 'X-Report (Short)'; de = 'X-Bericht (kurz)'; ru = 'X-Отчет (Краткий)'"));
	vUCList.Add(1, NStr("en='X-Report'; ru='X-Отчет'; de='X-Bericht'"));
	vUCList.Add(0, NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
	vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverINPASDualConnectorDriver83, New Structure("CashRegister, PaymentTerminal", pCashRegister, pPaymentTerminal)));
	Return True;
EndFunction // OpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
//
// Parameters:
//  vUCItem		 - ValueList - Selected values
//  vExtraParams - Strucrure - Params 
//
Procedure AfterServiceFunctionsMenuSelection(pUCItem, pExtraParams) Export
	If pUCItem = Undefined Then
		Return;
	EndIf;
	
	vCashRegister = pExtraParams.CashRegister;
	vPaymentTerminal = pExtraParams.PaymentTerminal;
	
	If pUCItem.Value = 2 Then
		PrintXReport(vCashRegister, vPaymentTerminal);
	ElsIf pUCItem.Value = 1 Then
		PrintXReport(vCashRegister, vPaymentTerminal, True);
	ElsIf pUCItem.Value = 0 Then
		ReconcileTotals(Undefined, vCashRegister, vPaymentTerminal);
	EndIf;
EndProcedure // AfterServiceFunctionsMenuSelection

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pPaymentTerminal - Structure - Params payment terminal 
//
Procedure pmCheckConnection(pPaymentTerminal) Export
	rMessage = "";
	// Try to connect
	Try
		// Read connection parameters
		vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pPaymentTerminal);
		If vConnParameters = Undefined Or IsBlankString(vConnParameters) Then
			vConnParameters = GetDefaultConnectionParameters();
		EndIf;
		// Show connection parameters
		OpenForm("CommonForm.tcInputText", New Structure("Text", vConnParameters), , , , , New NotifyDescription("AfterShowInputText", tcCreditCardsProcessingSystemDriverINPASDualConnectorDriver83, pPaymentTerminal.Ref));
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(rMessage);
	EndTry;
EndProcedure // pmCheckConnection

// -----------------------------------------------------------------------------   
//
// Parameters:
//  pPC			 	 - ComObject, Undefined - Driver
//  pCashRegister	 - Structure - Params Cash register 
//  pPaymentTerminal - Structure - Params payment terminal 
//  pResult			 - Boolean - Result operation
//
Procedure ReconcileTotals(pPC = Undefined, pCashRegister, pPaymentTerminal, pResult = True) Export
	vMessage = "";
	// Pay card system object was created successfully
	Try
		vDeviceID = "";
		vPC = Connect(vMessage, pPaymentTerminal, vDeviceID);
		If vPC = Undefined Then
			pResult = False;
			ShowMessageBox(,StrTemplate(NStr("en = 'Terminal connection error!
			|Error: %1'; de = 'Terminalverbindungsfehler!
			|Fehler: %1'; ru = 'Ошибка подключения к терминалу!
			|Error: %1'"), vMessage));
			Return;
		EndIf;
		
		// Bank day settlement
		vOutSlip = "";
		vRC = vPC.ИтогиДняПоКартам(vDeviceID, vOutSlip);
		If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), vMessage) Then
			pResult = False;
			ShowMessageBox(, StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
			|Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
			|Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
			|Error: %1'"), vMessage));
			Return;
		EndIf;
		
		// Print end of day slip
		If Not pPaymentTerminal.PrintSlipInCheque And 
			Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegister, True);
		EndIf;
		
		// Success
		ShowMessageBox(, NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'")); 
	Except
		pResult = False;
		vErrorInfo = ErrorInfo();
		vErrorDescription = ErrorProcessing.DetailErrorDescription(vErrorInfo);
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), vErrorDescription);
		vMessage = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		ShowMessageBox(, StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
		|Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
		|Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
		|Error: %1'"), vMessage));
	EndTry;
EndProcedure // ReconcileTotals

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 	- ComObject - Driver
//  pCashRegisterArr	- Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure PrintXReport(pCashRegister, pPaymentTerminal, pFull = False) Export 
	vMessage = "";
	// Pay card system object was created successfully
	Try
		vDeviceID = "";
		vPC = Connect(vMessage, pPaymentTerminal, vDeviceID);
		If vPC = Undefined Then
			pResult = False;
			ShowMessageBox(,StrTemplate(NStr("en = 'Terminal connection error!
			|Error: %1'; de = 'Terminalverbindungsfehler!
			|Fehler: %1'; ru = 'Ошибка подключения к терминалу!
			|Error: %1'"), vMessage));
			Return;
		EndIf;
		
		// Bank day settlement
		vOutSlip = "";
		vRC = vPC.ПолучитьОтчет(pFull, vOutSlip);
		If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.XReport'; de='CreditCardProcessingSystem.XReport'; ru='СистемаПроцессингаКредитныхКарт.XОтчет'"), vMessage) Then
			ShowMessageBox(, StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
							|Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
							|Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
							|Error: %1'"), vMessage));
			Return;
		EndIf;
		
		// Print end of day slip
		If Not pPaymentTerminal.PrintSlipInCheque And 
			Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegister, True);
		EndIf;
		
		// Success
		ShowMessageBox(, NStr("en='X-report operation completed successfully!'; de='X-bericht operation completed successfully!'; ru='Операция печати X-отчета выполнена успешно!'"));
	Except
		vErrorInfo = ErrorInfo();
		vErrorDescription = ErrorProcessing.DetailErrorDescription(vErrorInfo);
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.XReport'; de='CreditCardProcessingSystem.XReport'; ru='СистемаПроцессингаКредитныхКарт.XОтчет'"), vErrorDescription);
		vMessage = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		ShowMessageBox(, StrTemplate(NStr("en = 'Error printing report!
						|Error: %1'; de = 'Druckfehler melden!
						|Fehler: %1'; ru = 'Ошибка выполнения печати отчета!
						|Error: %1'"), vMessage));
	EndTry;
EndProcedure // PrintXReport

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Connect(rMessage, pArrPaymentTerminal, rDeviceID = "")
	// Reset return status
	rMessage = "";
	rDeviceID = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("INPAS");
		rDeviceID = GetPersistentObject("INPAS_DeviceID");
		
		If vPC = Undefined Then 
			// ACC:561-off
			Try
				AttachAddIn("Addin.a_inpasDC1c83");
				vPC = New("Addin.a_inpasDC1c83");
			Except
				LoadAddIn("a_inpasDC1c83.dll");
				vPC = New("Addin.a_inpasDC1c83");
			EndTry;
			// ACC:561-on
			// Get connection parameters
			ConnectionParameters = ParseConnectionParameters(tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pArrPaymentTerminal.Ref));
			If ConnectionParameters <> Undefined Then
				rTerminalID = GetTerminalId(pArrPaymentTerminal);
				ConnectionParameters.Insert("TerminalID", rTerminalID);
				
				SetConnectionParameters(vPC,ConnectionParameters);
			Else
				Raise NStr("en = 'INPAS parameters XML should be filled!'; de = 'INPAS parameters XML should be filled!'; ru = 'Не заполнен XML файл с параметрами подключения к системе ИНПАС!'");
			EndIf;
			// Connect to device and get device id
			vRC = vPC.Подключить(rDeviceID);
			If Not vRC Then
				rMessage = GetErrorDescription(vPC);
				Disconnect(vPC);
				Return Undefined;
			EndIf;
			
			SetPersistentObject("INPAS", vPC);
			SetPersistentObject("INPAS_DeviceID", rDeviceID);
		EndIf;
		
		// OK
		Return vPC;
		
	Except
		vErrorInfo = ErrorInfo();
		rMessage = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.Connect'; de='CreditCardProcessingSystem.Connect'; ru='СистемаПроцессингаКредитныхКарт.Подключить'"), "Error", , , "Error description: " + ErrorProcessing.DetailErrorDescription(vErrorInfo));
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	vDeviceID = GetPersistentObject("INPAS_DeviceID");
	Try
		If pPC <> Undefined Then
			pPC.Отключить(vDeviceID);
		EndIf;
		pPC = Undefined;
		SetPersistentObject("INPAS", Undefined);
		SetPersistentObject("INPAS_DeviceID", "");
	Except
	EndTry;
EndProcedure // Disconnect

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
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("SlipChequeCompanyRu, SlipChequeCompanyEn, " 
										+ "SlipChequeBankRu, SlipChequeBankEn, " 
										+ "SlipChequeCityRu, SlipChequeCityEn, " 
										+ "SlipChequeAddressRu, SlipChequeAddressEn, " 
										+ "SlipChequeFooterTextRu, SlipChequeFooterTextEn, " 
										+ "AuthServerIP, AuthServerPort, X25Script, TimeoutACK, AuthTimeoutPacket, CountNAK, PacketSize, TransactionTimeout, " 
										+ "CtrlServerIP, CtrlServerPort, CtrlTimeoutPacket, COMPort, BaudRate, ByteSize, Parity, StopBits, FlowCtrl,CurrencyCode",
										"", "", "", "", "", "", "", "", "", "", 
										"127.0.0.1", 0, "", 5000, 45000, 3, 1024, 90, 
										"127.0.0.1", 0, 60000, 2, 19200, 8, 0, 0, 2,643);
		#If Not WebClient Then
			vReader = New XMLReader();
			vReader.SetString(pStr);
			While vReader.Read() Do
				If vReader.NodeType = XMLNodeType.StartElement Then
					If vReader.Name = "SlipChequeCompanyRu" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeCompanyRu = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeCompanyEn" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeCompanyEn = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeBankRu" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeBankRu = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeBankEn" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeBankEn = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeCityRu" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeCityRu = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeCityEn" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeCityEn = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeAddressRu" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeAddressRu = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeAddressEn" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeAddressEn = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeFooterTextRu" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeFooterTextRu = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "SlipChequeFooterTextEn" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.SlipChequeFooterTextEn = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "AuthServerIP" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.AuthServerIP = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "AuthServerPort" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.AuthServerPort = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "X25Script" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.X25Script = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "TimeoutACK" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.TimeoutACK = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "AuthTimeoutPacket" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.AuthTimeoutPacket = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "CountNAK" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CountNAK = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "PacketSize" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.PacketSize = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "TransactionTimeout" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.TransactionTimeout = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "CtrlServerIP" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CtrlServerIP = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "CtrlServerPort" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CtrlServerPort = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "CtrlTimeoutPacket" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CtrlTimeoutPacket = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "COMPort" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.COMPort = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "BaudRate" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.BaudRate = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "ByteSize" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.ByteSize = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "Parity" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.Parity = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "StopBits" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.StopBits = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "CurrencyCode" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CurrencyCode = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "FlowCtrl" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.FlowCtrl = Number(vReader.Value);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vReader.Close();
			vReader = Undefined;
		#EndIf
		
	EndIf;
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC,pConnectionParameters)
	If pConnectionParameters <> Undefined Then
		pPC.PortNumber 		= pConnectionParameters.COMPort;
		pPC.BaudRate 		= pConnectionParameters.BaudRate;
		pPC.CurrencyCode 	= pConnectionParameters.CurrencyCode;
		pPC.TerminalID 		= pConnectionParameters.TerminalID;
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function GetTextLinesArray(pTextStr) 
	vTxtArr = New Array;
	If Not IsBlankString(pTextStr) Then
		vTxt = New TextDocument();
		vTxt.SetText(pTextStr);
		For i = 1 To vTxt.LineCount() Do
			vStr = vTxt.GetLine(i);
			If StrFind(vStr, "cut") > 0 Then
				Break;
			EndIf;
			vTxtArr.Add(vStr);
		EndDo;
	EndIf;
	Return vTxtArr;
EndFunction // GetTextLinesArray

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pCashRegister, pOneCopyOnly = False)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,pCashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
						  |de='Input cash register password please...';
						  |en='Input cash register password please...'");
		
		If  IsBlankString(vPasswordKKM) Then
			pCancel = True;
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverINPASDualConnectorDriver83, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
			// Show InputCashRegisterPassword
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription",vQuestion), , , , , vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'"), , NStr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));
		Return;
	EndIf;
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Error", , , "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function ProcessResultCode(pFR, pRC, pFunction, rMessage)
	If Not pFR Then
		If Not IsBlankString(TrimAll(pRC.Status)) Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + TrimAll(pRC.Status) + Chars.LF 
			+ NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pRC);
		Else
			rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pRC);
		EndIf;
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Function GetErrorDescription(pPC)
	vMessage = "";
	Try
		pPC.ПолучитьОшибку(vMessage);
	Except
		vMessage = NStr("en='<Description unknown>!'; de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndTry;
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function GetTerminalId(pArrPaymentTerminal)
	vTerminalNumber = StrReplace(TrimAll(pArrPaymentTerminal.TerminalNumber), " ", "");
	If IsBlankString(vTerminalNumber) Then
		vTerminalNumber = "00000000";
	Else
		If StrLen(vTerminalNumber) < 8 And tcOnServer.IsNumber(vTerminalNumber) Then
			vTerminalNumber = Format(Number(vTerminalNumber), "ND=8; NFD=; NZ=; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vTerminalNumber;
EndFunction // GetTerminalId

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName) Export
	vObject = Undefined;
	amPersistentObjects.Property(pName, vObject);
	If vObject = Undefined Then
		amPersistentObjects.Insert(pName, vObject);
	EndIf;
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue) Export
	amPersistentObjects.Insert(pName, pValue);
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Procedure AfterShowInputText(pConnParameters, pExtraParams) Export 
	Try
		vMessage = "";
		If pConnParameters = Undefined Then
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'"));
			Return;
		EndIf;
		// Save parameters
		tcCreditCardsProcessingSystemDriverAtServer.SetCreditCardsProcessingSystemConnectionParameters(pExtraParams, pConnParameters); 
		
		// Try to connect
		vDeviceID = "";
		vArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(pExtraParams); 
		vPC = Connect(vMessage, vArrPaymentTerminal, vDeviceID);
		If vPC = Undefined Then
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'") + Chars.LF + vMessage);
			Return;
		EndIf;
		// Initialize connection to the PIN pad device
		vDemo = "";
		vRC = vPC.ТестУстройства(vMessage, vDemo);
		If Not vRC Then
			vMessage = GetErrorDescription(vPC);
			Disconnect(vPC);
			Return;
		EndIf;
		Disconnect(vPC);
		If IsBlankString(vMessage) Then
			ShowMessageBox(, NStr("en = 'Pay card processing system was connected successfully!'; de = 'Das Verarbeitungssystem für Kreditkarten wurde erfolgreich angeschlossen!'; ru = 'Система процессинга кредитных карт успешно подключена!'"));
		Else
			ShowMessageBox(, NStr("en = 'Pay card processing system was connected with warning!'; de = 'Das Verarbeitungssystem für Kreditkarten wurde mit einer Warnung angeschlossen! '; ru = 'Система процессинга кредитных карт подключена с предупреждением! '") + Chars.LF + vMessage);
		EndIf;
	Except
		vMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndTry;
EndProcedure //  AfterShowInputText

// -----------------------------------------------------------------------------
Function GetDefaultConnectionParameters()
	Return "<?xml version=""1.0"" ?>  
	|<INPASConnectionParameters> 
	|	<COMPort>9</COMPort>
	|	<BaudRate>115200</BaudRate>
	|	<CurrencyCode>643</CurrencyCode>
	|	<SlipCharLineLength>0</SlipCharLineLength>
	|	<CheckNumberReturn>0</CheckNumberReturn>
	|	<AuthorisationCodeReturn>0</AuthorisationCodeReturn>
	|</INPASConnectionParameters>";
EndFunction // GetDefaultConnectionParameters

#EndRegion   
