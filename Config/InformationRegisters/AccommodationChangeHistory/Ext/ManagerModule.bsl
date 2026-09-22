
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data 
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vAccommodation = pData.Filter.Accommodation.Value;
	If ValueIsFilled(vAccommodation) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vAccommodation.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
