
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Ref) Then
		Object.Hotel = SessionParameters.CurrentHotel;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
