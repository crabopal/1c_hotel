
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vReservation = pData.Filter.Reservation.Value;
	If ValueIsFilled(vReservation) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vReservation.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion

