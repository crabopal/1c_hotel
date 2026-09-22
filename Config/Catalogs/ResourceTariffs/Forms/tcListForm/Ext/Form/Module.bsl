#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Filter by hotel
	vHotelsList = New Array;
	vHotelsList.Add(SessionParameters.CurrentHotel);
	vHotelsList.Add(Catalogs.Hotels.EmptyRef());
	
	vTreeFilter = Tree.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vTreeFilter.LeftValue = New DataCompositionField("Hotel");
	vTreeFilter.ComparisonType = DataCompositionComparisonType.InList;
	vTreeFilter.RightValue = vHotelsList;
	vTreeFilter.Use = True;
	vTreeFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	vListFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	vListFilter.LeftValue = New DataCompositionField("Hotel");
	vListFilter.ComparisonType = DataCompositionComparisonType.InList;
	vListFilter.RightValue = vHotelsList;
	vListFilter.Use = True;
	vListFilter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
		
		vDMFilter = List.SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		vDMFilter.LeftValue = New DataCompositionField("DeletionMark");
		vDMFilter.ComparisonType = DataCompositionComparisonType.Equal;
		vDMFilter.RightValue = False;
		vDMFilter.Use = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormListItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ListBeforeDeleteRow(pItem, pCancel)
	If Not HasPermissionToManagePrices() Then
		pCancel = True;
		ShowMessageBox(, NStr("en='You do not have rights for services and prices management!';
		                      |ru='Нет прав на управление услугами и ценами!';
							  |de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"));
	EndIf;
EndProcedure // ListBeforeDeleteRow

// --------------------------------------------------------------------------------
&AtClient
Procedure ListDragEnd(pItem, pDragParameters, pStandardProcessing)
	If Not HasPermissionToManagePrices() Then
		pStandardProcessing = False;
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for services and prices management!';
		                                                |ru='Нет прав на управление услугами и ценами!';
							                            |de='Sie haben keine Rechte, Dienstleistungen und Preise zu verwalten!'"),
		                                           MessageStatus.Attention);
	EndIf;
EndProcedure // ListDragEnd

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServerNoContext
Function HasPermissionToManagePrices()
	Return cmCheckUserPermissions("HavePermissionToManagePrices");
EndFunction

#EndRegion
