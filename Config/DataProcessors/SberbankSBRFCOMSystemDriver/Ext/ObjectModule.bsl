Var DefaultConnectionParameters;
Var ConnectionParameters;

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName) Export
	vObject = Undefined;
	#IF CLIENT THEN
		amPersistentObjects.Property(pName, vObject);
		If vObject = Undefined Then
			amPersistentObjects.Insert(pName, vObject);
		EndIf;
	#ENDIF
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Function SetPersistentObject(pName, pValue) Export
	#IF CLIENT THEN
		amPersistentObjects.Insert(pName, pValue);
	#ENDIF
EndFunction // SetPersistentObject

// -----------------------------------------------------------------------------
Function GetErrorDescription(vPC, rMessage)
	vErrCode = -1;
	rMessage = "";
	Try
		vErrCode = vPC.GetLastError(rMessage);
	Except
		rMessage = NStr("en='<Description unknown>!'; de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndTry;
	Return vErrCode;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("GateDllPath", 
										"");
		vReader = New XMLReader();
		vReader.SetString(pStr);
		While vReader.Read() Do
			If vReader.NodeType = XMLNodeType.StartElement Then
				If vReader.Name = "GateDllPath" Then
					If vReader.Read() Then
						If vReader.NodeType = XMLNodeType.Text Then
							vConnParameters.GateDllPath = TrimAll(vReader.Value);
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
Procedure SetConnectionParameters(pPC)
	If ConnectionParameters <> Undefined Then
		If Not IsBlankString(ConnectionParameters.GateDllPath) Then
			If Not pPC.SetDLLName(ConnectionParameters.GateDllPath) Then
				Raise NStr("en='Failed to set gate.dll path!'; de='Failed to set gate.dll path!'; ru='Не удалось установить путь к gate.dll!'");
			EndIf;
		EndIf;
		pPC.SlipWidth = CreditCardsProcessingSystemParameters.SlipCharLineLength;
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("SberbankRUS");
		If vPC = Undefined Then
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.SBRFCOMObject");
					vPC = New("AddIn.SBRFCOMExtension");
				Except
					LoadAddIn("SBRFCOM.dll");
					vPC = New("AddIn.SBRFCOMExtension");
				EndTry;
			#ELSE
				vPC = New("AddIn.SBRFCOMExtension");
			#ENDIF
		EndIf;
		// Get connection parameters
		ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get());
		If ConnectionParameters <> Undefined Then
			SetConnectionParameters(vPC);
		EndIf;
		// Save driver object
		SetPersistentObject("SberbankRUS", vPC);
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
Procedure pmDisconnect() Export
	Try
		vPC = GetPersistentObject("SberbankRUS");
		Disconnect(vPC);
		SetPersistentObject("SberbankRUS", Undefined);
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
		#IF CLIENT THEN
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
		#ENDIF
		// Try to connect
		vPC = Connect(rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the PIN pad device
		vRC = vPC.MakeReport();
		If Not vRC Then
			vErrCode = GetErrorDescription(vPC, rMessage);
			Disconnect(vPC);
			Return False;
		Else
			// Get slip
			rMessage = GetOperationSlipCheque(vPC, "en='Report'; ru='Отчет'");
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
	If Not pRC Then
		vErrCode = GetErrorDescription(pPC, rMessage);
		If vErrCode <> 0 Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + Format(vErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF + 
			           NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + rMessage;
		Else
			rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + rMessage;
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
	// Get card type from object payment method
	If TypeOf(pObj) <> Type("Structure") And ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
		vCardTypeRef = pObj.PaymentMethod.CardType;
	Else		
		// Try to find card type			
		vCardTypeRef = Catalogs.CreditCardTypes.EmptyRef();
		If pPC.CardType = 0 Then
			vCardTypeRef = Catalogs.CreditCardTypes.FindByCode("0", False);
		ElsIf pPC.CardType = 1 Then
			vCardTypeRef = Catalogs.CreditCardTypes.FindByCode("1", False);
		EndIf;
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

// -----------------------------------------------------------------------------
Function GetCardHolder(pPC)
	// Try to retrieve card holder name from the driver object properties
	vCardHolder = ""; // Unsupported yet
	Return vCardHolder;
EndFunction // GetCardHolder

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pPC, pCardNumber, pCardExpiryDate, pCardName, pHashCode, pSberbankCard, pObj)
	vCardNumber = TrimAll(pCardNumber);
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
		vCardObj.CardHolder = ?(IsBlankString(TrimAll(pCardName)), GetCardHolder(pPC), TrimAll(pCardName));
		vCardObj.CardValidTillDate = pCardExpiryDate;
		vCardObj.CardDataEnc = pHashCode;
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
Function GetOperationSlipCheque(pPC, pOperation)
	vSlipCheque = "";
	vSlipLineCount = pPC.SlipLineCount;
	vSlipCopiesCount = pPC.SlipCopiesCount;
	If vSlipCopiesCount <= 0 Then
		vSlipCopiesCount = 1;
	EndIf;
	If vSlipCopiesCount > 1 Then
		vSlipLineCount = Int(vSlipLineCount/vSlipCopiesCount);
	EndIf;
	For i = 1 To vSlipLineCount Do
		vSlipLine = "";
		If pPC.GetCheckString(i, vSlipLine) Then
			vSlipCheque = vSlipCheque + vSlipLine + Chars.LF;
		EndIf;			
	EndDo;
	If vSlipCopiesCount = 1 Then
		vTildaSPos = Find(vSlipCheque, "~S");
		If vTildaSPos >= (Int(StrLen(vSlipCheque)/2) - 9) Then
			vSlipCheque = Left(vSlipCheque, vTildaSPos - 1);
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
		// Not supported by COM driver
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vHashCode = Undefined; 
			vSberbankCard = Undefined; 
			vCardName = Undefined; 
			vCardNumber = Undefined;
			vCardExpiryDate = '00010101';
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма преавторизации!'; en = 'Zero sum preauthorization is not possible!'; de = 'Zero sum preauthorization is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			// Check card expiry date
			#IF CLIENT THEN
				If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
					If Not ValueIsFilled(pObj.CreditCard) And IsBlankString(TrimAll(vCardNumber)) Then
						// Ask user to enter card number and expiry date from the card.
						vFrm = ThisObject.GetForm("InputPayCardDataManually");
						vFrm.SelPayCardNumber = "";
						vFrm.SelDescription = NStr("en='Please enter card number and card expiration period...'; de='Please enter card number and card expiration period...'; ru='Укажите номер и срок действия карты...'");
						vRetStruct = vFrm.DoModal();
						If vRetStruct <> Undefined Then
							If Not IsBlankString(vRetStruct.PayCardNumber) And 
							   cmIsNumber(TrimAll(vRetStruct.PayCardNumber)) Then
								vCardNumber = TrimAll(vRetStruct.PayCardNumber);
								vCardExpiryDate = vRetStruct.CardExpDate;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			#ENDIF
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				If Not IsBlankString(TrimAll(vCardNumber)) Then
					vCreditCardRef = SaveCreditCardData(vPC, vCardNumber, vCardExpiryDate, vCardName, vHashCode, vSberbankCard, pObj);
					If ValueIsFilled(vCreditCardRef) Then
						pObj.CreditCard = vCreditCardRef;
						pObj.CardType = vCreditCardRef.CardType;
					EndIf;
				EndIf;
			Else
				pObj.CardType = GetCardType(vPC, pObj);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = "";
			pObj.Write(DocumentWriteMode.Write);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
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
		Try
			vReferenceNumber = "";
			vAuthorizationCode = "";
			vOutSlip = "";
			vHashCode = Undefined; 
			vSberbankCard = Undefined; 
			vCardName = Undefined; 
			vCardNumber = Undefined;
			vCardExpiryDate = '00010101';
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма авторизации!'; en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Fill card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.CardType = Number(TrimAll(pObj.PaymentMethod.CardType.Code));
				Except
					vPC.CardType = 0;
				EndTry;
			Else
				vPC.CardType = 0;
			EndIf;
			// Do operation
			If pSum > 0 Then
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				vRC = vPC.PayByPaymentCard(pSum * 100, vReferenceNumber, vAuthorizationCode, vHashCode, vSberbankCard, vCardName, vCardNumber);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC, "en='Authorisation'; ru='Авторизация'");
			Else
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
				vRC = vPC.ReturnPaymentByPaymentCard(-pSum * 100, vReferenceNumber, vAuthorizationCode, vHashCode, vSberbankCard, vCardName, vCardNumber);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"));
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC, "en='Return'; ru='Возврат'");
			EndIf;
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				If IsBlankString(TrimAll(vCardNumber)) Then
					#IF CLIENT THEN
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
					#ENDIF
				EndIf;
				vCreditCardRef = SaveCreditCardData(vPC, vCardNumber, vCardExpiryDate, vCardName, vHashCode, vSberbankCard, pObj);
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
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

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
		WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
		Return False;
	EndTry;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			vReferenceNumber = TrimAll(pObj.ReferenceNumber);
			vOutSlip = "";
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма аннуляции!'; en = 'Zero sum annulation is not possible!'; de = 'Zero sum annulation is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;
			// Check reference number
			If IsBlankString(vReferenceNumber) Then
				Raise NStr("ru = 'В платеже не указан референс номер операции оплаты!'; en = 'Payment reference number is empty!'; de = 'Payment reference number is empty!'");
			EndIf;
			// Fill card type
			If ValueIsFilled(pObj.PaymentMethod) And ValueIsFilled(pObj.PaymentMethod.CardType) Then
				Try
					vPC.CardType = Number(TrimAll(pObj.PaymentMethod.CardType.Code));
				Except
					vPC.CardType = 0;
				EndTry;
			Else
				vPC.CardType = 0;
			EndIf;
			// Fill operation currency code not supported
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vRC = vPC.CancelPaymentByPaymentCard(pSum * 100, vReferenceNumber);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization("", vReferenceNumber, NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"));
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC, "en='Cancel authorisation'; ru='Отмена авторизации'");
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
	#IF CLIENT THEN
		If DoQueryBox(NStr("en='Do totals check (settlement) operation?'; de='Do totals check (settlement) operation?'; ru='Выполнить операцию сверки итогов?'"), QuestionDialogMode.YesNo, 15, DialogReturnCode.No) = DialogReturnCode.No Then
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
			vRC = vPC.Settlement();
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = GetOperationSlipCheque(vPC, NStr("en='Settlement'; de='Settlement'; ru='Сверка итогов'"));
			// Print annulation slip
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
DefaultConnectionParameters = 
"<SberbankRUSConnectionParameters>
|	<GateDllPath></GateDllPath>
|</SberbankRUSConnectionParameters>";
