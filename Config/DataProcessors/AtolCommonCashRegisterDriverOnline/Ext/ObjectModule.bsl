
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// --------------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

//  --------------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	
EndProcedure // pmFillAttributesWithDefaultValues

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	ChecksProcessing();
EndProcedure // pmRun

// --------------------------------------------------------------------------------
//
// Parameters:
//  rSpreadsheetDocument - SpreadsheetDocument	 - Detailed result
// 
// Returns:
//  Boolean - Result
//
Function ChecksProcessing(rSpreadsheetDocument = Undefined) Export
	If Not IsBlankString(InteractionParameters.LogFolder) Then
		vIPObj = InteractionParameters.GetObject();
		vIPObj.OAuth_AccessToken = vIPObj.LogFolder;
		vIPObj.LogFolder = "";
		vIPObj.Write();
	EndIf;
	
	vDocuments = GetDocuments();
	For Each vDocument In vDocuments Do
		If Not CheckToken() Then
			Break;
		EndIf;
		
		If IsBlankString(vDocument.ExternalCode) Then
			SendCheck(vDocument.Payment, vDocument.IsCorrection, vDocument.CorrectionType, vDocument.CorrectionDescription, vDocument.CorrectionDocumentNumber, vDocument.CorrectionDocumentDate, vDocument.UUID);
		Else
			CheckStatus(vDocument.Payment, vDocument.ExternalCode);
		EndIf;
	EndDo;
	
	vCurDate = CurrentSessionDate();
	vMinutes = 60;
	vSeconds = 60;
	vMinNumberOfHours = MinNumberOfHours;
	If vMinNumberOfHours = 0 Then
		vMinNumberOfHours = 1;
	EndIf;
	
	vResult = True;
	If rSpreadsheetDocument <> Undefined Or vCurDate > InteractionParameters.LastFullSynchronizationTime + (vMinNumberOfHours * vMinutes * vSeconds) Then
		If rSpreadsheetDocument = Undefined Then
			rSpreadsheetDocument = New SpreadsheetDocument;
		EndIf;
		
		vResult = FillSpreadsheetDocument(rSpreadsheetDocument);
		If vResult Then
			Return True;
		EndIf;
		
		If Not IsBlankString(EmailForNotification) Then
			vMemoryStream = New MemoryStream;
			rSpreadsheetDocument.Write(vMemoryStream, SpreadsheetDocumentFileType.PDF);
			vSubject = StrTemplate(NStr("en = 'Error report: %1 of %2'; de = 'Fehlerbericht: %1 von %2'; ru = 'Отчет об ошибках: %1 от %2'"), TrimAll(InteractionParameters), Format(CurrentSessionDate(), "DF='dd.MM,yyyy HH:mm'"));
			If JobsScheduled.cmSendFileByEMail(vSubject, "", EmailForNotification, cmGetValidFileName(vSubject + ".pdf"), vMemoryStream.CloseAndGetBinaryData()) Then
				vIPObj = InteractionParameters.GetObject();
				vIPObj.LastFullSynchronizationTime = vCurDate;
				vIPObj.Write();
			EndIf;
		EndIf;
	EndIf;
	Return vResult;
EndFunction // ChecksProcessing

// --------------------------------------------------------------------------------
Function FillSpreadsheetDocument(rSpreadsheetDocument)
	rSpreadsheetDocument.Clear();
	vResult = True;
	
	vTemplate = GetTemplate("BugReport");
	vHeader = vTemplate.GetArea("Header");
	
	rSpreadsheetDocument.Put(vHeader);
	
	If InteractionParameters.Status = Enums.IntegrationStatuses.Error Then
		vRow = vTemplate.GetArea("Row");
		vRow.Parameters.mDocument = InteractionParameters;
		vRow.Parameters.mError = InteractionParameters.ErrorDescription;
		rSpreadsheetDocument.Put(vRow);
		vResult = False;
	EndIf;
	
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	ExternalSystemIntegrationData.RefKey1 AS CashRegister
	|INTO CashRegistersList
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
	|	AND ExternalSystemIntegrationData.DataType = ""CashRegisters""
	|	AND ExternalSystemIntegrationData.DataName = ""CashRegister""
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.RefKey1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChequeAttributes.Payment AS Payment,
	|	ChequeAttributes.Remarks AS Remarks
	|FROM
	|	InformationRegister.ChequeAttributes AS ChequeAttributes
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON ChequeAttributes.CashRegister = CashRegistersList.CashRegister
	|WHERE
	|	ChequeAttributes.ChequeFiscalNumber = """"
	|	AND (ChequeAttributes.Payment.Posted
	|			OR ChequeAttributes.ExternalCode <> """")
	|	AND (CAST(ChequeAttributes.Remarks AS STRING(100))) <> """"";
	vQ.SetParameter("qExternalSystem", InteractionParameters);
	
	vChequeAttributes = vQ.Execute().Unload();
	For Each vChequeAttribute In vChequeAttributes Do
		vRow = vTemplate.GetArea("Row");
		vRow.Parameters.mDocument = vChequeAttribute.Payment;
		vRow.Parameters.mError = vChequeAttribute.Remarks;
		
		If Not rSpreadsheetDocument.CheckPut(vRow) Then
			rSpreadsheetDocument.PutHorizontalPageBreak();
			rSpreadsheetDocument.Put(vHeader);
		EndIf;
		
		rSpreadsheetDocument.Put(vRow);
		
		vResult = False;
	EndDo;
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(rSpreadsheetDocument, PageOrientation.Portrait, True);
	// Check authorities
	cmSetSpreadsheetProtection(rSpreadsheetDocument);
	
	Return vResult;
EndFunction // FillSpreadsheetDocument

// --------------------------------------------------------------------------------
//
// Parameters:
//  rMessage - 	String - Message
// 
// Returns:
// Boolean  - Result
//
Function pmRefreshToken(rMessage = "") Export
	vBodyMap = New Map;
	vBodyMap.Insert("login", TrimAll(InteractionParameters.Login));
	vBodyMap.Insert("pass", TrimAll(InteractionParameters.Password));
	vBodyMap.Insert("source", "HotelTechConnect");
	
	vResponse = SendRequest(GetAddressByVersions("", True), MapToJson(vBodyMap), "POST", rMessage);
	If vResponse = Undefined Then
		vIPObj= InteractionParameters.GetObject();
		vIPObj.ErrorDescription = rMessage;
		vIPObj.Status = Enums.IntegrationStatuses.Error;
		vIPObj.Write();
		Return False;
	EndIf;
	
	vIPObj= InteractionParameters.GetObject();
	vIPObj.OAuth_AccessToken = vResponse["token"];
	vIPObj.SessionStartTime = CurrentSessionDate();
	vIPObj.ErrorDescription = "";
	vIPObj.Status = Enums.IntegrationStatuses.Success;
	vIPObj.Write();
	
	Return True;
EndFunction // RefreshToken

// --------------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, rMessage, pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	#If Not ThickClientOrdinaryApplication Then
		vObjRef = pObj.Ref;
		
		vChequeAttributes = Undefined;
		If ValueIsFilled(vObjRef) Then
			vChequeAttributes = cmGetChequeAttributes(vObjRef);
		EndIf;
		
		If vChequeAttributes = Undefined Then
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
		EndIf;
		
		Return True;
	#Else
		rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
		Return False;
	#EndIf
EndFunction // pmPrintCheque

// --------------------------------------------------------------------------------
Function pmPrintCustomerPaymentCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	#If Not ThickClientOrdinaryApplication Then
		vObjRef = pObj.Ref;
		
		vChequeAttributes = Undefined;
		If ValueIsFilled(vObjRef) Then
			vChequeAttributes = cmGetChequeAttributes(vObjRef);
		EndIf;
		
		If vChequeAttributes = Undefined Then
			vChequeAttributes = cmInitializeChequeAttributes(pObj, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
		EndIf;
		
		Return True;
	#Else
		rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
		Return False;
	#EndIf
EndFunction // pmPrintCustomerPaymentCheque

// --------------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False) Export
	#If Not ThickClientOrdinaryApplication Then
		Return True;
	#Else
		rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
		Return False;
	#EndIf
EndFunction // pmIsReadyToPrint

// --------------------------------------------------------------------------------
Function pmPrintZReport(rMessage) Export
	Return True;
EndFunction // pmPrintZReport

// --------------------------------------------------------------------------------
Function pmCloseSession(rMessage) Export
	Return pmPrintZReport(rMessage);
EndFunction // pmCloseSession

// --------------------------------------------------------------------------------
Function pmCheckConnection(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmCheckConnection

// --------------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmSetDeviceTime

// --------------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage) Export
	Return True;
EndFunction // pmPrintCashIncome

// --------------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage) Export
	Return True;
EndFunction // pmPrintCashOutcome

// --------------------------------------------------------------------------------
Function pmPrintXReport(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintXReport

// --------------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintHourXReport

// --------------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// --------------------------------------------------------------------------------
Function pmAnnulateCheque(Val pSum, Val pVATSum, pObj, rMessage, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101') Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmAnnulateCheque

// --------------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pObj, rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintSlip

// --------------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintNonFiscalCheque

// --------------------------------------------------------------------------------
Function pmOpenDrawer(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmOpenDrawer

// --------------------------------------------------------------------------------
Function pmGetFDF(rMessage) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return Undefined;
EndFunction // pmGetFDF

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CheckToken()
	vTokenLifeTime = 86400;
	
	If Not IsBlankString(InteractionParameters.OAuth_AccessToken) And CurrentSessionDate() < InteractionParameters.SessionStartTime + vTokenLifeTime Then
		Return True;
	EndIf;
	
	Return pmRefreshToken();
EndFunction // CheckToken

// --------------------------------------------------------------------------------
Procedure SendCheck(pDocument, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pUUID)
	vCashRegister = pDocument.CashRegister;
	vPaymentMethod = pDocument.PaymentMethod;
	vHotel = pDocument.Hotel;
	vIsPrepayment = False;
	
	vCurDate = CurrentSessionDate();
	If BegOfDay(pDocument.Date) <> BegOfDay(vCurDate) And Not pIsCorrection Then
		pIsCorrection =True;
		pCorrectionType = Enums.CorrectionChequeTypes.OnHotelsOwn;
		pCorrectionDocumentDate = pDocument.Date;
	EndIf;
	
	vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pDocument, pDocument, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
	
	Try
		vOperationType = "";
		vIsPayment = False;
		If pDocument.Sum < 0 Or TypeOf(pDocument) = Type("DocumentRef.Return") Then
			If pIsCorrection Then
				vOperationType = "sell_refund_correction";
			Else
				vOperationType = "sell_refund";
			EndIf;
		Else
			If pIsCorrection Then
				vOperationType = "sell_correction";
			Else
				vOperationType = "sell";
			EndIf;
			vIsPayment = True;
		EndIf;
		
		vBodyMap = New Map;
		vBodyMap.Insert("timestamp", Format(pDocument.Date, "DF='dd.MM.yyyy HH:mm:ss'"));
		If pUUID <> New UUID("00000000-0000-0000-0000-000000000000") Then
			vChequeAttributes.UUID = pUUID;
			vBodyMap.Insert("external_id", TrimAll(pUUID));
		Else
			vUUID = New UUID;
			vChequeAttributes.UUID = vUUID;
			vBodyMap.Insert("external_id", TrimAll(vUUID));
		EndIf;
		
		vBodyMap.Insert("ism_optional", Not vCashRegister.CancelReceiptPrintingWhenMarkingCheckError);
		
		vReceipt = New Map;
		
		If Not pIsCorrection Or FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
			vClientMap = New Map;
			
			vPayer = Undefined;
			If TypeOf(pDocument.Ref) = Type("DocumentRef.Payment") Or TypeOf(pDocument.Ref) = Type("DocumentRef.Return") Then
				vPayer = pDocument.Payer;
			Else
				vPayer = pDocument.AccountingCustomer;
			EndIf;
			
			vPayerContactsIsEmpty = True;
			If pDocument.SendPayerContactsToOFD = 0 Then
				// Transfer client e-mail
				vEMail = "";
				If Not IsBlankString(pDocument.EmailToSendToOFD) Then
					vEMail = TrimAll(pDocument.EmailToSendToOFD);
				ElsIf ValueIsFilled(vPayer) And (TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers")) Then
					vEMail = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "EMail"));
				EndIf;
				If Not IsBlankString(vEMail) And tcCommonFunctionOnClientServer.CheckEmail(vEMail, , False) And tcCashRegisters.CheckEMailsBlackList(vEMail) Then
					vClientMap.Insert("email", vEMail);
					vPayerContactsIsEmpty = False;
				Else
					vClientMap.Insert("email", "none");
				EndIf;
			ElsIf pDocument.SendPayerContactsToOFD = 1 Then
				// Transfer client Phone
				vPhone = "";
				If Not IsBlankString(pDocument.PhoneToSendToOFD) Then
					vPhone = TrimAll(pDocument.PhoneToSendToOFD);
				ElsIf ValueIsFilled(vPayer) And (TypeOf(vPayer) = Type("CatalogRef.Clients") Or TypeOf(vPayer) = Type("CatalogRef.Customers")) Then
					vPhone = TrimAll(tcOnServer.cmGetAttributeByRef(vPayer, "Phone"));
				EndIf;
				vPhone = TrimAll(SMS.GetValidPhoneNumber(vPhone));
				If Not IsBlankString(vPhone) Then
					vClientMap.Insert("phone", "+" + vPhone);
					vPayerContactsIsEmpty = False;
				Else
					vClientMap.Insert("phone", "none");
				EndIf;
			EnDIf;
			
			If vPayerContactsIsEmpty Then
				vClientMap.Insert("email", EmailForNotification);
			EndIf;
			
			vPayerName = "";
			vPayerTIN = "";
			tcOnServer.GetPayerNameAndTIN(pDocument.AccountingCustomer, vPayerName, vPayerTIN);
			If Not IsBlankString(vPayerTIN) And Not IsBlankString(vPayerName) Then
				vClientMap.Insert("name", vPayerName);
				vClientMap.Insert("inn", vPayerTIN);
			EndIf;
			
			// Extra functions for extensions
			SendCheck_ChangeClient(vClientMap, pDocument, vCashRegister, vChequeAttributes);
			
			vReceipt.Insert("client", vClientMap);
		EndIf;
		
		vCompany = vCashRegister.Owner;
		
		vCompanyMap = New Map;
		If Not IsBlankString(vCompany.EMail) Then
			vCompanyMap.Insert("email", TrimAll(vCompany.EMail));
		Else
			vCompanyMap.Insert("email", "none");
		EndIf;
		
		vTaxSystem = Undefined;
		vTaxSystemName = GetTaxationSystemCode(pDocument, vTaxSystem);
		If Not IsBlankString(vTaxSystemName) Then
			vCompanyMap.Insert("sno", vTaxSystemName);
			vChequeAttributes.TaxationSystem = vTaxSystem;
		EndIf;
		vCompanyMap.Insert("inn", vCompany.TIN);
		
		If Not IsBlankString(vCashRegister.PaymentAddress) Then
			vCompanyMap.Insert("payment_address", TrimAll(vCashRegister.PaymentAddress));
		ElsIf Not IsBlankString(vHotel.Site) Then
			vCompanyMap.Insert("payment_address", TrimAll(vHotel.Site));
		Else
			vLanguage = Undefined;
			If ValueIsFilled(vPayer) Then
				vLanguage = vPayer.Language
			ElsIf ValueIsFilled(vHotel.Language) Then
				vLanguage = vHotel.Language;
			Else
				vLanguage = SessionParameters.CurrentLanguage;
			EndIf;
			
			vCompanyMap.Insert("payment_address", Catalogs.Hotels.pmGetHotelPrintName(vHotel, vLanguage));
		EndIf;
		
		// Extra functions for extensions
		SendCheck_ChangeCompany(vCompanyMap, pDocument, vCashRegister, vChequeAttributes);
		
		vReceipt.Insert("company", vCompanyMap);
		
		If pIsCorrection Then
			vCorrectionInfoMap = New Map;
			
			vCorrectionInfoMap.Insert("type", ?(pCorrectionType = Enums.CorrectionChequeTypes.ByOrder, "instruction", "self"));
			vChequeAttributes.CorrectionType = pCorrectionType;
			
			vCorrectionDocumentDate = ?(ValueIsFilled(pCorrectionDocumentDate), BegOfDay(pCorrectionDocumentDate), ?(pDocument.CorrectionOfIncorrectCheque And ValueIsFilled(pDocument.Payment), pDocument.Payment.Date, '00010101'));
			vCorrectionInfoMap.Insert("base_date", Format(vCorrectionDocumentDate, "DF=dd.MM.yyyy"));
			vChequeAttributes.CorrectionDocumentDate = vCorrectionDocumentDate;
			
			vCorrectionDocumentNumber = TrimAll(TrimAll(pCorrectionDescription) + ?(IsBlankString(pCorrectionDocumentNumber), "", " №" + TrimAll(pCorrectionDocumentNumber)));
			vCorrectionInfoMap.Insert("base_number", Right(vCorrectionDocumentNumber, 32));
			vChequeAttributes.CorrectionDocumentNumber = vCorrectionDocumentNumber;
			
			// Extra functions for extensions
			SendCheck_ChangeCorrectionInfo(vCorrectionInfoMap, pDocument, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, vCashRegister, vChequeAttributes);
			
			vReceipt.Insert("correction_info", vCorrectionInfoMap);
		EndIf;
		
		If TypeOf(pDocument) <> Type("DocumentRef.CustomerPayment") And pDocument.CorrectionOfIncorrectCheque And (Not pIsCorrection Or FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2) Then
			vPayment = pDocument.Payment;
			If ValueIsFilled(vPayment) Then
				vPaymentAttrs = tcCashRegisters.GetChequeAttributes(vPayment);
				If vPaymentAttrs <> Undefined And Not IsBlankString(vPaymentAttrs.ChequeFiscalNumber) Then
					vReceipt.Insert("additional_check_props", TrimAll(vPaymentAttrs.ChequeFiscalNumber));
				EndIf;
			EndIf;
		EndIf;
		
		vCashier = pDocument.Author;
		If ValueIsFilled(vCashier) Then
			vCashierName = tcCashRegisters.GetCashierName(vCashier);
			If Not IsBlankString(vCashierName) Then
				vReceipt.Insert("cashier", vCashierName);
				vChequeAttributes.CashierName = vCashierName;
				
				If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vEmployeeTIN = TrimAll(vCashier.TIN);
					If Not IsBlankString(vEmployeeTIN) Then
						vReceipt.Insert("cashier_inn", vEmployeeTIN);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		vSum = pDocument.Sum;
		
		vContainsMarkingCodes = False;
		If Not pIsCorrection Or FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
			
			vChargesWithMarkingCode = New Map;
			If TypeOf(pDocument) <> Type("DocumentRef.CustomerPayment") Then
				vChargesWithMarkingCode = tcCashRegisters.GetChargesWithMarkingCode(pDocument.Folio);
			EndIf;
			
			vSumTotal = 0;
			vItemsArr =New Array;
			
			// Print number and sections
			If TypeOf(pDocument) <> Type("DocumentRef.CustomerPayment") And pDocument.PaymentSections.Count() > 0 Then
				vPSRows = tcCashRegisters.GetPrintableChequePositions(pDocument, vIsPrepayment, vCashRegister.AlwaysUseAveragePrice);
				If vCashRegister.PrintPaymentSectionNamesInCheques Then
					vSum = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							vSum = vSum + vPSRow.Sum;
						EndIf;
						vSectionAmount = vPSRow.Sum;
						vSectionVATAmount = vPSRow.VATSum;
						If TypeOf(pDocument.Ref) = Type("DocumentRef.Return") Then
							vSectionAmount = -vSectionAmount;
							vSectionVATAmount = -vSectionVATAmount;
						EndIf;
						
						vItemsMap = New Map;
						
						// Begin format item 
						// Print name, price and quantity
						vItemQuantity = 1;
						vPaymentModeTypeValue = GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pDocument.PaymentMethod, ?(ValueIsFilled(pDocument.PaymentSection), pDocument.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
						If ValueIsFilled(vPSRow.ChequeService) Then
							vIndustryInfo = GetIndustryInfo(vIsPayment, vPaymentModeTypeValue, vChargesWithMarkingCode, vPSRow.MarkingCode);
							
							// Commissioner mark
							vIsAgentService = vPSRow.ChequeService.IsAgentService;
							If vIsAgentService Then
								// Principal
								vPrincipal = vPSRow.ChequeService.Principal;
								If ValueIsFilled(vPrincipal) Then
									vSupplierInfo = New Map;
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									vSuplierInfo = Undefined;
									If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
										vPhonesArr = New Array;
										vPhonesArr.Add(SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
										vSupplierInfo.Insert("phones", vPhonesArr);
										vSupplierInfo.Insert("name", vPrincipalName);
									EndIf;
									If ValueIsFilled(vPrincipalTIN) Then
										vSupplierInfo.Insert("inn", vPrincipalTIN);
									EndIf;
									vItemsMap.Insert("supplier_info", vSupplierInfo);
								EndIf;
								vAgentInfoMap = New Map;
								// Commissioner attribute
								If vPSRow.ChequeService.PrincipalType = 1 Then
									vAgentInfoMap.Insert("type", "another");
								Else
									vAgentInfoMap.Insert("type", "commission_agent");
								EndIf;
								vItemsMap.Insert("agent_info", vAgentInfoMap);
							EndIf;
							If Not IsBlankString(vPSRow.MarkingCode) Then
								vContainsMarkingCodes = True;
								If vIndustryInfo <> Undefined Then
									vSectoralItemPropsArr = New Array;
									vSectoralItemPropsArr.Add(vIndustryInfo);
									vItemsMap.Insert("sectoral_item_props", vSectoralItemPropsArr);
								EndIf;
								
								vMarkCodeMap = New Map;
								vMarkCodeMap.Insert("gs1m", vPSRow.MarkingCode);
								vItemsMap.Insert("mark_code", vMarkCodeMap);
								vItemsMap.Insert("mark_processing_mode", "0");
							Else
								vCashRegisterItemCode = TrimAll(vPSRow.ChequeService.CashRegisterItemCode);
								If Not IsBlankString(vCashRegisterItemCode) Then
									If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
										vMarkCodeMap = New Map;
										If cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 8 Then
											vMarkCodeMap.Insert("ean8", vCashRegisterItemCode);
										ElsIf cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 13 Then
											vMarkCodeMap.Insert("ean13", vCashRegisterItemCode);
										ElsIf cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 14 Then
											vMarkCodeMap.Insert("itf14", vCashRegisterItemCode);
										Else
											vMarkCodeMap.Insert("unknown", vCashRegisterItemCode);
										EndIf;
										vItemsMap.Insert("mark_code", vMarkCodeMap);
									Else
										vItemsMap.Insert("nomenclature_code", tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(vPSRow.Item) Then
								vItemsMap.Insert("name", GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vCashRegister));
							Else
								vItemsMap.Insert("name", GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vCashRegister));
							EndIf;
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
							vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
							tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
							vItemsMap.Insert("price", vItemPrice);
							vItemsMap.Insert("quantity", vItemQuantity);
						ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
							vItemsMap.Insert("name", GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vCashRegister));
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("price", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("quantity", 1);
						Else
							If vSectionAmount >=0 Then
								vItemsMap.Insert("name", NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
							Else
								vItemsMap.Insert("name", NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
							EndIf;
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("price", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("quantity", 1);
						EndIf;
						vSumTotal = vSumTotal + ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPSRow.PaymentSection) Then
							vItemsMap.Insert("vat", GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pDocument));
						Else
							vItemsMap.Insert("vat", GetTaxGroup(pDocument, vVATRate, vPSRow.VATRate, pDocument));
						EndIf;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
						// Fill format 1.05 attributes and end item
						v1212 = GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pDocument, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
						vItemsMap.Insert("payment_object", v1212);
						If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
							// Fill excise value
							If ValueIsFilled(vPSRow.ChequeService) Then
								vItemsMap.Insert("excise", tcCashRegisters.GetChequeItemExciseValue(vPSRow.ChequeService.ExciseDutyType, pDocument.Date, vPSRow.ChequeService.Volume, vItemQuantity));
							EndIf;
						EndIf;
						vItemsMap.Insert("payment_method", vPaymentModeTypeValue);
						If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vItemsMap.Insert("measure", GetUnitPiece(vPSRow.ChequeService));
						EndIf;
						
						// Extra functions for extensions
						SendCheck_ChangeItem(vItemsMap, vPSRow, vSum, vSumTotal, vContainsMarkingCodes, pDocument, vCashRegister, vChequeAttributes);
						
						vItemsArr.Add(vItemsMap);
					EndDo;
				ElsIf Not vCashRegister.DoNotPrintPaymentSections Then
					vSum = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							vSum = vSum + vPSRow.Sum;
						EndIf;
						vSectionAmount = vPSRow.Sum;
						vSectionVATAmount = vPSRow.VATSum;
						If TypeOf(pDocument.Ref) = Type("DocumentRef.Return") Then
							vSectionAmount = -vSectionAmount;
							vSectionVATAmount = -vSectionVATAmount;
						EndIf;
						
						vItemsMap = New Map;
						
						// Begin format 1.05 item 
						// Print name, price and quantity
						vItemQuantity = 1;
						vPaymentModeTypeValue = GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pDocument.PaymentMethod, ?(ValueIsFilled(pDocument.PaymentSection), pDocument.PaymentSection, vPSRow.PaymentSection), vIsPrepayment));
						If ValueIsFilled(vPSRow.ChequeService) Then
							vIndustryInfo = GetIndustryInfo(vIsPayment, vPaymentModeTypeValue, vChargesWithMarkingCode, vPSRow.MarkingCode);
							
							// Commissioner mark
							vIsAgentService = vPSRow.ChequeService.IsAgentService;
							If vIsAgentService Then
								// Principal
								vPrincipal = vPSRow.ChequeService.Principal;
								If ValueIsFilled(vPrincipal) Then
									vSupplierInfo = New Map;
									vPrincipalTIN = TrimAll(vPrincipal.TIN);
									vPrincipalName = TrimAll(vPrincipal.LegacyName);
									vPrincipalPhone = TrimAll(vPrincipal.Phone);
									vSuplierInfo = Undefined;
									If ValueIsFilled(vPrincipalName) And ValueIsFilled(vPrincipalPhone) Then
										vPhonesArr = New Array;
										vPhonesArr.Add(SMS.GetPhoneNumberWithCountryCode(vPrincipalPhone));
										vSupplierInfo.Insert("phones", vPhonesArr);
										vSupplierInfo.Insert("name", vPrincipalName);
									EndIf;
									If ValueIsFilled(vPrincipalTIN) Then
										vSupplierInfo.Insert("inn", vPrincipalTIN);
									EndIf;
									vItemsMap.Insert("supplier_info", vSupplierInfo);
								EndIf;
								vAgentInfoMap = New Map;
								// Commissioner attribute
								If vPSRow.ChequeService.PrincipalType = 1 Then
									vAgentInfoMap.Insert("type", "another");
								Else
									vAgentInfoMap.Insert("type", "commission_agent");
								EndIf;
								vItemsMap.Insert("agent_info", vAgentInfoMap);
							EndIf;
							If Not IsBlankString(vPSRow.MarkingCode) Then
								vContainsMarkingCodes = True;
								If vIndustryInfo <> Undefined Then
									vSectoralItemPropsArr = New Array;
									vSectoralItemPropsArr.Add(vIndustryInfo);
									vItemsMap.Insert("sectoral_item_props", vSectoralItemPropsArr);
								EndIf;
								
								vMarkCodeMap = New Map;
								vMarkCodeMap.Insert("gs1m", vPSRow.MarkingCode);
								vItemsMap.Insert("mark_code", vMarkCodeMap);
								vItemsMap.Insert("mark_processing_mode", "0");
							Else
								vCashRegisterItemCode = TrimAll(vPSRow.ChequeService.CashRegisterItemCode);
								If Not IsBlankString(vCashRegisterItemCode) Then
									If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
										vMarkCodeMap = New Map;
										If cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 8 Then
											vMarkCodeMap.Insert("ean8", vCashRegisterItemCode);
										ElsIf cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 13 Then
											vMarkCodeMap.Insert("ean13", vCashRegisterItemCode);
										ElsIf cmIsNumber(vCashRegisterItemCode) And StrLen(vCashRegisterItemCode) = 14 Then
											vMarkCodeMap.Insert("itf14", vCashRegisterItemCode);
										Else
											vMarkCodeMap.Insert("unknown", vCashRegisterItemCode);
										EndIf;
										vItemsMap.Insert("mark_code", vMarkCodeMap);
									Else
										vItemsMap.Insert("nomenclature_code", tcCashRegisters.GetHexItemCode(vCashRegisterItemCode));
									EndIf;
								EndIf;
							EndIf;
							If ValueIsFilled(vPSRow.Item) Then
								vItemsMap.Insert("name", GetString(tcOnServer.cmGetOrderItemDescription(vPSRow.Item), vCashRegister));
							Else
								vItemsMap.Insert("name", GetString(tcOnServer.cmGetServiceDescription(vPSRow.ChequeService), vCashRegister));
							EndIf;
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemPrice = ?(vPSRow.ChequeServicePrice = 0, ?(vSectionAmount >=0, vSectionAmount, -vSectionAmount), vPSRow.ChequeServicePrice);
							vItemQuantity = ?(vPSRow.ChequeServiceQuantity <> 0, vPSRow.ChequeServiceQuantity, 1);
							vItemQuantity = ?(vItemQuantity < 0, -vItemQuantity, vItemQuantity);
							tcCashRegisters.ChequeItemAttributesCorrection(?(vSectionAmount < 0, -vSectionAmount, vSectionAmount), vItemQuantity, 3, vItemPrice, vItemQuantity);
							vItemsMap.Insert("price", vItemPrice);
							vItemsMap.Insert("quantity", vItemQuantity);
						ElsIf ValueIsFilled(vPSRow.PaymentSection) Then
							vItemsMap.Insert("name", GetString(tcOnServer.cmGetPaymentSectionDescription(vPSRow.PaymentSection), vCashRegister));
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("price", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("quantity", 1);
						Else
							If vSectionAmount >=0 Then
								vItemsMap.Insert("name", NStr("en='Hotel services'; de='Hoteldienstleistungen'; ru='Гостиничные услуги'"));
							Else
								vItemsMap.Insert("name", NStr("en='Refund for hotel services'; de='Rückreise für Hoteldienstleistungen'; ru='Возврат за гостиничные услуги'"));
							EndIf;
							vItemsMap.Insert("sum", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("price", ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount));
							vItemsMap.Insert("quantity", 1);
						EndIf;
						vSumTotal = vSumTotal + ?(vSectionAmount < 0, -vSectionAmount, vSectionAmount);
						// Add tax
						vVATRate = Undefined;
						If ValueIsFilled(vPSRow.PaymentSection) Then
							vItemsMap.Insert("vat", GetTaxGroup(vPSRow.PaymentSection, vVATRate, vPSRow.VATRate, pDocument));
						Else
							vItemsMap.Insert("vat", GetTaxGroup(pDocument, vVATRate, vPSRow.VATRate, pDocument));
						EndIf;
						tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, vPSRow.VATSum);
						// Fill format 1.05 attributes and end item
						v1212 = GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pDocument, vPSRow.ChequeService, vPSRow.PaymentSection, vIsPrepayment));
						vItemsMap.Insert("payment_object", v1212);
						If v1212 = 2 Or v1212 = 30 Or v1212 = 31 Then
							// Fill excise value
							If ValueIsFilled(vPSRow.ChequeService) Then
								vItemsMap.Insert("excise", tcCashRegisters.GetChequeItemExciseValue(vPSRow.ChequeService.ExciseDutyType, pDocument.Date, vPSRow.ChequeService.Volume, vItemQuantity));
							EndIf;
						EndIf;
						vItemsMap.Insert("payment_method", vPaymentModeTypeValue);
						If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
							vItemsMap.Insert("measure", GetUnitPiece(vPSRow.ChequeService));
						EndIf;
						
						// Extra functions for extensions
						SendCheck_ChangeItem(vItemsMap, vPSRow, vSum, vSumTotal, vContainsMarkingCodes, pDocument, vCashRegister, vChequeAttributes);
						
						vItemsArr.Add(vItemsMap);
					EndDo;
				Else
					vAmount = 0;
					vVATAmount = 0;
					vSum = 0;
					For Each vPSRow In vPSRows Do
						If vPSRow.Sum = 0 Then
							Continue;
						ElsIf vPSRow.Sum < 0 Then
							Continue;
						Else
							vSum = vSum + vPSRow.Sum;
						EndIf;
						If TypeOf(pDocument.Ref) = Type("DocumentRef.Return") Then
							vAmount = vAmount - vPSRow.Sum;
							vVATAmount = vVATAmount - vPSRow.VATSum;
						Else
							vAmount = vAmount + vPSRow.Sum;
							vVATAmount = vVATAmount + vPSRow.VATSum;
						EndIf;
					EndDo;
					
					vItemsMap = New Map;
					
					// Begin format 1.05 item 
					// Print name, price and quantity
					vSumTotal = vSumTotal + ?(vAmount < 0, -vAmount, vAmount);
					vItemsMap.Insert("name", NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'"));
					vItemsMap.Insert("sum", ?(vAmount < 0, -vAmount, vAmount));
					vItemsMap.Insert("price", ?(vAmount < 0, -vAmount, vAmount));
					vItemsMap.Insert("quantity", 1);
					vVATRate = Undefined;
					vItemsMap.Insert("vat", GetTaxGroup(pDocument, vVATRate, , pDocument));
					tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >=0, vVATAmount, -vVATAmount));
					// Fill format 1.05 attributes and end item
					vItemsMap.Insert("payment_object", GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pDocument, Undefined, Undefined)));
					vItemsMap.Insert("payment_method", GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pDocument.PaymentMethod, pDocument.PaymentSection)));
					If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
						vItemsMap.Insert("measure", GetUnitPiece(Undefined));
					EndIf;
					
					// Extra functions for extensions
					SendCheck_ChangeItem(vItemsMap, Undefined, vSum, vSumTotal, vContainsMarkingCodes, pDocument, vCashRegister, vChequeAttributes);
					
					vItemsArr.Add(vItemsMap);
				EndIf;
			Else
				vVATAmount = pDocument.VATSum;
				If vVATAmount < 0 Then
					vVATAmount = -vVATAmount;
				EndIf;
				
				vItemsMap = New Map;
				
				// Begin format 1.05 item 
				// Print name, price and quantity
				vCommodityName = NStr("en='Hotel services';ru='Гостиничные услуги';de='Hotel Dienstleistungen'");
				If Not vCashRegister.PrintFolioHeader Then
					vCommodityName = "#" + TrimAll(pDocument.Number);
				EndIf;
				If ValueIsFilled(pDocument.PaymentSection) Then
					If vCashRegister.PrintPaymentSectionNamesInCheques Then
						If vCashRegister.PrintFolioHeader Then
							vCommodityName = GetString(tcOnServer.cmGetPaymentSectionDescription(pDocument.PaymentSection), vCashRegister);
						Else
							vCommodityName = GetString(TrimR(vCommodityName) + " - " + tcOnServer.cmGetPaymentSectionDescription(pDocument.PaymentSection), vCashRegister);
						EndIf;
					EndIf;
				EndIf;
				vItemsMap.Insert("name", vCommodityName);
				vItemsMap.Insert("quantity", 1);
				vItemsMap.Insert("sum", ?(vSum < 0, -vSum, vSum));
				vSumTotal = vSumTotal + ?(vSum < 0, -vSum, vSum);
				vItemsMap.Insert("price", ?(vSum < 0, -vSum, vSum));
				// Add tax
				vVATRate = Undefined;
				vItemsMap.Insert("vat", GetTaxGroup(pDocument, vVATRate, , pDocument));
				tcCashRegisters.SetChequeVATAmount(vChequeAttributes, vVATRate, ?(vVATAmount >= 0, vVATAmount, -vVATAmount));
				// Fill format 1.05 attributes and end item
				vItemsMap.Insert("payment_object", GetChequeItemTypeValue(tcCashRegisters.GetChequeItemType(pDocument, Undefined, Undefined)));
				vItemsMap.Insert("payment_method", GetChequePaymentModeTypeValue(tcCashRegisters.GetChequePaymentMode(pDocument.PaymentMethod, pDocument.PaymentSection)));
				If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
					vItemsMap.Insert("measure", GetUnitPiece(Undefined));
				EndIf;
				
				// Extra functions for extensions
				SendCheck_ChangeItem(vItemsMap, Undefined, vSum, vSumTotal, vContainsMarkingCodes, pDocument, vCashRegister, vChequeAttributes);
				
				vItemsArr.Add(vItemsMap);
			EndIf;
			
			// Extra functions for extensions
			SendCheck_ChangeItems(vItemsArr, vPSRows, vSum, vSumTotal, vContainsMarkingCodes, pDocument, vCashRegister, vChequeAttributes);
			
			vReceipt.Insert("items", vItemsArr);
		EndIf;
		
		vPaymentsArr = New Array;
		vPaymentsMap = New Map;
		
		If ValueIsFilled(pDocument.PaymentMethod) Then
			If pDocument.PaymentMethod = Catalogs.PaymentMethods.AdvanceSettlement Then
				vPaymentsMap.Insert("type", 2);
			ElsIf vPaymentMethod.IsByCash Then
				vPaymentsMap.Insert("type", 0);
			ElsIf vPaymentMethod.IsByCreditCard Or vPaymentMethod.IsByBankTransfer Or vPaymentMethod.IsViaInternetAcquiring Then
				vPaymentsMap.Insert("type", 1);
			Else
				vPaymentsMap.Insert("type", vPaymentMethod.CashRegisterChequeCloseType);
			EndIf;
		Else
			vPaymentsMap.Insert("type", 0);
		EndIf;
		
		vPaymentsMap.Insert("sum", ?(vSum > 0, vSum, -vSum));
		
		// Extra functions for extensions
		SendCheck_ChangePayment(vPaymentsMap, vSum, pDocument, vCashRegister, vChequeAttributes);
		
		vPaymentsArr.Add(vPaymentsMap);
		
		// Extra functions for extensions
		SendCheck_ChangePayments(vPaymentsArr, vSum, pDocument, vCashRegister, vChequeAttributes);
		
		vReceipt.Insert("payments", vPaymentsArr);
		
		If pIsCorrection And FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_0_5 Then
			vVatsArr = New Array;
			
			If pDocument.PaymentSections.Count() > 0 Then
				vVatsList = New ValueTable;
				vVatsList.Columns.Add("VATRate", cmGetCatalogTypeDescription("VATRates"));
				vVatsList.Columns.Add("VATSum", cmGetNumberTypeDescription(17, 2, True));
				
				For Each vPSRow In pDocument.PaymentSections Do
					vVatsListRow = vVatsList.Add();
					vVatsListRow.VATRate = vPSRow.VATRate;
					vVatsListRow.VATSum = vVatsListRow.VATSum + vPSRow.VATSum
				EndDo;
				
				vVatsList.GroupBy("VATRate", "VATSum");
				
				For Each vVatsListRow In vVatsList Do
					vVatMap = GetTaxGroup(Catalogs.PaymentSections.EmptyRef(), , vVatsListRow.VATRate, pDocument);
					vVatMap.Insert("sum", vVatsListRow.VATSum);
					vVatsArr.Add(vVatMap);
				EndDo;
			ElsIf ValueIsFilled(pDocument.VATRate) Then
				vVatMap = GetTaxGroup(pDocument, , , pDocument);
				vVatMap.Insert("sum", pDocument.VATSum);
				vVatsArr.Add(vVatMap);
			EndIf;
			
			SendCheck_ChangeVats(vVatsArr, vSum, pDocument, vCashRegister, vChequeAttributes);
			
			vReceipt.Insert("vats", vVatsArr);
		EndIf;
		
		If Not pIsCorrection Or FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
			vReceipt.Insert("total", vSumTotal);
		EndIf;
		
		If vPaymentMethod.IsViaInternetAcquiring Then
			vReceipt.Insert("internet", True);
		Else
			vReceipt.Insert("internet", False);
		EndIf;
		
		If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 And vContainsMarkingCodes And vCashRegister.TimeZone > 0 Then
			vReceipt.Insert("timezone", vCashRegister.TimeZone);
		EndIf;
		
		If vIsPayment Then
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.Receipt");
		Else
			vChequeAttributes.ChequeAccountingType = PredefinedValue("Enum.ChequeAccountingTypes.ReceiptReturn");
		EndIf;
		
		// Extra functions for extensions
		SendCheck_ChangeReceipt(vReceipt, pDocument, vCashRegister, vChequeAttributes);
		
		If pIsCorrection Then
			vBodyMap.Insert("correction", vReceipt);
		Else
			vBodyMap.Insert("receipt", vReceipt);
		EndIf;
		
		// Extra functions for extensions
		SendCheck_ChangeMainBody(vBodyMap, pDocument, vCashRegister, vChequeAttributes);
		
		vMessage = "";
		vResponse = SendRequest(GetAddressByVersions(vOperationType), MapToJson(vBodyMap), "POST", vMessage, , True);
		If vResponse = Undefined Then
			vChequeAttributes.Remarks = vMessage;
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			Return;
		EndIf;
		
		vChequeAttributes.ExternalCode = vResponse["uuid"];
		vChequeAttributes.Remarks = "";
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	Except
		vErrorInfo = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "SendCheck", Enums.ExternalSystemEventTypes.Error, , , ErrorProcessing.DetailErrorDescription(vErrorInfo), InteractionParameters.MaxLogLenght);
		vChequeAttributes.Remarks = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	EndTry;
EndProcedure // SendCheck

// --------------------------------------------------------------------------------
Procedure CheckStatus(pDocument, pExternalCode)
	vChequeAttributes = tcCashRegisters.GetChequeAttributes(pDocument);
	
	Try
		vMessage = "";
		vFail = False;
		vResponse = SendRequest(GetAddressByVersions("report/" + pExternalCode), "", "GET", vMessage, vFail);
		If vResponse = Undefined Then
			vChequeAttributes.Remarks = vMessage;
			If vFail Then
				vChequeAttributes.UUID = New UUID("00000000-0000-0000-0000-000000000000");
				vChequeAttributes.ExternalCode = "";
			EndIf;
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			Return;
		EndIf;
		
		vChequeAttributes.Remarks = "";
		
		If vResponse["status"] = "wait" Then
			tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
			Return;
		EndIf;
		
		vPayload = vResponse["payload"];
		vChequeAttributes.CashDayChequeNumber = vPayload["fiscal_receipt_number"];
		vChequeAttributes.FiscalStorageFactoryNumber = vPayload["fn_number"];
		vChequeAttributes.ChequeSequenceNumber = Format(vPayload["fiscal_document_number"], "NFD=0; NZ=; NG=");
		vChequeAttributes.ChequeFiscalNumber = Format(vPayload["fiscal_document_attribute"], "NFD=0; NZ=; NG=");
		vChequeAttributes.ChequeDateTime = Date(vPayload["receipt_datetime"]);
		vChequeAttributes.CashDay = vPayload["shift_number"];
		vChequeAttributes.ReceiptUrl = vPayload["ofd_receipt_url"];
		
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	Except
		vErrorInfo = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "CheckStatus", Enums.ExternalSystemEventTypes.Error, , , ErrorProcessing.DetailErrorDescription(vErrorInfo), InteractionParameters.MaxLogLenght);
		vChequeAttributes.Remarks = ErrorProcessing.BriefErrorDescription(vErrorInfo);
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	EndTry;
EndProcedure // CheckStatus

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeMainBody(rBodyMap, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeMainBody

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeReceipt(rReceipt, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeReceipt

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeClient(rClientMap, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeClient

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeCompany(rCompanyMap, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeCompany

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeCorrectionInfo(vCorrectionInfoMap, pDocument, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeCorrectionInfo

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeItems(rItemsArr, pPSRows, rSum, rSumTotal, rContainsMarkingCodes, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeItems

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeItem(rItemsMap, pPSRow, rSum, rSumTotal, rContainsMarkingCodes, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeItem

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangePayments(rPaymentsArr, pSum, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangePayments

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangePayment(rPaymentsMap, pSum, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangePayment

// --------------------------------------------------------------------------------
Procedure SendCheck_ChangeVats(rPaymentsMap, pSum, pDocument, pCashRegister, pChequeAttributes)
	// Put code in extension of this function if necessary
EndProcedure // SendCheck_ChangeVats

// --------------------------------------------------------------------------------
Function GetDocuments()
	vQ = New Query;
	vQ.Text =
	"SELECT
	|	ExternalSystemIntegrationData.RefKey1 AS CashRegister
	|INTO CashRegistersList
	|FROM
	|	InformationRegister.ExternalSystemIntegrationData AS ExternalSystemIntegrationData
	|WHERE
	|	ExternalSystemIntegrationData.ExternalSystem = &qExternalSystem
	|	AND ExternalSystemIntegrationData.DataType = ""CashRegisters""
	|	AND ExternalSystemIntegrationData.DataName = ""CashRegister""
	|
	|GROUP BY
	|	ExternalSystemIntegrationData.RefKey1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ChequeAttributes.Payment AS Payment,
	|	ChequeAttributes.ExternalCode AS ExternalCode,
	|	ChequeAttributes.IsCorrection AS IsCorrection,
	|	ChequeAttributes.CorrectionType AS CorrectionType,
	|	ChequeAttributes.CorrectionDescription AS CorrectionDescription,
	|	ChequeAttributes.CorrectionDocumentNumber AS CorrectionDocumentNumber,
	|	ChequeAttributes.CorrectionDocumentDate AS CorrectionDocumentDate,
	|	ChequeAttributes.UUID AS UUID
	|FROM
	|	InformationRegister.ChequeAttributes AS ChequeAttributes
	|		INNER JOIN CashRegistersList AS CashRegistersList
	|		ON ChequeAttributes.CashRegister = CashRegistersList.CashRegister
	|WHERE
	|	ChequeAttributes.ChequeFiscalNumber = """"
	|	AND (ChequeAttributes.Payment.Posted
	|			OR ChequeAttributes.ExternalCode <> """")";
	vQ.SetParameter("qExternalSystem", InteractionParameters);
	Return vQ.Execute().Unload();
EndFunction // GetDocuments

// --------------------------------------------------------------------------------
Function GetAddressByVersions(pOperation, pGetToken = False)
	vVersions = "v4";
	If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
		vVersions = "v5";
	EndIf;
	
	If pGetToken Then
		Return StrTemplate("/possystem/%1/getToken", vVersions);
	Else
		Return StrTemplate("/possystem/%1/%2/%3?token=%4", vVersions, TrimAll(InteractionParameters.HttpAddress), TrimAll(pOperation), TrimAll(InteractionParameters.OAuth_AccessToken));
	EndIf;
EndFunction // GetResourceAddressByVersions

// --------------------------------------------------------------------------------
Function GetTaxationSystemCode(pDocument, rTaxSystem = Undefined)
	rTaxSystem = Undefined;
	vTaxSystemChar = "";
	vPaymentSection = pDocument.PaymentSection;
	If ValueIsFilled(vPaymentSection) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
	ElsIf TypeOf(pDocument.Ref) <> Type("DocumentRef.CustomerPayment") Then
		For Each vPaymentSectionRow In pDocument.PaymentSections Do
			vPaymentSection = vPaymentSectionRow.PaymentSection;
			If vPaymentSectionRow.Sum <> 0 And ValueIsFilled(vPaymentSection) Then
				rTaxSystem = tcOnServer.cmGetAttributeByRef(vPaymentSection, "TaxationSystem");
				If ValueIsFilled(rTaxSystem) Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If Not ValueIsFilled(rTaxSystem) And ValueIsFilled(pDocument.Company) Then
		rTaxSystem = tcOnServer.cmGetAttributeByRef(pDocument.Company, "TaxationSystem");
	EndIf;
	If ValueIsFilled(rTaxSystem) Then
		If rTaxSystem = PredefinedValue("Enum.TaxationSystems.Common") Then
			vTaxSystemChar = "osn";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncome") Then
			vTaxSystemChar = "usn_income";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.SimplifiedIncomeMinusOutcome") Then
			vTaxSystemChar = "usn_income_outcome";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedTaxOnImputedIncome") Then
			vTaxSystemChar = "envd";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.UnifiedAgriculturalTax") Then
			vTaxSystemChar = "esn";
		ElsIf rTaxSystem = PredefinedValue("Enum.TaxationSystems.PatentTaxationSystem") Then
			vTaxSystemChar = "patent";
		EndIf;
	EndIf;
	Return vTaxSystemChar;
EndFunction // GetTaxationSystemCode

// --------------------------------------------------------------------------------
Function GetChequePaymentModeTypeValue(pCMTValue)
	vCMTValueNumber = "full_payment";
	If pCMTValue = Enums.ChequePaymentModes.Prepayment100 Then
		vCMTValueNumber = "full_prepayment";
	ElsIf pCMTValue = Enums.ChequePaymentModes.Prepayment Then
		vCMTValueNumber = "prepayment";
	ElsIf pCMTValue = Enums.ChequePaymentModes.Advance Then
		vCMTValueNumber = "advance";
	ElsIf pCMTValue = Enums.ChequePaymentModes.FullSettlement Then
		vCMTValueNumber = "full_payment";
	ElsIf pCMTValue = Enums.ChequePaymentModes.PartialSettlementAndCredit Then
		vCMTValueNumber = "partial_payment";
	ElsIf pCMTValue = Enums.ChequePaymentModes.TransferToCredit Then
		vCMTValueNumber = "credit";
	ElsIf pCMTValue = Enums.ChequePaymentModes.PaymentOfCredit Then
		vCMTValueNumber = "credit_payment";
	Else
		vCMTValueNumber = "full_payment"; // Full settlement by default
	EndIf;
	Return vCMTValueNumber;
EndFunction // GetChequePaymentModeTypeValue

// --------------------------------------------------------------------------------
Function GetTaxGroup(pObj, rVATRate = Undefined, pRowVATRate = Undefined, pDocObj = Undefined)
	vVatMap = New Map;
	vVatMap.Insert("type", "none");
	
	rVATRate = Undefined;
	If ValueIsFilled(pRowVATRate) Then
		rVATRate = pRowVATRate;
	Else
		rVATRate = pObj.VATRate;
	EndIf;
	
	If Not ValueIsFilled(rVATRate) Then
		Return vVatMap;
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
		vTaxRate = rVATRate.TaxRate;
		vNoVAT = rVATRate.NoVAT;
		vTaxGroup = rVATRate.TaxGroup;
	EndIf;
	
	vAtolTaxGroup = "none";
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
		If vTaxGroup > 4 Then
			vAtolTaxGroup = "vat118";
		Else
			vAtolTaxGroup = "vat18";
		EndIf;
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
			vAtolTaxGroup = "vat" + Format(vTaxRate, "ND=2; NLZ=; NG=");
		EndIf;
	EndIf;
	vVatMap.Insert("type", vAtolTaxGroup);
	Return vVatMap;
EndFunction // GetTaxGroup

// --------------------------------------------------------------------------------
Function GetIndustryInfo(pIsPayment, pPaymentModeTypeValue, pChargesWithMarkingCode, pMarkingCode)
	vFullSettlement = "full_payment";
	vPartialSettlementAndCredit = "partial_payment";
	vTransferToCredit = "credit";
	
	If (pPaymentModeTypeValue <> vFullSettlement And pPaymentModeTypeValue <> vPartialSettlementAndCredit And pPaymentModeTypeValue <> vTransferToCredit) Or Not pIsPayment Or IsBlankString(pMarkingCode) Or pChargesWithMarkingCode[pMarkingCode] = Undefined Then
		Return Undefined;
	EndIf;
	
	vChargeWithMarkingCode = pChargesWithMarkingCode[pMarkingCode];
	If IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckUUID"]) Or IsBlankString(vChargeWithMarkingCode["MarkingCodeCheckDate"]) Then
		Return Undefined;
	EndIf;
	
	vSectoralItemProps = New Map;
	vSectoralItemProps.Insert("federal_id", "030");
	vSectoralItemProps.Insert("date", "21.11.2023");
	vSectoralItemProps.Insert("number", "1944");
	vSectoralItemProps.Insert("value", StrTemplate("UUID=%1&Time=%2", TrimAll(vChargeWithMarkingCode["MarkingCodeCheckUUID"]), TrimAll(vChargeWithMarkingCode["MarkingCodeCheckDate"])));
	Return vSectoralItemProps;
EndFunction // GetIndustryInfo

// --------------------------------------------------------------------------------
Function GetUnitPiece(pService)
	If ValueIsFilled(pService) Then
		vSUnit = pService.Unit;
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
EndFunction // CheckUnitPiece

// --------------------------------------------------------------------------------
Function GetString(pStr, pArrCashRegister)
	vChequeWidth = pArrCashRegister.ChequeWidth;
	If vChequeWidth > 0 Then
		Return Left(pStr, vChequeWidth);
	Else
		Return Left(pStr, 24);
	EndIf;
EndFunction // GetString

// --------------------------------------------------------------------------------
Function GetChequeItemTypeValue(pPTValue)
	If FiscalDataFormatVersions = Enums.FiscalDataFormatVersions.FDF_1_2 Then
		vPTValueNumber = 0;
		If pPTValue = Enums.ChequeItemTypes.Goods Then
			vPTValueNumber = 1;
		ElsIf pPTValue = Enums.ChequeItemTypes.ExcisableGoods Then
			vPTValueNumber = 2;
		ElsIf pPTValue = Enums.ChequeItemTypes.Work Then
			vPTValueNumber = 3;
		ElsIf pPTValue = Enums.ChequeItemTypes.Service Then
			vPTValueNumber = 4;
		ElsIf pPTValue = Enums.ChequeItemTypes.Bet Then
			vPTValueNumber = 5;
		ElsIf pPTValue = Enums.ChequeItemTypes.GamingPrize Then
			vPTValueNumber = 6;
		ElsIf pPTValue = Enums.ChequeItemTypes.LotteryTicket Then
			vPTValueNumber = 7;
		ElsIf pPTValue = Enums.ChequeItemTypes.LotteryWinning Then
			vPTValueNumber = 8;
		ElsIf pPTValue = Enums.ChequeItemTypes.IntellectualProperty Then
			vPTValueNumber = 9;
		ElsIf pPTValue = Enums.ChequeItemTypes.Payment Then
			vPTValueNumber = 10;
		ElsIf pPTValue = Enums.ChequeItemTypes.CompositeSubject Then
			vPTValueNumber = 11;
		ElsIf pPTValue = Enums.ChequeItemTypes.OtherSubject Then
			vPTValueNumber = 12;
		ElsIf pPTValue = Enums.ChequeItemTypes.ResortFee Then
			vPTValueNumber = 18;
		ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithoutMarking Then 
			vPTValueNumber = 30;
		ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithMarking Then 
			vPTValueNumber = 31;
		ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithoutMarking Then 
			vPTValueNumber = 32;
		ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithMarking Then 
			vPTValueNumber = 33;
		Else
			vPTValueNumber = 4; // Service by default
		EndIf;
	Else
		vPTValueNumber ="";
		If pPTValue = Enums.ChequeItemTypes.Goods Then
			vPTValueNumber = "commodity";
		ElsIf pPTValue = Enums.ChequeItemTypes.ExcisableGoods Then
			vPTValueNumber = "excise";
		ElsIf pPTValue = Enums.ChequeItemTypes.Work Then
			vPTValueNumber = "job";
		ElsIf pPTValue = Enums.ChequeItemTypes.Service Then
			vPTValueNumber = "service";
		ElsIf pPTValue = Enums.ChequeItemTypes.Bet Then
			vPTValueNumber = "gambling_bet";
		ElsIf pPTValue = Enums.ChequeItemTypes.GamingPrize Then
			vPTValueNumber = "gambling_prize";
		ElsIf pPTValue = Enums.ChequeItemTypes.LotteryTicket Then
			vPTValueNumber = "lottery";
		ElsIf pPTValue = Enums.ChequeItemTypes.LotteryWinning Then
			vPTValueNumber = "lottery_prize";
		ElsIf pPTValue = Enums.ChequeItemTypes.IntellectualProperty Then
			vPTValueNumber = "intellectual_activity";
		ElsIf pPTValue = Enums.ChequeItemTypes.Payment Then
			vPTValueNumber = "payment";
		ElsIf pPTValue = Enums.ChequeItemTypes.CompositeSubject Then
			vPTValueNumber = "agent_commission";
		ElsIf pPTValue = Enums.ChequeItemTypes.OtherSubject Then
			vPTValueNumber = "award";
		ElsIf pPTValue = Enums.ChequeItemTypes.ResortFee Then
			vPTValueNumber = "resort_fee";
		ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithoutMarking Then 
			vPTValueNumber = "";
		ElsIf pPTValue = Enums.ChequeItemTypes.ExciseWithMarking Then 
			vPTValueNumber = "";
		ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithoutMarking Then 
			vPTValueNumber = "";
		ElsIf pPTValue = Enums.ChequeItemTypes.CommodityWithMarking Then 
			vPTValueNumber = "";
		Else
			vPTValueNumber = 4; // Service by default
		EndIf;
	EndIf;
	Return vPTValueNumber;
EndFunction // GetChequeItemTypeValue

// --------------------------------------------------------------------------------
Function SendRequest(pResourceAddress, pJSON = "", pMethod = "POST", rMessage, rFail = False, pSendCheck = False)
	Try
		vHttpServer = "online.atol.ru";
		If Not IsBlankString(InteractionParameters.HttpServer) Then
			vHttpServer = StrReplace(StrReplace(InteractionParameters.HttpServer, "https://", ""), "http://", "");
		EndIf;
		
		vSSL = Undefined;
		If InteractionParameters.HttpUseSsl Then
			vSSL = New OpenSSLSecureConnection(Undefined, Undefined);
		EndIf;
		
		vHTTPConnection = New HTTPConnection(vHttpServer, , , , , , vSSL);
		
		vHeader = New Map;
		vHeader.Insert("Content-type", "application/json; charset=utf-8");
		
		vHTTPRequest = New HTTPRequest(pResourceAddress, vHeader);
		If Not IsBlankString(pJSON) Then
			vHTTPRequest.SetBodyFromString(pJSON, TextEncoding.UTF8);
		EndIf;
		
		vHTTPResponse = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
		
		vResponseBody = vHTTPResponse.GetBodyAsString(TextEncoding.UTF8);
		Try
			vResponseBodyMap = JsonToMap(vResponseBody);
		Except
			vResponseBodyMap = Undefined;
		EndTry;
		
		If vHTTPResponse.StatusCode <> 200 Then
			vIsError = True;
			rMessage = NStr("en = 'HTTP request status code: '; de = 'HTTP-Anforderungsstatuscode: '; ru = 'Код статуса HTTP запроса: '") + Format(vHTTPResponse.StatusCode, "NFD=0; NG=") + Chars.LF +vResponseBody;
			
			If vHTTPResponse.StatusCode = 401 Then
				vIPObj = InteractionParameters.GetObject();
				vIPObj.OAuth_AccessToken = "";
				vIPObj.Write();
			EndIf;
			
			If vResponseBodyMap <> Undefined Then
				If pSendCheck And vHTTPResponse.StatusCode = 400 And vResponseBodyMap["status"] = "wait" Then
					vIsError = False;
				EndIf;
				
				If vResponseBodyMap["error"] <> Undefined Then
					vErrorMap = vResponseBodyMap["error"];
					If vErrorMap <> Undefined Then
						rMessage =  NStr("en = 'HTTP request status code: '; de = 'HTTP-Anforderungsstatuscode: '; ru = 'Код статуса HTTP запроса: '") + Format(vHTTPResponse.StatusCode, "NFD=0; NG=") + Chars.LF + Format(vErrorMap["code"], "NFD=0; NG=") + ": " + vErrorMap["text"];
					EndIf;
				EndIf;
			EndIf;
			
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vHttpServer+ pResourceAddress, Enums.ExternalSystemEventTypes.Error, pJSON, vResponseBody, rMessage, InteractionParameters.MaxLogLenght);
			If vIsError Then
				Return Undefined;
			EndIf;
		EndIf;
		
		If vResponseBodyMap["status"] = "fail" Then
			vErrorMap = vResponseBodyMap["error"];
			If vErrorMap <> Undefined Then
				rMessage =  NStr("en = 'HTTP request status code: '; de = 'HTTP-Anforderungsstatuscode: '; ru = 'Код статуса HTTP запроса: '") + Format(vHTTPResponse.StatusCode, "NFD=0; NG=") + Chars.LF +Format(vErrorMap["code"], "NFD=0; NG=") + ": " + vErrorMap["text"];
			EndIf;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vHttpServer+ pResourceAddress, Enums.ExternalSystemEventTypes.Error, pJSON, vResponseBody, rMessage, InteractionParameters.MaxLogLenght);
			rFail = True;
			Return Undefined;
		EndIf;
		
		If InteractionParameters.DebugMode And vHTTPResponse.StatusCode = 200 Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vHttpServer + pResourceAddress, Enums.ExternalSystemEventTypes.Info, pJSON, vResponseBody, , InteractionParameters.MaxLogLenght);
		EndIf;
		
		Return vResponseBodyMap;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vHttpServer + pResourceAddress, Enums.ExternalSystemEventTypes.Error, pJSON, ErrorProcessing.DetailErrorDescription(vError), NStr("en = 'Failed to send request!'; de = 'Senden der Anfrage fehlgeschlagen!'; ru = 'Не удалось отправить запрос!'"), InteractionParameters.MaxLogLenght);
		rMessage = ErrorProcessing.BriefErrorDescription(vError);
	EndTry;
	
	Return Undefined;
EndFunction // SendRequest

// --------------------------------------------------------------------------------
Function MapToJson(pMap)
	Try
		vJSONWriter =New JSONWriter;
		vJSONWriter.SetString();
		WriteJSON(vJSONWriter, pMap);
		Return vJSONWriter.Close();
	Except
		Return Undefined;
	EndTry;
EndFunction // MapToJson

// --------------------------------------------------------------------------------
Function JsonToMap(pJson)
	Try
		vJSONReader =New JSONReader;
		vJSONReader.SetString(pJson);
		Return ReadJSON(vJSONReader, True);
	Except
		Return Undefined;
	EndTry;
EndFunction // JsonToMap

#EndRegion

