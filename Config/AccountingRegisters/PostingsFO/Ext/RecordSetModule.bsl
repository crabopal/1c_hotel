
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pWriteMode) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel, pWriteMode)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // BeforeWrite

#EndRegion  
