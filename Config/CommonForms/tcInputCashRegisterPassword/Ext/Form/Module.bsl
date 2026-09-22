
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vLabelDescription = ThisForm.Title;
	If Parameters.Property("LabelDescription", vLabelDescription) Then
		ThisForm.Title = vLabelDescription;
	EndIf;	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OK(Command)
	Close(New Structure("Password",Password));
EndProcedure

#EndRegion

