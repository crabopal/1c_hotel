
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
	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	vDataTypes = New Array();
	vDataTypes.Add("reservations");
	vDataRequestResult = ProlongedOperations.ExternalSystemDataRequest(InteractionParameters, vDataTypes,,, True);
	If TypeOf(vDataRequestResult) = Type("Map") And vDataRequestResult["Error"] <> Undefined Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, "ProlongedOperations.ExternalSystemDataRequest", Enums.ExternalSystemEventTypes.Error, , , vDataRequestResult["Error"]);		
	EndIf;
EndProcedure // pmRun

#EndRegion

