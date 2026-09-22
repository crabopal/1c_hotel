// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotelsList = New Array;
	vHotelsList.Add(SessionParameters.CurrentHotel);
	vHotelsList.Add(Catalogs.Hotels.EmptyRef());
	
	vNewFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vNewFilter.LeftValue = New DataCompositionField("Hotel");
	vNewFilter.ComparisonType = DataCompositionComparisonType.InList;
	vNewFilter.RightValue = vHotelsList;
	vNewFilter.Use = True;
	vNewFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
EndProcedure // OnCreateAtServer
