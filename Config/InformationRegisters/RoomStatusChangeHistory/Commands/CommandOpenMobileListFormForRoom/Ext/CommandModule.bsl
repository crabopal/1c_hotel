// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFormParameters = New Structure("Filter", New Structure("Room", pCommandParameter));
	OpenForm("InformationRegister.RoomStatusChangeHistory.Form.mcListForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing
