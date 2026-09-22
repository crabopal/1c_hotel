// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)   
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite