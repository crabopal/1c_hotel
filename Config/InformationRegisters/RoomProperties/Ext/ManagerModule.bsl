
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vRoom = pData.Filter.Room.Value;
	If ValueIsFilled(vRoom) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vRoom.Owner, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
