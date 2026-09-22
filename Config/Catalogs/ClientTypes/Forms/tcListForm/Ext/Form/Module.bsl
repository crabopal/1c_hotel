
#Region FormEventHandlers

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
		
		// Check permission to see client types
		vPermissionGroup = cmGetEmployeePermissionGroup(SessionParameters.CurrentUser);
		If ValueIsFilled(vPermissionGroup) Then
			If vPermissionGroup.ClientTypesAllowed.Count() > 0 Then
				vClientTypesList = New ValueList();
				For Each vRow In vPermissionGroup.ClientTypesAllowed Do
					If ValueIsFilled(vRow.ClientType) Then
						vClientTypesList.Add(vRow.ClientType);
					EndIf;
				EndDo;				
				vNewFilter 					= List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				vNewFilter.LeftValue		= New DataCompositionField("Ref");
				vNewFilter.ComparisonType	= DataCompositionComparisonType.InList;
				vNewFilter.RightValue		= vClientTypesList;
				vNewFilter.Use				= True;
				vNewFilter.ViewMode 		= DataCompositionSettingsItemViewMode.Inaccessible;
			EndIf;
		EndIf;
	EndIf;	
EndProcedure

#EndRegion

