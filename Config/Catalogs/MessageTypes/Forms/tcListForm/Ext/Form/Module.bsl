// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vHotel = SessionParameters.CurrentHotel;
	If Parameters.Property("Hotel") and ValueIsFilled(Parameters.Hotel) Then
		vHotel = Parameters.Hotel;
	EndIf;
	If ValueIsFilled(vHotel) Then
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(vHotel);
		
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Hotel");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
		vNewFilter.RightValue		= vFilterList;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
EndProcedure
