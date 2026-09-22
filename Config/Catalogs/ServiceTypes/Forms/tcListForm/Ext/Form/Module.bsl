
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "MergeAnyRefs.Change" Then
		Items.List.Refresh();
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionMergeServiceTypes(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(,NStr("en = 'Choose at least one service type first!'; de = 'Wählen Sie zuerst mindestens einen Service!'; ru = 'Выберите как минимум один тип услуг'"));
		Return;
	EndIf;
	If tcOnServer.cmGetAttributeByRef(vCurRow, "IsFolder") Then
		ShowMessageBox(,NStr("en = 'Do not choose service type folders!'; de = 'Wählen Sie keine Servicetypordner!'; ru = 'Нельзя выбирать группы услуг!'"));
		Return;
	EndIf;
	vParam = new Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.ServiceTypes"));
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
EndProcedure // ActionMergeServiceTypes

#EndRegion

