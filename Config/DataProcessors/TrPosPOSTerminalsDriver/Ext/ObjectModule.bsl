// -----------------------------------------------------------------------------
Function SlipFormat(pSlip, pCashRegister)
	If IsBlankString(pSlip) Then
		Return pSlip;
	EndIf;
	// Try to cut off double check
	vPos = Find(pSlip, Char(31));
	If vPos > 0 Then
		pSlip = Left(pSlip, vPos-1);
	EndIf;
	// Do not process slip cheque if printing is done using terminal printer
	If CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter Then
		Return pSlip;
	EndIf;
	// Get slip width
	vWidth = CreditCardsProcessingSystemParameters.SlipCharLineLength;
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
	If Int(vNumChars/2) <> vNumChars/2 Then
		vNumChars = vNumChars + 1;
	EndIf;
	// Process slip lines
	vSlip = "";
	vSlipTxtArr = cmGetTextLinesArray(pSlip);
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
		vLeftLength = Int(vWidth/2) - 2;
		vLeftTxt = Left(vTxt, Int(vWidth/2));
		vRightTxt = Right(vTxt, Int(vWidth/2));
		j = 0;
		k = 0;
		For i = 0 To (Int(vWidth/2) - 2) Do
			vLeft = Mid(vTxt, Int(vWidth/2) - 2 - i, 2);
			If vLeft = "  " Then
				vLeftTxt = Left(vTxt, Int(vWidth/2) - 2 - i + 1) + Mid(vLeftTxt, vLeftLength - j + 3); 
				vLeftLength = vLeftLength - 1;
				vRemoved = vRemoved + 1;
			Else
				j = j + 1;
			EndIf;
			If vRemoved = vNumChars Then
				Break;
			EndIf;
			vRight = Mid(vTxt, Int(vWidth/2) + 1 + i, 2);
			If vRight = "  " Then
				vRightTxt = Left(vRightTxt, k) + Mid(vTxt, Int(vWidth/2) + i + 2);
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
			If Int(vRemains/2) <> vRemains/2 Then
				vRemains = vRemains + 1;
			EndIf;
			vTxt = Mid(vTxt, vRemains/2+1);
			vTxt = Left(vTxt, StrLen(vTxt) - vRemains/2);
		EndIf;
		vSlip = vSlip + vTxt + Chars.LF;
	EndDo;
	Return TrimAll(vSlip);
EndFunction // SlipFormat

// -----------------------------------------------------------------------------
Function GetTerminalId(pObj)
	If pObj = Undefined Then
		Return Number(StrReplace(TrimAll(CreditCardsProcessingSystemParameters.TerminalNumber), " ", ""));
	ElsIf TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj) And Not IsBlankString(pObj.TerminalNumber) And TrimAll(pObj.TerminalNumber) <> "0" Then
		Return Number(StrReplace(TrimAll(pObj.TerminalNumber), " ", ""));
	ElsIf Not TypeOf(pObj) = Type("CatalogRef.CashRegisters") And ValueIsFilled(pObj.CashRegister) And Not IsBlankString(pObj.CashRegister.TerminalNumber) And TrimAll(pObj.CashRegister.TerminalNumber) <> "0" Then
		Return Number(StrReplace(TrimAll(pObj.CashRegister.TerminalNumber), " ", ""));
	Else
		Return Number(StrReplace(TrimAll(CreditCardsProcessingSystemParameters.TerminalNumber), " ", ""));
	EndIf;
EndFunction // GetTerminalId

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
Function GetDateFromString(pStr)
	If StrLen(pStr) = 4 Then
		Try
			Return BegOfMonth(Date(2000+Number(Right(pStr, 2)), Number(Left(pStr, 2)), 01));
		Except
			Return BegOfMonth(Date(2000+Number(Left(pStr, 2)), Number(Right(pStr, 2)), 01));
		EndTry;
	Else
		Return '00010101'
	EndIf;
EndFunction // GetDateFromString

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
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = GetPersistentObject("TrPosX");
		If vPC = Undefined Then
			vPC = New COMObject("TRPOSX.TRPOSX");
			// Read connection parameters
			vConnParameters = CreditCardsProcessingSystemParameters.ConnectionParameters.Get();
			// Write connection parameters to the configuration file
			vConfFileName = cmCommonDir() + "trposx.cfg";
			vConfFile =  New TextDocument();
			vConfFile.SetText(vConnParameters);
			vConfFile.Write(vConfFileName, TextEncoding.ANSI);
			// Initialize connection to the POS system
			vRC = vPC.Init(vConfFileName);
			If vRC <> 0 Then
				rMessage = GetErrorDescription(vRC);
				vPC = Undefined;
				Return vPC;
			EndIf;
			SetPersistentObject("TrPosX", vPC);
			// Wait 20 seconds
			cmWait(20);
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
		If pPC <> Undefined Then
			pPC.Close();
		EndIf;
		pPC = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect() Export
	Try
		vPC = GetPersistentObject("TrPosX");
		Disconnect(vPC);
		SetPersistentObject("TrPosX", Undefined);
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
		rMessage = GetErrorDescription(pRC);
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Result description: " + rMessage);
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
Function GetApprove(pOutParams)
	vApprove = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "Approve=");
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
		vPos = Find(vTxtLine, "ResponseCode=");
		If vPos > 0 Then
			vResponseCode = TrimAll(Mid(vTxtLine, vPos + 13));
			Break;
		EndIf;	
	EndDo;
	Return vResponseCode;
EndFunction // GetResponseCode

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
Function GetAuthorizationID(pOutParams)
	vAuthorizationID = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "AuthorizationID=");
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
		vPos = Find(vTxtLine, vParameterName);
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
		vPos = Find(vTxtLine, vParameterName);
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
		vPos = Find(vTxtLine, vParameterName);
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
		vPos = Find(vTxtLine, vParameterName);
		If vPos > 0 Then
			vTransactionID = TrimAll(Mid(vTxtLine, vPos + StrLen(vParameterName)));
			Break;
		EndIf;
	EndDo;
	Return vTransactionID;
EndFunction // GetTransactionID

// -----------------------------------------------------------------------------
Function GetCardNumber(pOutParams)
	vCardNumber = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "PAN=");
		If vPos > 0 Then
			vCardNumber = TrimAll(Mid(vTxtLine, vPos + 4));
			Break;
		EndIf;
	EndDo;
	Return vCardNumber;
EndFunction // GetCardNumber

// -----------------------------------------------------------------------------
Function GetCardEncData(pOutParams)
	vCardEncData = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "CardDataEnc=");
		If vPos > 0 Then
			vCardEncData = TrimAll(Mid(vTxtLine, vPos + 12));
			Break;
		EndIf;
	EndDo;
	Return vCardEncData;
EndFunction // GetCardEncData 

// -----------------------------------------------------------------------------
Function GetMaskedCardNumber(pOutParams)
	vCardNumber = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "PANhide=");
		If vPos > 0 Then
			vCardNumber = TrimAll(Mid(vTxtLine, vPos + 8));
			Break;
		EndIf;
	EndDo;
	Return vCardNumber;
EndFunction // GetMaskedCardNumber

// -----------------------------------------------------------------------------
Function GetCardHolder(pOutParams)
	vCardHolder = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "Cardholder=");
		If vPos > 0 Then
			vCardHolder = TrimAll(Mid(vTxtLine, vPos + 11));
			Break;
		EndIf;
	EndDo;
	Return vCardHolder;
EndFunction // GetCardHolder

// -----------------------------------------------------------------------------
Function GetCardType(pOutParams)
	vCardTypeRef = Catalogs.CreditCardTypes.EmptyRef();
	vCardType = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "IssuerName=");
		If vPos > 0 Then
			vCardType = TrimAll(Mid(vTxtLine, vPos + 11));
			Break;
		EndIf;
	EndDo;
	If Not IsBlankString(vCardType) Then
		vCardTypeRef = tcCreditCardsProcessingSystemDriverAtServer.GetCreditCardType(vCardType);
	EndIf;
	Return vCardTypeRef;
EndFunction // GetCardType

// -----------------------------------------------------------------------------
Function GetCardExpDate(pOutParams)
	vCardExpDateStr = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "ExpDate=");
		If vPos > 0 Then
			vCardExpDateStr = TrimAll(Mid(vTxtLine, vPos + 8));
			Break;
		EndIf;
	EndDo;
	Return GetDateFromString(vCardExpDateStr);
EndFunction // GetCardExpDate

// -----------------------------------------------------------------------------
Function GetDateTime(pOutParams)
	vOperationDateTime = "";
	For i = 0 To (pOutParams.Count() - 1) Do
		vTxtLine = pOutParams.Get(i);
		vPos = Find(vTxtLine, "DateTime=");
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
		vPos = Find(vTxtLine, "VisualHostResponse=");
		If vPos > 0 Then
			vResponse = TrimAll(Mid(vTxtLine, vPos + 19));
			Break;
		EndIf;
	EndDo;
	Return vResponse;
EndFunction // GetVisualHostResponse

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pOutParams, pObj)
	vCardNumber = GetCardNumber(pOutParams);
	vCardEncData = GetCardEncData(pOutParams);
	vCardRef = Undefined;
	If Not IsBlankString(vCardEncData) Then
		vCardRef = Catalogs.CreditCards.FindByAttribute("CardDataEnc", vCardEncData);
		If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
			vCardRef = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		If Not IsBlankString(vCardNumber) And cmIsNumber(vCardNumber) Then
			vCardRef = Catalogs.CreditCards.FindByAttribute("CardNumber", vCardNumber);
			If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
				vCardRef = Undefined;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vMaskedCardNumber = GetMaskedCardNumber(pOutParams);
		If IsBlankString(vMaskedCardNumber) Then
			vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		Else
			vCardObj.Description = vMaskedCardNumber;
		EndIf;
		vCardObj.CardOwner = GetCardOwner(pObj);
		vCardObj.CardType = GetCardType(pOutParams);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardHolder = GetCardHolder(pOutParams);
		vCardObj.CardValidTillDate = GetCardExpDate(pOutParams);
		vCardObj.CardDataEnc = vCardEncData;
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	Else
		vCardType = GetCardType(pOutParams);
		If ValueIsFilled(vCardType) And Not ValueIsFilled(vCardRef.CardType) Then
			vCardObj = vCardRef.GetObject();
			vCardObj.CardType = vCardType;
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
Procedure LogOnLineAuthorization(pOutParams, pFunction)
	vMessage = NStr("ru = 'Выполнена on-line авторизация! Параметры: '; en = 'On-line authorization processed with parameters: '; de = 'On-line authorization processed with parameters: '") + Chars.LF + pOutParams;
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма преавторизации!'; en = 'Zero sum preauthorization is not possible!'; de = 'Zero sum preauthorization is not possible!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pObj);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(cmGetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "TransactionAmount=" + Format(pObj.Sum*100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "MessageID=AUT";
			// Voice preauthorisation
			If ValueIsFilled(pObj.CreditCard) Then
				If StrLen(TrimAll(pObj.CreditCard.CardDataEnc)) = 32 Then
					vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(pObj.CreditCard.CardDataEnc);
				Else
					If Not IsBlankString(pObj.CreditCard.CardNumber) Then
						vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(pObj.CreditCard.CardNumber);
					EndIf;
					If ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
						vInParams = vInParams + Chars.LF + "ExpDate=" + Format(pObj.CreditCard.CardValidTillDate, "DF=MMyy");
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.Company) And Not IsBlankString(pObj.Company.MerchantID) Then
				vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(pObj.Company.MerchantID);
			EndIf;
			If ValueIsFilled(pObj.TransactionID) And Not IsBlankString(pObj.TransactionID) Then
				vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(pObj.TransactionID);
			Else
				vInParams = vInParams + Chars.LF + "TransactionID=0";
			EndIf;

			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			If vOutParamsLen = 0 Then
				vRC = 80; // Timeout
				ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
				// Do auto cancellation
				vOutParamsLen = 0;
				vOutSlipLen = 0;
				vInParams = StrReplace(vInParams, "MessageID=AUT", "MessageID=VOI");
				vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
				// Return error
				Return False;
			EndIf;
			// Get response
			vOutParams = vPC.GetResponse(0, vOutParamsLen);
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("ru = 'От POS терминала получен пустой ответ'; en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'");
			EndIf;
			vOutParamsArr = cmGetTextLinesArray(vOutParams);
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
				rMessage = NStr("ru = 'Операция отклонена банком! Код ответа: '; en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister);
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCreditCardRef = SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vOutParamsArr);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vInvoiceNumber + "/" + vReferenceNumber;
			pObj.TerminalNumber = vTerminalNumber;
			pObj.SlipText = vOutSlip;
			pObj.TransactionID = vTransactionID;
			pObj.DateTime = vDateTime;
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
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
Function pmCancelPreauthorization(pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check preauthorization amount
			If pObj.Sum = 0 Then
				Raise NStr("ru = 'Не указана сумма отмены!'; en = 'Zero amount is not possible!'; de = 'Zero amount is not possible!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pObj);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(cmGetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
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
				If StrLen(TrimAll(pObj.CreditCard.CardDataEnc)) = 32 Then
					vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(pObj.CreditCard.CardDataEnc);
				Else
					If Not IsBlankString(pObj.CreditCard.CardNumber) Then
						vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(pObj.CreditCard.CardNumber);
					EndIf;
					If ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
						vInParams = vInParams + Chars.LF + "ExpDate=" + Format(pObj.CreditCard.CardValidTillDate, "DF=MMyy");
					EndIf;
				EndIf;
			EndIf;
			vInParams = vInParams + Chars.LF + "MessageID=VOI";
			If ValueIsFilled(pObj.Company) And Not IsBlankString(pObj.Company.MerchantID) Then
				vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(pObj.Company.MerchantID);
			EndIf;
			If Not IsBlankString(pObj.TransactionID) Then
				vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(pObj.TransactionID);
			EndIf;
			If Not IsBlankString(pObj.DateTime) Then
				vInParams = vInParams + Chars.LF + "DateTime=" + TrimAll(pObj.DateTime);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage) Then
				Return False;
			EndIf;
			If vOutParamsLen = 0 Then
				vRC = 80; // Timeout
				ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
				// Return error
				Return False;
			EndIf;
			// Get response
			vOutParams = vPC.GetResponse(0, vOutParamsLen);
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("ru = 'От POS терминала получен пустой ответ'; en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'");
			EndIf;
			vOutParamsArr = cmGetTextLinesArray(vOutParams);
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
				rMessage = NStr("ru = 'Операция отклонена банком! Код ответа: '; en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister);
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCreditCardRef = SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vOutParamsArr);
			EndIf;
			// Change preauthorization status if there are no erros
			pObj.Status = Enums.PreauthorisationStatuses.Cancelled;
			pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vInvoiceNumber + "/" + vReferenceNumber + Chars.LF;
			pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			pObj.AuthorOfCancellation = SessionParameters.CurrentUser;
			pObj.DateOfCancellation = CurrentSessionDate();
			pObj.Write(DocumentWriteMode.Posting);
			// Print slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
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
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма авторизации!'; en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'");
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
			vTerminalId = GetTerminalId(pObj);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			If ValueIsFilled(pObj.Company) And Not IsBlankString(pObj.Company.MerchantID) Then
				vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(pObj.Company.MerchantID);
			EndIf;
			vInParams = vInParams + Chars.LF + "MessageID=&OperationCode";
			vInParams = vInParams + Chars.LF + "TransactionAmount=&OperationAmount";
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				vOperationCode = "CMP";
				// Complete preauthorization
				vRRN = "";
				If Not IsBlankString(pObj.Preauthorisation.ReferenceNumber) Then
					If StrLen(TrimAll(pObj.Preauthorisation.ReferenceNumber)) <= 6 Then
						vInvoiceNumber = Format(Number(TrimAll(pObj.Preauthorisation.ReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
					Else
						vInvoiceNumber = Left(TrimAll(pObj.Preauthorisation.ReferenceNumber), 6);
						vRRN = Right(TrimAll(pObj.Preauthorisation.ReferenceNumber), 12);
					EndIf;
				EndIf;
				If Not IsBlankString(vRRN) Then
					vInParams = vInParams + Chars.LF + "RRN=" + vRRN;
				EndIf;
				vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(pObj.Preauthorisation.AuthorizationCode);
				If ValueIsFilled(pObj.Preauthorisation.CreditCard) Then
					If StrLen(TrimAll(pObj.Preauthorisation.CreditCard.CardDataEnc)) = 32 Then
						vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(pObj.Preauthorisation.CreditCard.CardDataEnc);
					Else
						If Not IsBlankString(pObj.Preauthorisation.CreditCard.CardNumber) Then
							vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(pObj.Preauthorisation.CreditCard.CardNumber);
						EndIf;
						If ValueIsFilled(pObj.Preauthorisation.CreditCard.CardValidTillDate) Then
							vInParams = vInParams + Chars.LF + "ExpDate=" + Format(pObj.Preauthorisation.CreditCard.CardValidTillDate, "DF=MMyy");
						EndIf;
					EndIf;
				EndIf;
				If Not IsBlankString(pObj.Preauthorisation.TransactionID) Then
					vInParams = vInParams + Chars.LF + "TransactionID=" + TrimAll(pObj.Preauthorisation.TransactionID);
					// Get total preauthorisation amount by transaction ID
					vPreauthorizationAmount = GetTotalPreauthorizationAmountByTransactionID(TrimAll(pObj.Preauthorisation.TransactionID));
					If vPreauthorizationAmount > pObj.Sum Then
						vExtraAmount = vPreauthorizationAmount - pObj.Sum;
					    vExtraInParams = vInParams;
						vExtraOperationCode = "VAU";
						If Not IsBlankString(pObj.Preauthorisation.DateTime) Then
							vExtraInParams = vExtraInParams + Chars.LF + "DateTime=" + TrimAll(pObj.Preauthorisation.DateTime);
						EndIf;
					ElsIf vPreauthorizationAmount < pObj.Sum Then
						vExtraAmount = pObj.Sum - vPreauthorizationAmount;
					    vExtraInParams = vInParams;
						vExtraOperationCode = "AUT";
					EndIf;
					If Not IsBlankString(vExtraOperationCode) And vExtraAmount <> 0 Then
						vExtraInParams = vExtraInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(cmGetDocumentNumberPresentation(TrimAll(pObj.Number))) + 1000000, "ND=10; NFD=0; NZ=; NLZ=; NG=");
						vExtraInParams = StrReplace(vExtraInParams, "&OperationCode", vExtraOperationCode);
						vExtraInParams = StrReplace(vExtraInParams, "&OperationAmount", Format(vExtraAmount*100, "ND=12; NFD=0; NZ=; NLZ=; NG="));
						If vExtraOperationCode = "VAU" Then
							vExtraInParams = vExtraInParams + Chars.LF + "TransactionAmount2=" + Format(vPreauthorizationAmount*100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
							If Not IsBlankString(vInvoiceNumber) Then
								vExtraInParams = vExtraInParams + Chars.LF + "InvoiceNumber=" + vInvoiceNumber;
							EndIf;
						EndIf;
						// Call extra processing
						WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
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
						vOutParams = vPC.GetResponse(0, vOutParamsLen);
						// Check output parameters
						If IsBlankString(vOutParams) Then
							// Return error
							Return False;
						EndIf;
						vOutParamsArr = cmGetTextLinesArray(vOutParams);
						// Parse response
						vApprove = GetApprove(vOutParamsArr);
						vResponseCode = GetResponseCode(vOutParamsArr);
						vAuthorizationCode = GetAuthorizationID(vOutParamsArr);
						// Check approve and response code
						If vApprove = "N" Or IsBlankString(vApprove) And vResponseCode <> "00" Then
							// Authorization was not successfull
							vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
							rMessage = NStr("ru = 'Операция отклонена банком! Код ответа: '; en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
							tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
							WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
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
							WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
							// Return error
							Return False;
						EndIf;
						// Get slip
						vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister);
						// Print authorization slip
						If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
						   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
						   Not IsBlankString(vOutSlip) Then
							vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
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
						If StrLen(TrimAll(pObj.CreditCard.CardDataEnc)) = 32 Then
							vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(pObj.CreditCard.CardDataEnc);
						EndIf;
					EndIf;
				Else
					vOperationCode = "REF";
					vRRN = "";
					vPayment = pObj.Payment;
					If ValueIsFilled(vPayment) Then
						While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
							vPayment = vPayment.Payment;
							If Not ValueIsFilled(vPayment) Then
								Break;
							EndIf;
						EndDo;
					EndIf;
					If ValueIsFilled(vPayment) Then
						If Not IsBlankString(vPayment.ReferenceNumber) Then
							If StrLen(TrimAll(vPayment.ReferenceNumber)) <= 6 Then
								vInvoiceNumber = Format(Number(TrimAll(vPayment.ReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
							Else
								vInvoiceNumber = Left(TrimAll(vPayment.ReferenceNumber), 6);
								vRRN = Right(TrimAll(vPayment.ReferenceNumber), 12);
							EndIf;
						EndIf;
						If Not IsBlankString(vRRN) Then
							vInParams = vInParams + Chars.LF + "RRN=" + vRRN;
						EndIf;
						vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(vPayment.AuthorizationCode);
						If ValueIsFilled(vPayment.CreditCard) Then
							If StrLen(TrimAll(vPayment.CreditCard.CardDataEnc)) = 32 Then
								vInParams = vInParams + Chars.LF + "CardDataEnc=" + TrimAll(vPayment.CreditCard.CardDataEnc);
							Else
								If Not IsBlankString(vPayment.CreditCard.CardNumber) Then
									vInParams = vInParams + Chars.LF + "PAN=" + TrimAll(vPayment.CreditCard.CardNumber);
								EndIf;
								If ValueIsFilled(vPayment.CreditCard.CardValidTillDate) Then
									vInParams = vInParams + Chars.LF + "ExpDate=" + Format(vPayment.CreditCard.CardValidTillDate, "DF=MMyy");
								EndIf;
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			If Not IsBlankString(vInvoiceNumber) Then
				vInParams = vInParams + Chars.LF + "InvoiceNumber=" + vInvoiceNumber;
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(cmGetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = StrReplace(vInParams, "&OperationCode", vOperationCode);
			vInParams = StrReplace(vInParams, "&OperationAmount", Format(pObj.Sum*100, "ND=12; NFD=0; NZ=; NLZ=; NG="));
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
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
			vOutParams = vPC.GetResponse(0, vOutParamsLen);
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("ru = 'От POS терминала получен пустой ответ'; en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'");
			EndIf;
			vOutParamsArr = cmGetTextLinesArray(vOutParams);
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
				rMessage = NStr("ru = 'Операция отклонена банком! Код ответа: '; en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister);
			// Save credit card data if neccessary
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCreditCardRef = SaveCreditCardData(vOutParamsArr, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
					pObj.CardType = vCreditCardRef.CardType;
				EndIf;
			Else
				pObj.CardType = GetCardType(vOutParamsArr);
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vInvoiceNumber + "/" + vReferenceNumber;
			pObj.TerminalNumber = vTerminalNumber;
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
Function GetTotalPreauthorizationAmountByTransactionID(pTransactionID)
	vAmount  = 0;
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	SUM(Preauthorisation.Sum) AS Sum
	|FROM
	|	Document.Preauthorisation AS Preauthorisation
	|WHERE
	|	Preauthorisation.Posted
	|	AND Preauthorisation.Status = &qStatus
	|	AND Preauthorisation.TransactionID = &qTransactionID";
	vQry.SetParameter("qStatus", Enums.PreauthorisationStatuses.Authorised);
	vQry.SetParameter("qTransactionID", TrimAll(pTransactionID));
	vTotals = vQry.Execute().Unload();
	If vTotals.Count() > 0 Then
		vAmount = vTotals.Total("Sum");
	EndIf;
	Return vAmount;
EndFunction // GetTotalPreauthorizationAmountByTransactionID

// -----------------------------------------------------------------------------
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check payment amount
			If pSum = 0 Then
				Raise NStr("ru = 'Не указана сумма аннуляции!'; en = 'Zero sum annulation is not possible!'; de = 'Zero sum annulation is not possible!'");
			EndIf;
			// Initialize output parameters
			vOutParamsLen = 0;
			vOutSlipLen = 0;
			// Initialise pay card system operation parameters
			vInParams = "";
			vTerminalId = GetTerminalId(pObj);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(Number(cmGetDocumentNumberPresentation(TrimAll(pObj.Number))), "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "TransactionAmount=" + Format(pObj.Sum*100, "ND=12; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "MessageID=VAU";
			If StrLen(TrimAll(pObj.ReferenceNumber)) <= 6 Then
				vInParams = vInParams + Chars.LF + "InvoiceNumber=" + Format(Number(TrimAll(pObj.ReferenceNumber)), "ND=6; NFD=0; NZ=; NLZ=; NG=");
			Else
				vInParams = vInParams + Chars.LF + "InvoiceNumber=" + Left(TrimAll(pObj.ReferenceNumber), 6);
				vInParams = vInParams + Chars.LF + "RRN=" + Right(TrimAll(pObj.ReferenceNumber), 12);
			EndIf;
			vInParams = vInParams + Chars.LF + "AuthorizationID=" + TrimAll(pObj.AuthorizationCode);
			If ValueIsFilled(pObj.Company) And Not IsBlankString(pObj.Company.MerchantID) Then
				vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(pObj.Company.MerchantID);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Get response
			vOutParams = vPC.GetResponse(0, vOutParamsLen);
			// Log all response codes
			LogOnLineAuthorization(vOutParams, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"));
			// Check output parameters
			If IsBlankString(vOutParams) Then
				Raise NStr("ru = 'От POS терминала получен пустой ответ'; en = 'Empty response received from the POS terminal!'; de = 'Empty response received from the POS terminal!'");
			EndIf;
			vOutParamsArr = cmGetTextLinesArray(vOutParams);
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
				rMessage = NStr("ru = 'Операция отклонена банком! Код ответа: '; en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '") + TrimAll(vResponseCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Check authorization code
			If IsBlankString(vAuthorizationCode) Or 
			   TrimAll(vAuthorizationCode) = "0" Then
				// Authorization was not successfull
				vVisualHostResponse = GetVisualHostResponse(vOutParamsArr);
				rMessage = NStr("ru = 'Операция отклонена банком! Код авторизации: '; en = 'Operation was refused by bank! Authorization code: '; de = 'Operation was refused by bank! Authorization code: '") + TrimAll(vAuthorizationCode) + NStr("en='; Host response: '; de='; Host response: '; ru='; Ответ терминала: '") + vVisualHostResponse;
				tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннуляцияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pObj.CashRegister);
			// Save main authorization attributes to the payment document
			If TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
				pObj.CancellationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
				pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vInvoiceNumber + "/" + vReferenceNumber + Chars.LF;
				pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
			Else
				pObj.AnnulationSlipText = "Auth. #" + vAuthorizationCode + Chars.LF;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + "Ref. #" + vInvoiceNumber + "/" + vReferenceNumber + Chars.LF;
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
	// Try to connect
	vPC = Connect(rMessage);
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
			vTerminalId = GetTerminalId(pCashRegister);
			If vTerminalId > 0 Then 
				vInParams = vInParams + Chars.LF + "ECRnumber=" + Format(vTerminalId, "ND=2; NFD=0; NZ=; NLZ=; NG=");
			EndIf;
			vInParams = vInParams + Chars.LF + "ECRReceiptNumber=" + Format(vTerminalId, "ND=10; NFD=0; NZ=; NLZ=; NG=");
			vInParams = vInParams + Chars.LF + "MessageID=SRV";
			If ValueIsFilled(pCashRegister) And Not IsBlankString(pCashRegister.Owner.MerchantID) Then
				vInParams = vInParams + Chars.LF + "MerchantID=" + TrimAll(pCashRegister.Owner.MerchantID);
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.Process'; de='CreditCardProcessingSystem.Process'; ru='СистемаПроцессингаКредитныхКарт.Процесс'"), EventLogLevel.Information, , , NStr("en='Parameters: '; de='Parameters: '; ru='Параметры: '") + vInParams);
			vRC = vPC.Process(vInParams, vOutParamsLen, vOutSlipLen);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.OpenServiceFunctionsMenu'; de='CreditCardProcessingSystem.OpenServiceFunctionsMenu'; ru='СистемаПроцессингаКредитныхКарт.ОткрытиеМенюСервисныхФункций'"), rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = SlipFormat(vPC.GetReceipt(0, vOutSlipLen), pCashRegister);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vStruct = New Structure("CashRegister", pCashRegister);
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct);
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.OpenServiceFunctionsMenu'; de='CreditCardProcessingSystem.OpenServiceFunctionsMenu'; ru='СистемаПроцессингаКредитныхКарт.ОткрытиеМенюСервисныхФункций'"), rMessage);
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // pmOpenServiceFunctionsMenu
