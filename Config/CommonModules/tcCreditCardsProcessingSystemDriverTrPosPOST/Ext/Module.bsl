
#Region Public

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'; ru = 'Не указана сумма авторизации!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vOperationCode = "";
			vInvoiceNumber = "";
			vInParams = "";
		    vExtraInParams = "";
			vExtraOperationCode = "";
			vExtraAmount = 0;
			// Terminal
			vTerminalId = GetTerminalId(pObj, pPaymentTerminal);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf; 
			If ValueIsFilled(pObj.Company) Then
				vMerchantID = tcOnServer.cmGetAttributeByRef(pObj.Company, "MerchantID");
				If Not IsBlankString(vMerchantID) Then
					vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(vMerchantID);
				EndIf;
			EndIf;
			vInParams = vInParams + Chars.LF + "MessageID=&OperationCode";
			vInParams = vInParams + Chars.LF + "TransactionAmount=&OperationAmount";
			If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				vOperationCode = "CMP";
				// Complete preauthorization
				vRRN = "";
				vReferenceNumber = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"); 
				If ValueIsFilled(vReferenceNumber) Then
					If StrLen(TrimAll(vReferenceNumber)) <= 6 Then
						vInvoiceNumber = Format(Number(TrimAll(vReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
					Else
						vInvoiceNumber = Left(TrimAll(vReferenceNumber), 6);
						vRRN = Right(TrimAll(vReferenceNumber), 12);
					EndIf;
				EndIf;
				If ValueIsFilled(vRRN) Then
					vInParams = vInParams + Chars.LF + "RRN=" + vRRN;
				EndIf;
				vPreauthorisationArr = tcOnServer.cmGetAtributeAsArray(pObj.Preauthorisation);
				vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(vPreauthorisationArr.AuthorizationCode);
				If ValueIsFilled(vPreauthorisationArr.CreditCard) Then
					vCreditCardArr = tcOnServer.cmGetAtributeAsArray(vPreauthorisationArr.CreditCard); 
					If StrLen(TrimAll(vCreditCardArr.CardDataEnc)) = 32 Then
						vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vCreditCardArr.CardDataEnc);
					Else
						If ValueIsFilled(vCreditCardArr.CardNumber) Then
							vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(vCreditCardArr.CardNumber);
						EndIf;
						If ValueIsFilled(vCreditCardArr.CardValidTillDate) Then
							vInParams = vInParams + Chars.LF + "ExpDate=" + Format(vCreditCardArr.CardValidTillDate, "DF=MMyy");
						EndIf;
					EndIf;
				EndIf; 
				If Not IsBlankString(vPreauthorisationArr.TransactionID) Then
					vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(vPreauthorisationArr.TransactionID);
					// Get total preauthorisation amount by transaction ID
					vPreauthorizationAmount = tcCreditCardsProcessingSystemDriverAtServer.GetTotalPreauthorizationAmountByTransactionID((TrimAll(vPreauthorisationArr.TransactionID)));
					If vPreauthorizationAmount > pSum Then
						vExtraAmount = vPreauthorizationAmount - pSum;
					    vExtraInParams = vInParams;
						vExtraOperationCode = "VAU";
						If Not IsBlankString(vPreauthorisationArr.DateTime) Then
							vExtraInParams = vExtraInParams + Chars.LF + "DateTime=" + TrimAll(vPreauthorisationArr.DateTime);
						EndIf;
					ElsIf vPreauthorizationAmount < pSum Then
						vExtraAmount = pSum - vPreauthorizationAmount;
					    vExtraInParams = vInParams;
						vExtraOperationCode = "AUT";
					EndIf;
					If Not IsBlankString(vExtraOperationCode) And vExtraAmount <> 0 Then
						vExtraInParams = vExtraInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(GetDocumentNumberPresentation(TrimAll(pObj.Number))) + 1000000, "ND=10; NFD=0; NZ=; NLZ=; NG=");
						vExtraInParams = StrReplace(vExtraInParams, "&OperationCode", vExtraOperationCode);
						vExtraInParams = StrReplace(vExtraInParams, "&OperationAmount", Format(vExtraAmount * 100, "ND=12; NFD=0; NZ=; NLZ=; NG="));
						If vExtraOperationCode = "VAU" Then
							vExtraInParams = vExtraInParams + Chars.LF + "TransactionAmount2=" + Format(vPreauthorizationAmount * 100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
							If Not IsBlankString(vInvoiceNumber) Then
								vExtraInParams = vExtraInParams + Chars.LF + "InvoiceNumber=" + vInvoiceNumber;
							EndIf;
						EndIf;
						// Call extra processing
						tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.Process'; de = 'CreditCardProcessingSystem.Process'; ru = 'СистемаПроцессингаКредитныхКарт.Процесс'"), "Information", , , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
						vRC = vPC.Process(vExtraInParams, vOutParamsLen, vOutSlipLen);
						If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
							Return False;
						EndIf;
						If vOutParamsLen = 0 Then
							vRC = 80; // Timeout
							ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
							// Do auto cancellation
							vOutParamsLen = 0;
							vOutSlipLen = 0;
							vInParams = StrReplace(vExtraInParams, "MessageID=" + vExtraOperationCode, "MessageID=VOI");
							vRC = vPC.Process(vExtraInParams, vOutParamsLen, vOutSlipLen);
							// Return error
							Return False;
						EndIf;
						// Get response
						vOutParams = GetDataPresentation(vPC.GetResponse(0, vOutParamsLen));
						// Check output parameters
						If IsBlankString(vOutParams) Then
							// Return error
							Return False;
						EndIf;
						vOutParamsArr = GetTextLinesArray(vOutParams);
						// Parse response
						vApprove = GetApprove(vOutParamsArr);
						vResponseCode = GetResponseCode(vOutParamsArr);
						vAuthorizationCode = GetAuthorizationID(vOutParamsArr);
						// Check approve and response code
						If vApprove = "N" Or IsBlankString(vApprove) And vResponseCode <> "00" Then
							// Authorization was not successfull
							vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
							rMessage = NStr("en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '; ru = 'Операция отклонена банком! Код ответа: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
							tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
							tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),"Warning",,,rMessage);
							// Return error
							Return False;
						EndIf;
						// Check authorization code
						If IsBlankString(vAuthorizationCode) Or 
						   TrimAll(vAuthorizationCode) = "0" Then
							// Authorization was not successfull
							vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
							rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
							tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
							tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"),"Warning",,,rMessage);
							// Return error
							Return False;
						EndIf;
						// Get slip
						vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister, pPaymentTerminal);
						// Print authorization slip
						If Not pPaymentTerminal.PrintSlipInCheque And 
						   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
						   Not IsBlankString(vOutSlip) Then
							vSlipTxtArr = GetTextLinesArray(vOutSlip);
							PrintSlipDocument(vSlipTxtArr, pObj);
						EndIf;
						// Reset parameters
						vOutParamsLen = 0;
						vOutSlipLen = 0;
					EndIf;
				EndIf;
			Else
				If pSum > 0 Then
					vOperationCode = "PUR";
					If ValueIsFilled(pObj.CreditCard) Then
						vCardDataEnc = tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardDataEnc");
						If StrLen(TrimAll(vCardDataEnc)) = 32 Then
							vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vCardDataEnc);
						EndIf;
					EndIf;
				Else
					vOperationCode = "REF";
					vRRN = "";
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
							If StrLen(TrimAll(vReferenceNumber)) <= 6 Then
								vInvoiceNumber = Format(Number(TrimAll(vReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
							Else
								vInvoiceNumber = Left(TrimAll(vReferenceNumber), 6);
								vRRN = Right(TrimAll(vReferenceNumber), 12);
							EndIf;
						EndIf;
						If Not IsBlankString(vRRN) Then
							vInParams = vInParams + Chars.LF + "RRN=" + vRRN;
						EndIf;
						vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode"));
						vCreditCard =  tcOnServer.cmGetAttributeByRef(vPayment, "CreditCard");
						If ValueIsFilled(vCreditCard) Then
							vCreditCardArr = tcOnServer.cmGetAtributeAsArray(vCreditCard);
							If StrLen(TrimAll(vCreditCardArr.CardDataEnc)) = 32 Then
								vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vCreditCardArr.CardDataEnc);
							Else
								If ValueIsFilled(vCreditCardArr.CardNumber) Then
									vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(vCreditCardArr.CardNumber);
								EndIf;
								If ValueIsFilled(vCreditCardArr.CardValidTillDate) Then
									vInParams = vInParams + Chars.LF + "ExpDate=" + Format(vCreditCardArr.CardValidTillDate, "DF=MMyy");
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Not IsBlankString(vInvoiceNumber) Then
				vInParams = vInParams + Chars.LF + "InvoiceNumber=" + vInvoiceNumber;
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(GetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = StrReplace(vInParams, "&OperationCode", vOperationCode);
			vInParams = StrReplace(vInParams, "&OperationAmount", Format(pObj.Sum * 100, "ND=12; NFD=0; NZ=; NLZ=; NG="));
			// Call processing
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), "Warning", , , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			If vOutParamsLen = 0 Then
				vRC = 80; // Timeout
				ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
				// Do auto cancellation
				vOutParamsLen = 0;
				vOutSlipLen = 0;
				vInParams = StrReplace(vInParams, "MessageID=" + vOperationCode, "MessageID=VOI");
				vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
				// Do autocancellation of extra operation
				If Not IsBlankString(vExtraOperationCode) And vExtraAmount <> 0 Then
					vOutParamsLen = 0;
					vOutSlipLen = 0;
					vExtraInParams = StrReplace(vExtraInParams, "MessageID=" + vExtraOperationCode, "MessageID=VOI");
					vRC = vPC.Process(vExtraInParams, vOutParamsLen, vOutSlipLen);
				EndIf;
				// Return error
				Return False;
			EndIf;
			// Get response
			vOutParams = GetDataPresentation(vPC.GetResponse(0, vOutParamsLen));
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'; ru = 'От POS терминала получен пустой ответ'");
			EndIf;
			vOutParamsArr = GetTextLinesArray(vOutParams);
			// Parse response
			vApprove = GetApprove(vOutParamsArr);
			vResponseCode = GetResponseCode(vOutParamsArr);
			vAuthorizationCode = GetAuthorizationID(vOutParamsArr);
			vInvoiceNumber = GetInvoiceNumber(vOutParamsArr);
			vReferenceNumber = GetReferenceNumber(vOutParamsArr);
			vTerminalNumber = GetTerminalNumber(vOutParamsArr);
			// Check approve and response code
			If vApprove = "N" Or IsBlankString(vApprove) And vResponseCode <> "00" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '; ru = 'Операция отклонена банком! Код ответа: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister, pPaymentTerminal);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = tcOnServer.cmGetAttributeByRef(vCreditCardRef, "CardType");
				EndIf;
			Else
				pObj.CardType = tcCreditCardsProcessingSystemDriverAtServer.GetCardType(vOutParamsArr);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vInvoiceNumber + "/" + vReferenceNumber;
			pObj.TerminalNumber = vTerminalNumber;
			pObj.SlipText = vOutSlip;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
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
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister, pPaymentTerminal) Export
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
		// Pay card system object was created successfully
		Try
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialize pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pCashRegister, vPaymentTerminalArr);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(vTerminalId, "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "MessageID=SRV";
			If ValueIsFilled(pCashRegister) Then
				vMerchantID = tcOnServer.cmGetAttributeByRef(pCashRegister, "Owner.MerchantID");
				If Not IsBlankString(vMerchantID) Then
					vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(vMerchantID);
				EndIf;
			EndIf;
			// Call processing
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.Process'; de = 'CreditCardProcessingSystem.Process'; ru = 'СистемаПроцессингаКредитныхКарт.Процесс'"), "Information", , , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.OpenServiceFunctionsMenu'; de = 'CreditCardProcessingSystem.OpenServiceFunctionsMenu'; ru = 'СистемаПроцессингаКредитныхКарт.ОткрытиеМенюСервисныхФункций'"), rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pCashRegister, vPaymentTerminalArr);
			// Print authorization slip
			If Not vPaymentTerminalArr.PrintSlipInCheque 
				And Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vStruct = New Structure("CashRegister", pCashRegister);
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct, True);
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.OpenServiceFunctionsMenu'; de = 'CreditCardProcessingSystem.OpenServiceFunctionsMenu'; ru = 'СистемаПроцессингаКредитныхКарт.ОткрытиеМенюСервисныхФункций'"), rMessage);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("en = 'Zero sum preauthorization is not possible!'; de = 'Zero sum preauthorization is not possible!'; ru = 'Не указана сумма преавторизации!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pObj, pPaymentTerminal);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(GetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "TransactionAmount=" + Format(pObj.Sum * 100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "MessageID=AUT";
			// Voice preauthorisation
			If ValueIsFilled(pObj.CreditCard) Then
				vCreditCardArr = tcOnServer.cmGetAtributeAsArray(pObj.CreditCard);
				If StrLen(TrimAll(vCreditCardArr.CardDataEnc)) = 32 Then
					vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vCreditCardArr.CardDataEnc);
				Else
					If ValueIsFilled(vCreditCardArr.CardNumber) Then
						vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(vCreditCardArr.CardNumber);
					EndIf;
					If ValueIsFilled(vCreditCardArr.CardValidTillDate) Then
						vInParams = vInParams + Chars.LF + "ExpDate=" + Format(vCreditCardArr.CardValidTillDate, "DF=MMyy");
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.Company) Then
				vMerchantID = tcOnServer.cmGetAttributeByRef(pObj.Company, "MerchantID");
				If Not IsBlankString(vMerchantID) Then
					vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(vMerchantID);
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.TransactionID) And Not IsBlankString(pObj.TransactionID) Then
				vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(pObj.TransactionID);
			Else
				vInParams = vInParams + Chars.LF + "TransactionID=0";
			EndIf;

			// Call processing
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.Process'; de = 'CreditCardProcessingSystem.Process'; ru = 'СистемаПроцессингаКредитныхКарт.Процесс'"), "Information", , , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);		
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			If vOutParamsLen = 0 Then
				vRC = 80; // Timeout
				ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
				// Do auto cancellation
				vOutParamsLen = 0;
				vOutSlipLen = 0;
				vInParams = StrReplace(vInParams, "MessageID=AUT", "MessageID=VOI");
				vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
				// Return error
				Return False;
			EndIf;
			// Get response
			vOutParams = GetDataPresentation(vPC.GetResponse(0, vOutParamsLen));
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'; ru = 'От POS терминала получен пустой ответ'");
			EndIf;
			vOutParamsArr = GetTextLinesArray(vOutParams);
			// Parse response
			vApprove = GetApprove(vOutParamsArr);
			vResponseCode = GetResponseCode(vOutParamsArr);
			vAuthorizationCode = GetAuthorizationID(vOutParamsArr);
			vInvoiceNumber = GetInvoiceNumber(vOutParamsArr);
			vReferenceNumber = GetReferenceNumber(vOutParamsArr);
			vTerminalNumber = GetTerminalNumber(vOutParamsArr);
			vTransactionID = GetTransactionID(vOutParamsArr);
			vDateTime = GetDateTime(vOutParamsArr);
			// Check approve and response code
			If vApprove = "N" Or IsBlankString(vApprove) And vResponseCode <> "00" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '; ru = 'Операция отклонена банком! Код ответа: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '; ru = 'Операция отклонена банком! Код авторизации: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister, pPaymentTerminal);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = tcOnServer.cmGetAttributeByRef(vCreditCardRef, "CardType");
				EndIf;
			Else
				pObj.CardType = tcCreditCardsProcessingSystemDriverAtServer.GetCardType(vOutParamsArr);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vInvoiceNumber + "/" + vReferenceNumber;
			pObj.TerminalNumber = vTerminalNumber;
			pObj.SlipText = vOutSlip;
			pObj.TransactionID = vTransactionID;
			pObj.DateTime = vDateTime;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.PreauthorizePayment'; de = 'CreditCardProcessingSystem.PreauthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	// Try to connect
	vPC = Connect(rMessage, pPaymentTerminal);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check preauthorization amount
			If pSum = 0 Then
				Raise NStr("en = 'Zero amount is not possible!'; de = 'Zero amount is not possible!'; ru = 'Не указана сумма отмены!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pObj, pPaymentTerminal);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(GetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "TransactionAmount=" + Format(pObj.Sum*100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
			If Not IsBlankString(pObj.ReferenceNumber) Then
				If StrLen(TrimAll(pObj.ReferenceNumber)) <= 6 Then
					vInParams = vInParams + Chars.LF + "InvoiceNumber=" + Format(Number(TrimAll(pObj.ReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
				Else
					vInParams = vInParams + Chars.LF + "InvoiceNumber=" + Left(TrimAll(pObj.ReferenceNumber), 6);
					vInParams = vInParams + Chars.LF + "RRN=" + Right(TrimAll(pObj.ReferenceNumber), 12);
				EndIf;
			EndIf;
			vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(pObj.AuthorizationCode);
			If ValueIsFilled(pObj.CreditCard) Then
				vCreditCardArr = tcOnServer.cmGetAtributeAsArray(pObj.CreditCard); 
				If StrLen(TrimAll(vCreditCardArr.CardDataEnc)) = 32 Then
					vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vCreditCardArr.CardDataEnc);
				Else
					If Not IsBlankString(vCreditCardArr.CardNumber) Then
						vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(vCreditCardArr.CardNumber);
					EndIf;
					If ValueIsFilled(vCreditCardArr.CardValidTillDate) Then
						vInParams = vInParams + Chars.LF + "ExpDate=" + Format(vCreditCardArr.CardValidTillDate, "DF=MMyy");
					EndIf;
				EndIf;
			EndIf;
			vInParams = vInParams + Chars.LF + "MessageID=VOI";
			If ValueIsFilled(pObj.Company) Then
				vMerchantID = tcOnServer.cmGetAttributeByRef(pObj.Company, "MerchantID");
				If Not IsBlankString(vMerchantID) Then
					vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(vMerchantID);
				EndIf;
			EndIf;
			If Not IsBlankString(pObj.TransactionID) Then
				vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(pObj.TransactionID);
			EndIf;
			If Not IsBlankString(pObj.DateTime) Then
				vInParams = vInParams + Chars.LF + "DateTime=" + TrimAll(pObj.DateTime);
			EndIf;
			// Call processing
			tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.Process'; de = 'CreditCardProcessingSystem.Process'; ru = 'СистемаПроцессингаКредитныхКарт.Процесс'"), "Information", , , NStr("en = 'Parameters: '; de = 'Parameters: '; ru = 'Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
				Return False;
			EndIf;
			If vOutParamsLen = 0 Then
				vRC = 80; // Timeout
				ProcessResultCode(vRC, vPC, NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
				// Return error
				Return False;
			EndIf;
			// Get response
			vOutParams = GetDataPresentation(vPC.GetResponse(0, vOutParamsLen));
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'; ru = 'От POS терминала получен пустой ответ'");
			EndIf;
			vOutParamsArr = GetTextLinesArray(vOutParams);
			// Parse response
			vApprove = GetApprove(vOutParamsArr);
			vResponseCode = GetResponseCode(vOutParamsArr);
			vAuthorizationCode = GetAuthorizationID(vOutParamsArr);
			vInvoiceNumber = GetInvoiceNumber(vOutParamsArr);
			vReferenceNumber = GetReferenceNumber(vOutParamsArr);
			vTerminalNumber = GetTerminalNumber(vOutParamsArr);
			vTransactionID = GetTransactionID(vOutParamsArr);
			// Check approve and response code
			If vApprove = "N" Or IsBlankString(vApprove) And vResponseCode <> "00" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '; ru = 'Операция отклонена банком! Код ответа: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '; ru = 'Операция отклонена банком! Код авторизации: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				tcOnServer.cmWriteLogEventAtServer(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), "Warning", , , rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister, pPaymentTerminal);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = tcOnServer.cmGetAttributeByRef(vCreditCardRef, "CardType");
				EndIf;
			Else
				pObj.CardType = tcCreditCardsProcessingSystemDriverAtServer.GetCardType(vOutParamsArr);
			EndIf;
			// Change preauthorization status if there are no erros
			pObj.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
			pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vInvoiceNumber + "/" + vReferenceNumber + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.AuthorOfCancellation = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
			pObj.DateOfCancellation = tcOnServer.cmGetServerCurrentSessionDate();
			// Print slip
			If Not pPaymentTerminal.PrintSlipInCheque 
				And Not pPaymentTerminal.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Procedure pmCheckConnection(pPaymentTerminal) Export
	rMessage = "";
	// Try to connect
	Try
		// Read connection parameters
		vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pPaymentTerminal);
		// Show connection parameters
		OpenForm("CommonForm.tcInputText", New Structure("Text", vConnParameters), , , , , New NotifyDescription("AfterShowInputText", tcCreditCardsProcessingSystemDriverTrPosPOST, pPaymentTerminal.Ref));
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(rMessage);
	EndTry;
EndProcedure // pmCheckConnection

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
		vPC = Connect(vMessage, pExtraParams);
		If vPC = Undefined Then
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'") + Chars.LF + vMessage);
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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetDocumentNumberPresentation(pNumber)
	vNumberPresentation = "";
	vNumber = TrimAll(pNumber);
	Try
		vNumberLength = StrLen(vNumber);
		vPrefixLength = 0;
		For i = 1 To vNumberLength Do
			vChar = Mid(vNumber, i, 1);
			If (vChar < "0" Or vChar > "9") And vChar <> "/" Then
				vPrefixLength = i;
			EndIf;
		EndDo;
		If vPrefixLength < vNumberLength Then
			vNumberPresentation = Mid(vNumber, vPrefixLength + 1);
			vNumberPresentation = Format(Number(vNumberPresentation), "ND=12; NFD=0; NG=");
		EndIf;
		If IsBlankString(vNumberPresentation) Then
			vNumberPresentation = vNumber;
		EndIf;
	Except
		vNumberPresentation = TrimAll(pNumber);
	EndTry;
	Return vNumberPresentation;
EndFunction // GetDocumentNumberPresentation

// -----------------------------------------------------------------------------
Function CommonDir()
	vDir = Undefined;
	#If Not WebClient Then
		vDir = Lower(BinDir());
		If GetPlatformVersion() = "8.2" Then
			vCommonPos = StrFind(vDir, "\1cv82\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 5) + "\common\";
			EndIf;
		Else
			vCommonPos = StrFind(vDir, "\1cv8\");
			If vCommonPos > 0 Then
				vDir = Left(vDir, vCommonPos + 4) + "\common\";
			EndIf;
		EndIf;
	#EndIf
	Return vDir;
EndFunction // CommonDir

// -----------------------------------------------------------------------------
Function GetPlatformVersion(pFull = False)
	vSI = New SystemInfo();
	If pFull Then
		vAppVersion = vSI.AppVersion;
	Else
		vAppVersion = Left(vSI.AppVersion, 3);
	EndIf;
	Return vAppVersion;
EndFunction // GetPlatformVersion

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
Function SlipFormat(pSlip, pCashRegister, pPaymentTerminal)
	If IsBlankString(pSlip) Then
		Return pSlip;
	EndIf;
	pSlip = GetDataPresentation(pSlip);
	// Try to cut off double check
	vPos = StrFind(pSlip, Char(31));
	If vPos > 0 Then
		pSlip = Left(pSlip, vPos-1);
	EndIf;
	// Do not process slip cheque if printing is done using terminal printer
	If pPaymentTerminal.PrintSlipUsingTerminalPrinter Then
		Return pSlip;
	EndIf;
	// Get slip width
	vWidth = pPaymentTerminal.SlipCharLineLength;
	If vWidth = 0 Then
		vWidth = 40;
	EndIf;
	If vWidth >= 40 Then
		Return pSlip;
	EndIf;
	// Compare slip width with cash register width
	vChequeWidth = 0;
	If ValueIsFilled(pCashRegister) Then
		vChequeWidth = pCashRegister.ChequeWidth;
		If vChequeWidth = 0 Then
			vChequeWidth = 24;
		EndIf;
		If pCashRegister.ChequeWidth = vWidth Then
			Return pSlip;
		EndIf;
	Else
		Return pSlip;
	EndIf;
	// If cash register width is greater or equal slip width then do nothing
	If vChequeWidth >= vWidth Then
		Return pSlip;
	EndIf;
	// Calculate number of chars to remove from slip
	vNumChars = vWidth - vChequeWidth;
	If Int(vNumChars / 2) <> vNumChars / 2 Then
		vNumChars = vNumChars + 1;
	EndIf;
	// Process slip lines
	vSlip = "";
	vSlipTxtArr = GetTextLinesArray(pSlip);
	For Each vTxt In vSlipTxtArr Do
		vIniLen = StrLen(vTxt);
		If vIniLen <= vWidth Then
			vSlip = vSlip + vTxt + Chars.LF;
			Continue;
		EndIf;
		If vIniLen < vWidth Then
			i = vIniLen;
			While i < vWidth Do
				vTxt = vTxt + " ";
				i = i + 1;
			EndDo;			
		EndIf;		
		vRemoved = 0;
		// First try to remove blanks processing both ends of the line
		vLeftLength = Int(vWidth / 2) - 2;
		vLeftTxt = Left(vTxt, Int(vWidth / 2));
		vRightTxt = Right(vTxt, Int(vWidth/2));
		j = 0;
		k = 0;
		For i = 0 To (Int(vWidth / 2) - 2) Do
			vLeft = Mid(vTxt, Int(vWidth / 2) - 2 - i, 2);
			If vLeft = "  " Then
				vLeftTxt = Left(vTxt, Int(vWidth / 2) - 2 - i + 1) + Mid(vLeftTxt, vLeftLength - j + 3); 
				vLeftLength = vLeftLength - 1;
				vRemoved = vRemoved + 1;
			Else
				j = j + 1;
			EndIf;
			If vRemoved = vNumChars Then
				Break;
			EndIf;
			vRight = Mid(vTxt, Int(vWidth / 2) + 1 + i, 2);
			If vRight = "  " Then
				vRightTxt = Left(vRightTxt, k) + Mid(vTxt, Int(vWidth / 2) + i + 2);
				vRemoved = vRemoved + 1;
			Else
				k = k + 1;
			EndIf;
			If vRemoved = vNumChars Then
				Break;
			EndIf;
		EndDo;
		vTxt = vLeftTxt + vRightTxt;
		// Trancate double blanks left from the previous run
		vRemains = vNumChars - vRemoved;
		If vRemains > 0 Then
			vLen1 = 999;
			vLen2 = 0;
			While vLen1 > vLen2 Do
				vLen1 = StrLen(vTxt);
				vTxt = StrReplace(vTxt, "  ", " ");
				vLen2 = StrLen(vTxt);
				If vLen1 > vLen2 Then
					vRemoved = vRemoved + vLen1 - vLen2;
				EndIf;
			EndDo;
		EndIf;		
		// Trancate ": " to ":"
		vRemains = vNumChars - vRemoved;
		If vRemains > 0 Then
			vLen1 = 999;
			vLen2 = 0;
			While vLen1 > vLen2 Do
				vLen1 = StrLen(vTxt);
				vTxt = StrReplace(vTxt, ": ", ":");
				vLen2 = StrLen(vTxt);
				If vLen1 > vLen2 Then
					vRemoved = vRemoved + vLen1 - vLen2;
				EndIf;
			EndDo;
		EndIf;
		// Cut off from the left and right because nothing left to do
		vRemains = vNumChars - vRemoved;
		If vRemains > 0 Then
			If Int(vRemains / 2) <> vRemains / 2 Then
				vRemains = vRemains + 1;
			EndIf;
			vTxt = Mid(vTxt, vRemains / 2 + 1);
			vTxt = Left(vTxt, StrLen(vTxt) - vRemains / 2);
		EndIf;
		vSlip = vSlip + vTxt + Chars.LF;
	EndDo;
	Return TrimAll(vSlip);
EndFunction // SlipFormat

// -----------------------------------------------------------------------------
Function GetTerminalId(pObj, pPaymentTerminal)
	If pObj = Undefined Then
		Return Number(StrReplace(TrimAll(pPaymentTerminal.TerminalNumber), " ", ""));
	ElsIf TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(pObj, "TerminalNumber")) And TrimAll(tcOnServer.cmGetAttributeByRef(pObj, "TerminalNumber")) <> "0" Then
		Return Number(StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(pObj, "TerminalNumber")), " ", ""));
	ElsIf Not TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj.CashRegister) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")) And TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")) <> "0" Then
		Return Number(StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")), " ", ""));
	Else
		Return Number(StrReplace(TrimAll(pPaymentTerminal.TerminalNumber), " ", ""));
	EndIf;
EndFunction // GetTerminalId

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName) 
	vObject = Undefined;
	#If Client Then 
		amPersistentObjects.Property(pName, vObject);
		If vObject = Undefined Then
			amPersistentObjects.Insert(pName, vObject);
		EndIf;
	#EndIf
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue) 
	#If Client Then
		amPersistentObjects.Insert(pName, pValue);
	#EndIf
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Function GetErrorDescription(vRC)
	vMessage = TrimAll(vRC);
	If vRC = 1 Then
		vMessage = vMessage + " - " + NStr("en='Unable to open configuration file!'; de='Unable to open configuration file!'; ru='Невозможно открыть конфигурационный файл!'");
	ElsIf vRC = 2 Then
		vMessage = vMessage + " - " + NStr("en='Error processing input parameters!'; de='Error processing input parameters!'; ru='Ошибка обработки входных параметров (файла)!'");
	ElsIf vRC = 3 Then
		vMessage = vMessage + " - " + NStr("en='Error processing output parameters!'; de='Error processing output parameters!'; ru='Ошибка создания выходных параметров (файла)!'");
	ElsIf vRC = 4 Then
		vMessage = vMessage + " - " + NStr("en='Error building operation slip text!'; de='Error building operation slip text!'; ru='Ошибка создания образа карт-чека!'");
	ElsIf vRC = 5 Then
		vMessage = vMessage + " - " + NStr("en='Unable to open POS terminal port!'; de='Unable to open POS terminal port!'; ru='Невозможно открыть порт к POS-терминалу!'");
	ElsIf vRC = 6 Then
		vMessage = vMessage + " - " + NStr("en='Input parameters are wrong!'; de='Input parameters are wrong!'; ru='Ошибка в параметрах вызова!'");
	ElsIf vRC = 7 Then
		vMessage = vMessage + " - " + NStr("en='Output parameters contain wrong data!'; de='Output parameters contain wrong data!'; ru='Ошибка во входных данных!'");
	ElsIf vRC = 8 Then
		vMessage = vMessage + " - " + NStr("en='System error!'; de='System error!'; ru='Системная ошибка!'");
	ElsIf vRC = 9 Then
		vMessage = vMessage + " - " + NStr("en='POS-terminal is not ready!'; de='POS-terminal is not ready!'; ru='POS-терминал не готов!'");
	ElsIf vRC >= 80 Then
		vMessage = vMessage + " - " + NStr("en='Timeout has triggered!'; de='Timeout has triggered!'; ru='Сработал таймаут!'");
	Else
		vMessage = vMessage + " - " + NStr("en='<Description unknown>!'; de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndIf;
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function Connect(rMessage, pPaymentTerminal)
	// Reset return status
	rMessage = "";
	// Try to create external component
	#If Not MobileClient Then
		Try
			vPC = GetPersistentObject("TrPosX");
			If vPC = Undefined Then
				vPC = New COMObject("TRPOSX.TRPOSX");
				// Read connection parameters
				vConnParameters = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pPaymentTerminal);
				// Write connection parameters to the configuration file
				vCommonDir = CommonDir();
				If vCommonDir = Undefined Then
					rMessage = NStr("en = 'Is not supported in the web client'; de = 'Wird im Web Client nicht unterstützt'; ru = 'Не поддерживается в веб-клиенте'");
					Return Undefined;	
				EndIf;
				vConfFileName = CommonDir() + "trposx.cfg";
				vConfFile =  New TextDocument();
				vConfFile.SetText(vConnParameters);
				vConfFile.Write(vConfFileName, TextEncoding.ANSI);  // ACC:561
				// Initialize connection to the POS system
				vRC = vPC.Init(vConfFileName);
				If vRC <> 0 Then
					rMessage = GetErrorDescription(vRC);
					vPC = Undefined;
					Return vPC;
				EndIf;
				SetPersistentObject("TrPosX", vPC);
				// Wait 20 seconds
				tcOnServer.Wait(15);
			EndIf;
			// OK
			Return vPC;
		Except
			rMessage = ErrorDescription();
			Return Undefined;
		EndTry;
	#Else
		Return Undefined;
	#EndIf
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	Try
		If pPC <> Undefined Then
			pPC.Close();
		EndIf;
		pPC = Undefined;
		SetPersistentObject("TrPosX", pPC);
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, rMessage)
	If pRC <> 0 Then
		rMessage = GetErrorDescription(pRC);
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		tcOnServer.cmWriteLogEventAtServer(pFunction, "Warning", , , "Result description: " + rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pPC, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Warning", , , "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function GetDataPresentation(Val pStr)
	pStr = StrReplace(pStr, Char(1),  "");
	pStr = StrReplace(pStr, Char(2),  "");
	pStr = StrReplace(pStr, Char(3),  "");
	pStr = StrReplace(pStr, Char(4),  "");
	pStr = StrReplace(pStr, Char(5),  "");
	pStr = StrReplace(pStr, Char(6),  "");
	pStr = StrReplace(pStr, Char(7),  "");
	pStr = StrReplace(pStr, Char(8),  "");
	pStr = StrReplace(pStr, Char(11), "");
	pStr = StrReplace(pStr, Char(12), "");
	pStr = StrReplace(pStr, Char(14), "");
	pStr = StrReplace(pStr, Char(15), "");
	pStr = StrReplace(pStr, Char(16), "");
	pStr = StrReplace(pStr, Char(17), "");
	pStr = StrReplace(pStr, Char(18), "");
	pStr = StrReplace(pStr, Char(19), "");
	pStr = StrReplace(pStr, Char(20), "");
	pStr = StrReplace(pStr, Char(21), "");
	pStr = StrReplace(pStr, Char(22), "");
	pStr = StrReplace(pStr, Char(23), "");
	pStr = StrReplace(pStr, Char(24), "");
	pStr = StrReplace(pStr, Char(25), "");
	pStr = StrReplace(pStr, Char(26), "");
	pStr = StrReplace(pStr, Char(27), "");
	pStr = StrReplace(pStr, Char(28), "");
	pStr = StrReplace(pStr, Char(29), "");
	pStr = StrReplace(pStr, Char(30), "");
	Return pStr;
EndFunction // GetDataPresentation

// -----------------------------------------------------------------------------
Function GetApprove(pOutParams)
	vApprove = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "Approve=");
		If vPos > 0 Then
			vApprove = TrimAll(Mid(vTxtLine, vPos + 8));
			Break;
		EndIf;
	EndDo;
	Return vApprove;
EndFunction // GetApprove

// -----------------------------------------------------------------------------
Function GetResponseCode(pOutParams)
	vResponseCode = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "ResponseCode=");
		If vPos > 0 Then
			vResponseCode = TrimAll(Mid(vTxtLine, vPos + 13));
			Break;
		EndIf;	
	EndDo;
	Return vResponseCode;
EndFunction // GetResponseCode

// -----------------------------------------------------------------------------
Function GetAuthorizationID(pOutParams)
	vAuthorizationID = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "AuthorizationID=");
		If vPos > 0 Then
			vAuthorizationID = TrimAll(Mid(vTxtLine, vPos + 16));
			Break;
		EndIf;
	EndDo;
	Return vAuthorizationID;
EndFunction // GetAuthorizationID

// -----------------------------------------------------------------------------
Function GetInvoiceNumber(pOutParams)
	vParameterName = "InvoiceNumber=";
	vInvoiceNumber = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, vParameterName);
		If vPos > 0 Then
			vInvoiceNumber = TrimAll(Mid(vTxtLine, vPos + StrLen(vParameterName)));
			Break;
		EndIf;
	EndDo;
	Return vInvoiceNumber;
EndFunction // GetInvoiceNumber

// -----------------------------------------------------------------------------
Function GetReferenceNumber(pOutParams)
	vParameterName = "RRN=";
	vRRN = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, vParameterName);
		If vPos > 0 Then
			vRRN = TrimAll(Mid(vTxtLine, vPos + StrLen(vParameterName)));
			Break;
		EndIf;
	EndDo;
	Return vRRN;
EndFunction // GetReferenceNumber

// -----------------------------------------------------------------------------
Function GetTerminalNumber(pOutParams)
	vParameterName = "TerminalID=";
	vTerminalNo = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, vParameterName);
		If vPos > 0 Then
			vTerminalNo = TrimAll(Mid(vTxtLine, vPos + StrLen(vParameterName)));
			Break;
		EndIf;
	EndDo;
	Return vTerminalNo;
EndFunction // GetTerminalNumber

// -----------------------------------------------------------------------------
Function GetTransactionID(pOutParams)
	vParameterName = "TransactionID=";
	vTransactionID = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, vParameterName);
		If vPos > 0 Then
			vTransactionID = TrimAll(Mid(vTxtLine, vPos + StrLen(vParameterName)));
			Break;
		EndIf;
	EndDo;
	Return vTransactionID;
EndFunction // GetTransactionID

// -----------------------------------------------------------------------------
Function GetDateTime(pOutParams)
	vOperationDateTime = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "DateTime=");
		If vPos > 0 Then
			vOperationDateTime = TrimAll(Mid(vTxtLine, vPos + 9));
			Break;
		EndIf;
	EndDo;
	Return vOperationDateTime;
EndFunction // GetDateTime

// -----------------------------------------------------------------------------
Function GetVisualHostResponse(pOutParams)
	vResponse = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = StrFind(vTxtLine, "VisualHostResponse=");
		If vPos > 0 Then
			vResponse = TrimAll(Mid(vTxtLine, vPos + 19));
			Break;
		EndIf;
	EndDo;
	Return vResponse;
EndFunction // GetVisualHostResponse
	
// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pOutParams, pFunction)
	vMessage = NStr("ru = 'Выполнена on-line авторизация! Параметры: '; en = 'On-line authorization processed with parameters: '; de = 'On-line authorization processed with parameters: '") + Chars.LF + pOutParams;
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Information", , , vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pObj, pOneCopyOnly = False)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pObj.CashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,pObj.CashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
						  |de='Input cash register password please...';
						  |en='Input cash register password please...'");
		
		If  IsBlankString(vPasswordKKM) Then
			pCancel = True;
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverTrPosPOST, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pObj.CashRegister, pSlipTextArr, pOneCopyOnly));
			// Show InputCashRegisterPassword
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), , , , , vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pObj.CashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'"), , NStr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));
		Return;
	EndIf;
EndProcedure // PrintSlipDocument

#EndRegion
