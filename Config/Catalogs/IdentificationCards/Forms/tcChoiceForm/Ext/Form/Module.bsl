
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Hotel", SessionParameters.CurrentHotel, DataCompositionComparisonType.Equal, , True);
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		// Apply filter by identifier
		If Not IsBlankString(vEventData.DeviceData) Then
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Identifier", vEventData.DeviceData, DataCompositionComparisonType.Equal, , True);
		Else
			tcCommonFunctionOnClientServer.cmAddOrReplaceItemDynamicList(List, "Identifier", , , , False);
		EndIf;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion
