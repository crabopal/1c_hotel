
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not ValueIsFilled(Object.Ref) Then
		If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights for resources management!'; de = 'Sie haben keine Rechte, Ressourcen zu verwalten!'; ru = 'Нет прав на управление ресурсами!'"));
		EndIf;
	Else
		If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
			ReadOnly = True;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

#EndRegion
