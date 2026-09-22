
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Initialize hotel
	tcOnServer.cmInitHotel(Object);
EndProcedure     

#EndRegion

