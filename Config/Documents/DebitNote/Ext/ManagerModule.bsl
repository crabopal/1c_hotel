#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region EventHandlers

// ------------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	vRef = Data.Ref;
	If ValueIsFilled(vRef) and ValueIsFilled(vRef.AccountingCustomer) and ValueIsFilled(vRef.AccountingCurrency) Then
		Presentation = NStr("en = 'Debit note'; ru = 'Дебет. корр.'; de = 'Lastschrift'") + 
		               " " + Trimall(vRef.AccountingCustomer) + 
					   NStr("en = ' for '; ru = ' на '; de = ' für '") + cmFormatSum(vRef.CorrectionSum, vRef.AccountingCurrency) + 
					   NStr("en = ' from '; ru = ' c '; de = ' ab '") + Format(vRef.Date, "DF=dd.MM.yyyy") + 
					   " №" + TrimAll(Data.Number);
		StandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing


#EndRegion
