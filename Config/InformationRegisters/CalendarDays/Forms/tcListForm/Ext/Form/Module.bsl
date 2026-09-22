
#Region FormTableListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;     
EndProcedure // ListBeforeDeleteRow

#EndRegion
