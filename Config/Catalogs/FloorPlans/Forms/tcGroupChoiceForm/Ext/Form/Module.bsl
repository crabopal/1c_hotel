
#Region FormEventHandlers

// ------------------------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Filter") And Parameters.Filter.Property("Hotel") And ValueIsFilled(Parameters.Filter.Hotel) Then
		vHotel = Parameters.Filter.Hotel;
	Else
		vHotel = SessionParameters.CurrentHotel;	
	EndIf;                                                          
	List.Parameters.SetParameterValue("qHotel", vHotel);	
EndProcedure // OnCreateAtServer

#EndRegion
