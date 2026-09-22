
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
		Disconnect(vPC);
		SetPersistentObject("INPAS", Undefined);
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
			vFrm.Caption = NStr("en='Please input configuration file data'; de='Please input configuration file data'; ru='Укажите здесь данные конфигурационного файла'");
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
		vPC = Connect(Undefined, rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the PIN pad device
		vRC = vPC.ТестУстройства(rMessage);
		If Not vRC Then
			rMessage = GetErrorDescription(vPC);
			Disconnect(vPC);
			Return False;
		EndIf;

		Disconnect(vPC);
		Return True;
	Except
		rMessage = ErrorDescription();
		Return False;
	EndTry;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(pObj, rMessage);
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
			// Fill operation currency code
			vPC.CurrencyCode = Format(pObj.PaymentCurrency.Code, "ND=3; NFD=0; NZ=; NLZ=; NG=");
			// Voice preauthorisation
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) And 
			   Not IsBlankString(pObj.CreditCard.CardNumber) 
			   And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) 
			   And ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vPC.PAN = vCardNumber;
				vPC.Expiry = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vPC.PAN = "";
				vPC.Expiry = "";
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vRC = vPC.ПреавторизацияПоПлатежнойКарте(vCardNumber, pSum, vReferenceNumber, vAuthorizationCode);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Check card expiry date
			#If Client Then
				If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
					If Not ValueIsFilled(pObj.CreditCard) And 
					   IsBlankString(TrimAll(vPC.Expiry)) Then
						// Card number is returned with or without mask but expiry date is empty. 
						// Ask user to enter it from the card.
						vFrm = ThisObject.GetForm("InputPayCardDataManually");
						vFrm.SelPayCardNumber = cmGetCreditCardDescription(TrimAll(vPC.PAN));
						vFrm.SelDescription = NStr("en='Please enter card expiration period...'; de='Please enter card expiration period...'; ru='Укажите срок действия карты...'");
						vRetStruct = vFrm.DoModal();
						If vRetStruct <> Undefined Then
							vPC.Expiry = Format(vRetStruct.CardExpDate, "DF=yyMM");
							If Not IsBlankString(vRetStruct.PayCardNumber) And 
							   cmIsNumber(TrimAll(vRetStruct.PayCardNumber)) Then
								vPC.PAN = TrimAll(vRetStruct.PayCardNumber);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			#EndIf
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC, "en='Preauthorisation'; ru='Преавторизация'", pObj);
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
	// Not supported by driver
	rMessage = "";
	Try
		pObj.Status = Enums.PreauthorisationStatuses.Cancelled;
		pObj.AuthorOfCancellation = SessionParameters.CurrentUser;
		pObj.DateOfCancellation = CurrentSessionDate();
		pObj.Write(DocumentWriteMode.Posting);
		Return True;
	Except
		rMessage = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Error, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
		Return False;
	EndTry;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(pObj, rMessage);
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
			If ValueIsFilled(pObj.CreditCard) 
				And Not IsBlankString(pObj.CreditCard.CardNumber) 
				And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) 
				And ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vCardExpiryDate = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vCardNumber = "";
				vCardExpiryDate = "";
			EndIf;
			// Fill operation currency code
			vCurrencyCode = Format(pObj.PaymentCurrency.Code, "ND=3; NFD=0; NZ=; NLZ=; NG=");
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(pObj.Preauthorisation.AuthorizationCode);
				vReferenceNumber = TrimAll(pObj.Preauthorisation.ReferenceNumber);
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				vRC = vPC.ЗавершитьПреавторизациюПоПлатежнойКарте(vCardNumber, pSum, vReferenceNumber, vAuthorizationCode);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), rMessage) Then
					Return False;
				EndIf;
				vReferenceNumber = vPC.RRNCode;
				vAuthorizationCode = vPC.AuthorizationCode;
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC, "en='Auth. confirmation'; de='Auth. confirmation'; ru='Расчет по преавторизации'", pObj);
			Else
				If pSum > 0 Then
					// Call processing
					WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
					vRC = vPC.ОплатитьПлатежнойКартой(vCardNumber, pSum, vReferenceNumber, vAuthorizationCode);
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
					// Get slip
					vOutSlip = GetOperationSlipCheque(vPC, "en='Authorisation'; ru='Авторизация'", pObj);
					
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
						If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
							And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
							And Not IsBlankString(vOutSlip) Then
							vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
							PrintSlipDocument(vSlipTxtArr, pObj);
						EndIf;
						
						Return False;
					EndIf;
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
					// Get slip
					vOutSlip = GetOperationSlipCheque(vPC, "en='Authorisation'; ru='Авторизация'", pObj);
				Else
					// Call processing
					vPayment = Undefined;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vPayment = pObj.Payment;
					ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
						vPayment = pObj.CustomerPayment;
					EndIf;
					If ValueIsFilled(vPayment) Then
						vReferenceNumber = TrimAll(vPayment.ReferenceNumber);
					Else
						Raise NStr("en='Return should be based on previous payment!'; de='Return should be based on previous payment!'; ru='Возврат должен быть на основании предыдущего платежа!'");
					EndIf;
					WriteLogEvent(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
					vRC = vPC.ВернутьПлатежПоПлатежнойКарте(vCardNumber, -pSum, vReferenceNumber, vAuthorizationCode);
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
						Return False;
					EndIf;
					// Log authorisation code and RRN
					LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"));
					// Get slip
					vOutSlip = GetOperationSlipCheque(vPC, "en='Return'; de='Return'; ru='Возврат'", pObj);
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
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
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
	vPC = Connect(pObj, rMessage);
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
			If ValueIsFilled(pObj.CreditCard) And 
			   Not IsBlankString(pObj.CreditCard.CardNumber) 
			   And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) 
			   And ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vPC.PAN = vCardNumber;
				vPC.Expiry = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vPC.PAN = "";
				vPC.Expiry = "";
			EndIf;
			// Fill operation currency code
			vPC.CurrencyCode = Format(pObj.PaymentCurrency.Code, "ND=3; NFD=0; NZ=; NLZ=; NG=");
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vRC = vPC.ОтменитьПлатежПоПлатежнойКарте(vCardNumber, pSum, vReferenceNumber);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization("", vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"));
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC, "en='Cancel authorisation'; ru='Отмена авторизации'", pObj);
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
	// Ask for confirmation
	#If Client Then
		If DoQueryBox(NStr("en='Do totals check (settlement) operation?'; de='Do totals check (settlement) operation?'; ru='Выполнить операцию сверки итогов?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No) = DialogReturnCode.No Then
			Return True;
		EndIf;
	#EndIf
	// Try to connect
	vPC = Connect(pCashRegister, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		vStruct = New Structure("CashRegister", pCashRegister);
		// Pay card system object was created successfully
		Try
			// Bank day settlement
			vRC = vPC.ИтогиДняПоКартам();
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				Return False;
			EndIf;
			// Success
			#If Client Then
				DoMessageBox(NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));
			#EndIf
			Try
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC, "en='Settlement'; de='Settlement'; ru='Итоги дня по картам'", Undefined);
				// Print settlement slip
				If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
					And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
					And Not IsBlankString(vOutSlip) Then
					vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
					vStruct = New Structure("CashRegister", pCashRegister);
					PrintSlipDocument(vSlipTxtArr, vStruct);
				EndIf;
			Except
				rMessage = NStr("en='Error in settlement operation: '; de='Error in settlement operation: '; ru='Ошибка печати слип чека снятия итогов дня: '") + ErrorDescription();
				ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
				rMessage = "";
			EndTry;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
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
Function Connect(pObj, rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("INPAS");
		
		If vPC = Undefined Then
			#If Client Then
				Try
					AttachAddIn("Addin.a_inpasDC1c82");
					vPC = New("Addin.a_inpasDC1c82");
				Except
					LoadAddIn("a_inpasDC1c82.dll");
					vPC = New("Addin.a_inpasDC1c82");
				EndTry;
			#Else
				vPC = New("Addin.a_inpasDC1c82");
			#EndIf

			// Read connection parameters
			ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get(), pObj);
			
			If ConnectionParameters = Undefined Then
				Raise NStr("en='INPAS parameters XML should be filled!'; de='INPAS parameters XML should be filled!'; ru='Не заполнен XML файл с параметрами подключения к системе ИНПАС!'");
			EndIf;
			
			SetConnectionParameters(vPC, pObj); 
			SetPersistentObject("INPAS", vPC);
		EndIf;
		
		// OK
		Return vPC;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pPC)
	Try
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, rMessage)
	If Not pRC Then
		If Not IsBlankString(TrimAll(pPC.Status)) Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + TrimAll(pPC.Status) + Chars.LF + 
			           NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pPC);
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
	vCardTypeStr = TrimAll(pPC.ReceiptText);
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
	vCardHolder = TrimAll(pPC.CardHolderName);
	If IsBlankString(vCardHolder) And Not IsBlankString(TrimAll(pPC.PrintData)) Then
		vPrintData = TrimAll(pPC.PrintData);
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
		vCardObj.CardDataEnc = "";
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
	vMessage = "";
	If ValueIsFilled(pObj.CashRegister) Then
		vCashRegisterProcessor = cmGetCashRegisterDataProcessor(pObj.CashRegister);
		vStatus = vCashRegisterProcessor.pmPrintSlip(pSlipTextArr, Undefined, vMessage);
	Else
		vMessage = NStr("en='Cash register is not specified!'; de='Cash register is not specified!'; ru='Не выбран ККМ для печати!'");
	EndIf;
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pAuthCode, pRRN, pFunction)
	vMessage = NStr("en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '; ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '") + pAuthCode + "/" + pRRN;
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Function GetOperationSlipCheque(pPC, pOperation, pObj)
	vSlipCheque = pPC.ReceiptText;
	Return vSlipCheque;
EndFunction // GetOperationSlipCheque

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
