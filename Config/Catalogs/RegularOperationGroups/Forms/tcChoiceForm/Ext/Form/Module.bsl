
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		Items.List.ChangeRowSet = False;
	EndIf;
EndProcedure


#EndRegion

