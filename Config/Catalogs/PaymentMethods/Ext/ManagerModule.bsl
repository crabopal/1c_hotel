
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

// -----------------------------------------------------------------------------
Function pmGetPaymentMethodDescription(pRef, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pRef.Description);
	Else
		If IsBlankString(pRef.DescriptionTranslations) Then
			vDescr = TrimAll(pRef.Description);
		Else
			vDescr = TrimAll(cmNStr(pRef.DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetPaymentMethodDescription

#EndRegion
