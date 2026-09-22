

#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure("RoomQuota",CommandParameter );
	OpenForm("Document.SetRoomQuota.Form.tcListForm",FormParameters , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure

#EndRegion

