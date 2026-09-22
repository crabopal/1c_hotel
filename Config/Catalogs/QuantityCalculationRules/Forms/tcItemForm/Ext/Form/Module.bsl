
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		If NOT ValueIsFilled(Object.Ref) Then
			pCancel = True;
			tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'You do not have rights for services and prices management!'; de = 'Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'; ru = 'Нет прав на управление услугами и ценами!'"));
		Else
			ReadOnly = True;
		EndIf;		
	EndIf;
	// Form items appearance
	RefreshItemsAppearance();
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure QuantityCalculationRuleTypeOnChange(pItem)
	RefreshItemsAppearance();
EndProcedure // QuantityCalculationRuleTypeOnChange

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure RefreshItemsAppearance()
	If Object.QuantityCalculationRuleType = Enums.QuantityCalculationRuleTypes.External Then
		Items.ExternalAlgorithm.Enabled = True;
	Else
		Items.ExternalAlgorithm.Enabled = False;
		If ValueIsFilled(Object.ExternalAlgorithm) Then
			Object.ExternalAlgorithm = Undefined;
		EndIf;
	EndIf;
EndProcedure // RefreshItemsAppearance

#EndRegion
