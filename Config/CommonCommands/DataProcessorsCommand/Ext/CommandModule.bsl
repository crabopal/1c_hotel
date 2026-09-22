#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("CommonForm.tcDataProcessorsList", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window);
EndProcedure // CommandProcessing

#EndRegion
