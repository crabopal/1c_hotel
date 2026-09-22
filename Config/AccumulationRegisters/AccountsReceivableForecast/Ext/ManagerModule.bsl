
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
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vRecorder.Hotel, pReceiverNode);
	EndIf;	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
