
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)    
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder And Not IsNew() Then
		// Get user UUIDs for this employee
		vUserUUIDs = cmGetUserUUIDsByEmployee(Ref);
		For Each vUserUUIDsRow In vUserUUIDs Do
			pCancel = Not Catalogs.Employees.DeleteInfoBaseUser(TrimAll(vUserUUIDsRow.UserUUID));
		EndDo;
	EndIf;
EndProcedure // BeforeDelete

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Disable all employee logins if it is marked for deletion
	If DeletionMark And Not IsFolder And Not IsNew() Then
		AllowAccessToSystem = False;
		// Get user UUIDs for this employee
		vUserUUIDs = cmGetUserUUIDsByEmployee(Ref);
		For Each vUserUUIDsRow In vUserUUIDs Do
			pCancel = Not Catalogs.Employees.DisableInfoBaseUser(TrimAll(vUserUUIDsRow.UserUUID));
		EndDo;
	EndIf;
EndProcedure // BeforeWrite

// -----------------------------------------------------------------------------
Procedure OnCopy(CopiedObject)
	If IsFolder Then
		Prefix = "";
	EndIf;
EndProcedure // OnCopy

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// See Catalogs.Employees.------------------------------------------------------
//
// Parameters:
//  pLang	 - CatalogRef.Languages	 - Ref
// 
// Returns:
//  String - Employee description
//
Function pmGetEmployeeDescription(pLang) Export
	Return Catalogs.Employees.pmGetEmployeeDescription(Ref, pLang);
EndFunction // pmGetEmployeeDescription

// See Catalogs.Employees.------------------------------------------------------
//  Get employee operation pbx codes
//
// Parameters:
//  pOperation	 - CatalogRef.Operations - Ref
// 
// Returns:
//  ValueTable - Operation PBX codes
//
Function pmGetOperationPBXCodes(pOperation) Export
	Return Catalogs.Employees.pmGetOperationPBXCodes(Ref, pOperation);
EndFunction // pmGetOperationPBXCodes

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueTable - NonReplicatingAttributes
//
Function pmGetNonReplicatingAttributes() Export
	Return CachedSettings.сmGetEmployeeNonReplicatingAttributes(Ref);
EndFunction // pmGetNonReplicatingAttributes

// See Catalogs.Employees.------------------------------------------------------
// 
// Returns:
//  CatalogRef.Clients - Ref
//
Function pmGetClient() Export
	Return Catalogs.Employees.pmGetClient(Ref);
EndFunction

#EndRegion
