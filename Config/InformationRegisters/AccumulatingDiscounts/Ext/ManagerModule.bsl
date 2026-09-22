
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data 
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vDiscountType = pData.Filter.DiscountType.Value;
	If ValueIsFilled(vDiscountType) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vDiscountType.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges       

#EndRegion