// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export  
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, ?(ValueIsFilled(pData.Filter.PaymentSection.Value.Hotel), pData.Filter.PaymentSection.Value.Hotel, Undefined), pReceiverNode);		
EndProcedure // ExchangePlansRecordChanges