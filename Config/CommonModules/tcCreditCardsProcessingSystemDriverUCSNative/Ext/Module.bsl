
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pCreditCardsProcessingSystemType - EnumRef.CreditCardsProcessingSystems	 - Credit cards processing systems
//  pDriverLocation					 - String								 - Driver location
//
Procedure pmInstall(pCreditCardsProcessingSystemType) Export
	BeginInstallAddIn(,"CommonTemplate.AddInCreditCardsUCS");
EndProcedure // Install

// --------------------------------------------------------------------------------
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
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	EndIf;
	
	vTimeout = pPaymentTerminal.Timeout;
	If vTimeout <= 2000 Then
		vTimeout = 2000;
	EndIf;
	
	// Pay card system object was created successfully
	Try
		If Not Login(vPC, pPaymentTerminal, rMessage) Then
			Return False;
		EndIf;
		
		vPC.Wait(vTimeout);
		
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
		
		// Do operation
		If pSum > 0 Then
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			
			// Set amount
			vAmount = pSum * 100;
			
			// Do payment
			If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				vPreauthorisationSum =  tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "Sum");
				If pSum > vPreauthorisationSum Then
					Raise NStr("en = 'The settlement amount must not be greater than the pre-authorization amount.'; de = 'Der Abrechnungsbetrag darf nicht höher sein als der vorautorisierte Betrag.'; ru = 'Сумма расчета не должна быть больше суммы преавторизации'");
				EndIf;
				
				vRRN = "";
				vReferenceNumber = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber");
				If Not IsBlankString(vReferenceNumber) Then
					vRRN = vReferenceNumber;
				EndIf;
				
				vAuthCode = "";
				vAuthorizationCode = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "AuthorizationCode");
				If Not IsBlankString(vAuthorizationCode) Then
					vAuthCode = vAuthorizationCode;
				EndIf;
				
				While StrLen(vAuthCode) < 6 Do
					vAuthCode = vAuthCode + " ";
				EndDo;
				
				vCardType = "";
				
				vCardTypeRef = pObj.CardType;
				If Not ValueIsFilled(vCardTypeRef) Then
					vCardTypeRef = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "CardType");
				EndIf;
				If Not ValueIsFilled(vCardTypeRef) Then
					vCreditCard = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "CreditCard");
					If ValueIsFilled(vCreditCard) Then
						vCardTypeRef = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardType");
					EndIf;
				EndIf;
				
				If ValueIsFilled(vCardTypeRef) Then
					vCardType = "*** " + TrimAll(tcOnServer.cmGetAttributeByRef(vCardTypeRef, "Code")) + " ***";
				EndIf;
				
				vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(30 + StrLen(vCardType), 16);
				If StrLen(vCommandLength) = 1 Then
					vCommandLength = "0" + vCommandLength;
				EndIf;
				
				vInBuffer =
				StrTemplate(
					"%1%2%3%4%5%6%7",
					"86",
					Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
					vCommandLength,
					Format(vAmount, "ND=12; NFD=0; NZ=0; NLZ=; NG="),
					vAuthCode,
					vRRN,
					vCardType
				);
				
				vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
			Else
				vCreditCardInfo = "";
				vCreditCard = pObj.CreditCard;
				If ValueIsFilled(vCreditCard) Then
					vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
					vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
					If Not IsBlankString(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then
						vCreditCardInfo = vCardNumber + Format(vCardValidTillDate, "DF==yyMM");
					EndIf;
				EndIf;
				
				vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(12 + StrLen(vCreditCardInfo), 16);
				If StrLen(vCommandLength) = 1 Then
					vCommandLength = "0" + vCommandLength;
				EndIf;
				
				vInBuffer =
				StrTemplate(
					"%1%2%3%4%5",
					"10",
					Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
					vCommandLength,
					Format(vAmount, "ND=12; NFD=0; NZ=0; NLZ=; NG="),
					vCreditCardInfo
				);
				
				vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
			EndIf;
			If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage) Then
				Return False;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vResponse.ReferenceNumber;
			vAuthorizationCode = vResponse.AuthorizationCode;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
			// Get slip
			vOutSlip = vResponse.SlipText;
		Else
			// Try annulate payment
			vRRN = "";
			vAuthCode = "";
			vCreditCardInfo = "";
			vCurAmount = 0;
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
					vRRN = vReferenceNumber;
				EndIf;
				vAuthorizationCode = tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode");
				If Not IsBlankString(vAuthorizationCode) Then
					vAuthCode = vAuthorizationCode;
				EndIf;
				vCurAmount = tcOnServer.cmGetAttributeByRef(vPayment, "Sum") * 100;
				vCreditCard = tcOnServer.cmGetAttributeByRef(vPayment, "CreditCard");
				If ValueIsFilled(vCreditCard) Then
					vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
					vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
					If Not IsBlankString(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then
						vCreditCardInfo = vCardNumber + Format(vCardValidTillDate, "DF==yyMM");
					EndIf;
				EndIf;
			EndIf;
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
			
			// Set amount
			vAmount = -pSum * 100;
			
			vCurAmountStr = Format(vCurAmount, "ND=12; NFD=0; NLZ=; NG=");
			vAmountStr = "";
			If vCurAmount <> vAmount Then
				vAmountStr = Format(vAmount, "ND=12; NFD=0; NLZ=; NG=");
			EndIf;
			
			vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(24 + StrLen(vAmountStr), 16);
			If StrLen(vCommandLength) = 1 Then
				vCommandLength = "0" + vCommandLength;
			EndIf;
			
			// Do return
			vInBuffer =
			StrTemplate(
				"%1%2%3%4%5%6",
				"1A",
				Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
				vCommandLength,
				vRRN,
				vCurAmountStr,
				vAmountStr
			);
			
			vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
			If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage, True) Then
				rMessage = "";
				vPC.Wait(vTimeout);
				
				vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(12 + StrLen(vCreditCardInfo), 16);
				If StrLen(vCommandLength) = 1 Then
					vCommandLength = "0" + vCommandLength;
				EndIf;
				
				vAmountStr = Format(vAmount, "ND=12; NFD=0; NLZ=; NG=");
				
				// Do return
				vInBuffer =
				StrTemplate(
					"%1%2%3%4%5",
					"14",
					Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
					vCommandLength,
					vAmountStr,
					vCreditCardInfo
				);
				
				vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
				If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage) Then
					Return False;
				EndIf;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vResponse.ReferenceNumber;
			vAuthorizationCode = vResponse.AuthorizationCode;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),,,,vMessage);
			// Get slip
			vOutSlip = vResponse.SlipText;
		EndIf;
		// Save authorization code and reference number if there are no errors
		pObj.AuthorizationCode = vAuthorizationCode;
		pObj.ReferenceNumber = vReferenceNumber;
		Try
			pObj.TerminalNumber = vResponse.TerminalNumber;
			pObj.MerchantID = vResponse.MerchantID;
			// Fill card type
			vCardTypeRef = GetCardType(vResponse.CardType, pObj);
			If ValueIsFilled(vCardTypeRef) Then
				pObj.CardType = vCardTypeRef;
			EndIf;
			pObj.CardOperationDate = Date(vResponse.CardOperationDate + vResponse.CardOperationTime);
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
EndFunction // pmAuthorizePayment

// --------------------------------------------------------------------------------
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
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	EndIf;
	
	vTimeout = pPaymentTerminal.Timeout;
	If vTimeout <= 2000 Then
		vTimeout = 2000;
	EndIf;
	
	// Pay card system object was created successfully
	Try
		If Not Login(vPC, pPaymentTerminal, rMessage) Then
			Return False;
		EndIf;
		
		vPC.Wait(vTimeout);
		
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
				
		// Do operation
		// Log payment
		tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
		// Set amount
		vAmount = pSum * 100;
		
		vCreditCardInfo = "";
		vCreditCard = pObj.CreditCard;
		If ValueIsFilled(vCreditCard) Then
			vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
			vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
			If Not IsBlankString(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then
				vCreditCardInfo = vCardNumber + Format(vCardValidTillDate, "DF==yyMM");
			EndIf;
		EndIf;
		
		vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(12 + StrLen(vCreditCardInfo), 16);
		If StrLen(vCommandLength) = 1 Then
			vCommandLength = "0" + vCommandLength;
		EndIf;
		
		vInBuffer =
		StrTemplate(
			"%1%2%3%4%5",
			"11",
			Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
			vCommandLength,
			Format(vAmount, "ND=12; NFD=0; NZ=0; NLZ=; NG="),
			vCreditCardInfo
		);
		
		vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
		If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage) Then
			Return False;
		EndIf;
		// Get Reference number, Authorization code
		vReferenceNumber = vResponse.ReferenceNumber;
		vAuthorizationCode = vResponse.AuthorizationCode;
		// Log authorisation code and RRN
		vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
		tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
		Try
			pObj.TerminalNumber = vResponse.TerminalNumber;
			pObj.MerchantID = vResponse.MerchantID;
			// Fill card type
			vCardTypeRef = GetCardType(vResponse.CardType, pObj);
			If ValueIsFilled(vCardTypeRef) Then
				pObj.CardType = vCardTypeRef;
			EndIf;
			pObj.DateTime = Date(vResponse.CardOperationDate + vResponse.CardOperationTime);
		Except
		EndTry;
		vOutSlip = vResponse.SlipText;
		
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
EndFunction // pmPreauthorization

// --------------------------------------------------------------------------------
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
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	EndIf;
	
	vTimeout = pPaymentTerminal.Timeout;
	If vTimeout <= 2000 Then
		vTimeout = 2000;
	EndIf;
	
	// Pay card system object was created successfully
	Try
		If Not Login(vPC, pPaymentTerminal, rMessage) Then
			Return False;
		EndIf;
		
		vPC.Wait(vTimeout);
		
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
		
		// Set RNN
		vRRN = pObj.ReferenceNumber;
		vAuthCode = pObj.AuthorizationCode;
		
		While StrLen(vAuthCode) < 6 Do
			vAuthCode = vAuthCode + " ";
		EndDo;
		
		vCardType = "";
		
		vCardTypeRef = pObj.CardType;
		If Not ValueIsFilled(vCardTypeRef) Then
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vCardTypeRef = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardType");
			EndIf;
		EndIf;
		
		If ValueIsFilled(vCardTypeRef) Then
			vCardType = "*** " + TrimAll(tcOnServer.cmGetAttributeByRef(vCardTypeRef, "Code")) + " ***" + Char(27);
		EndIf;
		
		vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(24, 16);
		If StrLen(vCommandLength) = 1 Then
			vCommandLength = "0" + vCommandLength;
		EndIf;
		
		// Do operation
		If pSum > 0 Then
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			// Set amount
			vCurAmountStr = Format(pSum * 100, "ND=12; NFD=0; NLZ=; NG=");
			
			vInBuffer =
			StrTemplate(
				"%1%2%3%4%5",
				"1A",
				Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
				vCommandLength,
				vRRN,
				vCurAmountStr
			);
			
			vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
			If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage, True) Then
				rMessage = "";
				vPC.Wait(vTimeout);
				
				vCommandLength = tcCommonFunctionOnClientServer.DecToBasic(30 + StrLen(vCardType), 16);
				If StrLen(vCommandLength) = 1 Then
					vCommandLength = "0" + vCommandLength;
				EndIf;
				
				vInBuffer =
				StrTemplate(
					"%1%2%3%4%5%6%7",
					"8A",
					Format(Number(pPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
					vCommandLength,
					vRRN,
					vCurAmountStr,
					vAuthCode,
					vCardType
				);
				
				vResponse = ExecuteProcessing(vPC, vInBuffer, rMessage);
				If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, rMessage, True) Then
					Return False;
				EndIf;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vResponse.ReferenceNumber;
			vAuthorizationCode = vResponse.AuthorizationCode;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,vMessage);
			// Get slip
			vOutSlip = vResponse.SlipText;
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
EndFunction // pmCancelPreauthorization

// --------------------------------------------------------------------------------
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
	EndIf;
	
	vUCList = New ValueList();
	vUCList.Add(1, NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
	vUCList.Add(2, NStr("en = 'X-Report (Short)'; de = 'X-Bericht (kurz)'; ru = 'X-Отчет (Краткий)'"));
	vUCList.Add(3, NStr("en='X-Report'; ru='X-Отчет'; de='X-Bericht'"));
	vUCList.Add(5, NStr("en = 'Z-Report (DUPLICATE ENCASHMENT)'; de = 'Z-Report (DUPLIKATINKASSO)'; ru = 'Z-Отчет (ДУБЛИКАТ ИНКАССАЦИЯ)'"));
	vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverUCSNative, New Structure("PC, CashRegisterArr, PaymentTerminalArr", vPC, vCashRegisterArr, vPaymentTerminalArr)));
	
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

// --------------------------------------------------------------------------------
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
			vConnParameters = "C:\UCS\BIN\ucs_ms.dll";
		EndIf;
		
		vDirectory = "";
		If Not IsBlankString(vConnParameters) Then
			vDirectory = Left(vConnParameters, StrFind(vConnParameters, "\", SearchDirection.FromEnd));
		EndIf;
		
		// Show connection parameters
		vFileDialog = New FileDialog(FileDialogMode.Open);
		vFileDialog.Title = NStr("en = 'Select the library ucs_ms.dll'; de = 'Wählen Sie die Bibliothek ucs_ms.dll aus'; ru = 'Выберите библиотеку ucs_ms.dll'");
		vFileDialog.Directory = vDirectory;
		vFileDialog.Multiselect = False;
		vFileDialog.Filter = NStr("en = 'Library ucs_ms.dll'; de = 'Bibliothek ucs_ms.dll'; ru = 'Библиотека ucs_ms.dll'") + " (ucs_ms.dll) |ucs_ms.dll";
		
		vFileDialog.Show(New NotifyDescription("AfterShowFileDialog", tcCreditCardsProcessingSystemDriverUCSNative, pPaymentTerminal.Ref));
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.UserMessage(rMessage);
	EndTry;
EndProcedure // pmCheckConnection

// --------------------------------------------------------------------------------
Procedure ReconcileTotals(pPC = Undefined, pCashRegister, pPaymentTerminal, pResult = True) Export
	rMessage = "";
	Try
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
		
		vPC = pPC;
		If pPC = Undefined Then
			vPC = Connect(rMessage, vPaymentTerminalArr);
			If vPC = Undefined Then
				ShowMessageBox(,StrTemplate(NStr("en = 'Terminal connection error!
                                  |Error: %1'; de = 'Terminalverbindungsfehler!
                                  |Fehler: %1'; ru = 'Ошибка подключения к терминалу!
                                  |Error: %1'"), rMessage));
				pResult = False;
				Return;
			EndIf;
		EndIf;
		
		vTimeout = vPaymentTerminalArr.Timeout;
		If vTimeout <= 2000 Then
			vTimeout = 2000;
		EndIf;
		
		vMessage = "";
		If Not Login(vPC, vPaymentTerminalArr, vMessage) Then
			pResult = False;
			ShowMessageBox(,
				StrTemplate(
					NStr("en = 'Terminal connection error!
					|Error: %1'; de = 'Terminalverbindungsfehler!
					|Fehler: %1'; ru = 'Ошибка подключения к терминалу!
					|Error: %1'"),
					vMessage
				)
			);
			Return;
		EndIf;
		
		vPC.Wait(vTimeout);
		
		vInBuffer =
		StrTemplate(
			"%1%2%3",
			"21",
			Format(Number(vPaymentTerminalArr.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
			"00"
		);
		
		vMessage = "";
		vResponse = ExecuteProcessing(vPC, vInBuffer, vMessage);
		If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, vMessage) Then
			pResult = False;
			ShowMessageBox(,
				StrTemplate(
					NStr("en = 'Execution error!
					|Error: %1'; de = 'Laufzeitfehler!
					|Fehler: %1'; ru = 'Ошибка выполнения!
					|Error: %1'"),
					vMessage
				)
			);
			Return;
		EndIf;
		
		If Not vPaymentTerminalArr.PrintSlipInCheque And 
			Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vResponse.SlipText) Then
			vSlipTxtArr = GetTextLinesArray(vResponse.SlipText);
			PrintSlipDocument(vSlipTxtArr, vCashRegisterArr);
		EndIf;
		
		ShowMessageBox(, NStr("en='The operation was completed successfully!'; de='Der Vorgang wurde erfolgreich abgeschlossen!'; ru='Операция выполнена успешно!'"));
		Disconnect(vPC);
	Except
		vMessage = BriefErrorDescription(ErrorInfo());
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AfterServiceFunctionsMenuSelection'; de='CreditCardProcessingSystem.AfterServiceFunctionsMenuSelection'; ru='СистемаПроцессингаКредитныхКарт.ServiceFunctionsMenu'"), vMessage);
		pResult = False;
		ShowMessageBox(,
			StrTemplate(
				NStr("en = 'Execution error!
				|Error: %1'; de = 'Laufzeitfehler!
				|Fehler: %1'; ru = 'Ошибка выполнения!
				|Error: %1'"),
				vMessage
			)
		);
	EndTry;
EndProcedure // ReconcileTotals

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function Connect(rMessage, pArrPaymentTerminal)
	// Reset return status
	rMessage = "";
	
	vPC = Undefined;
	Try
		IsConnected = AttachAddIn("CommonTemplate.AddInCreditCardsUCS", "Native", AddInType.Native); // ACC:561
		If Not IsConnected Then
			rMessage = NStr("en = 'Error connecting to the acquiring system driver'; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber'; ru = 'Ошибка подключения к драйверу эквайринговой системы'");
			Return Undefined;
		Endif;
		
		vPC = New("AddIn.Native.UCS");
	
		vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pArrPaymentTerminal);
		If Not ValueIsFilled(vConnParameters) Then
			rMessage = NStr("en = 'Error connecting to the acquiring system driver: '; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber: '; ru = 'Ошибка подключения к драйверу эквайринговой системы: '") +NStr("en = 'The path to the ucs_ms.dll library is not specified'; de = 'Der Pfad zur Bibliothek ucs_ms.dll ist nicht angegeben'; ru = 'Не указан путь к библиотеке ucs_ms.dll'");
			Return Undefined;
		EndIf;
		
		vRC = vPC.Connect(TrimAll(vConnParameters));
		If Not ProcessResultCode(vPC, Format(vRC, "NFD=0; NG="), "", rMessage) Then
			Return Undefined;
		EndIf;
		
		vRC = vPC.Create("");
		If Not ProcessResultCode(vPC, Format(vRC, "NFD=0; NG="), "", rMessage) Then
			Return Undefined;
		EndIf;
	Except
		rMessage = NStr("en = 'Error connecting to the acquiring system driver: '; de = 'Fehler beim Herstellen einer Verbindung zum Acquiring-Systemtreiber: '; ru = 'Ошибка подключения к драйверу эквайринговой системы: '") + ErrorDescription();
		Return Undefined;
	EndTry;
	
	Return vPC;
EndFunction // Connect

// --------------------------------------------------------------------------------
Procedure Disconnect(pPC)
	Try
		pPC.Destroy();
		pPC.Disconnect();
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// --------------------------------------------------------------------------------
Function Login(pPC, pArrPaymentTerminal, rMessage)
	Try
		vInBuffer =
		StrTemplate(
			"%1%2%3",
			"30",
			Format(Number(pArrPaymentTerminal.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
			"00"
		);
		
		vResponse = ExecuteProcessing(pPC, vInBuffer, rMessage);
		If Not ProcessResultCode(pPC, vResponse.ErrorCode, vResponse.Error, rMessage) Then
			Return False;
		EndIf;
		
		Return True;
	Except
		rMessage = NStr("en = 'Acquiring system authorization error: '; de = 'Beim Erfassen eines Systemautorisierungsfehlers: '; ru = 'Ошибка авторизации эквайринговой системы: '") + ErrorDescription();
		Disconnect(pPC);
		Return False;
	EndTry;
EndFunction // Login

// --------------------------------------------------------------------------------
Function ExecuteProcessing(pPC, Val pInBuffer, rMessage)
	vOutBufferArr = New Array;
	vOutBuffer = "";
	vInBuffer = pInBuffer;
	
	Try
		While pPC.Execute(vInBuffer, vOutBuffer) = 0 Do
			vOutBufferArr.Add(vOutBuffer);
			vInBuffer = "";
			vOutBuffer = "";
		EndDo;
	Except
		rMessage = NStr("en = 'Acquiring system authorization error: '; de = 'Beim Erfassen eines Systemautorisierungsfehlers: '; ru = 'Ошибка авторизации эквайринговой системы: '") + BriefErrorDescription(ErrorInfo());
		Return New Array;
	EndTry;
	
	If Not IsBlankString(vOutBuffer) Then
		vOutBufferArr.Add(vOutBuffer);
	EndIf;
	
	Return ParsingResponse(vOutBufferArr);
EndFunction // ExecuteProcessing

// --------------------------------------------------------------------------------
Function ParsingResponse(pOutBufferArr)
	vResponse = New Structure("TerminalNumber, AuthorizationCode, ReferenceNumber, MerchantID, CardNumber, CardType, CardExpiryDate, CardOperationDate, CardOperationTime, SlipText, ErrorCode, Error", "", "",, "", "", "", "", "", "", "", "", "", "");
	If pOutBufferArr.Count() <= 0 Then
		vResponse.ErrorCode ="-1000";
		vResponse.Error = NStr("en = 'No response from terminal'; de = 'Keine Antwort vom Terminal'; ru = 'Нет ответа от терминала'");
		Return vResponse;
	EndIf;
	
	vSuccess = False;
	For Each vOutBufferRow In pOutBufferArr Do
		vResponseCode = Left(vOutBufferRow, 2);
		If vResponseCode = "32" Then
			vResponse.SlipText = vResponse.SlipText + ?(StrLen(vResponse.SlipText) > 0, Chars.LF, "") + Right(vOutBufferRow, StrLen(vOutBufferRow) - 15);
		ElsIf vResponseCode = "5X" And Not vSuccess Then
			vResponse.TerminalNumber = Mid(vOutBufferRow, 3, 10);
			vResponse.ErrorCode = Mid(vOutBufferRow, 15, 2);
			vResponse.Error = Right(vOutBufferRow, StrLen(vOutBufferRow) - 16);
		ElsIf vResponseCode = "51" Then
			vResponse.TerminalNumber = Mid(vOutBufferRow, 3, 10);
			vResponse.ErrorCode = "51";
			vResponse.Error = "Требуется инициация рабочей сессии";
		ElsIf vResponseCode = "54" Then
			vResponse.TerminalNumber = Mid(vOutBufferRow, 3, 10);
			vResponse.ErrorCode = "54";
			vResponse.Error = "Нет предыдущих транзакций с таким номером ссылки";
		ElsIf vResponseCode = "55" Then
			vResponse.TerminalNumber = Mid(vOutBufferRow, 3, 10);
			vResponse.ErrorCode = "55";
			vResponse.Error = "необходимо обнулить таймаут ожидания";
		ElsIf vResponseCode = "22" Then
			vResponse.TerminalNumber = Mid(vOutBufferRow, 3, 10);
		ElsIf vResponseCode = "60" Then
			vOutArr = StrSplit(vOutBufferRow, Char(27), True);
			For i = 0 To vOutArr.Count() - 1 Do
				If i = 0 Then
					vResponse.TerminalNumber = Mid(vOutArr[i], 3, 10);
					vResponse.CardOperationDate = Mid(vOutArr[i], 31, 8);
					vResponse.CardOperationTime = Mid(vOutArr[i], 39, 6);
					vResponse.MerchantID = Mid(vOutArr[i], 45, 15);
					vResponse.ReferenceNumber = Mid(vOutArr[i], 60, 12);
					vResponse.ErrorCode = Mid(vOutArr[i], 72, 2);
					If vResponse.ErrorCode = "00" Then
						vResponse.ErrorCode = "";
						vSuccess = True;
					EndIf;
					vResponse.AuthorizationCode = Right(vOutArr[i], StrLen(vOutArr[i]) - 73);
				ElsIf i = 1 Then
					vCardDetails = StrSplit(vOutArr[i], "=", True);
					vResponse.CardNumber = vCardDetails[0];
					If vCardDetails.Count() > 1 Then
						vResponse.CardExpiryDate = vCardDetails[1];
					EndIf;
				ElsIf i = 2 Then
					vResponse.CardType = TrimAll(StrReplace(vOutArr[i], "*", ""));
				ElsIf i = 3 Then
					vResponse.Error = vOutArr[i];
					If IsBlankString(vResponse.ErrorCode) Or vResponse.ErrorCode = "00" Then
						vResponse.Error = "";
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	Return vResponse;
EndFunction // ParsingResponse

// --------------------------------------------------------------------------------
Procedure AfterServiceFunctionsMenuSelection(vUCItem, vExtraParams) Export
	If vUCItem = Undefined Then
		Return;
	EndIf;
	
	Try
		vPaymentTerminalArr = vExtraParams.PaymentTerminalArr;
		vCashRegisterArr = vExtraParams.CashRegisterArr;
		vPC = vExtraParams.PC;
		
		If vUCItem.Value = 1 Then
			ReconcileTotals(vPC, vCashRegisterArr, vPaymentTerminalArr);
			Return;
		EndIf;
		
		vTimeout = vPaymentTerminalArr.Timeout;
		If vTimeout <= 2000 Then
			vTimeout = 2000;
		EndIf;
		
		vMessage = "";
		If Not Login(vPC, vPaymentTerminalArr, vMessage) Then
			ShowMessageBox(,
				StrTemplate(
					NStr("en = 'Terminal connection error!
					|Error: %1'; de = 'Terminalverbindungsfehler!
					|Fehler: %1'; ru = 'Ошибка подключения к терминалу!
					|Error: %1'"),
					vMessage
				)
			);
			Return;
		EndIf;
		
		vPC.Wait(vTimeout);
		
		vInBuffer =
		StrTemplate(
			"%1%2%3%4",
			"25",
			Format(Number(vPaymentTerminalArr.TerminalNumber), "ND=10; NZ=0; NLZ=; NG="),
			"01",
			Format(vUCItem.Value, "NFD=0; NZ=0; NG=")
		);
		
		vMessage = "";
		vResponse = ExecuteProcessing(vPC, vInBuffer, vMessage);
		If Not ProcessResultCode(vPC, vResponse.ErrorCode, vResponse.Error, vMessage) Then
			ShowMessageBox(,
				StrTemplate(
					NStr("en = 'Execution error!
					|Error: %1'; de = 'Laufzeitfehler!
					|Fehler: %1'; ru = 'Ошибка выполнения!
					|Error: %1'"),
					vMessage
				)
			);
			Return;
		EndIf;
		
		If Not vPaymentTerminalArr.PrintSlipInCheque And 
			Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vResponse.SlipText) Then
			vSlipTxtArr = GetTextLinesArray(vResponse.SlipText);
			PrintSlipDocument(vSlipTxtArr, vCashRegisterArr);
		EndIf;
		
		ShowMessageBox(, NStr("en='The operation was completed successfully!'; de='Der Vorgang wurde erfolgreich abgeschlossen!'; ru='Операция выполнена успешно!'"));
		Disconnect(vPC);
	Except
		vMessage = BriefErrorDescription(ErrorInfo());
		ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AfterServiceFunctionsMenuSelection'; de='CreditCardProcessingSystem.AfterServiceFunctionsMenuSelection'; ru='СистемаПроцессингаКредитныхКарт.ServiceFunctionsMenu'"), vMessage);
		ShowMessageBox(,
			StrTemplate(
				NStr("en = 'Execution error!
				|Error: %1'; de = 'Laufzeitfehler!
				|Fehler: %1'; ru = 'Ошибка выполнения!
				|Error: %1'"),
				vMessage
			)
		);
	EndTry;
EndProcedure // AfterServiceFunctionsMenuSelection

// --------------------------------------------------------------------------------
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
EndProcedure // AfterShowFileDialog

// --------------------------------------------------------------------------------
Function ProcessResultCode(pFR, pRC, pErrorrMessage, rMessage, pSkipDisconnect = False)
	If IsBlankString(pRC) Then
		Return True;
	EndIf;
	
	rMessage = "Result code: " + pRC + ", " + NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '");
	If Not IsBlankString(pErrorrMessage) Then
		rMessage = rMessage + pErrorrMessage;
	Else
		rMessage = rMessage + NStr("en = 'Driver error'; de = 'Treiberfehler'; ru = 'Ошибка драйвера'");
	EndIf;
	
	If Not pSkipDisconnect Then
		Disconnect(pFR);
	EndIf;
	Return False;
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
Procedure PrintSlipDocument(pSlipTextArr, pCashRegister)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If vDriver = Undefined Then
		ShowMessageBox(,Nstr("en = 'Printing is not supported for this cash register!'; ru = 'Печать на ленте не поддерживается для вашей ККМ!'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;
	
	vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,pCashRegister);
	If Not IsBlankString(vPasswordKKM) Then
		vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, True);
		Return;
	EndIf;
	
	vQuestion = 
	NStr(
		"ru='Пожалуйста введите пароль ККМ...';
		|de='Input cash register password please...';
		|en='Input cash register password please...'"
	);
	
	vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverUCSNative, New Structure("Driver, Message, CashRegister, SlipTextArr", vDriver, rMessage, pCashRegister, pSlipTextArr));
	// Ask for password
	OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion),,,,,vNotifity);
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.Message;
	If pValue = Undefined Then
		Return;
	EndIf;
	
	vDriver.pmPrintSlip(pAdditionalParameters.SlipTextArr, pAdditionalParameters.CashRegister, vMessage, pValue.Password, True);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
EndProcedure // AfterInputCashRegisterPassword

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function GetCardType(pCardType, pObj)
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
	If Not IsBlankString(pCardType) Then
		vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(pCardType);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

#EndRegion