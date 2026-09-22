
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
		If pFormType = "ChoiceForm" Or pSelectedForm = "tcChoiceForm" Then 
			pStandardProcessing = False;
			pSelectedForm = "mcChoiceForm";
		EndIf; 
	EndIf;
EndProcedure // FormGetProcessing

// -----------------------------------------------------------------------------
Procedure ChoiceDataGetProcessing(pChoiceData, pParameters, pStandardProcessing)
	If Not pParameters.Filter.Property("Owner") Or pParameters.Filter.Property("Owner") And Not ValueIsFilled(pParameters.Filter.Owner) Then
		pParameters.Filter.Insert("Owner", SessionParameters.CurrentHotel);
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

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRef	 - CatalogRef.RoomTypes - Ref					 - 
//  pLang	 - CatalogRef.Languages	 - Language
// 
// Returns:
//  String - Room type description
//
Function pmGetRoomTypeDescription(pRef, pLang) Export
	vDescr = "";
	If Not ValueIsFilled(pLang) Then
		vDescr = TrimAll(pRef.Description);
	Else
		If IsBlankString(pRef.DescriptionTranslations) Then
			vDescr = TrimAll(pRef.Description);
		Else
			vDescr = TrimAll(cmNStr(pRef.DescriptionTranslations, pLang));
		EndIf;
	EndIf;
	Return vDescr;
EndFunction // pmGetRoomTypeDescription

#EndRegion  
