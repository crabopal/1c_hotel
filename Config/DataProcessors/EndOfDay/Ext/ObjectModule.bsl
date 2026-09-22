
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - 	Undefined, Structure - Parametrs for fill 
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Undefined, Structure	 - Parametrs for fill
//  pIsInteractive	 - Boolean				 - is interactive use
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#If ThickClientOrdinaryApplication Then
		OpenForm("DataProcessor.EndOfDay.Form.Form");
	#EndIf
EndProcedure // pmRun

#EndRegion
 