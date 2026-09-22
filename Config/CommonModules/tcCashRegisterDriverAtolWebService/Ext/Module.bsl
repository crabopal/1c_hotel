
#Region JSONObject 

// -----------------------------------------------------------------------------
Function GetOperatorStructure(pName, pVatin = "")
	vOperator = New Structure();
	vBody = New Structure();
	vBody.Insert("name", pName);
	If ValueIsFilled(pVatin) Then
		vBody.Insert("vatin", pVatin);	
	EndIf;
	vOperator.Insert("operator", vBody);
	Return vOperator;
EndFunction // FillInTheOperator

// -----------------------------------------------------------------------------
Procedure GetPaymentStructure(pPaymentsStruct, pType, pSum, pPrintItems = Undefined)
	vCheckPayment = New Structure();
	vCheckPayment.Insert("type", pType);
	vCheckPayment.Insert("sum", pSum);
	If pPrintItems <> Undefined Then
		vCheckPayment.Insert("printItems", pPrintItems.items);
	Endif;
	If pPaymentsStruct <> Undefined Then
		If pPaymentsStruct.Property("payments") Then
			pPaymentsStruct.payments.Add(vCheckPayment);	
		Else
			pPaymentsStruct = New Structure("payments", New Array());
			pPaymentsStruct.payments.Add(vCheckPayment);
		EndIf;	
	Else
		pPaymentsStruct = New Structure("payments", New Array());
		pPaymentsStruct.payments.add(vCheckPayment);
	EndIf;
EndProcedure // GetPaymentStructure

// -----------------------------------------------------------------------------
Function GetTaxStructure(pType, pSum = Undefined)
	vTax = New Structure();
	vTax.Insert("type", pType);
	If ValueIsFilled(pSum) Then
		vTax.Insert("sum", pSum);
	EndIf;
	Return vTax;
EndFunction // GetTaxStructure

// -----------------------------------------------------------------------------
Function GetClientInfoStructure(pEmailOrPhone = "", pVatin = "", pName = "")
	If IsBlankString(pEmailOrPhone) And IsBlankString(pVatin) And IsBlankString(pName) Then
		Return Undefined;	
	EndIf;
	
	vClientInfo = New Structure();
	vBody = New Structure();
	If Not IsBlankString(pEmailOrPhone) Then
		vBody.Insert("emailOrPhone", pEmailOrPhone);
	EndIf;
	If Not IsBlankString(pVatin) And Not IsBlankString(pName) Then
		vBody.Insert("vatin", ?(StrLen(pVatin) = 10, pVatin + "  ", pVatin));
		vBody.Insert("name", pName);
	EndIf;
	If Not IsBlankString(vBody) Then
		vClientInfo.Insert("clientInfo", vBody);
	EndIf;
	Return vClientInfo;
EndFunction // GetClientInfoStructure

// -----------------------------------------------------------------------------
Function GetAgentInfoStructure(pAgents = Undefined, pPayingAgent = Undefined, pReceivePaymentsOperator = Undefined, pMoneyTransferOperator = Undefined)
	vAgentInfo = New Structure();
	vBody = New Structure();
	If pAgents <> Undefined Then
		vAgentsArray = New Array();
		If TypeOf(pAgents) = Type("String") Then
			vAgentsArray.Add(pAgents);
			vBody.Insert("agents",vAgentsArray);		
		ElsIf TypeOf(pAgents) = Type("Array") Then
			vBody.Insert("agents",pAgents);	
		Else
			If pAgents = 1 Then
				vAgentsArray.Add("another");
				vBody.Insert("agents",vAgentsArray);
			Else
				vAgentsArray.Add("commissionAgent");
				vBody.Insert("agents",vAgentsArray);
			EndIf;
		EndIf;
	EndIf;
	If pPayingAgent <> Undefined Then
		vBody.Insert("payingAgent",GetPayingAgent(pPayingAgent));
	EndIf;
	If pReceivePaymentsOperator <> Undefined Then
		vBody.Insert("receivePaymentsOperator",GetReceivePaymentsOperator(pReceivePaymentsOperator));
	EndIf;
	If pMoneyTransferOperator <> Undefined Then
		vBody.Insert("moneyTransferOperator",GetMoneyTransferOperator(pMoneyTransferOperator));
	EndIf;
	vAgentInfo.Insert("agentInfo",vBody);
	If Not ValueIsFilled(pAgents) And Not ValueIsFilled(pPayingAgent) And Not ValueIsFilled(pReceivePaymentsOperator) And Not ValueIsFilled(pMoneyTransferOperator) Then
		vAgentInfo = Undefined;
	EndIf;
	Return vAgentInfo;
EndFunction // GetAgentInfoStructure

// -----------------------------------------------------------------------------
Function GetPayingAgent(pPayingAgent)
	vPayingAgent = New Structure();
	vPayingAgent.Insert("operation", pPayingAgent.Operation);
	vPhonesArray = New Array();
	If TypeOf(pPayingAgent.Phones) <> Type("String") Then
		For Each vPayingAgentPhone In pPayingAgent.Phones Do
			vPhonesArray.Add(vPayingAgentPhone);	
		EndDo;
	Else
		vPhonesArray.Add(pPayingAgent.Phones);	
	EndIf;
	vPayingAgent.Insert("phones", vPhonesArray);
	Return vPayingAgent;
EndFunction // GetPayingAgent

// -----------------------------------------------------------------------------
Function GetReceivePaymentsOperator(pReceivePaymentsOperator)
	vReceivePaymentsOperator = New Structure();
	vPhonesArray = New Array();
	If TypeOf(pReceivePaymentsOperator.Phones) <> Type("String") Then
		For Each vReceivePaymentsOperatorPhone in pReceivePaymentsOperator.Phones Do
			vPhonesArray.Add(vReceivePaymentsOperatorPhone);	
		EndDo;
	Else
		vPhonesArray.Add(pReceivePaymentsOperator.Phones);	
	EndIf;
	vReceivePaymentsOperator.Insert("phones", vPhonesArray);
	Return vReceivePaymentsOperator;
EndFunction // GetReceivePaymentsOperator

// -----------------------------------------------------------------------------
Function GetMoneyTransferOperator(pMoneyTransferOperator)
	vMoneyTransferOperator = New Structure();
	vPhonesArray = New Array();
	If TypeOf(pMoneyTransferOperator.Phones) <> Type("String") Then
		For Each vMoneyTransferOperatorPhone In pMoneyTransferOperator.Phones Do
			vPhonesArray.Add(vMoneyTransferOperatorPhone);	
		EndDo;
	Else
		vPhonesArray.Add(pMoneyTransferOperator.Phones);	
	EndIf;
	vMoneyTransferOperator.Insert("phones", vPhonesArray);
	vMoneyTransferOperator.Insert("name", pMoneyTransferOperator.Name);
	vMoneyTransferOperator.Insert("address", pMoneyTransferOperator.Address);
	vMoneyTransferOperator.Insert("vatin", pMoneyTransferOperator.Vatin);
	Return vMoneyTransferOperator;
EndFunction // GetMoneyTransferOperator

// -----------------------------------------------------------------------------
Function GetSupplierInfoStructure(pPhones, pName, pVatin)
	vSupplierInfo = New Structure();
	vPhonesArray = New Array();
	If TypeOf(pPhones) <> Type("String") Then
		For Each vMoneyTransferOperatorPhone In pPhones Do
			vPhonesArray.Add(vMoneyTransferOperatorPhone);	
		EndDo;
	Else
		vPhonesArray.Add(pPhones);	
	EndIf;
	vBody = New Structure();
	vBody.Insert("phones", vPhonesArray);
	vBody.Insert("name", pName);
	vBody.Insert("vatin", pVatin);
	vSupplierInfo.Insert("supplierInfo",vBody);
	Return vSupplierInfo;
EndFunction // GetSupplierInfoStructure

// -----------------------------------------------------------------------------
Procedure GetTextStructure(pItemsStructure, pText = "", pAlignment = "", pWrap = "", pFont = Undefined, pDoubleWidth = Undefined, pDoubleHeight = Undefined)
	vText = New Structure();
	vText.Insert("type", "text");
	If ValueIsFilled(pText) Then
		vText.Insert("text", pText);
	EndIf;
	If ValueIsFilled(pAlignment) Then
		vText.Insert("alignment", pAlignment);
	EndIf;
	If ValueIsFilled(pWrap) Then
		vText.Insert("wrap", pWrap);
	EndIf;
	If pFont <> Undefined Then
		vText.Insert("font", pFont);
	EndIf;
	If pDoubleWidth <> Undefined Then
		vText.Insert("doubleWidth", pDoubleWidth);
	EndIf;
	If pDoubleHeight <> Undefined Then
		vText.Insert("doubleHeight", pDoubleHeight);
	EndIf;
	If pItemsStructure <> Undefined Then
		If pItemsStructure.Property("items") Then
			pItemsStructure.items.Add(vText);	
		Else
			pItemsStructure = New Structure("items", New Array());
			pItemsStructure.items.Add(vText);
		EndIf;
	Else
		pItemsStructure = New Structure("items", New Array());
		pItemsStructure.items.Add(vText);		
	EndIf;	
EndProcedure // GetTextStructure

// -----------------------------------------------------------------------------
Procedure GetPositionStructure(pItemsStructure, pName, pPrice, pQuantity, pAmount, pInfoDiscountAmount = Undefined, pDepartment = Undefined, pMeasurementUnit = "", pPiece = Undefined, 
	pPaymentMethod = Undefined, pPaymentObject, pTax = Undefined, pAgentInfo = Undefined, pSupplierInfo = Undefined, 
	pAdditionalAttribute = "", pAdditionalAttributePrint = Undefined, pExciseSum = Undefined, pCountryCode = "", pCustomsDeclaration = "", pCashRegisterItemCode = "")
	
	vPosition = New Structure();
	vPosition.Insert("type", "position");
	vPosition.Insert("name", pName);
	vPosition.Insert("price", pPrice);
	vPosition.Insert("quantity", pQuantity);
	vPosition.Insert("amount", pAmount);
	If pInfoDiscountAmount <> Undefined Then
		vPosition.Insert("infoDiscountAmount", pInfoDiscountAmount);
	EndIf;
	If pDepartment <> Undefined Then
		vPosition.Insert("department", pDepartment);
	EndIf;
	If ValueIsFilled(pMeasurementUnit) Then
		vPosition.Insert("measurementUnit", pMeasurementUnit);
	EndIf;
	If pPiece <> Undefined Then
		vPosition.Insert("piece", pPiece);
	EndIf;
	If pPaymentMethod <> Undefined Then
		vPosition.Insert("paymentMethod", pPaymentMethod);
	EndIf;
	vPosition.Insert("paymentObject", pPaymentObject);
	If pTax <> Undefined Then
		vPosition.Insert("tax", pTax);
	EndIf;
	If pAgentInfo <> Undefined Then
		vPosition.Insert("agentInfo", pAgentInfo.agentInfo);
	EndIf;
	If pSupplierInfo <> Undefined Then
		vPosition.Insert("supplierInfo", pSupplierInfo.supplierInfo);
	EndIf;
	If ValueIsFilled(pAdditionalAttribute) Then
		vPosition.Insert("additionalAttribute", pAdditionalAttribute);
	EndIf;
	If pAdditionalAttributePrint <> Undefined Then
		vPosition.Insert("additionalAttributePrint", pAdditionalAttributePrint);
	EndIf;
	If pExciseSum <> Undefined Then
		vPosition.Insert("exciseSum", pExciseSum);
	EndIf;
	If ValueIsFilled(pCountryCode) Then
		vPosition.Insert("countryCode", pCountryCode);
	EndIf;
	If ValueIsFilled(pCustomsDeclaration) Then
		vPosition.Insert("customsDeclaration", pCustomsDeclaration);
	EndIf;
	If Not IsBlankString(pCashRegisterItemCode) Then
		vPosition.Insert("nomenclatureCode", pCashRegisterItemCode);
	EndIf;
	If pItemsStructure <> Undefined Then
		If pItemsStructure.Property("items") Then
			pItemsStructure.items.Add(vPosition);	
		Else
			pItemsStructure = New Structure("items", New Array());
			pItemsStructure.items.Add(vPosition);
		EndIf;
	Else
		pItemsStructure = New Structure("items", New Array());
		pItemsStructure.items.Add(vPosition);		
	EndIf;
EndProcedure // GetPositionStructure

// -----------------------------------------------------------------------------
Procedure GetAddCheckDetailsStructure(pItemsStructure, pValue)
	vCheckDetails = New Structure("type, value, print", "additionalAttribute", pValue, True);
	If pItemsStructure <> Undefined Then
		If pItemsStructure.Property("items") Then
			pItemsStructure.items.Add(vCheckDetails);	
		Else
			pItemsStructure = New Structure("items", New Array());
			pItemsStructure.items.Add(vCheckDetails);
		EndIf;
	Else
		pItemsStructure = New Structure("items", New Array());
		pItemsStructure.items.Add(vCheckDetails);		
	EndIf;
EndProcedure // GetAddCheckDetails

#EndRegion

#Region JSONRequests

// -----------------------------------------------------------------------------
Function GetOpenCashDrawerStructure()
	vOpenCashDrawer = New Structure("type", "openCashDrawer");
	Return vOpenCashDrawer;	
EndFunction // GetOpenCashDrawerStructure

// -----------------------------------------------------------------------------
Function GetRegistrationInfoStructure()
	vOpenCashDrawer = New Structure("type", "getRegistrationInfo");
	Return vOpenCashDrawer;	
EndFunction // GetRegistrationInfoStructure

// -----------------------------------------------------------------------------
Function GetOpenShiftStructure(pOperator = Undefined, pPreItems = Undefined, pPostItems = Undefined, pElectronically = Undefined)
	vOpenShift = New Structure();
	vOpenShift.Insert("type","openShift");
	If pOperator <> Undefined Then
		vOpenShift.Insert("operator", pOperator.operator);
	EndIf;
	If pPreItems <> Undefined Then
		vOpenShift.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vOpenShift.Insert("postItems", pPostItems.items);
	EndIf;
	If pElectronically <> Undefined Then
		vOpenShift.Insert("electronically", pElectronically);
	EndIf;
	Return vOpenShift;
EndFunction // GetOpenShiftStructure

// -----------------------------------------------------------------------------
Function GetCloseShiftStructure(pOperator = Undefined, pPreItems = Undefined, pPostItems = Undefined, pElectronically = Undefined)
	vCloseShift = New Structure();
	vCloseShift.Insert("type","closeShift");
	If pOperator <> Undefined Then
		vCloseShift.Insert("operator", pOperator.operator);
	EndIf;
	If pPreItems <> Undefined Then
		vCloseShift.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vCloseShift.Insert("postItems", pPostItems.items);
	EndIf;
	If pElectronically <> Undefined Then
		vCloseShift.Insert("electronically", pElectronically);
	EndIf;
	Return vCloseShift;
EndFunction // GetCloseShiftStructure

// -----------------------------------------------------------------------------
Function GetXReportStructure(pOperator = Undefined, pPreItems = Undefined, pPostItems = Undefined)
	vXReport = New Structure();
	vXReport.Insert("type","reportX");
	If pOperator <> Undefined Then
		vXReport.Insert("operator", pOperator.operator);
	EndIf;
	If pPreItems <> Undefined Then
		vXReport.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vXReport.Insert("postItems", pPostItems.items);
	EndIf;
	Return vXReport;
EndFunction // GetXReportStructure

// -----------------------------------------------------------------------------
Function GetNonFiscalChequeStructure(pItems, pPrintFooter = Undefined)
	vNonFiscalCheque = New Structure();
	vNonFiscalCheque.Insert("type","nonFiscal");
	vNonFiscalCheque.Insert("items", pItems.items);	
	If pPrintFooter <> Undefined Then
		vNonFiscalCheque.Insert("printFooter", pPrintFooter);
	EndIf;
	Return vNonFiscalCheque;
EndFunction // GetNonFiscalChequeStructure

// -----------------------------------------------------------------------------
Function GetReportOfdExchangeStatusStructure(pOperator = Undefined, pPreItems = Undefined, pPostItems = Undefined)
	vReportOfdExchangeStatus = New Structure();
	vReportOfdExchangeStatus.Insert("type","reportOfdExchangeStatus");
	If pOperator <> Undefined Then
		vReportOfdExchangeStatus.Insert("operator", pOperator.operator);
	EndIf;
	If pPreItems <> Undefined Then
		vReportOfdExchangeStatus.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vReportOfdExchangeStatus.Insert("postItems", pPostItems.items);
	EndIf;
	Return vReportOfdExchangeStatus;
EndFunction // GetReportOfdExchangeStatusStructure

// -----------------------------------------------------------------------------
Function GetCashIncomeOrOutcomeStructure(pType, pOperator = Undefined, pCashSum, pPreItems = Undefined, pPostItems = Undefined)
	vCashIncomeOrOutcome = New Structure();
	vCashIncomeOrOutcome.Insert("type", pType);
	If pOperator <> Undefined Then
		vCashIncomeOrOutcome.Insert("operator", pOperator.operator);
	EndIf;
	vCashIncomeOrOutcome.Insert("cashSum", pCashSum);
	If pPreItems <> Undefined Then
		vCashIncomeOrOutcome.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vCashIncomeOrOutcome.Insert("postItems", pPostItems.items);
	EndIf;
	Return vCashIncomeOrOutcome;
EndFunction // GetCashIncomeOrOutcomeStructure

// -----------------------------------------------------------------------------
Function GetDeviceStatusStructure()
	vDeviceStatus = New Structure("type","getDeviceStatus");
	Return vDeviceStatus;
EndFunction // GetDeviceStatusStructure

// -----------------------------------------------------------------------------
Function GetSetDateTimeStructure(pDateTime = "")
	vSetDateTime = New Structure("type","setDateTime");
	vSetDateTime.Insert("dateTime",pDateTime);
	Return vSetDateTime;
EndFunction // GetSetDateTimeStructure

// -----------------------------------------------------------------------------
Function GetFiscalStructure(pType, pIgnoreNonFiscalPrintErrors = Undefined, pElectronically = Undefined, pUseVAT18 = Undefined, pTaxationType = "",
	pPaymentsPlace = "", pMachineNumber = "", pOperator = Undefined, pClientInfo = Undefined, pCompanyInfo = Undefined, pAgentInfo = Undefined,
	pSupplierInfo = Undefined, pItems, pPayments, pTaxes = Undefined, pTotal = Undefined, pPreItems = Undefined, pPostItems = Undefined)
	
	vFiscal = New Structure();
	vFiscal.Insert("type", pType);
	If pIgnoreNonFiscalPrintErrors <> Undefined Then
		vFiscal.Insert("ignoreNonFiscalPrintErrors", pIgnoreNonFiscalPrintErrors);
	EndIf;
	If pElectronically <> Undefined Then
		vFiscal.Insert("electronically", pElectronically);
	EndIf;
	If pUseVAT18 <> Undefined Then
		vFiscal.Insert("useVAT18", pUseVAT18);
	EndIf;
	If ValueIsFilled(pTaxationType) Then
		vFiscal.Insert("taxationType", pTaxationType);
	EndIf;
	If ValueIsFilled(pPaymentsPlace) Then
		vFiscal.Insert("paymentsPlace", pPaymentsPlace);
	EndIf;
	If ValueIsFilled(pMachineNumber) Then
		vFiscal.Insert("machineNumber", pMachineNumber);
	EndIf;
	If pOperator <> Undefined Then
		vFiscal.Insert("operator", pOperator.operator);
	EndIf;
	If pClientInfo <> Undefined Then
		vFiscal.Insert("clientInfo", pClientInfo.clientInfo);
	EndIf;
	If pCompanyInfo <> Undefined Then
		vFiscal.Insert("companyInfo", pCompanyInfo.companyInfo);
	EndIf;
	If pAgentInfo <> Undefined Then
		vFiscal.Insert("agentInfo", pAgentInfo.agentInfo);
	EndIf;
	If pSupplierInfo <> Undefined Then
		vFiscal.Insert("supplierInfo", pSupplierInfo.supplierInfo);
	EndIf;
	vFiscal.Insert("items", pItems.items);
	vFiscal.Insert("payments", pPayments.payments);
	If pTaxes <> Undefined Then
		vFiscal.Insert("taxes", pTaxes);
	EndIf;
	If pTotal <> Undefined Then
		vFiscal.Insert("total", pTotal);
	EndIf;
	If pPreItems <> Undefined Then
		vFiscal.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vFiscal.Insert("postItems", pPostItems.items);
	EndIf;
	Return vFiscal;
EndFunction // GetFiscalStructure

// -----------------------------------------------------------------------------
Function GetCorrectionStructure(pType, pIgnoreNonFiscalPrintErrors = Undefined, pOperator = Undefined, pCorrectionType = "", pCorrectionBaseName = "", pCorrectionBaseDate = "", 
	pCorrectionBaseNumber = "", pElectronically = Undefined, pUseVAT18 = Undefined, pTaxationType = "", pPaymentsPlace = "", pMachineNumber = "", pClientInfo = Undefined, pCompanyInfo = Undefined, 
	pAgentInfo = Undefined, pSupplierInfo = Undefined, pItems, pPayments, pTaxes = Undefined, pTotal = Undefined, pPreItems = Undefined, pPostItems = Undefined)
	
	vCorrection = New Structure();
	vCorrection.Insert("type", pType);
	If pIgnoreNonFiscalPrintErrors <> Undefined Then
		vCorrection.Insert("ignoreNonFiscalPrintErrors", pIgnoreNonFiscalPrintErrors);
	EndIf;
	If pOperator <> Undefined Then
		vCorrection.Insert("operator", pOperator.operator);
	EndIf;
	If ValueIsFilled(pCorrectionType) Then
		vCorrection.Insert("correctionType", pCorrectionType);
	EndIf;
	If ValueIsFilled(pCorrectionBaseName) Then
		vCorrection.Insert("correctionBaseName", pCorrectionBaseName);
	EndIf;
	If ValueIsFilled(pCorrectionBaseDate) Then
		vCorrection.Insert("correctionBaseDate", pCorrectionBaseDate);
	EndIf;
	If ValueIsFilled(pCorrectionBaseNumber) Then
		vCorrection.Insert("correctionBaseNumber", pCorrectionBaseNumber);
	EndIf;
	If pElectronically <> Undefined Then
		vCorrection.Insert("electronically", pElectronically);
	EndIf;
	If pUseVAT18 <> Undefined Then
		vCorrection.Insert("useVAT18", pUseVAT18);
	EndIf;
	If ValueIsFilled(pTaxationType) Then
		vCorrection.Insert("taxationType", pTaxationType);
	EndIf;
	If ValueIsFilled(pPaymentsPlace) Then
		vCorrection.Insert("paymentsPlace", pPaymentsPlace);
	EndIf;
	If ValueIsFilled(pMachineNumber) Then
		vCorrection.Insert("machineNumber", pMachineNumber);
	EndIf;
	If pOperator <> Undefined Then
		vCorrection.Insert("operator", pOperator.operator);
	EndIf;
	If pClientInfo <> Undefined Then
		vCorrection.Insert("clientInfo", pClientInfo.clientInfo);
	EndIf;
	If pCompanyInfo <> Undefined Then
		vCorrection.Insert("companyInfo", pCompanyInfo.companyInfo);
	EndIf;
	If pAgentInfo <> Undefined Then
		vCorrection.Insert("agentInfo", pAgentInfo.agentInfo);
	EndIf;
	If pSupplierInfo <> Undefined Then
		vCorrection.Insert("supplierInfo", pSupplierInfo.supplierInfo);
	EndIf;
	vCorrection.Insert("items", pItems.items);
	vCorrection.Insert("payments", pPayments.payments);
	If pTaxes <> Undefined Then
		vCorrection.Insert("taxes", pTaxes);
	EndIf;
	If pTotal <> Undefined Then
		vCorrection.Insert("total", pTotal);
	EndIf;
	If pPreItems <> Undefined Then
		vCorrection.Insert("preItems", pPreItems.items);
	EndIf;
	If pPostItems <> Undefined Then
		vCorrection.Insert("postItems", pPostItems.items);
	EndIf;
	Return vCorrection;
EndFunction // GetCorrectionStructure

#EndRegion

// -----------------------------------------------------------------------------
Function CloseOpenCheque(pConnectionParameters, pOpenSessionIfClosed = False, pIgnoreEndOfPaperError = False, rMessage)
	vStatusArr = JSONProcessing(pConnectionParameters, GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"));	
	If vStatusArr <> Undefined Then
		vStatus = vStatusArr[0].result.deviceStatus;
		If Not pIgnoreEndOfPaperError And Not vStatus.paperPresent Then
			rMessage = NStr("en='Cheque ribbon is over!'; de='Scheck Band ist vorbei!'; ru='В ККМ закончилась бумага!'");
			Return False;
		EndIf;
		If pOpenSessionIfClosed Then
			If vStatus.shift = "closed" Then
				// Set cashier name
				vCashier = tcOnServer.cmGetCurrentUserAttribute();
				If ValueIsFilled(vCashier) Then
					vCashierName = tcCashRegisters.GetCashierName(vCashier);
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					vOperator = GetOperatorStructure(vCashierName, vEmployeeTIN);
					vOpenSession = GetOpenShiftStructure(vOperator);
				Else
					vOpenSession = GetOpenShiftStructure();	
				EndIf;
				// Open session
				vOpenStatus = JSONProcessing(pConnectionParameters, vOpenSession, rMessage, NStr("en='CashRegister.OpenShift'; de='CashRegister.OpenShift'; ru='ККМ.ОткрытиеСмены'"));
				If vOpenStatus = Undefined Then
					Return False;
				Endif;
			EndIf;
		EndIf;
		Return True;
	EndIf;
	Return False;
EndFunction // CloseOpenCheque

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try	
			vItemsArray = Undefined;
			vChequeType = ?(pSum >= 0, "ПРИХОД", "ВОЗВРАТ ПРИХОДА");
			
			// Convert cheque template to the array of strings
			vTextArr = tcCashRegisters.GetTextLinesArray(pChequeTemplate);
			
			// Print all strings in the array
			vDoPrintClicheAtEnd = False;
			
			// Print first slip for the hotel
			vNum = 0;
			For Each vStr In vTextArr Do
				vNum = vNum + 1;
				If vStr = "&Cliche" And vNum = vTextArr.Count() Then
					vDoPrintClicheAtEnd = True;
					Continue;
				ElsIf vStr = "&FolioHeader" Then
					Try
						PrintFolioHeader(vItemsArray, pObj, vArrCashRegister)					
					Except
					EndTry;
				Else
					vStr = StrReplace(vStr, "&Type", vChequeType);
					vStr = StrReplace(vStr, "&CurrentDate", Format(CurrentDate(), "DF=dd.MM.yyyy"));
					vStr = StrReplace(vStr, "&CurrentTime", Format(CurrentDate(), "DF=HH:mm"));
					Try
						vStr = StrReplace(vStr, "&Document", ?(pSum >= 0, "Предварительный счет", "Возврат по платежу") + " № " + TrimAll(pObj.Number));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Hotel", tcCashRegisters.GetHotelPrintName(pObj.Hotel));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Currency", TrimAll(pObj.PaymentCurrency));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&VATRate", TrimAll(pObj.VATRate));
					Except
					EndTry;
					Try
						vStr = StrReplace(vStr, "&Cashier", tcCashRegisters.GetCashierName(pObj.Author));
					Except
					EndTry;
					vStr = StrReplace(vStr, "&Amount", Format(?(pSum < 0, -pSum, pSum), "NFD=2"));
					GetTextStructure(vItemsArray, GetString(vStr, vArrCashRegister));
				EndIf;
			EndDo;
			
			// Print cliche
			If Not vDoPrintClicheAtEnd Then
				For s = 0 To 5 Do
					GetTextStructure(vItemsArray," ");
				EndDo;
			EndIf;
			
			vPrintNonFiscal = JSONProcessing( vArrCashRegister, GetNonFiscalChequeStructure(vItemsArray, vDoPrintClicheAtEnd), rMessage, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"));
			If vPrintNonFiscal = Undefined Then
				Return False;
			EndIf;
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Procedure PrintFolioHeader(rItemsArr, pObj, pArrCashRegister)
	vArrCashRegister = pArrCashRegister;
	// Header start delimeter
	GetTextStructure(rItemsArr, GetString("-----------------------------------------------------------------------", vArrCashRegister));
	// Folio #                                                                    
	vFolioRef = pObj.Folio;
	vFolioNumber = tcOnServer.cmGetAttributeByRef(vFolioRef, "Number");
	GetTextStructure(rItemsArr, GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + tcOnServer.GetDocumentNumberPresentation(vFolioNumber), vArrCashRegister));
	// Room
	If Not pArrCashRegister.DoNotPrintRoom Then
		GetTextStructure(rItemsArr, GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Room"), "Description")), vArrCashRegister)); 
	EndIf;
	// Guest
	If Not pArrCashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			GetTextStructure(rItemsArr, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Payer, "Description")), vArrCashRegister));
		Else
			GetTextStructure(rItemsArr, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Client"), "Description")), vArrCashRegister));
		EndIf;
	EndIf;
	// Guest group
	GetTextStructure(rItemsArr, GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.GuestGroup, "Code")), vArrCashRegister)); 
	// Document                                                                
	GetTextStructure(rItemsArr, GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(pObj.Number), vArrCashRegister));
	// Header end delimeter
	GetTextStructure(rItemsArr, GetString("-----------------------------------------------------------------------", vArrCashRegister)); 
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Function GetString(pStr, pArrCashRegister)
	vChequeWidth = pArrCashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	vStatusArr = JSONProcessing(vArrCashRegister, GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.pmIsReadyToPrint'; de='CashRegister.pmIsReadyToPrint'; ru='ККМ.ГотовКПечати'"));
	If vStatusArr = Undefined Then
		Return False;
	Else // Cash register was connected
		vStatus = vStatusArr[0].result.deviceStatus;
		If vStatus.shift = "expired" Then
			If Not pSkip24HoursLimitWarning Then
				rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
				Return False;
			EndIf;
		EndIf;
		// Check paper
		If Not vArrCashRegister.IgnoreEndOfPaperError And Not vStatus.paperPresent Then
			rMessage = NStr("ru='В ККТ закончилась чековая лента!'; en='Cash register is out of paper!'; de='Cash register is out of paper!'");
			Return False;
		EndIf;
		// Check cheque printer
		If vStatus.blocked = True Then
			rMessage = NStr("ru='ККТ заблокирована!'; en='Cash register is blocked!'; de='Kasse ist gesperrt!'");
			Return False;
		EndIf;
		If vStatus.coverOpened = True Then
			rMessage = NStr("ru='Крышка открыта!'; en='The lid is open'; de='Deckel offen!'");
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage, pObj, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj);
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try
			vReportOfdExchangeStatus = JSONProcessing(vArrCashRegister, GetReportOfdExchangeStatusStructure(), rMessage, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"));
			If vReportOfdExchangeStatus = Undefined Then
				Return False;	
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), , , , rMessage);
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage, pObj, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		Try	
			// Set cashier name
			vCashier = tcOnServer.cmGetCurrentUserAttribute();
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				// Set TIN
				vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
				vOperator = GetOperatorStructure(vCashierName, vEmployeeTIN);
				vCloseSession = GetCloseShiftStructure(vOperator);
			Else
				vCloseSession = GetCloseShiftStructure();	
			EndIf;
			
			vCloseStatus = JSONProcessing(vArrCashRegister, vCloseSession, rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));
			
			If vCloseStatus = Undefined And Left(rMessage,2) <> "73" Then
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));
			
			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(vArrCashRegister, rMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(rMessage);
				Return True;
			EndIf;
			// Open new session
			If Not vArrCashRegister.DoNotOpenNewSessionAfterZReport Then
				// Open session
				If ValueIsFilled(vCashier) Then
					vOperator = GetOperatorStructure(vCashierName, vEmployeeTIN);
					vOpenSession = GetOpenShiftStructure(vOperator);
				Else
					vOpenSession = GetOpenShiftStructure();	
				EndIf;
				
				vOpenStatus = JSONProcessing(vArrCashRegister, vOpenSession, rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));
				If vOpenStatus = Undefined And Left(rMessage,2) <> "83" Then
					Return False;
				EndIf;
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function CheckTimeDifference(pConnectionParameters, rMessage)
	#IF NOT WebClient THEN
		vStatusArr = JSONProcessing(pConnectionParameters, GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверьтеРазницуВоВремени'"));	
		If vStatusArr <> Undefined Then
			vStatus = vStatusArr[0].result.deviceStatus;
			vFRDate = XMLValue(Type("Date"),vStatus.currentDateTime);
			If BegOfDay(CurrentDate()) = BegOfDay(vFRDate) Then
				vTimeDiff = CurrentDate() - vFRDate;
				If vTimeDiff < 0 Then 
					vTimeDiff = -vTimeDiff;
				EndIf;
				If vTimeDiff > 300 Then // > 5 minutes
					// Set current time
					Return SetDeviceTime(pConnectionParameters, rMessage);
				EndIf;
			Else
				// Date is different, need to set correct date manually
				rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
				Return False;
			EndIf;
		Else
			Return False;
		EndIf;
	#ENDIF
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function SetDeviceTime(pConnectionParameters, rMessage)
	vCurDate = Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF='yyyy.MM.dd HH:mm:ss'");
	
	vSetDateTime = JSONProcessing(pConnectionParameters,GetSetDateTimeStructure(vCurDate), rMessage, NStr("en='CashRegister.SetDateTime'; de='CashRegister.SetDateTime'; ru='ККМ.УстановитеДатуИВремя'"));
	
	If vSetDateTime = Undefined Then
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Do report
			vXReportStatus = JSONProcessing(vArrCashRegister, GetXReportStructure(), rMessage, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"));
			
			If vXReportStatus = Undefined Then
				Return False;
			EndIf;
			// Log cash register operation
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), , , , rMessage);
			// Open drawer
			vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.OpenCashDrawer'; de='CashRegister.OpenCashDrawer'; ru='ККМ.ОткрытьЯщик'"));
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Not supported in this version of the cash register'; de = 'Nicht in dieser version der Kasse unterstützt'; ru = 'Не поддерживается в данной версии ККМ'"));
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPasswordKKM="", pOneCopyOnly = False) Export
	If TypeOf(pCashRegister) = Type("Structure") Then  
		vArrCashRegister = pCashRegister;
	Else 
		vArrCashRegister =  tcOnServer.cmGetAtributeAsArray(pCashRegister);
	EndIf;
	
	// Try to connect
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try	
			vItemsArray = Undefined;
			vItemsClientArr = Undefined;
			// Print all strings in the array
			PrintSlipLines(vItemsArray, vItemsClientArr, pSlipTextArr, vArrCashRegister, pOneCopyOnly);
			vArrayRequest = New Array();
			vArrayRequest.Add(GetNonFiscalChequeStructure(vItemsArray, False));
			vArrayRequest.Add(GetNonFiscalChequeStructure(vItemsClientArr, False));
			vPrintNonFiscal = JSONProcessing(vArrCashRegister, vArrayRequest, rMessage, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"));
			If vPrintNonFiscal = Undefined Then
				Return False;
			EndIf;
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(rItemsArr, rItemsClientArr, pSlipTextArr, pArrCashRegister, pOneCopyOnly = False)
	vArrCashRegister = pArrCashRegister;
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		GetTextStructure(rItemsArr, vStr);
	EndDo;
	
	If Not pOneCopyOnly Then
		// Print second slip for the client
		GetTextStructure(rItemsArr," ");
		GetTextStructure(rItemsArr, GetString("-8<--------------------------------------------------------------------",vArrCashRegister));
		GetTextStructure(rItemsArr," ");
		GetTextStructure(rItemsArr," ");
		GetTextStructure(rItemsArr," ");
		GetTextStructure(rItemsArr," ");
		
		GetTextStructure(rItemsClientArr, NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'"));
		
		For Each vStr In pSlipTextArr Do
			GetTextStructure(rItemsClientArr, vStr);
		EndDo;
	EndIf;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try			
			// Do cash income
			vCashIncomeStatus = JSONProcessing(vArrCashRegister, GetCashIncomeOrOutcomeStructure("cashIn",,pSum), rMessage, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"));
			
			If vCashIncomeStatus = Undefined Then
				Return False;	
			EndIf;
			
			vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"));
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try			
			// Do cash income
			vCashOutcomeStatus = JSONProcessing(vArrCashRegister, GetCashIncomeOrOutcomeStructure("cashOut",,pSum), rMessage, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"));
			
			If vCashOutcomeStatus = Undefined Then
				Return False;	
			EndIf;
			
			vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"));
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmOpenCashDrawer(rMessage, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Try to connect
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, True, rMessage) Then
		Return False;
	Else 
		// Open drawer
		vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.pmOpenCashDrawer'; de='CashRegister.pmOpenCashDrawer'; ru='ККМ.ОткрытьЯщик'"));
		If vOpenCashDrawerStatus = Undefined Then
			Return false;
		EndIf;		
	EndIf;
	Return True;
EndFunction // pmOpenCashDrawer

// -----------------------------------------------------------------------------
Function pmGetFDF(rMessage, pCashRegister) Export
	vFDF = Undefined;
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	
	vRegistrationInfo = JSONProcessing(vArrCashRegister, GetRegistrationInfoStructure(), rMessage, NStr("en='CashRegister.pmGetFDF'; de='CashRegister.pmGetFDF'; ru='ККМ.ПолучитьФФД'"));
	
	If vRegistrationInfo <> Undefined Then
		vDevice = vRegistrationInfo[0].result.device;
		
		If vDevice.ffdVersion = "1.2" Then
			vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2");	
		ElsIf vDevice.ffdVersion = "1.1" Then
			vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_1");					
		Else
			vFDF = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5");	
		EndIf;
	EndIf;
	Return vFDF;	
EndFunction // pmGetFDF

// -----------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage, pCashRegister) Export
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	// Set cash register time to the current one
	If Not SetDeviceTime(vArrCashRegister, rMessage) Then
		Return False;	
	EndIf;
	Return True;
EndFunction // pmSetDeviceTime

// -----------------------------------------------------------------------------
Function GetTaxationSystem(pObj, rTaxSystem = Undefined)
	rTaxSystem = Undefined;
	vTaxSystemChar = "";
	vPaymentSection = pObj.PaymentSection;
	If ValueIsFilled(vPaymentSection) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
	ElsIf TypeOf(pObj.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pObj.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) Then
				rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
				If ValueIsFilled(rTaxSystem) Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pObj.Company) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(pObj.Company, "TaxationSystem");
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemChar = "osn";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemChar = "usnIncome";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemChar = "usnIncomeOutcome";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemChar = "envd";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemChar = "esn";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemChar = "patent";
		EndIf;			
	EndIf;
	Return vTaxSystemChar;
EndFunction // GetTaxationSystem

// -----------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate = Undefined, pRowVATRate = Undefined, pDocObj = Undefined)
	vAtolTaxGroup = "none";
	
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		If TypeOf(pObj) = Type("FormDataStructure") Then
			rVATRate = pObj.VATRate;
		Else
			rVATRate = tcOnServer.cmGetAttributeByRef(pObj, "VATRate");
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vAtolTaxGroup;
	EndIf;
	
	vRateDate = Undefined;
	If TypeOf(pDocObj) = Type("FormDataStructure") And TypeOf(pDocObj.Ref) = Type("DocumentRef.Return") And ValueIsFilled(pDocObj.Payment) Then
		vRateDate = tcOnServer.cmGetAttributeByRef(pDocObj.Payment, "Date");
	EndIf;
	
	vVATRateParams = Undefined;
	If ValueIsFilled(vRateDate) Then
		vVATRateParams = tcCashRegisters.GetVATRateParams(rVATRate, vRateDate);
	EndIf;
	
	If vVATRateParams <> Undefined Then
		vTaxRate = vVATRateParams.TaxRate;
		vNoVAT = vVATRateParams.NoVAT;
		vTaxGroup = vVATRateParams.TaxGroup;
	Else
		vTaxRate = tcOnServer.cmGetAttributeByRef(rVATRate, "TaxRate");
		vNoVAT = tcOnServer.cmGetAttributeByRef(rVATRate, "NoVAT");
		vTaxGroup = tcOnServer.cmGetAttributeByRef(rVATRate, "TaxGroup");
	EndIf;
	
	If vNoVAT Then
		vAtolTaxGroup = "none";
	ElsIf vTaxRate = 0 Then
		vAtolTaxGroup = "vat0";
	ElsIf vTaxRate = 5 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat105";
		Else
			vAtolTaxGroup = "vat5";
		EndIf;
	ElsIf vTaxRate = 7 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat107";
		Else
			vAtolTaxGroup = "vat7";
		EndIf;
	ElsIf vTaxRate = 10 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat110";
		Else
			vAtolTaxGroup = "vat10";
		EndIf;
	ElsIf vTaxRate = 18 Then
		vAtolTaxGroup = "vat18";
	ElsIf vTaxRate = 20 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat120";
		Else
			vAtolTaxGroup = "vat20";
		EndIf;
	ElsIf vTaxRate = 22 Then
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat122";
		Else
			vAtolTaxGroup = "vat22";
		EndIf;
	Else
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat1" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		Else
			vAtolTaxGroup = "vat2" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		EndIf;
	EndIf;
	Return vAtolTaxGroup;
EndFunction // GetTaxGroup

// -----------------------------------------------------------------------------
Function GetPaymentMethodText(pCMTValue)
	If pCMTValue = PredefinedValue("Enum.ChequePaymentModes.Prepayment100") Then
		Return "fullPrepayment";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.Prepayment") Then
		Return "prepayment";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.Advance") Then
		Return "advance";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.FullSettlement") Then
		Return "fullPayment";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.PartialSettlementAndCredit") Then
		Return "partialPayment";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.TransferToCredit") Then
		Return "credit";
	ElsIf pCMTValue = PredefinedValue("Enum.ChequePaymentModes.PaymentOfCredit") Then
		Return "creditPayment";
	Else
		Return "fullPayment"; // full settlement by default
	EndIf;
EndFunction // GetPaymentMethodText

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, 
	pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101',
	pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pObj.CashRegister);
	vArrPaymentMethod = tcOnServer.cmGetAtributeAsArray(pObj.PaymentMethod);
	If Not CloseOpenCheque(vArrCashRegister, vArrCashRegister.DoNotOpenNewSessionAfterZReport, vArrCashRegister.IgnoreEndOfPaperError, rMessage) Then
		Return False;
	Else
		vTypeS = "";
		vIgnoreNonFiscalPrintErrorsS = Undefined;
		vOperatorS = Undefined; 
		vCorrectionTypeS = ""; 
		vCorrectionBaseNameS = ""; 
		vCorrectionBaseDateS = ""; 
		vCorrectionBaseNumberS = ""; 
		vElectronicallyS = Undefined; 
		vTaxationTypeS = ""; 
		vPaymentsPlaceS = ""; 
		vMachineNumberS = ""; 
		vClientInfoS = Undefined; 
		vCompanyInfoS = Undefined; 
		vAgentInfoS = Undefined; 
		vSupplierInfoS = Undefined; 
		vItemsS = Undefined; 
		vPaymentsS = Undefined; 
		vTaxesS = Undefined; 
		vTotalS = Undefined; 
		vPreItemsS = Undefined; 
		vPostItemsS = Undefined;
		vUseVAT18S = Undefined;
		vIsPrepayment = False;
		vResponseArray = New Array();
		// Cash register was connected
		Try
			
			If Not pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vTypeS = "sellReturn";
				Else
					vTypeS = "sell";
				EndIf;
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
					vTypeS = "sellReturnCorrection";
				Else
					vTypeS = "sellCorrection";
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And tcOnServer.cmGetAttributeByRef(pObj.PaymentMethod, "ElectronicChequeOnly") Then
				vElectronicallyS = True;
			Else
				vElectronicallyS = False;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vCorrectionTypeS = ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), "instruction", "self");
				vChequeAttributes.CorrectionType = pCorrectionType;
				
				vCorrectionBaseDateS = "";
				vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pObj.CorrectionOfIncorrectCheque And ValueIsFilled(pObj.Payment), tcOnServer.cmGetAttributeByRef(pObj.Payment, "Date"), '00010101'));
				If ValueIsFilled(vCorrectionDocumentDate) Then
					vCorrectionBaseDateS = Format(vCorrectionDocumentDate, "DF=yyyy.MM.dd");
					vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
				Else
					rMessage = NStr("en='The date of the corrected payment is not specified (the date when the wrong cheque was posted)!'; 
					|ru='Не указана дата совершения корректируемого расчета (дата, когда пробит неверный чек)!'; 
					|de='Das Datum der korrigierten Zahlung ist nicht angegeben (das Datum, an dem der falsche Scheck gebucht wurde)!'");
					Return False;
				EndIf;
				
				vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
				vCorrectionBaseNumberS = Right(vCorrectionDocumentNumber, 32);
				vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
			EndIf;
			
			// Print FPD of the base cheque if return
			If pObj.CorrectionOfIncorrectCheque Then
				vPayment = pObj.Payment;
				If ValueIsFilled(vPayment) Then
					// Get payment cheque attributes
					vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
					If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
						GetAddCheckDetailsStructure(vItemsS, vPaymentAttrs.ChequeFiscalNumber); 
					EndIf;
				EndIf;
			EndIf;
			
			// Set taxation system
			vTaxSystem = Undefined;
			vTaxSystemText = GetTaxationSystem(pObj, vTaxSystem);
			If Not IsBlankString(vTaxSystemText) Then
				vTaxationTypeS = vTaxSystemText;
				vChequeAttributes.TaxationSystem = vTaxSystem;
			EndIf;
			
			// Set cashier name
			vCashier = pObj.Author;
			If ValueIsFilled(vCashier) Then
				vCashierName = tcCashRegisters.GetCashierName(vCashier);
				If Not IsBlankString(vCashierName) Then
					vChequeAttributes.CashierName = vCashierName;
					
					// Set TIN
					vEmployeeTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vCashier, "TIN"));
					
					vOperatorS = GetOperatorStructure(vCashierName, vEmployeeTIN);
				EndIf;
			EndIf;
			
			// Payer name and TIN and EMail 
			vPayerName = "";
			vPayerTIN = "";
			vContact = "";
			vPayer = Undefined;
			If pSendPayerContactsToOFD = 0 Then	
				// Transfer client e-mail
				vEMail = "";
				If ValueIsFilled(TrimAll(pEmailToSendToOFD)) Then
					vEMail = TrimAll(pEmailToSendToOFD);	
				Else
					vPayer = Undefined;
					If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) Then
						If ValueIsFilled(pObj.Payer) Then
							vPayer = pObj.Payer;
						EndIf;
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
						EndIf;
					EndIf;
				EndIf;
				If ValueIsFilled(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vContact = vEMail;
				EndIf;
			ElsIf pSendPayerContactsToOFD = 1 Then
				// Transfer client Phone
				vPhone = "";
				If ValueIsFilled(TrimAll(pPhoneToSendToOFD)) Then
					vPhone = TrimAll(pPhoneToSendToOFD);	
				Else
					vPayer = Undefined;
					If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) Then
						If ValueIsFilled(pObj.Payer) Then
							vPayer = pObj.Payer;
						EndIf;
					EndIf;
					If ValueIsFilled(vPayer) Then
						If TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers") Then
							vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "Phone"));
						EndIf;
					EndIf;
				EndIf;
				vPhone = TrimAll(SMS.GetValidPhoneNumber(vPhone));
				If ValueIsFilled(vPhone) And Left(vPhone, 1) <> "+" Then
					vPhone = "+" + vPhone;	
				EndIf;
				If ValueIsFilled(vPhone) Then
					vContact = vPhone;
				EndIf;	
			EndIf;  
			
			tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			If IsBlankString(vPayerName) Or IsBlankString(vPayerTIN) Then
				vPayerName = "";
				vPayerTIN = "";		
			EndIf;
			
			vClientInfoS = GetClientInfoStructure(vContact, vPayerTIN, vPayerName);
			
			// Print slip if payment was made by credit card
			If vArrCashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					rItemsArr = Undefined;
					rItemsClientArr = Undefined;
					PrintSlipLines(rItemsArr, rItemsClientArr, tcOnServer.GetTextLinesArray(pObj.SlipText),vArrCashRegister);
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsArr, False));
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsClientArr, False));
				EndIf;
			EndIf;
			
			// Cheque folio header
			If vArrCashRegister.PrintFolioHeader Then
				PrintFolioHeader(vPreItemsS, pObj, vArrCashRegister);
			EndIf;
			
			// Print services
			If Not pIsCorrection Or pIsCorrection And vArrCashRegister.FiscalDataFormatVersions <> PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_0_5") Then
				If Not vArrCashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						// Begin format 1.05 item 
						vCashRegisterItemCode = "";
						// Commissioner mark
						If ValueIsFilled(vSrvRow.Service) Then
							vIsAgentService = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "IsAgentService");
							If vIsAgentService Then
								// Commissioner attribute
								vPrincipalType = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PrincipalType");
								vAgentInfo = GetAgentInfoStructure(vPrincipalType);
								// Principal
								vPrincipal = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "Principal");
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
									vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
									vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));; 
									If StrLen(vPrincipalTIN) = 10 Then
										vTINValue = vPrincipalTIN + "  ";
									Else
										vTINValue = vPrincipalTIN;
									EndIf;
									vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
								EndIf;
							EndIf;
							// Item code
							vCashRegisterItemCode = tcCashRegisters.GetBase64ItemCode(TrimAll(tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "CashRegisterItemCode")));
						EndIf;
						// Fill item attributes
						vPaymentSection = Undefined;
						vDepartment = 0;
						vName = "";
						If ValueIsFilled(vSrvRow.Service) Then
							vName = GetString(tcOnServer.cmGetServiceDescription(vSrvRow.Service), vArrCashRegister);
							vPaymentSection = tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "PaymentSection");
							If ValueIsFilled(vPaymentSection) Then
								vDepartment = tcOnServer.cmGetAttributeByRef(vPaymentSection, "Code");
							EndIf;
						EndIf;
						vItemPrice = vSrvRow.Price;
						vItemQuantity = vSrvRow.Quantity;
						tcCashRegisters.ChequeItemAttributesCorrection(vSrvRow.Amount, vItemQuantity, 3, vItemPrice, vItemQuantity);;
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) Then
							vTax = GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj);
						Else
							vTax = GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj);
						EndIf;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRAte, vSrvRow.VATSum);
						// Fill format 1.05 attributes and end item
						vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vSrvRow.Service, vSrvRow.PaymentSection));
						vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						
						vExciseSum = Undefined;
						If vPaymentObject = 2 Or vPaymentObject = 30 Or vPaymentObject = 31 Then
							// Fill excise value
							vExciseSum = tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vSrvRow.Service, "Volume"), vItemQuantity);
						EndIf;
						
						GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vSrvRow.Amount,,vDepartment, GetUnitPiece(vSrvRow.Service, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo,,, vExciseSum,,, vCashRegisterItemCode);
					EndDo;
				Else
					// Print number and sections
					If pObj.PaymentSections.Count() > 0 Then
						If Not vArrCashRegister.PrintFolioHeader Then
							GetTextStructure(vItemsS, "#" + TrimAll(pObj.Number)); 
						EndIf;
						vPSRows = tcCashRegisters.GetPrintableChequePositions(pObj, vIsPrepayment, vArrCashRegister.AlwaysUseAveragePrice);
						If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Print name, price and quantity
								vCashRegisterItemCode = "";
								vItemQuantity = 1;
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Commissioner attribute
										vPrincipalType = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType");
										vAgentInfo = GetAgentInfoStructure(vPrincipalType);
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));; 
											If StrLen(vPrincipalTIN) = 10 Then
												vTINValue = vPrincipalTIN + "  ";
											Else
												vTINValue = vPrincipalTIN;
											EndIf;
											vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue); 
										EndIf;
									EndIf;
									// Item code
									vCashRegisterItemCode = tcCashRegisters.GetBase64ItemCode(TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode")));
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vDepartment = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									Else
										vDepartment = 0;
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister);
									Else
										vName = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
									EndIf;
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									vName = GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vArrCashRegister);
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = vAmount;
									vItemQuantity = 1;
								Else
									vDepartment = 0;
									If vSectionAmount >=0 Then
										vName = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vName = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = vAmount;
									vItemQuantity = 1;
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								
								vExciseSum = Undefined;
								If vPaymentObject = 2 Or vPaymentObject = 30 Or vPaymentObject = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vExciseSum = tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Volume"), vItemQuantity);
									EndIf;
								EndIf;
								
								GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo,,, vExciseSum,,, vCashRegisterItemCode);
							EndDo;
						ElsIf Not vArrCashRegister.DoNotPrintPaymentSections Then
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Print name, price and quantity
								vCashRegisterItemCode = "";
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "IsAgentService");
									If vIsAgentService Then
										// Commissioner attribute
										vPrincipalType = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "PrincipalType");
										vAgentInfo = GetAgentInfoStructure(vPrincipalType);
										// Principal
										vPrincipal = tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Principal");
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "TIN"));
											vPrincipalName = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "LegacyName"));
											vPrincipalPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPrincipal, "Phone"));; 
											If StrLen(vPrincipalTIN) = 10 Then
												vTINValue = vPrincipalTIN + "  ";
											Else
												vTINValue = vPrincipalTIN;
											EndIf;
											vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue); 
										EndIf;
									EndIf;
									// Item code
									vCashRegisterItemCode = tcCashRegisters.GetBase64ItemCode(TrimAll(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "CashRegisterItemCode")));
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vDepartment = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									Else
										vDepartment = 0;
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vArrCashRegister);
									Else
										vName = GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vArrCashRegister);
									EndIf;
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = tcOnServer.cmGetAttributeByRef(vPSRow.PaymentSection, "Code");
									vName = GetString(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Code"), vArrCashRegister);
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = vAmount;
									vItemQuantity = 1;
								Else
									vDepartment = 0;
									If vSectionAmount >=0 Then
										vName = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vName = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									vItemPrice = vAmount;
									vItemQuantity = 1;
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
								// Fill format 1.05 attributes and end item
								vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								
								vExciseSum = Undefined;
								If vPaymentObject = 2 Or vPaymentObject = 30 Or vPaymentObject = 31 Then
									// Fill excise value
									If ValueIsFilled(vPSRow.ChequeService) Then
										vExciseSum = tcCashRegisters.GetChequeItemExciseValue(tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "ExciseDutyType"), pObj.Date, tcOnServer.cmGetAttributeByRef(vPSRow.ChequeService, "Volume"), vItemQuantity);
									EndIf;
								EndIf;
								
								GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo,,, vExciseSum,,, vCashRegisterItemCode);
							EndDo;
						Else
							vAmount = 0;
							vVATAmount = 0;
							pSum = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									Continue;
								Else
									pSum = pSum + vPSRow.Sum;
								EndIf;
								If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
									vAmount = vAmount - vPSRow.Sum;
									vVATAmount = vVATAmount - vPSRow.VATSum;
								Else
									vAmount = vAmount + vPSRow.Sum;
									vVATAmount = vVATAmount + vPSRow.VATSum;
								EndIf;
							EndDo;
							// Print name, price and quantity
							vDepartment = 0;
							vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
							vItemPrice = ?(vAmount < 0, -vAmount, vAmount);
							vItemQuantity = 1;
							// Add tax
							vVATRate = Undefined;
							vTax = GetTaxGroup(pObj, vVATRate, , pObj);
							tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >=0, vVATAmount, -vVATAmount));
							// Fill format 1.05 attributes and end item
							vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
							vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));							
							GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));	
						EndIf;
					Else
						vVATAmount = pObj.VATSum;
						If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
							vVATAmount = -vVATAmount;
						EndIf;
						// Print name, price and quantity
						vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						If Not vArrCashRegister.PrintFolioHeader Then
							GetTextStructure(vItemsS, "#" + TrimAll(pObj.Number));
						EndIf;
						vDepartment = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vDepartment = tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code");
							If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
								If vArrCashRegister.PrintFolioHeader Then
									vName = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								Else
									vName = GetString(TrimR(vName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
								EndIf;
							EndIf;
						EndIf;
						vItemQuantity = 1;
						vAmount = ?(pSum < 0, -pSum, pSum);
						vItemPrice = vAmount;
						// Add tax
						vVATRate = Undefined;
						vTax = GetTaxGroup(pObj, vVATRate, , pObj);
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
						// Fill format 1.05 attributes and end item
						vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
						vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If vArrCashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
					If vNoVAT Then
						GetTextStructure(vItemsS,GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'"), vArrCashRegister));
					Else
						GetTextStructure(vItemsS,GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ="), vArrCashRegister));
					EndIf;
				ElsIf vArrCashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					GetTextStructure(vItemsS,GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'"), vArrCashRegister));;
				EndIf;
			Else // Correction cheque
				vVATAmount = pObj.VATSum;
				If TypeOf(pObj.Ref) = Type("DocumentRef.Return") Then
					vVATAmount = -vVATAmount;
				EndIf;
				// Print name, price and quantity
				vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
				If Not vArrCashRegister.PrintFolioHeader Then
					GetTextStructure(vItemsS, "#" + TrimAll(pObj.Number));
				EndIf;
				vDepartment = 0;
				If ValueIsFilled(pObj.PaymentSection) Then
					vDepartment = tcOnServer.cmGetAttributeByRef(pObj.PaymentSection, "Code");
					If vArrCashRegister.PrintPaymentSectionNamesInCheques Then
						If vArrCashRegister.PrintFolioHeader Then
							vName = GetString(tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						Else
							vName = GetString(TrimR(vName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pObj.PaymentSection), vArrCashRegister);
						EndIf;
					EndIf;
				EndIf;
				vItemQuantity = 1;
				vItemPrice = ?(pSum < 0, -pSum, pSum);
				vAmount = vItemPrice;
				// Add tax
				vVATRate = Undefined;
				vTax = GetTaxGroup(pObj, vVATRate, , pObj);
				tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
				// Fill format 1.05 attributes and end item
				vPaymentObject = tcCashRegisters.GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pObj, Undefined, Undefined));
				vPaymentMethod = GetPaymentMethodText(tcCashRegisters.GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection)));
				GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined, vArrCashRegister),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				If pObj.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.AdvanceSettlement") Then
					vTypePayments = "2";
				ElsIf vArrPaymentMethod.IsByCash Then
					vTypePayments = "0";
				ElsIf vArrPaymentMethod.IsByCreditCard Or vArrPaymentMethod.IsByBankTransfer Or vArrPaymentMethod.IsViaInternetAcquiring Then
					vTypePayments = "1";
				Else
					vTypePayments = TrimAll(vArrPaymentMethod.CashRegisterChequeCloseType);
				EndIf;
			Else
				vTypePayments = "0";
			EndIf;
			vOpenDrawer = False;
			If vTypePayments = "0" Then
				vOpenDrawer = True;
			EndIf;
			GetPaymentStructure(vPaymentsS, vTypePayments, ?(pSum > 0, pSum, -pSum));
			
			// Get current cheque attributes
			If pSum < 0 Or pSum = 0 And TypeOf(pObjRef) = Type("DocumentRef.Return") Then
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
			Else
				vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
			EndIf;
			
			If pIsCorrection Then
				vResponse = GetCorrectionStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vOperatorS, vCorrectionTypeS, vCorrectionBaseNameS, vCorrectionBaseDateS, 
				vCorrectionBaseNumberS, vElectronicallyS, vUseVAT18S, vTaxationTypeS, vPaymentsPlaceS, vMachineNumberS, vClientInfoS, vCompanyInfoS, 
				vAgentInfoS, vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);
			Else
				vResponse = GetFiscalStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vElectronicallyS, vUseVAT18S, vTaxationTypeS, 
				vPaymentsPlaceS, vMachineNumberS, vOperatorS, vClientInfoS, vCompanyInfoS, vAgentInfoS, 
				vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);
			EndIf;
			vResponseArray.Add(vResponse);
			vChequeStatus = JSONProcessing(vArrCashRegister, vResponseArray, rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
			
			If vChequeStatus = Undefined Then
				Return False;
			EndIf;
			vfiscalParams = Undefined;
			For Each vCheque In vChequeStatus Do
				If vCheque.result <> Undefined Then
					If vCheque.result.Property("fiscalParams") Then
						vfiscalParams = vCheque.result.fiscalParams; 
						Break;
					EndIf;
				EndIf;
			EndDo;
			
			If vfiscalParams = Undefined Then
				Return False;	
			EndIf;
			
			If vfiscalParams.Property("fiscalDocumentSign") Then
				vChequeAttributes.ChequeFiscalNumber = vfiscalParams.fiscalDocumentSign;
			EndIf;
			If vfiscalParams.Property("fiscalDocumentNumber") Then
				vChequeAttributes.ChequeSequenceNumber = vfiscalParams.fiscalDocumentNumber;
			EndIf;
			#IF NOT WebClient THEN
				If vfiscalParams.Property("fiscalDocumentDateTime") Then
					vChequeAttributes.ChequeDateTime = XMLValue(Type("Date"), vfiscalParams.fiscalDocumentDateTime);
				EndIf;
			#ENDIF
			If vfiscalParams.Property("shiftNumber") Then
				vChequeAttributes.CashDay = vfiscalParams.shiftNumber;
			EndIf;
			If vfiscalParams.Property("fiscalReceiptNumber") Then
				vChequeAttributes.CashDayChequeNumber = vfiscalParams.fiscalReceiptNumber;
			EndIf;
			If vfiscalParams.Property("fnNumber") Then
				vChequeAttributes.FiscalStorageFactoryNumber = vfiscalParams.fnNumber;
			EndIf;
			
			// Log cash register operation
			vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
			NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
			NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.CashRegister, "Description")) + 
			NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,,vMessage);
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			
			// Open drawer
			If vOpenDrawer Then
				vOpenCashDrawerStatus = JSONProcessing(vArrCashRegister, GetOpenCashDrawerStructure(),rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
			EndIf;
			
			Return True;
		Except
			rMessage = ErrorDescription();
			tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"),,,, "Error description: " + rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Function GetUnitPiece(pService, pArrCashRegister)
	If pArrCashRegister.FiscalDataFormatVersions = PredefinedValue("Enum.FiscalDataFormatVersions.FDF_1_2") Then
		If ValueIsFilled(pService) Then
			vSUnit = tcOnServer.cmGetAttributeByRef(pService, "Unit");
			If IsBlankString(vSUnit) Or TrimAll(PredefinedValue("Catalog.Units.Piece")) = vSUnit Then
				Return 0;	
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Gram")) = vSUnit Then
				Return 10;
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Kilogram")) = vSUnit Then
				Return 11; 
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Litre")) = vSUnit Then
				Return 41; 
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Mililitre")) = vSUnit Then
				Return 40; 
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Night")) = vSUnit Then
				Return 70;
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Minute")) = vSUnit Then
				Return 72; 
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Hour")) = vSUnit Then
				Return 71;
			ElsIf TrimAll(PredefinedValue("Catalog.Units.Megabyte")) = vSUnit Then
				Return 81;    
			Else         
				Return 0;	
			EndIf; 	
		Else
			Return 255;	
		EndIf;  
	Else
		Return Undefined;
	EndIf;
EndFunction // GetUnitPiece

#Region JSONProcessing 

// -----------------------------------------------------------------------------
Function JSONProcessing(pConnectParameters, pResponse, rMessage, pFunc, vUUID = "")
	Try
		vStructureResponse = Undefined;
		AddResponse(pResponse, vStructureResponse);
		vResult = Undefined;
		vConnect = Connect(pConnectParameters, rMessage);
		If vConnect <> Undefined And vStructureResponse <> Undefined Then
			vUUID = vStructureResponse.uuid;
			vResourceAddress = GetResourceAddressByVer(pConnectParameters);
			vStatResponse = GetStatResponseFromWebServer(pConnectParameters, vConnect, vResourceAddress.Stat);
			If (pConnectParameters.VerWebService >= "10.7" And vStatResponse.Property("isblocked") And vStatResponse.isblocked = False) Or (vStatResponse.Property("is_blocked") And vStatResponse.is_blocked = False) Then
				vStatusCode = PostJSONToWebServer(vConnect, vStructureResponse, vResourceAddress.Response, pConnectParameters.DeviceIDInWebServer, pConnectParameters.VerWebService, pConnectParameters.WriteLogFile);
				If vStatusCode = 201 Then
					vResult = Wait(pConnectParameters.Timeout, vConnect, vUUID, pFunc, rMessage, vResourceAddress.Response, pConnectParameters.DeviceIDInWebServer, pConnectParameters.VerWebService);
				Else
					If vStatusCode = 400 Then 
						rMessage = NStr("en = 'Request format error (required fields not found, more than one fiscal operation in the task, json parsing failed)'; de = 'Abfrage-Formatfehler (erforderliche Felder wurden nicht gefunden, mehr als ein fiskalischer Vorgang im Auftrag, json konnte nicht analysiert werden)'; ru = 'Ошибка формата запроса (обязательные поля не найдены, больше одной фискальной операции в задании, не удалось разобрать json)'");
					ElsIf vStatusCode = 409 Then
						rMessage = NStr("en = 'The task with this uuid is already in the database'; de = 'Auftragswarteschlange gesperrt'; ru = 'Задание с таким uuid уже есть в БД'");	
					EndIf;
				EndIf;
			Else
				rMessage = NStr("en = 'The job queue is blocked'; de = 'Auftragswarteschlange gesperrt'; ru = 'Очередь заданий заблокирована'");
			EndIf;
		EndIf;
		vConnect = Undefined;
	Except
		rMessage = ErrorDescription();
		vResult = Undefined	
	EndTry;
	Return vResult;
EndFunction // JSONProcessing

// -----------------------------------------------------------------------------
Function GetJSONFromTheStructure(pStructure)
	vResult = Undefined;
	
	#IF NOT WebClient THEN
		
		vJSONSettings	= New JSONWriterSettings(JSONLineBreak.None);
		vJSONWriter 	= New JSONWriter;
		vJSONWriter.SetString(vJSONSettings);		
		JSON_MapToJSON(pStructure, vJSONWriter, Undefined);
		
		vResult = vJSONWriter.Close();
		
	#ENDIF
	
	Return vResult;
EndFunction // GetBaudRate

// -----------------------------------------------------------------------------
Procedure JSON_MapToJSON(pValues, rJSONWriter, pDateFormatString)
	
	If TypeOf(pValues) = Type("Map") OR TypeOf(pValues) = Type("Structure") Then
		rJSONWriter.WriteStartObject();
		For each vKeyAndValue in pValues Do
			If TypeOf(vKeyAndValue.Key) = Type("Number") Then
				rJSONWriter.WritePropertyName(Format(vKeyAndValue.Key,"NDS=.; NGS=; NZ=0; NG="));
			Else
				rJSONWriter.WritePropertyName(String(vKeyAndValue.Key));
			EndIf;			
			JSON_MapToJSON(vKeyAndValue.Value, rJSONWriter, pDateFormatString);		
		EndDo;
		rJSONWriter.WriteEndObject();
	ElsIf TypeOf(pValues) = Type("Array") Then
		rJSONWriter.WriteStartArray();
		For each vValue in pValues Do
			JSON_MapToJSON(vValue, rJSONWriter, pDateFormatString)
		EndDo;
		rJSONWriter.WriteEndArray();
	Else
		If TypeOf(pValues) = Type("Boolean") OR  TypeOf(pValues) = Type("Number") Then
			rJSONWriter.WriteValue(pValues);	
		ElsIf TypeOf(pValues) = Type("Date") AND pDateFormatString <> Undefined Then
			rJSONWriter.WriteValue(Format(pValues, pDateFormatString));
		Else			
			rJSONWriter.WriteValue(String(pValues));
		EndIf;
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
Function GetStructureFromTheJSON(pJSON)	
	vResult = Undefined;
	
	#IF NOT WebClient THEN
		
		If NOT IsBlankString(pJSON) Then
			vJSONReader = New JSONReader;
			vJSONReader.SetString(pJSON);
			vResult = ReadJSON(vJSONReader);
		EndIf;
		
	#ENDIF
	
	Return vResult;
EndFunction // GetBaudRate                  

// -----------------------------------------------------------------------------
Function PostJSONToWebServer(pConnect, pJSON, pResourceAddress, pDeviceID, pVerWebService, pWriteLogFile)
	vJSON =  GetJSONFromTheStructure(pJSON);
	If pWriteLogFile Then
		tcOnServer.cmWriteLogEventAtServer(NStr("en='CashRegister.Log'; de='CashRegister.Log'; ru='ККМ.Журнал'"),,,,vJSON);	
	EndIf;
	vHTTPRequest = New HTTPRequest();
	If pVerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + ?(pDeviceID <> "", "?deviceID=" + pDeviceID, "");
	Else
		vHTTPRequest.ResourceAddress = pResourceAddress;
	EndIf;
	vHTTPRequest.Headers.Insert("Content-Type", "application/json");
	vHTTPRequest.SetBodyFromString(vJSON, TextEncoding.UTF8);
	vResult = pConnect.Post(vHTTPRequest);
	Return vResult.StatusCode;
EndFunction // PostJSONToWebServer

// -----------------------------------------------------------------------------
Function GetResponseFromWebServer(pConnect, pUUID, pResourceAddress, pDeviceID, pVerWebService)
	vHTTPRequest = New HTTPRequest();
	If pVerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID + ?(pDeviceID <> "", "?deviceID=" + pDeviceID, "");
	Else
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID;	
	EndIf;
	vResult = pConnect.Get(vHTTPRequest);
	If vResult.StatusCode <> 200 Then
		Return Undefined;	
	EndIf;
	vResultStructure = GetStructureFromTheJSON(vResult.GetBodyAsString(TextEncoding.UTF8));
	Return vResultStructure.results;
EndFunction // GetResponseFromWebServer

// -----------------------------------------------------------------------------
Procedure DeleteResponseFromWebServer(pConnect, pUUID, pResourceAddress, pDeviceID, pVerWebService)
	vHTTPRequest = New HTTPRequest();
	If pVerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID + ?(pDeviceID <> "", "?deviceID=" + pDeviceID, "");
	Else
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID;	
	EndIf;
	pConnect.Delete(vHTTPRequest);
EndProcedure // DeleteResponseFromWebServer

// -----------------------------------------------------------------------------
Function GetStatResponseFromWebServer(pConnectParameters, pConnect, pResourceAddress)
	vHTTPRequest = New HTTPRequest();
	vHTTPRequest.ResourceAddress = pResourceAddress;
	vResult = pConnect.Get(vHTTPRequest);
	vResultStructure = GetStructureFromTheJSON(vResult.GetBodyAsString(TextEncoding.UTF8));
	Return vResultStructure
EndFunction // GetResponseFromWebServer

// -----------------------------------------------------------------------------
Function Connect(pConnectParameters, rMessage)
	// Try to load external component
	Try
		vAddress = StrSplit(pConnectParameters.Address, ":", False);
		If vAddress.Count() > 1 Then
			vConnect = New HTTPConnection(vAddress[0], Number(vAddress[1]), pConnectParameters.LoginWebServer, pConnectParameters.PasswordWebServer);
		Else
			vConnect = New HTTPConnection(pConnectParameters.Address,, pConnectParameters.LoginWebServer, pConnectParameters.PasswordWebServer);	
		EndIf;
		Return vConnect;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure AddResponse(pResponse, rStructureResponse)
	If TypeOf(rStructureResponse) = Type("Structure") Then
		If rStructureResponse.Property("uuid") And rStructureResponse.Property("request") Then
			If ValueIsFilled(rStructureResponse.uuid) And TypeOf(rStructureResponse.request) = Type("Array") Then
				rStructureResponse.request.Add(pResponse);	
			Else
				vRequests = new Array();
				vRequests.Add(pResponse);
				rStructureResponse = New Structure("uuid, request", New UUID(), vRequests);	
			EndIf;
		Else
			vRequests = new Array();
			vRequests.Add(pResponse);
			rStructureResponse = New Structure("uuid, request", New UUID(), vRequests);	
		EndIf;
	Else 
		rStructureResponse = New Structure("uuid, request", New UUID(), pResponse);
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
Function Wait(pMilliseconds, pConnect, pUUID, pFunc, rMessage, pResourceAddress, pDeviceID, pVerWebService)
	vSeconds = ?(pMilliseconds / 1000 < 10, 10, Round(pMilliseconds / 1000)); 
	vCheckReady = False;
	vCheckWait = False;
	vInProgress = True;
	vCheckError = False;
	vResultArray = Undefined;
	vCurTime = tcOnServer.cmGetServerCurrentSessionDate();
	vEndTime = vCurTime + vSeconds;
	While vCurTime <= vEndTime Or vInProgress  Do
		tcOnServer.Wait(1);
		vResult = GetResponseFromWebServer(pConnect, pUUID, pResourceAddress, pDeviceID, pVerWebService);
		vCurTime = tcOnServer.cmGetServerCurrentSessionDate();
		If vResult <> Undefined Then
			For Each vResponse In vResult Do
				If vResponse.status = "ready" Then
					vCheckReady = True;
					vCheckError = False;
					vInProgress = False;
					vCheckWait = False;
				ElsIf vResponse.status = "error" Or vResponse.status = "blocked" Or vResponse.status = "interrupted" Then
					If pVerWebService >= "10.7" Then
						rMessage = TrimAll(vResponse.error.code) + ": " + vResponse.error.description;
						tcOnServer.cmWriteLogEventAtServer(pFunc,,,,"Result code: " + vResponse.error.code + ", result description: " + vResponse.error.description);
					Else
						rMessage = TrimAll(vResponse.errorCode) + ": " + vResponse.errorDescription;
						tcOnServer.cmWriteLogEventAtServer(pFunc,,,,"Result code: " + vResponse.errorCode + ", result description: " + vResponse.errorDescription);
					EndIf;
					vCheckReady = False;
					vCheckError = True;
					vCheckWait = False;
					vInProgress = False;
					Break;
				ElsIf vResponse.status = "wait" Then
					vCheckReady = False;
					vCheckError = False;
					vCheckWait = True;
					vInProgress = False;
				ElsIf vResponse.status = "inProgress" Then
					vCheckReady = False;
					vCheckError = False;
					vCheckWait = False;
					vInProgress = True;
				Else
					vCheckReady = False;
					vCheckError = True;
					vCheckWait = False;
					vInProgress = False;
				EndIf;
			EndDo;
		Else 
			Break;
		EndIf;
		If vCheckReady Then
			vResultArray = vResult;
			Break;	
		ElsIf vCheckError Then
			Break;	
		EndIf;
	EndDo;
	If vCheckWait Then
		DeleteResponseFromWebServer(pConnect, pUUID, pResourceAddress, pDeviceID, pVerWebService);
		rMessage = NStr("en = 'The waiting time for the task to start has been exceeded, and the task has been canceled'; de = 'Das Zeitlimit für den Start des tasks wurde überschritten, der Task wurde abgebrochen'; ru = 'Превышено время ожидания начала выполнения задания, задание было отменено'");
		Return Undefined;
	EndIf;
	Return vResultArray;
EndFunction // Wait

// -----------------------------------------------------------------------------
Function GetResourceAddressByVer(pConnectParameters)
	vStructure = New Structure("Response, Stat");
	If pConnectParameters.VerWebService >= "10.7" Then
		vStructure.Response = "/api/v2/requests";
		vStructure.Stat = "/api/v2/getRequestsQueueStatus" + ?(pConnectParameters.DeviceIDInWebServer <> "", "?deviceID=" + pConnectParameters.DeviceIDInWebServer, "");
	Else
		vStructure.Response = "/requests/";
		vStructure.Stat = "/stat/requests";	
	EndIf;
	Return vStructure;
EndFunction // GetResourceAddressByVer

#EndRegion
