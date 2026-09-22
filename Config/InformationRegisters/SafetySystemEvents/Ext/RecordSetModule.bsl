
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)   
	If DataExchange.Load Then
		Return;
	EndIf;
	vUserExitProc = Catalogs.ExternalDataProcessors.SendSafetySystemEventsToExternalSystem;
	If ValueIsFilled(vUserExitProc) Then
		If vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.Algorithm Then
			If Not IsBlankString(vUserExitProc.Algorithm) Then
				SetSafeMode(True);
				Execute(TrimAll(vUserExitProc.Algorithm));
				SetSafeMode(False);
			EndIf;
		ElsIf vUserExitProc.ExternalProcessingType = Enums.ExternalProcessingTypes.DataProcessor Then	
			vDPObj = cmGetExternalDataProcessorObject(vUserExitProc);
			If Not vDPObj = Undefined Then
				vDPObj.pmLoadDataProcessorAttributes();
				vDPObj.pmRun();
			EndIf;	
		EndIf;
	EndIf;
EndProcedure

#EndRegion
