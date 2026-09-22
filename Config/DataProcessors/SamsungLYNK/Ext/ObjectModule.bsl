
#Region Public

// -----------------------------------------------------------------------------
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
// Initialize attributes with default values
// Attention: This procedure could be called AFTER some attributes initialization
// routine, so it SHOULD NOT reset attributes being set before
// -----------------------------------------------------------------------------
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.SamsungLYNK.Form.Form",New Structure("DataProcessor", ThisObject.DataProcessor));
	#ELSE	
		SamsungLYNK.Sync(ExternalInteraction);
		If IsAutomaticallySyncData Then
			vCurDate = CurrentSessionDate();
			If BegOfDay(ExternalInteraction.LastFullSynchronizationTime) < BegOfDay(vCurDate) And ExternalInteraction.FullSynchronizationTime <= vCurDate - BegOfDay(vCurDate) Then
				vMessage = ""; 
				If SamsungLYNK.Hello(ExternalInteraction, vMessage) Then
					vObj = ExternalInteraction.GetObject();
					vObj.LastFullSynchronizationTime = vCurDate;
					vObj.Write();
				EndIf;
			EndIf;
		EndIf;
	#ENDIF
EndProcedure // pmRun

#EndRegion


