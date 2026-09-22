// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights
	If Not cmCheckUserPermissions("HavePermissionToManagePrices") Then
		Items.List.ChangeRowSet = False;
	EndIf;
	
	// Filter by hotel
	vFilterList	= New ValueList;
	vFilterList.Add(Catalogs.Hotels.EmptyRef());
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vFilterList.Add(SessionParameters.CurrentHotel);
	EndIf;
	vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue		= New DataCompositionField("Hotel");
	vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
	vNewFilter.RightValue		= vFilterList;
	vNewFilter.Use				= True;
	vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure // OnCreateAtServer
