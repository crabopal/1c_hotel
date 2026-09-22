
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Filter.Property("Owner") And Not ValueIsFilled(Parameters.Filter.Owner) Then
		Parameters.Filter.Owner = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

