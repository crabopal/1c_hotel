// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then
		vArray = New Array;
		vArray.Add(SessionParameters.CurrentHotel);		
		vArray.Add(Catalogs.Hotels.EmptyRef());		
		Parameters.Filter.Insert("Hotel", vArray);
	EndIf;	
	If Parameters.Property("CloseOnChoice") And Parameters.CloseOnChoice <> Undefined Then
		ThisForm.CloseOnChoice = Parameters.CloseOnChoice;
	EndIf;
EndProcedure // OnCreateAtServer
