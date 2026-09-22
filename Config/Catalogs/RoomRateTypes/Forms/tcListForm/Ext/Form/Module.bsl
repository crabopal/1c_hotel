// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
		Items.Tree.ChangeRowSet = False;
	EndIf;
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		If Not SessionParameters.CurrentHotel.Vauchers Then
			Items.VoucherType.Visible = False;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
