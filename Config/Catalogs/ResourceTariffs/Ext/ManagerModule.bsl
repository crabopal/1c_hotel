#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	vHotelFilter = New Array;
	vHotelFilter.Add(SessionParameters.CurrentHotel);
	vHotelFilter.Add(Catalogs.Hotels.EmptyRef());
	
	pParameters.Filter.Insert("Hotel", vHotelFilter);
EndProcedure

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
