
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export 
	vHotel = Catalogs.Hotels.EmptyRef();   
	vAuthor = pData.Author;
	If ValueIsFilled(vAuthor) Then
		vHotel = vAuthor.Hotel; 	
	EndIf;
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vHotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
