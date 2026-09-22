#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	If ValueIsFilled(pData.Ref) Then
		vDoc = pData.Ref;  
		vFormatTitle = NStr("en = 'Deposit transfer %1 №%2 - %3 - %4'; de = 'Deposit versch. %1 №%2 - %3 - %4'; ru = 'Перемещ. депозита %1 №%2 - %3 - %4'");
		pPresentation = StrTemplate(vFormatTitle, cmFormatSum(vDoc.SumInFolioFromCurrency, vDoc.FolioFromCurrency, "NZ="),   
		                           TrimAll(pData.Number), pData.Date, TrimAll(vDoc.Author)); 
		
		pStandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing

#EndRegion

