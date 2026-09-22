
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Record.Hotel = SessionParameters.CurrentHotel;
EndProcedure
