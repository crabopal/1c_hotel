
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") And ValueIsFilled(Parameters.Hotel) Then
		vHotel = Parameters.Hotel;	 
	Else
		vHotel = SessionParameters.CurrentHotel;
	EndIf;         
	List.Parameters.SetParameterValue("qHotel", vHotel);
EndProcedure // OnCreateAtServer

#EndRegion
