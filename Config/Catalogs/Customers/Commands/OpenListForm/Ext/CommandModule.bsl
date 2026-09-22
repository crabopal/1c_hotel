
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	OpenForm("Catalog.Customers.ListForm", New Structure("ChoiceMode", False));
EndProcedure

#EndRegion

