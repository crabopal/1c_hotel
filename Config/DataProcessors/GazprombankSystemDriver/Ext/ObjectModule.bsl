
#Region Variables

Var DefaultConnectionParameters;
Var ConnectionParameters;
Var ErrorCodesTrue;

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
		vPC = Connect(rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		
		// Initialize connection to the PIN pad device
		vRC = vPC.EchoTest(CreditCardsProcessingSystemParameters.TerminalNumber, rMessage);
		If Not IsBlankString(rMessage) Then
			Return False;
		ElsIf Not vRC Then
			vErrCode = GetErrorDescription(vPC, rMessage);
			Return False;
		EndIf;
		Return True;
	Except
		rMessage = ErrorDescription();
		Return False;
	EndTry;
EndFunction // pmCheckConnection

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
			vCardNumber = "";
			vCardExpiryDate = '00010101';
			#IF CLIENT THEN
				If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
					If Not ValueIsFilled(pObj.CreditCard) Then
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
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			pObj.SlipText = "";
			pObj.Write(DocumentWriteMode.Write);
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
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
		Try
			vReferenceNumber 	= "";
			vAuthorizationCode 	= "";
			vCardNumber 		= "";
			vReceiptNumber 		= "";
			vDeviceID			= CreditCardsProcessingSystemParameters.TerminalNumber;
			vOutSlip 			= "";

			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма авторизации!'; en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'");
			EndIf;
			// Check payment currency
			If Not ValueIsFilled(pObj.PaymentCurrency) Then
				Raise NStr("ru = 'Не указана валюта преавторизации!'; en = 'Preauthorization currency is not filled!'; de = 'Preauthorization currency is not filled!'");
			EndIf;

			// Do operation
			If pSum > 0 Then
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				vRC = vPC.PayByPaymentCard(vDeviceID, vCardNumber, pSum * 100, vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
			Else
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(-pSum, pObj.PaymentCurrency));
				vRC = vPC.ReturnPaymentByPaymentCard(vDeviceID, vCardNumber, pSum * 100, vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
				If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"), rMessage) Then
					Return False;
				EndIf;
				// Log authorisation code and RRN
				LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'"));
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
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			Disconnect(vPC);
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
			vDeviceID			= CreditCardsProcessingSystemParameters.TerminalNumber;
			vOutSlip 			= "";
			vCardNumber         = "";
			vReceiptNumber      = "";
			vAuthorizationCode  = "";
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
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vRC = vPC.CancelPaymentByPaymentCard(vDeviceID, vCardNumber, pSum * 100, vReceiptNumber, vReferenceNumber, vAuthorizationCode, vOutSlip);
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
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, pObj);
			EndIf;
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage);
			Disconnect(vPC);
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
	#ENDIF
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		vDeviceID			= CreditCardsProcessingSystemParameters.TerminalNumber;
		vOutSlip 			= "";

		vStruct = New Structure("CashRegister", pCashRegister);
		// Pay card system object was created successfully
		Try
			// Bank day settlement
			vRC = vPC.Settlement(vDeviceID,vOutSlip);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage) Then
				Disconnect(vPC);
				Return False;
			EndIf;
			// Print annulation slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque 
				And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter 
				And Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct);
			EndIf;
			// Success
			#If Client Then
				DoMessageBox(NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));
			#EndIf
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), rMessage);
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
Procedure pmDisconnect() Export
	Try
		vPC = GetPersistentObject("Gazprombank");
		Disconnect(vPC);
		SetPersistentObject("Gazprombank", Undefined);
	Except
	EndTry;
EndProcedure // pmDisconnect

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetErrorDescription(vPC, rMessage)
	vErrCode = 957;
	rMessage = "";
	Try
		vErrCode = vPC.GetLastError(rMessage);
	Except
		rMessage = NStr("en = '<Description unknown>!'; de = '<Description unknown>!'; ru = '<Описание не найдено>!'");
	EndTry;
	Return vErrCode;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("DllFileName, CfgFileName, HeadCheck","");
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
	EndIf;
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC)
	If ConnectionParameters <> Undefined Then
		
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
					vKeyValue = ?(ValueIsFilled(vKeyValue), vKeyValue, ConnectionParameters.DllFileName);
				ElsIf vKey = "CfgFileName" Then
					vKeyValue = ?(ValueIsFilled(vKeyValue), vKeyValue, ConnectionParameters.DllFileName);
				EndIf;	
				
				If Not pPC.SetParameter(vKey, vKeyValue) Then
					Raise ErrorDescription();
				EndIf;	
			EndIf;
		EndDo;
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("Gazprombank");
		If vPC = Undefined Then
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.EMVGateCOM");
					vPC = New("AddIn.EMVGateCOM1C");
				Except
					LoadAddIn("EMVGateCOM1C.dll");
					vPC = New("AddIn.EMVGateCOM1C");
				EndTry;
			#ELSE
				vPC = New("AddIn.EMVGateCOM1C");
			#ENDIF
		EndIf;
		
		// Get connection parameters
		ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get());
		If ConnectionParameters <> Undefined Then
			SetConnectionParameters(vPC);
		EndIf;
		vID = "";
		If Not vPC.Open(vID) Then
			vErrCode = GetErrorDescription(vPC, rMessage);
			Return Undefined;;
		EndIf;
		
		// Save driver object
		SetPersistentObject("Gazprombank", vPC);
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
		pPC.Close(CreditCardsProcessingSystemParameters.TerminalNumber);
	Except
		pPC = Undefined;
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Function ProcessResultCode(pRC, pPC, pFunction, rMessage)
	If Not pRC Then
		vErrCode = GetErrorDescription(pPC, rMessage);
		If vErrCode <> 0 Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + Format(vErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF 
						+ NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + rMessage;
		Else
			rMessage = NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + rMessage;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
		Return False;
	Else
		vErrCode = ErrCodeProcessingSystem(pRC.AuthResponse);
		If ErrorCodesTrue.FindByValue(vErrCode) = Undefined Then
			vErrCode = GetErrorDescription(pPC, rMessage);
			If vErrCode <> 0 Then
				rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + Format(vErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF 
							+ NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung: '") + rMessage;
			Else
				rMessage = NStr("en = 'Error description: '; de = 'Fehlerbeschreibung: '; ru = 'Описание ошибки: '") + rMessage;
			EndIf;
			tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
			WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
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
Procedure ProcessException(pPC, pFunction, rMessage)
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
		rMessage = NStr("en='Cash register is not specified!'; de='Cash register is not specified!'; ru='Не выбран ККМ для печати!'");
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
"<GazprombankConnectionParameters>
|	<DllFileName></DllFileName>
|	<CfgFileName></CfgFileName>
|	<HeadCheck></HeadCheck>
|</GazprombankConnectionParameters>";

ErrorCodesTrue = New ValueList;
ErrorCodesTrue.Add("000");
ErrorCodesTrue.Add("003");
ErrorCodesTrue.Add("020");
ErrorCodesTrue.Add("959");

#EndRegion
