&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFormParameters = New Structure("", );
	OpenForm("DataProcessor.CheckGuestKeys.Form", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure
