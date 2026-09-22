// --------------------------------------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	pCancel = True;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	pCancel = True;
EndProcedure // BeforeWriteAtServer
