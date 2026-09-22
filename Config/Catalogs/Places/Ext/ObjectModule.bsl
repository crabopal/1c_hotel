
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeDelete(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CheckPermissions()
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to edit housekeeping settings!';
														|ru='Нет прав на управление службой горничных!';
														|de='Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'"));
		Return True;
	Else
		Return False;		
	EndIf;
EndFunction

#EndRegion