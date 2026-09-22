// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = Parameters.ChoiceMode;
	EndIf;
EndProcedure // OnCreateAtServer
