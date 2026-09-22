
#Region Public

// --------------------------------------------------------------------------------
Function SetVaucherNumberPresentation(pVaucherNumber, pVaucherType) Export
	vVaucherNumber = TrimAll(pVaucherNumber);
	If cmIsNumber(vVaucherNumber) And ValueIsFilled(pVaucherType) Then
		If pVaucherType.UseVaucherTypeCodeAsVaucherSeries And Not IsBlankString(pVaucherType.Code) Then
			If pVaucherType.SeriesIsAtTheEnd Then
				vVaucherNumber = vVaucherNumber + pVaucherType.SeriesSplitter + TrimAll(pVaucherType.Code);
			Else
				vVaucherNumber = TrimAll(pVaucherType.Code) + pVaucherType.SeriesSplitter + vVaucherNumber;
			EndIf;
		EndIf;
	EndIf;
	Return vVaucherNumber; 
EndFunction // SetVaucherNumberPresentation

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
