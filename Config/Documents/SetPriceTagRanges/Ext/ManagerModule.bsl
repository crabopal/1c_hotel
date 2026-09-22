
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DocimentRef.Folio - Ref
//  pReceiverNode	 - Node				 - Ref
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
