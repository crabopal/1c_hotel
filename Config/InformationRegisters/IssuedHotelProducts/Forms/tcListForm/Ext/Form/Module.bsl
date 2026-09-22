// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToIssueHotelProducts") Then
		Items.List.ChangeRowSet = False;
	EndIf;    	
EndProcedure // OnCreateAtServer
