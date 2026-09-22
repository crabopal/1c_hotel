// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vServicePackage = pData.Filter.ServicePackage.Value;
	If ValueIsFilled(vServicePackage) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vServicePackage.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges