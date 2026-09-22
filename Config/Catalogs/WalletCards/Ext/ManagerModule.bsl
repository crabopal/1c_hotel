
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vCardOwner = pData.CardOwner;
	If ValueIsFilled(vCardOwner) Then 
		vHotel = Catalogs.Hotels.EmptyRef();
		If TypeOf(vCardOwner) = Type("CatalogRef.DiscountCards") Then
			vHotel = vCardOwner.CreateHotel; 	
		Else
			vHotel = vCardOwner.Hotel;	
		EndIf;       
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vHotel, pReceiverNode);
	Else
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
