#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ChoiceList = Parameters.ValueList;
	MultipleChoice = Parameters.MultipleChoice;
	Title = Parameters.Title; 
	If ChoiceList.Count() = 0 Then
		pCancel = True;	
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'The list is empty'; de = 'Die Liste ist leer'; ru = 'Список пуст'"));
	Else
		For Each vItem In ChoiceList Do
			If Not ValueIsFilled(vItem.Presentation) Then
				vItem.Presentation = vItem.Value;	
			EndIf;
		EndDo;
	EndIf;
	Items.ChoiceListCheck.Visible = MultipleChoice; 
	Items.ChoiceListCheckAll.Visible = MultipleChoice;
	Items.ChoiceListUncheckAll.Visible = MultipleChoice;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormTableItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoiceListSelection(pItem, pSelectedRow, pField, pStandardProcessing)
	pStandardProcessing = False;
	vCurData = Items.ChoiceList.CurrentData;
	If vCurData <> Undefined Then
		If MultipleChoice Then
			If pField.Name <> "ChoiceListCheck" Then
				vCurData.Check = Not vCurData.Check;	
			EndIf;
		Else
			Close(vCurData);
		EndIf;
	EndIf;
EndProcedure // ChoiceListSelection

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure OK(pCommand)
	If MultipleChoice Then
		Close(ChoiceList);
	Else
		Close(Items.ChoiceList.CurrentData);	
	EndIf;
EndProcedure // OK

#EndRegion

