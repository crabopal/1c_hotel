// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vSpecialOffer = pData.Filter.SpecialOffer.Value;
	If ValueIsFilled(vSpecialOffer) Then	
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vSpecialOffer.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges