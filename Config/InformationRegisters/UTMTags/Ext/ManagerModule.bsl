// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vGuestGroup = pData.Filter.GuestGroup.Value;
	If ValueIsFilled(vGuestGroup) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vGuestGroup.Owner, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges