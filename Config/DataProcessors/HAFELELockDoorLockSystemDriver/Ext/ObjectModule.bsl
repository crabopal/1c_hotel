
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Dataprocessor parameters
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure //  pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure //  pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export

EndProcedure //  pmFillAttributesWithDefaultValues

#EndRegion
