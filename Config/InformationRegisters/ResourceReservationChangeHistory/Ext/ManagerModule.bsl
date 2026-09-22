// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vResourceReservation = pData.Filter.ResourceReservation.Value;
	If ValueIsFilled(vResourceReservation) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vResourceReservation.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges