
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pVATSum			 - Number	 - Vat sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmAuthorizePayment(Val pSum, Val pVATSum, pObj, rMessage, pPaymentTerminal) Export
	vCardOperationWasDone = False;
	Try
		vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pPaymentTerminal.Ref);
		If vHardwareData = Undefined Then
			Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
		EndIf;
		
		vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		
		vCommand = "";
		vFunctionName = "";
		vDataOperations = POSTerminalOperationExecutionParameters();
		
		vMerchantID = 0;
		If Not IsBlankString(pPaymentTerminal.MerchantID) And tcOnServer.IsNumber(pPaymentTerminal.MerchantID) Then
			vMerchantID = Number(pPaymentTerminal.MerchantID);
		EndIf;
		vDataOperations.MerchantNumber = vMerchantID;
		
		If TypeOf(pObj.Ref) = Type("DocumentRef.Payment") And ValueIsFilled(pObj.Preauthorisation) Then
			vFunctionName = NStr("en='CreditCardProcessingSystem.AuthorisationConfirmation'; de='CreditCardProcessingSystem.AuthorisationConfirmation'; ru='СистемаПроцессингаКредитныхКарт.РасчетПоПреавторизации'");
			
			vCommand = "AuthorizeCompletion";
			vDataOperations.Amount = pSum;
			vDataOperations.RRNCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReferenceNumber"));
			vDataOperations.AuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "AuthorizationCode"));
			vDataOperations.ReceiptNumber = TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "ReceiptNumber"));
			
			vCreditCard = tcOnServer.cmGetAttributeByRef(pObj.Preauthorisation, "CreditCard");
			FillCardDataByCard(vDataOperations, vCreditCard);
		Else
			If pSum > 0 Then
				vFunctionName = NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'");
				
				vCommand = "AuthorizeSales";
				vDataOperations.Amount = pSum;
				FillCardDataByCard(vDataOperations, pObj.CreditCard);
			Else
				vFunctionName = NStr("en='CreditCardProcessingSystem.ReturnPayment'; de='CreditCardProcessingSystem.ReturnPayment'; ru='СистемаПроцессингаКредитныхКарт.ВозвратПлатежа'");
				
				vPayment = GetPaymentByDocument(pObj);
				If Not ValueIsFilled(vPayment) Then
					Raise NStr("en='Return should be based on previous payment!'; de='Return should be based on previous payment!'; ru='Возврат должен быть на основании предыдущего платежа!'");
				EndIf;
				
				vCommand = "AuthorizeVoid";
				vDataOperations.Amount = -pSum;
				
				vSumOriginalTransaction = tcOnServer.cmGetAttributeByRef(vPayment, "Sum");
				If vDataOperations.Amount < vSumOriginalTransaction Then
					vDataOperations.AmountOriginalTransaction = vSumOriginalTransaction;
				EndIf;
				
				vDataOperations.RRNCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "ReferenceNumber"));
				vDataOperations.AuthorizationCode = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationCode"));
				vDataOperations.ReceiptNumber = TrimAll(tcOnServer.cmGetAttributeByRef(vPayment, "ReceiptNumber"));
				
				vAuthorizationType = tcOnServer.cmGetAttributeByRef(vPayment, "AuthorizationType");
				If vAuthorizationType <> PredefinedValue("Enum.AuthorizationTypes.Сard") Then
					vCommand = "AuthorizeRefund";
				EndIf;
				
				vCreditCard = tcOnServer.cmGetAttributeByRef(vPayment, "CreditCard");
				FillCardDataByCard(vDataOperations, vCreditCard);
			EndIf;
		EndIf;
		
		vDataOperations = PrepareOperationData(vHardwareData, vCommand, vDataOperations);
		If Not vDataOperations.Result Then
			Raise vDataOperations.ErrorDescription;
		EndIf;
		
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Request parameters:'; de = 'Anforderungsparameter:'; ru = 'Параметры запроса:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vDataOperations));
		
		vResultOperation = ExecutingCommand(vHardwareData, vCommand, vDataOperations);
		If Not vResultOperation.Result Then
			If vCommand = "AuthorizeVoid" Then
				tcOnServer.Wait(5);
				vCommand = "AuthorizeRefund";
				vResultOperation = ExecutingCommand(vHardwareData, vCommand, vDataOperations);
				If Not vResultOperation.Result Then
					Raise vResultOperation.ErrorDescription;
				EndIf;
			Else
				Raise vResultOperation.ErrorDescription;
			EndIf;
		EndIf;
		vCardOperationWasDone = True;
		
		ProcessOperationData(vCommand, vResultOperation);
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Antwortparameter:'; de = 'Antwortparameter:'; ru = 'Параметры ответа:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vResultOperation));
		
		If pPaymentTerminal.SaveCreditCardsData And vResultOperation.CardNumber <> Undefined And Not IsBlankString(vResultOperation.CardNumber) Then
			vExtraParams = New Structure("CardDataEnc, CardType", vResultOperation.CardNumberHash, Undefined);
			vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardDataByCardNumber(vResultOperation.CardNumber, pObj, vExtraParams);
			If ValueIsFilled(vCreditCardRef) Then
				pObj.CreditCard = vCreditCardRef;
			EndIf;
		EndIf;
		
		vOutSlip = vResultOperation.Slip;
		vMerchantID = Format(vMerchantID, "NFD=0; NG=");
		vReferenceNumber = ?(vResultOperation.RRNCode = Undefined Or IsBlankString(vResultOperation.RRNCode), vDataOperations.RRNCode, vResultOperation.RRNCode);
		vAuthorizationCode = ?(vResultOperation.AuthorizationCode = Undefined Or IsBlankString(vResultOperation.AuthorizationCode), vDataOperations.AuthorizationCode, vResultOperation.AuthorizationCode);
		vTerminalNumber = ?(vResultOperation.TerminalID = Undefined Or IsBlankString(vResultOperation.TerminalID), vHardwareData.DeviceID, vResultOperation.TerminalID);
		
		pObj.ReferenceNumber = vReferenceNumber;
		pObj.AuthorizationCode = vAuthorizationCode;
		pObj.ReceiptNumber = vResultOperation.ReceiptNumber;
		pObj.TerminalNumber = vTerminalNumber;
		pObj.MerchantID = vMerchantID;
		pObj.AuthorizationType = vResultOperation.AuthorizationType;
		pObj.SlipText = vOutSlip;
		
		If Not vHardwareData.PrintSlipOnTerminal And Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
		EndIf;
		
		tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData);
		Return True;
	Except
		If vCardOperationWasDone Then
			ExecutingCommand(vHardwareData, "EmergencyVoid", Undefined);
		EndIf;
		rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ProcessException(vHardwareData, NStr("en='CreditCardProcessingSystem.AuthorizePayment'; de='CreditCardProcessingSystem.AuthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.АвторизацияПлатежа'"), rMessage);
		Return False;
	EndTry;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vCardOperationWasDone = False;
	Try
		vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pPaymentTerminal.Ref);
		If vHardwareData = Undefined Then
			Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
		EndIf;
		
		vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		
		vMerchantID = 0;
		If Not IsBlankString(pPaymentTerminal.MerchantID) And tcOnServer.IsNumber(pPaymentTerminal.MerchantID) Then
			vMerchantID = Number(pPaymentTerminal.MerchantID);
		EndIf;
		
		vCommand = "AuthorizePreSales";
		vDataOperations = POSTerminalOperationExecutionParameters();
		vDataOperations.MerchantNumber = vMerchantID;
		vDataOperations.Amount = pSum;
		vDataOperations.ReceiptNumber = pObj.ReceiptNumber;
		vDataOperations.RRNCode = pObj.ReferenceNumber;
		vDataOperations.AuthorizationCode = pObj.AuthorizationCode;
		
		FillCardDataByCard(vDataOperations, pObj.CreditCard);
		
		vDataOperations = PrepareOperationData(vHardwareData, vCommand, vDataOperations);
		If Not vDataOperations.Result Then
			Raise vDataOperations.ErrorDescription;
		EndIf;
		
		vFunctionName = NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'");
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Request parameters:'; de = 'Anforderungsparameter:'; ru = 'Параметры запроса:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vDataOperations));
		
		vResultOperation = ExecutingCommand(vHardwareData, vCommand, vDataOperations);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		vCardOperationWasDone = True;
		
		ProcessOperationData(vCommand, vResultOperation);
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Antwortparameter:'; de = 'Antwortparameter:'; ru = 'Параметры ответа:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vResultOperation));
		
		If pPaymentTerminal.SaveCreditCardsData And vResultOperation.CardNumber <> Undefined And Not IsBlankString(vResultOperation.CardNumber) Then
			vExtraParams = New Structure("CardDataEnc, CardType", vResultOperation.CardNumberHash, Undefined);
			vCreditCardRef = tcCreditCardsProcessingSystemDriverAtServer.SaveCreditCardDataByCardNumber(vResultOperation.CardNumber, pObj, vExtraParams);
			If ValueIsFilled(vCreditCardRef) Then
				pObj.CreditCard = vCreditCardRef;
			EndIf;
		EndIf;
		
		vOutSlip = vResultOperation.Slip;
		vMerchantID = Format(vMerchantID, "NFD=0; NG=");
		vTerminalNumber = ?(vResultOperation.TerminalID = Undefined Or IsBlankString(vResultOperation.TerminalID), vHardwareData.DeviceID, vResultOperation.TerminalID);
		
		pObj.ReferenceNumber = vResultOperation.RRNCode;
		pObj.AuthorizationCode = vResultOperation.AuthorizationCode;
		pObj.ReceiptNumber = vResultOperation.ReceiptNumber;
		pObj.TerminalNumber = vTerminalNumber;
		pObj.MerchantID = vMerchantID;
		pObj.SlipText = vOutSlip;
		
		If Not vHardwareData.PrintSlipOnTerminal And Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
		EndIf;
		
		tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData);
		Return True;
	Except
		If vCardOperationWasDone Then
			ExecutingCommand(vHardwareData, "EmergencyVoid", Undefined);
		EndIf;
		rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ProcessException(vHardwareData, NStr("en='CreditCardProcessingSystem.PreauthorizePayment'; de='CreditCardProcessingSystem.PreauthorizePayment'; ru='СистемаПроцессингаКредитныхКарт.ПреавторизацияПлатежа'"), rMessage);
		Return False;
	EndTry;
EndFunction // pmAuthorizePayment

// -----------------------------------------------------------------------------
//
// Parameters:
//  pSum			 - Number	 - Sum
//  pObj			 - DocumentObject	 - Document object
//  rMessage		 - String			 - Error message
//  pPaymentTerminal - Structure		 - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmCancelPreauthorization(Val pSum, pObj, rMessage, pPaymentTerminal) Export
	vCardOperationWasDone = False;
	Try
		vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pPaymentTerminal.Ref);
		If vHardwareData = Undefined Then
			Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
		EndIf;
		
		vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		
		vMerchantID = 0;
		If Not IsBlankString(pPaymentTerminal.MerchantID) And tcOnServer.IsNumber(pPaymentTerminal.MerchantID) Then
			vMerchantID = Number(pPaymentTerminal.MerchantID);
		EndIf;
		
		vCommand = "AuthorizeVoidPreSales";
		vDataOperations = POSTerminalOperationExecutionParameters();
		vDataOperations.MerchantNumber = vMerchantID;
		vDataOperations.Amount = pObj.Sum;
		vDataOperations.ReceiptNumber = pObj.ReceiptNumber;
		vDataOperations.RRNCode = pObj.ReferenceNumber;
		vDataOperations.AuthorizationCode = pObj.AuthorizationCode;
		
		FillCardDataByCard(vDataOperations, pObj.CreditCard);
		
		vDataOperations = PrepareOperationData(vHardwareData, vCommand, vDataOperations);
		If Not vDataOperations.Result Then
			Raise vDataOperations.ErrorDescription;
		EndIf;
		
		vFunctionName = NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'");
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Request parameters:'; de = 'Anforderungsparameter:'; ru = 'Параметры запроса:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vDataOperations));
		
		vResultOperation = ExecutingCommand(vHardwareData, vCommand, vDataOperations);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		vCardOperationWasDone = True;
		
		ProcessOperationData(vCommand, vResultOperation);
		tcOnServer.cmWriteLogEventAtServer(vFunctionName, , , , NStr("en = 'Antwortparameter:'; de = 'Antwortparameter:'; ru = 'Параметры ответа:'") + Chars.LF + tcConnectedHardwareOnClientServer.MapToJson(vResultOperation));
		
		vOutSlip = vResultOperation.Slip;
		vReferenceNumber = ?(vResultOperation.RRNCode = Undefined Or IsBlankString(vResultOperation.RRNCode), vDataOperations.RRNCode, vResultOperation.RRNCode);
		
		pObj.CancellationSlipText = pObj.CancellationSlipText + "Ref. #" + vReferenceNumber;
		pObj.CancellationSlipText = pObj.CancellationSlipText + Chars.LF + vOutSlip;
		pObj.Status = PredefinedValue("Enum.PreauthorisationStatuses.Cancelled");
		pObj.AuthorOfCancellation = tcOnServer.cmGetCurrentUserAttribute();
		pObj.DateOfCancellation = CurrentDate();
		
		If Not vHardwareData.PrintSlipOnTerminal And Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pObj.CashRegister);
		EndIf;
		
		tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData);
		Return True;
	Except
		If vCardOperationWasDone Then
			ExecutingCommand(vHardwareData, "EmergencyVoid", Undefined);
		EndIf;
		rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ProcessException(vHardwareData, NStr("en='CreditCardProcessingSystem.CancelPreauthorization'; de='CreditCardProcessingSystem.CancelPreauthorization'; ru='СистемаПроцессингаКредитныхКарт.ОтменаПреавторизации'"), rMessage);
		Return False;
	EndTry;
EndFunction // pmCancelPreauthorization

// -----------------------------------------------------------------------------
//
// Parameters:
//  rMessage		 - String	 - Errors
//  pCashRegister	 - Structure - Params cash register
//  pPaymentTerminal - Structure - Params payment terminal
// 
// Returns:
//  Boolean - Result operation
//
Function pmOpenServiceFunctionsMenu(rMessage, pCashRegister, pPaymentTerminal) Export
	vUCList = New ValueList;
	vUCList.Add("Settlement", NStr("en='Z-Report (reconcile totals)'; ru='Z-Отчет (сверка итогов)'; de='Z-Bericht (Summen abgleichen)'"));
	vUCList.ShowChooseItem(New NotifyDescription("AfterServiceFunctionsMenuSelection", tcCreditCardsProcessingSystemDriverNativeDriver1C, New Structure("CashRegister, PaymentTerminal", pCashRegister, pPaymentTerminal)));
	Return True;
EndFunction // OpenServiceFunctionsMenu

// -----------------------------------------------------------------------------
//
// Parameters:
//  vUCItem		 - ValueList - Selected values
//  vExtraParams - Strucrure - Params 
//
Procedure AfterServiceFunctionsMenuSelection(pUCItem, pExtraParams) Export
	If pUCItem = Undefined Then
		Return;
	EndIf;
	
	vCashRegister = pExtraParams.CashRegister;
	vPaymentTerminal = pExtraParams.PaymentTerminal;
	
	If pUCItem.Value = "Settlement" Then
		ReconcileTotals(Undefined, vCashRegister, vPaymentTerminal);
	ElsIf pUCItem.Value = "OperationByCards" Then
		PrintXReport(Undefined, vCashRegister, vPaymentTerminal);
	EndIf;
EndProcedure // AfterServiceFunctionsMenuSelection

// ----------------------------------------------------------------------------- 
//
// Parameters:
//  pPaymentTerminal - Structure - Params payment terminal 
//
Procedure pmCheckConnection(pPaymentTerminal) Export
	Return;
EndProcedure // pmCheckConnection

// -----------------------------------------------------------------------------   
//
// Parameters:
//  pPC			 	 - ComObject, Undefined - Driver
//  pCashRegister	 - Structure - Params Cash register 
//  pPaymentTerminal - Structure - Params payment terminal 
//  pResult			 - Boolean - Result operation
//
Procedure ReconcileTotals(pPC = Undefined, pCashRegister, pPaymentTerminal, pResult = True) Export
	vMessage = "";
	Try
		vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pPaymentTerminal.Ref);
		If vHardwareData = Undefined Then
			Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
		EndIf;
		
		vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		
		vResultOperation = ExecutingCommand(vHardwareData, "Settlement", Undefined);
		If Not vResultOperation.Result Then
			Raise vResultOperation.ErrorDescription;
		EndIf;
		
		vOutSlip = vResultOperation.Slip;
		If Not vHardwareData.PrintSlipOnTerminal And Not IsBlankString(vOutSlip) Then
			vSlipTxtArr = GetTextLinesArray(vOutSlip);
			PrintSlipDocument(vSlipTxtArr, pCashRegister);
		EndIf;
		
		tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData);
		ShowMessageBox(, NStr("en='Totals check (settlement) operation completed successfully!'; de='Totals check (settlement) operation completed successfully!'; ru='Операция сверки итогов выполнена успешно!'"));
	Except
		vMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ProcessException(vHardwareData, NStr("en='CreditCardProcessingSystem.Settlement'; de='CreditCardProcessingSystem.Settlement'; ru='СистемаПроцессингаКредитныхКарт.СверкаИтоговПоКартам'"), vMessage);
		ShowMessageBox(, vMessage);
		pResult = False;
	EndTry;
EndProcedure // ReconcileTotals

// -----------------------------------------------------------------------------
//
// Parameters:
//  pPC			 	 	- ComObject - Driver
//  pCashRegisterArr	- Structure - Params Cash register 
//  pPaymentTerminalArr - Structure - Params payment terminal 
//
Procedure PrintXReport(pPC = Undefined, pCashRegister, pPaymentTerminal) Export
	Return;
EndProcedure // PrintXReport

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetPaymentByDocument(pObj)
	vPayment = Undefined;
	If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
		vPayment = pObj.Payment;
		If ValueIsFilled(vPayment) Then
			Return vPayment;
		EndIf;
		
		While TypeOf(vPayment) = Type("DocumentRef.DepositTransfer") Do
			vPayment = tcOnServer.cmGetAttributeByRef(vPayment, "Payment");
			If Not ValueIsFilled(vPayment) Then
				Break;
			EndIf;
		EndDo;
	ElsIf TypeOf(pObj.Ref) = Type("DocumentRef.CustomerPayment") Then
		vPayment = pObj.CustomerPayment;
	Else
		vPayment = Undefined;
	EndIf;
	Return vPayment;
EndFunction // GetPaymentByDocument

// --------------------------------------------------------------------------------
Procedure FillCardDataByCard(pDataOperations, pCreditCard)
	If Not ValueIsFilled(pCreditCard) Then
		Return;
	EndIf;
	
	vCardNumber = "";
	vCardNumberHash = "";
	
	vArrCreditCard = tcOnServer.cmGetAtributeAsArray(pCreditCard);
	If Not IsBlankString(vArrCreditCard.CardNumber) Then 
		vCardNumber = TrimAll(vArrCreditCard.CardNumber);
	EndIf;
	If Not IsBlankString(vArrCreditCard.CardDataEnc) Then
		vCardNumberHash = TrimAll(vArrCreditCard.CardDataEnc);
	EndIf;
	
	pDataOperations.CardNumber = vCardNumber;
	pDataOperations.CardNumberHash = vCardNumberHash;
EndProcedure // FillCardDataByCard

// -----------------------------------------------------------------------------
Function GetTextLinesArray(pTextStr)
	vTxtArr = New Array;
	If IsBlankString(pTextStr) Then
		Return vTxtArr;
	EndIf;
	
	vTxt = New TextDocument();
	vTxt.SetText(pTextStr);
	For i = 1 To vTxt.LineCount() Do
		vStr = vTxt.GetLine(i);
		If StrFind(vStr, "cut") > 0 Or StrFind(vStr, "отрезка") Then
			Break;
		EndIf;
		vTxtArr.Add(vStr);
	EndDo;
	Return vTxtArr;
EndFunction // GetTextLinesArray

// -----------------------------------------------------------------------------
Procedure PrintSlipDocument(pSlipTextArr, pCashRegister, pOneCopyOnly = False)
	rMessage = "";
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	If vDriver = Undefined Then
		ShowMessageBox(,Nstr("en = 'Work with driver this device is not supported'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'; ru = 'Работа с драйвером этого устройства не поддерживается'"), , NStr("en = 'ERROR'; de = 'ERROR'; ru = 'ОШИБКА'"));
		Return;
	EndIf;
	
	vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(,pCashRegister);
	
	If Not IsBlankString(vPasswordKKM) Then
		vDriver.pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, vPasswordKKM, pOneCopyOnly);
		Return;
	EndIf;
	
	vQuestion = NStr("en = 'Input cash register password please...'; de = 'Input cash register password please...'; ru = 'Пожалуйста введите пароль ККМ...'");
	vNotifyDescription = New NotifyDescription("AfterInputCashRegisterPassword", tcCreditCardsProcessingSystemDriverNativeDriver1C, New Structure("Driver, Message, CashRegister, SlipTextArr, OneCopyOnly", vDriver, rMessage, pCashRegister, pSlipTextArr, pOneCopyOnly));
	OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription",vQuestion), , , , , vNotifyDescription);
EndProcedure // PrintSlipDocument

// --------------------------------------------------------------------------------
Procedure AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	
	vDriver = pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.Message;
	vCashRegister = pAdditionalParameters.CashRegister;
	vSlipTextArr = pAdditionalParameters.SlipTextArr;
	vOneCopyOnly = pAdditionalParameters.OneCopyOnly;
	
	vDriver.pmPrintSlip(vSlipTextArr, vCashRegister, vMessage, pValue.Password, vOneCopyOnly);
	If Not IsBlankString(vMessage) Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
	EndIf;
EndProcedure // AfterInputCashRegisterPassword()

// -----------------------------------------------------------------------------
Procedure ProcessException(pHardwareData, pFunction, rMessage)
	tcOnServer.cmWriteLogEventAtServer(pFunction, "Error", , , "Error description: " + rMessage);
	tcConnectedHardwareOnClientServer.DisconnectHardware(pHardwareData);
EndProcedure // ProcessException

// --------------------------------------------------------------------------------
Function PrepareOperationData(pHardwareData, pCommand, pDataOperations)
	pDataOperations.Insert("Result", True);
	pDataOperations.Insert("ErrorDescription");
	
	If Not pDataOperations.Amount > 0 Then
		pDataOperations.ErrorDescription =  NStr("en = 'Incorrect transaction amount.'; de = 'Falscher Transaktionsbetrag.'; ru = 'Не корректная сумма операции.'");
		pDataOperations.Result = False;
		Return pDataOperations;
	EndIf;
	
	If Not IsBlankString(pDataOperations.ConsumerPresentedQR) And Not pHardwareData.ConsumerPresentedQR Then
		pDataOperations.ErrorDescription = NStr("en = 'Consumer-Presented QR is not supported by the driver.'; de = 'Consumer-Presented QR wird vom Treiber nicht unterstützt.'; ru = 'Consumer-Presented QR не поддерживается драйвером.'");
		pDataOperations.Result = False;
		Return pDataOperations;
	EndIf;
	
	If pCommand = "AuthorizeSales" Or pCommand = "AuthorizeRefund" Or pCommand = "AuthorizeVoid"
		Or pCommand = "AuthorizePreSales" Or pCommand = "AuthorizeCompletion" Or pCommand = "AuthorizeVoidPreSales" Then
		pDataOperations.Insert("InParametersXML", tcConnectedHardwareOnClientServer.GetPOSTerminalXMLParameters(pDataOperations));
	EndIf;
	
	Return pDataOperations;
EndFunction // PrepareOperationData

// --------------------------------------------------------------------------------
Procedure ProcessOperationData(pCommand, pResultOperation)
	If pCommand = "GetOperationByCards" Then
		If pResultOperation.Property("ResultOperationXML") Then
			vOperations = tcConnectedHardwareOnClientServer.OperationByCards(pResultOperation.ResultOperationXML);
			pResultOperation.Insert("Operations", vOperations);
		EndIf;
		Return;
	EndIf;
	
	If pResultOperation.Property("OutParametersXML") And Not IsBlankString(pResultOperation.OutParametersXML) Then
		vOperationParameters = tcConnectedHardwareOnClientServer.ReadRootElementXML(pResultOperation.OutParametersXML);
		If vOperationParameters.Property("AuthorizationCode") Then
			pResultOperation.AuthorizationCode = vOperationParameters.AuthorizationCode;
		EndIf;
		If vOperationParameters.Property("CardNumber") Then
			pResultOperation.CardNumber = vOperationParameters.CardNumber;
		EndIf;
		If vOperationParameters.Property("CardNumberHash") Then
			pResultOperation.CardNumberHash = vOperationParameters.CardNumberHash;
		EndIf;
		If vOperationParameters.Property("RRNCode") Then
			pResultOperation.RRNCode = vOperationParameters.RRNCode;
		EndIf;
		If vOperationParameters.Property("ReceiptNumber") Then
			pResultOperation.ReceiptNumber = vOperationParameters.ReceiptNumber;
		EndIf;
		If vOperationParameters.Property("AuthorizationType") Then
			pResultOperation.AuthorizationTypeCode = vOperationParameters.AuthorizationType;
		EndIf;
		If vOperationParameters.Property("OperationStatus") Then
			vOperationStatus = vOperationParameters.OperationStatus;
			pResultOperation.OperationStatus = ?(ValueIsFilled(vOperationStatus), Number(vOperationStatus), 0);
		EndIf;
		If vOperationParameters.Property("ResultCode") Then
			vResultCode = vOperationParameters.ResultCode;
			pResultOperation.ResultCode = ?(ValueIsFilled(vResultCode), Number(vResultCode), 0);
		EndIf;
		If vOperationParameters.Property("PaymentSystemIdentifier") Then
			pResultOperation.PaymentSystemIdentifier = vOperationParameters.PaymentSystemIdentifier;
		EndIf;
		If vOperationParameters.Property("UUID") Then
			pResultOperation.UUID = vOperationParameters.UUID;
		EndIf;
		If vOperationParameters.Property("Date") Then
			pResultOperation.Date = vOperationParameters.Date;
		EndIf;
	EndIf;
	
	If pResultOperation.Property("AuthorizationTypeCode") And tcOnServer.IsNumber(pResultOperation.AuthorizationTypeCode) Then
		pResultOperation.AuthorizationType = tcConnectedHardwareOnServer.AuthorizationTypesByCode(Number(pResultOperation.AuthorizationTypeCode));
	EndIf;
EndProcedure // ProcessOperationData

// --------------------------------------------------------------------------------
Function ExecutingCommand(pHardwareData, pCommand, pDataOperations)
	vObjectDriver = pHardwareData.ObjectDriver;
	If pDataOperations <> Undefined Then
		pDataOperations.Insert("Command", pCommand);
	EndIf;
	
	If pCommand = "AuthorizeSales" Or pCommand = "AuthorizeRefund" Or pCommand = "AuthorizeVoid" Or 
		pCommand = "AuthorizePreSales" Or pCommand = "AuthorizeCompletion" Or pCommand = "AuthorizeVoidPreSales" Then
		If pHardwareData.InterfaceRevision > 4002 Then
			vResultOperation = POSTerminalOperationXML(vObjectDriver, pHardwareData, pDataOperations, pCommand);
		Else
			vResultOperation = POSTerminalOperation(vObjectDriver, pHardwareData, pDataOperations, pCommand);
		EndIf;
	ElsIf pCommand = "Settlement" Then
		vResultOperation = Settlement(vObjectDriver, pHardwareData, pDataOperations);
	ElsIf pCommand = "EmergencyVoid" Then
		vResultOperation = EmergencyReversal(vObjectDriver, pHardwareData, pDataOperations);
	ElsIf pCommand = "GetCardParametrs" Then
		vResultOperation = GetCardParametrs(vObjectDriver, pHardwareData, pDataOperations);
	ElsIf pCommand = "GetOperationByCards" Then
		vResultOperation = GetOperationByCards(vObjectDriver, pHardwareData, pDataOperations);
	Else
		vErrorDescription = NStr("en = 'Invalid command.'; de = 'Ungültiger Befehl.'; ru = 'Недопустимая команда.'"); 
		vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
	EndIf;
	
	Return vResultOperation;
EndFunction // ExecutingCommand

// --------------------------------------------------------------------------------
Function POSTerminalOperationXML(pObjectDriver, pHardwareData, pDataOperations, pCommand)
	If pHardwareData.InterfaceRevision < 4003 Then
		vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
		vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
		Return vResultOperation;
	EndIf;
	
	vConsumerPresentedQR = ?(pDataOperations.ConsumerPresentedQR <> Undefined, pDataOperations.ConsumerPresentedQR, "");
	vAmount = ?(pDataOperations.Amount <> Undefined, pDataOperations.Amount, 0);
	vMerchantNumber = ?(pDataOperations.MerchantNumber <> Undefined, pDataOperations.MerchantNumber, 0);
	vAmountOriginalTransaction = ?(pDataOperations.AmountOriginalTransaction <> Undefined, pDataOperations.AmountOriginalTransaction, 0);
	vInParametersXML = ?(pDataOperations.Property("InParametersXML"), pDataOperations.InParametersXML, "");
	vSlip = "";
	vOutParametersXML = "";
	
	Try
		If pCommand = "AuthorizeSales" Then
			vResult = pObjectDriver.Pay(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
		ElsIf pCommand = "AuthorizeRefund" Then
			vResult = pObjectDriver.ReturnPayment(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
		ElsIf pCommand = "AuthorizeVoid" Then
			If vAmountOriginalTransaction > 0 And Not pHardwareData.PartialCancellation Then
				vErrorDescription = NStr("en = 'Partial cancellation is not supported by the driver.'; de = 'Eine Teilstornierung wird vom Treiber nicht unterstützt.'; ru = 'Частичная отмена не поддерживается драйвером.'");
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
				Return vResultOperation;
			Else
				vResult = pObjectDriver.CancelPayment(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
			EndIf;
		ElsIf pCommand = "AuthorizePreSales" Then
			vResult = pObjectDriver.Authorisation(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
		ElsIf pCommand = "AuthorizeCompletion" Then
			vResult = pObjectDriver.AuthConfirmation(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
		ElsIf pCommand = "AuthorizeVoidPreSales" Then
			vResult = pObjectDriver.CancelAuthorisation(pHardwareData.DeviceID, vInParametersXML, vOutParametersXML, vSlip);
		Else
			vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
			vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
			Return vResultOperation;
		EndIf;
		
		If vResult Then
			vResultOperation = ResultPOSTerminalOperation(True, Undefined, pHardwareData);
			vResultOperation.MerchantNumber = vMerchantNumber;
			vResultOperation.Amount = vAmount;
			vResultOperation.ConsumerPresentedQR = vConsumerPresentedQR;
			vResultOperation.Insert("InParametersXML", vInParametersXML);
			vResultOperation.Insert("OutParametersXML", vOutParametersXML);
		Else
			vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
		EndIf;
		
		vResultOperation.Insert("Slip" , vSlip);
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError(pCommand, vErrorMessage);
	EndTry;
	
	Return vResultOperation;
EndFunction // POSTerminalOperationXML

// --------------------------------------------------------------------------------
Function POSTerminalOperation(pObjectDriver, pHardwareData, pDataOperations, pCommand)
	vInterfaceRevision = pHardwareData.InterfaceRevision;
	
	vConsumerPresentedQR = ?(pDataOperations.ConsumerPresentedQR <> Undefined, pDataOperations.ConsumerPresentedQR, "");
	vMerchantNumber = ?(pDataOperations.MerchantNumber <> Undefined, pDataOperations.MerchantNumber, 0);
	vCardNumber = ?(pDataOperations.CardNumber <> Undefined, pDataOperations.CardNumber, "");
	vReceiptNumber = ?(pDataOperations.ReceiptNumber <> Undefined, pDataOperations.ReceiptNumber, "");
	vRRNCode = ?(pDataOperations.RRNCode <> Undefined, pDataOperations.RRNCode, "");
	vAuthorizationCode = ?(pDataOperations.AuthorizationCode <> Undefined, pDataOperations.AuthorizationCode, "");
	vAmount = ?(pDataOperations.Amount <> Undefined, pDataOperations.Amount, 0);
	vAmountOriginalTransaction = ?(pDataOperations.AmountOriginalTransaction <> Undefined, pDataOperations.AmountOriginalTransaction, 0);
	vSlip = "";
	
	Try
		If vInterfaceRevision >= 4000 Then
			If pCommand = "AuthorizeSales" Then
				vResult = pObjectDriver.PayByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeRefund" Then
				vResult = pObjectDriver.ВернутьПлатежПоПлатежнойКарте(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoid" Then
				If vAmountOriginalTransaction > 0 And Not pHardwareData.PartialCancellation Then
					vErrorDescription = NStr("en = 'Partial cancellation is not supported by the driver.'; de = 'Eine Teilstornierung wird vom Treiber nicht unterstützt.'; ru = 'Частичная отмена не поддерживается драйвером.'");
					vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
					Return vResultOperation;
				Else
					vResult = pObjectDriver.CancelPaymentByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
						vAmountOriginalTransaction, vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
				EndIf;
			ElsIf pCommand = "AuthorizePreSales" Then
				vResult = pObjectDriver.AuthorisationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeCompletion" Then
				vResult = pObjectDriver.AuthConfirmationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoidPreSales" Then
				vResult = pObjectDriver.CancelAuthorisationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vConsumerPresentedQR, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			Else
				vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
				Return vResultOperation;
			EndIf;
		ElsIf vInterfaceRevision >= 3005 Then
			If pCommand = "AuthorizeSales" Then
				vResult = pObjectDriver.PayByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeRefund" Then
				vResult = pObjectDriver.ВернутьПлатежПоПлатежнойКарте(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoid" Then
				vResult = pObjectDriver.CancelPaymentByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizePreSales" Then
				vResult = pObjectDriver.AuthorisationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeCompletion" Then
				vResult = pObjectDriver.AuthConfirmationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoidPreSales" Then
				vResult = pObjectDriver.CancelAuthorisationByPaymentCard(pHardwareData.DeviceID, vMerchantNumber, vAmount,
					vCardNumber, vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			Else
				vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
				Return vResultOperation;
			EndIf;
		Else
			If pCommand = "AuthorizeSales" Then
				vResult = pObjectDriver.PayByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeRefund" Then
				vResult = pObjectDriver.ReturnPaymentByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoid" Then
				vResult = pObjectDriver.CancelPaymentByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizePreSales" Then
				vResult = pObjectDriver.AuthorisationByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeCompletion" Then
				vResult = pObjectDriver.AuthConfirmationByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			ElsIf pCommand = "AuthorizeVoidPreSales" Then
				vResult = pObjectDriver.CancelAuthorisationByPaymentCard(pHardwareData.DeviceID, vCardNumber, vAmount,
					vReceiptNumber, vRRNCode, vAuthorizationCode, vSlip);
			Else
				vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
				Return vResultOperation;
			EndIf;
		EndIf;
			
		If vResult Then
			vResultOperation = ResultPOSTerminalOperation(True, Undefined, pHardwareData);
			vResultOperation.MerchantNumber = vMerchantNumber;
			vResultOperation.CardNumber = vCardNumber;
			vResultOperation.ReceiptNumber = vReceiptNumber;
			vResultOperation.RRNCode = vRRNCode;
			vResultOperation.AuthorizationCode = vAuthorizationCode;
			vResultOperation.Amount = vAmount; 
			vResultOperation.ConsumerPresentedQR = vConsumerPresentedQR;
		Else
			vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
		EndIf;
		vResultOperation.Insert("Slip" , vSlip);
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError(pCommand, vErrorMessage);
	EndTry;
	
	Return vResultOperation;
EndFunction // POSTerminalOperation

// --------------------------------------------------------------------------------
Function Settlement(pObjectDriver, pHardwareData, pDataOperations)
	vSlip = "";
	Try
		vResult = pObjectDriver.ИтогиДняПоКартам(pHardwareData.DeviceID, vSlip);
		If vResult Then
			vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(True);
			vResultOperation.Insert("Slip", vSlip);
		Else
			vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
		EndIf;
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError("Settlement", vErrorMessage);
	EndTry;
	
	If pHardwareData.InterfaceRevision > 4001 Then
		vResult = SetApplicationInformation(pObjectDriver, pHardwareData);
	EndIf;
	
	Return vResultOperation;
EndFunction // Settlement

// --------------------------------------------------------------------------------
Function SetApplicationInformation(pObjectDriver, pHardwareData) 
	Try
		vResult = pObjectDriver.SetApplicationInformation(pHardwareData.ApplicationSettingsXML);
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError("SetApplicationInformation", vErrorMessage);
	EndTry;
	
	vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(vResult);
	If Not vResult Then
		tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
	EndIf;
	
	Return vResultOperation;
EndFunction // SetApplicationInformation

// --------------------------------------------------------------------------------
Function EmergencyReversal(pObjectDriver, pHardwareData, pDataOperations)
	Try
		vResult = pObjectDriver.EmergencyReversal(pHardwareData.DeviceID);
		If vResult Then
			vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(True);
		Else
			vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
		EndIf;
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError("EmergencyReversal", vErrorMessage);
	EndTry;
	
	Return vResultOperation;
EndFunction // EmergencyReversal

// --------------------------------------------------------------------------------
Function GetCardParametrs(pObjectDriver, pHardwareData, pDataOperations)
	vInterfaceRevision = pHardwareData.InterfaceRevision;
	
	If vInterfaceRevision > 3004 Then
		vLastOperation = True;
		vCardNumber = "";
		vCardNumberHash = "";
		vConsumerPresentedQR = "";
		vPaymentAccountReference = "";
		vCardType = "";
		vIsOwnCard = 0;
		Try
			If vInterfaceRevision >= 4000 Then
				vConsumerPresentedQR = ?(pDataOperations.Property("ConsumerPresentedQR"), pDataOperations.ConsumerPresentedQR, "");
				If Not IsBlankString(vConsumerPresentedQR) And Not pHardwareData.ConsumerPresentedQR Then
					vErrorDescription = NStr("en = 'Consumer-Presented QR is not supported by the driver.'; de = 'Consumer-Presented QR wird vom Treiber nicht unterstützt.'; ru = 'Consumer-Presented QR не поддерживается драйвером.'");
					vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
					Return vResultOperation;
				EndIf;
				
				vResult = pObjectDriver.GetCardParametrs(pHardwareData.DeviceID, vConsumerPresentedQR, vLastOperation, vCardNumber, vCardNumberHash, vPaymentAccountReference, vCardType, vIsOwnCard);
			ElsIf vInterfaceRevision >= 3007 Then
				vResult = pObjectDriver.GetCardParametrs(pHardwareData.DeviceID, vLastOperation, vCardNumber, vCardNumberHash, vPaymentAccountReference, vCardType, vIsOwnCard);
			Else
				vResult = pObjectDriver.GetCardParametrs(pHardwareData.DeviceID, vLastOperation, vCardNumber, vCardNumberHash, vCardType, vIsOwnCard);
			EndIf;
			If vResult Then
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(True);
				vResultOperation.Insert("CardNumber", vCardNumber);
				vResultOperation.Insert("CardNumberHash", vCardNumberHash);
				vResultOperation.Insert("PaymentAccountReference", vPaymentAccountReference);
				vResultOperation.Insert("ConsumerPresentedQR", vConsumerPresentedQR);
				vResultOperation.Insert("CardType", vCardType);
				vResultOperation.Insert("IsOwnCard", vIsOwnCard);
			Else
				vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
			EndIf;
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError("GetCardParametrs", vErrorMessage);
		EndTry;
	Else
		vErrorDescription = NStr("en = 'The terminal does not support this operation.'; de = 'Das Terminal unterstützt diesen Vorgang nicht.'; ru = 'Терминал не поддерживает данную операцию.'");
		vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
	EndIf;
	
	Return vResultOperation;
EndFunction // GetCardParametrs

// --------------------------------------------------------------------------------
Function GetOperationByCards(pObjectDriver, pHardwareData, pDataOperations)
	If pHardwareData.InterfaceRevision < 4000 Then
		vErrorDescription = NStr("en = 'The command is not supported by the driver.'; de = 'Der Befehl wird vom Treiber nicht unterstützt.'; ru = 'Команда не поддерживается драйвером.'");
		vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription); 
		Return vResultOperation;
	Else
		If Not pHardwareData.ListCardTransactions Then
			vErrorDescription = NStr("en = 'The terminal does not support this operation.'; de = 'Das Terminal unterstützt diesen Vorgang nicht.'; ru = 'Терминал не поддерживает данную операцию.'"); 
			vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(False, vErrorDescription);
			Return vResultOperation;
		EndIf;
		
		Try
			vResultOperationXML = "";
			vResult = pObjectDriver.GetOperationByCards(pHardwareData.DeviceID, vResultOperationXML);
			If vResult Then
				vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(True);
				vResultOperation.Insert("ResultOperationXML", vResultOperationXML);
			Else
				vResultOperation = tcConnectedHardwareOnClientServer.GetDriverError(pObjectDriver, True);
			EndIf;
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			vResultOperation = tcConnectedHardwareOnClientServer.DriverCallError("GetOperationByCards", vErrorMessage);
		EndTry;
	EndIf;
	
	Return vResultOperation;
EndFunction // GetOperationByCards

// --------------------------------------------------------------------------------
Function ResultPOSTerminalOperation(pResult, pErrorDescription, pHardwareData)
	vResultOperation = tcConnectedHardwareOnClientServer.ResultOperationOnHardware(pResult, pErrorDescription, pHardwareData.Hardware);
	vResultOperation.Insert("MerchantNumber");
	vResultOperation.Insert("ConsumerPresentedQR");
	vResultOperation.Insert("UseBiometrics", False);
	vResultOperation.Insert("Amount");
	vResultOperation.Insert("AuthorizationType");
	vResultOperation.Insert("AuthorizationTypeCode", 0);
	vResultOperation.Insert("CardNumber");
	vResultOperation.Insert("CardNumberHash");
	vResultOperation.Insert("ReceiptNumber");
	vResultOperation.Insert("RRNCode");
	vResultOperation.Insert("AuthorizationCode");
	vResultOperation.Insert("Date");
	vResultOperation.Insert("PaymentSystemIdentifier");
	vResultOperation.Insert("UUID");
	vResultOperation.Insert("ResultCode");
	vResultOperation.Insert("TerminalID", pHardwareData.TerminalID);
	vResultOperation.Insert("AcquiringBankIdentifier", pHardwareData.AcquiringBankIdentifier);
	Return vResultOperation;
EndFunction // ResultPOSTerminalOperation

// --------------------------------------------------------------------------------
Function POSTerminalOperationExecutionParameters()
	vResult = New Structure;
	vResult.Insert("MerchantNumber");
	vResult.Insert("ConsumerPresentedQR");
	vResult.Insert("UseBiometrics", False);
	vResult.Insert("Amount", 0);
	vResult.Insert("AmountOriginalTransaction", 0);
	vResult.Insert("CardNumber");
	vResult.Insert("CardNumberHash");
	vResult.Insert("ReceiptNumber");
	vResult.Insert("RRNCode");
	vResult.Insert("AuthorizationCode");
	Return vResult;
EndFunction // POSTerminalOperationExecutionParameters

#EndRegion
