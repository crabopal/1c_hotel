// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vService = pData.Filter.Service.Value;
	If ValueIsFilled(vService) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vService.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges