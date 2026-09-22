
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ChoiceMode") and Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
		Items.Tree.ChoiceMode = True;
	EndIf;
EndProcedure
