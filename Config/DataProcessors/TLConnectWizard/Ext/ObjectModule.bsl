
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
	// NONE SO FAR
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	#IF CLIENT THEN
		OpenForm("DataProcessor.TLConnectWizard.Form.tcWizardForm", New Structure("DataProcessor", ThisObject.DataProcessor));	
	#ELSE
		TLConnect.SyncData(InteractionParameters, HotelCode, AmountOfDaysToUpdate, SkipPricesCacheUpdate, DoFullSync, LoadReservations, UpdateAvailability, UpdatePrices, GetPrices, UsePriceTags, GetVacantRoomsAtMidnight, ReceiveBonusPayments);
	#ENDIF
EndProcedure // pmRun

#EndRegion
