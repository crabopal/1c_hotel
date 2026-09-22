
#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure BeforeDelete(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

// -----------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	pCancel = CheckPermissions();
EndProcedure

#EndRegion

#Region Public

// -----------------------------------------------------------------------------
//  Get operation standards for the specified hotel, room and room type
//  -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRoomType	 - CatalogRef.Roo,Types	 - Ref
//  pRoom		 - CatalogRef.Rooms	 - Ref
// 
// Returns:
//  ValyeTable - List operations
//
Function pmGetOperationStandards(pHotel, pRoomType, pRoom, pEmployee = Undefined) Export
	Return Catalogs.Operations.GetOperationStandards(Ref, pHotel, pRoomType, pRoom, pEmployee);
EndFunction // pmGetOperationStandards

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
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
