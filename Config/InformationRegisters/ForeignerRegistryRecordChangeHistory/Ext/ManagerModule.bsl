// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vForeignerRegistryRecord = pData.Filter.ForeignerRegistryRecord.Value;
	If ValueIsFilled(vForeignerRegistryRecord) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vForeignerRegistryRecord.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges