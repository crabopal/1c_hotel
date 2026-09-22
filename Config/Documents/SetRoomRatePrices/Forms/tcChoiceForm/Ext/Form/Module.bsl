
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Multiple choice
	If Parameters.Property("MultipleChoice") And Parameters.MultipleChoice <> Undefined And Parameters.MultipleChoice Then
		Items.List.MultipleChoice = True;
		CloseOnChoice = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
