
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	SetPrivilegedMode(True);
	vCurSession = GetCurrentInfoBaseSession();
	SetPrivilegedMode(False);
	vSessionNumber = vCurSession.SessionNumber;
	vSessionStartTime = vCurSession.SessionStarted;
	vAppRunMode = CachedCommonFunctions.cmGetAppRunMode(vSessionNumber, vSessionStartTime);
	If vAppRunMode.MobileDeviceMode Then 
		If pSelectedForm = "tcResourcesCalendar" Then
			pStandardProcessing = False;
			pSelectedForm = "mcResourcesCalendar";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing  

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion        
