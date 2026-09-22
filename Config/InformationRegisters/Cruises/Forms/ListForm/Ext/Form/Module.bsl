
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Parameters.Filter.Insert("Hotel",SessionParameters.CurrentHotel);
	Title = String(SessionParameters.CurrentHotel);
EndProcedure
