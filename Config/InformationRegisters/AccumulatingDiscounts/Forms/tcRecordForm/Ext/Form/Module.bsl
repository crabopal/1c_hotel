// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;
	If ValueIsFilled(Record.DiscountType) Then
		If Not Record.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed Then
			Items.ServiceGroup.Enabled = False;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer
