
#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ActionMergeRows(pCommand)
	vCurRow = Items.List.CurrentRow;
	If vCurRow = Undefined Then
		ShowMessageBox(, NStr("en = 'Choose at least one row first!'; de = 'Wählen Sie zuerst mindestens eine Zeile aus!'; ru = 'Выберите как минимум одну строку!'"));
		Return;
	EndIf;
	vParam = new Structure();
	vParam.Insert("SelDefaultTypeDescription", New TypeDescription("CatalogRef.PaymentSections"));
	vParam.Insert("SelMergedRef", vCurRow);
	If Items.List.SelectedRows.Count() > 1 Then
		vFirstSelRow = Items.List.SelectedRows.Get(0);
		vParam.Insert("SelMergedRef", vFirstSelRow);
		vLastSelRow = Items.List.SelectedRows.Get(Items.List.SelectedRows.Count() - 1);
		If vLastSelRow <> vFirstSelRow Then
			vParam.Insert("SelMainRef", vLastSelRow);
		EndIf;
	EndIf;
	OpenForm("DataProcessor.MergeAnyRefs.Form", vParam, ThisForm, UUID);
EndProcedure // ActionMergeRows

#EndRegion       
