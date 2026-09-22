// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes
	FillPropertyValues(ThisForm, Parameters);
	
	// Check if some settings have to be hidden
	If Parameters.Property("HideRowTotals") Then
		If Parameters.HideRowTotals Then
			Items.ReportRowDimensions.Visible = False;
		EndIf;
	EndIf;
	If Parameters.Property("HideColumnTotals") Then
		If Parameters.HideColumnTotals Then
			Items.ReportColumnDimensions.Visible = False;
		EndIf;
	EndIf;
	If Parameters.Property("HideFilters") Then
		If Parameters.HideFilters Then
			Items.ReportFilterSettings.Visible = False;
		EndIf;
	EndIf;
	
	// Check if report attribute is defined
	If Not ValueIsFilled(Report) Then
		pCancel = True;
		Return;
	EndIf;
	
	// Report name
	ReportName = TrimAll(Report.Code) + " - " + cmNStr(Report.Description);
	
	// Check permissions
	If Not cmCheckUserPermissions("HavePermissionToManageReportColumns") Then
		Items.ReportFields.ReadOnly = True;
		Items.FormSaveCurrentSettingsForAllUsers.Enabled = False;
	Else
		Items.ReportFields.ReadOnly = False;
		Items.FormSaveCurrentSettingsForAllUsers.Enabled = True;
	EndIf;
	If Report.LockSettings Then
		Items.FormSaveCurrentSettingsForAllUsers.Enabled = False;
		Items.FormSaveAsDefaultSettings.Enabled = False;
	EndIf;	
	// Set form appearance
	Items.GroupChartSettings.Visible = Parameters.ChartIsSupported;
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.FormOpenFormCatalogItem.Visible = False;
		//Items.FormSaveNewAttributesSetting.Enabled = False;
	EndIf;	
	// Load settings from parameters
	LoadReportSettingFromParameters();	
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadReportSettingFromParameters()
	// Report column overrides
	vReportColumnOverrides = GetFromTempStorage(ReportColumnOverridesAddress);
	If vReportColumnOverrides = Undefined Or TypeOf(vReportColumnOverrides) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	ReportColumnOverrides.Clear();
	For Each vReportColumnOverridesRow In vReportColumnOverrides Do
		vOverridesRow = ReportColumnOverrides.Add();
		FillPropertyValues(vOverridesRow, vReportColumnOverridesRow);
	EndDo;
	
	// Restore selected fields value table
	vSelectedFields = GetFromTempStorage(SelectedFieldsAddress);
	If vSelectedFields = Undefined Or TypeOf(vSelectedFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	SelectedFields.Clear();
	For Each vSelectedFieldsRow In vSelectedFields Do
		vFieldRow = SelectedFields.Add();
		FillPropertyValues(vFieldRow, vSelectedFieldsRow);
		// Column overrides
		vOverrideRow = Undefined;
		If vReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = vReportColumnOverrides.Find(vFieldRow.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			If vReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
				vOverrideRow = vReportColumnOverrides.Find(vFieldRow.Name, "ColumnName");
			EndIf;
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If vOverrideRow.ColumnWidth > 0 Then
					vFieldRow.ColumnWidth = vOverrideRow.ColumnWidth;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnHeaderDescription) Then
					vFieldRow.ColumnHeaderDescription = vOverrideRow.ColumnHeaderDescription;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnFormat) Then
					vFieldRow.ColumnFormat = vOverrideRow.ColumnFormat;
				EndIf;
				If ValueIsFilled(vOverrideRow.ColumnTextPlacement) Then
					vFieldRow.ColumnTextPlacement = vOverrideRow.ColumnTextPlacement;
				EndIf;
				If vOverrideRow.ShowInChart Then
					vFieldRow.ShowInChart = vOverrideRow.ShowInChart;
				Else
					vFieldRow.ShowInChart = False;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndDo;
	
	// Restore filter fields value table
	vFilterFields = GetFromTempStorage(FilterAddress);
	If vFilterFields = Undefined Or TypeOf(vFilterFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	Filter.Clear();
	For Each vFilterFieldsRow In vFilterFields Do
		vFilterRow = Filter.Add();
		FillPropertyValues(vFilterRow, vFilterFieldsRow);
	EndDo;
	
	// Restore row dimensions value table
	vRowDimensionsFields = GetFromTempStorage(RowDimensionsAddress);
	If vRowDimensionsFields = Undefined Or TypeOf(vRowDimensionsFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	RowDimensions.Clear();
	For Each vRowDimensionsFieldsRow In vRowDimensionsFields Do
		vRowDimensionRow = RowDimensions.Add();
		FillPropertyValues(vRowDimensionRow, vRowDimensionsFieldsRow);
		// Column overrides
		vOverrideRow = Undefined;
		If vReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = vReportColumnOverrides.Find(vRowDimensionRow.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			If vReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
				vOverrideRow = vReportColumnOverrides.Find(vRowDimensionRow.Name, "ColumnName");
			EndIf;
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If vOverrideRow.ShowGroupClosed Then
					vRowDimensionRow.GroupBy = vOverrideRow.ShowGroupClosed;
				Else
					vRowDimensionRow.GroupBy = False;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndDo;
	
	// Restore column dimensions value table
	vColumnDimensionsFields = GetFromTempStorage(ColumnDimensionsAddress);
	If vColumnDimensionsFields = Undefined Or TypeOf(vColumnDimensionsFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	ColumnDimensions.Clear();
	For Each vColumnDimensionsFieldsRow In vColumnDimensionsFields Do
		vColumnDimensionRow = ColumnDimensions.Add();
		FillPropertyValues(vColumnDimensionRow, vColumnDimensionsFieldsRow);
		// Column overrides
		vOverrideRow = Undefined;
		If vReportColumnOverrides.Columns.Find("ColumnDataPath") <> Undefined Then
			vOverrideRow = vReportColumnOverrides.Find(vColumnDimensionRow.DataPath, "ColumnDataPath");
		EndIf;
		If vOverrideRow = Undefined Then
			If vReportColumnOverrides.Columns.Find("ColumnName") <> Undefined Then
				vOverrideRow = vReportColumnOverrides.Find(vColumnDimensionRow.Name, "ColumnName");
			EndIf;
		EndIf;
		If vOverrideRow <> Undefined Then
			Try
				If vOverrideRow.ShowGroupClosed Then
					vColumnDimensionRow.GroupBy = vOverrideRow.ShowGroupClosed;
				Else
					vColumnDimensionRow.GroupBy = False;
				EndIf;
			Except
			EndTry;
		EndIf;
	EndDo;
	
	// Restore order value table
	vOrderFields = GetFromTempStorage(OrderAddress);
	If vOrderFields = Undefined Or TypeOf(vOrderFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	Order.Clear();
	For Each vOrderFieldsRow In vOrderFields Do
		vOrderRow = Order.Add();
		FillPropertyValues(vOrderRow, vOrderFieldsRow);
	EndDo;
	
	// Restore conditional appearance
	vCondAppFields = GetFromTempStorage(ConditionalAppearanceAddress);
	If vCondAppFields = Undefined Or TypeOf(vCondAppFields) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	ReportConditionalAppearance.Clear();
	For Each vCondAppFieldsRow In vCondAppFields Do
		vCondAppRow = ReportConditionalAppearance.Add();
		
		FillPropertyValues(vCondAppRow, vCondAppFieldsRow, , "Area, Filter, Appearance");
		
		For Each vAreaRow In vCondAppFieldsRow.Area Do
			vAreaItem = vCondAppRow.Area.Add();
			FillPropertyValues(vAreaItem, vAreaRow);
		EndDo;
		vCondAppRow.AreaAddress = PutToTempStorage(vCondAppFieldsRow.Area, ThisForm.UUID);
		
		For Each vFilterRow In vCondAppFieldsRow.Filter Do
			vFilterItem = vCondAppRow.Filter.Add();
			FillPropertyValues(vFilterItem, vFilterRow);
		EndDo;
		vCondAppRow.FilterAddress = PutToTempStorage(vCondAppFieldsRow.Filter, ThisForm.UUID);
		
		For Each vAppearanceRow In vCondAppFieldsRow.Appearance Do
			vAppearanceItem = vCondAppRow.Appearance.Add();
			FillPropertyValues(vAppearanceItem, vAppearanceRow);
		EndDo;
		vCondAppRow.AppearanceAddress = PutToTempStorage(vCondAppFieldsRow.Appearance, ThisForm.UUID);
	EndDo;
EndProcedure // LoadReportSettingsFromParameters

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsFilter, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // FilterPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "Filter" Then
			pSelectedValue.Name = "";
			vCurData = Items.Filter.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
				If TypeOf(vCurData.ValueType) = Type("TypeDescription") Then
					vCurData.Value = vCurData.ValueType.AdjustValue();
					vCurData.ValueFrom = vCurData.Value;
					vCurData.ValueTo = vCurData.Value;
					If vCurData.ValueType.Types().Count() = 1 Then
						Items.FilterValue.ChooseType = False;	
						Items.FilterValueFrom.ChooseType = False;	
						Items.FilterValueTo.ChooseType = False;
					Else
						Items.FilterValue.ChooseType = True;	
						Items.FilterValueFrom.ChooseType = True;	
						Items.FilterValueTo.ChooseType = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FilterPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterComparisonTypeOnChange(pItem)
	vFilterData = Items.Filter.CurrentData;
	If vFilterData <> Undefined Then
		If vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InList") Or 
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInList") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InListByHierarchy") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInListByHierarchy") Then
			vTypesArray = New Array;
			vTypesArray.Add(Type("ValueList"));
			vListTypeDef = New TypeDescription(vTypesArray);
			vFilterData.Value = vListTypeDef.AdjustValue();
			vFilterData.Value.ValueType = vFilterData.ValueType;
			vFilterData.ValueFrom = vFilterData.Value;
			vFilterData.ValueTo = vFilterData.Value;
			Items.FilterValuesRange.Visible = False;
			Items.FilterValue.Visible = True;
		ElsIf vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			vFilterData.Value = vFilterData.ValueType.AdjustValue();
			vFilterData.ValueFrom = vFilterData.Value;
			vFilterData.ValueTo = vFilterData.Value;
			Items.FilterValuesRange.Visible = True;
			Items.FilterValue.Visible = False;
		Else
			vFilterData.Value = vFilterData.ValueType.AdjustValue();
			vFilterData.ValueFrom = vFilterData.Value;
			vFilterData.ValueTo = vFilterData.Value;
			Items.FilterValuesRange.Visible = False;
			Items.FilterValue.Visible = True; 
		EndIf;
		If vFilterData.ValueType.Types().Count() = 1 Then
			Items.FilterValue.ChooseType = False;	
			Items.FilterValueFrom.ChooseType = False;	
			Items.FilterValueTo.ChooseType = False;
		Else
			Items.FilterValue.ChooseType = True;	
			Items.FilterValueFrom.ChooseType = True;	
			Items.FilterValueTo.ChooseType = True;
		EndIf; 
		If  vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InListByHierarchy") Or
		    vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInListByHierarchy") Or
			vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InHierarchy") Or
			vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInHierarchy") Then  
			Items.FilterValue.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		Else        
			Items.FilterValue.ChoiceFoldersAndItems = FoldersAndItems.Items;
		EndIf;	
	EndIf;
EndProcedure // FilterComparisonTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterValueOnChange(pItem)
	vFilterData = Items.Filter.CurrentData;
	If vFilterData <> Undefined And ValueIsFilled(vFilterData.ComparisonType) Then
		vFilterData.Use = True;
		If vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			If ValueIsFilled(vFilterData.Value) Then
				vFilterData.Value = vFilterData.ValueType.AdjustValue();
			EndIf;
		Else
			If ValueIsFilled(vFilterData.ValueFrom) Then
				vFilterData.ValueFrom = vFilterData.ValueType.AdjustValue();
				vFilterData.ValueTo = vFilterData.ValueFrom;
			ElsIf ValueIsFilled(vFilterData.ValueTo) Then
				vFilterData.ValueFrom = vFilterData.ValueType.AdjustValue();
				vFilterData.ValueTo = vFilterData.ValueFrom;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FilterValueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterOnActivateRow(pItem)
	vCurData = Items.Filter.CurrentData;
	If vCurData <> Undefined Then
		If vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			Items.FilterValuesRange.Visible = True;
			Items.FilterValue.Visible = False;
		Else
			Items.FilterValuesRange.Visible = False;
			Items.FilterValue.Visible = True;
		EndIf;
		If vCurData.ValueType.Types().Count() = 1 Then
			Items.FilterValue.ChooseType = False;	
			Items.FilterValueFrom.ChooseType = False;	
			Items.FilterValueTo.ChooseType = False;
		Else
			Items.FilterValue.ChooseType = True;	
			Items.FilterValueFrom.ChooseType = True;	
			Items.FilterValueTo.ChooseType = True;
		EndIf;
	EndIf;
EndProcedure // FilterOnActivateRow

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.Filter.CurrentData;
		If vCurData <> Undefined Then
			vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Equal");
			Items.FilterValuesRange.Visible = False;
			Items.FilterValue.Visible = True;
		EndIf;
	EndIf;
EndProcedure // FilterOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure RowDimensionsPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsRowDimension, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // RowDimensionsPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure RowDimensionsPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "RowDimension" Then
			vCurData = Items.RowDimensions.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // RowDimensionsPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure ColumnDimensionsPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsColumnDimension, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // ColumnDimensionsPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ColumnDimensionsPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "ColumnDimension" Then
			vCurData = Items.ColumnDimensions.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // ColumnDimensionsPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectedFieldsColumnFormatStartChoice(pItem, pChoiceData, pStandardProcessing)
	#If Not MobileClient Then
		vFormatWizard = New FormatStringWizard(pItem.EditText);
		vFormatWizard.Show(New NotifyDescription("FormatWizardAfterClose", ThisForm));
	#EndIf
EndProcedure // SelectedFieldsColumnFormatStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure FormatWizardAfterClose(pFormatText, pExtraParams) Export
	If pFormatText <> Undefined Then
		vFieldData = Items.SelectedFields.CurrentData;
		If vFieldData <> Undefined Then
			vFieldData.ColumnFormat = pFormatText;
		EndIf;
	EndIf;
EndProcedure // FormatWizardAfterClose

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectedFieldsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vFieldData = Items.SelectedFields.CurrentData;
	If vFieldData <> Undefined Then
		vOverrideRow = Undefined;
		vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnDataPath", vFieldData.DataPath));
		If vOverrideRows.Count() = 0 Then
			vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnName", vFieldData.Name));
		EndIf;
		If vOverrideRows.Count() = 0 Then
			vOverrideRow = ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vFieldData.Name;
			vOverrideRow.ColumnDataPath = vFieldData.DataPath;
		Else
			vOverrideRow = vOverrideRows.Get(0);
		EndIf;
		If vOverrideRow <> Undefined Then
			FillPropertyValues(vOverrideRow, vFieldData);
		EndIf;
	EndIf;
EndProcedure // SelectedFieldsOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure RowDimensionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vFieldData = Items.RowDimensions.CurrentData;
	If vFieldData <> Undefined Then
		vOverrideRow = Undefined;
		vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnDataPath", vFieldData.DataPath));
		If vOverrideRows.Count() = 0 Then
			vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnName", vFieldData.Name));
		EndIf;
		If vOverrideRows.Count() = 0 Then
			vOverrideRow = ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vFieldData.Name;
			vOverrideRow.ColumnDataPath = vFieldData.DataPath;
		Else
			vOverrideRow = vOverrideRows.Get(0);
		EndIf;
		If vOverrideRow <> Undefined Then
			vOverrideRow.ShowGroupClosed = vFieldData.GroupBy;
		EndIf;
	EndIf;
EndProcedure // RowDimensionsOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure ColumnDimensionsOnEditEnd(pItem, pNewRow, pCancelEdit)
	vFieldData = Items.ColumnDimensions.CurrentData;
	If vFieldData <> Undefined Then
		vOverrideRow = Undefined;
		vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnDataPath", vFieldData.DataPath));
		If vOverrideRows.Count() = 0 Then
			vOverrideRows = ReportColumnOverrides.FindRows(New Structure("ColumnName", vFieldData.Name));
		EndIf;
		If vOverrideRows.Count() = 0 Then
			vOverrideRow = ReportColumnOverrides.Add();
			vOverrideRow.ColumnName = vFieldData.Name;
			vOverrideRow.ColumnDataPath = vFieldData.DataPath;
		Else
			vOverrideRow = vOverrideRows.Get(0);
		EndIf;
		If vOverrideRow <> Undefined Then
			vOverrideRow.ShowGroupClosed = vFieldData.GroupBy;
		EndIf;
	EndIf;
EndProcedure // ColumnDimensionsOnEditEnd

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectedFieldsColumnHeaderDescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", pItem.EditText), pItem);
EndProcedure // SelectedFieldsColumnHeaderDescriptionOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure OrderPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsOrder, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // OrderPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure OrderPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "Order" Then
			vCurData = Items.Order.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OrderPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectedFieldsPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsField, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure // SelectedFieldsPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure SelectedFieldsPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "Field" Then
			vCurData = Items.SelectedFields.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // SelectedFieldsPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceAreaPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If vCurData <> Undefined Then
		vParams = New Structure("Report, AvailableFieldsAddress, AreaAddress, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", Report, AvailableFieldsAddress, vCurData.AreaAddress, True, True, True, False);
		OpenForm("CommonForm.tcReportAreaSelectionForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ConditionalAppearanceAreaPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceAreaPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If pSelectedValue <> Undefined And TypeOf(pSelectedValue) = Type("Structure") Then
		If vCurData <> Undefined Then
			vCurData.AreaAddress = pSelectedValue.AreaAddress;
			vCurData.AreaPresentation = pSelectedValue.AreaPresentation;
			LoadAreasForRowAtServer(Items.ConditionalAppearance.CurrentRow);
		EndIf;
	EndIf;
EndProcedure // ConditionalAppearanceAreaPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadAreasForRowAtServer(pRowID)
	vCurData = ReportConditionalAppearance.FindByID(pRowID);
	If vCurData <> Undefined Then
		vAreas = GetFromTempStorage(vCurData.AreaAddress);
		If vAreas <> Undefined And TypeOf(vAreas) = Type("ValueTable") Then
			vCurData.Area.Clear();
			For Each vAreasRow In vAreas Do
				vAreaItem = vCurData.Area.Add();
				FillPropertyValues(vAreaItem, vAreasRow);
			EndDo;
			vCurData.AreaAddress = PutToTempStorage(vAreas, ThisForm.UUID);
		EndIf;
	EndIf;
EndProcedure // LoadAreasForRowAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceAppearancePresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If vCurData <> Undefined Then
		vParams = New Structure("Report, AppearanceAddress, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", Report, vCurData.AppearanceAddress, True, True, True, False);
		OpenForm("CommonForm.tcReportAppearanceSelectionForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ConditionalAppearanceAppearancePresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceAppearancePresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If pSelectedValue <> Undefined And TypeOf(pSelectedValue) = Type("Structure") Then
		If vCurData <> Undefined Then
			vCurData.AppearanceAddress = pSelectedValue.AppearanceAddress;
			vCurData.AppearancePresentation = pSelectedValue.AppearancePresentation;
			LoadAppearancesForRowAtServer(Items.ConditionalAppearance.CurrentRow);
		EndIf;
	EndIf;
EndProcedure // ConditionalAppearanceAppearancePresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadAppearancesForRowAtServer(pRowID)
	vCurData = ReportConditionalAppearance.FindByID(pRowID);
	If vCurData <> Undefined Then
		vAppearances = GetFromTempStorage(vCurData.AppearanceAddress);
		If vAppearances <> Undefined And TypeOf(vAppearances) = Type("ValueTable") Then
			vCurData.Appearance.Clear();
			For Each vAppearancesRow In vAppearances Do
				vAppearanceItem = vCurData.Appearance.Add();
				FillPropertyValues(vAppearanceItem, vAppearancesRow);
			EndDo;
			vCurData.AppearanceAddress = PutToTempStorage(vAppearances, ThisForm.UUID);
		EndIf;
	EndIf;
EndProcedure // LoadAppearancesForRowAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceFilterPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If vCurData <> Undefined Then
		vParams = New Structure("Report, AvailableFieldsAddress, FilterAddress, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", Report, AvailableFieldsAddress, vCurData.FilterAddress, True, True, True, False);
		OpenForm("CommonForm.tcReportFilterSelectionForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // ConditionalAppearanceFilterPresentationStartChoice

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceFilterPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ConditionalAppearance.CurrentData;
	If pSelectedValue <> Undefined And TypeOf(pSelectedValue) = Type("Structure") Then
		If vCurData <> Undefined Then
			vCurData.FilterAddress = pSelectedValue.FilterAddress;
			vCurData.FilterPresentation = pSelectedValue.FilterPresentation;
			LoadFiltersForRowAtServer(Items.ConditionalAppearance.CurrentRow);
		EndIf;
	EndIf;
EndProcedure // ConditionalAppearanceFilterPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtServer
Procedure LoadFiltersForRowAtServer(pRowID)
	vCurData = ReportConditionalAppearance.FindByID(pRowID);
	If vCurData <> Undefined Then
		vFilters = GetFromTempStorage(vCurData.FilterAddress);
		If vFilters <> Undefined And TypeOf(vFilters) = Type("ValueTable") Then
			vCurData.Filter.Clear();
			For Each vFiltersRow In vFilters Do
				vFilterItem = vCurData.Filter.Add();
				FillPropertyValues(vFilterItem, vFiltersRow);
			EndDo;
			vCurData.FilterAddress = PutToTempStorage(vFilters, ThisForm.UUID);
		EndIf;
	EndIf;
EndProcedure // LoadFiltersForRowAtServer

// --------------------------------------------------------------------------------
&AtServer
Function UpdateValueTablesInTempStorage()
	vFilters = FormAttributeToValue("Filter");
	PutToTempStorage(vFilters, FilterAddress);
	
	vRowDims = FormAttributeToValue("RowDimensions");
	PutToTempStorage(vRowDims, RowDimensionsAddress);
	
	vColDims = FormAttributeToValue("ColumnDimensions");
	PutToTempStorage(vColDims, ColumnDimensionsAddress);
	
	vFields = FormAttributeToValue("SelectedFields");
	PutToTempStorage(vFields, SelectedFieldsAddress);
	
	vSortings = FormAttributeToValue("Order");
	PutToTempStorage(vSortings, OrderAddress);
	
	vCondApps = FormAttributeToValue("ReportConditionalAppearance");
	PutToTempStorage(vCondApps, ConditionalAppearanceAddress);
	
	vRepColOvrs = FormAttributeToValue("ReportColumnOverrides");
	PutToTempStorage(vRepColOvrs, ReportColumnOverridesAddress);
	
	vRetStruct = New Structure("Report, FilterAddress, RowDimensionsAddress, ColumnDimensionsAddress, SelectedFieldsAddress, OrderAddress, ConditionalAppearanceAddress, ReportColumnOverridesAddress, 
	                           |ReportAppearanceTemplateType, ReportAutoscaleType, ReportChartType, 
							   |ReportDimensionAttributesPlacementInColumnsType, ReportDimensionAttributesPlacementInRowsType, ReportDimensionsPlacementOnColumnsType, ReportDimensionsPlacementOnRowsType, 
							   |ReportDoNotPutDetailRecords, ReportDoNotPutOveralls, ReportDoNotPutReportFooter, ReportDoNotPutReportHeader, ReportDoNotPutTableFooter, ReportDoNotPutTableHeader, 
							   |ReportPageOrientation, ReportShowChartOnOpen, ReportTotalsPlacementOnColumnsType, ReportTotalsPlacementOnRowsType", 
	                           Report, FilterAddress, RowDimensionsAddress, ColumnDimensionsAddress , SelectedFieldsAddress, OrderAddress, ConditionalAppearanceAddress, ReportColumnOverridesAddress, 
	                           ?(ValueIsFilled(ReportAppearanceTemplateType), ReportAppearanceTemplateType, PredefinedValue("Enum.ReportAppearanceTemplateTypes.Interface")), ReportAutoscaleType, 
							   cmGetReportChartType(ReportChartType), 
							   ReportDimensionAttributesPlacementInColumnsType, ReportDimensionAttributesPlacementInRowsType, ReportDimensionsPlacementOnColumnsType, ReportDimensionsPlacementOnRowsType, 
							   ReportDoNotPutDetailRecords, ReportDoNotPutOveralls, ReportDoNotPutReportFooter, ReportDoNotPutReportHeader, ReportDoNotPutTableFooter, ReportDoNotPutTableHeader, 
							   ReportPageOrientation, ReportShowChartOnOpen, ReportTotalsPlacementOnColumnsType, ReportTotalsPlacementOnRowsType);
	Return vRetStruct;
EndFunction // UpdateValueTablesInTempStorage

// --------------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	vRetStruct = UpdateValueTablesInTempStorage();
	Notify("ReportSettings.Generate", vRetStruct, Report);
	ThisForm.Close();
EndProcedure // Generate

// --------------------------------------------------------------------------------
&AtClient
Procedure OrderOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.Order.CurrentData;
		If vCurData <> Undefined Then
			vCurData.Direction = PredefinedValue("Enum.SortingDirections.Asc");
		EndIf;
	EndIf;
EndProcedure // OrderOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure ColumnDimensionsOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.ColumnDimensions.CurrentData;
		If vCurData <> Undefined Then
			vCurData.DimensionType = PredefinedValue("Enum.ReportDimensionTypes.Items");
		EndIf;
	EndIf;
EndProcedure // ColumnDimensionsOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure RowDimensionsOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.RowDimensions.CurrentData;
		If vCurData <> Undefined Then
			vCurData.DimensionType = PredefinedValue("Enum.ReportDimensionTypes.Items");
		EndIf;
	EndIf;
EndProcedure // RowDimensionsOnStartEdit

// --------------------------------------------------------------------------------
&AtClient
Procedure ConditionalAppearanceOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow Then
		vCurData = Items.ConditionalAppearance.CurrentData;
		If vCurData <> Undefined Then
			vCurData.Use = True;
		EndIf;
	EndIf;
EndProcedure // ConditionalAppearanceOnStartEdit

// --------------------------------------------------------------------------------
&AtServer
Function LoadDefaultSettingsAtServer()
	vMessage = "";
	vRepObj = Undefined;
	If ValueIsFilled(Report) Then
		// Create report object
		If Report.IsExternal Then
			vURL = GetURL(Report.Report, "ExternalProcessingStorage"); 
			vName = ExternalReports.Connect(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(Report.Report, "FileName"), ".erf", ""), False);
			vRepObj = ExternalReports[vName];
		Else
			vRepObj = Reports[TrimAll(Report.Report)].Create();
		EndIf;
		vRepObj.Report = Report;
		// Load default settings for this object
		vMessage = LoadDefaultReportSettings(vRepObj);
		If IsBlankString(vMessage) Then
			// Reload this form data
			vParams = cmGetReportParametersStructure(vRepObj, ThisForm.UUID);
			FillPropertyValues(ThisForm, vParams);
			// Load settings from parameters
			LoadReportSettingFromParameters();
		EndIf;
	EndIf;
	Return vMessage;
EndFunction // LoadDefaultSettingsAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadDefaultSettings(pCommand)
	vMessage = LoadDefaultSettingsAtServer();
	If Not IsBlankString(vMessage) Then
		ShowMessageBox(, vMessage, 30);
	EndIf;
EndProcedure // LoadDefaultSettings

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAsDefaultSettingsAtServer()
	vRepObj = Undefined;
	If ValueIsFilled(Report) Then
		// Save current settings to the temp storage
		vSettingsStruct = UpdateValueTablesInTempStorage();
		// Create report object
		If Report.IsExternal Then
			vURL = GetURL(Report.Report, "ExternalProcessingStorage"); 
			vName = ExternalReports.Connect(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(Report.Report, "FileName"), ".erf", ""), False);
			vRepObj = ExternalReports[vName];
		Else
			vRepObj = Reports[TrimAll(Report.Report)].Create();
		EndIf;
		vRepObj.Report = Report;
		// Load report default settings
		vRepObj.pmLoadReportAttributes();
		// Apply report settings
		cmApplyReportSettingsStructure(vRepObj, vSettingsStruct);
		// Save current report settings
		vRepObj.pmSaveReportAttributes();
		// Save current settings as default settings for this object
		SaveAsDefaultReportSettings(vRepObj);
	EndIf;
EndProcedure // SaveAsDefaultSettingsAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveAsDefaultSettings(pCommand)
	SaveAsDefaultSettingsAtServer();
EndProcedure // SaveAsDefaultSettings

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAsDefaultReportSettings(pReportObject)
	pReportObject.pmSaveReportAttributes();
	vFileName = GetTempFileName("xml");
	cmWriteReportSettingsToFile(pReportObject.Report, vFileName);
	vFileReader = New TextReader(vFileName, TextEncoding.UTF8);
	vXMLData = vFileReader.Read();
	vFileReader.Close();
	vRepObj = pReportObject.Report.GetObject();
	vRepObj.DefaultSettings = New ValueStorage(vXMLData);
	vRepObj.Write();    
	DeleteFiles(vFileName);
EndProcedure // SaveAsDefaultReportSettings

// --------------------------------------------------------------------------------
&AtServer
Function LoadDefaultReportSettings(pReportObject) Export
	vMessage = "";
	vDefaultSettings = Undefined;
	If Not ValueIsFilled(pReportObject.Report) Then
		vMessage = NStr("en='Use menu option <Save current form attributes to existing setting> first!';
		                |ru='Сначала выполните пункт меню <Сохранить параметры в существующую настройку>!';
						|de='Zuerst im Menü den Punkt <Alle Parameter in den existierenden Einstellungen speichern> ausführen!'");
		Return vMessage;
	EndIf;
	If pReportObject.Report.DefaultSettings <> Undefined Then
		// Read settings from the report catalog item value storage
		vDefaultSettings = pReportObject.Report.DefaultSettings.Get();
		If TypeOf(vDefaultSettings) <> Type("String") Then
			// Read settings from the report binary template if found
			Try
				vFileName = GetTempFileName("xml");
				pReportObject.GetTemplate("DefaultSettings").Write(vFileName);
				vFileReader = New TextReader(vFileName, TextEncoding.UTF8);
				vDefaultSettings = vFileReader.Read();
				vFileReader.Close();
				DeleteFiles(vFileName);
			Except
			EndTry;
		EndIf;
	EndIf;
	If TypeOf(vDefaultSettings) <> Type("String") Then
		vMessage = NStr("en='Default report settings are not filled!';
		                |ru='Настройки отчета по умолчанию не заполнены!';
		                |de='Standardeinstellungen des Berichts sind nicht ausgefüllt!'");
		Return vMessage;
	EndIf;
	vFileName = GetTempFileName("xml");
	vFileWriter = New TextWriter(vFileName, TextEncoding.UTF8);
	vFileWriter.Write(vDefaultSettings);
	vFileWriter.Close();
	// Update report object
	vRepObj = pReportObject.Report.GetObject();
	cmReadReportSettingsFromFile(vRepObj, vFileName);
	vRepObj.Write();
	// Reload report attribuets from the catalog item
	pReportObject.pmLoadReportAttributes();
	DeleteFiles(vFileName);

	Return vMessage
EndFunction // LoadDefaultReportSettings

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveCurrentSettingsForAllUsers(pCommand)
	vRetStruct = UpdateValueTablesInTempStorage();
	Notify("ReportSettings.Save", vRetStruct, Report);
	ThisForm.Close();
EndProcedure // SaveCurrentSettingsForAllUsers

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFormCatalogItem(pCommand)
	OpenForm("Catalog.Reports.ObjectForm", New Structure("Key", Report));;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Report.Chaged" And pSource = Report Then
		Items.FormSaveCurrentSettingsForAllUsers.Enabled = Not tcOnServer.cmGetAttributeByRef(Report, "LockSettings");
	EndIf;	
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveNewAttributesSetting(pCommand)
	//vRetStruct = UpdateValueTablesInTempStorage();
	//
	//Notify("ReportSettings.SaveNewAttributesSetting", vRetStruct, Report);
	ThisForm.Close();
EndProcedure

&AtClient
Procedure FilterValueStartChoice(Item, ChoiceData, StandardProcessing)
	vFilterData = Items.Filter.CurrentData;
	If vFilterData <> Undefined Then
		If  vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InListByHierarchy") Or
			vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInListByHierarchy") Or
			vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.InHierarchy") Or
			vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.NotInHierarchy") Then  
			Items.FilterValue.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		Else        
			Items.FilterValue.ChoiceFoldersAndItems = FoldersAndItems.Items;
		EndIf;	
	EndIf;	
EndProcedure

&AtClient
Procedure SaveReportSettingsToFile(Command)
	If Modified Then
		Return;
	EndIf;
	// Start file operations
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult", ThisObject));
EndProcedure

// --------------------------------------------------------------------------------
// 
// Returns:
// String - File address   
//
&AtServer
Function ExportReportSettingsToXMLFileAtServer()
	vRepObj = Report;
	
	vFileName = GetTempFileName("xml");
	vNameSpaceURI = "http://1chotel.ru";
	vXMLWriter = New XMLWriter();
	vXMLWriter.OpenFile(vFileName, "UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("Hotel");
	vXMLWriter.WriteNamespaceMapping("htl", vNameSpaceURI);
	vXMLWriter.WriteStartElement("ReportSettings", vNameSpaceURI);
	vXMLWriter.WriteAttribute("report", vNameSpaceURI, TrimAll(vRepObj.Report));
	vXMLWriter.WriteAttribute("description", vNameSpaceURI, TrimAll(vRepObj.Description));
	vXMLWriter.WriteStartElement("Dynamic", vNameSpaceURI);
	WriteXML(vXMLWriter, vRepObj.DynamicParameters, XMLTypeAssignment.Explicit);
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteStartElement("Static", vNameSpaceURI);
	WriteXML(vXMLWriter, vRepObj.StaticParameters, XMLTypeAssignment.Explicit);
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.WriteEndElement();
	vXMLWriter.Close();
	
	vFileBinaryData = New BinaryData(vFileName);
	vFileTempStorageAddress = PutToTempStorage(vFileBinaryData, UUID);
	
	Return vFileTempStorageAddress;
EndFunction // ExportReportSettingsToXMLFileAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToSaveReportSettingsXMLFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted", ThisObject, pParam));
	EndIf;
EndProcedure // SaveReportSettingsToXMLFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult", ThisObject, pParam));
EndProcedure // SaveReportSettingsToXMLFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToSaveReportSettingsXMLFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // SaveReportSettingsToXMLFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToSaveReportSettingsXMLFileCompleted(pFileArray, pParam) Export
	If ValueIsFilled(pFileArray) Then
		vFullFileNameAtClient = pFileArray[0];
		StartTransferReportSettingsFileFromServerToClient(vFullFileNameAtClient);
	EndIf;
EndProcedure // OpenFileDialogToSaveReportSettingsXMLFileCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure StartTransferReportSettingsFileFromServerToClient(pFullFileNameAtClient) Export
	vFileAddressAtServer = ExportReportSettingsToXMLFileAtServer();

	vFilesArray = New Array();
	vFileDescription = New TransferableFileDescription(pFullFileNameAtClient, vFileAddressAtServer);
	vFilesArray.Add(vFileDescription);
	
	BeginGettingFiles(New NotifyDescription("ReportSettingsFileDownloadToClientCompleted", ThisObject), vFilesArray, , False);
EndProcedure // StartTransferReportSettingsFileFromServerToClient

// --------------------------------------------------------------------------------
&AtClient 
Procedure ReportSettingsFileDownloadToClientCompleted(pFilesArray, pParam) Export
	If pFilesArray <> Undefined Then
		// Show result message
		ShowMessageBox(, NStr("en='Report settings were exported to the file successfully!';ru='Настройки отчета были успешно сохранены в файл!';de='Die Berichtseinstellungen wurden erfolgreich in einer Datei gespeichert!'"), 5);
	EndIf;
EndProcedure // ReportSettingsFileDownloadToClientCompleted

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToSaveReportSettingsXMLFile()
	vFileSave = New FileDialog(FileDialogMode.Save);
	vSymPos = Find(ReportName, " - ");
	vFileSave.FullFileName = GetDefaultReportSettingsFileName(Report, Left(ReportName, vSymPos - 1));
	vFileSave.Filter = NStr("ru = 'XML файл (*.xml)|*.xml;|'; 
	                        |de = 'XML Datei (*.xml)|*.xml;|'; 
	                        |en = 'XML file (*.xml)|*.xml;|'");
	vFileSave.Multiselect = False;
	vFileSave.Title = NStr("en='Create file';ru='Создать файл';de='Datei erstellen'");
	vFileSave.Preview = False;
	vFileSave.CheckFileExist = True;
	vFileSave.Show(New NotifyDescription("OpenFileDialogToSaveReportSettingsXMLFileCompleted", ThisObject));
EndProcedure // OpenFileDialogToSaveReportSettingsXMLFile

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDescription - String Report Description 
//  pCode		 - String Report Code 
// 
// Returns:
//  String - Default file name for report export 
//
&AtServerNoContext
Function GetDefaultReportSettingsFileName(pDescription, pCode)
	Return StrReplace(cmGetValidFileName(cmNStr(TrimAll(pDescription))), " ", "_") + "_" + TrimAll(pCode);
EndFunction // GetDefaultReportSettingFileName
