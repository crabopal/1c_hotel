
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(Parameters.LabelDescription) Then
		ThisForm.Title 	= Parameters.LabelDescription;
	EndIf;
    Items.ResultRadioButton.ChoiceList.Add(0,Enums.CancelActionTypes.ClientRefusal);
	Items.ResultRadioButton.ChoiceList.Add(1,Enums.CancelActionTypes.EmployeeFault);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksStartChoice(Item, ChoiceData, StandardProcessing)
	vResult = Undefined;
	ShowChooseFromMenu(New NotifyDescription("RemarksStartChoiceEnd", ThisForm), GetList(),Item);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure RemarksStartChoiceEnd(SelectedItem, AdditionalParameters) Export
	vResult = SelectedItem;
	If vResult <> Undefined Then
		Remarks = vResult.Value;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OK(Command)
	vParam = New Structure();
	vParam.Insert("Remarks",Remarks);
	vParam.Insert("TypeOfStorno",ResultTypeOfStorno);
	
	Close(vParam);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function GetList()
	vParam = New Structure();
	vParam.Insert("Filter", New Structure("DeletionMark",False));
	vParam.Insert("SearchString", Undefined);
	vParam.Insert("ChoiceFoldersAndItems", FoldersAndItems.Items);
	Return Catalogs.UsualActionReasons.GetChoiceData(vParam)
EndFunction	

#EndRegion
