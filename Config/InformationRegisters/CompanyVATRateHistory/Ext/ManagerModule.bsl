// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export  
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, ?(ValueIsFilled(pData.Filter.Company.Value.Hotel), pData.Filter.Company.Value.Hotel, Undefined), pReceiverNode);		
EndProcedure // ExchangePlansRecordChanges