
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vSetRoomRateFormulas = pData.Filter.SetRoomRateFormulas.Value;
	If ValueIsFilled(vSetRoomRateFormulas) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vSetRoomRateFormulas.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
