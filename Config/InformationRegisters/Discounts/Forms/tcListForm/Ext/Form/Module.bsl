// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentHotel) Then	
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(SessionParameters.CurrentHotel);
		
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Hotel");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
		vNewFilter.RightValue		= vFilterList;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	Items.BonusCalculationFactor.Visible = True;
	If Parameters.Filter.Property("DiscountType") Then
		vDiscountType = Parameters.Filter.DiscountType;
		If ValueIsFilled(vDiscountType) Then
			If vDiscountType.LoyaltyType <> Enums.LoyaltyType.Bonuses Then
				Items.BonusCalculationFactor.Visible = False	
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeAddRow(pItem, pCancel, pClone, pParent, pFolder, pParameter)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;
EndProcedure // ListBeforeAddRow

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManagePrices") Then
		pCancel = True;
	EndIf;
EndProcedure // ListBeforeDeleteRow

