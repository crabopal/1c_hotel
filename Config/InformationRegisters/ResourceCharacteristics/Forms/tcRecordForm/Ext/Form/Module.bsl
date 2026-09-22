// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
		ThisForm.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer
