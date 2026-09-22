// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vResource = pData.Filter.Resource.Value;
	If ValueIsFilled(vResource) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vResource.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges