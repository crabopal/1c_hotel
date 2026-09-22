
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vFilterList	= New ValueList;
	vFilterList.Add(Catalogs.Hotels.EmptyRef());
	vFilterList.Add(SessionParameters.CurrentHotel);
	
	vNewFilter = Tree.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Hotel");
	vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
	vNewFilter.RightValue = vFilterList;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	vNewFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Hotel");
	vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
	vNewFilter.RightValue = vFilterList;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure // OnCreateAtServer

#EndRegion

