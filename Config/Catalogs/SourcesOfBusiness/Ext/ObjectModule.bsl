
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		pCancel = True;     
		vErr = NStr("en = 'You do not have rights for services and prices management!'; 
					 |de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'; 
					 |ru = 'Нет прав на управление услугами и ценами!'");
		tcCommonFunctionOnClientServer.TextMessage(vErr);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf; 
EndProcedure // OnWrite

#EndRegion
