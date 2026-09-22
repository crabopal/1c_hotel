
#Region Public

// -----------------------------------------------------------------------------
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
		OpenForm("CommonForm.tcInputText", New Structure("Text", vConnParameters), , , , , New NotifyDescription("AfterShowInputText", tcCreditCardsProcessingSystemDriverUCS, pPaymentTerminal.Ref));
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
		vPC = Connect(Undefined, vMessage, pExtraParams, pConnParameters);
		If vPC = Undefined Then
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'") + Chars.LF + vMessage);
			Return;
		EndIf;
		// Initialize connection to the PIN pad device
		vAddInfo = "";
		vDemoAddInfo = "";
		vRC = vPC.DeviceTest(vAddInfo, vDemoAddInfo);
		If Not vRC Then        
			GetErrorDescription(vPC, vMessage);
			If vAddInfo <> vDemoAddInfo And Not IsBlankString(vAddInfo) And Not IsBlankString(vDemoAddInfo) Then
				vMessage = vMessage + Chars.LF + vAddInfo + Chars.LF + vDemoAddInfo;
			ElsIf Not IsBlankString(vAddInfo) Then 
				vMessage = vMessage + Chars.LF + vAddInfo;
			ElsIf Not IsBlankString(vDemoAddInfo) Then 
				vMessage = vMessage + Chars.LF + vDemoAddInfo;
			EndIf;
			Disconnect(vPC);
			ShowMessageBox(, NStr("en = 'Error validating pay card system connection!'; de = 'Fehler bei der Prüfung des Kreditkartenverabeitungssystemanschlusses!'; ru = 'Ошибка проверки подключения системы процессинга кредитных карт!'") + Chars.LF + vMessage);
			Return;
		Else
			vMessage = vAddInfo + Chars.LF + vDemoAddInfo;
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
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage, pPaymentTerminal) Export
	// Try to connect
	vConnectionParameters = "";
	vPC = Connect(pObj, rMessage, pPaymentTerminal, vConnectionParameters);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vOperationType = NStr("en='CreditCardProcessingSystem.AuthorizePayment';de='CreditCardProcessingSystem.AuthorizePayment';ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'");
			// Try to get device id and open connection to the terminal
			vDevID = "";
			vRC = vPC.Open(vDevID);
			If Not vRC Then
				vErrCode = GetErrorDescription(vPC, rMessage);
				Return False;
			EndIf;
			// Init
			vOutSlip = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма!'; en = 'Zero amount is not possible!'; de = 'Zahlungsbetrag gleich Null ist!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта!'; en = 'Currency is not filled!'; de = 'Währungs ist nicht gefüllt!'");
			Else
				vPaymentCurrencyCode = tcOnServer.cmGetAttributeByRef(pObj.PaymentCurrency, "Code");
				If vConnectionParameters.Currency = 810 And vPaymentCurrencyCode <> 643 And vPaymentCurrencyCode <> 810 
					Or vConnectionParameters.Currency <> 810 And vPaymentCurrencyCode <> vConnectionParameters.Currency Then
					Raise NStr("en = 'Payment currency differs from the currency of payment terminal!'; 
							   |de = 'Zahlungswährung von der Währung des Zahlungsterminal sich unterscheiden!'; 
							   |ru = 'Валюта платежа отличается от валюты платежного терминала!'");
				EndIf;
			EndIf;
			// Voice authorisation
			vAuthorizationCode = "";
			vReferenceNumber = "";
			vVoicepay = False;
			If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) And ValueIsFilled(pObj.CreditCard) Then
				vCreditCardCardNumber = tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardNumber");
				vCreditCardCardValidTillDater = tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardValidTillDate");
				If ValueIsFilled(vCreditCardCardNumber) And IsNumber(TrimAll(vCreditCardCardNumber)) And ValueIsFilled(vCreditCardCardValidTillDater) Then
					vAuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardType")) + Chars.LF 
								+ TrimAll(vCreditCardCardNumber) + " " + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardSecurityCode")) + Chars.LF 
								+ TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CreditCard, "CardHolder")) + " " + Format(vCreditCardCardValidTillDater, "DF=MM.yyyy");
					vVoicepay = True;
				EndIf;
			EndIf;
			// Do operation
			vSlipName = "";
			If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "AuthorizationCode"));
				vReferenceNumber = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"));
				vVoicepay = True;
				// Call processing
				vOperationType = NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation';de='CreditCardProcessingSystem.AuthorisationConfirmation';ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'");
				tcOnServer.cmWriteLogEventAtServer(vOperationType, "Information", , , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + tcCreditCardsProcessingSystemDriverAtServer.FormatSum(pSum, pObj.PaymentCurrency));
				vSlipName = NStr("en = 'Auth. confirmation'; de = 'Auth. confirmation'; ru = 'Расчет по преавторизации'");
			Else
				If pSum > 0 Then
					// Call processing
					vOperationType = NStr("en='CreditCardProcessingSystem.AuthorizePayment';de='CreditCardProcessingSystem.AuthorizePayment';ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'");
					tcOnServer.cmWriteLogEventAtServer(vOperationType, "Information", , , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + tcCreditCardsProcessingSystemDriverAtServer.FormatSum(pSum, pObj.PaymentCurrency));
					vSlipName = NStr("en = 'Authorisation'; de = 'Authorisation'; ru = 'Авторизация'");
				Else
					// Take parameters from the payment
					vPayment = Undefined;
					If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
						If ValueIsFilled(pObj.Payment) Then
							vPayment = pObj.Payment;
							If ValueIsFilled(vPayment) Then
								While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
									vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
									If Not ValueIsFilled(vPayment) Then
										Break;
									EndIf;
								EndDo;
							EndIf;
						EndIf;
					ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
						If ValueIsFilled(pObj.CustomerPayment) Then
							vPayment = pObj.CustomerPayment;
						EndIf;
					EndIf;
					If ValueIsFilled(vPayment) Then
						vReferenceNumber = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber"));
						vAuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode"));
					Else
						vReferenceNumber = TrimAll(pObj.ReferenceNumber);
						vAuthorizationCode = TrimAll(pObj.AuthorizationCode);
					EndIf;
					vOperationType = NStr("en='CreditCardProcessingSystem.ReturnPayment';de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'");
					tcOnServer.cmWriteLogEventAtServer(vOperationType, "Information", , , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + tcCreditCardsProcessingSystemDriverAtServer.FormatSum(-pSum, pObj.PaymentCurrency));
					vSlipName = NStr("en='Return';de='Return';ru='Возврат'");
				EndIf;
			EndIf;
			// Do smart payment
			vCardNumber = "";
			rOutSlip = "";
			rMustcommit = False;
			vErrCode = 0;
			vRC = vPC.SmartPay(vDevID, vCardNumber, pSum, vReferenceNumber, vAuthorizationCode, rOutSlip, vVoicepay, rMustcommit);
			If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage, vErrCode) Then
				If vErrCode = -101 And pSum < 0 And Not IsBlankString(vReferenceNumber) Then
					vReferenceNumber = "";
					vRC = vPC.SmartPay(vDevID, vCardNumber, pSum, vReferenceNumber, vAuthorizationCode, rOutSlip, vVoicepay, rMustcommit);
					If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage) Then
						Return False;
					EndIf;
				Else					
					// Print authorization slip
					If Not pPaymentTerminal.PrintSlipInCheque And 
					   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
					   Not IsBlankString(rOutSlip) Then
						// Format slip
						vOutSlip = GetOperationSlipCheque(rOutSlip, vSlipName);
						vSlipTxtArr = GetTextLinesArray(vOutSlip);
						PrintSlipDocument(vSlipTxtArr, pObj);
					EndIf;
					Return False;
				EndIf;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, vOperationType);
			// Format slip
			vOutSlip = GetOperationSlipCheque(rOutSlip, vSlipName);
			// Save credit card data if neccessary
			If pPaymentTerminal.SaveCreditCardsData Then
				vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardDataUCS(vCardNumber, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
				EndIf;
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			If pSum < 0 And (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment")) Then
				pObj.AnnulationSlipText = "Ref. #" + vReferenceNumber + Chars.LF;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + vOutSlip;
			Else
				pObj.SlipText = vOutSlip;
			EndIf;
			// Print authorization slip
			If Not pPaymentTerminal.PrintSlipInCheque And 
			   Not pPaymentTerminal.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Commit operation
			If rMustcommit Then
				vRC = vPC.Commit(vDevID, vReferenceNumber);
				If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage) Then
					Return False;
				EndIf;
			EndIf;
			// Close connection
			vRC = vPC.Close(vDevID);
			ProcessResultCode(vRC, vPC, vOperationType, rMessage);
			vPC = Undefined;
			// Return
			Return True;
		Except
			vRC = vPC.Close(vDevID);
			rMessage = ErrorDescription();
			ProcessException(vPC, vOperationType, rMessage);
			vPC = Undefined;
			Return False;
		EndTry;
	EndIf;	
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister, pPaymentTerminal, pOperationType = 1) Export
	If TypeOf(pPaymentTerminal) = Type("Structure") Then  
		vPaymentTerminalArr = pPaymentTerminal;
	Else 
		vPaymentTerminalArr =  tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	EndIf;
	// Try to connect
	vPC = Connect(pCashRegister, rMessage, vPaymentTerminalArr, Undefined);
	If vPC = Undefined Then
		Return False;
	Else
		vStruct = New Structure("CashRegister", pCashRegister);
		vOperationType = "";
		vSlipName = "";
		If pOperationType = 1 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.Settlement';de='CreditCardProcessingSystem.Settlement';ru='СистемаПроцессингаКредитныхКарт.СверкаИтогов'");
			vSlipName = NStr("en='Settlement';de='Settlement';ru='Сверка итогов'");
		ElsIf pOperationType = 2 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.PrintShortReport';de='CreditCardProcessingSystem.PrintShortReport';ru='СистемаПроцессингаКредитныхКарт.ПечатьКраткогоОтчета'");
			vSlipName = NStr("en='Print short report';de='Print short report';ru='Печать краткого отчета'");
		ElsIf pOperationType = 3 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.PrintDetailedReport';de='CreditCardProcessingSystem.PrintDetailedReport';ru='СистемаПроцессингаКредитныхКарт.ПечатьДетальногоОтчета'");
			vSlipName = NStr("en='Print detailed report';de='Print detailed report';ru='Печать детального отчета'");
		EndIf;
		// Try to get device id and open connection to the terminal
		vDevID = "";
		vRC = vPC.Open(vDevID);
		If Not vRC Then
			GetErrorDescription(vPC, rMessage);
			Return False;
		EndIf;
		// Init
		rOutSlip = "";
		// Pay card system object was created successfully
		Try
			If pOperationType = 1 Then
				// Bank day settlement
				vRC = vPC.Settlement(vDevID, rOutSlip);
			Else
				vRC = vPC.PrintReport(vDevID, pOperationType, rOutSlip);
			EndIf;
			// Check result code
			If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = GetOperationSlipCheque(rOutSlip, vSlipName);
			// Print annulation slip
			If Not vPaymentTerminalArr.PrintSlipInCheque 
				And Not vPaymentTerminalArr.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = GetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct, True);
			EndIf;
			// Close connection
			vRC = vPC.Close(vDevID);
			ProcessResultCode(vRC, vPC, vOperationType, rMessage);
			vPC = Undefined;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, vOperationType, rMessage);
			Return False;
		EndTry;
	EndIf;
	Return True;	
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	rMessage = "";
	Return True;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	// Not supported by driver
	rMessage = "";
	Try
		pObj.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
		pObj.AuthorOfCancellation = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
		pObj.DateOfCancellation = tcOnServer.cmGetServerCurrentSessionDate();
		Return True;
	Except
		rMessage = ErrorDescription();
		vOperationType = NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'");
		ProcessException(Undefined, vOperationType, rMessage);
		Return False;
	EndTry;	
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

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, rMessage, rErrCode = 0)
	rErrCode = 0;
	If Not pRC Then
		rErrCode = GetErrorDescription(pPC, rMessage);
		If rErrCode <> 0 Then
			rMessage = NStr("en = 'Host response: '; de = 'Host response: '; ru = 'Ответ хоста: '") + Format(rErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF 
						+ NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung.'") + rMessage;
		Else
			rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung.'") + rMessage;
		EndIf;
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
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	#If Not WebClient Then
		If pStr <> Undefined And Not IsBlankString(pStr) Then
			vConnParameters = New Structure("ConnectionType, RSPort, RSSpeed, RSTimeout, TCPIP, TCPPort, TCPTimeout, Currency, WriteLog, LogFileName, ArchPeriod, HeadLn1, HeadLn2, HeadLn3, HeadLn4, UseCommit, PathToDataBase, PostOperTimeout, InitTimeout", 
											 0,              0,      0,       0,         "",    0,       0,          0,        False,    "",          0,          "",      "",      "",      "",      False,     "",             0,               0);
			vReader = New XMLReader();
			vReader.SetString(pStr);
			While vReader.Read() Do
				If vReader.NodeType = XMLNodeType.StartElement Then
					If vReader.Name = "ConnectionType" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.ConnectionType = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "RSPort" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.RSPort = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "RSSpeed" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.RSSpeed = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "RSTimeout" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.RSTimeout = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "TCPIP" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.TCPIP = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "TCPPort" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.TCPPort = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "TCPTimeout" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.TCPTimeout = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "Currency" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.Currency = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "WriteLog" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								If Lower(TrimAll(vReader.Value)) = "false" Then
									vConnParameters.WriteLog = False;
								Else
									vConnParameters.WriteLog = True;
								EndIf;
							EndIf;
						EndIf;
					ElsIf vReader.Name = "LogFileName" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.LogFileName = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "ArchPeriod" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.ArchPeriod = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "HeadLn1" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.HeadLn1 = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "HeadLn2" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.HeadLn2 = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "HeadLn3" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.HeadLn3 = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "HeadLn4" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.HeadLn4 = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "UseCommit" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								If Lower(TrimAll(vReader.Value)) = "false" Then
									vConnParameters.UseCommit = False;
								Else
									vConnParameters.UseCommit = True;
								EndIf;
							EndIf;
						EndIf;
					ElsIf vReader.Name = "PathToDataBase" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.PathToDataBase = TrimAll(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "PostOperTimeout" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.PostOperTimeout = Number(vReader.Value);
							EndIf;
						EndIf;
					ElsIf vReader.Name = "InitTimeout" Then
						If vReader.Read() Then
							If vReader.NodeType = XMLNodeType.Text Then
								vConnParameters.InitTimeout = Number(vReader.Value);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			vReader.Close();
			vReader = Undefined;
		EndIf;
	#EndIf
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pAuthCode, pRRN, pFunction)
	vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; 
					|de = 'On-line authorization processed with authorization code/RRN: '; 
					|ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + pAuthCode + "/" + pRRN;
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Information", , , vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Function IsNumber(pStr) 
	Try 
		vNumStr = Number(pStr);
		Return True;
	Except
	EndTry;
	Return False;
EndFunction // IsNumber

// -----------------------------------------------------------------------------
Function GetTerminalId(pObj, pPaymentTerminal)
	vTerminalNumber = "";
	If TypeOf(pObj) = Type("CatalogRef.CashRegisters") Then
		vObj = tcOnServer.cmGetAtributeAsArray(pObj);
	EndIf;
	If pObj = Undefined Then
		vTerminalNumber = StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(pPaymentTerminal, "TerminalNumber")), " ", "");
	ElsIf TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj) And Not IsBlankString(vObj.TerminalNumber) And TrimAll(vObj.TerminalNumber) <> "0" Then
		vTerminalNumber = StrReplace(TrimAll(vObj.TerminalNumber), " ", "");
	ElsIf Not TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj.CashRegister) And Not IsBlankString(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")) And TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")) <> "0" Then
		vTerminalNumber = StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "TerminalNumber")), " ", "");
	Else
		vTerminalNumber = StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(pPaymentTerminal, "TerminalNumber")), " ", "");
	EndIf;
	If IsBlankString(vTerminalNumber) Then
		vTerminalNumber = "0000000000";
	Else
		If StrLen(vTerminalNumber) < 10 And IsNumber(vTerminalNumber) Then
			vTerminalNumber = Format(Number(vTerminalNumber), "ND=10; NFD=; NZ=; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vTerminalNumber;
EndFunction // GetTerminalId

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pObj, pOneCopyOnly = False)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pObj.CashRegister);
	If Not vDriver = Undefined Then
		vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(, pObj.CashRegister);
		vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
						  |de='Input cash register password please...';
						  |en='Input cash register password please...'");
		
		If  IsBlankString(vPasswordKKM) Then
			vNotifity = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverUCS, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pObj.CashRegister, pSlipTextArr, pOneCopyOnly));
			// Show InputCashRegisterPassword
			OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), , , , , vNotifity);
		Else
			vDriver.pmPrintSlip(pSlipTextArr, pObj.CashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		EndIf;
	Else
		ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
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
Function GetOperationSlipCheque(pSlipCheque, pSlipName)
	vTildaSPos  = StrFind(pSlipCheque, "[cut]");
	If vTildaSPos > 0 Then
		vSlipCheque = TrimAll(pSlipName) + Chars.LF + Left(pSlipCheque, vTildaSPos - 1);
	Else
		vSlipCheque = TrimAll(pSlipName) + Chars.LF +  pSlipCheque;
	EndIf;
	Return vSlipCheque;
EndFunction // GetOperationSlipCheque

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC, pObj, pPaymentTerminal, pConnectionParameters)
	If pConnectionParameters <> Undefined Then
		pPC.TerminalID = GetTerminalId(pObj, pPaymentTerminal);
		pPC.RcpWidth = pPaymentTerminal.SlipCharLineLength;
		If pConnectionParameters.RSTimeout <= 0 Then
			pConnectionParameters.RSTimeout = 3000;
		EndIf;
		FillPropertyValues(pPC, pConnectionParameters);
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(pObj, rMessage, pPaymentTerminal, rConnectionParameters)
	// Reset return status
	rMessage = "";
	// Try to create external component
	#If Not MobileClient Then
		Try
			vPC = Undefined;
			// Get connection parameters
			rConnectionParameters = ParseConnectionParameters(tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardsProcessingSystemConnectionParameters(pPaymentTerminal));
			If rConnectionParameters = Undefined Then
				Raise NStr("en = 'UCS parameters XML data should be filled!'; de = 'UCS parameters XML data should be filled!'; ru = 'Не заполнен XML файл с параметрами подключения к системе UCS!'");
			EndIf;
			vPC = New COMObject("AddIn.UCS_EFTPOS");
			SetConnectionParameters(vPC, pObj, pPaymentTerminal, rConnectionParameters);
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
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function GetErrorDescription(vPC, rMessage)
	vErrCode = -1;
	rMessage = "";
	Try
		vErrCode = vPC.GetLastError(rMessage);
	Except
		rMessage = NStr("en='<Description unknown>!';de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndTry;
	Return vErrCode;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function GetDefaultConnectionParameters()
	Return "<UCSConnectionParameters>
	|	<ConnectionType>1</ConnectionType> <!-- 0 - RS/232; 1 - TCP/IP -->
	|	<RSPort>0</RSPort> <!-- COM port number -->
	|	<RSSpeed>0</RSSpeed> <!-- 0 - 2400, 1 - 4800, 2 - 9600, 3 - 19200, 4 - 38400, 5 - 57600, 6 - 115200 -->
	|	<RSTimeout>0</RSTimeout>
	|	<TCPIP>192.168.0.0</TCPIP>
	|	<TCPPort>4001</TCPPort>
	|	<TCPTimeout>0</TCPTimeout>
	|	<Currency>810</Currency>
	|	<WriteLog>false</WriteLog>
	|	<LogFileName></LogFileName>
	|	<ArchPeriod>0</ArchPeriod> <!-- 0 - do not archive, 1 - day, 2 - week, 3 - month, 4 - year -->
	|	<HeadLn1></HeadLn1>
	|	<HeadLn2></HeadLn2>
	|	<HeadLn3></HeadLn3>
	|	<HeadLn4></HeadLn4>
	|	<UseCommit>false</UseCommit>
	|	<PathToDataBase></PathToDataBase>
	|	<PostOperTimeout>5</PostOperTimeout>
	|	<InitTimeout>10</InitTimeout>
	|</UCSConnectionParameters>";
EndFunction // GetDefaultConnectionParameters

#EndRegion
