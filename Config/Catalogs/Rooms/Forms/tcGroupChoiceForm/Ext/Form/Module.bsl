
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not Parameters.Filter.Property("Owner") Then		
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Owner",vArray);
	EndIf;	
EndProcedure

#EndRegion


