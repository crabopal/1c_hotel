// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Record.Hotel) Then
		Record.Hotel = SessionParameters.CurrentHotel;
	EndIf;
	If ValueIsFilled(Record.GuestGroup) And Record.GuestGroup.Owner <> Record.Hotel Then
		Record.Hotel = Record.GuestGroup.Owner;
	EndIf;
EndProcedure // OnCreateAtServer
