// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vRoomRate = pData.Filter.RoomRate.Value;
	If ValueIsFilled(vRoomRate) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vRoomRate.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges