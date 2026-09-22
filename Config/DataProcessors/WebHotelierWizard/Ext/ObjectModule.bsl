#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // LoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // SaveDataProcessorAttributes

//  -----------------------------------------------------------------------------
//
Procedure pmFillAttributesWithDefaultValues() Export
	// NOTHING SO FAR
EndProcedure // FillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter		 - Structure - Parameter
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	WebHotelier.SyncData(InteractionParameters, HotelCode, AmountOfDaysToUpdate, SkipPricesCacheUpdate, False, LoadReservations, UpdateAvailability, UpdatePrices, GetVacantRoomsAtMidnight);
EndProcedure // Run

#EndRegion