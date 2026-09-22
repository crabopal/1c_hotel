
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	vFilter = New Structure("PermissionGroup", CommandParameter);
	vFormParameters = New Structure("Filter", vFilter);
	OpenForm("Catalog.Employees.ListForm", vFormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure

#EndRegion
