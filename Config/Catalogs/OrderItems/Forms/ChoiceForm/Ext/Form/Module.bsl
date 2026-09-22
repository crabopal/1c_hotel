&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vHotels = New Array();
	vHotels.Add(SessionParameters.CurrentHotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	Parameters.Filter.Insert("Hotel",vHotels);
EndProcedure
