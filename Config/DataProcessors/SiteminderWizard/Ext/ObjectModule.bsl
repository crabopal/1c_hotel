
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
		OpenForm("DataProcessor.SiteminderWizard.Form.tcWizard", New Structure("DataProcessor", ThisObject.DataProcessor));
	#ELSE
		SyncChanges();
	#ENDIF
EndProcedure // pmRun

// -----------------------------------------------------------------------------
Function SyncChanges() Export
	If ValueIsFilled(ThisObject.InteractionParameters) and ValueIsFilled(ThisObject.Login) and ValueIsFilled(ThisObject.Password) and ValueIsFilled(ThisObject.HotelCode) Then		
		Return Siteminder.SyncChanges(ThisObject.Login, ThisObject.Password, ThisObject.InteractionParameters.WSHost, ThisObject.InteractionParameters.HttpAddress, "1CHOTEL", ThisObject.HotelCode, ThisObject.InteractionParameters, True, ThisObject.SyncRates, ThisObject.SyncRestrictions, ThisObject.SyncPeriod, True, ThisObject.GetPrices, ThisObject.DefaultAccomondationType, ThisObject.GetVacantRoomsAtMidnight); 
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Fill all settings!'; ru = 'Введите все настройки!'")) //#Translate
	EndIf;
	Return Undefined;
EndFunction

#EndRegion
