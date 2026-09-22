
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vRef = pData.Ref;
	If ValueIsFilled(vRef) Then   
		pPresentation = cmNStr(pData.Description, SessionParameters.CurrentLanguage); 
		pStandardProcessing = False;
	EndIf;
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
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, , pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
