// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure CheckUserPermissions(pCancel)
	If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
		pCancel = True;
	EndIf;
EndProcedure // CheckUserPermissions

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	CheckUserPermissions(pCancel);
EndProcedure // ListBeforeAddRowAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	CheckUserPermissions(pCancel);
EndProcedure // ListBeforeDeleteRow
