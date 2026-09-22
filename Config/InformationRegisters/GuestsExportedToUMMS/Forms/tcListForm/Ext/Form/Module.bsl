// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Hotel") Then		
		Parameters.Filter.Insert("Hotel", SessionParameters.CurrentHotel);
	EndIf;	
EndProcedure // OnCreateAtServer
