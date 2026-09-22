
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Set customer filter if necessary
	If ThisForm.Parameters.Filter.Count() >0 And ValueIsFilled(ThisForm.Parameters.Filter.Owner) Then
		vOwnerFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vOwnerFilter.LeftValue = New DataCompositionField("Owner");
		vOwnerFilter.ComparisonType = DataCompositionComparisonType.Equal;
		vOwnerFilter.RightValue = ThisForm.Parameters.Filter.Owner;
		vOwnerFilter.Use = True;
		Items.Owner.Visible = False;
	EndIf;
	// Filter by current hotel
	If ValueIsFilled(SessionParameters.CurrentHotel) Then
		vFilter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vFilter.LeftValue = New DataCompositionField("Hotel");
		vFilter.ComparisonType = DataCompositionComparisonType.InList;
		vList = New ValueList;
		vList.Add(Catalogs.Hotels.EmptyRef());
		vList.Add(SessionParameters.CurrentHotel);
		vFilter.RightValue = vList;
		vFilter.Use = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

