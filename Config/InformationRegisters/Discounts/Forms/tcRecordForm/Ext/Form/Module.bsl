// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;
	If ValueIsFilled(Record.DiscountType) Then
		If Not Record.DiscountType.DifferentDiscountPercentsForServiceGroupsAllowed And Not Record.DiscountType.DifferentBonusCalculationFactorsForServiceGroupsAllowed Then
			Items.ServiceGroup.Enabled = False;
		EndIf;
	EndIf;
	If Record.DiscountType.LoyaltyType <> Enums.LoyaltyType.Bonuses Then
		Items.BonusCalculationFactor.Enabled = False;	
	EndIf;
EndProcedure // OnCreateAtServer
