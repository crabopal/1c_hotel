
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not ValueIsFilled(Object.Owner) Then
		Object.Owner = SessionParameters.CurrentHotel;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for room inventory management!';ru='Нет прав на управление номерным фондом!';de='Sie haben keine Rechte, den Zimmerfond zu verwalten!'"));
			Return;
		EndIf;		
	EndIf;
	// Check user rights to edit room type
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ThisForm.ReadOnly = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

