
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameters
//
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
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Structure - Parameters
//  pIsInteractive	 - Boolean	 - IsInteractive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.Bitrix24.Form.Form",New Structure("DataProcessor",ThisObject.DataProcessor));
	#ELSE
		Bitrix24.SynchDataWithBitrix24(InteractionParameters,, SyncTasks, SyncClients, SyncCustomers, SyncDeals);
	#ENDIF
EndProcedure // pmRun

#EndRegion


