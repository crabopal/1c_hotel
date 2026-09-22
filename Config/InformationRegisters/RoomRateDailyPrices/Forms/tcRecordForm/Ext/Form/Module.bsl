// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	pCurrentObject.Timestamp = CurrentSessionDate();
EndProcedure // BeforeWriteAtServer
