Var DefaultConnectionParameters;
Var ConnectionParameters;

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
Function GetErrorDescription(vPC)
	vMessage = "";
	Try
		vPC.GetLastError(vMessage);
	Except
		vMessage = NStr("en='<Description unknown>!'; de='<Description unknown>!'; ru='<Описание не найдено>!'");
	EndTry;
	Return vMessage;
EndFunction // GetErrorDescription

// -----------------------------------------------------------------------------
Function ParseConnectionParameters(pStr)
	vConnParameters = Undefined;
	If pStr <> Undefined And Not IsBlankString(pStr) Then
		vConnParameters = New Structure("SlipChequeCompanyRu, SlipChequeCompanyEn, " +
		                                "SlipChequeBankRu, SlipChequeBankEn, " + 
										"SlipChequeCityRu, SlipChequeCityEn, " + 
										"SlipChequeAddressRu, SlipChequeAddressEn, " + 
										"SlipChequeFooterTextRu, SlipChequeFooterTextEn, " + 
										"AuthServerIP, AuthServerPort, X25Script, TimeoutACK, AuthTimeoutPacket, CountNAK, PacketSize, TransactionTimeout, " + 
										"CtrlServerIP, CtrlServerPort, CtrlTimeoutPacket, COMPort, BaudRate, ByteSize, Parity, StopBits, FlowCtrl",
										"", "", "", "", "", "", "", "", "", "", 
										"127.0.0.1", 0, "", 5000, 45000, 3, 1024, 90, 
										"127.0.0.1", 0, 60000, 2, 19200, 8, 0, 0, 2);
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
		pPC.AuthServerIP = ConnectionParameters.AuthServerIP;
		pPC.AuthServerPort = ConnectionParameters.AuthServerPort;
		pPC.X25Script = ConnectionParameters.X25Script;
		pPC.TimeoutACK = ConnectionParameters.TimeoutACK;
		pPC.AuthTimeoutPacket = ConnectionParameters.AuthTimeoutPacket;
		pPC.CountNAK = ConnectionParameters.CountNAK;
		pPC.PacketSize = ConnectionParameters.PacketSize;
		pPC.TransactionTimeout = ConnectionParameters.TransactionTimeout;
		pPC.CtrlServerIP = ConnectionParameters.CtrlServerIP;
		pPC.CtrlServerPort = ConnectionParameters.CtrlServerPort;
		pPC.CtrlTimeoutPacket = ConnectionParameters.CtrlTimeoutPacket;
		pPC.COMPort = ConnectionParameters.COMPort;
		pPC.BaudRate = ConnectionParameters.BaudRate;
		pPC.ByteSize = ConnectionParameters.ByteSize;
		pPC.Parity = ConnectionParameters.Parity;
		pPC.StopBits = ConnectionParameters.StopBits;
		pPC.FlowCtrl = ConnectionParameters.FlowCtrl;
		pPC.TerminalID = GetTerminalId(pObj);
		pPC.TerminalDateTime = Format(CurrentSessionDate(), "DF=yyyyMMddHHmmss");
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
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.AddInPulsarDriver1CObject");
					vPC = New("AddIn.AddInPulsarDriver1C");
				Except
					LoadAddIn("PulsarDrv1C.dll");
					vPC = New("AddIn.AddInPulsarDriver1C");
				EndTry;
			#ELSE
				vPC = New("AddIn.AddInPulsarDriver1C");
			#ENDIF
		EndIf;
		// Read connection parameters
		ConnectionParameters = ParseConnectionParameters(CreditCardsProcessingSystemParameters.ConnectionParameters.Get());
		If ConnectionParameters = Undefined Then
			Raise NStr("en='INPAS parameters XML should be filled!'; de='INPAS parameters XML should be filled!'; ru='Не заполнен XML файл с параметрами подключения к системе ИНПАС!'");
		EndIf;
		SetConnectionParameters(vPC, pObj);
		SetPersistentObject("INPAS", vPC);
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
		vPC = Connect(Undefined, rMessage);
		If vPC = Undefined Then
			Return False;
		EndIf;
		// Initialize connection to the PIN pad device
		vAddInfo = "";
		vRC = vPC.TestDevice(vAddInfo);
		If Not vRC Then
			rMessage = GetErrorDescription(vPC);
			Disconnect(vPC);
			Return False;
		Else
			rMessage = vAddInfo;
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
		If Not IsBlankString(TrimAll(pPC.ResponseCode)) Then
			rMessage = NStr("en='Host response: '; de='Host response: '; ru='Ответ хоста: '") + TrimAll(pPC.ResponseCode) + " " + TrimAll(pPC.ResponseDescription) + Chars.LF + 
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
Function GetCardType(pPC)
	// Try to retrieve card type from the driver object properties
	vCardTypeStr = TrimAll(pPC.CardType);
	If IsBlankString(vCardTypeStr) And Not IsBlankString(TrimAll(pPC.PrintData)) Then
		vPrintData = TrimAll(pPC.PrintData);
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
Function GetTVR(pPC)
	// Try to retrieve TVR from the driver object properties
	vTVR = TrimAll(pPC.TVR);
	If IsBlankString(vTVR) And Not IsBlankString(TrimAll(pPC.PrintData)) Then
		vPrintData = TrimAll(pPC.PrintData);
		vPosStr = Find(vPrintData, "^TVR^");
		If vPosStr > 0 Then
			vPrintData = Mid(vPrintData, vPosStr + 5);
			If Not IsBlankString(vPrintData) Then
				vPosStr = Find(vPrintData, "~");
				If vPosStr > 0 Then
					vTVR = TrimAll(Left(vPrintData, vPosStr - 1));
				Else
					vTVR = TrimAll(vPrintData);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vTVR;
EndFunction // GetTVR

// -----------------------------------------------------------------------------
Function GetAID(pPC)
	// Try to retrieve AID from the driver object properties
	vAID = TrimAll(pPC.AID);
	If IsBlankString(vAID) And Not IsBlankString(TrimAll(pPC.PrintData)) Then
		vPrintData = TrimAll(pPC.PrintData);
		vPosStr = Find(vPrintData, "^AID^");
		If vPosStr > 0 Then
			vPrintData = Mid(vPrintData, vPosStr + 5);
			If Not IsBlankString(vPrintData) Then
				vPosStr = Find(vPrintData, "~");
				If vPosStr > 0 Then
					vAID = TrimAll(Left(vPrintData, vPosStr - 1));
				Else
					vAID = TrimAll(vPrintData);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	Return vAID;
EndFunction // GetAID

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pPC, pObj)
	vCardNumber = StrReplace(TrimAll(pPC.CardNumber), " ", "");
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
		vCardObj.CardValidTillDate = GetCardExpDate(pPC.CardExpiryDate);
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
			vCardObj.CardValidTillDate = GetCardExpDate(pPC.CardExpiryDate);
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
Function GetOperationSlipCheque(pPC, pOperation, pObj)
	vSlipCheque = "";
	vLanguage = Catalogs.Languages.RU;
	vLanguageCode = "Ru";
	If pObj <> Undefined Then
		If TypeOf(pObj) <> Type("DocumentObject.CustomerPayment") Then
			If ValueIsFilled(pObj.Payer) And ValueIsFilled(pObj.Payer.Language) Then
				vLanguage = pObj.Payer.Language;
				vLanguageCode = Title(TrimAll(pObj.Payer.Language.Code));
			EndIf;
		Else
			If ValueIsFilled(pObj.AccountingCustomer) And ValueIsFilled(pObj.AccountingCustomer.Language) Then
				vLanguage = pObj.AccountingCustomer.Language;
				vLanguageCode = Title(TrimAll(pObj.AccountingCustomer.Language.Code));
			EndIf;
		EndIf;
	EndIf;
	
	vAmount = 0;
	vCurrencyDescription = "";
	If pOperation <> "en='Settlement'; de='Settlement'; ru='Итоги дня по картам'" Then
		vAmount = Number(StrReplace(StrReplace(pPC.Amount, " ", ""), ",", "."));
		vCurrencyDescription = TrimAll(Catalogs.Currencies.FindByCode(TrimAll(pPC.CurrencyCode)));
	EndIf;
	
	vTxtDoc = New TextDocument();
	
	vSlipArea = Undefined;
	vSlipTemplateName = "SlipCheque" + Format(CreditCardsProcessingSystemParameters.SlipCharLineLength, "ND=2; NFD=0; NZ=; NLZ=; NG=") + vLanguageCode;
	vSlipTemplate = ThisObject.GetTemplate(vSlipTemplateName);
	vSlipArea = vSlipTemplate.GetArea("SlipCheque");
	
	ConnectionParameters.Property("SlipChequeBank" + vLanguageCode, vSlipArea.Parameters.Bank);
	ConnectionParameters.Property("SlipChequeCompany" + vLanguageCode, vSlipArea.Parameters.Company);
	ConnectionParameters.Property("SlipChequeCity" + vLanguageCode, vSlipArea.Parameters.City);
	ConnectionParameters.Property("SlipChequeAddress" + vLanguageCode, vSlipArea.Parameters.Address);
	ConnectionParameters.Property("SlipChequeFooterText" + vLanguageCode, vSlipArea.Parameters.FooterText);
	
	If pObj <> Undefined And TypeOf(pObj) <> Type("DocumentObject.Preauthorisation") Then
		vSlipArea.Parameters.Section = TrimAll(pObj.PaymentSection);
	Else
		vSlipArea.Parameters.Section = "";
	EndIf;
	vSlipArea.Parameters.Cashier = SessionParameters.CurrentUser.GetObject().pmGetEmployeeDescription(vLanguage);
	
	vSlipArea.Parameters.ChequeNumber = pPC.TerminalTrxID;
	vSlipArea.Parameters.TID = pPC.TerminalID;
	vSlipArea.Parameters.MID = pPC.MerchantID;
	vSlipArea.Parameters.Operation = Upper(cmNStr(pOperation, vLanguage));
	
	vSlipArea.Parameters.Amount = Format(vAmount, "ND=15; NFD=2; NS=2; NGS=' '; NG=3,0") + " " + vCurrencyDescription;
	vSlipArea.Parameters.Total = Format(vAmount, "ND=15; NFD=2; NS=2; NGS=' '; NG=3,0") + " " + vCurrencyDescription;
	vSlipArea.Parameters.CardType = TrimAll(GetCardType(pPC));
	vSlipArea.Parameters.PIN = ?(pPC.PinEntryMode = 0, "", "PIN");
	vSlipArea.Parameters.CardNumber = "**** **** **** " + Right(pPC.CardNumber, 4);
	vSlipArea.Parameters.CardExpiryDate = ?(IsBlankString(pPC.CardExpiryDate), "", Left(pPC.CardExpiryDate, 2) + "/" + Right(pPC.CardExpiryDate, 2));
	vSlipArea.Parameters.AuthorizationCode = TrimAll(pPC.AuthorizationCode);
	vSlipArea.Parameters.ReferenceNumber = TrimAll(pPC.RRNCode);
	vSlipArea.Parameters.HostReplyCode = TrimAll(pPC.ResponseCode);
	vSlipArea.Parameters.HostReplyDescription = TrimAll(pPC.ResponseDescription);
	vSlipArea.Parameters.Date = Format(Date(pPC.TerminalDateTime), "DF=yy/MM/dd");
	vSlipArea.Parameters.Time = Format(Date(pPC.TerminalDateTime), "DF=HH:mm:ss");
	vSlipArea.Parameters.ProgramID = GetAID(pPC);
	vSlipArea.Parameters.ProgramName = TrimAll(pPC.ApplicationLabel);
	vSlipArea.Parameters.TVR = GetTVR(pPC);
	vSlipArea.Parameters.CardHolder = GetCardHolder(pPC);

	vTxtDoc.Put(vSlipArea);
	vSlipCheque = vTxtDoc.GetText();
	
	Return vSlipCheque;
EndFunction // GetOperationSlipCheque

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
			   Not IsBlankString(pObj.CreditCard.CardNumber) And 
			   cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) And 
			   ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vPC.CardNumber = vCardNumber;
				vPC.CardExpiryDate = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vPC.CardNumber = "";
				vPC.CardExpiryDate = "";
			EndIf;
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
			vRC = vPC.AuthorisationByPaymentCard(vCardNumber, pSum * 100, vReferenceNumber, vAuthorizationCode);
			If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Log authorisation code and RRN
			LogOnLineAuthorization(vAuthorizationCode, vReferenceNumber, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"));
			// Check card expiry date
			#IF CLIENT THEN
				If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
					If Not ValueIsFilled(pObj.CreditCard) And 
					   IsBlankString(TrimAll(vPC.CardExpiryDate)) Then
						// Card number is returned with or without mask but expiry date is empty. 
						// Ask user to enter it from the card.
						vFrm = ThisObject.GetForm("InputPayCardDataManually");
						vFrm.SelPayCardNumber = cmGetCreditCardDescription(TrimAll(vPC.CardNumber));
						vFrm.SelDescription = NStr("en='Please enter card expiration period...'; de='Please enter card expiration period...'; ru='Укажите срок действия карты...'");
						vRetStruct = vFrm.DoModal();
						If vRetStruct <> Undefined Then
							vPC.CardExpiryDate = Format(vRetStruct.CardExpDate, "DF=yyMM");
							If Not IsBlankString(vRetStruct.PayCardNumber) And 
							   cmIsNumber(TrimAll(vRetStruct.PayCardNumber)) Then
								vPC.CardNumber = TrimAll(vRetStruct.PayCardNumber);
							EndIf;
						EndIf;
					EndIf;
				EndIf;
			#ENDIF
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
			If ValueIsFilled(pObj.CreditCard) And 
			   Not IsBlankString(pObj.CreditCard.CardNumber) And 
			   cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) And 
			   ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vPC.CardNumber = vCardNumber;
				vPC.CardExpiryDate = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vPC.CardNumber = "";
				vPC.CardExpiryDate = "";
			EndIf;
			// Fill operation currency code
			vPC.CurrencyCode = Format(pObj.PaymentCurrency.Code, "ND=3; NFD=0; NZ=; NLZ=; NG=");
			If TypeOf(pObj) = Type("DocumentObject.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
				// Take parameters from the preauthorisation
				vAuthorizationCode = TrimAll(pObj.Preauthorisation.AuthorizationCode);
				vReferenceNumber = TrimAll(pObj.Preauthorisation.ReferenceNumber);
				// Call processing
				WriteLogEvent(NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe: '") + cmFormatSum(pSum, pObj.PaymentCurrency));
				vRC = vPC.AuthConfirmationByPaymentCard(vCardNumber, pSum * 100, vReferenceNumber, vAuthorizationCode);
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
					vRC = vPC.PayByPaymentCard(vCardNumber, pSum * 100, vReferenceNumber, vAuthorizationCode);
					If Not ProcessResultCode(vRC, vPC, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
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
					vRC = vPC.ReturnPaymentByPaymentCard(vCardNumber, -pSum * 100, vReferenceNumber, vAuthorizationCode);
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
	vPC = Connect(pObj, rMessage);
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
			// Voice authorisation
			vCardNumber = "";
			If ValueIsFilled(pObj.CreditCard) And 
			   Not IsBlankString(pObj.CreditCard.CardNumber) And 
			   cmIsNumber(TrimAll(pObj.CreditCard.CardNumber)) And 
			   ValueIsFilled(pObj.CreditCard.CardValidTillDate) Then
				vCardNumber = TrimAll(pObj.CreditCard.CardNumber);
				vPC.CardNumber = vCardNumber;
				vPC.CardExpiryDate = Format(pObj.CreditCard.CardValidTillDate, "DF=yyMM");
			Else
				vPC.CardNumber = "";
				vPC.CardExpiryDate = "";
			EndIf;
			// Fill operation currency code
			vPC.CurrencyCode = Format(pObj.PaymentCurrency.Code, "ND=3; NFD=0; NZ=; NLZ=; NG=");
			// Call processing
			WriteLogEvent(NStr("en='CreditCardProcessingSystem.CancelAuthorisation'; de='CreditCardProcessingSystem.CancelAuthorisation'; ru='СистемаПроцессингаКредитныхКарт.ОтменаАвторизации'"), EventLogLevel.Information, pObj.Metadata(), , NStr("en='Amount: ';ru='Сумма: ';de='Summe:'") + cmFormatSum(pSum, pObj.PaymentCurrency));
			If TypeOf(pObj) = Type("DocumentObject.Preauthorisation") Then
				vRC = vPC.CancelAuthorisationByPaymentCard(vCardNumber, pSum * 100, vReferenceNumber);
			Else
				vRC = vPC.CancelPaymentByPaymentCard(vCardNumber, pSum * 100, vReferenceNumber);
			EndIf;
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
	vPC = Connect(pCashRegister, rMessage);
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
			// Success
			#IF CLIENT THEN
				DoMessageBox(NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));
			#ENDIF
			Try
				// Get slip
				vOutSlip = GetOperationSlipCheque(vPC, "en='Settlement'; de='Settlement'; ru='Итоги дня по картам'", Undefined);
				// Print settlement slip
				If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And 
				   Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter And  
				   Not IsBlankString(vOutSlip) Then
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

// -----------------------------------------------------------------------------
DefaultConnectionParameters = 
"<INPASConnectionParameters>
|	<SlipChequeCompanyRu></SlipChequeCompanyRu>
|	<SlipChequeCompanyEn></SlipChequeCompanyEn>
|	<SlipChequeBankRu></SlipChequeBankRu>
|	<SlipChequeBankEn></SlipChequeBankEn>
|	<SlipChequeCityRu></SlipChequeCityRu>
|	<SlipChequeCityEn></SlipChequeCityEn>
|	<SlipChequeAddressRu></SlipChequeAddressRu>
|	<SlipChequeAddressEn></SlipChequeAddressEn>
|	<SlipChequeFooterTextRu></SlipChequeFooterTextRu>
|	<SlipChequeFooterTextEn></SlipChequeFooterTextEn>
|	<AuthChannel>
|		<AuthServerIP>127.0.0.1</AuthServerIP>
|		<AuthServerPort>1025</AuthServerPort>
|		<X25Script></X25Script>
|		<TimeoutACK>5000</TimeoutACK>
|		<AuthTimeoutPacket>45000</AuthTimeoutPacket>
|		<CountNAK>3</CountNAK>
|		<PacketSize>1024</PacketSize>
|		<TransactionTimeout>90</TransactionTimeout>
|	</AuthChannel>
|	<CtrlChannel>
|		<CtrlServerIP>127.0.0.1</CtrlServerIP>
|		<CtrlServerPort>1026</CtrlServerPort>
|		<CtrlTimeoutPacket>60000</CtrlTimeoutPacket>
|		<COMPort>2</COMPort>
|		<BaudRate>115200</BaudRate>
|		<ByteSize>8</ByteSize>
|		<Parity>0</Parity>
|		<StopBits>0</StopBits>
|		<FlowCtrl>2</FlowCtrl>
|	</CtrlChannel>
|</INPASConnectionParameters>";
