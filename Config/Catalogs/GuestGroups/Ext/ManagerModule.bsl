
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
		If pFormType = "ListForm" Or pSelectedForm = "tcListForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcListForm";
		ElsIf pFormType = "ObjectForm" Or pSelectedForm = "tcItemForm" Then
          	pStandardProcessing = False;
			pSelectedForm = "mcItemForm";
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
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Owner, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion