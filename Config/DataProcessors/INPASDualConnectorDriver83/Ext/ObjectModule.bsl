
#Region Variables

Var DefaultConnectionParameters;
Var ConnectionParameters;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName) Export
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
Procedure SetPersistentObject(pName, pValue) Export
	#If Client Then
		amPersistentObjects.Insert(pName, pValue);
	#EndIf
EndProcedure // SetPersistentObject

// -----------------------------------------------------------------------------
Procedure pmDisconnect() Export
	Try
		vPC = GetPersistentObject("INPAS");
		vDeviceID = GetPersistentObject("INPAS_DeviceID");
		Disconnect(vPC, vDeviceID);
		SetPersistentObject("INPAS", Undefined);
		SetPersistentObject("INPAS_DeviceID", "");
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage, pSettingsObj = Undefined) Export
	rMessage = "";
	// Try to connect
	Try
		// Read connection parameters
		vConnParameters = CreditCardsProcessingSystemParameters.ConnectionParameters.Get();
		If vConnParameters = Undefined Or IsBlankString(vConnParameters) Then
			vConnParameters = DefaultConnectionParameters;
		EndIf;
		// Show connection parameters
		#If Client Then
			vFrm = GetCommonForm("InputText");
			vFrm.SelText = vConnParameters;
			vFrm.Caption = NStr("en = 'Please input configuration file data'; de = 'Please input configuration file data'; ru = 'Укажите здесь данные конфигурационного файла'");
			vConnParameters = vFrm.DoModal();
			If vConnParameters = Undefined Then
				Return False;
			EndIf;
			// Save parameters
			If pSettingsObj <> Undefined Then
				pSettingsObj.ConnectionParameters = New ValueStorage(vConnParameters);
				pSettingsObj.Write();
				CreditCardsProcessingSystemParameters = pSettingsObj.Ref;
			EndIf;
		#EndIf
		// Try to connect
		vDeviceID = "";
		vPC = Connect(Undefined, vDeviceID, rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the PIN pad device
		vDemo = "";
		vRC = vPC.ТестУстройства(rMessage, vDemo);
		If Not vRC Then
			rMessage = GetErrorDescription(vPC);
			Disconnect(vPC, vDeviceID);
			Return False;
		EndIf;
		
		Disconnect(vPC, vDeviceID);
		Return True;
	Except
		rMessage = ErrorDescription();
		Return False;
	EndTry;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	// Try to connect
	vDeviceID = "";
	vPC = Connect(pObj, vDeviceID, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма преавторизации!'; en = 'Zero sum preauthorization is not possible!'; de = 'Zero sum preauthorization is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Voice preauthorisation
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) And 
				Not IsBlankString(pObj.CreditCard.CardNumber) And 
				cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) And 
				ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vOutSlip = "";
			vChequeNumber = "";
			vRC = vPC.ПреавторизацияПоПлатежнойКарте(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vPC.PAN = vCardNumber;
				vCreditCardRef = SaveCreditCardData(vPC, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vPC);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.TransactionID = vChequeNumber;
			pObj.SlipText = vOutSlip;
			pObj.Write(DocumentWriteMode.Write);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(pObj, rMessage) Export
	// Try to connect
	vDeviceID = "";
	vPC = Connect(pObj, vDeviceID, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber = TrimAll(pObj.ReferenceNumber);
			vAuthorizationCode  = pObj.AuthorizationCode;
			vOutSlip = "";
			// Voice authorisation
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) 
				And Not IsBlankString(pObj.CreditCard.CardNumber) 
				And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) 
				And ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pObj.Sum, pObj.PaymentCurrency));
			vChequeNumber = "";
			vOutSlip = "";
			vRC = vPC.ОтменитьПреавторизациюПоПлатежнойКарте(vDeviceID, vCardNumber, pObj.Sum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"));
			// Save main authorization attributes to the payment document
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vReferenceNumber;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.Status = Enums.PreauthorisationStatuses.Cancelled;
			pObj.AuthorOfCancellation = SessionParameters.CurrentUser;
			pObj.DateOfCancellation = CurrentSessionDate();
			pObj.Write(DocumentWriteMode.Posting);
			// Print annulation slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
	// Not supported by driver
	rMessage = "";
	Try
		Return True;
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
		Return False;
	EndTry;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vDeviceID = "";
	vPC = Connect(pObj, vDeviceID, rMessage);
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
			If ValueIsFilled(pObj.CreditCard) And Not IsBlankString(pObj.CreditCard.CardNumber) Then 
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vCardNumberRight4Digits = Right(vCardNumber, 4);
				If Not IsBlankString(pObj.CreditCard.CardDataEnc) Then
					vCardDataEnc = TrimAll(pObj.CreditCard.CardDataEnc);
					vCardDataBin = TrimAll(pObj.CreditCard.CardSecurityCode);
				EndIf;
			EndIf;
			// Fill operation currency code
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(pObj.Preauthorisation.AuthorizationCode);
				vReferenceNumber = TrimAll(pObj.Preauthorisation.ReferenceNumber);
				vChequeNumber = TrimAll(pObj.Preauthorisation.TransactionID);
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
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
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"));
			Else
				If pSum > 0 Then
					// Call processing
					WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
					vOutSlip = "";
					vChequeNumber = "";
					vRC = vPC.ОплатитьПлатежнойКартой(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
						Return False;
					EndIf;
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
				Else
					// Call processing
					vPayment = Undefined;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vPayment = pObj.Payment;
						If ValueIsFilled(vPayment) Then
							While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
								vPayment = vPayment.Payment;
								If Not ValueIsFilled(vPayment) Then
									Break;
								EndIf;
							EndDo;
						EndIf;
					ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
						vPayment = pObj.CustomerPayment;
					EndIf;
					If ValueIsFilled(vPayment) Then
						vReferenceNumber = TrimAll(vPayment.ReferenceNumber);
					Else
						Raise NStr("en='Return should be based on previous payment!'; de='Return should be based on previous payment!'; ru='Возврат должен быть на основании предыдущего платежа!'");
					EndIf;
					WriteLogEvent(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
					vChequeNumber = "";
					vOutSlip = "";
					vRC = vPC.ВернутьПлатежПоПлатежнойКарте(vDeviceID, vCardNumber, -pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
						Return False;
					EndIf;
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"));
				EndIf;
			EndIf;
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCreditCardRef = SaveCreditCardData(vPC, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vPC);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = vOutSlip;
			pObj.Write(DocumentWriteMode.Write);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
				Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
				Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
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
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vDeviceID = "";
	vPC = Connect(pObj, vDeviceID, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber = TrimAll(pObj.ReferenceNumber);
			vAuthorizationCode  = pObj.AuthorizationCode;
			vOutSlip = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма аннуляции!'; en = 'Zero sum annulation is not possible!'; de = 'Zero sum annulation is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Voice authorisation
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) 
				And Not IsBlankString(pObj.CreditCard.CardNumber) 
				And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) 
				And ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vChequeNumber = "";
			vOutSlip = "";
			vRC = vPC.ОтменитьПлатежПоПлатежнойКарте(vDeviceID, vCardNumber, pSum, vChequeNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization("", vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"));
			// Save main authorization attributes to the payment document
			If TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
				pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vReferenceNumber;
				pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			Else
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + "Ref. #" + vReferenceNumber;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + Chars.LF + vOutSlip;
			EndIf;
			pObj.Write(DocumentWriteMode.Write);
			// Print annulation slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulatePayment

// -----------------------------------------------------------------------------
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister) Export
	vUserChoice = Undefined;
	vUserChoices = New ValueList();
	vUserChoices.Add(2, NStr("en='Print short report'; ru='Печать краткого отчета'; de='Drucken Kurzbericht'"));
	vUserChoices.Add(1, NStr("en='Print detailed report'; ru='Печать детального отчета'; de='Drucken ausführlichen Bericht'"));
	vUserChoices.Add(0, NStr("en='Totals check (settlement)'; ru='Сверка итогов'; de='Überleitung der Ergebnisse'"));
	#If Client Then
		vUserChoiceItem = vUserChoices.ChooseItem(NStr("en='Operation type'; ru='Тип операции'; de='Betriebstyp'"));
		If vUserChoiceItem = Undefined Then
			Return True;
		EndIf;
		vUserChoice = vUserChoiceItem.Value;
	#Else
		vUserChoice = 1;
	#EndIf
	// Try to connect
	vDeviceID = "";
	vPC = Connect(pCashRegister, vDeviceID, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		vStruct = New Structure("CashRegister", pCashRegister);
		If vUserChoice = 0 Then
			vOperationType = NStr("en = 'CreditCardProcessingSystem.Settlement'; de = 'CreditCardProcessingSystem.Settlement'; ru = 'СистемаПроцессингаКредитныхКарт.СверкаИтогов'");
			vSlipName = NStr("en = 'Settlement'; de = 'Settlement'; ru = 'Сверка итогов'");   
		ElsIf vUserChoice = 1 Then
			vOperationType = NStr("en = 'CreditCardProcessingSystem.PrintDetailedReport'; de = 'CreditCardProcessingSystem.PrintDetailedReport'; ru = 'СистемаПроцессингаКредитныхКарт.ПечатьДетальногоОтчета'");
			vSlipName = NStr("en = 'Print detailed report'; de = 'Print detailed report'; ru = 'Печать детального отчета'");
		ElsIf vUserChoice = 2 Then
			vOperationType = NStr("en = 'CreditCardProcessingSystem.PrintShortReport'; de = 'CreditCardProcessingSystem.PrintShortReport'; ru = 'СистемаПроцессингаКредитныхКарт.ПечатьКраткогоОтчета'");
			vSlipName = NStr("en = 'Print short report'; de = 'Print short report'; ru = 'Печать краткого отчета'");
		Else
			vOperationType = "";
			vSlipName = "";
		EndIf;
		// Pay card system object was created successfully
		Try
			// Bank day settlement
			vOutSlip = "";
			If vUserChoice = 0 Then
				vRC = vPC.ИтогиДняПоКартам(vDeviceID, vOutSlip);
			ElsIf vUserChoice = 1 Then
				vRC = vPC.ПолучитьОтчет(True, vOutSlip);
			Else
				vRC = vPC.ПолучитьОтчет(False, vOutSlip);
			EndIf;
			If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage) Then
				Return False;
			EndIf;
			// Print settlement slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				vStruct = New Structure("CashRegister", pCashRegister);
				PrintSlipDocument(vSlipTxtArr, vStruct);
			EndIf;
			// Success
			#If Client Then
				DoMessageBox(NStr("en = 'Operation completed successfully!'; de = 'Operation completed successfully!'; ru = 'Операция выполнена успешно!'"));
			#EndIf
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, vOperationType, rMessage);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetTerminalId(pObj)
	vTerminalNumber = "";
	If pObj = Undefined Then
		vTerminalNumber = StrReplace(TrimAll(CreditCardsProcessingSystemParameters.TerminalNumber), " ", "");
	ElsIf TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj) And Not IsBlankString(pObj.TerminalNumber) And TrimAll(pObj.TerminalNumber) <> "0" Then
		vTerminalNumber = StrReplace(TrimAll(pObj.TerminalNumber), " ", "");
	ElsIf Not TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj.CashRegister) And Not IsBlankString(pObj.CashRegister.TerminalNumber) And TrimAll(pObj.CashRegister.TerminalNumber) <> "0" Then
		vTerminalNumber = StrReplace(TrimAll(pObj.CashRegister.TerminalNumber), " ", "");
	Else
		vTerminalNumber = StrReplace(TrimAll(CreditCardsProcessingSystemParameters.TerminalNumber), " ", "");
	EndIf;
	If IsBlankString(vTerminalNumber) Then
		vTerminalNumber = "00000000";
	Else
		If StrLen(vTerminalNumber) < 8 And cmIsNumber(vTerminalNumber) Then
			vTerminalNumber = Format(Number(vTerminalNumber), "ND=8; NFD=; NZ=; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vTerminalNumber;
EndFunction // GetTerminalId

// -----------------------------------------------------------------------------
Function GetErrorDescription(vPC)
	vMessage = "";
	Try
		vPC.ПолучитьОшибку(vMessage);
	Except
		vMessage = NStr("en='<Description unknown>!'; de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndTry;
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr,pObj)
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
	EndIf;
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC, pObj)
	If ConnectionParameters <> Undefined Then
		pPC.PortNumber = ConnectionParameters.COMPort;
		pPC.BaudRate = ConnectionParameters.BaudRate;
		pPC.CurrencyCode = ConnectionParameters.CurrencyCode;
		pPC.TerminalID = GetTerminalId(pObj);
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(pObj, rDeviceID, rMessage)
	// Reset return status
	rMessage = "";
	rDeviceID = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("INPAS");
		rDeviceID = GetPersistentObject("INPAS_DeviceID");
		
		If vPC = Undefined Then
			#If Client Then
				Try
					AttachAddIn("Addin.a_inpasDC1c83");
					vPC = New("Addin.a_inpasDC1c83");
				Except
					LoadAddIn("a_inpasDC1c83.dll");
					vPC = New("Addin.a_inpasDC1c83");
				EndTry;
			#Else
				vPC = New("Addin.a_inpasDC1c83");
			#EndIf
			
			// Read connection parameters
			ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get(), pObj);
			
			If ConnectionParameters = Undefined Then
				Raise NStr("en = 'INPAS parameters XML should be filled!'; de = 'INPAS parameters XML should be filled!'; ru = 'Не заполнен XML файл с параметрами подключения к системе ИНПАС!'");
			EndIf;
			
			SetConnectionParameters(vPC, pObj); 
			
			// Connect to device and get device id
			vRC = vPC.Подключить(rDeviceID);
			If Not vRC Then
				rMessage = GetErrorDescription(vPC);
				Disconnect(vPC, rDeviceID);
				Return Undefined;
			EndIf;
			
			SetPersistentObject("INPAS", vPC);
			SetPersistentObject("INPAS_DeviceID", rDeviceID);
		EndIf;
		
		// OK
		Return vPC;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC, pDeviceID)
	Try
		If pPC <> Undefined Then
			pPC.Отключить(pDeviceID);
		EndIf;
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, rMessage)
	If Not pRC Then
		If Not IsBlankString(TrimAll(pPC.Status)) Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + TrimAll(pPC.Status) + Chars.LF 
			+ NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pPC);
		Else
			rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pPC);
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
		Return False;
	Else
		Return True;
	EndIf;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pPC, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function GetCardExpDate(pYYMM)
	vCardExpDate = '00010101';
	If Not IsBlankString(pYYMM) and StrLen(pYYMM) = 4 Then
		vCardExpDate = BegOfMonth(Date(2000 + Number(Left(pYYMM, 2)), Number(Right(pYYMM, 2)), 1, 0, 0, 0));
	EndIf;
	Return vCardExpDate;
EndFunction // GetCardExpDate

// -----------------------------------------------------------------------------
Function GetCardOwner(pObj)
	vCardOwner = Undefined;
	If TypeOf(pObj) = Type("DocumentObject.Payment") 
		Or TypeOf(pObj) = Type("DocumentObject.Return") 
		Or TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
		vCardOwner = pObj.Payer;
	ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
		vCardOwner = pObj.AccountingCustomer;
	EndIf;
	Return vCardOwner;
EndFunction // GetCardOwner

// -----------------------------------------------------------------------------
Function GetCardType(pPC)
	// Try to retrieve card type from the driver object properties
	vCardTypeStr = "";
	If IsBlankString(vCardTypeStr) And Not IsBlankString(TrimAll(pPC.ReceiptText)) Then
		vPrintData = TrimAll(pPC.ReceiptText);
		vPosStr = Find(vPrintData, "^Карта^");
		If vPosStr > 0 Then
			vPrintData = Mid(vPrintData, vPosStr + 7);
			If Not IsBlankString(vPrintData) Then
				vPosStr = Find(vPrintData, "~");
				If vPosStr > 0 Then
					vCardTypeStr = TrimAll(Left(vPrintData, vPosStr - 1));
				Else
					vCardTypeStr = TrimAll(vPrintData);
				EndIf;
			EndIf;
		Else
			vPosStr = Find(vPrintData, "MasterCard");
			If vPosStr > 0 Тогда
				vCardTypeStr = "MasterCard";
			Else
				vPosStr = Find(vPrintData, "Visa");
				If vPosStr > 0 Тогда
					vCardTypeStr = "Visa";
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	// Try to find card type			
	vCardTypeRef = Catalogs.CreditCardTypes.EmptyRef();
	If Not IsBlankString(vCardTypeStr) Then
		vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vCardTypeStr);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

// -----------------------------------------------------------------------------
Function GetCardHolder(pPC)
	// Try to retrieve card holder name from the driver object properties
	vCardHolder = "";
	If IsBlankString(vCardHolder) And Not IsBlankString(TrimAll(pPC.ReceiptText)) Then
		vPrintData = TrimAll(pPC.ReceiptText);
		vPosStr = Find(vPrintData, "^Держатель^");
		If vPosStr > 0 Then
			vPrintData = Mid(vPrintData, vPosStr + 11);
			If Not IsBlankString(vPrintData) Then
				vPosStr = Find(vPrintData, "~");
				If vPosStr > 0 Then
					vCardHolder = TrimAll(Left(vPrintData, vPosStr - 1));
				Else
					vCardHolder = TrimAll(vPrintData);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vCardHolder;
EndFunction // GetCardHolder

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pPC, pObj)
	vCardNumber = StrReplace(TrimAll(pPC.PAN), " ", "");
	vCardRef = Undefined;
	If Not IsBlankString(vCardNumber) And cmIsNumber(vCardNumber) Then
		vCardRef = Catalogs.CreditCards.FindByAttribute("CardNumber", vCardNumber);
		If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
			vCardRef = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		vCardObj.CardOwner = GetCardOwner(pObj);
		vCardObj.CardType = GetCardType(pPC);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardHolder = GetCardHolder(pPC);
		vCardObj.CardValidTillDate = GetCardExpDate(pPC.Expiry);
		
		vCardDataEnc = "";
		vCardDataBin = "";
		vCardNumberRight4Chars = "";
		rMessage = "";
		vRC = pPC.ПолучитьДопДанныеКарты(vCardDataEnc, vCardDataBin, vCardNumberRight4Chars);
		If Not ProcessResultCode(vRC, pPC, NStr("en = 'CreditCardProcessingSystem.GetCardExtraData'; de = 'CreditCardProcessingSystem.GetCardExtraData'; ru = 'СистемаПроцессингаКредитныхКарт.ПолучитьДопДанныеКарты'"), rMessage) Then
			Return vCardRef;
		EndIf;
		
		vCardObj.CardDataEnc = vCardDataEnc;
		vCardObj.CardSecurityCode = vCardDataBin;
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	Else
		vCardType = GetCardType(pPC);
		If ValueIsFilled(vCardType) And Not ValueIsFilled(vCardRef.CardType) Then
			vCardObj = vCardRef.GetObject();
			vCardObj.CardType = vCardType;
			vCardObj.CardValidTillDate = GetCardExpDate(pPC.Expiry);
			vCardObj.Write();
		EndIf;
	EndIf;
	Return vCardRef;
EndFunction // SaveCreditCardData

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
Procedure LogOnLineAuthorization(pAuthCode, pRRN, pFunction)
	vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + pAuthCode + "/" + pRRN;
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

#EndRegion

#Region Initialize    

// -----------------------------------------------------------------------------
DefaultConnectionParameters = 
"<?xml version=""1.0"" ?>  
|<INPASConnectionParameters> 
|	<COMPort>9</COMPort>
|	<BaudRate>115200</BaudRate>
|	<CurrencyCode>643</CurrencyCode>
|	<SlipCharLineLength>0</SlipCharLineLength>
|	<CheckNumberReturn>0</CheckNumberReturn>
|	<AuthorisationCodeReturn>0</AuthorisationCodeReturn>
|</INPASConnectionParameters>"; 

#EndRegion
