
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
			pSelectedForm = "mcHousekeepingForm";
		ElsIf pFormType = "ObjectForm" Or pSelectedForm = "tcItemForm" Then
          	pStandardProcessing = False;
			pSelectedForm = "mcHousekeepingItemForm";
		ElsIf pFormType = "ChoiceForm" Or pSelectedForm = "tcChoiceForm" Then 
			pStandardProcessing = False;
			pSelectedForm = "mcChoiceForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing

// -----------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("Owner") Or pParameters.Filter.Property("Owner") And Not ValueIsFilled(pParameters.Filter.Owner) Then
		If ValueIsFilled(SessionParameters.CurrentHotel) Then
			pParameters.Filter.Insert("Owner", SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
EndProcedure

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
