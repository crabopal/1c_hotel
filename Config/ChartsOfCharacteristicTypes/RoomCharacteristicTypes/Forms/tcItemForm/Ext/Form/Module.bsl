
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for rooms management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, Zimmeren zu verwalten!'"));
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
