
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
		If pFormType = "ObjectForm" Or pSelectedForm = "tcDocumentForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcDocumentForm";
		ElsIF pFormType = "ListForm" Or pSelectedForm = "tcListForm" Then
			pStandardProcessing = False;
			pSelectedForm = "mcListForm";	
		EndIf;                               
	EndIf;
EndProcedure // FormGetProcessing

#EndRegion   

#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
