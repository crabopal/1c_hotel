// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vContract = pData.Filter.Contract.Value;
	If ValueIsFilled(vContract) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vContract.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges