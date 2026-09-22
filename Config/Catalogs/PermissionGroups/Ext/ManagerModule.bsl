
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPermissionsRef	 - CatalogRef.PermissionGroups - Ref
// 
// Returns:
//  Boolean - True or false result
//
Function UpdateInfobaseUsersRoles(pPermissionsRef) Export
	If pPermissionsRef.InfobaseUserRoles.Count() > 0 Then
		BeginTransaction();   
		Try
			vQuery = New Query;
			vQuery.Text = 
			"SELECT
			|	Employees.Ref AS Ref,
			|	Employees.Code AS Code
			|FROM
			|	Catalog.Employees AS Employees
			|WHERE
			|	NOT Employees.DeletionMark
			|	AND Employees.PermissionGroup = &qPermissionGroup
			|	AND Employees.AllowAccessToSystem";
			vQuery.SetParameter("qPermissionGroup", pPermissionsRef);
			vQueryResult = vQuery.Execute().Select();
			While vQueryResult.Next() Do
				// Current employee with this permission group
				vEmployeeRef = vQueryResult.Ref;
				// Get user UUIDs for this employee
				vUserUUIDs = cmGetUserUUIDsByEmployee(vEmployeeRef);
				For Each vUserUUIDsRow In vUserUUIDs Do
					If Not IsBlankString(vUserUUIDsRow.UserUUID) Then
						Try
							vUUID = New UUID(TrimAll(vUserUUIDsRow.UserUUID));
						Except
							vUUID = Undefined;
						EndTry;
						If ValueIsFilled(vUUID) Then
							vInfoBaseUser = InfoBaseUsers.FindByUUID(vUUID);
							If vInfoBaseUser <> Undefined Then
								If vInfoBaseUser.UUID = InfoBaseUsers.CurrentUser().UUID Then
									vIsAdministrator = False;
									For Each vRole In vInfoBaseUser.Roles Do
										If vRole = Metadata.Roles.Administrator Then
											vIsAdministrator = True;
										EndIf;
									EndDo;
									
									If vIsAdministrator Then  
										vStillAdministrator = False;
										For Each vRole In pPermissionsRef.InfobaseUserRoles Do
											vRole = Metadata.Roles.Find(vRole.Role);
											If vRole = Metadata.Roles.Administrator Then
												vStillAdministrator = True;
												Break;
											EndIf;	
										EndDo;
										
										If Not vStillAdministrator Then
											tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'It is impossible to remove system administration permission from yourself!'; 
																							|de = 'Es ist unmöglich, die systemadministrationsberechtigung von sich selbst zu entfernen!'; 
																							|ru = 'Нельзя удалить права системного администратора у самого себя!'"));
											RollbackTransaction();
											Return False;
										EndIf;
									EndIf;
								EndIf;
								vInfoBaseUser.Roles.Clear();
								For Each vRole In pPermissionsRef.InfobaseUserRoles Do
									vRole = Metadata.Roles.Find(vRole.Role);
									If vRole <> Undefined Then
										vInfoBaseUser.Roles.Add(vRole);
									EndIf;	
								EndDo;
								vInfoBaseUser.Write();
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndDo;
			CommitTransaction();  
		Except
			RollbackTransaction();
			Return False;
		EndTry;
	EndIf;
	Return True;
EndFunction // UpdateInfobaseUsersRoles

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - CatalogRef	 - Ref
//  pReceiverNode	 - ExchangePlanRef	 - The Receiver node
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	ExchangePlansProcessing.ExchangePlansRecordChanges(pData, pData.Hotel, pReceiverNode);
EndProcedure // ExchangePlansRecordChanges

#EndRegion
