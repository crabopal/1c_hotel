// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;
EndProcedure // ListBeforeAddRow

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;
EndProcedure // ListBeforeDeleteRow
