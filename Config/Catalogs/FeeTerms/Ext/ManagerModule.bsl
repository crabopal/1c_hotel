 
#Region EventHandlers

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vHotel = Catalogs.Hotels.EmptyRef();
	vNoShowService = pData.NoShowService;
	If ValueIsFilled(vNoShowService) Then
		vHotel = vNoShowService.Hotel;	
	EndIf;  
	If Not ValueIsFilled(vHotel) Then
		vLateAnnulationService = pData.LateAnnulationService;
		If ValueIsFilled(vLateAnnulationService) Then
			vHotel = vLateAnnulationService.Hotel;	
		EndIf;	
	EndIf;  
	If Not ValueIsFilled(vHotel) Then
		vLateAnnulationStatus = pData.LateAnnulationStatus;
		If ValueIsFilled(vLateAnnulationStatus) Then
			vHotel = vLateAnnulationStatus.Hotel;	
		EndIf;	
	EndIf;   
	If Not ValueIsFilled(vHotel) Then
		vLateAnnulationStatus1 = pData.LateAnnulationStatus1;
		If ValueIsFilled(vLateAnnulationStatus1) Then
			vHotel = vLateAnnulationStatus1.Hotel;	
		EndIf;	
	EndIf;
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vHotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
