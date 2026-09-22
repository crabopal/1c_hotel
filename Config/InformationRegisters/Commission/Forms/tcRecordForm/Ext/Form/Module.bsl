
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(Record.Contract) And Not ValueIsFilled(Record.Agent) Then
		Record.Agent = Record.Contract.Owner; 
	ElsIf Not ValueIsFilled(Record.Contract) And ValueIsFilled(Record.Agent) Then
		Items.Contract.ReadOnly = False;
	ElsIf Not ValueIsFilled(Record.Agent) And ValueIsFilled(Record.Contract) Then
		Items.Agent.ReadOnly = False;	
	EndIf;	
EndProcedure

#EndRegion
