
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure AfterWrite(pWriteParameters)
	Notify("RoomProperties.Changed", Record.Room, ThisForm);
EndProcedure // AfterWrite

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomPropertyOnChange(pItem)
	Record.Author = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	Record.ChangeDate = tcOnServer.GetCurrentSessionDate();
EndProcedure // RoomPropertyOnChange

#EndRegion
