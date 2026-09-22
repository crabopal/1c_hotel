#Region Variables

Var DefaultConnectionParameters;
Var ConnectionParameters;

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pName	 - String	 - Name
// 
// Returns:
//  COMObject - COM object
//
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
//
// Parameters:
//  pName	 - String	 - Name
//  pValue	 - COMObject - COM object
// 
// Returns:
//  Boolean - Result
//
Function SetPersistentObject(pName, pValue) Export
	#IF CLIENT THEN
		amPersistentObjects.Insert(pName, pValue);
	#ENDIF
EndFunction // SetPersistentObject

// -----------------------------------------------------------------------------
//
Procedure pmDisconnect() Export
	Try
		vPC = GetPersistentObject("UCS");
		Disconnect(vPC);
		SetPersistentObject("UCS", Undefined);
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage	 - String											 - Error message
//  pSettingsObj - CatalogRef.CreditCardsProcessingSystemParameters	 - Credit cards processing system parameters
// 
// Returns:
//  Boolean - Result
//
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
			vFrm.Caption = NStr("en='Please input configuration file data';de='Please input configuration file data'; ru='Укажите здесь данные конфигурационного файла'");
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
		vPC = GetPersistentObject("UCS");
		If vPC = Undefined Then
			vPC = Connect(Undefined, rMessage);
		EndIf;

		vPC = Connect(Undefined, rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the PIN pad device
		vAddInfo = "";
		vDemoAddInfo = "";
		vRC = vPC.DeviceTest(vAddInfo, vDemoAddInfo);
		If Not vRC Then
			vErrCode = GetErrorDescription(vPC, rMessage);
			If vAddInfo <> vDemoAddInfo And Not IsBlankString(vAddInfo) And Not IsBlankString(vDemoAddInfo) Then
				rMessage = rMessage + Chars.LF + vAddInfo + Chars.LF + vDemoAddInfo;
			ElsIf Not IsBlankString(vAddInfo) Then 
				rMessage = rMessage + Chars.LF + vAddInfo;
			ElsIf Not IsBlankString(vDemoAddInfo) Then 
				rMessage = rMessage + Chars.LF + vDemoAddInfo;
			EndIf;
			Disconnect(vPC);
			Return False;
		Else
			rMessage = vAddInfo + Chars.LF + vDemoAddInfo;
		EndIf;
		Disconnect(vPC);
		Return True;
	Except
		rMessage = ErrorDescription();
		Return False;
	EndTry;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum	 - Number						 - Sum
//  pObj	 - DocumentObject.Preauthorisation	 - Preauthorisation
//  rMessage - String							 - Error message
// 
// Returns:
//  Boolean - Result
//
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	rMessage = "";
	Return True;
EndFunction // pmPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum	 - Number									 - Sum
//  pVATSum	 - Number									 - VAT sum
//  pObj	 - DocumentObject.Return, DocumentObject.Payment - Return Or Payment
//  rMessage - String										 - Error message
// 
// Returns:
//  Boolean - Result
//
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(pObj, rMessage);
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
				If ConnectionParameters.Currency = 810 And pObj.PaymentCurrency.Code <> 643 And pObj.PaymentCurrency.Code <> 810 Or 
				   ConnectionParameters.Currency <> 810 And pObj.PaymentCurrency.Code <> ConnectionParameters.Currency Then
					Raise NStr("ru = 'Валюта платежа отличается от валюты платежного терминала!'; en = 'Payment currency differs from the currency of payment terminal!'; de = 'Zahlungswährung von der Währung des Zahlungsterminal sich unterscheiden!'");
				EndIf;
			EndIf;
			// Voice authorisation
			vAuthorizationCode = "";
			vReferenceNumber = "";
			vVoicepay = False;
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) And 
			   ValueIsFilled(pObj.CreditCard) And Not IsBlankString(pObj.CreditCard.CardNumber) And cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) And 
			   ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardData = TrimAll(pObj.CreditCard.CardType) + Chars.LF + 
				            TrimAll(pObj.CreditCard.CardNumber) + " " + TrimAll(pObj.CreditCard.CardSecurityCode) + Chars.LF + 
				            TrimAll(pObj.CreditCard.CardHolder) + " " + Format(pObj.CreditCard.CardValidTillDate, "DF=MM.yyyy");
				vFrm = ThisObject.GetForm("InputPayCardDataManually");
				vFrm.SelDescription = vCardData;			
				vAuthcode = vFrm.DoModal();
				If vAuthcode <> Undefined Then
					vAuthorizationCode = vAuthcode;
					vVoicepay = True;
				Else
					rMessage = NStr("en='Operation was cancelled!'; ru='Операция отменена!'; de='Vorgang wurde abgebrochen!'");
					Return False;
				EndIf;
			EndIf;
			// Do operation
			vSlipName = "";
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(pObj.Preauthorisation.AuthorizationCode);
				vReferenceNumber = TrimAll(pObj.Preauthorisation.ReferenceNumber);
				vVoicepay = True;
				// Call processing
				vOperationType = NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation';de='CreditCardProcessingSystem.AuthorisationConfirmation';ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'");
				WriteLogEvent(vOperationType, EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
				vSlipName = NStr("en='Auth. confirmation';de='Auth. confirmation';ru='Расчет по преавторизации'");
			Else
				If pSum > 0 Then
					// Call processing
					vOperationType = NStr("en='CreditCardProcessingSystem.AuthorizePayment';de='CreditCardProcessingSystem.AuthorizePayment';ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'");
					WriteLogEvent(vOperationType, EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
					vSlipName = NStr("en='Authorisation';de='Authorisation';ru='Авторизация'");
				Else
					// Take parameters from the payment
					vPayment = Undefined;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						If ValueIsFilled(pObj.Payment) Then
							vPayment = pObj.Payment;
							While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
								vPayment = vPayment.Payment;
								If Not ValueIsFilled(vPayment) Then
									Break;
								EndIf;
							EndDo;
						EndIf;
					ElsIf TypeOf(pObj) = Type("DocumentObject.CustomerPayment") Then
						If ValueIsFilled(pObj.CustomerPayment) Then
							vPayment = pObj.CustomerPayment;
						EndIf;
					EndIf;
					If ValueIsFilled(vPayment) Then
						vReferenceNumber = TrimAll(vPayment.ReferenceNumber);
						vAuthorizationCode = TrimAll(vPayment.AuthorizationCode);
					Else
						vReferenceNumber = TrimAll(pObj.ReferenceNumber);
						vAuthorizationCode = TrimAll(pObj.AuthorizationCode);
					EndIf;
					vOperationType = NStr("en='CreditCardProcessingSystem.ReturnPayment';de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'");
					WriteLogEvent(vOperationType, EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(-pSum, pObj.PaymentCurrency));
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
					If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
					   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
					   Not IsBlankString(rOutSlip) Then
						// Format slip
						vOutSlip = GetOperationSlipCheque(rOutSlip, vSlipName);
						vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
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
			If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
				vCreditCardRef = SaveCreditCardData(vCardNumber, pObj);
				If ValueIsFilled(vCreditCardRef) Then
					pObj.CreditCard = vCreditCardRef;
				EndIf;
			EndIf;
			// Save authorization code and reference number if there are no errors
			pObj.AuthorizationCode = vAuthorizationCode;
			pObj.ReferenceNumber = vReferenceNumber;
			If pSum < 0 And (TypeOf(pObj) = Type("DocumentObject.Payment") Or TypeOf(pObj) = Type("DocumentObject.CustomerPayment")) Then
				pObj.AnnulationSlipText = "Ref. #" + vReferenceNumber + Chars.LF;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + vOutSlip;
			Else
				pObj.SlipText = vOutSlip;
			EndIf;
			pObj.Write(DocumentWriteMode.Write);
			// Print authorization slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
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
//
// Parameters:
//  pObj	 - DocumentObject.Preauthorisation	 - Preauthorisation
//  rMessage - String							 - Error message
// 
// Returns:
//  Boolean - Result
//
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
		WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelPreauthorization';de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
		Return False;
	EndTry;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum	 - Number			 - Sum
//  pVATSum	 - Number			 - VAT Sum
//  pObj	 - DocumentObject.Return - Return
//  rMessage - String				 - Error message
// 
// Returns:
//  Boolean - Result
//
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	Return pmAuthorizePayment(-pSum, -pVATSum, pObj, rMessage);
EndFunction // pmAnnulatePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage		 - String				 - Error message
//  pCashRegister	 - CatalogRef.CashRegisters	 - Cash registers
// 
// Returns:
//  Boolean - Result
//
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister) Export
	// Ask for operation type
	vUserChoice = Undefined;
	vUserChoices = New ValueList();
	vUserChoices.Add(2, NStr("en='Print short report'; ru='Печать краткого отчета'; de='Drucken Kurzbericht'"));
	vUserChoices.Add(3, NStr("en='Print detailed report'; ru='Печать детального отчета'; de='Drucken ausführlichen Bericht'"));
	vUserChoices.Add(1, NStr("en='Totals check (settlement)'; ru='Сверка итогов'; de='Überleitung der Ergebnisse'"));
	#IF CLIENT THEN
		vUserChoiceItem = vUserChoices.ChooseItem(NStr("en='Operation type'; ru='Тип операции'; de='Betriebstyp'"));
		If vUserChoiceItem = Undefined Then
			Return True;
		EndIf;
		vUserChoice = vUserChoiceItem.Value;
	#ELSE
		vUserChoice = 1;
	#ENDIF
	// Try to connect
	vPC = Connect(pCashRegister, rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		vStruct = New Structure("CashRegister", pCashRegister);
		vOperationType = "";
		vSlipName = "";
		If vUserChoice = 1 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.Settlement';de='CreditCardProcessingSystem.Settlement';ru='СистемаПроцессингаКредитныхКарт.СверкаИтогов'");
			vSlipName = NStr("en='Settlement';de='Settlement';ru='Сверка итогов'");
		ElsIf vUserChoice = 2 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.PrintShortReport';de='CreditCardProcessingSystem.PrintShortReport';ru='СистемаПроцессингаКредитныхКарт.ПечатьКраткогоОтчета'");
			vSlipName = NStr("en='Print short report';de='Print short report';ru='Печать краткого отчета'");
		ElsIf vUserChoice = 3 Then
			vOperationType = NStr("en='CreditCardProcessingSystem.PrintDetailedReport';de='CreditCardProcessingSystem.PrintDetailedReport';ru='СистемаПроцессингаКредитныхКарт.ПечатьДетальногоОтчета'");
			vSlipName = NStr("en='Print detailed report';de='Print detailed report';ru='Печать детального отчета'");
		EndIf;
		// Try to get device id and open connection to the terminal
		vDevID = "";
		vRC = vPC.Open(vDevID);
		If Not vRC Then
			vErrCode = GetErrorDescription(vPC, rMessage);
			Return False;
		EndIf;
		// Init
		rOutSlip = "";
		// Pay card system object was created successfully
		Try
			If vUserChoice = 1 Then
				// Bank day settlement
				vRC = vPC.Settlement(vDevID, rOutSlip);
			Else
				vRC = vPC.PrintReport(vDevID, vUserChoice, rOutSlip);
			EndIf;
			// Check result code
			If Not ProcessResultCode(vRC, vPC, vOperationType, rMessage) Then
				Return False;
			EndIf;
			// Get slip
			vOutSlip = GetOperationSlipCheque(rOutSlip, vSlipName);
			// Print annulation slip
			If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
			   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And 
			   Not IsBlankString(vOutSlip) Then
				vSlipTxtArr = cmGetTextLinesArray(vOutSlip);
				PrintSlipDocument(vSlipTxtArr, vStruct);
			EndIf;
			// Close connection
			vRC = vPC.Close(vDevID);
			ProcessResultCode(vRC, vPC, vOperationType, rMessage);
			vPC = Undefined;
			// Success
			#IF CLIENT THEN
				DoMessageBox(NStr("en='Operation completed successfully!'; de='Operation completed successfully!'; ru='Операция выполнена успешно!'"));
			#ENDIF
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
		vTerminalNumber = "0000000000";
	Else
		If StrLen(vTerminalNumber) < 10 And cmIsNumber(vTerminalNumber) Then
			vTerminalNumber = Format(Number(vTerminalNumber), "ND=10; NFD=; NZ=; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vTerminalNumber;
EndFunction // GetTerminalId

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
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("ConnectionType, RSPort, RSSpeed, RSTimeout, TCPIP, TCPPort, TCPTimeout, Currency, WriteLog, LogFileName, ArchPeriod, HeadLn1, HeadLn2, HeadLn3, HeadLn4, UseCommit, PathToDataBase, PostOperTimeout, InitTimeout", 
										 0,              0,      0,       0,         "",    0,       0,          0,        false,    "",          0,          "",      "",      "",      "",      false,     "",             0,               0);
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
	Return vConnParameters;
EndFunction // ParseConnectionParameters

// -----------------------------------------------------------------------------
Procedure SetConnectionParameters(pPC, pObj)
	If ConnectionParameters <> Undefined Then
		pPC.TerminalID = GetTerminalId(pObj);
		pPC.RcpWidth = CreditCardsProcessingSystemParameters.SlipCharLineLength;
		FillPropertyValues(pPC, ConnectionParameters);
	EndIf;
EndProcedure // SetConnectionParameters

// -----------------------------------------------------------------------------
Function Connect(pObj, rMessage)
	// Reset return status
	rMessage = "";
	// Try to create external component
	Try
		vPC = Undefined;
		// Get connection parameters
		ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get());
		If ConnectionParameters = Undefined Then
			Raise NStr("en='UCS parameters XML data should be filled!';de='UCS parameters XML data should be filled!'; ru='Не заполнен XML файл с параметрами подключения к системе UCS!'");
		EndIf;
		vPC = New COMObject("AddIn.UCS_EFTPOS");
		SetConnectionParameters(vPC, pObj);
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
Function ProcessResultCode(pRC, pPC, pFunction, rMessage, rErrCode = 0)
	rErrCode = 0;
	If Not pRC Then
		rErrCode = GetErrorDescription(pPC, rMessage);
		If rErrCode <> 0 Then
			rMessage = NStr("en='Host response: ';de='Host response: '; ru='Ответ хоста: '") + Format(rErrCode, "ND=10; NFD=0; NZ=; NG=") + Chars.LF + 
			           NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung.'") + rMessage;
		Else
			rMessage = NStr("en='Error description: ';ru='Описание ошибки: ';de='Fehlerbeschreibung.'") + rMessage;
		EndIf;
		If rErrCode <> -101 Then
			tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		EndIf;
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
Function SaveCreditCardData(pCardNumber, pObj)
	vCardNumber = TrimAll(pCardNumber);
	vCardRef = Undefined;
	If Not IsBlankString(vCardNumber) Then
		vCardRef = Catalogs.CreditCards.FindByAttribute("CardNumber", vCardNumber);
		If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
			vCardRef = Undefined;
		EndIf;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		vCardObj.CardOwner = GetCardOwner(pObj);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardDataEnc = vCardNumber;
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
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
		rMessage = NStr("en='Cash register is not specified!';de='Cash register is not specified!'; ru='Не выбран ККМ для печати!'");
	EndIf;
EndFunction // PrintSlipDocument

// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pAuthCode, pRRN, pFunction)
	vMessage = NStr("ru = 'Выполнена on-line авторизация! Код авторизации/RRN: '; en = 'On-line authorization processed with authorization code/RRN: '; de = 'On-line authorization processed with authorization code/RRN: '") + pAuthCode + "/" + pRRN;
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

// -----------------------------------------------------------------------------
Function GetOperationSlipCheque(pSlipCheque, pSlipName)
	vTildaSPos  = Find(pSlipCheque, "[cut]");
	If vTildaSPos > 0 Then
		vSlipCheque = TrimAll(pSlipName) + Chars.LF + Left(pSlipCheque, vTildaSPos - 1);
	Else
		vSlipCheque = TrimAll(pSlipName) + Chars.LF +  pSlipCheque;
	EndIf;
	Return vSlipCheque;
EndFunction // GetOperationSlipCheque

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
DefaultConnectionParameters = 
"<UCSConnectionParameters>
|	<ConnectionType>1</ConnectionType> <!-- 0 - RS/232; 1 - TCP/IP -->
|	<RSPort>0</RSPort> <!-- COM port number -->
|	<RSSpeed>0</RSSpeed> <!-- 0 – 2400, 1 – 4800, 2 – 9600, 3 – 19200, 4 – 38400, 5 – 57600, 6 – 115200 -->
|	<RSTimeout>0</RSTimeout>
|	<TCPIP>192.168.0.0</TCPIP>
|	<TCPPort>4001</TCPPort>
|	<TCPTimeout>0</TCPTimeout>
|	<Currency>810</Currency>
|	<WriteLog>false</WriteLog>
|	<LogFileName></LogFileName>
|	<ArchPeriod>0</ArchPeriod> <!-- 0 – do not archive, 1 – day, 2 – week, 3 – month, 4 – year -->
|	<HeadLn1></HeadLn1>
|	<HeadLn2></HeadLn2>
|	<HeadLn3></HeadLn3>
|	<HeadLn4></HeadLn4>
|	<UseCommit>false</UseCommit>
|	<PathToDataBase></PathToDataBase>
|	<PostOperTimeout>5</PostOperTimeout>
|	<InitTimeout>10</InitTimeout>
|</UCSConnectionParameters>";

#EndRegion