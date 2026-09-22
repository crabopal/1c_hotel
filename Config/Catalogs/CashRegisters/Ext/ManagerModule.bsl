
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	If ValueIsFilled(pData.Hotel) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
