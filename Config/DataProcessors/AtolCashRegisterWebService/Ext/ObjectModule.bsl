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
	If Not IsBlankString(pVatin) Then
		vBody.Insert("vatin", pVatin);
	EndIf;
	If Not IsBlankString(pName) Then
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
	vBody = New Structure();
	vPhonesArray = New Array();
	If TypeOf(pPhones) <> Type("String") Then
		For Each vMoneyTransferOperatorPhone In pPhones Do
			vPhonesArray.Add(vMoneyTransferOperatorPhone);	
		EndDo;
	Else
		vPhonesArray.Add(pPhones);	
	EndIf;
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
	pAdditionalAttribute = "", pAdditionalAttributePrint = Undefined, pExciseSum = Undefined, pCountryCode = "", pCustomsDeclaration = "")
	
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
	pCorrectionBaseNumber = "", pElectronically = Undefined, pTaxationType = "", pPaymentsPlace = "", pMachineNumber = "", pClientInfo = Undefined, pCompanyInfo = Undefined, 
	pAgentInfo = Undefined, pSupplierInfo = Undefined, pItems, pPayments, pTaxes = Undefined, pTotal = Undefined, pPreItems = Undefined, pPostItems = Undefined)
	
	Correction = New Structure();
	Correction.Insert("type", pType);
	If pIgnoreNonFiscalPrintErrors <> Undefined Then
		Correction.Insert("ignoreNonFiscalPrintErrors", pIgnoreNonFiscalPrintErrors);	
	EndIf;
	If pOperator <> Undefined Then
		Correction.Insert("operator", pOperator.operator);	
	EndIf;
	If ValueIsFilled(pCorrectionType) Then
		Correction.Insert("correctionType", pCorrectionType);	
	EndIf;
	If ValueIsFilled(pCorrectionBaseName) Then
		Correction.Insert("correctionBaseName", pCorrectionBaseName);	
	EndIf;
	If ValueIsFilled(pCorrectionBaseDate) Then
		Correction.Insert("correctionBaseDate", pCorrectionBaseDate);	
	EndIf;
	If ValueIsFilled(pCorrectionBaseNumber) Then
		Correction.Insert("correctionBaseNumber", pCorrectionBaseNumber);	
	EndIf;
	If pElectronically <> Undefined Then
		Correction.Insert("electronically", pElectronically);	
	EndIf;
	If ValueIsFilled(pTaxationType) Then
		Correction.Insert("taxationType", pTaxationType);	
	EndIf;
	If ValueIsFilled(pPaymentsPlace) Then
		Correction.Insert("paymentsPlace", pPaymentsPlace);	
	EndIf;
	If ValueIsFilled(pMachineNumber) Then
		Correction.Insert("machineNumber", pMachineNumber);	
	EndIf;
	If pClientInfo <> Undefined Then
		Correction.Insert("clientInfo", pClientInfo.clientInfo);	
	EndIf;
	If pCompanyInfo <> Undefined Then
		Correction.Insert("companyInfo", pCompanyInfo.companyInfo);	
	EndIf;
	If pAgentInfo <> Undefined Then
		Correction.Insert("agentInfo", pAgentInfo.agentInfo);	
	EndIf;
	If pSupplierInfo <> Undefined Then
		Correction.Insert("supplierInfo", pSupplierInfo.supplierInfo);	
	EndIf;
		Correction.Insert("items", pItems.items);	
		Correction.Insert("payments", pPayments.payments);	
	If pTaxes <> Undefined Then
		Correction.Insert("taxes", pTaxes);	
	EndIf;
	If pTotal <> Undefined Then
		Correction.Insert("total", pTotal);	
	EndIf;
	If pPreItems <> Undefined Then
		Correction.Insert("preItems", pPreItems.items);	
	EndIf;
	If pPostItems <> Undefined Then
		Correction.Insert("postItems", pPostItems.items);	
	EndIf;
	Return Correction;
EndFunction // GetCorrectionStructure

#EndRegion

#Region JSONProcessing 

// -----------------------------------------------------------------------------
Function JSONProcessing(pResponse, rMessage, pFunc, vUUID = "")
	vStructureResponse = Undefined;
	AddResponse(pResponse, vStructureResponse);
	vResult = Undefined;
	vConnect = Connect(rMessage);
	If vConnect <> Undefined And vStructureResponse <> Undefined Then
		vUUID = vStructureResponse.uuid; 
		vResourceAddress = GetResourceAddressByVer();
		vStatResponse = GetStatResponseFromWebServer(vConnect, vResourceAddress.Stat);
		If (CashRegister.VerWebService >= "10.7" And vStatResponse.Property("isblocked") And vStatResponse.isblocked = False) Or (vStatResponse.Property("is_blocked") And vStatResponse.is_blocked = False)Then
			vStatusCode = PostJSONToWebServer(vConnect, vStructureResponse, vResourceAddress.Response);
			If vStatusCode = 201 Then
				vResult = Wait(CashRegister.Timeout, vConnect, vUUID, pFunc, rMessage, vResourceAddress.Response);
			Else
				If vStatusCode = 400 Then 
					ProcessResultCode(, 400, NStr("en = 'Request format error (required fields not found, more than one fiscal operation in the task, json parsing failed)'; de = 'Abfrage-Formatfehler (erforderliche Felder wurden nicht gefunden, mehr als ein fiskalischer Vorgang im Auftrag, json konnte nicht analysiert werden)'; ru = 'Ошибка формата запроса (обязательные поля не найдены, больше одной фискальной операции в задании, не удалось разобрать json)'"),pFunc, rMessage);
				ElsIf vStatusCode = 409 Then
					ProcessResultCode(, 409, NStr("en = 'The task with this uuid is already in the database'; de = 'Auftragswarteschlange gesperrt'; ru = 'Задание с таким uuid уже есть в БД'"),pFunc, rMessage);
				EndIf;
			EndIf;
		Else
			ProcessResultCode(,, NStr("en = 'The job queue is blocked'; de = 'Auftragswarteschlange gesperrt'; ru = 'Очередь заданий заблокирована'"),pFunc, rMessage);
		EndIf;
	EndIf;
	vConnect = Undefined;
	Return vResult;
EndFunction // JSONProcessing

// -----------------------------------------------------------------------------
Function GetJSONFromTheStructure(pStructure)
	vResult = Undefined;

	vJSONSettings	= New JSONWriterSettings(JSONLineBreak.None);
	vJSONWriter 	= New JSONWriter;
	vJSONWriter.SetString(vJSONSettings);		
	JSON_MapToJSON(pStructure, vJSONWriter, Undefined);
	
	vResult = vJSONWriter.Close();
	
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
	
	If NOT IsBlankString(pJSON) Then
		vJSONReader = New JSONReader;
		vJSONReader.SetString(pJSON);
		vResult = ReadJSON(vJSONReader);
	EndIf;
	
	Return vResult;
EndFunction // GetBaudRate                  

// -----------------------------------------------------------------------------
Function PostJSONToWebServer(pConnect, pJSON, pResourceAddress)
	vJSON =  GetJSONFromTheStructure(pJSON);
	vHTTPRequest = New HTTPRequest();
	If CashRegister.VerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + ?(CashRegister.DeviceIDInWebServer <> "", "?deviceID=" + CashRegister.DeviceIDInWebServer, "");
	Else
		vHTTPRequest.ResourceAddress = pResourceAddress;
	EndIf;
	vHTTPRequest.Headers.Insert("Content-Type", "application/json");
	vHTTPRequest.SetBodyFromString(vJSON, TextEncoding.UTF8);
	vResult = pConnect.Post(vHTTPRequest);
	Return vResult.StatusCode;
EndFunction // PostJSONToWebServer

// -----------------------------------------------------------------------------
Function GetResponseFromWebServer(pConnect, pUUID, pResourceAddress)
	vHTTPRequest = New HTTPRequest();
	If CashRegister.VerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID + ?(CashRegister.DeviceIDInWebServer <> "", "?deviceID=" + CashRegister.DeviceIDInWebServer, "");
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
Procedure DeleteResponseFromWebServer(pConnect, pUUID, pResourceAddress)
	vHTTPRequest = New HTTPRequest();
	If CashRegister.VerWebService >= "10.7" Then
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID + ?(CashRegister.DeviceIDInWebServer <> "", "?deviceID=" + CashRegister.DeviceIDInWebServer, "");
	Else
		vHTTPRequest.ResourceAddress = pResourceAddress + "/" + pUUID;	
	EndIf;
	pConnect.Delete(vHTTPRequest);
EndProcedure // DeleteResponseFromWebServer

// -----------------------------------------------------------------------------
Function GetStatResponseFromWebServer(pConnect, pResourceAddress)
	vHTTPRequest = New HTTPRequest();
	vHTTPRequest.ResourceAddress = pResourceAddress;
	vResult = pConnect.Get(vHTTPRequest);
	vResultStructure = GetStructureFromTheJSON(vResult.GetBodyAsString(TextEncoding.UTF8));
	Return vResultStructure
EndFunction // GetResponseFromWebServer

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Try to load external component
	Try
		vAddress = StrSplit(CashRegister.Address, ":", False);
		If vAddress.Count() > 1 Then
			vConnect = New HTTPConnection(vAddress[0], Number(vAddress[1]), CashRegister.LoginWebServer, CashRegister.PasswordWebServer);
		Else
			vConnect = New HTTPConnection(CashRegister.Address,, CashRegister.LoginWebServer, CashRegister.PasswordWebServer);	
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
Function Wait(pMilliseconds, pConnect, pUUID, pFunc, rMessage, pResourceAddress)
	vSeconds = ?(pMilliseconds / 1000 < 10, 10, Round(pMilliseconds / 1000)); 
	vCheckReady = False;
	vCheckWait = False;
	vInProgress = True;
	vCheckError = False;
	vResultArray = Undefined;
	vCurTime = CurrentSessionDate();
	vEndTime = vCurTime + vSeconds;
	While vCurTime <= vEndTime Or vInProgress  Do
		cmWait(1);
		vResult = GetResponseFromWebServer(pConnect, pUUID, pResourceAddress);
		vCurTime = CurrentSessionDate();
		If vResult <> Undefined Then
			For Each vResponse In vResult Do
				If vResponse.status = "ready" Then
					vCheckReady = True;
					vCheckError = False;
					vInProgress = False;
					vCheckWait = False;
				ElsIf vResponse.status = "error" Or vResponse.status = "blocked" Or vResponse.status = "interrupted" Then
					ProcessResultCode(vResponse,,,pFunc, rMessage);  
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
		DeleteResponseFromWebServer(pConnect, pUUID, pResourceAddress);
		ProcessResultCode(,,NStr("en = 'The waiting time for the task to start has been exceeded, and the task has been canceled'; de = 'Das Zeitlimit für den Start des tasks wurde überschritten, der Task wurde abgebrochen'; ru = 'Превышено время ожидания начала выполнения задания, задание было отменено'"),pFunc, rMessage);
		Return Undefined;
	EndIf;
	Return vResultArray;
EndFunction // Wait

// -----------------------------------------------------------------------------
Function GetResourceAddressByVer()
	vStructure = New Structure("Response, Stat");
	If CashRegister.VerWebService >= "10.7" Then
		vStructure.Response = "/api/v2/requests";
		vStructure.Stat = "/api/v2/getRequestsQueueStatus" + ?(CashRegister.DeviceIDInWebServer <> "", "?deviceID=" + CashRegister.DeviceIDInWebServer, "");
	Else
		vStructure.Response = "/requests/";
		vStructure.Stat = "/stat/requests";	
	EndIf;
	Return vStructure; 
EndFunction // GetResourceAddressByVer

#EndRegion

// -----------------------------------------------------------------------------
Procedure ProcessResultCode(pResponse = Undefined, pErrorCode = Undefined, pErrorDescription = "",  pFunction, rMessage)
	If pResponse <> Undefined Then
		rMessage = TrimAll(pResponse.errorDescription);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Result code: " + pResponse.errorCode + ", result description: " + rMessage);
	Else
		rMessage = TrimAll(pErrorDescription);
		WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, ?(pErrorCode <> Undefined, "Result code: " + pErrorCode + ",", "") + ", result description: " + rMessage);
	EndIf;
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
EndProcedure // ProcessResultCode

// -----------------------------------------------------------------------------
Procedure ProcessException(pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, CashRegister.Metadata(), CashRegister, "Error description: " + rMessage);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Procedure LogCashPayment(pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru = 'По платежу №'; en = 'For payment N'; de = 'For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru = ' по ККМ '; en = ' by cash register '; de = ' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru = ' пробит кассовый чек'; en = ' cheque was issued'; de = ' cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPayment

// -----------------------------------------------------------------------------
Procedure LogCashPaymentAnnulation(pFunction, pObj, pChequeAttributes = Undefined)
	vMessage = NStr("ru='По платежу №'; en='For payment N'; de='For payment N'") + TrimAll(pObj.Number) + 
	           NStr("en=' with sum ';ru=' на сумму ';de=' für einen Betrag von '") + Format(pObj.Sum, "ND=17; NFD=2") + 
	           NStr("ru=' по ККМ '; en=' by cash register '; de=' by cash register '") + TrimAll(CashRegister) + 
	           NStr("ru=' пробит кассовый чек аннуляции'; en=' storno cheque was issued'; de=' storno cheque was issued'");
	WriteLogEvent(pFunction, EventLogLevel.Information, pObj.Metadata(), pObj, vMessage);
	If pChequeAttributes <> Undefined Then
		tcCashRegisters.WriteChequeAttributes(pChequeAttributes);
	EndIf;
EndProcedure // LogCashPaymentAnnulation

// -----------------------------------------------------------------------------
Function GetString(pStr)
	vChequeWidth = CashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// -----------------------------------------------------------------------------
Function CloseOpenCheque(pOpenSessionIfClosed = False, rMessage)
	vStatusArr = JSONProcessing(GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.CloseOpenCheque'; de='CashRegister.CloseOpenCheque'; ru='ККМ.ЗакрытьОткрытыйЧек'"));	
	If vStatusArr <> Undefined Then
		vStatus = vStatusArr[0].result.deviceStatus;
		If vStatus.paperPresent = False Then
			rMessage = NStr("en='Cheque ribbon is over!'; de='Scheck Band ist vorbei!'; ru='В ККМ закончилась бумага!'");
			Return False;
		EndIf;
		If pOpenSessionIfClosed And CashRegister.DoNotOpenNewSessionAfterZReport Then
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
				vOpenStatus = JSONProcessing(vOpenSession, rMessage, NStr("en='CashRegister.OpenShift'; de='CashRegister.OpenShift'; ru='ККМ.ОткрытиеСмены'"));
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
		rVATRate = pObj.VATRate;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vAtolTaxGroup;
	EndIf;
	
	vRateDate = Undefined;
	If (TypeOf(pDocObj) = Type("DocumentObject.Return") Or TypeOf(pDocObj) = Type("DocumentRef.Return")) And ValueIsFilled(pDocObj.Payment) Then
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
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	// Try to connect
	vStatusArr = JSONProcessing(GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.pmIsReadyToPrint'; de='CashRegister.pmIsReadyToPrint'; ru='ККМ.ГотовКПечати'"));
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
		If vStatus.paperPresent = False Then
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
Function pmCheckConnection(rMessage) Export
	// Try to connect
	vStatusArr = JSONProcessing(GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.pmIsReadyToPrint'; de='CashRegister.pmIsReadyToPrint'; ru='ККМ.ГотовКПечати'"));
	If vStatusArr = Undefined Then
		Return False;
	Else // Cash register was connected
		vStatus = vStatusArr[0].result.deviceStatus;
		If vStatus.shift = "expired" Then
			rMessage = NStr("ru='Смена превысила 24 часа!'; en='24 hours open session limit exceeded!'; de='24 hours open session limit exceeded!'");
			Return False;
		EndIf;
		// Check paper
		If vStatus.paperPresent = False Then
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
EndFunction // pmCheckConnection

// -----------------------------------------------------------------------------
Function pmOpenCashDrawer(rMessage) Export
	// Open drawer
	vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.pmOpenCashDrawer'; de='CashRegister.pmOpenCashDrawer'; ru='ККМ.ОткрытьЯщик'"));
	If vOpenCashDrawerStatus = Undefined Then
		Return false;
	EndIf;		
	Return True;
EndFunction // pmOpenCashDrawer

// -----------------------------------------------------------------------------
Function pmGetFDF(rMessage, pCashRegister) Export
	vFDF = Undefined;
	vArrCashRegister = tcOnServer.cmGetAtributeAsArray(pCashRegister);
	
	vRegistrationInfo = JSONProcessing(GetRegistrationInfoStructure(), rMessage, NStr("en='CashRegister.pmGetFDF'; de='CashRegister.pmGetFDF'; ru='ККМ.ПолучитьФФД'"));
	
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
Function CheckTimeDifference(rMessage)
	vStatusArr = JSONProcessing(GetDeviceStatusStructure(), rMessage, NStr("en='CashRegister.CheckTimeDifference'; de='CashRegister.CheckTimeDifference'; ru='ККМ.ПроверьтеРазницуВоВремени'"));	
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
				Return SetDeviceTime(rMessage);
			EndIf;
		Else
			// Date is different, need to set correct date manually
			rMessage = NStr("en='Check date in the cash register!'; de='Überprüfen Datum im Kasse!'; ru='Проверьте дату в ККМ!'");
			Return False;
		EndIf;
	Else
		Return False;
	EndIf;
	Return True;
EndFunction // CheckTimeDifference

// -----------------------------------------------------------------------------
Function SetDeviceTime(rMessage)
	vCurDate = Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF='yyyy.MM.dd HH:mm:ss'");

	vSetDateTime = JSONProcessing(GetSetDateTimeStructure(vCurDate), rMessage, NStr("en='CashRegister.SetDateTime'; de='CashRegister.SetDateTime'; ru='ККМ.УстановитеДатуИВремя'"));
	
	If vSetDateTime = Undefined Then
		Return False;
	EndIf;
	Return True;
EndFunction // SetDeviceTime

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
Procedure PrintFolioHeader(rItemsArr, pObj)
	// Header start delimeter
	GetTextStructure(rItemsArr, GetString("-----------------------------------------------------------------------"));
	// Folio #                                                                    
	vFolioRef = pObj.Folio;
	vFolioNumber = tcOnServer.cmGetAttributeByRef(vFolioRef, "Number");
	GetTextStructure(rItemsArr, GetString(NStr("ru='Фолио № '; en='Folio # '; de='Folio Nr. '") + tcOnServer.GetDocumentNumberPresentation(vFolioNumber)));
	// Room
	If Not CashRegister.DoNotPrintRoom Then
		GetTextStructure(rItemsArr, GetString(NStr("en='Room  : ';ru='Номер : ';de='Zimmer:'") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Room"), "Description")))); 
	EndIf;
	// Guest
	If Not CashRegister.DoNotPrintClient Then
		If (TypeOf(pObj.Ref) = Type("DocumentRef.Payment") Or TypeOf(pObj.Ref) = Type("DocumentRef.Return")) And ValueIsFilled(pObj.Payer) Then
			GetTextStructure(rItemsArr, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.Payer, "Description"))));
		Else
			GetTextStructure(rItemsArr, GetString(NStr("en='Client: ';ru='Клиент: ';de='Kunde : '") + TrimAll(tcOnServer.cmGetAttributeByRef(tcOnServer.cmGetAttributeByRef(vFolioRef, "Client"), "Description"))));
		EndIf;
	EndIf;
	// Guest group
	GetTextStructure(rItemsArr, GetString(NStr("en='Group : ';ru='Группа: ';de='Gruppe: '") + TrimAll(tcOnServer.cmGetAttributeByRef(pObj.GuestGroup, "Code")))); 
	// Document                                                                
	GetTextStructure(rItemsArr, GetString(NStr("ru = 'Док.  № '; en='Doc.  # '; de='Dok.  Nr. '") + tcOnServer.GetDocumentNumberPresentation(pObj.Number)));
	// Header end delimeter
	GetTextStructure(rItemsArr, GetString("-----------------------------------------------------------------------")); 
EndProcedure // PrintFolioHeader

// -----------------------------------------------------------------------------
Procedure PrintSlipLines(rItemsArr, rItemsClientArr, pSlipTextArr)
	// Print first slip for the hotel
	For Each vStr In pSlipTextArr Do
		GetTextStructure(rItemsArr, vStr);
	EndDo;
	// Print second slip for the client
	GetTextStructure(rItemsArr," ");
	GetTextStructure(rItemsArr, GetString("-8<--------------------------------------------------------------------"));
	GetTextStructure(rItemsArr," ");
	GetTextStructure(rItemsArr," ");
	GetTextStructure(rItemsArr," ");
	GetTextStructure(rItemsArr," ");
	
	GetTextStructure(rItemsClientArr, NStr("ru='ДЛЯ КЛИЕНТА'; en='FOR THE CLIENT'; de='FÜR DEN KUNDEN'"));

	For Each vStr In pSlipTextArr Do
		GetTextStructure(rItemsClientArr, vStr);
	EndDo;
EndProcedure // PrintSlipLines

// -----------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage) Export
	// Cash register was connected
	Try
		// Set cash register time to the current one
		vResult = SetDeviceTime(rMessage);
	Except
		rMessage = ErrorDescription();
		ProcessException(NStr("en='CashRegister.SetDeviceTime'; de='CashRegister.SetDeviceTime'; ru='ККМ.УстановкаВремени'"), rMessage);
		vResult = False;
	EndTry;
	Return vResult;
EndFunction // pmSetDeviceTime

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage) Export
	If Not CloseOpenCheque(True, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try			
			// Do cash income
			vCashIncomeStatus = JSONProcessing(GetCashIncomeOrOutcomeStructure("cashIn",,pSum), rMessage, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"));
			
			If vCashIncomeStatus = Undefined Then
				Return False;	
			EndIf;
			
			vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"));
			
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintCashIncome'; de='CashRegister.PrintCashIncome'; ru='ККМ.ПечатьЧекаВнесенияДенег'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage) Export
	If Not CloseOpenCheque(True, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try			
			// Do cash income
			vCashOutcomeStatus = JSONProcessing(GetCashIncomeOrOutcomeStructure("cashOut",,pSum), rMessage, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"));
			
			If vCashOutcomeStatus = Undefined Then
				Return False;	
			EndIf;
			
			vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"));
			
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintCashOutcome'; de='CashRegister.PrintCashOutcome'; ru='ККМ.ПечатьЧекаИнкассации'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage) Export
	// Try to connect
	If Not CloseOpenCheque(,rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try
			// Do report
			vXReportStatus = JSONProcessing(GetXReportStructure(), rMessage, NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"));
			
			If vXReportStatus = Undefined Then
				Return False;
			EndIf;
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.OpenCashDrawer'; de='CashRegister.OpenCashDrawer'; ru='ККМ.ОткрытьЯщик'"));

			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintDeviceXReport'; de='CashRegister.PrintDeviceXReport'; ru='ККМ.ПечатьХОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage) Export
	tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Not supported in this version of the cash register'; de = 'Nicht in dieser version der Kasse unterstützt'; ru = 'Не поддерживается в данной версии ККМ'"));
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage) Export
	If Not CloseOpenCheque(, rMessage) Then
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
			
			vCloseStatus = JSONProcessing(vCloseSession, rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));
			
			If vCloseStatus = Undefined And Left(rMessage,2) <> "73" Then
				Return False;
			EndIf;
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			// Open drawer
			vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(), rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));

 			// Check time difference between workstation and cash register and correct 
			// device time if difference is more then 5 minutes
			If Not CheckTimeDifference(rMessage) Then
				tcCommonFunctionOnClientServer.TextMessage(rMessage);
				Return True;
			EndIf;
			// Open new session
			If Not CashRegister.DoNotOpenNewSessionAfterZReport Then
				// Open session
				If ValueIsFilled(vCashier) Then
					vOperator = GetOperatorStructure(vCashierName, vEmployeeTIN);
					vOpenSession = GetOpenShiftStructure(vOperator);
				Else
					vOpenSession = GetOpenShiftStructure();	
				EndIf;
				
				vOpenStatus = JSONProcessing(vOpenSession, rMessage, NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"));
				If vOpenStatus = Undefined And Left(rMessage,2) <> "83" Then
					Return False;
				EndIf;
			EndIf;
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintDeviceZReport'; de='CashRegister.PrintDeviceZReport'; ru='ККМ.ПечатьZОтчетаПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage) Export
	If Not CloseOpenCheque(, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try
			vReportOfdExchangeStatus = JSONProcessing(GetReportOfdExchangeStatusStructure(), rMessage, NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"));
			If vReportOfdExchangeStatus = Undefined Then
				Return False;	
			EndIf;
			// Log cash register operation
			WriteLogEvent(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), EventLogLevel.Information, CashRegister.Metadata(), CashRegister, rMessage);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintCurrentStateOfCalculationsReport'; de='CashRegister.PrintCurrentStateOfCalculationsReport'; ru='ККМ.ПечатьОтчетаОТекущемСостоянииРасчетовПоФР'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pObj, rMessage) Export
	// Try to connect
	If Not CloseOpenCheque(True, rMessage) Then
		Return False;
	Else
		// Cash register was connected
		Try	
			vItemsArray = Undefined;
			vItemsClientArr = Undefined;
			// Print all strings in the array
			PrintSlipLines(vItemsArray, vItemsClientArr, pSlipTextArr);
			vArrayRequest = New Array();
			vArrayRequest.Add(GetNonFiscalChequeStructure(vItemsArray, False));
			vArrayRequest.Add(GetNonFiscalChequeStructure(vItemsClientArr, False));
			vPrintNonFiscal = JSONProcessing(vArrayRequest, rMessage, NStr("en='CashRegister.PrintSlip'; de='CashRegister.PrintSlip'; ru='ККМ.ПечатьСлипа'"));
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
Function pmCloseSession(rMessage) Export
	Return pmPrintZReport(rMessage);
EndFunction // pmCloseSession

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage) Export
	If Not CloseOpenCheque(False, rMessage) Then
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
						PrintFolioHeader(vItemsArray, pObj)					
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
					GetTextStructure(vItemsArray, GetString(vStr));
				EndIf;
			EndDo;
			
			// Print cliche
			If Not vDoPrintClicheAtEnd Then
				For s = 0 To 5 Do
					GetTextStructure(vItemsArray," ");
				EndDo;
			EndIf;
			
			vPrintNonFiscal = JSONProcessing(GetNonFiscalChequeStructure(vItemsArray, vDoPrintClicheAtEnd), rMessage, NStr("en='CashRegister.PrintNonFiscalCheque'; de='CashRegister.PrintNonFiscalCheque'; ru='ККМ.ПечатьНеФискальногоЧека'"));
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
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	If Not CloseOpenCheque(True, rMessage) Then
		Return False;
	Else
		Try
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
			
			// Open cheque
			If Not pIsCorrection Then
				If pSum >= 0 Then
					vTypeS = "sell";
				Else
					vTypeS = "sellReturn";
				EndIf;
			Else
				If pSum >= 0 Then
					vTypeS = "sellCorrection";
				Else
					vTypeS = "sellReturnCorrection";
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vElectronicallyS = True; // Do not print cheque on paper
			Else
				vElectronicallyS = False;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vCorrectionTypeS = ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), "instruction", "self");
				vChequeAttributes.CorrectionType = pCorrectionType;
				If ValueIsFilled(pCorrectionDocumentDate) Or Not IsBlankString(pCorrectionDocumentNumber) Then
					If ValueIsFilled(pCorrectionDocumentDate) Then
						vCorrectionBaseDateS = Format(pCorrectionDocumentDate, "DF=yyyy.MM.dd");
						vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
					EndIf;
					If Not IsBlankString(pCorrectionDocumentNumber) Then
						vCorrectionBaseNumberS = Right(TrimAll(pCorrectionDocumentNumber), 32);
						vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
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
			vEMail = "";
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
			vChequeAttributes.BuyerAddress = vEMail;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Then
					vPayerName = tcOnServer.cmGetAttributeByRef(vPayer, "FullName");
					vPayerTIN = tcOnServer.cmGetAttributeByRef(vPayer, "TIN");
				ElsIf TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					tcOnServer.GetPayerNameAndTIN(vPayer, vPayerName, vPayerTIN);
				EndIf;
			Else
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			EndIf;
			
			If Not ValueIsFilled(vPayerTIN) Or Not ValueIsFilled(vPayerName) Then
				vPayerName = "";
				vPayerTIN = "";		
			EndIf;

			vClientInfoS = GetClientInfoStructure(vEMail, vPayerTIN, vPayerName);
						
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					rItemsArr = Undefined;
					rItemsClientArr = Undefined;
					PrintSlipLines(rItemsArr, rItemsClientArr, tcOnServer.GetTextLinesArray(pObj.SlipText));
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsArr, False));
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsClientArr, False));
				EndIf;
			EndIf;
			
			// Begin format 1.05 item 
			// Print payment number and section
			vName = "#" + TrimAll(pObj.Number);
			vDepartment = 0;
			If Not CashRegister.DoNotPrintPaymentSections Then
				If ValueIsFilled(pObj.PaymentSection) Then
					vDepartment = pObj.PaymentSection.Code;
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						vName = GetString(TrimR(vName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
					EndIf;
				EndIf;
			EndIf;
			
			// Add tax
			vVATRate = Undefined;
			vVATSum = 0;
			vItemQuantity = 1;
			vItemPrice = ?(pSum >= 0, pSum, -pSum);
			vItemSumm = ?(pSum >= 0, pSum, -pSum);
			If ValueIsFilled(pObj.PaymentSection) Then
				vTax = GetTaxGroup(pObj.PaymentSection, vVATRate, , pObj);
			Else
				vTax = GetTaxGroup(pObj, vVATRate, , pObj);
			EndIf;
			vVATSum = pObj.VATSum;
			vTaxSumm = cmCalculateVATSum(vVATRAte, vItemSumm, pObj.Date);
			cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
			
			// Fill format 1.05 attributes and end item
			vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
			vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
			
			GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vItemSumm,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
			
			// Print VAT sum if neccessary
			If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
				vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
				If vNoVAT Then
					GetTextStructure(vItemsS,GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
				Else
					GetTextStructure(vItemsS,GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
				EndIf;
			ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
				GetTextStructure(vItemsS,GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));;
			EndIf;
			
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vPaymentMethod = pObj.PaymentMethod;
				If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					vTypePayments = "2";
				ElsIf vPaymentMethod.IsByCash Then
					vTypePayments = "0";
				ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
					vTypePayments = "1";
				Else
					vTypePayments = TrimAll(vPaymentMethod.CashRegisterChequeCloseType);
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
			If pSum >= 0 Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			EndIf;
			
			If pIsCorrection Then
				vResponse = GetCorrectionStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vOperatorS, vCorrectionTypeS, vCorrectionBaseNameS, vCorrectionBaseDateS, 
												   vCorrectionBaseNumberS, vElectronicallyS, vTaxationTypeS, vPaymentsPlaceS, vMachineNumberS, vClientInfoS, vCompanyInfoS, 
												   vAgentInfoS, vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
			Else
				vResponse = GetFiscalStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vElectronicallyS, vUseVAT18S, vTaxationTypeS, 
											   vPaymentsPlaceS, vMachineNumberS, vOperatorS, vClientInfoS, vCompanyInfoS, vAgentInfoS, 
											   vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
			EndIf;
			
			vResponseArray.Add(vResponse);
			vChequeStatus = JSONProcessing(vResponseArray, rMessage, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"));
			
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
			If vfiscalParams.Property("fiscalDocumentDateTime") Then
				vChequeAttributes.ChequeDateTime = XMLValue(Type("Date"), vfiscalParams.fiscalDocumentDateTime);
			EndIf;
			If vfiscalParams.Property("shiftNumber") Then
				vChequeAttributes.CashDay = vfiscalParams.shiftNumber;
			EndIf;
			If vfiscalParams.Property("fiscalReceiptNumber") Then
				vChequeAttributes.CashDayChequeNumber = vfiscalParams.fiscalReceiptNumber;
			EndIf;
			If vfiscalParams.Property("fnNumber") Then
				vChequeAttributes.ChequeFiscalNumber = vfiscalParams.fnNumber;
			EndIf;
			
			// Log cash register operation
			LogCashPayment(NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), pObj, vChequeAttributes);
			
			// Open drawer
			// Open drawer
			If vOpenDrawer Then
				vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(),rMessage, NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"));
			EndIf;
			
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintCustomerPaymentCheque'; de='CashRegister.PrintCustomerPaymentCheque'; ru='ККМ.ПечатьЧекаПлатежаКонтрагента'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCustomerPaymentCheque

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	vIsPrepayment = False;
	If Not CloseOpenCheque(True, rMessage) Then
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
		Try
			// Open cheque
			If Not pIsCorrection Then
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vTypeS = "sellReturn";
				Else
					vTypeS = "sell";
				EndIf;
			Else
				If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
					vTypeS = "sellReturnCorrection";
				Else
					vTypeS = "sellCorrection";
				EndIf;
			EndIf;
			If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
				vElectronicallyS = True; // Do not print cheque on paper
			Else
				vElectronicallyS = False;
			EndIf;
			
			// Initialize cheque attributes used to send online cheque by sms or e-mail
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			
			// Set correction type
			vChequeAttributes.IsCorrection = pIsCorrection;
			If pIsCorrection Then
				vCorrectionTypeS = ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), "instruction", "self");
				vChequeAttributes.CorrectionType = pCorrectionType;
				If ValueIsFilled(pCorrectionDocumentDate) Or Not IsBlankString(pCorrectionDocumentNumber) Then
					If ValueIsFilled(pCorrectionDocumentDate) Then
						vCorrectionBaseDateS = Format(pCorrectionDocumentDate, "DF=yyyy.MM.dd");
						vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
					EndIf;
					If Not IsBlankString(pCorrectionDocumentNumber) Then
						vCorrectionBaseNumberS = Right(TrimAll(pCorrectionDocumentNumber), 32);
						vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
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
			vEMail = "";
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
			vChequeAttributes.BuyerAddress = vEMail;
			If ValueIsFilled(vPayer) Then
				If TypeOf(vPayer) = Type("CatalogRef.Clients") Then
					vPayerName = tcOnServer.cmGetAttributeByRef(vPayer, "FullName");
					vPayerTIN = tcOnServer.cmGetAttributeByRef(vPayer, "TIN");
				ElsIf TypeOf(vPayer) = Type("CatalogRef.Customers") Then
					tcOnServer.GetPayerNameAndTIN(vPayer, vPayerName, vPayerTIN);
				EndIf;
			Else
				tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
			EndIf;
			
			If Not ValueIsFilled(vPayerTIN) Or Not ValueIsFilled(vPayerName) Then
				vPayerName = "";
				vPayerTIN = "";		
			EndIf;

			vClientInfoS = GetClientInfoStructure(vEMail, vPayerTIN, vPayerName);
			
			// Print slip if payment was made by credit card
			If CashRegister.PrintSlipInCheque Then
				If Not IsBlankString(pObj.SlipText) Then
					rItemsArr = Undefined;
					rItemsClientArr = Undefined;
					PrintSlipLines(rItemsArr, rItemsClientArr, tcOnServer.GetTextLinesArray(pObj.SlipText));
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsArr, False));
					vResponseArray.Add(GetNonFiscalChequeStructure(rItemsClientArr, False));
				EndIf;
			EndIf;
			
			// Cheque folio header
			If CashRegister.PrintFolioHeader Then
				PrintFolioHeader(vPreItemsS, pObj);
			EndIf;

			// Print services
			If Not pIsCorrection Then
				If Not CashRegister.DoNotPrintKioskServices AND pServices <> Undefined And pServices.Count() > 0 Then
					For Each vSrvRow In pServices Do
						vSupplierInfo = Undefined;
						// Begin format 1.05 item 
						// Commissioner mark
						If ValueIsFilled(vSrvRow.Service) Then
							vIsAgentService = vSrvRow.Service.IsAgentService;
							If vIsAgentService Then
								// Commissioner attribute
								vAgentInfo = GetAgentInfoStructure("another");
								// Principal
								vPrincipal = vSrvRow.Service.Principal;
								If ValueIsFilled(vPrincipal) Then
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									If StrLen(vPrincipalTIN) = 10 Then
										vTINValue = vPrincipalTIN + "  ";
									Else
										vTINValue = vPrincipalTIN;
									EndIf;
									vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
								EndIf;
							EndIf;
						EndIf;
						// Fill item attributes
						vPaymentSection = Undefined;
						vDepartment = 0;
						vName = "";
						If ValueIsFilled(vSrvRow.Service) Then
							vName = GetString(vSrvRow.Service.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
							If ValueIsFilled(vSrvRow.PaymentSection) Then
								vPaymentSection = vSrvRow.PaymentSection;
								vDepartment = vPaymentSection.Code;
							EndIf;
						EndIf;
						vItemQuantity = vSrvRow.Quantity;
						vItemPrice = vSrvRow.Price;
						vItemSumm = vSrvRow.Amount; 
						tcCashRegisters.ChequeItemAttributesCorrection(vItemSumm, vItemQuantity, 3, vItemPrice, vItemQuantity);
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPaymentSection) Then
							vTax = GetTaxGroup(vPaymentSection, vVATRate, vSrvRow.VATRate, pObj);
						Else
							vTax = GetTaxGroup(pObj, vVATRate, vSrvRow.VATRate, pObj);
						EndIf;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vTaxSumm = cmCalculateVATSum(vVATRAte, vItemSumm, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
						Else
							vTaxSumm = cmCalculateVATSum(vVATRAte, vItemSumm, pObj.Date);
						EndIf;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vSrvRow.Service, vSrvRow.PaymentSection));
						vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						
						GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vSrvRow.Amount,,vDepartment, GetUnitPiece(vSrvRow.Service),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo);
					EndDo;
				Else
					// Print number and sections
					If pObj.PaymentSections.Count() > 0 Then
						If Not CashRegister.PrintFolioHeader Then
							GetTextStructure(vItemsS, "#" + TrimAll(pObj.Number));
						EndIf;
						vPSRows = cmGetPrintableChequePositions(pObj, vIsPrepayment, CashRegister.AlwaysUseAveragePrice);
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									pSum = pSum - vPSRow.Sum;
									Continue;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Begin format 1.05 item 
								// Print name, price and quantity
								vSupplierInfo = Undefined;
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = vPSRow.ChequeService.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vAgentInfo = GetAgentInfoStructure("another");
										// Principal
										vPrincipal = vPSRow.ChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											If StrLen(vPrincipalTIN) = 10 Then
												vTINValue = vPrincipalTIN + "  ";
											Else
												vTINValue = vPrincipalTIN;
											EndIf;
											vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vDepartment = vPSRow.PaymentSection.Code;
									Else
										vDepartment = 0;
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
									Else
										vName = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
									EndIf;
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = vPSRow.PaymentSection.Code;
									vName = GetString(vPSRow.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
									vItemQuantity = 1;
									vItemPrice = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
									vAmount = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								Else
									vDepartment = 0;
									If vSectionAmount >=0 Then
										vName = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vName = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vItemQuantity = 1;
									vItemPrice = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
									vAmount = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
								Else
									vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
								EndIf;
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
								// Fill format 1.05 attributes and end item
								vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo);
							EndDo;
						ElsIf Not CashRegister.DoNotPrintPaymentSections Then
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									pSum = pSum - vPSRow.Sum;
									Continue;
								EndIf;
								vSectionAmount = vPSRow.Sum;
								vSectionVATAmount = vPSRow.VATSum;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vSectionAmount = -vSectionAmount;
									vSectionVATAmount = -vSectionVATAmount;
								EndIf;
								// Begin format 1.05 item 
								// Print name, price and quantity
								vSupplierInfo = Undefined;
								If ValueIsFilled(vPSRow.ChequeService) Then
									// Commissioner mark
									vIsAgentService = vPSRow.ChequeService.IsAgentService;
									If vIsAgentService Then
										// Commissioner attribute
										vAgentInfo = GetAgentInfoStructure("another");
										// Principal
										vPrincipal = vPSRow.ChequeService.Principal;
										If ValueIsFilled(vPrincipal) Then
											vPrincipalTIN = TrimAll(vPrincipal.TIN);
											vPrincipalName = TrimAll(vPrincipal.LegacyName);
											vPrincipalPhone = TrimAll(vPrincipal.Phone);
											If StrLen(vPrincipalTIN) = 10 Then
												vTINValue = vPrincipalTIN + "  ";
											Else
												vTINValue = vPrincipalTIN;
											EndIf;
											vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
										EndIf;
									EndIf;
									// Item main attributes
									If ValueIsFilled(vPSRow.PaymentSection) Then
										vDepartment = vPSRow.PaymentSection.Code;
									Else
										vDepartment = 0;
									EndIf;
									If ValueIsFilled(vPSRow.Item) Then
										vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
									Else
										vName = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
									EndIf;
									vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
									vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
									vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
									vAmount = ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
									tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
								ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = vPSRow.PaymentSection.Code;
									vName = TrimAll(vPSRow.PaymentSection.Code);
									vItemQuantity = 1;
									vItemPrice = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
									vAmount = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								Else
									vDepartment = 0;
									If vSectionAmount >=0 Then
										vName = NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'");
									Else
										vName = NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'");
									EndIf;
									vItemQuantity = 1;
									vItemPrice = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
									vAmount = ?(vSectionAmount >= 0, vSectionAmount, -vSectionAmount);
								EndIf;
								// Add tax
								vVATRate = Undefined;
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
								Else
									vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
								EndIf;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
								Else
									vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
								EndIf;
								cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
								// Fill format 1.05 attributes and end item
								vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
								vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
								GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo);
							EndDo;
						Else
							vAmount = 0;
							vVATAmount = 0;
							For Each vPSRow In vPSRows Do
								If vPSRow.Sum = 0 Then
									Continue;
								ElsIf vPSRow.Sum < 0 Then
									pSum = pSum - vPSRow.Sum;
									Continue;
								EndIf;
								If TypeOf(pObj) = Type("DocumentObject.Return") Then
									vAmount = vAmount - vPSRow.Sum;
									vVATAmount = vVATAmount - vPSRow.VATSum;
								Else
									vAmount = vAmount + vPSRow.Sum;
									vVATAmount = vVATAmount + vPSRow.VATSum;
								EndIf;
							EndDo;
							// Begin format 1.05 item 
							// Print name, price and quantity
							vDepartment = 0;
							vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
							vItemQuantity = 1;
							vItemPrice = ?(vAmount >= 0, vAmount, -vAmount);
							vAmount = ?(vAmount >= 0, vAmount, -vAmount);
							// Add tax
							vVATRate = Undefined;
							vTax = GetTaxGroup(pObj, vVATRate, , pObj);
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
							Else
								vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
							EndIf;
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
							vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
							GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
						EndIf;
					Else
						vVATAmount = pObj.VATSum;
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vVATAmount = -vVATAmount;
						EndIf;
						// Begin format 1.05 item 
						// Print name, price and quantity
						vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						If Not CashRegister.PrintFolioHeader Then
							vName = "#" + TrimAll(pObj.Number);
						EndIf;
						vDepartment = 0;
						If ValueIsFilled(pObj.PaymentSection) Then
							vDepartment = pObj.PaymentSection.Code;
							If CashRegister.PrintPaymentSectionNamesInCheques Then
								If CashRegister.PrintFolioHeader Then
									vName = GetString(pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								Else
									vName = GetString(TrimR(vName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								EndIf;
							EndIf;
						EndIf;
						vItemQuantity = 1;
						vItemPrice = ?(pSum >= 0, pSum, -pSum);
						vAmount = ?(pSum >= 0, pSum, -pSum);
						// Add tax
						vVATRate = Undefined;
						vTax = GetTaxGroup(pObj, vVATRate, , pObj);
						If TypeOf(pObj) = Type("DocumentObject.Return") Then
							vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
						Else
							vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
						EndIf;
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
						vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
					EndIf;
				EndIf;
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
					If vNoVAT Then
						GetTextStructure(vItemsS,GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
					Else
						GetTextStructure(vItemsS,GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					GetTextStructure(vItemsS,GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));;
				EndIf;
			Else // Correction cheque
				vVATAmount = pObj.VATSum;
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vVATAmount = -vVATAmount;
				EndIf;
				// Begin format 1.05 item 
				// Print name, price and quantity
				vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
				If Not CashRegister.PrintFolioHeader Then
					vName = "#" + TrimAll(pObj.Number);
				EndIf;
				vDepartment = 0;
				If ValueIsFilled(pObj.PaymentSection) Then
					vDepartment = pObj.PaymentSection.Code;
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						If CashRegister.PrintFolioHeader Then
							vName = GetString(pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						Else
							vName = GetString(TrimR(vName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						EndIf;
					EndIf;
				EndIf;
				vItemQuantity = 1;
				vItemPrice = ?(pSum >= 0, pSum, -pSum);
				vAmount = ?(pSum >= 0, pSum, -pSum);
				// Add tax
				vVATRate = Undefined;
				vTax = GetTaxGroup(pObj, vVATRate, , pObj);
				If TypeOf(pObj) = Type("DocumentObject.Return") Then
					vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, ?(ValueIsFilled(pObj.Payment), pObj.Payment.Date, pObj.Date));
				Else
					vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
				EndIf;
				cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
				// Fill format 1.05 attributes and end item
				vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
				vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
	            GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));	
			EndIf;
						
			// Close cheque
			If ValueIsFilled(pObj.PaymentMethod) Then
				vPaymentMethod = pObj.PaymentMethod;
				If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
					vTypePayments = "2";
				ElsIf vPaymentMethod.IsByCash Then
					vTypePayments = "0";
				ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
					vTypePayments = "1";
				Else
					vTypePayments = TrimAll(vPaymentMethod.CashRegisterChequeCloseType);
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
			If pSum < 0 Or pSum = 0 And TypeOf(pObj) = Type("DocumentObject.Return") Then
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
			Else
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.Receipt;
			EndIf;

			If pIsCorrection Then
				vResponse = GetCorrectionStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vOperatorS, vCorrectionTypeS, vCorrectionBaseNameS, vCorrectionBaseDateS, 
												   vCorrectionBaseNumberS, vElectronicallyS, vTaxationTypeS, vPaymentsPlaceS, vMachineNumberS, vClientInfoS, vCompanyInfoS, 
												   vAgentInfoS, vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
			Else
				vResponse = GetFiscalStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vElectronicallyS, vUseVAT18S, vTaxationTypeS, 
											   vPaymentsPlaceS, vMachineNumberS, vOperatorS, vClientInfoS, vCompanyInfoS, vAgentInfoS, 
											   vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
			EndIf;
			vResponseArray.Add(vResponse);
			vChequeStatus = JSONProcessing(vResponseArray, rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
			
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
			If vfiscalParams.Property("fiscalDocumentDateTime") Then
				vChequeAttributes.ChequeDateTime = XMLValue(Type("Date"), vfiscalParams.fiscalDocumentDateTime);
			EndIf;
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
			LogCashPayment(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), pObj, vChequeAttributes);
			
			// Open drawer
			If vOpenDrawer Then
				vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(),rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
			EndIf;

			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	vIsPrepayment = False;
	If Not CloseOpenCheque(True, rMessage) Then
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
			If pSum > 0 Then
				// Open cheque
				vUseReturn = True;
				If Not pIsCorrection Then
					vTypeS = "sellReturn";
				Else
					vTypeS = "sellReturnCorrection";
				EndIf;
				If ValueIsFilled(pObj.PaymentMethod) And pObj.PaymentMethod.ElectronicChequeOnly Then
					vElectronicallyS = True; // Do not print cheque on paper
				Else
					vElectronicallyS = False;
				EndIf;
				
				// Initialize cheque attributes used to send online cheque by sms or e-mail
				vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
				
				// Set correction type
				vChequeAttributes.IsCorrection = pIsCorrection;
				If pIsCorrection Then
					vCorrectionTypeS = ?(pCorrectionType = PredefinedValue("Enum.CorrectionChequeTypes.ByOrder"), "instruction", "self");
					vChequeAttributes.CorrectionType = pCorrectionType;
					If ValueIsFilled(pCorrectionDocumentDate) Or Not IsBlankString(pCorrectionDocumentNumber) Then
						If ValueIsFilled(pCorrectionDocumentDate) Then
							vCorrectionBaseDateS = Format(pCorrectionDocumentDate, "DF=yyyy.MM.dd");
							vChequeAttributes.CorrectionDocumentDate = pCorrectionDocumentDate;
						EndIf;
						If Not IsBlankString(pCorrectionDocumentNumber) Then
							vCorrectionBaseNumberS = Right(TrimAll(pCorrectionDocumentNumber), 32);
							vChequeAttributes.CorrectionDocumentNumber = pCorrectionDocumentNumber;
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
				vEMail = "";
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
				vChequeAttributes.BuyerAddress = vEMail;
				If ValueIsFilled(vPayer) Then
					If TypeOf(vPayer) = Type("CatalogRef.Clients") Then
						vPayerName = tcOnServer.cmGetAttributeByRef(vPayer, "FullName");
						vPayerTIN = tcOnServer.cmGetAttributeByRef(vPayer, "TIN");
					ElsIf TypeOf(vPayer) = Type("CatalogRef.Customers") Then
						tcOnServer.GetPayerNameAndTIN(vPayer, vPayerName, vPayerTIN);
					EndIf;
				Else
					tcOnServer.GetPayerNameAndTIN(pObj.AccountingCustomer, vPayerName, vPayerTIN);
				EndIf;
				
				If Not ValueIsFilled(vPayerTIN) Or Not ValueIsFilled(vPayerName) Then
					vPayerName = "";
					vPayerTIN = "";		
				EndIf;

				vClientInfoS = GetClientInfoStructure(vEMail, vPayerTIN, vPayerName);
				
				// Print slip if payment was made by credit card
				If CashRegister.PrintSlipInCheque Then
					If Not IsBlankString(pObj.SlipText) Then
						rItemsArr = Undefined;
						rItemsClientArr = Undefined;
						PrintSlipLines(rItemsArr, rItemsClientArr, tcOnServer.GetTextLinesArray(pObj.SlipText));
						vResponseArray.Add(GetNonFiscalChequeStructure(rItemsArr, False));
						vResponseArray.Add(GetNonFiscalChequeStructure(rItemsClientArr, False));
					EndIf;
				EndIf;
				
				// Cheque folio header
				If CashRegister.PrintFolioHeader Then
					PrintFolioHeader(vPreItemsS, pObj);
				EndIf;
				
				// Print document number and sections
				If pObj.Metadata().TabularSections.Find("PaymentSections") <> Undefined And 
				   pObj.PaymentSections.Count() > 0 Then
					If Not CashRegister.PrintFolioHeader Then
						GetTextStructure(vItemsS, "#" + TrimAll(pObj.Number));
					EndIf;
					vPSRows = cmGetPrintableChequePositions(pObj, vIsPrepayment, CashRegister.AlwaysUseAveragePrice);
					If CashRegister.PrintPaymentSectionNamesInCheques Then
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								pSum = pSum - vPSRow.Sum;
								Continue;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							If vSectionAmount < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							// Begin format 1.05 item 
							// Print name, price and quantity
							vSupplierInfo = Undefined;
							If ValueIsFilled(vPSRow.ChequeService) Then
								// Commissioner mark
								vIsAgentService = vPSRow.ChequeService.IsAgentService;
								If vIsAgentService Then
									// Commissioner attribute
									vAgentInfo = GetAgentInfoStructure("another");
									// Principal
									vPrincipal = vPSRow.ChequeService.Principal;
									If ValueIsFilled(vPrincipal) Then
										vPrincipalTIN = TrimAll(vPrincipal.TIN);
										vPrincipalName = TrimAll(vPrincipal.LegacyName);
										vPrincipalPhone = TrimAll(vPrincipal.Phone);
										If StrLen(vPrincipalTIN) = 10 Then
											vTINValue = vPrincipalTIN + "  ";
										Else
											vTINValue = vPrincipalTIN;
										EndIf;
										vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
									EndIf;
								EndIf;
								// Item main attributes
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = vPSRow.PaymentSection.Code;
								Else
									vDepartment = 0;
								EndIf;
								If ValueIsFilled(vPSRow.Item) Then
									vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
								Else
									vName = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								EndIf;
								vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
								vItemPrice = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
								vAmount = vSectionAmount;
								tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vDepartment = vPSRow.PaymentSection.Code;
								vName = GetString(vPSRow.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
								vItemQuantity = 1;
								vItemPrice = vSectionAmount;
								vAmount = vSectionAmount;
							Else
								vDepartment = 0;
								vName = NStr("en='Advance return for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат предоплаты за гостиничные услуги'");
								vItemQuantity = 1;
								vItemPrice = vSectionAmount;
								vAmount = vSectionAmount;
							EndIf;
							// Add tax
							vVATRate = Undefined;
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
							Else
								vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
							EndIf;
							vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
							vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
							GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo);	
						EndDo;
					ElsIf Not CashRegister.DoNotPrintPaymentSections Then
						For Each vPSRow In vPSRows Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								pSum = pSum - vPSRow.Sum;
								Continue;
							EndIf;
							vSectionAmount = vPSRow.Sum;
							vSectionVATAmount = vPSRow.VATSum;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vSectionAmount = -vSectionAmount;
								vSectionVATAmount = -vSectionVATAmount;
							EndIf;
							If vSectionAmount < 0 Then
								Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
							EndIf;
							// Begin format 1.05 item 
							// Print name, price and quantity
							vSupplierInfo = Undefined;
							If ValueIsFilled(vPSRow.ChequeService) Then
								// Commissioner mark
								vIsAgentService = vPSRow.ChequeService.IsAgentService;
								If vIsAgentService Then
									// Commissioner attribute
									vAgentInfo = GetAgentInfoStructure("another");
									// Principal
									vPrincipal = vPSRow.ChequeService.Principal;
									If ValueIsFilled(vPrincipal) Then
										vPrincipalTIN = TrimAll(vPrincipal.TIN);
										vPrincipalName = TrimAll(vPrincipal.LegacyName);
										vPrincipalPhone = TrimAll(vPrincipal.Phone);
										If StrLen(vPrincipalTIN) = 10 Then
											vTINValue = vPrincipalTIN + "  ";
										Else
											vTINValue = vPrincipalTIN;
										EndIf;
										vSupplierInfo = GetSupplierInfoStructure(vPrincipalPhone, vPrincipalName, vTINValue);
									EndIf;
								EndIf;
								// Item main attributes
								If ValueIsFilled(vPSRow.PaymentSection) Then
									vDepartment = vPSRow.PaymentSection.Code;
								Else
									vDepartment = 0;
								EndIf;
								If ValueIsFilled(vPSRow.Item) Then
									vName = GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item));
								Else
									vName = GetString(vPSRow.ChequeService.GetObject().pmGetServiceDescription(SessionParameters.CurrentLanguage));
								EndIf;
								vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
								vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
								vItemPrice = ?(vPSRow.ChequeServicePrice = 0, vSectionAmount, vPSRow.ChequeServicePrice);
								vAmount = vSectionAmount;
								tcCashRegisters.ChequeItemAttributesCorrection(vAmount, vItemQuantity, 3, vItemPrice, vItemQuantity);
							ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
								vDepartment = vPSRow.PaymentSection.Code;
								vName = TrimAll(vPSRow.PaymentSection.Code);
								vItemQuantity = 1;
								vItemPrice = vSectionAmount;
								vAmount = vSectionAmount;
							Else
								vDepartment = 0;
								vName = NStr("en='Advance return for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат предоплаты за гостиничные услуги'");
								vItemQuantity = 1;
								vItemPrice = vSectionAmount;
								vAmount = vSectionAmount;
							EndIf;
							// Add tax
							vVATRate = Undefined;
							If ValueIsFilled(vPSRow.PaymentSection) Then
								vTax = GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pObj);
							Else
								vTax = GetTaxGroup(pObj, vVATRate, vPSRow.VATRate, pObj);
							EndIf;
							vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
							cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
							// Fill format 1.05 attributes and end item
							vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
							vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, ?(ValueIsFilled(pObj.PaymentSection), pObj.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
							GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(vPSRow.ChequeService),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined), vAgentInfo, vSupplierInfo);
						EndDo;
					Else
						vAmount = 0;
						vVATAmount = 0;
						For Each vPSRow In pObj.PaymentSections Do
							If vPSRow.Sum = 0 Then
								Continue;
							ElsIf vPSRow.Sum < 0 Then
								pSum = pSum - vPSRow.Sum;
								Continue;
							EndIf;
							If TypeOf(pObj) = Type("DocumentObject.Return") Then
								vAmount = vAmount - vPSRow.Sum;
								vVATAmount = vVATAmount - vPSRow.VATSum;
							Else
								vAmount = vAmount + vPSRow.Sum;
								vVATAmount = vVATAmount + vPSRow.VATSum;
							EndIf;
						EndDo;
						If vAmount < 0 Then
							Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
						EndIf;
						// Begin format 1.05 item 
						// Print name, price and quantity
						vDepartment = 0;
						vName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
						vItemQuantity = 1;
						vItemPrice = vAmount;
						// Add tax
						vVATRate = Undefined;
						vTax = GetTaxGroup(pObj, vVATRate, , pObj);
						vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
						cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
						// Fill format 1.05 attributes and end item
						vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
						vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
						GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
					EndIf;
				Else
					vVATAmount = pObj.VATSum;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vVATAmount = -vVATAmount;
					EndIf;
					vAmount = pSum;
					If TypeOf(pObj) = Type("DocumentObject.Return") Then
						vAmount = -vAmount;
					EndIf;
					If vAmount < 0 Then
						Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
					EndIf;
					// Begin format 1.05 item 
					// Print name, price and quantity
					vName = "#" + TrimAll(pObj.Number);
					vDepartment = 0;
					If ValueIsFilled(pObj.PaymentSection) Then
						vDepartment = pObj.PaymentSection.Code;
						If CashRegister.PrintPaymentSectionNamesInCheques Then
							vName = GetString(TrimR(vName) + " - " + pObj.PaymentSection.GetObject().pmGetDescription(SessionParameters.CurrentLanguage));
						EndIf;
					EndIf;
					vItemQuantity = 1;
					vItemPrice = vAmount;;
					// Add tax
					vTax = GetTaxGroup(pObj, vVATRate, , pObj);
					vTaxSumm = cmCalculateVATSum(vVATRAte, vAmount, pObj.Date);
					cmSetChequeVATAmount(vChequeAttributes, vVATRAte, vTaxSumm);
					// Fill format 1.05 attributes and end item
					vPaymentObject = cmGetChequeItemTypeValue(cmGetChequeItemType(pObj, Undefined, Undefined));
					vPaymentMethod = GetPaymentMethodText(cmGetChequePaymentMode(pObj.PaymentMethod, pObj.PaymentSection));
					GetPositionStructure(vItemsS, vName, vItemPrice, vItemQuantity, vAmount,,vDepartment, GetUnitPiece(Undefined),,vPaymentMethod, TrimAll(vPaymentObject), ?(ValueIsFilled(vTax),GetTaxStructure(vTax),Undefined));
				EndIf;
				
				// Print VAT sum if neccessary
				If CashRegister.PrintVATSumInCheques And pVATSum > 0 Then
					vNoVAT = ?(ValueIsFilled(pObj.VATRate), tcOnServer.cmGetAttributeByRef(pObj.VATRate, "NoVAT"), False);
					If vNoVAT Then
						GetTextStructure(vItemsS,GetString(NStr("en='No VAT';ru='Без НДС';de='Ohne MwSt.'")));
					Else
						GetTextStructure(vItemsS,GetString(NStr("ru='В т.ч. НДС '; en='Incl. VAT '; de='Inkl. MwSt. '") + Format(pVATSum, "ND=17; NFD=2; NZ=")));
					EndIf;
				ElsIf CashRegister.PrintInclVATStrInCheques And pVATSum > 0 Then
					GetTextStructure(vItemsS,GetString(NStr("ru='НДС включён в сумму'; en='Amount includes VAT'; de='Betrag inkl. MwSt.'")));;
				EndIf;
							
				// Close cheque
				If ValueIsFilled(pObj.PaymentMethod) Then
					vPaymentMethod = pObj.PaymentMethod;
					If vPaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
						vTypePayments = "2";
					ElsIf vPaymentMethod.IsByCash Then
						vTypePayments = "0";
					ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
						vTypePayments = "1";
					Else
						vTypePayments = TrimAll(vPaymentMethod.CashRegisterChequeCloseType);
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
				vChequeAttributes.ChequeAccountingType = Enums.ChequeAccountingTypes.ReceiptReturn;
				If pIsCorrection Then
					vResponse = GetCorrectionStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vOperatorS, vCorrectionTypeS, vCorrectionBaseNameS, vCorrectionBaseDateS, 
													   vCorrectionBaseNumberS, vElectronicallyS, vTaxationTypeS, vPaymentsPlaceS, vMachineNumberS, vClientInfoS, vCompanyInfoS, 
													   vAgentInfoS, vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
				Else
					vResponse = GetFiscalStructure(vTypeS, vIgnoreNonFiscalPrintErrorsS, vElectronicallyS, vUseVAT18S, vTaxationTypeS, 
												   vPaymentsPlaceS, vMachineNumberS, vOperatorS, vClientInfoS, vCompanyInfoS, vAgentInfoS, 
												   vSupplierInfoS, vItemsS, vPaymentsS, vTaxesS, vTotalS, vPreItemsS, vPostItemsS);	
				EndIf;
				vResponseArray.Add(vResponse);
				vChequeStatus = JSONProcessing(vResponseArray, rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
				
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
				If vfiscalParams.Property("fiscalDocumentDateTime") Then
					vChequeAttributes.ChequeDateTime = XMLValue(Type("Date"), vfiscalParams.fiscalDocumentDateTime);
				EndIf;
				If vfiscalParams.Property("shiftNumber") Then
					vChequeAttributes.CashDay = vfiscalParams.shiftNumber;
				EndIf;
				If vfiscalParams.Property("fiscalReceiptNumber") Then
					vChequeAttributes.CashDayChequeNumber = vfiscalParams.fiscalReceiptNumber;
				EndIf;
				If vfiscalParams.Property("fnNumber") Then
					vChequeAttributes.ChequeFiscalNumber = vfiscalParams.fnNumber;
				EndIf;
				
				// Log cash register operation
				LogCashPaymentAnnulation(NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), pObj, vChequeAttributes);
				
				// Open drawer
				If vOpenDrawer Then
					vOpenCashDrawerStatus = JSONProcessing(GetOpenCashDrawerStructure(),rMessage, NStr("en='CashRegister.PrintCheque'; de='CashRegister.PrintCheque'; ru='ККМ.ПечатьЧека'"));
				EndIf;
				
				Return True;
			Else
				Raise NStr("ru='Анулирование не поддерживается для возвратов!'; en='Annulation is not supported for returns!'; de='Annulation is not supported for returns!'");
			EndIf;
		Except
			rMessage = ErrorDescription();
			ProcessException(NStr("en='CashRegister.AnnulateCheque'; de='CashRegister.AnnulateCheque'; ru='ККМ.АннулированиеЧека'"), rMessage);
			Return False;
		EndTry;
	EndIf;
EndFunction // pmAnnulateCheque

// -----------------------------------------------------------------------------
Function GetUnitPiece(pService)
	If CashRegister.FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
		If ValueIsFilled(pService) Then
			vSUnit = tcOnServer.cmGetAttributeByRef(pService, "Unit");
			If IsBlankString(vSUnit) Or TrimAll(Catalogs.Units.Piece) = vSUnit Then
				Return 0;	
			ElsIf TrimAll(Catalogs.Units.Gram) = vSUnit Then
				Return 10;
			ElsIf TrimAll(Catalogs.Units.Kilogram) = vSUnit Then
				Return 11; 
			ElsIf TrimAll(Catalogs.Units.Litre) = vSUnit Then
				Return 41; 
			ElsIf TrimAll(Catalogs.Units.Mililitre) = vSUnit Then
				Return 40; 
			ElsIf TrimAll(Catalogs.Units.Night) = vSUnit Then
				Return 70;
			ElsIf TrimAll(Catalogs.Units.Minute) = vSUnit Then
				Return 72; 
			ElsIf TrimAll(Catalogs.Units.Hour) = vSUnit Then
				Return 71;
			ElsIf TrimAll(Catalogs.Units.Megabyte) = vSUnit Then
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