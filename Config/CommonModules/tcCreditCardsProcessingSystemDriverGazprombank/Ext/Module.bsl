
#Region Public

// -----------------------------------------------------------------------------  
//
// Parameters:
//  pSum			 - Number - Sum
//  pVATSum			 - Number - Vat sum
//  pObj			 - DocumentObject - Document object 
//  pMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, pMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(pMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber 	= "";
			vAuthorizationCode 	= "";
			vCardNumber 		= "";
			vReceiptNumber 		= "";
			vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
			If vDeviceID = Undefined Then
				Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
			EndIf;

			vOutSlip 			= "";

			// Check payment amount
			If pSum = 0 Then
				Raise NStr("en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'; ru = 'Не указана сумма авторизации!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("en = 'Authorization currency is not filled!'; de = 'Authorization currency is not filled!'; ru = 'Не указана валюта авторизации!'");
			EndIf;

			// Do operation
			If pSum > 0 Then
				// Call processing
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
				If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
					vReferenceNumber = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"); 
					vRC = vPC.AuthConfirmationByPaymentCard(vDeviceID, vCardNumber, Format(pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				Else
					// Payment
					vReceiptNumber  = "9999999999";
					vRC = vPC.PayByPaymentCard(vDeviceID, vCardNumber, Format(pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				EndIf; 
				
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), pMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; 
								|de = 'On-line authorization processed with authorization code/RRN: '; 
								|ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , vMessage);
			Else
				vAnnulated = False;
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
						vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
						If Not ValueIsFilled(vPayment) Then
							Break;
						EndIf;
					EndDo;
				EndIf;
				// Log payment
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"),  ,  , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") +  -pSum );
				If ValueIsFilled(vPayment) And tcOnServer.cmGetAttributeByRef(vPayment, "Sum") = pObj.Sum Then
					// Try annulate payment
					vReferenceNumber = tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber");
					vAuthorizationCode  = tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode");
					vReceiptNumber  = tcOnServer.cmGetAttributeByRef(vPayment, "ReceiptNumber");
					If Not IsBlankString(vReferenceNumber) And Not IsBlankString(vAuthorizationCode) Then 
						vRC = vPC.CancelPaymentByPaymentCard(vDeviceID, vCardNumber, Format(-pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
						If ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.AnnulatePayment'; de = 'CreditCardProcessingSystem.AnnulatePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"), pMessage) Then
							vAnnulated = True;
							vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
							tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelAuthorisation'; de = 'CreditCardProcessingSystem.CancelAuthorisation'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), , , , vMessage);
						EndIf;
					EndIf;	
				EndIf;	
				// If not annulated then return
				If vAnnulated = False Then
					vReferenceNumber 	= "";
					vAuthorizationCode 	= "";
					vReceiptNumber  = "";
					vRC = vPC.ReturnPaymentByPaymentCard(vDeviceID, vCardNumber, Format(-pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), pMessage) Then
						Return False;
					EndIf;
				EndIf;	
				// Log authorisation code and RRN
				vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; 
								|de = 'On-line authorization processed with authorization code/RRN: '; 
								|ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), , , , vMessage);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.ReceiptNumber = vReceiptNumber;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;

			Disconnect(vPC);
			Return True;
		Except
			pMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), pMessage);
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pSum			 - Number - Sum
//  pVATSum			 - Number - Vat sum
//  pObj			 - DocumentObject - Document object 
//  pMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, pMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(pMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
			If vDeviceID = Undefined Then
				Raise NStr("en = 'We could not determine the device ID!'; 
						   |de = 'Wir konnten die Gerätenummer nicht ermitteln!'; 
						   |ru = 'Не смогли определить ID устройства!'");
			EndIf;
			vOutSlip 			= "";
			vCardNumber         = "";
			vReceiptNumber      = "9999999999";
			vReferenceNumber 	= TrimAll(pObj.ReferenceNumber);
			vAuthorizationCode  = TrimAll(pObj.AuthorizationCode);
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("en = 'Zero sum annulation is not possible!'; de = 'Zero sum annulation is not possible!'; ru = 'Не указана сумма аннуляции!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта аннуляции!'; en = 'Annulation currency is not filled!'; de = 'Annulation currency is not filled!'");
			EndIf;
			// Check reference number
			If IsBlankString(vReferenceNumber) Then
				Raise NStr("ru = 'В платеже не указан референс номер операции оплаты!'; en = 'Payment reference number is empty!'; de = 'Payment reference number is empty!'");
			EndIf;
			// Call processing
			// Log payment
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			vRC = vPC.CancelPaymentByPaymentCard(vDeviceID, vCardNumber, Format(pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), pMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; 
							|de = 'On-line authorization processed with authorization code/RRN: '; 
							|ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelAuthorisation'; de = 'CreditCardProcessingSystem.CancelAuthorisation'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), , , , vMessage);
			// Save main authorization attributes to the payment document
			If TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
				pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vReferenceNumber;
				pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			Else
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + "Ref. #" + vReferenceNumber;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + Chars.LF + vOutSlip;
			EndIf;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;

			Disconnect(vPC);
			Return True;
		Except
			pMessage = ErrorDescription();
			ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), pMessage);
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulatePayment

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pSum			 - Number - Sum
//  pObj			 - DocumentObject - Document object 
//  pMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmPreauthorization(Val pSum, pObj, pMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(pMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber 	= TrimAll(pObj.ReferenceNumber);
			vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
			If vDeviceID = Undefined Then
				Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
			EndIf;
			vOutSlip 			= "";
			vCardNumber         = "";
			vReceiptNumber      = "9999999999";
			vAuthorizationCode  = "";

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
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			vRC = vPC.AuthorisationByPaymentCard(vDeviceID, vCardNumber, Format(pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), pMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			vMessage = NStr("ru = 'Выполнена on-line преавторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with preauthorization code/RRN: '; de = 'On-line authorization processed with preauthorization code/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"),,,,vMessage);
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = vOutSlip;
			pObj.ReceiptNumber = vReceiptNumber;

			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
			EndIf;
			Disconnect(vPC);
			Return True;
		Except
			pMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), pMessage);
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
//  pMessage		 - String - Error message
//  pPaymentTerminal - Structure - Params payment terminal 
// 
// Returns:
//  Boolean - Result operation 
//
Function pmCancelPreauthorization(Val pSum, pObj, pMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(pMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
			If vDeviceID = Undefined Then
				Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
			EndIf;
			vOutSlip 			= "";
			vCardNumber         = "";
			vReceiptNumber  = pObj.ReceiptNumber;
			vReferenceNumber = pObj.ReferenceNumber;
			vAuthorizationCode  = pObj.AuthorizationCode;

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
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), , , , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + pSum);
			vRC = vPC.CancelAuthorisationByPaymentCard(vDeviceID, vCardNumber, Format(pSum,"NS=-2; NG=0"), vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), pMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			vMessage = NStr("en = 'On-line authorization processed with preauthorization code/RRN: '; de = 'On-line authorization processed with preauthorization code/RRN: '; ru = 'Выполнена on-line отмена преавторизации! Код авторизации/RRN: '") + vAuthorizationCode + "/" + vReferenceNumber;
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), , , , vMessage);
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
			Disconnect(vPC);
			Return True;
		Except
			pMessage = ErrorDescription();
			ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), pMessage);
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPaymentTerminal - Structure - Params payment terminal 
//
Procedure pmCheckConnection(pPaymentTerminal) Export
	vMessage = "";
	// Try to connect
	Try
		// Read connection parameters
		vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pPaymentTerminal);
		If vConnParameters = Undefined Or IsBlankString(vConnParameters) Then
			vConnParameters = GetDefaultConnectionParameters();
		EndIf;
		// Show connection parameters
		OpenForm("CommonForm.tcInputText", New Structure("Text", vConnParameters), , , , , New NotifyDescription("AfterShowInputText", tcCreditCardsProcessingSystemDriverGazprombank, pPaymentTerminal.Ref));
	Except  
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndTry;
EndProcedure // pmCheckConnection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pConnParameters	 - XMLString - XML with params
//  pExtraParams	 - Structure - 
//
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
		vArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(pExtraParams); 
		vPC = Connect(vMessage, vArrPaymentTerminal);
		If vPC = Undefined Then
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'") + Chars.LF + vMessage);
			Return;
		EndIf;
		vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
		If vDeviceID = Undefined Then
			Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
		EndIf;
		
		// Initialize connection to the PIN pad device
		vRC = vPC.EchoTest(vDeviceID, vMessage);
		If Not IsBlankString(vMessage) Then
			ShowMessageBox(, NStr("en = 'Pay card processing system was connected with warning!'; de = 'Das Verarbeitungssystem für Kreditkarten wurde mit einer Warnung angeschlossen! '; ru = 'Система процессинга кредитных карт подключена с предупреждением! '") + Chars.LF + vMessage);
			Return;
		ElsIf Not vRC Then
			vErrCode = GetErrorDescription(vPC, vMessage);
		EndIf;
		Disconnect(vPC);
		If IsBlankString(vMessage) Then
			ShowMessageBox(, NStr("en = 'Pay card processing system was connected successfully!'; de = 'Das Verarbeitungssystem für Kreditkarten wurde erfolgreich angeschlossen!'; ru = 'Система процессинга кредитных карт успешно подключена!'"));
		EndIf;
	Except
		vMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(vMessage);
	EndTry;
EndProcedure //  AfterShowInputText

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - String	 - Errors
//  pCashRegister	 - Structure - Params cash register
//  pPaymentTerminal - Structure - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmOpenServiceFunctionsMenu(pMessage, pCashRegister, pPaymentTerminal) Export
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
	vPC = Connect(pMessage, vPaymentTerminalArr);
	If vPC = Undefined Then
		Return False;
	Else
		vUCList = New ValueList();
		vUCList.Add("XReportShort", NStr("en = 'Summary of transactions'; de = 'Zusammenfassung der Transaktionen'; ru = 'Краткий отчет по операциям'"));
		vUCList.Add("XReportFull", NStr("en = 'Complete transaction report'; de = 'Vollständiger Transaktionsbericht'; ru = 'Полный отчет по операциям'"));
		vUCList.Add("MenuCashier", NStr("en = 'Menu cashier'; de = 'Menu cashier'; ru = 'Меню кассира'"));
		vUCList.Add("MenuAdmin", NStr("en = 'Menu admin'; de = 'Menu admin'; ru = 'Меню администратора'"));
		vUCList.Add("ZReport", NStr("en = 'Z-Report (reconcile totals)'; de = 'Z-Bericht (Summen abgleichen)'; ru = 'Z-Отчет (сверка итогов)'"));
		vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverGazprombank, New Structure("PC, CashRegisterArr, PaymentTerminalArr", vPC, vCashRegisterArr, vPaymentTerminalArr)));
	EndIf;
	Return True;
EndFunction

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
			ShowMessageBox(, StrTemplate(NStr("en = 'Terminal connection error!
                                  |Error: %1'; de = 'Terminalverbindungsfehler!
                                  |Fehler: %1'; ru = 'Ошибка подключения к терминалу!
                                  |Error: %1'"), rMessage));
			Return;
		Else
			// Bank day settlement
			vOutSlip = "";
			vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
			If vDeviceID = Undefined Then
				ShowMessageBox(, NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'"));
				pResult = False;
				Return ;
			EndIf;
			vRC = vPC.Settlement(vDeviceID, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.Settlement'; de = 'CreditCardProcessingSystem.Settlement'; ru = 'СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				ShowMessageBox(, StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));
				pResult = False;
				Return;
			EndIf;
			// Print end of day slip
			If Not vPaymentTerminalArr.PrintSlipInCheque 
				And Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vCashRegisterArr, True);
			EndIf;
			// Success
			ShowMessageBox(, NStr("en = 'Totals check (settlement) operation completed successfully!'; de = 'Totals check (settlement) operation completed successfully!'; ru = 'Операция сверки итогов выполнена успешно!'"));
		EndIf;
	Except
		rMessage = ErrorDescription();
		ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.Settlement'; de = 'CreditCardProcessingSystem.Settlement'; ru = 'СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
		pResult = False;
		ShowMessageBox(, StrTemplate(NStr("en = 'An error occurred while reconciling the totals!
                                          |Error: %1'; de = 'Beim Abgleich der Summen ist ein Fehler aufgetreten!
                                          |Fehler: %1'; ru = 'Ошибка выполнения сверки итогов!
                                          |Error: %1'"), rMessage));

	EndTry;
EndProcedure // ReconcileTotals

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 - ComObject - Driver
//  pCashRegisterArr	 - Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure PrintXReportShort(pPC, pCashRegisterArr, pPaymentTerminalArr) Export
	rMessage = "";
	Try
		// X report
		// Bank day settlement
		vOutSlip = "";
		vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
		If vDeviceID = Undefined Then
			Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
		EndIf;
		vRC = pPC.GetShortReport(vDeviceID, vOutSlip);
		If Not ProcessResultCode(pPC, vRC, NStr("en = 'CreditCardProcessingSystem.XReportShort'; de = 'CreditCardProcessingSystem.XReportShort'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетКраткий'"), rMessage) Then
			Return;
		EndIf;
		// Print end of day slip
		If Not pPaymentTerminalArr.PrintSlipInCheque 
			And Not pPaymentTerminalArr.PrintSlipUsingTerminalPrinter 
			And Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegisterArr, True);
		EndIf;
		// Success
		ShowMessageBox(,NStr("en = 'Operation summary printing operation completed successfully!'; de = 'Vorgang Zusammenfassung Druckvorgang erfolgreich abgeschlossen!'; ru = 'Операция печати краткого отчета по операциям выполнена успешно!'"));
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en = 'CreditCardProcessingSystem.XReportShort'; de = 'CreditCardProcessingSystem.XReportShort'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетКраткий'"), rMessage);
	EndTry;
EndProcedure // PrintXReportShort

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 - ComObject - Driver
//  pCashRegisterArr	 - Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure PrintXReportFull(pPC, pCashRegisterArr, pPaymentTerminalArr) Export
	rMessage = "";
	Try
		// X report
		vOutSlip = "";
		vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
		If vDeviceID = Undefined Then
			Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
		EndIf;
		vRC = pPC.GetFullReport(vDeviceID, vOutSlip);
		If Not ProcessResultCode(pPC, vRC, NStr("en = 'CreditCardProcessingSystem.XReportFull'; de = 'CreditCardProcessingSystem.XReportFull'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетПолный'"), rMessage) Then
			Return;
		EndIf;
		// Print end of day slip
		If Not pPaymentTerminalArr.PrintSlipInCheque And 
			Not pPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegisterArr, True);
		EndIf;
		// Success
		ShowMessageBox(,NStr("en = 'The operation to print the complete activity report was successful!'; de = 'Der Vorgang zum Drucken des vollständigen Aktivitätsberichts war erfolgreich!'; ru = 'Операция печати полного отчета по операциям выполнена успешно!'"));
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en = 'CreditCardProcessingSystem.XReportFull'; de = 'CreditCardProcessingSystem.XReportFull'; ru = 'СистемаПроцессингаКредитныхКарт.XОтчетПолный'"), rMessage);
	EndTry;
EndProcedure // PrintXReportFull

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 - ComObject - Driver
//  pCashRegisterArr	 - Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure OpenMenuCashier(pPC, pCashRegisterArr, pPaymentTerminalArr) Export
	rMessage = "";
	Try
		// Any Cashier report
		vOutSlip = "";
		vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
		If vDeviceID = Undefined Then
			Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
		EndIf;
		vRC = pPC.MenuCashier(vDeviceID, vOutSlip);
		If Not ProcessResultCode(pPC, vRC, NStr("en = 'CreditCardProcessingSystem.MenuCashier'; de = 'CreditCardProcessingSystem.MenuCashier'; ru = 'СистемаПроцессингаКредитныхКарт.MenuCashier'"), rMessage) Then
			Return;
		EndIf;
		// Print slip
		If Not pPaymentTerminalArr.PrintSlipInCheque And 
			Not pPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegisterArr, True);
		EndIf;
		// Success
		ShowMessageBox(,NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'"));
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en='CreditCardProcessingSystem.MenuCashier'; de='CreditCardProcessingSystem.MenuCashier'; ru='СистемаПроцессингаКредитныхКарт.MenuCashier'"), rMessage);
	EndTry;
EndProcedure // OpenMenuCashier

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pPC			 	 - ComObject - Driver
//  pCashRegisterArr	 - Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure OpenMenuAdmin(pPC, pCashRegisterArr, pPaymentTerminalArr) Export
	rMessage = "";
	Try
		// Any admin function
		vOutSlip = "";
		vDeviceID    = GetPersistentObject("Gazprombank_DeviceID");
		If vDeviceID = Undefined Then
			Raise NStr("en = 'We could not determine the device ID!'; de = 'Wir konnten die Gerätenummer nicht ermitteln!'; ru = 'Не смогли определить ID устройства!'");
		EndIf;
		vRC = pPC.MenuAdmin(vDeviceID, vOutSlip);
		If Not ProcessResultCode(pPC, vRC, NStr("en = 'CreditCardProcessingSystem.MenuAdmin'; de = 'CreditCardProcessingSystem.MenuAdmin'; ru = 'СистемаПроцессингаКредитныхКарт.MenuAdmin'"), rMessage) Then
			Return;
		EndIf;
		// Print slip
		If Not pPaymentTerminalArr.PrintSlipInCheque And 
			Not pPaymentTerminalArr.PrintSlipUsingTerminalPrinter And 
			Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegisterArr, True);
		EndIf;
		// Success
		ShowMessageBox(,NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'"));
	Except
		rMessage = ErrorDescription();
		ProcessException(pPC, NStr("en = 'CreditCardProcessingSystem.MenuAdmin'; de = 'CreditCardProcessingSystem.MenuAdmin'; ru = 'СистемаПроцессингаКредитныхКарт.MenuAdmin'"), rMessage);
	EndTry;
EndProcedure // OpenMenuCashier

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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Connect(pMessage, pArrPaymentTerminal)
	// Reset return status
	pMessage = "";
	vDeviceID = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("Gazprombank");
		If vPC = Undefined Then
			#If Client Then  
				// ACC:561-off
				Try
					AttachAddIn("AddIn.EMVGateCOM");
					vPC = New("AddIn.EMVGateCOM1C");
				Except
					LoadAddIn("EMVGateCOM1C.dll");
					vPC = New("AddIn.EMVGateCOM1C");
				EndTry;
			#Else
				vPC = New("AddIn.EMVGateCOM1C");
			#EndIf      
			// ACC:561-on
			// Get connection parameters
			vConnectionParameters = ParseConnectionParameters(tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pArrPaymentTerminal));
			If vConnectionParameters <> Undefined Then
				SetConnectionParameters(vPC, vConnectionParameters);
			EndIf;
			If Not vPC.Open(vDeviceID) Then
				vErrCode = GetErrorDescription(vPC, pMessage);
				Return Undefined;;
			EndIf;
			// Save driver object
			SetPersistentObject("Gazprombank", vPC);
			SetPersistentObject("Gazprombank_DeviceID", vDeviceID);
		EndIf;
		// OK
		Return vPC;
	Except
		pMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	vDeviceID = GetPersistentObject("Gazprombank_DeviceID");
	Try
		pPC.Close(vDeviceID);
	Except
		pPC = Undefined;
	EndTry;
	SetPersistentObject("Gazprombank", Undefined);

EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("DllFileName, CfgFileName, HeadCheck","");
		
		#If Not WebClient Then
			vReader = New XMLReader();
			vReader.SetString(pStr);
			While vReader.Read() Do
				If vReader.NodeType = XMLNodeType.StartElement Then
					If vReader.Name = "DllFileName" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.DllFileName = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					EndIf;
					If vReader.Name = "CfgFileName" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.CfgFileName = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					EndIf;
					If vReader.Name = "HeadCheck" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.HeadCheck = TrimAll(vReader.Value);
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
Procedure SetConnectionParameters(pPC, pConnectionParameters)
	If pConnectionParameters <> Undefined Then
		#If Not WebClient Then
			
			vXmlParameters = "";
			If Not pPC.GetParameters(vXmlParameters) Then
				Raise ErrorDescription();
			EndIf;	
			vParams = New Structure();
			
			vReader = New XMLReader();
			vReader.SetString(vXmlParameters);
			vReader.MoveToContent();
			
			If vReader.Name = "Settings" And vReader.NodeType = XMLNodeType.StartElement Then
				While vReader.Read() Do
					If  vReader.Name = "Parameter" And vReader.NodeType = XMLNodeType.StartElement Then
						
						vEnabled = ?(Upper(vReader.AttributeValue("ReadOnly")) = "TRUE", True, False) 
						Or ?(Upper(vReader.AttributeValue("ReadOnly")) = "ИСТИНА", True, False);
						If vEnabled = True Then
							vKey = "R_" + vReader.AttributeValue("Name");
						Else
							vKey = "P_" + vReader.AttributeValue("Name");
						EndIf;
						
						vParamType         = Upper(vReader.AttributeValue("TypeValue"));
						vParamType         = ?(Not IsBlankString(vParamType), vParamType, "STRING");
						vKeyValue    		= vReader.AttributeValue("DefaultValue");
						
						If vParamType = "NUMBER" Then 
							vKeyValue = Number(vKeyValue);
						ElsIf  vParamType = "BOOLEAN" Then 
							vKeyValue = ?(Upper(vKeyValue) = "TRUE" Or Upper(vKeyValue) = "ИСТИНА", True, False);
						EndIf;
						
						vParams.Insert(vKey, vKeyValue);
						
					EndIf;
				EndDo;				
			EndIf;					
			vReader.Close();				
			
			vKey		= "";				
			vKeyValue	= "";			
			
			For  Each vParam In vParams Do
				If Left(vParam.Key, 2) = "P_" Then
					vKeyValue = vParam.Value;
					vKey = Сред(vParam.Key, 3);
					
					If vKey = "DllFileName"  Then
						vKeyValue = ?(ValueIsFilled(vKeyValue), vKeyValue, pConnectionParameters.DllFileName);
					ElsIf vKey = "CfgFileName" Then
						vKeyValue = ?(ValueIsFilled(vKeyValue), vKeyValue, pConnectionParameters.CfgFileName);
					EndIf;	
					
					If Not pPC.SetParameter(vKey, vKeyValue) Then
						Raise ErrorDescription();
					EndIf;	
				EndIf;
			EndDo;
		#ENDIF
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue) 
	amPersistentObjects.Insert(pName, pValue);
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName) 
	vObject = Undefined;
	amPersistentObjects.Property(pName, vObject);
	If vObject = Undefined Then
		amPersistentObjects.Insert(pName, vObject);
	EndIf;
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Function GetErrorDescription(pPC, pMessage)
	vErrCode = 957;
	pMessage = "";
	Try
		vErrCode = pPC.GetLastError(pMessage);
	Except
		pMessage = NStr("en = '<Description unknown>!'; de = '<Description unknown>!'; ru = '<Описание не найдено>!'");
	EndTry;
	Return vErrCode;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function GetDefaultConnectionParameters()
	Return 	"<GazprombankConnectionParameters>
	|	<DllFileName>Путь к библиотеке emvgatessl.dll</DllFileName>
	|	<CfgFileName>Путь к конфигурационному файлу emvgate.cfg</CfgFileName>
	|	<HeadCheck></HeadCheck>
	|</GazprombankConnectionParameters>";

EndFunction // GetDefaultConnectionParameters

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, pMessage)
	If Not pRC Then
		vErrCode = GetErrorDescription(pPC, pMessage);
		If vErrCode <> 0 Then
			pMessage = NStr("en = 'Host response: '; de = 'Host response: '; ru = 'Ответ хоста: '") + Format(vErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF 
						+ NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + pMessage;
		Else
			pMessage = NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + pMessage;
		EndIf;
		tcOnServer.cmWriteLogEventAtServer(pFunction, , , , pMessage);
		Disconnect(pPC);
		Return False;
	Else
		ErrorCodesTrue = New ValueList;
		ErrorCodesTrue.Add("000");
		ErrorCodesTrue.Add("003");
		ErrorCodesTrue.Add("020");
		ErrorCodesTrue.Add("959");

		vErrCode = ErrCodeProcessingSystem(pPC.AuthResponse);
		If ErrorCodesTrue.FindByValue(vErrCode) = Undefined Then
			vErrCode = GetErrorDescription(pPC, pMessage);
			If vErrCode = 0 Then
				pMessage = NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + pPC.AuthResponse;
			Else
				pMessage = NStr("en = 'Host response: '; de = 'Host response: '; ru = 'Ответ хоста: '") + Format(vErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF 
							+ NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + pMessage;
			EndIf;
			tcOnServer.cmWriteLogEventAtServer(pFunction, , , , pMessage);
			Return False;
		Else	
			Return True;
		EndIf;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Function  ErrCodeProcessingSystem(pRC)
	
	vResponse = Left(pRC, 3);	
	vPos = 3;
	vStop = False;
    
	While Not Mid(vResponse,vPos,1) = " " Do
		If vPos = 0 Then
			vStop = True;
			Break;
		EndIf;
        vPos = vPos - 1;
    EndDo;    
    
	vResponse = ?(vStop, vResponse, Left(vResponse,vPos - 1));
	
	Return ?(vResponse = "0", "000", Format(Number(vResponse), "ЧЦ=3; ЧВН="));
	
EndFunction

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
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverGazprombank, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
			// Show InputCashRegisterPassword
			OpenForm("CommonForm.tcInputCashRegisterPassword",New Structure("LabelDescription", vQuestion), , , , , vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		ShowMessageBox(, Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'"), , NStr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));
		Return;
	EndIf;	
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Function GetTextLinesArray(pTextStr)
	vTxtArr = New Array;
	If Not IsBlankString(pTextStr) Then
		vTxt = New TextDocument();
		vTxt.SetText(pTextStr);
		For i = 1 To vTxt.LineCount() Do
			vStr = vTxt.GetLine(i);
			If TrimAll(vStr) = "[cut]" Then
				Break;
			EndIf;
			vTxtArr.Add(vStr);
		EndDo;
	EndIf;
	Return vTxtArr;
EndFunction // GetTextLinesArray

// -----------------------------------------------------------------------------
Procedure ProcessException(pFR, pFunction, pMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction, , , , "Error description: " + pMessage);
	Disconnect(pFR);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Procedure AfterServiceFunctionsMenuSelection(vUCItem, vExtraParams) Export
	If vUCItem <> Undefined Then
		If vUCItem.Value = "XReportShort" Then
			PrintXReportShort(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		ElsIf vUCItem.Value = "XReportFull" Then
			PrintXReportFull(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		ElsIf vUCItem.Value = "MenuCashier" Then
			OpenMenuCashier(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
	    ElsIf vUCItem.Value = "MenuAdmin" Then
			OpenMenuAdmin(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		ElsIf vUCItem.Value = "ZReport" Then
			ReconcileTotals(vExtraParams.PC, vExtraParams.CashRegisterArr, vExtraParams.PaymentTerminalArr);
		EndIf;
	EndIf;
EndProcedure // AfterServiceFunctionsMenuSelection

#EndRegion
