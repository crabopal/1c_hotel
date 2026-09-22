// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Record.Hotel) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer
