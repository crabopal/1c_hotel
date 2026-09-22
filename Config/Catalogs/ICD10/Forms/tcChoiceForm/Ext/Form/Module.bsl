
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandartProcedure)
	Parameters.Property("TransferableParametersOnChoice", TransferableParametersOnChoice);
	Parameters.Property("ReturnAsStructure", ReturnAsStructure);

	ShowInHierarchy = True;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	Items.HierarchyView.Check = ShowInHierarchy;
	ApplyFilter();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterCodeOnChange(pItem)
	FilterByCode = GetInLat(pItem.EditText);
	ApplyFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FilterOnChange(pItem)
	ApplyFilter();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListSelection(pItem, pRowSelected, pField, pStandartProcessing)
	ReturnICDSelected(pItem, Items.List.CurrentRow, pStandartProcessing);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ListValueChoice(pItem, pValue, pStandartProcessing)
	ReturnICDSelected(pItem, Items.List.CurrentRow, pStandartProcessing);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ReturnICDSelected(pItem, pRowSelected, pStandartProcessing)
	pStandartProcessing = False;

	vCurData = pItem.CurrentData;

	If TypeOf(pRowSelected) = Type("CatalogRef.ICD10") Then 
		vICD10 = pRowSelected;
	Else 
		vICD10 = vCurData.Ref;
	EndIf;

	If ReturnAsStructure Then
		vChoiceResult = New Structure("Ref, Description, Code, TransferableParametersOnChoice");
		FillPropertyValues(vChoiceResult, vCurData);
		vChoiceResult.TransferableParametersOnChoice = TransferableParametersOnChoice;
		vChoiceResult.Ref = vICD10;
	Else
		vChoiceResult = vICD10;
	EndIf;

	NotifyChoice(vChoiceResult);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure Hierarchy(pCommand)
	Items.HierarchyView.Check = Not Items.HierarchyView.Check;
	ShowInHierarchy = Items.HierarchyView.Check;
	ApplyFilter();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Function GetInLat(vText)
	vText = Upper(vText);
	vText = StrReplace(vText, "А", "A");
	vText = StrReplace(vText, "В", "B");
	vText = StrReplace(vText, "С", "C");
	vText = StrReplace(vText, "Е", "E");
	vText = StrReplace(vText, "К", "K");
	vText = StrReplace(vText, "М", "M");
	vText = StrReplace(vText, "О", "O");
	vText = StrReplace(vText, "Р", "P");
	vText = StrReplace(vText, "Т", "T");
	vText = StrReplace(vText, "У", "Y");
	vText = StrReplace(vText, "Х", "X");
	Return vText;
EndFunction // GetInLat

// --------------------------------------------------------------------------------
&AtClient
Procedure ApplyFilter()
	List.Parameters.SetParameterValue("qCodeIsEmpty", Not ValueIsFilled(FilterByCode));
	List.Parameters.SetParameterValue("qCode", "%" + TrimAll(FilterByCode) + "%");
	List.Parameters.SetParameterValue("qDescriptionIsEmpty", Not ValueIsFilled(FilterByDescription));
	List.Parameters.SetParameterValue("qDescription", "%" + TrimAll(FilterByDescription) + "%");
	List.Parameters.SetParameterValue("qShowInHierarchy", ShowInHierarchy);

	If ShowInHierarchy Then
		Items.List.Representation = TableRepresentation.Tree;
	Else
		Items.List.Representation = TableRepresentation.List;
	EndIf;

	Items.List.Refresh();
EndProcedure

#EndRegion
