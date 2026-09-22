
#Region Public

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
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
				Raise NStr("en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'; ru = 'Не указана сумма операции!'");
			EndIf;
			If pSum < 0 Then
				Raise NStr("en = 'Operation amount should be positive!'; de = 'Betriebsbetrag sollte positiv sein!'; ru = 'Сумма операции должна быть больше 0!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'; ru = 'Не указана валюта операции!'");
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(pObj.PaymentCurrency.Code);
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vEncData = vCreditCard.CardDataEnc;
				If CheckFilledEncData(vEncData) Then
					vComObj.Request.EncData = vEncData; 		
				EndIf;
				vCardNumber = vCreditCard.CardNumber;
				vCardValidTillDate = vCreditCard.CardValidTillDate;
				If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
					vComObj.Request.PAN = vCreditCard.CardNumber;
					vComObj.Request.CardExpiryDate = Format(vCreditCard.CardValidTillDate, "DF=yyMM");
				EndIf;
				vComObj.Request.CVV2 = vCreditCard.CardSecurityCode;
			EndIf;
			// Do operation
			// Log payment  
			WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			// Set amount
			vComObj.Request.Amount = pSum * 100;
			// Do payment
			vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.PreauthorisationCommandCode <> 0, CreditCardsProcessingSystemParameters.PreauthorisationCommandCode, 5);
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
			If Not ProcessResultCode(vComObj, vRC, rMessage) Then
				Return False;
			EndIf;
			// Get Reference number, Authorization code
			vReferenceNumber = vComObj.Response.ReferenceNumber;
			vAuthorizationCode = vComObj.Response.AuthorizationCode;
			// Log authorisation code and RRN
			vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , vMessage);
			// Get slip
			vOutSlip = vComObj.Response.SLIP;
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData And CheckFilledEncData(vComObj.Response.EncData) Then
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
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Disconnect
			Disconnect(vComObj);
			pObj.Write(DocumentWriteMode.Write);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
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
				Raise NStr("en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'; ru = 'Не указана сумма операции!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'; ru = 'Не указана валюта операции!'");
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(pObj.PaymentCurrency.Code);
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			// Do operation
			If pSum > 0 Then
				// Log payment
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				// Set amount
				vComObj.Request.Amount = pSum * 100;
				vCreditCard = PredefinedValue("Catalog.CreditCards.EmptyRef");
				// Do payment
				If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
					vComObj.Request.Last4Digits = TrimAll(pObj.Preauthorisation.PANLast4Digits);
					vComObj.Request.ReferenceNumber = TrimAll(pObj.Preauthorisation.ReferenceNumber);
					vComObj.Request.AuthorizationCode = pObj.Preauthorisation.AuthorizationCode;
					vCreditCard = pObj.Preauthorisation.CreditCard;
					vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.ComputationCommandCode <> 0, CreditCardsProcessingSystemParameters.ComputationCommandCode, 6); // Close preauthorization
				Else
					vCreditCard = pObj.CreditCard;
					vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.PaymentCommandCode <> 0, CreditCardsProcessingSystemParameters.PaymentCommandCode, 1); // Payment
				EndIf;
				If ValueIsFilled(vCreditCard) Then
					vEncData = vCreditCard.CardDataEnc;
					If CheckFilledEncData(vEncData) Then
						vComObj.Request.EncData = vEncData; 		
					EndIf;
					vCardNumber = vCreditCard.CardNumber;
					vCardValidTillDate = vCreditCard.CardValidTillDate;
					If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
						vComObj.Request.PAN = vCreditCard.CardNumber;
						vComObj.Request.CardExpiryDate = Format(vCreditCard.CardValidTillDate, "DF=yyMM");
					EndIf;
					vComObj.Request.CVV2 = vCreditCard.CardSecurityCode;
				EndIf;
	  			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
				If Not ProcessResultCode(vComObj, vRC, rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
			Else
				// Try annulate payment
				vComObj.Request.ReferenceNumber = pObj.Payment.ReferenceNumber;
				vComObj.Request.AuthorizationCode = pObj.Payment.AuthorizationCode;
				vComObj.Request.TrxIDCRM = pObj.Payment.ReceiptNumber;
				vCreditCard = pObj.Payment.CreditCard;
				If ValueIsFilled(vCreditCard) Then
					vEncData = vCreditCard.CardDataEnc;
					If CheckFilledEncData(vEncData) Then
						vComObj.Request.EncData = vEncData; 		
					EndIf;
					vCardNumber = vCreditCard.CardNumber;
					vCardValidTillDate = vCreditCard.CardValidTillDate;
					If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
						vComObj.Request.PAN = vCreditCard.CardNumber;
						vComObj.Request.CardExpiryDate = Format(vCreditCard.CardValidTillDate, "DF=yyMM");
					EndIf;
					vComObj.Request.CVV2 = vCreditCard.CardSecurityCode;
				EndIf;
				// Set operation currency code
				If ValueIsFilled(pObj.PaymentCurrency) Then
					vComObj.Request.CurrencyCode = TrimAll(pObj.PaymentCurrency.Code);
				Else
					vComObj.Request.CurrencyCode = "643";	
				EndIf;
				// Set amount
				vComObj.Request.Amount = -pSum * 100;
				vComObj.Request.Last4Digits = TrimAll(pObj.Payment.PANLast4Digits);
				// Log payment 
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.CancelPayment'; de = 'CreditCardProcessingSystem.CancelPayment'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
				// Try Cancel payment
				vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.CancelCommandCode <> 0, CreditCardsProcessingSystemParameters.CancelCommandCode, 4);
				vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
				vReturn = False;
				If Not ProcessResultCode(vComObj, vRC, rMessage, True, vReturn) Then
					If vReturn Then
						Return False;	
					EndIf;
					// Log payment
					WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.ReturnPayment'; de = 'CreditCardProcessingSystem.ReturnPayment'; ru = 'СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
					// Do return
					vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.ReturnCommandCode <> 0, CreditCardsProcessingSystemParameters.ReturnCommandCode, 3);
					vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15);
					If Not ProcessResultCode(vComObj, vRC, rMessage) Then
						Return False;
					EndIf;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.ReturnPayment'; de = 'CreditCardProcessingSystem.ReturnPayment'; ru = 'СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), ,vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
			EndIf;
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData And CheckFilledEncData(vComObj.Response.EncData) Then
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
			pObj.Write(DocumentWriteMode.Write);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Disconnect
			Disconnect(vComObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(pObj, rMessage) Export	
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
			vSum = pObj.Sum;
			If vSum = 0 Then
				Raise NStr("en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'; ru = 'Не указана сумма операции!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'; ru = 'Не указана валюта операции!'");
			EndIf;
			// Set operation currency code
			If ValueIsFilled(pObj.PaymentCurrency) Then
				vComObj.Request.CurrencyCode = TrimAll(pObj.PaymentCurrency.Code);
			Else
				vComObj.Request.CurrencyCode = "643";	
			EndIf;
			// Set RNN
			vComObj.Request.ReferenceNumber = pObj.ReferenceNumber;
			vComObj.Request.AuthorizationCode = pObj.AuthorizationCode;
			vCreditCard = pObj.CreditCard;
			If ValueIsFilled(vCreditCard) Then
				vEncData = vCreditCard.CardDataEnc;
				If CheckFilledEncData(vEncData) Then
					vComObj.Request.EncData = vEncData; 		
				EndIf;
				vCardNumber = vCreditCard.CardNumber;
				vCardValidTillDate = vCreditCard.CardValidTillDate;
				If ValueIsFilled(vCardNumber) And ValueIsFilled(vCardValidTillDate) Then 
					vComObj.Request.PAN = vCreditCard.CardNumber;
					vComObj.Request.CardExpiryDate = Format(vCreditCard.CardValidTillDate, "DF=yyMM");
				EndIf;
				vComObj.Request.CVV2 = vCreditCard.CardSecurityCode;
			EndIf;
			vComObj.Request.TrxIDCRM = pObj.ReceiptNumber; 
			// Do operation
			If vSum > 0 Then
				// Log payment
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + vSum);
				// Set amount
				vComObj.Request.Amount = vSum * 100;
				vComObj.Request.Last4Digits = pObj.PANLast4Digits;
				vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.CancelCommandCode <> 0, CreditCardsProcessingSystemParameters.CancelCommandCode, 4);
				vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
				If Not ProcessResultCode(vComObj, vRC, rMessage) Then
					Return False;
				EndIf;
				// Get Reference number, Authorization code
				vReferenceNumber = vComObj.Response.ReferenceNumber;
				vAuthorizationCode = vComObj.Response.AuthorizationCode;
				// Log authorisation code and RRN
				vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , vMessage);
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
			EndIf;
			// Change preauthorization status if there are no erros
			pObj.Status = Enums.PreauthorisationStatuses.Cancelled;
			pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" +  vReferenceNumber + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.AuthorOfCancellation = SessionParameters.CurrentUser;
			pObj.DateOfCancellation =  CurrentSessionDate(); 
			pObj.Write(DocumentWriteMode.Posting);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Disconnect
			Disconnect(vComObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
			// Disconnect
			Disconnect(vComObj);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	Return pmAuthorizePayment(-pSum, -pVATSum, pObj, rMessage);
EndFunction // pmAnnulatePayment

// -----------------------------------------------------------------------------
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister) Export
	rMessage = "";
	// Try to connect
	vComObj = Connect(rMessage);
	If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
		Return False;
	Else
		vUCList = New ValueList();
		vUCList.Add(?(CreditCardsProcessingSystemParameters.ShortXReportCommandCode <> 0, CreditCardsProcessingSystemParameters.ShortXReportCommandCode, 8), NStr("en = 'Summary of transactions'; de = 'Zusammenfassung der Transaktionen'; ru = 'Краткий отчет по операциям'"));
		vUCList.Add(?(CreditCardsProcessingSystemParameters.FullXReportCommandCode <> 0, CreditCardsProcessingSystemParameters.FullXReportCommandCode, 7), NStr("en = 'Complete transaction report'; de = 'Vollständiger Transaktionsbericht'; ru = 'Полный отчет по операциям'"));
		vUCList.Add(?(CreditCardsProcessingSystemParameters.CashierMenuCommandCode <> 0, CreditCardsProcessingSystemParameters.CashierMenuCommandCode, 98), NStr("en = 'Menu cashier'; de = 'Menu cashier'; ru = 'Меню кассира'"));
		vUCList.Add(?(CreditCardsProcessingSystemParameters.AdminMenuCommandCode <> 0, CreditCardsProcessingSystemParameters.AdminMenuCommandCode, 99), NStr("en = 'Menu admin'; de = 'Menu admin'; ru = 'Меню администратора'"));
		vUCList.Add(?(CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode <> 0, CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode, 10), NStr("en = 'Z-Report (reconcile totals)'; de = 'Z-Bericht (Summen abgleichen)'; ru = 'Z-Отчет (сверка итогов)'"));
		vUCItem = vUCList.ChooseItem();	 
		If vUCItem <> Undefined Then
			Try
				// X report 
				vComObj.Request.OperationCode = vUCItem.Value;
				vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
				If Not ProcessResultCode(vComObj, vRC, rMessage) Then 
					// Disconnect
					Disconnect(vComObj);
					Return False;
				EndIf;
				// Get slip
				vOutSlip = vComObj.Response.SLIP;
				// Print end of day slip
				If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
				   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
				   Not IsBlankString(vOutSlip) Then
					vSlipTxtArr = GetTextLinesArray(vOutSlip);
					PrintSlipDocument(vSlipTxtArr, New Structure("CashRegister", pCashRegister));
				EndIf;
				// Success
				If vUCItem.Value = CreditCardsProcessingSystemParameters.ShortXReportCommandCode Or (vUCItem.Value = 8 And CreditCardsProcessingSystemParameters.ShortXReportCommandCode = 0) Then
					rMessage = NStr("en = 'Operation summary printing operation completed successfully!'; de = 'Vorgang Zusammenfassung Druckvorgang erfolgreich abgeschlossen!'; ru = 'Операция печати краткого отчета по операциям выполнена успешно!'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.FullXReportCommandCode Or (vUCItem.Value = 7 And CreditCardsProcessingSystemParameters.FullXReportCommandCode = 0) Then
					rMessage = NStr("en = 'The operation to print the complete activity report was successful!'; de = 'Der Vorgang zum Drucken des vollständigen Aktivitätsberichts war erfolgreich!'; ru = 'Операция печати полного отчета по операциям выполнена успешно!'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.CashierMenuCommandCode Or (vUCItem.Value = 98 And CreditCardsProcessingSystemParameters.CashierMenuCommandCode = 0) Then
					rMessage = NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.AdminMenuCommandCode Or (vUCItem.Value = 99 And CreditCardsProcessingSystemParameters.AdminMenuCommandCode = 0) Then
					rMessage = NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode Or (vUCItem.Value = 10 And CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode = 0) Then
					rMessage = NStr("en = 'Totals check (settlement) operation completed successfully!'; de = 'Totals check (settlement) operation completed successfully!'; ru = 'Операция сверки итогов выполнена успешно!'");
				EndIf;
				Disconnect(vComObj);
			Except
				rMessage = ErrorDescription();
				vFName = "";
				If vUCItem.Value = CreditCardsProcessingSystemParameters.ShortXReportCommandCode Or (vUCItem.Value = 8 And CreditCardsProcessingSystemParameters.ShortXReportCommandCode = 0) Then
					vFName = NStr("en = 'CreditCardProcessingSystem.XReportShort'; de = 'CreditCardProcessingSystem.XReportShort'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетКраткий'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.FullXReportCommandCode Or (vUCItem.Value = 7 And CreditCardsProcessingSystemParameters.FullXReportCommandCode = 0) Then
					vFName = NStr("en = 'CreditCardProcessingSystem.XReportFull'; de = 'CreditCardProcessingSystem.XReportFull'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетПолный'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.CashierMenuCommandCode Or (vUCItem.Value = 98 And CreditCardsProcessingSystemParameters.CashierMenuCommandCode = 0) Then
					vFName = NStr("en = 'CreditCardProcessingSystem.MenuCashier'; de = 'CreditCardProcessingSystem.MenuCashier'; ru = 'СистемаПроцессингаКредитныхКарт.MenuCashier'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.AdminMenuCommandCode Or (vUCItem.Value = 99 And CreditCardsProcessingSystemParameters.AdminMenuCommandCode = 0) Then
					vFName = NStr("en = 'CreditCardProcessingSystem.MenuAdmin'; de = 'CreditCardProcessingSystem.MenuAdmin'; ru = 'СистемаПроцессингаКредитныхКарт.MenuAdmin'");
				ElsIf vUCItem.Value = CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode Or (vUCItem.Value = 10 And CreditCardsProcessingSystemParameters.TotalsReconciliationCommandCode = 0) Then
					vFName = NStr("en = 'CreditCardProcessingSystem.Settlement'; de = 'CreditCardProcessingSystem.Settlement'; ru = 'СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'");
				EndIf;
				ProcessException(vFName, rMessage);
				// Disconnect
				Disconnect(vComObj);
				Return False;
			EndTry;
		EndIf;
	EndIf;
	Return True;	
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage, pSettingsObj = Undefined) Export
	rMessage = "";
	// Try to connect
	Try
		vComObj = Connect(rMessage);
		If vComObj.Request = Undefined Or vComObj.Response = Undefined Or vComObj.POST = Undefined Then
			Return False;
		Else	
			vComObj.Request.OperationCode = ?(CreditCardsProcessingSystemParameters.ConnectionCheckCommandCode <> 0, CreditCardsProcessingSystemParameters.ConnectionCheckCommandCode, 95);
			vRC = vComObj.POST.Exchange(vComObj.Request, vComObj.Response, 15); 
			If Not ProcessResultCode(vComObj, vRC, rMessage) Then 
				Disconnect(vComObj);
				Return False;
			EndIf;	 
			Disconnect(vComObj);
			Return True;
		EndIf;
	Except
		vMessage = ErrorDescription();
		ProcessException(NStr("en = 'CreditCardProcessingSystem.CheckConnection'; de = 'CreditCardProcessingSystem.CheckConnection'; ru = 'СистемаПроцессингаКредитныхКарт.ПроверкаПодключения'"), vMessage);
		// Disconnect
		Disconnect(vComObj);
		Return False;
	EndTry;
EndFunction // pmCheckConnection

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	vComObj = New Structure("Request, Response, POST", Undefined, Undefined, Undefined);
	// Reset return status
	rMessage = "";
	// Try to create external component
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
			rMessage = "Result code: " + TrimAll(vCode) + ", " + NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + vErrorDescription;
			Disconnect(pComObj);
			rReturn = True;
		EndIf;
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pObj)
	vStatus = False;
	rMessage = "";
	If ValueIsFilled(pObj.CashRegister) Then
		vCashRegisterProcessor = cmGetCashRegisterDataProcessor(pObj.CashRegister);
		vStatus = vCashRegisterProcessor.pmPrintSlip(pSlipTextArr, Undefined, rMessage);
	Else
		rMessage = NStr("en = 'Cash register is not specified!'; de = 'Cash register is not specified!'; ru = 'Не выбран ККМ для печати!'");
	EndIf;
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Function CheckFilledEncData(pEncData)
	Return ValueIsFilled(pEncData) And pEncData <> "0000000000000000000000000000000000000000000000000000000000000000"; 
EndFunction //  CheckFilledEncData

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

#EndRegion
