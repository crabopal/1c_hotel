// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to edit form
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		ThisForm.ReadOnly = True;
	EndIf;
	// Check user rights to edit period
	If Not cmCheckUserPermissions("HavePermissionToSetFixedPeriodForTheHotelProduct") Then
		Items.FixProductPeriod.Enabled = False;
	EndIf;
	// Check user rights to edit sum
	If Not cmCheckUserPermissions("HavePermissionToSetFixedCostForTheHotelProduct") Then
		Items.FixProductCost.Enabled = False;
	EndIf;
	// Reference hour
	If ValueIsFilled(Object.DurationCalculationRuleType) Then
		If Object.DurationCalculationRuleType = PredefinedValue("Enum.DurationCalculationRuleTypes.ByDays") Or
		   Object.DurationCalculationRuleType = PredefinedValue("Enum.DurationCalculationRuleTypes.ByNights") Then
			Items.ReferenceHour.Enabled = False;
		Else
			Items.ReferenceHour.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure DurationCalculationRuleTypeOnChange(pItem)
	If ValueIsFilled(Object.DurationCalculationRuleType) Then
		If Object.DurationCalculationRuleType = PredefinedValue("Enum.DurationCalculationRuleTypes.ByDays") Or
		   Object.DurationCalculationRuleType = PredefinedValue("Enum.DurationCalculationRuleTypes.ByNights") Then
			Items.ReferenceHour.Enabled = False;
		Else
			Items.ReferenceHour.Enabled = True;
		EndIf;
	EndIf;
EndProcedure // DurationCalculationRuleTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixPlannedPeriodOnChange(pItem)
	If Object.FixPlannedPeriod Then
		If Object.FixProductPeriod Then
			Object.FixProductPeriod = False;
		EndIf;
	EndIf;
EndProcedure // FixPlannedPeriodOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure FixProductPeriodOnChange(pItem)
	If Object.FixProductPeriod Then
		If Object.FixPlannedPeriod Then
			Object.FixPlannedPeriod = False;
		EndIf;
	EndIf;
EndProcedure // FixProductPeriodOnChange
