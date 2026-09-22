
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pCreditCardsProcessingSystemType - EnumRef.CreditCardsProcessingSystems	 - Credit cards processing systems
//  pDriverLocation					 - String								 - Driver location
//
Procedure pmInstall(pCreditCardsProcessingSystemType) Export
	If pCreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNT33_33SystemDriver") Then
		BeginInstallAddIn(,"CommonTemplate.AddInCreditCardsSberbankPilotNT33_33");
	Else
		BeginInstallAddIn(,"CommonTemplate.AddInCreditCardsSberbankPilotNT");
	EndIf;
EndProcedure // Install

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
					vPC.CardType = Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType, "Code")));
				Except
					vPC.CardType = 0;
				EndTry;
			Else
				vPC.CardType = 0;
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vPC.CurrencyCode = Number(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vPC.CurrencyCode = 643;	
			EndIf;
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vPC.Amount = pSum * 100;
				// Do payment
				If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then 
					
					vReferenceNumber = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber");
					If Not IsBlankString(vReferenceNumber) Then
						vPC.RRN = vReferenceNumber;
					EndIf;
					
					vCreditCard = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "CreditCard");
					If ValueIsFilled(vCreditCard) Then
						vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
						If ValueIsFilled(vEncData) Then
							vPC.EncryptedData = Base64Value(vEncData); 	
						EndIf;
					EndIf;
					
					vRC = vPC.NFun(52); // Close preauthorization
				Else
					vCreditCard = pObj.CreditCard;
					If ValueIsFilled(vCreditCard) Then
						vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
						If ValueIsFilled(vEncData) Then
							vPC.EncryptedData = Base64Value(vEncData); 	
						EndIf;	
					EndIf;
					
					vRC = vPC.NFun(1); // Payment
				EndIf; 
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.RRN;
				vAuthorizationCode = vPC.AuthCode;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			Else
				// Try annulate payment
				vPC.RRN = "";
				vPC.EncryptedData = Base64Value("");
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
						vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
						If Not ValueIsFilled(vPayment) Then
							Break;
						EndIf;
					EndDo;
				EndIf;
				If ValueIsFilled(vPayment) Then
					vReferenceNumber = tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber");
					If Not IsBlankString(vReferenceNumber) Then
						vPC.RRN = vReferenceNumber;
					EndIf;
					vCreditCard = tcOnServer.cmGetAttributeByRef(vPayment, "CreditCard");
					If ValueIsFilled(vCreditCard) Then
						vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
						If ValueIsFilled(vEncData) Then
							vPC.EncryptedData = Base64Value(vEncData); 	
						EndIf;
					EndIf;
				EndIf;
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
				// Set amount
				vPC.Amount =  -pSum * 100; 
				// Do return
				vRC = vPC.NFun(3);
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.RRN;
				vAuthorizationCode = vPC.AuthCode;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			EndIf;
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				pObj.CreditCard = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardRef(pObj, vPC.CardID,, Base64String(vPC.EncryptedData), GetCardType(vPC, pObj), GetCardExpiryDate(vPC));
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			Try
				pObj.TerminalNumber = vPC.TermNum;
				pObj.MerchantID  = vPC.MerchNum;
				// Fill card type
				vCardTypeRef = GetCardType(vPC, pObj);
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
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
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
					vPC.CardType = Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType, "Code")));
				Except
					vPC.CardType = 0;
				EndTry;
			Else
				vPC.CardType = 0;
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vPC.CurrencyCode = Number(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vPC.CurrencyCode = 643;	
			EndIf;
			// Do operation
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			// Set amount
			vPC.Amount = pSum * 100;   
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
				If ValueIsFilled(vEncData) Then
					vPC.EncryptedData = Base64Value(vEncData); 	
				EndIf;	
			EndIf;
			// Do payment
			vRC = vPC.NFun(51);
			If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vPC.RRN;
			vAuthorizationCode = vPC.AuthCode;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				pObj.CreditCard = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardRef(pObj, vPC.CardID,, Base64String(vPC.EncryptedData), GetCardType(vPC, pObj), GetCardExpiryDate(vPC));
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
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
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
					vPC.CardType = Number(TrimAll(tcOnServer.cmGetAttributeByRef(vArrPaymentMethod.CardType, "Code")));
				Except
					vPC.CardType = 0;
				EndTry;
			Else
				vPC.CardType = 0;
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vPC.CurrencyCode = Number(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vPC.CurrencyCode = 643;	
			EndIf;
			// Set RNN
			vPC.RRN = pObj.ReferenceNumber;
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vPC.Amount = 0;  //set sum =0 for cancelled preauthorization
				vCreditCard = pObj.CreditCard;
				If ValueIsFilled(vCreditCard) Then
					vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
					If ValueIsFilled(vEncData) Then
						vPC.EncryptedData = Base64Value(vEncData); 	
					EndIf;	
				EndIf;
				vRC = vPC.NFun(43); 
				If Not ProcessResultCode(vPC, vRC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.RRN;
				vAuthorizationCode = vPC.AuthCode;
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
		vUCList.Add(6002, NStr("en = 'X-Report (Short)'; de = 'X-Bericht (kurz)'; ru = 'X-Отчет (Краткий)'"));
		vUCList.Add(6001, NStr("en='X-Report'; ru='X-Отчет'; de='X-Bericht'"));
		vUCList.Add(6000, NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
		vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverSberbankPilotNT, New Structure("PC, CashRegisterArr, PaymentTerminalArr", vPC, vCashRegisterArr, vPaymentTerminalArr)));
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
			PrintXReport(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr, True); 
		ElsIf vUCItem.Value = 6001 Then
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
		Disconnect(pPC);
	Except
		rMessage = ErrorDescription();
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
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
Procedure PrintXReport(pPC, pCashRegisterArr, pPaymentTerminalArr, pShort = False) Export
	rMessage = "";
	Try
		// X report 
		If pShort Then
			vRC = pPC.NFun(6002);
		Else
			vRC = pPC.NFun(6001);	
		EndIf;
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
		Disconnect(pPC);
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en='CreditCardProcessingSystem.XReport'; de='CreditCardProcessingSystem.XReport'; ru='СистемаПроцессингаКредитныхКарт.XОтчет'"), rMessage);
	EndTry;
EndProcedure // PrintXReport

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
			vConnParameters = "C:\sc552\pilot_nt.dll";
		EndIf;
		
		vDirectory = "";
		If Not IsBlankString(vConnParameters) Then
			vDirectory = Left(vConnParameters, StrFind(vConnParameters, "\", SearchDirection.FromEnd));
		EndIf;
		
		// Show connection parameters
		vFileDialog = New FileDialog(FileDialogMode.Open);
		vFileDialog.Title = NStr("en = 'Select the library pilot_nt.dll'; de = 'Wählen Sie die Bibliothek pilot_nt.dll aus'; ru = 'Выберите библиотеку pilot_nt.dll'");
		vFileDialog.Directory = vDirectory;
		vFileDialog.Multiselect = False;
		vFileDialog.Filter = NStr("en = 'Library pilot_nt.dll'; de = 'Bibliothek pilot_nt.dll'; ru = 'Библиотека pilot_nt.dll'") + " (pilot_nt.dll) |pilot_nt.dll";
		
		vFileDialog.Show(New NotifyDescription("AfterShowFileDialog", tcCreditCardsProcessingSystemDriverSberbankPilotNT, pPaymentTerminal.Ref));
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.UserMessage(rMessage);
	EndTry;
EndProcedure // pmCheckConnection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pConnParameters	 - XMLString - XML with params
//  pExtraParams	 - Structure - 
//
Procedure AfterShowFileDialog(pConnParameters, pExtraParams) Export 
	Try
		vMessage = "";
		If pConnParameters = Undefined Then
			ShowMessageBox(, NStr("en='Error validating pay card system connection!';ru='Ошибка проверки подключения системы процессинга кредитных карт!';de='Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'"));
			Return;
		EndIf;
		// Save parameters
		tcCreditCardsProcessingSystemDriverAtServer.SetCreditCardsProcessingSystemConnectionParameters(pExtraParams, pConnParameters[0]);
		
		// Try to connect
		vPC = Connect(vMessage, pExtraParams);
		If vPC = Undefined Then
			ShowMessageBox(, NStr("en='Error validating pay card system connection!';ru='Ошибка проверки подключения системы процессинга кредитных карт!';de='Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'") + Chars.LF + vMessage);
			Return;
		EndIf;
		Disconnect(vPC);
		If IsBlankString(vMessage) Then
			ShowMessageBox(, NStr("en='Pay card processing system was connected successfully!';ru='Система процессинга кредитных карт успешно подключена!';de='Das Verarbeitungssystem für Kreditkarten wurde erfolgreich angeschlossen!'"));
		EndIf;
	Except
		vMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndTry;
EndProcedure //  AfterShowFileDialog

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetErrorDescription(pPC)
	vMessage = "";
	Try
		vMessage = pPC.LastErrorDescription;
	Except
		vMessage = NStr("en='Error description is unknown! Error code is '; de='Fehlerbeschreibung ist nicht bekannt! Der Fehlercode ist '; ru='Описание ошибки не найдено! Код ошибки '");
	EndTry;	
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function Connect(rMessage, pArrPaymentTerminal)
	// Reset return status
	rMessage = "";
	// Try to create external component
	vPC = Undefined;
	Try
		// Build ActiveX object to work with
		
		vCreditCardsProcessingSystemType = tcOnServer.cmGetAttributeByRef(pArrPaymentTerminal, "CreditCardsProcessingSystemType");
		vCommonTemplateName = "CommonTemplate.AddInCreditCardsSberbankPilotNT";
		If vCreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNT33_33SystemDriver") Then
			vCommonTemplateName = "CommonTemplate.AddInCreditCardsSberbankPilotNT33_33";
		EndIf;
		IsConnected = AttachAddIn(vCommonTemplateName, "Native", AddInType.Native); // ACC:561
		If Not IsConnected Then
			rMessage = NStr("en = 'Error connecting to the acquiring system driver'; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber'; ru = 'Ошибка подключения к драйверу эквайринговой системы'");
			Return Undefined;
		Endif;
		
		vNativeName = "AddIn.Native.pilotNT";
		If vCreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNT33_33SystemDriver") Then
			vNativeName = "AddIn.Native.pilotNT33_33";
		EndIf;
		vPC = New(vNativeName);
		
		vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pArrPaymentTerminal);
		
		If Not ValueIsFilled(vConnParameters) Then
			rMessage = NStr("en = 'Error connecting to the acquiring system driver: '; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber: '; ru = 'Ошибка подключения к драйверу эквайринговой системы: '") + ErrorDescription();
			Return Undefined;	
		EndIf;
		
		vRC = vPC.Connect(TrimAll(vConnParameters));
		
		If Not ProcessResultCode(vPC, vRC, "Connect", rMessage) Then
			Return Undefined;	
		EndIf;
	Except
		rMessage = NStr("en = 'Error connecting to the acquiring system driver: '; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber: '; ru = 'Ошибка подключения к драйверу эквайринговой системы: '") + ErrorDescription();
		Return Undefined;
	EndTry;
	
	Return vPC;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	Try
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pFR, pRC, pFunction, rMessage)
	If pRC <> 0 Then
		rMessage = "Result code: " + pRC + ", " + NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pFR);
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
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function GetOperationSlipCheque(pPC)
	vSlipCheque = GetStringFromBinaryData(pPC.Cheque, TextEncoding.ANSI);
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
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverSberbankPilotNT, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
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

// -----------------------------------------------------------------------------
Function GetCardType(pPC, pObj)
	vCardTypeRef = PredefinedValue("Catalog.CreditCardTypes.EmptyRef");
	// Get card type from object payment method
	If TypeOf(pObj) <> Type("Structure") Then
		vPaymentMethod = pObj.PaymentMethod;
		If ValueIsFilled(vPaymentMethod) Then
			vCardType = tcOnServer.cmGetAttributeByRef(vPaymentMethod, "CardType");
			If ValueIsFilled(vCardType) Then
				vCardTypeRef = vCardType;
			EndIf;
		EndIf;
	EndIf;
	
	// Try to find card type
	vCardName = "";
	Try
		vCardName = cmRemoveUTFControlSymbols(TrimAll(pPC.CardName));
	Except
		vCardName = "";
	EndTry;
	
	vCardType = "";
	Try
		vCardType = cmRemoveUTFControlSymbols(TrimAll(pPC.CardType));
	Except
		vCardType = "";
	EndTry;

	If Not IsBlankString(vCardName) Or Not IsBlankString(vCardType) Then
		vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vCardName, vCardType);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType 

// -----------------------------------------------------------------------------
Function GetCardExpiryDate(pPC)
	// Try to retrieve card number
	vCardExpiryDate = pPC.ClientExpiryDate;
	If IsBlankString(vCardExpiryDate) Then
		Return '00010101';
	Else
		Try
			Return Date(2000 + Number(Right(vCardExpiryDate, 2)), Number(Left(vCardExpiryDate, 2)), 1, 0, 0, 0);
		Except
			Return '00010101';
		EndTry;
	EndIf;
EndFunction // GetCardExpiryDate

#EndRegion