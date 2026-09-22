// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not IsInRole("Administrator") Then
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer
