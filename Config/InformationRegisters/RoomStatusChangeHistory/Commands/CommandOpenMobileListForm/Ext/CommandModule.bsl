// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	If ValueIsFilled(pCommandParameter) Then
		vFormParameters = New Structure("Filter", New Structure("Room", pCommandParameter));
	Else
		vFormParameters = New Structure();
	EndIf;
	OpenForm("InformationRegister.RoomStatusChangeHistory.Form.mcListForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing
