
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	vCurPres = Data.Description;
	If Not IsBlankString(vCurPres) Then
		vDescription = NStr(vCurPres, SessionParameters.CurrentLanguage);
		If IsBlankString(vDescription) Then
			Presentation = vCurPres;
		Else
			Presentation = vDescription;
		EndIf;	
		StandardProcessing = False;
	EndIf;	
EndProcedure

#EndRegion

#Region Public

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR	
EndProcedure // ExchangePlansRecordChanges

#EndRegion
