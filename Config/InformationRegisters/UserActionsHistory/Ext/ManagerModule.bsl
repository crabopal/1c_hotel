
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
//  pHotel	 - CatalogRef.Hotels - Ref
//  pObject	 - AnyRef			 - Ref on catalog or document
//  pChanges - String			 - User changes
//  pUser	 - CatalogRef.Employees	 - Ref user
//  pDate	 - Date					 - Date changes
//
Procedure WriteUserActivityRecord(pObject, pChanges, pHotel = Undefined, pUser = Undefined, pDate = Undefined) Export
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
	vUserLogRec = InformationRegisters.UserActionsHistory.CreateRecordManager();
	vUserLogRec.Period = vDate;  
	vUserLogRec.Hotel = vHotel;
	vUserLogRec.User = vUser;
	vUserLogRec.Object = pObject;
	vUserLogRec.Changes = pChanges;
				
	// Write record
	vUserLogRec.Write(True);
EndProcedure

#EndRegion
