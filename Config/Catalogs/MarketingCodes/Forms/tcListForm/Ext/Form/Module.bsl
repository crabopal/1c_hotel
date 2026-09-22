
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
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MergeAnyRefs.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure //  NotificationProcessing
#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionMergeMarketingCodes(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(,NStr("en = 'Choose at least one marketing code first!'; de = 'Wählen Sie zuerst mindestens einen Marketingrichtunge!'; ru = 'Выберите как минимум одно направление маркетинга!'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox(,NStr("en = 'Do not choose marketing code folders!'; de = 'Wählen Sie keine Marketingrichtungeordner!'; ru = 'Нельзя выбирать группы направления маркетинга!'"));
		Return;
	EndIf;
	vParam = new Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.MarketingCodes"));
	vParam.Insert("SelMergedRef", vCurRow);
	If Items.List.SelectedRows.Count() > 1 Then
		vFirstSelRow = Items.List.SelectedRows.Get(0);
		If Not tcOnServer.cmGetAttributeByRef(vFirstSelRow, "IsFolder") Then
			vParam.Insert("SelMergedRef", vFirstSelRow);
		EndIf;
		vLastSelRow = Items.List.SelectedRows.Get(Items.List.SelectedRows.Count() - 1);
		If Not tcOnServer.cmGetAttributeByRef(vLastSelRow, "IsFolder") And vLastSelRow <> vFirstSelRow Then
			vParam.Insert("SelMainRef", vLastSelRow);
		EndIf;
	EndIf;
	OpenForm("DataProcessor.MergeAnyRefs.Form", vParam, ThisForm, UUID);
EndProcedure //  ActionMergeMarketingCodes

#EndRegion
