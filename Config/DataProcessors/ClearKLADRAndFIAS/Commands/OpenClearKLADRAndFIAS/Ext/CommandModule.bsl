
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFormParameters = New Structure("", );
	OpenForm("DataProcessor.ClearKLADRAndFIAS.Form", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure

#EndRegion

