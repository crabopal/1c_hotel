// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Hotel") and ValueIsFilled(Parameters.Hotel) Then
		vFilterList	= New ValueList;
		vFilterList.Add(Catalogs.Hotels.EmptyRef());
		vFilterList.Add(Parameters.Hotel);
		
		vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vNewFilter.LeftValue		= New DataCompositionField("Hotel");
		vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
		vNewFilter.RightValue		= vFilterList;
		vNewFilter.Use				= True;
		vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;	
	ElsIf ValueIsFilled(SessionParameters.CurrentHotel) Then	
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
	If Parameters.Property("ChoiceMode") and Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
		Items.Tree.ChoiceMode = True;
	EndIf;
EndProcedure // OnCreateAtServer
