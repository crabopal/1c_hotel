
#Region FormEventHandlers

Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vCurPres = pData.Description;
	If Not IsBlankString(vCurPres) Then
		vDescription = NStr(vCurPres, SessionParameters.CurrentLanguage);
		If IsBlankString(vDescription) Then
			pPresentation = vCurPres;
		Else
			pPresentation = vDescription;	
		EndIf;	
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
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
