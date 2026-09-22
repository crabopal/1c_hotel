
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		If ValueIsFilled(Object.Ref) Then
			ThisForm.ReadOnly = True;
		Else
			pCancel = False;
		EndIf;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
	EndIf;		
EndProcedure // OnCreateAtServer

#EndRegion

