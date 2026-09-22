// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vSetPriceTagRanges = pData.Filter.SetPriceTagRanges.Value;
	If ValueIsFilled(vSetPriceTagRanges) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vSetPriceTagRanges.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges