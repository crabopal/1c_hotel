
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	If Not Parameters.Filter.Property("Hotel") Then		
		Parameters.Filter.Insert("Hotel", SessionParameters.CurrentHotel);
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
