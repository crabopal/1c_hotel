
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

#Region EventHandlers

 // --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vRef = pData.Ref;
	If ValueIsFilled(vRef.Parent) Then
		pStandardProcessing = False;
		pPresentation = TrimAll(vRef.Parent.Description) + " / " + TrimAll(pData.Description);
	EndIf;
EndProcedure // PresentationGetProcessing

#EndRegion
