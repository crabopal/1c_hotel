 
#Region EventHandlers

// --------------------------------------------------------------------------------
//
// Parameters:
//  pCancel		 - Boolean	 - Cancel
//  pReplacing	 - Boolean	 - Replacing
//
Procedure OnWrite(pCancel, pReplacing)    
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion
