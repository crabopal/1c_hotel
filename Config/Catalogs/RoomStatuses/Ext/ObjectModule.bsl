
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure BeforeDelete(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
	pCancel = CheckPermissions();
EndProcedure

// --------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel) 
	If DataExchange.Load Then
		Return;
	EndIf;
	pCancel = CheckPermissions();
	If Not pCancel Then
		If IsFolder Then
			IconIndex = 11;
		EndIf;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CheckPermissions()
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then 
		vMsg = NStr("en = 'You do not have rights to edit housekeeping settings!'; 
					|de = 'Sie haben keine Rechte, die Einstellungen des Reinigungsdienstes zu verwalten!'; 
					|ru = 'Нет прав на управление службой горничных!'");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		Return True;
	Else
		Return False;		
	EndIf;
EndFunction

#EndRegion
