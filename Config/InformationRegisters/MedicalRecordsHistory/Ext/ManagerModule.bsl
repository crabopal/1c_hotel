
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Filter.Hotel.Value, pReceiverNode);		
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Procedure WriteData(pClient, pAccommodation = Undefined, pHotel = Undefined, pDiagnosisNumber = 0, pDate = '00010101', pIsMainDiagnosis = False, pICD10 = Undefined, pTreatmentResults = Undefined) Export 

	If Not ValueIsFilled(pClient) Then
		Return;	
	EndIf;
		
	vMRHRecMgr = InformationRegisters.MedicalRecordsHistory.CreateRecordManager();
	
	vMRHRecMgr.Client 			= pClient;
	vMRHRecMgr.Accommodation	= pAccommodation;
	If ValueIsFilled(pHotel) Then
		vMRHRecMgr.Hotel		= pHotel;
	ElsIf ValueIsFilled(pAccommodation) Then
		vMRHRecMgr.Hotel		= pAccommodation.Hotel;	
	Else
		vMRHRecMgr.Hotel		= SessionParameters.CurrentHotel;	
	EndIf;
	vMRHRecMgr.DiagnosisNumber	= pDiagnosisNumber;
	vMRHRecMgr.Date				= pDate;
	vMRHRecMgr.IsMainDiagnosis	= pIsMainDiagnosis;
	vMRHRecMgr.ICD10			= pICD10;
	vMRHRecMgr.TreatmentResults = pTreatmentResults;
	
	vMRHRecMgr.Write(True);
EndProcedure // WriteData

#EndRegion
