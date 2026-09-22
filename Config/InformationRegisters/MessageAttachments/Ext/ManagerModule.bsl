
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	If pParameters.Property("Filter") And pParameters.Filter.Property("Message") And ValueIsFilled(pParameters.Filter.Message) Then
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
			EndIf; 
		EndIf;
	EndIf;
EndProcedure // FormGetProcessing   

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
