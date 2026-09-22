
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Fill(Command)
	FillAtServer(); 
	
	tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Done'; de = 'Getan'; ru = 'Готово'"));
EndProcedure  

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure FillAtServer()
	InformationRegisters.ChatCommands.pmInit();
	InformationRegisters.emoji.pmInit();
EndProcedure

#EndRegion
