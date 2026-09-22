// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Owner") Then
			If ValueIsFilled(Parameters.Filter.Owner) Then
				Items.Owner.Visible = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
