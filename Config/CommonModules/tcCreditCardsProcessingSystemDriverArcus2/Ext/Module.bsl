
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
	vComObj = Connect(rMessage);
	If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
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
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vComObj.Request.Amount = pSum * 100;
				vCreditCard = PredefinedValue("Catalog.CreditCards.EmptyRef");
				// Do payment
				If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
					vComObj.Request.Last4Digits = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "PANLast4Digits"));
					vComObj.Request.ReferenceNumber = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"));
					vComObj.Request.AuthorizationCode = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "AuthorizationCode");
					vCreditCard = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "CreditCard");
					vComObj.Request.OperationCode = ?(pPaymentTerminal.ComputationCommandCode <> 0, pPaymentTerminal.ComputationCommandCode, 6); // Close preauthorization
				Else
					vCreditCard = pObj.CreditCard;
					vComObj.Request.OperationCode = ?(pPaymentTerminal.PaymentCommandCode <> 0, pPaymentTerminal.PaymentCommandCode, 1); // Payment
				EndIf;
				If ValueIsFilled(vCreditCard) Then
					vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
					If CheckFilledEncData(vEncData) Then
						vComObj.Request.EncData = vEncData; 		
					EndIf;
					vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
					vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
					If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
						vComObj.Request.PAN = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
						vComObj.Request.CardExpiryDate = Format(tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate"), "DF=yyMM");
					EndIf;
					vComObj.Request.CVV2 = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardSecurityCode");
				EndIf;
	  			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
				If Not ProcessResultCode(vComObj, vRC, rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
			Else
				// Try to fill payment RRN, AuthCode and encripted card data
				vComObj.Request.ReferenceNumber = "";
				vComObj.Request.AuthorizationCode = "";
				vComObj.Request.TrxIDCRM = "";
				vComObj.Request.Last4Digits = "";
				vComObj.Request.EncData = ""; 		
				vComObj.Request.PAN = "";
				vComObj.Request.CardExpiryDate = "";
				vComObj.Request.CVV2 = "";
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
						vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
						If Not ValueIsFilled(vPayment) Then
							Break;
						EndIf;
					EndDo;
					If ValueIsFilled(vPayment) Then
						vComObj.Request.ReferenceNumber = tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber");
						vComObj.Request.AuthorizationCode = tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode");
						vComObj.Request.TrxIDCRM = tcOnServer.cmGetAttributeByRef(vPayment, "ReceiptNumber");
						vComObj.Request.Last4Digits = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "PANLast4Digits"));
						vCreditCard = tcOnServer.cmGetAttributeByRef(vPayment, "CreditCard");
						If ValueIsFilled(vCreditCard) Then
							vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
							If CheckFilledEncData(vEncData) Then
								vComObj.Request.EncData = vEncData; 		
							EndIf;
							vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
							vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
							If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
								vComObj.Request.PAN = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
								vComObj.Request.CardExpiryDate = Format(tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate"), "DF=yyMM");
							EndIf;
							vComObj.Request.CVV2 = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardSecurityCode");
						EndIf;
					EndIf;
				EndIf;
				// Set operation currency code
				If ValueIsFilled(pObj.PaymentCurrency) Then
					vComObj.Request.CurrencyCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
				Else
					vComObj.Request.CurrencyCode = "643";	
				EndIf;
				// Set amount
				vComObj.Request.Amount = -pSum * 100;
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPayment'; de='CreditCardProcessingSystem.CancelPayment'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
				// Try Cancel payment
				vComObj.Request.OperationCode = ?(pPaymentTerminal.CancelCommandCode <> 0, pPaymentTerminal.CancelCommandCode, 4);
				vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
				vReturn = False;
				If Not ProcessResultCode(vComObj, vRC, rMessage, True, vReturn) Then
					If vReturn Then
						Return False;	
					EndIf;
					// Log payment
					tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
					// Do return
					vComObj.Request.OperationCode = ?(pPaymentTerminal.ReturnCommandCode <> 0, pPaymentTerminal.ReturnCommandCode, 3);
					vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
					If Not ProcessResultCode(vComObj, vRC, rMessage) Then
						Return False;
					EndIf;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),,,,vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
			EndIf;
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData And CheckFilledEncData(vComObj.Response.EncData) Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardRef(pObj, vComObj.Response.PAN, vComObj.Response.PAN, vComObj.Response.EncData, vComObj.Response.PaymentDetails, tcCreditCardsProcessingSystemDriverAtServer.GetDateFromString(vComObj.Response.CardExpiryDate, "yyMM"));
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
				EndIf;
			EndIf; 
			pObj.CardType = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vComObj.Response.PaymentDetails);
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.PANLast4Digits = vComObj.Response.Last4Digits; 
			pObj.TerminalNumber  = vComObj.Response.TerminalOutID;
			pObj.ReceiptNumber = vComObj.Response.TrxIDCRM;
			Try
				pObj.CardOperationDate = vComObj.Response.DateTimeHost;
			Except
			EndTry;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			// Disconnect
			Disconnect(vComObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
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
	vComObj = Connect(rMessage);
	If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
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
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
				If CheckFilledEncData(vEncData) Then
					vComObj.Request.EncData = vEncData; 		
				EndIf;
				vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
				vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
				If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
					vComObj.Request.PAN = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
					vComObj.Request.CardExpiryDate = Format(tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate"), "DF=yyMM");
				EndIf;
				vComObj.Request.CVV2 = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardSecurityCode");
			EndIf;
			// Do operation
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			// Set amount
			vComObj.Request.Amount = pSum * 100;
			// Do payment
			vComObj.Request.OperationCode = ?(pPaymentTerminal.PreauthorisationCommandCode <> 0, pPaymentTerminal.PreauthorisationCommandCode, 5);
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
			If Not ProcessResultCode(vComObj, vRC, rMessage) Then
				Return False;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vComObj.Response.ReferenceNumber;
			vAuthorizationCode = vComObj.Response.AuthorizationCode;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),,,,vMessage);
			// Get slip
			vOutSlip = vComObj.Response.SLIP;
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData And CheckFilledEncData(vComObj.Response.EncData) Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardRef(pObj, vComObj.Response.PAN, vComObj.Response.PAN, vComObj.Response.EncData, vComObj.Response.PaymentDetails, tcCreditCardsProcessingSystemDriverAtServer.GetDateFromString(vComObj.Response.CardExpiryDate, "yyMM"));
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
				EndIf;
			EndIf; 
			pObj.CardType = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vComObj.Response.PaymentDetails);
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.PANLast4Digits = vComObj.Response.Last4Digits;
			pObj.TerminalNumber  = vComObj.Response.TerminalOutID;
			pObj.ReceiptNumber = vComObj.Response.TrxIDCRM;
			Try
				pObj.CardOperationDate = vComObj.Response.DateTimeHost;
			Except EndTry;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			// Disconnect
			Disconnect(vComObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
// Parameters:
//  pSum			 - Number	 - Sum
//  pObj			 - DocumentObject - Document object 
//  rMessage		 - String	 - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	// Try to connect
	vComObj = Connect(rMessage);
	If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
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
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code"));
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			// Set RNN
			vComObj.Request.ReferenceNumber = pObj.ReferenceNumber;
			vComObj.Request.AuthorizationCode = pObj.AuthorizationCode;
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vEncData = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardDataEnc");
				If CheckFilledEncData(vEncData) Then
					vComObj.Request.EncData = vEncData; 		
				EndIf;
				vCardNumber = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
				vCardValidTillDate = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate");
				If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
					vComObj.Request.PAN = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardNumber");
					vComObj.Request.CardExpiryDate = Format(tcOnServer.cmGetAttributeByRef(vCreditCard, "CardValidTillDate"), "DF=yyMM");
				EndIf;
				vComObj.Request.CVV2 = tcOnServer.cmGetAttributeByRef(vCreditCard, "CardSecurityCode");
			EndIf;
			vComObj.Request.TrxIDCRM = pObj.ReceiptNumber; 
			// Do operation
			If pSum > 0 Then
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				// Set amount
				vComObj.Request.Amount = pSum * 100;
				vComObj.Request.Last4Digits = pObj.PANLast4Digits;
				vComObj.Request.OperationCode = ?(pPaymentTerminal.CancelCommandCode <> 0, pPaymentTerminal.CancelCommandCode, 4);
				vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
				If Not ProcessResultCode(vComObj, vRC, rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"),,,,vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
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
			Disconnect(vComObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
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
//  rMessage		 - String	 - 
//  pCashRegister	 - Structure - Params Cash register 
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
// Boolean  - Result 
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
	vComObj = Connect(rMessage);
	If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
		Return False;
	Else
		vUCList = New ValueList();
		vUCList.Add(?(vPaymentTerminalArr.ShortXReportCommandCode <> 0, vPaymentTerminalArr.ShortXReportCommandCode, 8), NStr("en='Summary of transactions'; ru='Краткий отчет по операциям'; de='Zusammenfassung der Transaktionen'"));
		vUCList.Add(?(vPaymentTerminalArr.FullXReportCommandCode <> 0, vPaymentTerminalArr.FullXReportCommandCode, 7), NStr("en='Complete transaction report'; ru='Полный отчет по операциям'; de='Vollständiger Transaktionsbericht'"));
		vUCList.Add(?(vPaymentTerminalArr.CashierMenuCommandCode <> 0, vPaymentTerminalArr.CashierMenuCommandCode, 98), NStr("en = 'Menu cashier'; de = 'Menu cashier'; ru = 'Меню кассира'"));
		vUCList.Add(?(vPaymentTerminalArr.AdminMenuCommandCode <> 0, vPaymentTerminalArr.AdminMenuCommandCode, 99), NStr("en = 'Menu admin'; de = 'Menu admin'; ru = 'Меню администратора'"));
		vUCList.Add(?(vPaymentTerminalArr.TotalsReconciliationCommandCode <> 0, vPaymentTerminalArr.TotalsReconciliationCommandCode, 10), NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
		vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverArcus2, New Structure("ComObj, CashRegisterArr, PaymentTerminalArr", vComObj, vCashRegisterArr, vPaymentTerminalArr)));
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
		vMessage = "";
		vPaymentTerminalArr = vExtraParams.PaymentTerminalArr;
		vCashRegisterArr = vExtraParams.CashRegisterArr;
		Try
			// X report 
			vComObj = vExtraParams.ComObj;
			vComObj.Request.OperationCode = vUCItem.Value;
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
			If Not ProcessResultCode(vComObj, vRC, vMessage) Then
				Return;
			EndIf;
			// Get slip
			vOutSlip = vComObj.Response.SLIP;
			// Print end of day slip
			If Not vPaymentTerminalArr.PrintSlipInCheque And 
			   Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vCashRegisterArr, True);
			EndIf;
			// Success
			If vUCItem.Value = vPaymentTerminalArr.ShortXReportCommandCode Or (vUCItem.Value = 8 And vPaymentTerminalArr.ShortXReportCommandCode = 0) Then
				vMessage = NStr("en='Operation summary printing operation completed successfully!'; ru='Операция печати краткого отчета по операциям выполнена успешно!'; de='Vorgang Zusammenfassung Druckvorgang erfolgreich abgeschlossen!'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.FullXReportCommandCode Or (vUCItem.Value = 7 And vPaymentTerminalArr.FullXReportCommandCode = 0) Then
				vMessage = NStr("en = 'The operation to print the complete activity report was successful!'; de = 'Der Vorgang zum Drucken des vollständigen Aktivitätsberichts war erfolgreich!'; ru = 'Операция печати полного отчета по операциям выполнена успешно!'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.CashierMenuCommandCode Or (vUCItem.Value = 98 And vPaymentTerminalArr.CashierMenuCommandCode = 0) Then
				vMessage = NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.AdminMenuCommandCode Or (vUCItem.Value = 99 And vPaymentTerminalArr.AdminMenuCommandCode = 0) Then
				vMessage = NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.TotalsReconciliationCommandCode Or (vUCItem.Value = 10 And vPaymentTerminalArr.TotalsReconciliationCommandCode = 0) Then
				vMessage = NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'");
			EndIf;
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
			Disconnect(vExtraParams.ComObj);
		Except
			vMessage = ErrorDescription();
			vFName = "";
			If vUCItem.Value = vPaymentTerminalArr.ShortXReportCommandCode Or (vUCItem.Value = 8 And vPaymentTerminalArr.ShortXReportCommandCode = 0) Then
				vFName = NStr("en='CreditCardProcessingSystem.XReportShort'; de='CreditCardProcessingSystem.XReportShort'; ru='СистемаПроцессингаКредитныхКарт.XОтчетКраткий'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.FullXReportCommandCode Or (vUCItem.Value = 7 And vPaymentTerminalArr.FullXReportCommandCode = 0) Then
				vFName = NStr("en='CreditCardProcessingSystem.XReportFull'; de='CreditCardProcessingSystem.XReportFull'; ru='СистемаПроцессингаКредитныхКарт.XОтчетПолный'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.CashierMenuCommandCode Or (vUCItem.Value = 98 And vPaymentTerminalArr.CashierMenuCommandCode = 0) Then
				vFName = NStr("en='CreditCardProcessingSystem.MenuCashier'; de='CreditCardProcessingSystem.MenuCashier'; ru='СистемаПроцессингаКредитныхКарт.MenuCashier'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.AdminMenuCommandCode Or (vUCItem.Value = 99 And vPaymentTerminalArr.AdminMenuCommandCode = 0) Then
				vFName = NStr("en='CreditCardProcessingSystem.MenuAdmin'; de='CreditCardProcessingSystem.MenuAdmin'; ru='СистемаПроцессингаКредитныхКарт.MenuAdmin'");
			ElsIf vUCItem.Value = vPaymentTerminalArr.TotalsReconciliationCommandCode Or (vUCItem.Value = 10 And vPaymentTerminalArr.TotalsReconciliationCommandCode = 0) Then
				vFName = NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'");
			EndIf;
			ProcessException(vFName, vMessage);
			// Disconnect
			Disconnect(vExtraParams.ComObj);
		EndTry;
	EndIf;
EndProcedure // AfterServiceFunctionsMenuSelection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPaymentTerminal - Structure - Params payment terminal 
//
Procedure pmCheckConnection(pPaymentTerminal) Export
	vMessage = "";
	If TypeOf(pPaymentTerminal) = Type("Structure") Then  
		vPaymentTerminalArr = pPaymentTerminal;
	Else 
		vPaymentTerminalArr =  tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	EndIf;
	// Try to connect
	Try
		vComObj = Connect(vMessage);
		If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
			tcCommonFunctionOnClientServer.TextMessage(vMessage);
			Return;
		Else	
			vComObj.Request.OperationCode = ?(vPaymentTerminalArr.ConnectionCheckCommandCode <> 0, vPaymentTerminalArr.ConnectionCheckCommandCode, 95);
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
			If Not ProcessResultCode(vComObj, vRC, vMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(vMessage);
				Return;
			EndIf;	
			tcCommonFunctionOnClientServer.TextMessage(vComObj.Response.TextResponse);
		EndIf;
	Except
		vMessage = ErrorDescription();
		ProcessException(NStr("en='CreditCardProcessingSystem.CheckConnection'; de='CreditCardProcessingSystem.CheckConnection'; ru='СистемаПроцессингаКредитныхКарт.ПроверкаПодключения'"), vMessage);
		// Disconnect
		Disconnect(vComObj);
	EndTry;
EndProcedure // pmCheckConnection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pComObj			 - ComObject - Driver
//  pCashRegister	 - Structure - Params Cash register 
//  pPaymentTerminal - Structure - Params payment terminal 
//  pResult			 - Boolean - Result operation
//
Procedure ReconcileTotals(pComObj = Undefined, pCashRegister, pPaymentTerminal, pResult = True) Export
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
		// Try to connect
		vComObj = pComObj; 
		If pComObj = Undefined Then
			vComObj = Connect(rMessage);
		EndIf;
		If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
			pResult = False;
			ShowMessageBox(,StrTemplate(NStr("en = 'Terminal connection error!
                                  |Error: %1'; de = 'Terminalverbindungsfehler!
                                  |Fehler: %1'; ru = 'Ошибка подключения к терминалу!
                                  |Error: %1'"), rMessage));
			Return;
		Else	
			vComObj.Request.OperationCode = ?(pPaymentTerminal.TotalsReconciliationCommandCode <> 0, pPaymentTerminal.TotalsReconciliationCommandCode, 10);
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
			If Not ProcessResultCode(vComObj, vRC, rMessage) Then
				ShowMessageBox(,StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));

				pResult = False;
				Return;
			EndIf;
			// Get slip
			vOutSlip = vComObj.Response.SLIP;
			// Print end of day slip
			If Not vPaymentTerminalArr.PrintSlipInCheque And 
			   Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vCashRegisterArr, True);
			EndIf;
			// Success
			ShowMessageBox(,NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));	
		EndIf;		
	Except
		rMessage = ErrorDescription();
		ProcessException(NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
		pResult = False;
		ShowMessageBox(,StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));

	EndTry;
EndProcedure // ReconcileTotals

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	vComObj = New Structure("Request, Response, POST", Undefined, Undefined, Undefined);
	// Reset return status
	rMessage = "";
	// Try to create external component
	#IF NOT MobileClient THEN
		Try
			vComObj.Request  = New COMObject("ArcCom.SAPacketObj.1");
		    vComObj.Response = New COMObject("ArcCom.SAPacketObj.1");
		    vComObj.POST     = New COMObject("ArcCom.PCPOSTConnectorObj.1");
		Except
			rMessage         = ErrorDescription();
			vComObj.Request  = Undefined;
			vComObj.Response = Undefined;
			vComObj.POST     = Undefined;
		EndTry;
	#ENDIF
	Return vComObj;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pComObj)
	Try
		pComObj.Request  = Undefined;
		pComObj.Response = Undefined;
		pComObj.POST     = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pComObj, pRC, rMessage, pSkipDisconnect = False, rReturn = False)
	If Number(pRC) <> 0 Or Number(pComObj.Response.ResponseCodeHost) <> 0 Then
		If Not pSkipDisconnect Or Number(pComObj.Response.ResponseCodeHost) = 201 Or Number(pRC) <> 0 Then
			If Number(pRC) <> 0 Then 
				vErrorDescription = pComObj.POST.ErrorDescription; 
				vCode = pRC;
			ELse
				vErrorDescription = pComObj.Response.TextResponse; 
				vCode = pComObj.Response.ResponseCodeHost; 	
			EndIf;
			rMessage = "Result code: " + TrimAll(vCode) + ", " + NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + vErrorDescription;
			Disconnect(pComObj);
			rReturn = True;
		EndIf;
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
EndFunction // GetTextLinesArray

// -----------------------------------------------------------------------------
Procedure ProcessException(pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction,,,, "Error description: " + rMessage);
EndProcedure // ProcessException

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
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverArcus2, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
			// Ask for password
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion),,,,,vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(Nstr("en = 'Printing is not supported for this cash register!'; ru = 'Печать на ленте не поддерживается для вашей ККМ!'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"));
		Return;
	EndIf;	
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Function CheckFilledEncData(pEncData)
	Return ValueIsFilled(pEncData) And pEncData <> "0000000000000000000000000000000000000000000000000000000000000000"; 
EndFunction //  CheckFilledEncData
  

#EndRegion

