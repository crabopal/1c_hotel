#Region EventHandlers

// ----------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)	
	vFormParameters = New Structure("Filter",New Structure("Room", pCommandParameter));
	OpenForm("DocumentJournal.RoomInventoryJournal.Form.tcForm", vFormParameters, pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
EndProcedure // CommandProcessing

#EndRegion 


