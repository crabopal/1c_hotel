
#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	vObject = pData.Filter.Object.Value;
	If ValueIsFilled(vObject) Then
		// ExchangePlansProcessing.ExchangePlansRecordChanges(pData, vObject.Hotel, pReceiverNode);
	EndIf;		
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
//  Write user event log
//
// Parameters:
//  pClient	 - CatalogRef.Clients	 - Ref
//  pSource	 - String				 - Source information
//  pHotel	 - CatalogRef.Hotels	 - Ref
//  pUser	 - CatalogRef.Employees	 - Ref user
//  pDate	 - Date					 - Date changes
//
Procedure AddRecord(pClient, pSource, pHotel = Undefined, pUser = Undefined, pDate = Undefined) Export
    vUser = SessionParameters.CurrentUser;
	If Not pUser = Undefined Then
		vUser = pUser;
	EndIf;
	vDate = CurrentSessionDate();
	If Not pDate = Undefined Then
		vDate = pDate;
	EndIf; 
	vHotel = SessionParameters.CurrentHotel;
	If ValueIsFilled(pHotel) Then
		vHotel = pHotel;
	EndIf;	
	vRec = InformationRegisters.PersonalDataSources.CreateRecordManager();
	vRec.Period = vDate;  
	vRec.Hotel = vHotel;
	vRec.User = vUser;
	vRec.Client = pClient;
	vRec.Source = pSource;
				
	// Write record
	vRec.Write(True);
EndProcedure

#EndRegion
