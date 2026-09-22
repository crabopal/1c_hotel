#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Filter.Hotel.Value, pReceiverNode);	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
