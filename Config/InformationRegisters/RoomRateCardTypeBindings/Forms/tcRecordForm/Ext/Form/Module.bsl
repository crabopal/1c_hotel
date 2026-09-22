
// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;   
EndProcedure // OnCreateAtServer
