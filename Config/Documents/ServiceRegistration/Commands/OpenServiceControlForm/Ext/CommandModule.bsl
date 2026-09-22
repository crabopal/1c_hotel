

#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vFormParameters = New Structure("", );
	OpenForm("Document.ServiceRegistration.Form.tcServiceControlForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure

#EndRegion

