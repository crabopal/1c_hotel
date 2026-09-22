
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If NOT ValueIsFilled(Parameters.Hotel) Then
		Parameters.Hotel = SessionParameters.CurrentHotel;	
	EndIf;
	
	If ValueIsFilled(Parameters.Hotel) Then
		vFilterValue = New Array;
		vFilterValue.Add(Catalogs.Hotels.EmptyRef());
		vFilterValue.Add(Parameters.Hotel);
		
		vFilter 				= List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFilter.LeftValue 		= New DataCompositionField("Hotel");
		vFilter.ComparisonType 	= DataCompositionComparisonType.InList;
		vFilter.RightValue		= vFilterValue;
		vFilter.Use 			= True;
		vFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
EndProcedure
