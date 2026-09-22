
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for resources management!';ru='Нет прав на управление ресурсами!';de='Sie haben keine Rechte, Ressourcen zu verwalten!'"));
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
			ThisForm.ReadOnly = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
