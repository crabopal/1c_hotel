// -----------------------------------------------------------------------------
// Data processors framework start
// -----------------------------------------------------------------------------

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
	If Not ValueIsFilled(Hotel) Then
		Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If FreeOfChargeCheckOutDelay = 0 Then
		FreeOfChargeCheckOutDelay = 20;
	EndIf;
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
// Run data processor in silent mode
// -----------------------------------------------------------------------------
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
	// Run in-house guests period of stay extension routine
	pmExtendInHouseGuestsPeriodOfStay(pIsInteractive);
EndProcedure // pmRun

// -----------------------------------------------------------------------------
// Data processors framework end
// -----------------------------------------------------------------------------
	
// -----------------------------------------------------------------------------
Procedure pmExtendInHouseGuestsPeriodOfStay(pIsInteractive = False) Export
	#IF CLIENT THEN
		WriteLogEvent(NStr("en='DataProcessor.ExtendInHouseGuestsPeriodOfStay';ru='Обработка.ПродлитьПериодПроживанияГостей';de='DataProcessor.ExtendInHouseGuestsPeriodOfStay'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'"));
		cmExtendInHouseGuestsPeriodOfStay(Hotel, FreeOfChargeCheckOutDelay, pIsInteractive);
		WriteLogEvent(NStr("en='DataProcessor.ExtendInHouseGuestsPeriodOfStay';ru='Обработка.ПродлитьПериодПроживанияГостей';de='DataProcessor.ExtendInHouseGuestsPeriodOfStay'"), EventLogLevel.Information, ThisObject.Metadata(), Undefined, NStr("en='End of processing';ru='Конец выполнения';de='Ende des Ausführung'"));
	#ENDIF
EndProcedure // pmExtendInHouseGuestsPeriodOfStay
