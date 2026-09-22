&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Filter by hotel
	If Not Parameters.Filter.Property("Hotel") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	Else
		vArray = New Array;
		vArray.Add(Parameters.Filter.Hotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;
EndProcedure // OnCreateAtServer
