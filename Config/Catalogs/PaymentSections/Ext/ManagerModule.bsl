
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

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef					 - CatalogRef.PaymentSections	- Ref
//  pLang					 - CatalogRef.Languages			- Ref
// 
// Returns:
//  String - service description
//
Function pmGetDescription(pRef, pLang) Export
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
EndFunction // pmGetDescription      

#EndRegion
