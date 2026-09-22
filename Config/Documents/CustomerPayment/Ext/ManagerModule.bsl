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
		pStandardProcessing = False;
		vDoc = pData.Ref;
		If vDoc.Sum >= 0 Then
			pPresentation = NStr("en='Customer payment '; ru='Платеж контрагента '; de='Zahlung vom Firma '") + TrimAll(vDoc.PaymentMethod) + " " + cmFormatSum(vDoc.Sum, vDoc.PaymentCurrency) + NStr("en=' N'; ru=' №'; de=' N'") + TrimAll(pData.Number) + " - " + Format(pData.Date, "DF='dd.MM.yyyy HH:mm:ss'") + " - " + TrimAll(vDoc.Author);
		Else
			pPresentation = NStr("en='Customer refund '; ru='Возврат контрагенту '; de='Rückerstattung zu Firma '") + TrimAll(vDoc.PaymentMethod) + " " + cmFormatSum(-vDoc.Sum, vDoc.PaymentCurrency) + NStr("en=' N'; ru=' №'; de=' N'") + TrimAll(pData.Number) + " - " + Format(pData.Date, "DF='dd.MM.yyyy HH:mm:ss'") + " - " + TrimAll(vDoc.Author);
		EndIf;
	EndIf;
EndProcedure // PresentationGetProcessing

#EndRegion

