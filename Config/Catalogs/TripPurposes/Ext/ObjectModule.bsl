
#Region EventHandlers

// ---------------------------------------------------------------------------------
Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		pCancel = True;
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
Procedure OnWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;
EndProcedure // OnWrite

#EndRegion
