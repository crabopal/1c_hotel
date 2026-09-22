&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	OpenForm("AccumulationRegister.TouristTaxToBePaid.ListForm", New Structure("Filter", New Structure("Recorder", pCommandParameter)), pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure
