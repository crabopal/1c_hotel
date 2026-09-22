
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export 
	vCashRegister =	pData.CashRegister;
	If ValueIsFilled(vCashRegister) Then
		If ValueIsFilled(vCashRegister.Hotel) Then 
			ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vCashRegister.Hotel, pReceiverNode); 
		EndIf;
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
