
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data 
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export  
	vRecorder = pData.Filter.Recorder.Value;
	If ValueIsFilled(vRecorder) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vRecorder.Hotel, pReceiverNode);
	EndIf;		
EndProcedure // ExchangePlansRecordChanges     

#EndRegion     
