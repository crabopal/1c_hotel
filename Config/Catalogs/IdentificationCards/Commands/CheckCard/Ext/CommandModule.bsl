#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vInteraction = GetInteraction();
	If ValueIsFilled(vInteraction) Then
		vParamCard = New Structure();
		vParamCard.Insert("ExternalSystemInteraction", vInteraction);
		vParamCard.Insert("IsDetailsInfo", False);
		OpenForm("Catalog.IdentificationCards.Form.tcISDCardInfo", vParamCard, , ,,,,FormWindowOpeningMode.LockOwnerWindow);
	Else
		// other system
	EndIf;
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetInteraction() 
	vIdentityCardSystemParameters = Undefined;
	vCurWstn = SessionParameters.CurrentWorkstation;
	If ValueIsFilled(vCurWstn) Then
		If vCurWstn.HasConnectionToIdentityCardsProcessingSystem Then
			vIdentityCardSystemParameters = vCurWstn.IdentityCardsProcessingSystemParameters;
		EndIf;
	EndIf;
	vExternalInteraction = Undefined;
	If ValueIsFilled(vIdentityCardSystemParameters) And ValueIsFilled(vIdentityCardSystemParameters.ExternalInteraction) Then
		vExternalInteraction = vIdentityCardSystemParameters.ExternalInteraction;
	EndIf;
	Return vExternalInteraction;
EndFunction // GetInteraction

#EndRegion
