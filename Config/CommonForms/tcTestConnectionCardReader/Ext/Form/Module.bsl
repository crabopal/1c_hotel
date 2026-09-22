
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	IdentityCardsSystemParameter = Parameters.IdentityCardsSystemParameter;
	If Not ValueIsFilled(IdentityCardsSystemParameter) Then
		pCancel = True;
		Return;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	#IF Not ThickClientOrdinaryApplication THEN
		vRC = New Map;
		tcOnClient.cmDisconnectReader(amReaderMC, vRC, amIdentityCardsProcessing);
		amReaderMC = Undefined;
		
		amIdentityCardsProcessing = tcOnServer.cmGetAtributeAsArray(IdentityCardsSystemParameter);
		
		amReaderMC = tcOnClient.cmConnectReader(amIdentityCardsProcessing, vRC);
		If amReaderMC = Undefined Then
			vErrorCode = vRC.Get("RC_CODE"); 
			vErrorDescription = vRC.Get(vErrorCode);
			vMessage = StrTemplate(NStr("en = 'Error connecting to MC reader! Error code: %1. Error description: %2'; 
										|de = 'Reader-Verbindungsfehler! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										|ru = 'Ошибка подключения считывателя! Код ошибки: %1. Описание ошибки: %2'"), vErrorCode, vErrorDescription);
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
			pCancel = True;
			Return;
		EndIf;
	#EndIf
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "MagneticStripeCardReader" Then
		CardData = vEventData.DeviceData;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion