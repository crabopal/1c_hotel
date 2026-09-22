
#Region Public

// -----------------------------------------------------------------------------
Function pmCheckConnection(rMessage, pSettingsObj = Undefined) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Driver was connected, so open it's properties window
		Try
			vPC.ShowProperties();
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			Disconnect(vPC);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Function pmPreauthorization(Val pSum, pObj, rMessage) Export
	rMessage = "";
	Return True; // Not supported by driver
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
		WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.CancelPreauthorization'; de = 'CreditCardProcessingSystem.CancelPreauthorization'; ru = 'СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), EventLogLevel.Error, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
		Return False;
	EndTry;
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
			// Check demo mode
			If vPC.IsDemo = 1 Then
				Raise NStr("en = 'Atol pay card system driver dongle was not found!'; de = 'Atol pay card system driver dongle was not found!'; ru = 'Не обнаружен ключ защиты драйвера платежных систем фирмы Атол!'");
			EndIf;
			// Set current logical device number
			vPC.CurrentDeviceNumber = CreditCardsProcessingSystemParameters.CurrentDeviceNumber;
			If Not ProcessResultCode(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Initialise pay card sysytem object attributes
			vPC.DataTracks = "";
			vPC.ReferenceNumber = "";
			vPC.CardNumber = "";
			vPC.CharLineLength = CreditCardsProcessingSystemParameters.SlipCharLineLength;
			If vPC.CharLineLength = 0 Then
				vPC.CharLineLength = 24;
			EndIf;
			vPC.TerminalNumber = GetTerminalId(pObj);
			If pSum > 0 Then
				// Payment
				vPC.Sum = pSum;
				vPC.OperationType = 0;
			ElsIf pSum < 0 Then
				// Return
				vPC.Sum = -pSum;
				vPC.OperationType = 1;
			Else
				Raise NStr("en = 'Zero sum authorization is not possible!'; de = 'Zero sum authorization is not possible!'; ru = 'Не указана сумма авторизации!'");
			EndIf;
			// Prepare for authorization
			vPC.PrepareOnLineAuthorization();
			If Not ProcessResultCode(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Do all neccessary operations
			If vPC.NeedReferenceNumber <> 0 And vPC.ReferenceNumber = "" Then
				If ValueIsFilled(pObj.Payment) Then
					vPC.ReferenceNumber = TrimR(pObj.Payment.ReferenceNumber);
				EndIf;
			EndIf;
			If vPC.NeedKeyboardEntryDataTracks <> 0 Then
				vFrm = GetForm("InputPayCardDataManually");
				vFrm.SelPayCardNumber = "";
				vFrm.SelCardExpDate = '00010101';
				vFrm.SelDescription = NStr("ru='Пожалуйста введите номер карты и срок её действия (ММ:ГГ)...'; 
				                           |de='Please input pay card number and expiration date (mm:yy)...'; 
										   |en='Please input pay card number and expiration date (mm:yy)...'");
				vCardDataStruct = vFrm.DoModal();
				If vCardDataStruct = Undefined Then
					rMessage = NStr("en = 'Operation is cancelled by user!'; de = 'Der Vorgang wurde vom Benutzer abgebrochen!'; ru = 'Операция отменена пользователем!'");
					Return False;
				Else
					vPC.CardNumber = vCardDataStruct.PayCardNumber;
					vPC.CardExpDate = vCardDataStruct.CardExpDate;
				EndIf;
			EndIf;
			If vPC.NeedReaderEntryDataTracks <> 0 Then
				vFrm = GetForm("InputPayCardDataByReader");
				vFrm.SelDataTracks = "";
				vFrm.SelDescription = NStr("ru='Пожалуйста прокатайте платежную карту...'; 
				                           |en='Slip pay card please...';
										   |de='Slip pay card please...'");
				vDataTracks = vFrm.DoModal();
				If vDataTracks = Undefined Then
					rMessage = NStr("en = 'Operation is cancelled by user!'; de = 'Der Vorgang wurde vom Benutzer abgebrochen!'; ru = 'Операция отменена пользователем!'");
					Return False;
				Else
					If CreditCardsProcessingSystemParameters.MultiTrackReader Then
						vPC.DataTracks = vDataTracks;
					Else
						vPC.DataTrack2 = RemoveSpecChars(vDataTracks);
					EndIf;
				EndIf;
			EndIf;
			// Authorize payment
			vRC = vPC.OnLineAuthorization();
			// Log all response codes
			LogOnLineAuthorization(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"));
			// Analize result code
			If vRC >= 0 Or (vRC <= -10000 And vRC > -11000) Then
				// If current operation type is return and auth code is blank then take auth code from payment
				vPCAuthCode = vPC.AuthCode;
				If pSum < 0 Then
					If IsBlankString(vPCAuthCode) Then
						If ValueIsFilled(pObj.Payment) Then
							vPCAuthCode = pObj.Payment.AuthorizationCode;
						EndIf;
					EndIf;
				EndIf;
				// Check authorization code
				If IsBlankString(vPCAuthCode) Or 
				   TrimAll(vPCAuthCode) = "0" Then
					// Authorization was not successfull
					rMessage = NStr("en = 'Operation was canceled by bank! Response code: '; de = 'Operation was canceled by bank! Response code: '; ru = 'Операция отклонена банком! Код ответа: '") + TrimAll(vPC.ResponseCode);
					tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
					WriteLogEvent(NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
					// Disconnect
					Disconnect(vPC);
					Return False;
				EndIf;
				// Save credit card data if neccessary
				If CreditCardsProcessingSystemParameters.SaveCreditCardsData Then
					vCreditCardRef = SaveCreditCardData(vPC, pObj);
					If ValueIsFilled(vCreditCardRef) Then
						pObj.CreditCard = vCreditCardRef;
						pObj.CardType = vCreditCardRef.CardType;
					EndIf;
				Else
					pObj.CardType = Catalogs.CreditCardTypes.FindByDescription(vPC.CardType, True);
				EndIf;
				// Save authorization code and reference number if there are no errors
				If vRC >= 0 Then
					pObj.AuthorizationCode = vPCAuthCode;
					pObj.ReferenceNumber = vPC.ReferenceNumber;
				EndIf;
				pObj.SlipText = vPC.TextStr;
				pObj.Write(DocumentWriteMode.Write);
				// Print authorization slip
				If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter Then
					vSlipTxtArr = New Array();
					For i = 0 To (vPC.TextCount - 1) Do
						vPC.TextIndex = i;
						vSlipTxtArr.Add(vPC.Text);
					EndDo;
					PrintSlipDocument(vSlipTxtArr, pObj);
				EndIf;
			EndIf;
			If Not ProcessResultCode(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en = 'CreditCardProcessingSystem.AuthorizePayment'; de = 'CreditCardProcessingSystem.AuthorizePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
Function pmAnnulatePayment(Val pSum, Val pVATSum, pObj, rMessage) Export
	// Try to connect
	vPC = Connect(rMessage);
	If vPC = Undefined Then
		Return False;
	Else
		// Pay card system object was created successfully
		Try
			// Check demo mode
			If vPC.IsDemo = 1 Then
				Raise NStr("en = 'Atol pay card system driver dongle was not found!'; de = 'Atol pay card system driver dongle was not found!'; ru = 'Не обнаружен ключ защиты драйвера платежных систем фирмы Атол!'");
			EndIf;
			// Set current logical device number
			vPC.CurrentDeviceNumber = CreditCardsProcessingSystemParameters.CurrentDeviceNumber;
			If Not ProcessResultCode(vPC, NStr("en = 'CreditCardProcessingSystem.AnnulatePayment'; de = 'CreditCardProcessingSystem.AnnulatePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Initialise pay card sysytem object attributes
			vPC.DataTracks = "";
			vPC.ReferenceNumber = "";
			vPC.CardNumber = "";
			vPC.CharLineLength = CreditCardsProcessingSystemParameters.SlipCharLineLength;
			If vPC.CharLineLength = 0 Then
				vPC.CharLineLength = 24;
			EndIf;
			vPC.TerminalNumber = GetTerminalId(pObj);
			If pSum > 0 Then
				// Payment annulation
				vPC.Sum = pSum;
				vPC.OperationType = 2;
			ElsIf pSum < 0 Then
				// Return annulation
				vPC.Sum = -pSum;
				vPC.OperationType = 3;
			Else
				Raise NStr("en = 'Zero sum annulation is not possible!'; de = 'Zero sum annulation is not possible!'; ru = 'Не указана сумма аннуляции!'");
			EndIf;
			// Prepare for authorization
			vPC.PrepareOnLineAuthorization();
			If Not ProcessResultCode(vPC, NStr("en = 'CreditCardProcessingSystem.AnnulatePayment'; de = 'CreditCardProcessingSystem.AnnulatePayment'; ru = 'СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Do all neccessary operations
			If vPC.NeedReferenceNumber <> 0 And vPC.ReferenceNumber = "" Then
				If ValueIsFilled(pObj.Payment) Then
					vPC.ReferenceNumber = TrimR(pObj.Payment.ReferenceNumber);
				Else
					vPC.ReferenceNumber = TrimR(pObj.ReferenceNumber);
				EndIf;
			EndIf;
			If vPC.NeedKeyboardEntryDataTracks <> 0 Then
				vFrm = GetForm("InputPayCardDataManually");
				vFrm.SelPayCardNumber = "";
				vFrm.SelCardExpDate = '00010101';
				vFrm.SelDescription = NStr("ru='Пожалуйста введите номер карты и срок её действия (ММ:ГГ)...'; 
				                           |en='Please input pay card number and expiration date (mm:yy)...';
										   |de='Please input pay card number and expiration date (mm:yy)...'");
				vCardDataStruct = vFrm.DoModal();
				If vCardDataStruct = Undefined Then
					rMessage = NStr("en = 'Operation is cancelled by user!'; de = 'Operation is cancelled by user!'; ru = 'Операция отменена пользователем!'");
					Return False;
				Else
					vPC.CardNumber = vCardDataStruct.PayCardNumber;
					vPC.CardExpDate = vCardDataStruct.CardExpDate;
				EndIf;
			EndIf;
			If vPC.NeedReaderEntryDataTracks <> 0 Then
				vFrm = GetForm("InputPayCardDataByReader");
				vFrm.SelDataTracks = "";
				vFrm.SelDescription = NStr("ru='Пожалуйста прокатайте платежную карту...'; 
				                           |en='Slip pay card please...';
										   |de='Slip pay card please...'");
				vDataTracks = vFrm.DoModal();
				If vDataTracks = Undefined Then
					rMessage = NStr("en = 'Operation is cancelled by user!'; de = 'Operation is cancelled by user!'; ru = 'Операция отменена пользователем!'");
					Return False;
				Else
					vPC.DataTracks = vDataTracks;
				EndIf;
			EndIf;
			// Authorize payment
			vRC = vPC.OnLineAuthorization();
			// Log all response codes
			LogOnLineAuthorization(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"));
			// Analize result code
			If vRC >= 0 Or (vRC <= -10000 And vRC > -11000) Then
				// Check authorization code
				If IsBlankString(vPC.AuthCode) Or 
				   TrimAll(vPC.AuthCode) = "0" Then
					// Authorization was not successfull
					rMessage = NStr("ru='Операция отклонена банком! Код ответа: '; en='Operation was canceled by bank! Response code: '; de='Operation was canceled by bank! Response code: '") + TrimAll(vPC.ResponseCode);
					tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
					WriteLogEvent(NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, rMessage);
					// Disconnect
					Disconnect(vPC);
					Return False;
				EndIf;
				// Save main authorization attributes to the payment document
				pObj.AnnulationSlipText = "Auth. #" + TrimR(vPC.AuthCode) + Chars.LF;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + "Ref. #" + TrimR(vPC.ReferenceNumber) + Chars.LF;
				pObj.AnnulationSlipText = pObj.AnnulationSlipText + Chars.LF + vPC.TextStr;
				pObj.Write(DocumentWriteMode.Write);
				// Print annulation slip
				If Not CreditCardsProcessingSystemParameters.PrintSlipInCheque And Not CreditCardsProcessingSystemParameters.PrintSlipUsingTerminalPrinter Then
					vSlipTxtArr = New Array();
					For i = 0 To (vPC.TextCount - 1) Do
						vPC.TextIndex = i;
						vSlipTxtArr.Add(vPC.Text);
					EndDo;
					PrintSlipDocument(vSlipTxtArr, pObj);
				EndIf;
			EndIf;
			If Not ProcessResultCode(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage) Then
				Return False;
			EndIf;
			// Disconnect
			Disconnect(vPC);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vPC, NStr("en='CreditCardProcessingSystem.AnnulatePayment'; de='CreditCardProcessingSystem.AnnulatePayment'; ru='СистемаПроцессингаКредитныхКарт.АннулированиеПлатежа'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulatePayment

// -----------------------------------------------------------------------------
Function pmOpenServiceFunctionsMenu(rMessage) Export
	rMessage = NStr("en='Not supported function!'; de='Not supported function!'; ru='Не поддерживается драйвером!'");
	Return False;
EndFunction // pmOpenServiceFunctionsMenu

#EndRegion            

#Region Private

// -----------------------------------------------------------------------------
Function GetDateFromString(pStr)
	Return Date(Number(Mid(pStr, 7, 4)), Number(Mid(pStr, 4, 2)), Number(Mid(pStr, 1, 2)));
EndFunction // GetDateFromString

// -----------------------------------------------------------------------------
Function GetTerminalId(pObj)
	If ValueIsFilled(pObj.CashRegister) And Not IsBlankString(pObj.CashRegister.TerminalNumber) And TrimAll(pObj.CashRegister.TerminalNumber) <> "0" Then
		Return Number(StrReplace(TrimAll(pObj.CashRegister.TerminalNumber), " ", ""));
	Else
		Return Number(StrReplace(TrimAll(CreditCardsProcessingSystemParameters.TerminalNumber), " ", ""));
	EndIf;
EndFunction // GetTerminalId

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		#IF CLIENT THEN
			Try
				AttachAddIn("ADDIn.PayCard");
				vPC = New("ADDIn.PayCard");
			Except
				LoadAddIn("PayCARD.dll");
				vPC = New("ADDIn.PayCard");
			EndTry;
		#ELSE
			vPC = New("ADDIn.PayCard");
		#ENDIF
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
Function ProcessResultCode(pPC, pFunction, rMessage)
	vRC = pPC.ResultCode;
	If vRC < 0 And vRC <> -5 Then
		rMessage = TrimAll(pPC.ResultDescription) + Chars.LF + TrimAll(pPC.ResultPrompt);
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Result code: " + vRC + ", result description: " + rMessage);
		Disconnect(pPC);
		Return False;
	ElsIf vRC = -5 Then
		rMessage = NStr("ru='Операция отменена пользователем!'; en='Operation was canceled by user!'; de='Der Vorgang wurde vom Benutzer abgebrochen!'");
		tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Result code: " + vRC + ", result description: " + rMessage);
		Disconnect(pPC);
		Return False;
	Else
		Return True;
	Endif;
EndFunction // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pPC, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, "Error description: " + rMessage);
	Disconnect(pPC);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function SaveCreditCardData(pPC, pObj)
	vCardRef = Undefined;
	vCardNumber = TrimAll(pPC.CardNumber);
	vCardRef = Catalogs.CreditCards.FindByAttribute("CardNumber", vCardNumber);
	If ValueIsFilled(vCardRef) And vCardRef.DeletionMark Then
		vCardRef = Undefined;
	EndIf;
	If Not ValueIsFilled(vCardRef) Then
		vCardObj = Catalogs.CreditCards.CreateItem();
		vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
		vCardObj.CardOwner = pObj.Payer;
		vCardObj.CardType = Catalogs.CreditCardTypes.FindByDescription(pPC.CardType, True);
		vCardObj.CardNumber = vCardNumber;
		vCardObj.CardHolder = TrimAll(pPC.CardHolderName);
		vCardObj.CardValidTillDate = GetDateFromString(pPC.CardExpDate);
		vCardObj.Author = SessionParameters.CurrentUser;
		vCardObj.CreateDate = CurrentSessionDate();
		vCardObj.Write();
		vCardRef = vCardObj.Ref;
	Else
		vCardType = Catalogs.CreditCardTypes.FindByDescription(pPC.CardType, True);
		If ValueIsFilled(vCardType) And Not ValueIsFilled(vCardRef.CardType) Then
			vCardObj = vCardRef.GetObject();
			vCardObj.CardType = vCardType;
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
		rMessage = NStr("en = 'Cash register is not specified!'; de = 'Kassen nicht angegeben!'; ru = 'Не выбран ККМ для печати!'");
	EndIf;
EndProcedure // PrintSlipDocument

// -----------------------------------------------------------------------------
Function RemoveSpecChars(Val pDataTrack)
	If IsBlankString(pDataTrack) Then
		Return "";
	EndIf;
	vDataTrack = TrimAll(pDataTrack);
	vLeftChar = Left(vDataTrack, 1);
	If Find(vLeftChar, "0123456789") = 0 Then
		Return Mid(vDataTrack, 2);
	Else
		Return vDataTrack;
	EndIf;
EndFunction // RemoveSpecChars

// -----------------------------------------------------------------------------
Procedure LogOnLineAuthorization(pPC, pFunction)
	vMessage = NStr("ru='Выполнена on-line авторизация! Параметры: '; en='On-line authorization processed with parameters: '; de='On-line authorization processed with parameters: '");
	vMessage = vMessage + "Result code: " + TrimAll(pPC.ResultCode) + " (" + TrimAll(pPC.ResultDescription) + "); ";
	vMessage = vMessage + "Authorization code: " + TrimAll(pPC.AuthCode) + "; ";
	vMessage = vMessage + "Transaction type: " + pPC.TransType + "; ";
	vMessage = vMessage + "Operation type: " + pPC.OperationType + "; ";
	vMessage = vMessage + "Sum: " + pPC.Sum + "; ";
	vMessage = vMessage + "Card number: " + TrimAll(pPC.CardNumber) + "; ";
	vMessage = vMessage + "Card exp. date: " + Format(pPC.CardExpDate, "DF=MM.yy") + "; ";
	vMessage = vMessage + "Slip number: " + pPC.SlipNumber + "; ";
	vMessage = vMessage + "Transaction date: " + Format(pPC.TransDate, "DF=dd.MM.yyyy") + "; ";
	vMessage = vMessage + "Transaction time: " + Format(pPC.TransTime, "DF=HH:mm:ss") + "; ";
	vMessage = vMessage + "Message number: " + pPC.MsgNumber + "; ";
	vMessage = vMessage + "Terminal ID: " + TrimAll(pPC.TerminalID) + "; ";
	vMessage = vMessage + "Reference number: " + TrimAll(pPC.ReferenceNumber) + "; ";
	vMessage = vMessage + "Response code: " + TrimAll(pPC.ResponseCode) + ";";
	WriteLogEvent(pFunction, EventLogLevel.Information, CreditCardsProcessingSystemParameters.Metadata(), CreditCardsProcessingSystemParameters, vMessage);
EndProcedure // LogOnLineAuthorization

#EndRegion
