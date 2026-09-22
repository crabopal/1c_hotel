
#Region EventHandlers

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = Not Catalogs.PermissionGroups.UpdateInfobaseUsersRoles(Ref);
	If Ref.DeletionMark Then
		pCancel = Not CheckUsersBeforeDelete(Ref);
	EndIf;   
EndProcedure // OnWrite

// --------------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = Not CheckUsersBeforeDelete(Ref);
EndProcedure // BeforeDelete

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function CheckUsersBeforeDelete(pRef)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Employees.Ref AS Ref,
		|	Employees.Description AS Description
		|FROM
		|	Catalog.Employees AS Employees
		|WHERE
		|	NOT Employees.DeletionMark
		|	AND Employees.PermissionGroup = &qPermissionGroup";
	vQuery.SetParameter("qPermissionGroup", pRef);
	vSel = vQuery.Execute().Select();
	If vSel.Count() > 0 Then   
		vMsg = Nstr("en = 'You can not delete permission group while it is listed for the following users: '; 
					|de = 'Sie können eine Reihe von Rechten nicht löschen. Es ist auf den folgenden Benutzern aufgeführt: '; 
					|ru = 'Невозможно удалить набор прав т.к. он указан у следующих пользователей: '");
		tcCommonFunctionOnClientServer.TextMessage(vMsg);
		While vSel.Next() Do
			tcCommonFunctionOnClientServer.TextMessage(vSel.Description);	
		EndDo;
		Return False;
	EndIf;
	Return True;
EndFunction // CheckUsersBeforeDelete

#EndRegion
