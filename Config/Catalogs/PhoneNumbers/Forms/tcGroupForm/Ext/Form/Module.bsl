// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Owner) Then
		Object.Owner = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer
