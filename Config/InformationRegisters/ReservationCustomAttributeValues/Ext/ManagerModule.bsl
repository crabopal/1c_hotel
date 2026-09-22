
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vOwner = pData.Filter.Owner.Value;
	If ValueIsFilled(vOwner) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vOwner.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
