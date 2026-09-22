
#Region Public

// -----------------------------------------------------------------------------
Function pmPrintCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pServices = Undefined, pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vObjRef = pObjRef;
	If ValueIsFilled(pObj.Ref) Then
		vObjRef = pObj.Ref;
	EndIf;
	
	vChequeAttributes = tcCashRegisters.GetChequeAttributes(vObjRef);
	If vChequeAttributes = Undefined Then
		vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	EndIf;
	
	Return True;
EndFunction // pmPrintCheque

// -----------------------------------------------------------------------------
Function pmPrintCustomerCheque(Val pSum, Val pVATSum, pObj, pObjRef, rMessage, pPasswordKKM="", pIsCorrection = False, pCorrectionType = Undefined, pCorrectionDescription = "", pCorrectionDocumentNumber = "", pCorrectionDocumentDate = '00010101', pSendPayerContactsToOFD = 0, pEmailToSendToOFD = "", pPhoneToSendToOFD = "") Export
	vObjRef = pObjRef;
	If ValueIsFilled(pObj.Ref) Then
		vObjRef = pObj.Ref;
	EndIf;
	
	vChequeAttributes = tcCashRegisters.GetChequeAttributes(vObjRef);
	If vChequeAttributes = Undefined Then
		vChequeAttributes = tcCashRegisters.InitializeChequeAttributes(pObj, pObjRef, pIsCorrection, pCorrectionType, pCorrectionDescription, pCorrectionDocumentNumber, pCorrectionDocumentDate);
		tcCashRegisters.WriteChequeAttributes(vChequeAttributes);
	EndIf;
		
	Return True;
EndFunction // pmPrintCustomerCheque

// -----------------------------------------------------------------------------
Function pmIsReadyToPrint(rMessage, pSkip24HoursLimitWarning = False, pCashRegister) Export
	Return True;
EndFunction // pmIsReadyToPrint

// -----------------------------------------------------------------------------
Function pmPrintZReport(rMessage, pObj, pPasswordKKM = "") Export
	Return True;
EndFunction // pmPrintZReport

// -----------------------------------------------------------------------------
Function pmPrintNonFiscalCheque(pSum, pVATSum, pObj, pChequeTemplate, rMessage, pPasswordKKM="") Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintNonFiscalCheque

// -----------------------------------------------------------------------------
Function pmPrintCurrentStateOfCalculationsReport(rMessage, pObj, pPasswordKKM="") Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
Function pmPrintXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintXReport

// -----------------------------------------------------------------------------
Function pmPrintHourXReport(rMessage,pCashRegister,pPasswordKKM="") Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintHourXReport

// -----------------------------------------------------------------------------
Function pmPrintSlip(pSlipTextArr, pCashRegister, rMessage, pPasswordKKM="", pOneCopyOnly = False) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmPrintSlip

// -----------------------------------------------------------------------------
Function pmPrintCashIncome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	Return True;
EndFunction // pmPrintCashIncome

// -----------------------------------------------------------------------------
Function pmPrintCashOutcome(Val pSum, pObj, rMessage, pPasswordKKM="") Export
	Return True;
EndFunction // pmPrintCashOutcome

// -----------------------------------------------------------------------------
Function pmOpenCashDrawer(rMessage, pCashRegister) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmOpenCashDrawer

// -----------------------------------------------------------------------------
Function pmSetDeviceTime(rMessage, pCashRegister) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return False;
EndFunction // pmSetDeviceTime

// -----------------------------------------------------------------------------
Function pmGetFDF(rMessage, pCashRegister) Export
	rMessage = NStr("en = 'Not supported in current driver'; de = 'Wird im aktuellen Treiber nicht unterstützt'; ru = 'Не поддерживается в текущем драйвере'");
	Return Undefined;
EndFunction // pmGetFDF

#EndRegion