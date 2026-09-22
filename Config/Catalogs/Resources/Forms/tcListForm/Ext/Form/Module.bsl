
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vArray = New Array;
	vArray.Add(SessionParameters.CurrentHotel);    
	vArray.Add(Catalogs.Hotels.EmptyRef());    
	Parameters.Filter.Insert("Hotel", vArray);
EndProcedure // OnCreateAtServer

#EndRegion

