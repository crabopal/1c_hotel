// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Fill form attributes
	FillPropertyValues(ThisForm, Parameters);
	
	// Check if report attribute is defined
	If Not ValueIsFilled(Report) Then
		pCancel = True;
		Return;
	EndIf;
	
	// Report name
	ReportName = TrimAll(Report.Code) + " - " + cmNStr(Report.Description);
	
	// Restore selected fields value table
	vFilters = Undefined;
	If IsBlankString(FilterAddress) Then
		vFilters = New ValueTable();
		vFilters.Columns.Add("Name", cmGetStringTypeDescription(1000));
		vFilters.Columns.Add("Presentation", cmGetStringTypeDescription(1000));
		vFilters.Columns.Add("DataPath", cmGetStringTypeDescription(1000));
		vFilters.Columns.Add("ComparisonType", cmGetEnumTypeDescription("ComparisonTypes"));
		vFilters.Columns.Add("Value");
		vFilters.Columns.Add("ValueFrom");
		vFilters.Columns.Add("ValueTo");
		vFilters.Columns.Add("ValueType");
		vFilters.Columns.Add("Use", cmGetBooleanTypeDescription());
	Else
		vFilters = GetFromTempStorage(FilterAddress);
	EndIf;
	If vFilters = Undefined Or TypeOf(vFilters) <> Type("ValueTable") Then
		pCancel = True;
		Return;
	EndIf;
	Filters.Clear();
	For Each vFiltersRow In vFilters Do
		vFilterItem = Filters.Add();
		FillPropertyValues(vFilterItem, vFiltersRow);
	EndDo;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	vFilterPresentation = "";
	vFilterAddress = GetFilterAddressAtServer(vFilterPresentation);
	NotifyChoice(New Structure("Report, FilterAddress, FilterPresentation", Report, vFilterAddress, vFilterPresentation));
EndProcedure // SaveSettings

// --------------------------------------------------------------------------------
&AtServer
Function GetFilterAddressAtServer(rFilterPresentation)
	rFilterPresentation = "";
	vFilters = FormAttributeToValue("Filters");
	For Each vFiltersRow In vFilters Do
		If vFiltersRow.Use Then
			rFilterPresentation = rFilterPresentation + 
			                      ?(IsBlankString(rFilterPresentation), "", "; ") + 
								  GetFilterItemPresentation(vFiltersRow);
		EndIf;
	EndDo;
	vFilterAddress = PutToTempStorage(vFilters, ThisForm.UUID);
	Return vFilterAddress;
EndFunction // GetFilterAddressAtServer

// --------------------------------------------------------------------------------
&AtServer
Function GetFilterItemPresentation(pRow)
	vPres = "";
	If pRow.ComparisonType = Enums.ComparisonTypes.Equal Then
		vPres = TrimAll(pRow.Presentation) + " = " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.NotEqual Then
		vPres = TrimAll(pRow.Presentation) + " <> " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.Greater Then
		vPres = TrimAll(pRow.Presentation) + " > " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.GreaterOrEqual Then
		vPres = TrimAll(pRow.Presentation) + " >= " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.Less Then
		vPres = TrimAll(pRow.Presentation) + " < " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.LessOrEqual Then
		vPres = TrimAll(pRow.Presentation) + " <= " + """" + TrimAll(pRow.Value) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.Interval Then
		vPres = """" + TrimAll(pRow.ValueFrom) + """" + " < " + TrimAll(pRow.Presentation) + " < " + """" + TrimAll(pRow.ValueTo) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.IntervalIncludingBounds Then
		vPres = """" + TrimAll(pRow.ValueFrom) + """" + " <= " + TrimAll(pRow.Presentation) + " <= " + """" + TrimAll(pRow.ValueTo) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.IntervalIncludingLowerBound Then
		vPres = """" + TrimAll(pRow.ValueFrom) + """" + " <= " + TrimAll(pRow.Presentation) + " < " + """" + TrimAll(pRow.ValueTo) + """";
	ElsIf pRow.ComparisonType = Enums.ComparisonTypes.IntervalIncludingUpperBound Then
		vPres = """" + TrimAll(pRow.ValueFrom) + """" + " < " + TrimAll(pRow.Presentation) + " <= " + """" + TrimAll(pRow.ValueTo) + """";
	Else
		vPres = TrimAll(pRow.Presentation) + " " + TrimAll(pRow.ComparisonType) + " " + """" + TrimAll(pRow.Value) + """";
	EndIf;
	Return vPres;
EndFunction // GetFilterItemPresentation

// --------------------------------------------------------------------------------
&AtClient
Procedure FiltersPresentationStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vParams = New Structure("AvailableFieldsAddress, IsField, ChoiceMode, CloseOnChoice, CloseOnOwnerClose, ReadOnly", AvailableFieldsAddress, True, True, True, True, False);
	OpenForm("CommonForm.tcFieldChoiceForm", vParams, pItem, Report, , , , FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FiltersPresentationChoiceProcessing(pItem, pSelectedValue, pStandardProcessing)
	pStandardProcessing = False;
	If TypeOf(pSelectedValue) = Type("Structure") Then
		vCurData = Undefined;
		If pSelectedValue.Mode = "Field" Then
			vCurData = Items.Filters.CurrentData;
			If vCurData <> Undefined Then
				FillPropertyValues(vCurData, pSelectedValue);
				If TypeOf(vCurData.ValueType) = Type("TypeDescription") Then
					vCurData.Value = vCurData.ValueType.AdjustValue();
					vCurData.ValueFrom = vCurData.Value;
					vCurData.ValueTo = vCurData.Value;
					If vCurData.ValueType.Types().Count() = 1 Then
						Items.FiltersValue.ChooseType = False;	
						Items.FiltersValueFrom.ChooseType = False;	
						Items.FiltersValueTo.ChooseType = False;
					Else
						Items.FiltersValue.ChooseType = True;	
						Items.FiltersValueFrom.ChooseType = True;	
						Items.FiltersValueTo.ChooseType = True;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FiltersPresentationChoiceProcessing

// --------------------------------------------------------------------------------
&AtClient
Procedure FiltersComparisonTypeOnChange(pItem)
	vFilterData = Items.Filters.CurrentData;
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
			Items.FiltersValuesRange.Visible = False;
			Items.FiltersValue.Visible = True;
		ElsIf vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or 
		      vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			vFilterData.Value = vFilterData.ValueType.AdjustValue();
			vFilterData.ValueFrom = vFilterData.Value;
			vFilterData.ValueTo = vFilterData.Value;
			Items.FiltersValuesRange.Visible = True;
			Items.FiltersValue.Visible = False;
		Else
			vFilterData.Value = vFilterData.ValueType.AdjustValue();
			vFilterData.ValueFrom = vFilterData.Value;
			vFilterData.ValueTo = vFilterData.Value;
			Items.FiltersValuesRange.Visible = False;
			Items.FiltersValue.Visible = True;
		EndIf;
		If vFilterData.ValueType.Types().Count() = 1 Then
			Items.FiltersValue.ChooseType = False;	
			Items.FiltersValueFrom.ChooseType = False;	
			Items.FiltersValueTo.ChooseType = False;
		Else
			Items.FiltersValue.ChooseType = True;	
			Items.FiltersValueFrom.ChooseType = True;	
			Items.FiltersValueTo.ChooseType = True;
		EndIf;
	EndIf;
EndProcedure // FiltersComparisonTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterValueOnChange(pItem)
	vFilterData = Items.Filters.CurrentData;
	If vFilterData <> Undefined And ValueIsFilled(vFilterData.ComparisonType) Then
		vFilterData.Use = True;
		If vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or
		   vFilterData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			If ValueIsFilled(vFilterData.Value) Then
				vFilterData.ValueFrom = vFilterData.Value;
				vFilterData.Value = vFilterData.ValueType.AdjustValue();
			EndIf;
		Else
			If ValueIsFilled(vFilterData.ValueFrom) Then
				vFilterData.Value = vFilterData.ValueFrom;
				vFilterData.ValueFrom = vFilterData.ValueType.AdjustValue();
				vFilterData.ValueTo = vFilterData.ValueFrom;
			ElsIf ValueIsFilled(vFilterData.ValueTo) Then
				vFilterData.Value = vFilterData.ValueTo;
				vFilterData.ValueFrom = vFilterData.ValueType.AdjustValue();
				vFilterData.ValueTo = vFilterData.ValueFrom;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // FilterValueOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure FiltersOnActivateRow(pItem)
	vCurData = Items.Filters.CurrentData;
	If vCurData <> Undefined Then
		If vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Interval") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingBounds") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingLowerBound") Or 
		   vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.IntervalIncludingUpperBound") Then
			Items.FiltersValuesRange.Visible = True;
			Items.FiltersValue.Visible = False;
		Else
			Items.FiltersValuesRange.Visible = False;
			Items.FiltersValue.Visible = True;
		EndIf;
		If vCurData.ValueType.Types().Count() = 1 Then
			Items.FiltersValue.ChooseType = False;	
			Items.FiltersValueFrom.ChooseType = False;	
			Items.FiltersValueTo.ChooseType = False;
		Else
			Items.FiltersValue.ChooseType = True;	
			Items.FiltersValueFrom.ChooseType = True;	
			Items.FiltersValueTo.ChooseType = True;
		EndIf;
	EndIf;
EndProcedure // FiltersOnActivateRow

// --------------------------------------------------------------------------------
&AtClient
Procedure FiltersOnStartEdit(pItem, pNewRow, pClone)
	If pNewRow And Not pClone Then
		vCurData = Items.Filters.CurrentData;
		If vCurData <> Undefined Then
			vCurData.ComparisonType = PredefinedValue("Enum.ComparisonTypes.Equal");
			Items.FiltersValuesRange.Visible = False;
			Items.FiltersValue.Visible = True;
		EndIf;
	EndIf;
EndProcedure // FiltersOnStartEdit
