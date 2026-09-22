// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManageHousekeeping") Then
		ThisForm.ReadOnly = True;
	EndIf;
	If Parameters.Property("Filter") Then
		If Not Parameters.Filter.Property("Hotel") Then
			Parameters.Filter.Insert("Hotel", SessionParameters.CurrentHotel);
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
