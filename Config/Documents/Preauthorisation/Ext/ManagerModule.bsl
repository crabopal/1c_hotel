
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If ValueIsFilled(Data.Ref) Then
		doc = Data.Ref;
		Presentation = NStr("en = 'Preauth.'; ru = 'Преавтор.'; de = 'Vorautorisierung'") + 
		               ?(ValueIsFilled(doc.PaymentMethod), " " + Trimall(doc.PaymentMethod), "") + " " + 
					    cmFormatSum(doc.Sum, doc.PaymentCurrency, "NZ=") +
					   " №" + TrimAll(Data.Number) + " - " + Data.Date + " - " + TrimAll(doc.Author);
		StandardProcessing = False;
	EndIf;
EndProcedure // PresentationGetProcessing

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion

