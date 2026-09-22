
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Filter.Property("Guest") And ValueIsFilled(Parameters.Filter.Guest) Then
		Items.Guest.Visible = False;	
	EndIf;
EndProcedure // OnCreateAtServer