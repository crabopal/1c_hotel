
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Filter") Then
		If Not Parameters.Filter.Property("Hotel") Then
			Parameters.Filter.Insert("Hotel", vHotel);
		Else
			Parameters.Filter.Hotel = vHotel;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

