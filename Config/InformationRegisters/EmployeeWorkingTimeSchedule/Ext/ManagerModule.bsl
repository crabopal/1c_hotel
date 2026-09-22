
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vEmployee = pData.Filter.Employee.Value;
	If ValueIsFilled(vEmployee) Then
		ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vEmployee.Hotel, pReceiverNode);
	EndIf;
EndProcedure // ExchangePlansRecordChanges

#EndRegion
