Var DefaultConnectionParameters;
Var ConnectionParameters;

// -----------------------------------------------------------------------------
Function GetErrorDescription(vRC, vPC)
	vMessage = "";
	Try
		vMessage = TrimAll(vRC)+":"+vPC.GParamString("LastError");
	Except
		vMessage = NStr("en='Error description is unknown! Error code is '; de='Fehlerbeschreibung ist nicht bekannt! Der Fehlercode ist '; ru='Описание ошибки не найдено! Код ошибки '")+TrimAll(vRC);
	EndTry;
	
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		// Nothing to configure
	EndIf;
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC)
	If ConnectionParameters <> Undefined Then
		// Nothing to configure
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = New COMObject("SBRFSRV.Server");
		// Get connection parameters
		ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get());
		If ConnectionParameters <> Undefined Then
			SetConnectionParameters(vPC);
		EndIf;
		// Clear parameters
		vPC.Clear();
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
		pPC.Clear();
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

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
		#IF CLIENT THEN
			If Not IsBlankString(vConnParameters) Then
				vFrm = GetCommonForm("InputText");
				vFrm.SelText = vConnParameters;
				vFrm.Caption = NStr("en='Please input configuration file data'; de='Please input configuration file data'; ru='Укажите здесь данные конфигурационного файла'");
				vConnParameters = vFrm.DoModal();
				If vConnParameters = Undefined Then
					Return False;
				EndIf;
			EndIf;
			// Save parameters
			If pSettingsObj <> Undefined Then
				pSettingsObj.ConnectionParameters = New ValueStorage(vConnParameters);
				pSettingsObj.Write();
				CreditCardsProcessingSystemParameters = pSettingsObj.Ref;
			EndIf;
		#ENDIF
		// Try to connect
		vPC = Connect(rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the terminal device and get X-Report slip
		vRC = vPC.NFun(7000);
		If vRC = 0 Then
			rMessage = GetOperationSlipCheque(vPC);
		Else
			rMessage = GetErrorDescription(vRC, vPC);
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
Function ProcessResultCode(pRC, pPC, pFunction, rMessage)
	If pRC <> 0 Then
		rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + GetErrorDescription(pRC, pPC);
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
Function GetCardOwner(pObj)
	vCardOwner = Undefined;
	If TypeOf(pObj) = Type("DocumentObject.Payment") Or 
	   TypeOf(pObj) = Type("DocumentObject.Return") Or 
	   TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
		vCardOwner = pObj.Payer;
	ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
		vCardOwner = pObj.AccountingCustomer;
	EndIf;
	Return vCardOwner;
EndFunction // GetCardOwner

// -----------------------------------------------------------------------------
Function GetCardType(pPC, pObj)
	vCardTypeRef = Catalogs.CreditCardTypes.EmptyRef();
	// Get card type from object payment method
	If TypeOf(pObj) <> Type("Structure") And ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
		vCardTypeRef = pObj.PaymentMethod.CardType;
	EndIf;
	// Try to find card type			
	vCardName = TrimAll(pPC.GParamString("CardName"));
	vCardType = TrimAll(pPC.GParamString("CardType"));
	If Not IsBlankString(vCardName) Or Not IsBlankString(vCardType) Then
		vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vCardName, vCardType);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

// -----------------------------------------------------------------------------
Function GetCardHolder(pPC)
	// Try to retrieve card holder name from the driver object properties
	vCardHolder = ""; // Not supported by SBRF library
	Return vCardHolder;
EndFunction // GetCardHolder

// -----------------------------------------------------------------------------
Function GetCardNumber(pPC)
	// Try to retrieve card number
	vCardNumber = pPC.GParamString("ClientCard");
	Return vCardNumber;
EndFunction // GetCardNumber

// -----------------------------------------------------------------------------
Function GetCardHash(pPC)
	// Try to retrieve hashed card number
	vCardNumberHash = pPC.GParamString("Hash");
	Return vCardNumberHash;
EndFunction // GetCardHash

// -----------------------------------------------------------------------------
Function GetCardExpiryDate(pPC)
	// Try to retrieve card number
	vCardExpiryDate = pPC.GParamString("ClientExpiryDate");
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

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pPC, pCardNumber, pCardExpiryDate, pObj)
	vCardNumber = TrimAll(pCardNumber);
	If IsBlankString(vCardNumber) Then
		vCardNumber = GetCardNumber(pPC);
	EndIf;
	vCardExpiryDate = pCardExpiryDate;
	If vCardExpiryDate <> Undefined Then
		vCardExpiryDate = GetCardExpiryDate(pPC);
	EndIf;
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
		vCardObj.CardType = GetCardType(pPC, pObj);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardHolder = GetCardHolder(pPC);
		vCardObj.CardValidTillDate = vCardExpiryDate;
		vCardObj.CardDataEnc = GetCardHash(pPC);
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	Else
		vCardType = GetCardType(pPC, pObj);
		If ValueIsFilled(vCardType) And Not ValueIsFilled(vCardRef.CardType) Then
			vCardObj = vCardRef.GetObject();
			vCardObj.CardType = vCardType;
			vCardObj.CardValidTillDate = pCardExpiryDate;
			vCardObj.Write();
		EndIf;
	EndIf;
	Return vCardRef;
EndFunction // SaveCreditCardData

// -----------------------------------------------------------------------------
Function PrintSlipDocument(pSlipTextArr, pObj)
	vStatus = False;
	rMessage = "";
	If ValueIsFilled(pObj.CashRegister) Then
		vCashRegisterProcessor = cmGetCashRegisterDataProcessor(pObj.CashRegister);
		vStatus = vCashRegisterProcessor.pmPrintSlip(pSlipTextArr, Undefined, rMessage);
	Else
		rMessage = NStr("en='Cash register is not specified!'; de='Cash register is not specified!'; ru='Не выбран ККМ для печати!'");
	EndIf;
EndFunction // PrintSlipDocument

// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pAuthCode, pRRN, pFunction)
	vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + pAuthCode + "/" + pRRN;
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Function GetOperationSlipCheque(pPC)
	vSlipCheque = pPC.GParamString("Cheque");
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
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
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
			If pSum < 0 Then
				Raise NStr("ru = 'Сумма операции должна быть больше 0!'; en = 'Operation amount should be positive!'; de = 'Betriebsbetrag sollte positiv sein!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта операции!'; en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'");
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(pObj.PaymentMethod.CardType.Code)));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Log operation
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			// Set amount
			vPC.SParam("Amount", pSum * 100);
			// Do payment
			vRC = vPC.NFun(4009);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Set unconfirmed mode
			vRC = vPC.NFun(6003);
			vCardOperationWasDone = True;
			// Get Reference number, Authorization code
			vReferenceNumber = vPC.GParamString("RRN");
			vAuthorizationCode = vPC.GParamString("AuthCode");
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCardNumber = GetCardNumber(vPC);
				vCardExpiryDate = GetCardExpiryDate(vPC);
				#IF CLIENT THEN
					If Not ValueIsFilled(vCardExpiryDate) Then
						// Ask user to enter card number and expiry date from the card.
						vFrm = ThisObject.GetForm("InputPayCardDataManually");
						vFrm.SelPayCardNumber = vCardNumber;
						vFrm.SelDescription = NStr("en='Please enter card expiration period...'; de='Please enter card expiration period...'; ru='Укажите срок действия карты...'");
						vRetStruct = vFrm.DoModal();
						If vRetStruct <> Undefined Then
							If Not IsBlankString(vRetStruct.PayCardNumber) And 
							   cmIsNumber(TrimAll(vRetStruct.PayCardNumber)) Then
								vCardNumber = TrimAll(vRetStruct.PayCardNumber);
								vCardExpiryDate = vRetStruct.CardExpDate;
							EndIf;
						EndIf;
					EndIf;
				#ENDIF						
				vCreditCardRef = SaveCreditCardData(vPC, vCardNumber, vCardExpiryDate, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vPC, pObj);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = vOutSlip;
			pObj.Write(DocumentWriteMode.Write);
			// Print preauthorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			// Rollback operation
			If vCardOperationWasDone Then
				vRC = vPC.NFun(6004); 
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
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
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(pObj.PaymentMethod.CardType.Code)));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Do operation
			If pSum > 0 Then
				// Log payment
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				// Set amount
				vPC.SParam("Amount", pSum * 100);
				// Do payment
				If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
					vRC = vPC.NFun(4010); // Close preauthorization
				Else
					vRC = vPC.NFun(4000); // Payment
				EndIf; 
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003);
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			Else
				// Log payment
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
				// Set amount
				vPC.SParam("Amount", -pSum * 100);
				// Do return
				vRC = vPC.NFun(4002);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003); 
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			EndIf;
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCardNumber = GetCardNumber(vPC);
				vCardExpiryDate = GetCardExpiryDate(vPC);
				#IF CLIENT THEN
					If Not ValueIsFilled(vCardExpiryDate) Then
						// Ask user to enter card number and expiry date from the card.
						vFrm = ThisObject.GetForm("InputPayCardDataManually");
						vFrm.SelPayCardNumber = vCardNumber;
						vFrm.SelDescription = NStr("en='Please enter card expiration period...'; de='Please enter card expiration period...'; ru='Укажите срок действия карты...'");
						vRetStruct = vFrm.DoModal();
						If vRetStruct <> Undefined Then
							If Not IsBlankString(vRetStruct.PayCardNumber) And 
							   cmIsNumber(TrimAll(vRetStruct.PayCardNumber)) Then
								vCardNumber = TrimAll(vRetStruct.PayCardNumber);
								vCardExpiryDate = vRetStruct.CardExpDate;
							EndIf;
						EndIf;
					EndIf;
				#ENDIF						
				vCreditCardRef = SaveCreditCardData(vPC, vCardNumber, vCardExpiryDate, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vPC, pObj);
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
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			// Rollback operation
			If vCardOperationWasDone Then
				vRC = vPC.NFun(6004); 
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			// Check amount
			vSum = pObj.Sum;
			If vSum = 0 Then
				Raise NStr("ru = 'Не указана сумма операции!'; en = 'Zero amount operation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
			EndIf;
			// Check currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта операции!'; en = 'Operation currency is not filled!'; de = 'Operation Währung ist nicht gefüllt!'");
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(pObj.PaymentMethod.CardType.Code)));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Set RNN
			vPC.SParam("RRN", pObj.ReferenceNumber);
			// Do operation
			If vSum > 0 Then
				// Log payment
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(vSum, pObj.PaymentCurrency));
				// Set amount
				vPC.SParam("Amount", 0);  //set sum =0 for cancelled preauthorization
				vRC = vPC.NFun(4010); 
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
					Return False;
				EndIf;
				// Set unconfirmed mode
				vRC = vPC.NFun(6003);
				vCardOperationWasDone = True;
				// Get Reference number, Authorization code
				vReferenceNumber = vPC.GParamString("RRN");
				vAuthorizationCode = vPC.GParamString("AuthCode");
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC);
			EndIf;
			// Change preauthorization status if there are no erros
			pObj.Status = Enums.PreauthorisationStatuses.Cancelled;
			pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" +  vReferenceNumber + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.AuthorOfCancellation = SessionParameters.CurrentUser;
			pObj.DateOfCancellation = CurrentSessionDate();
			pObj.Write(DocumentWriteMode.Posting);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		vCardOperationWasDone = False;
		Try
			vReferenceNumber = TrimAll(pObj.ReferenceNumber);
			vOutSlip = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма аннуляции!'; en = 'Zero amount annulation is not possible!'; de = 'Null-Summen-Operation nicht möglich ist!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Check reference number
			If IsBlankString(vReferenceNumber) Then
				//Sberbank does not return reference number in payment so it most of the time empty.
				//In this case we just call for return function
				Return pmAuthorizePayment(-pSum, -pVATSum, pObj, rMessage);				
			EndIf;
			// Set card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.SParam("CardType", Number(TrimAll(pObj.PaymentMethod.CardType.Code)));
				Except
					vPC.SParam("CardType", 0);
				EndTry;
			Else
				vPC.SParam("CardType", 0);
			EndIf;
			// Set operation RRN
			vPC.SParam("RRN", vReferenceNumber);
			// Set operation currency code
			vPC.SParam("Currency", 0);
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			// Set amount
			vPC.SParam("Amount", pSum * 100);
			// Do cancel operation
			vRC = vPC.NFun(4003);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Set unconfirmed mode
			vRC = vPC.NFun(6003);
			vCardOperationWasDone = True;
			// Get Reference number, Authorization code
			vReferenceNumber = vPC.GParamString("RRN");
			vAuthorizationCode = vPC.GParamString("AuthCode");
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"));
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
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
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			// Confirm operation
			vRC = vPC.NFun(6001);
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage);
			// Rollback operation
			If vCardOperationWasDone Then
				vRC = vPC.NFun(6004); 
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulatePayment

// -----------------------------------------------------------------------------
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister) Export
	// Ask for confirmation
	#IF CLIENT THEN
		If DoQueryBox(NStr("en='Do totals check (settlement) operation?'; de='Die Betriebsergebnisse der Versöhnung?'; ru='Выполнить операцию сверки итогов?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No) = DialogReturnCode.No Then
			Return True;
		EndIf;
	#ENDIF
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		vStruct = New Structure("CashRegister", pCashRegister);
		// Pay card system object was created successfully
		Try
			// Bank day settlement
			vRC = vPC.NFun(6000);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC);
			// Print end of day slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct);
			EndIf;
			// Success
			#IF CLIENT THEN
				DoMessageBox(NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));
			#ENDIF
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
DefaultConnectionParameters = "";
