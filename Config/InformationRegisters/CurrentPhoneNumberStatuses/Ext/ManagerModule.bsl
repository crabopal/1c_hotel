// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vCurrentPhoneNumberStatuses = pData.Filter.CurrentPhoneNumberStatuses.Value;
	If ValueIsFilled(vCurrentPhoneNumberStatuses) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vCurrentPhoneNumberStatuses.Owner, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges