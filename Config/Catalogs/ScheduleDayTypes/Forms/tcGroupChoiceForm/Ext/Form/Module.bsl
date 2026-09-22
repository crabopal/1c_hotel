
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		Items.List.ChangeRowSet = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

