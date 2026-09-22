// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		Items.List.ChangeRowSet = False;
	EndIf;
EndProcedure // OnCreateAtServer