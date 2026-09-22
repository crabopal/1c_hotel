#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("DataProcessor.ShowShortcuts.Form", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing

#EndRegion