
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DataRow	 - Data
//  pReceiverNode	 - Node	 - Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vRecorder = pData.Filter.Recorder.Value; 	
	If ValueIsFilled(vRecorder) Then
		If TypeOf(vRecorder) = Type("DocumentRef.CloseOfCashRegisterDay") Then
			vCashRegister = vRecorder.CashRegister;
			If ValueIsFilled(vCashRegister) And ValueIsFilled(vCashRegister.Hotel) Then 
				ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vCashRegister.Hotel, pReceiverNode);
			EndIf;
		Else
			ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vRecorder.Hotel, pReceiverNode);	
		EndIf;
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
