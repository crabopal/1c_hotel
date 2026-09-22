// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vSetRoomRatePrices = pData.Filter.SetRoomRatePrices.Value;
	If ValueIsFilled(vSetRoomRatePrices) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vSetRoomRatePrices.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges