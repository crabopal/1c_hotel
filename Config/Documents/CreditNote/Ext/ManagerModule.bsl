
#Region EventHandlers

// ------------------------------------------------------------------------------
Procedure PresentationGetProcessing(pData, pPresentation, pStandardProcessing)
	vRef = pData.Ref;
	If ValueIsFilled(vRef) and ValueIsFilled(vRef.AccountingCustomer) and ValueIsFilled(vRef.AccountingCurrency) Then
		pPresentation = NStr("en = 'Credit note'; ru = 'Кред. корр.'; de = 'Gutschrift'") + 
		               " " + Trimall(vRef.AccountingCustomer) + 
					   NStr("en = ' for '; ru = ' на '; de = ' für '") + cmFormatSum(vRef.CorrectionSum, vRef.AccountingCurrency) + 
					   NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.Date, "DF=dd.MM.yyyy") + 
					   " №" + TrimAll(pData.Number);
		pStandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - DocumentRef - Ref
//  pReceiverNode	 - Node	 - Ref
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

