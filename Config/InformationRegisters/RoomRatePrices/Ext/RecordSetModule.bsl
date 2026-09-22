// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel, pReplacing)   
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;   
EndProcedure // OnWrite