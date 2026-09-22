
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Owner") And ValueIsFilled(Parameters.Owner) Then
		If Record.Owner <> Parameters.Owner Then
			Record.Owner = Parameters.Owner;
		EndIf;
	EndIf;
EndProcedure

#EndRegion
