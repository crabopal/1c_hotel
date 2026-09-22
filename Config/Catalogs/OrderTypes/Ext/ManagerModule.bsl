
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vHotel = Catalogs.Hotels.EmptyRef();
	vDepartment = pData.Department; 
	If ValueIsFilled(vDepartment)Then
		vHotel = vDepartment.Hotel;	
	EndIf; 
	If Not ValueIsFilled(vHotel)Then
		vMessageType = pData.MessageType; 
		If ValueIsFilled(vMessageType)Then
			vHotel = vMessageType.Hotel;	
		EndIf; 	
	EndIf;
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vHotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
