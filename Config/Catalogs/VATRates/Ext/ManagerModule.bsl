
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("DeletionMark") Then
		pParameters.Filter.Insert("DeletionMark", False);
	EndIf;
EndProcedure // ChoiceDataGetProcessing

#EndRegion
