#Region EventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	#IF NOT MobileClient THEN
		OpenForm("CommonForm.tcDirectPostingsForm");
	#ELSE
		OpenForm("CommonForm.mcDirectPostingsForm");	
	#ENDIF
EndProcedure // CommandProcessing

#EndRegion
