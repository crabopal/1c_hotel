
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not Parameters.Filter.Property("Owner") Then		
		Parameters.Filter.Insert("Owner", SessionParameters.CurrentHotel);
	EndIf;
	// Check rights
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		Items.List.EnableStartDrag = False;
		Items.List.EnableDrag = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion
