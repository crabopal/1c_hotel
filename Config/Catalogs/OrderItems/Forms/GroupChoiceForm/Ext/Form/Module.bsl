// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotels = New Array();
	vHotels.Add(SessionParameters.CurrentHotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	Parameters.Filter.Insert("Hotel", vHotels);
EndProcedure // OnCreateAtServer
