
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data 
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Filter.Hotel.Value, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges     

#EndRegion