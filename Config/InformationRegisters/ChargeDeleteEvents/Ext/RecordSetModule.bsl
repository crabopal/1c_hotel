#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion