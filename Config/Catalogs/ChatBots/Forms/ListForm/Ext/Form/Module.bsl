  
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure UpdateEmoji(Command)
	UpdateEmojiAtServer();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateEmojiAtServer()
	InformationRegisters.emoji.pmInit();
	InformationRegisters.ChatCommands.pmInit();
EndProcedure

#EndRegion
