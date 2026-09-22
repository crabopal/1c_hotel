#Region Public

// The procedure ends measuring the time of the key operation
// Called from a wait handler
Procedure FinishTimeIntervalMeasurementAuto() Export
	
	APDEXPerformanceSystemOnClient.FinishTimeIntervalMeasurementNotGlobal();
	
EndProcedure

// The procedure calls the function for recording measurement results on the server
// Called from a wait handler
Procedure ResultWriteNotGlobalAuto() Export 
	
	APDEXPerformanceSystemOnClient.ResultWriteNotGlobal();
	
EndProcedure

// Check application caption
//
Procedure ApplicationCaptionExt() Export

	tcProtection.StartProtection(, True);	
    // Set application caption
	tcOnClient.ChangeApplicationCaption(tcOnServer.cmGetSessionParametersAttribute("CurrentHotel")); 
	
EndProcedure

#EndRegion