
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;
	SetFormAppearance();
	ChangeModeList.Clear();
	ChangeModeList.Add(0, NStr("en = 'All'; de = 'Alle'; ru = 'Все'"));
	ChangeModeList.Add(1, NStr("en = 'Bonuses'; de = 'Boni'; ru = 'Бонусы'"));
	ChangeModeList.Add(2, NStr("en = 'Gift cards'; de = 'Geschenkkarten'; ru = 'Подарочные карты'"));
	ChangeModeList.Add(3, NStr("en = 'Discounts'; de = 'Ermäßigungen'; ru = 'Скидки'"));
	vItem = ChangeModeList.FindByValue(Mode);
	If vItem <> Undefined Then
		Items.ChangeMode.Title = vItem.Presentation;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Procedure SetFormAppearance()
	If Mode = 0 Then
		// All
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter,"LoyaltyType",,,,False);
	ElsIf Mode = 1 Then
		// Bonuses
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter,"LoyaltyType",,Enums.LoyaltyType.Bonuses,,True);
	ElsIf Mode = 2 Then
		// Gift cards
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter,"LoyaltyType",,Enums.LoyaltyType.Certificate,,True);
	ElsIf Mode = 3 Then
		// Discounts
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter,"LoyaltyType",,Enums.LoyaltyType.Discount,,True);
	Else
		tcCommonFunctionOnClientServer.cmChangeFilterItems(List.SettingsComposer.Settings.Filter,"LoyaltyType",,Enums.LoyaltyType.Bonuses,,True);
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not pClone Then
		pCancel = True;
		vLoyaltyType = Undefined;
		If Mode > 0 Then
			If Mode = 1 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Bonuses");
			ElsIf Mode = 2 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate");
			ElsIf Mode = 3 Then
				vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Discount");
			EndIf;
		Else
			vLoyaltyType = PredefinedValue("Enum.LoyaltyType.Certificate");
		EndIf;
		OpenForm("Catalog.DiscountCards.ObjectForm", New Structure("FillingValues", New Structure("Parent, LoyaltyType", pParent, vLoyaltyType)));
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeMode(pCommand)
	vNotifyDescription = New NotifyDescription("ChangeModeAfterChoice", ThisForm);
	vParams = New Structure("ValueList, MultipleChoice, Title", ChangeModeList, False);
	OpenForm("CommonForm.mcChoiceValueList", vParams, ThisForm, UUID,,,vNotifyDescription);
EndProcedure // ChangeMode

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeModeAfterChoice(pItem, pExtraParameters) Export
	If pItem <> Undefined Then
		Mode = pItem.Value;
		Items.ChangeMode.Title = pItem.Presentation;
		SetFormAppearance();
	EndIf;
EndProcedure // FilterStatusListAfterChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure ShowFiletGroup(pCommand)
	Items.ListSettingsComposerUserSettings.Visible = Not Items.ListSettingsComposerUserSettings.Visible; 
	Items.FormShowFiletGroup.Check = Items.ListSettingsComposerUserSettings.Visible;
EndProcedure // ShowFiletGroup

#EndRegion