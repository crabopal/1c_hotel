
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToManageResources") Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights for resources management!'; 
														|de = 'Sie haben keine Rechte, Ressourcen zu verwalten!'; 
														|ru = 'Нет прав на управление ресурсами!'"));
	EndIf;
EndProcedure 

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
