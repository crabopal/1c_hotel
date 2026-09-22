

#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If ThisObject.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Catalogs.ServiceGroups.UserHasPermissionToManageServiceGroups() Then
		Raise NStr("en='No rights to manage service groups!'; ru='Нет прав на изменение наборов услуг!'; de='Keine Rechte zur Verwaltung von Servicegruppen!'");
	EndIf;
EndProcedure // OnWrite

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
// 
// Returns:
//  ValueList - List services
//
Function pmGetServicesList() Export
	Return cmGetServiceGroupServices(Ref);
EndFunction // pmGetServicesList


#EndRegion
