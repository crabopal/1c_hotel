
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Room") Then
			If ValueIsFilled(Parameters.Filter.Room) Then
				Items.Room.Visible = False;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
