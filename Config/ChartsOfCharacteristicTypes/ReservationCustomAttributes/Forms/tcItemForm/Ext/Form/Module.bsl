// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ValueTypeOnChangeAtServer();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure DescriptionOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure // DescriptionOpening

// --------------------------------------------------------------------------------
&AtClient
Procedure RemarksOpening(pItem, pStandardProcessing)
	pStandardProcessing = False;
	OpenForm("Catalog.Languages.Form.tcEditForm", New Structure("Text", TrimAll(pItem.EditText)), pItem);
EndProcedure // RemarksOpening

// --------------------------------------------------------------------------------
&AtServer
Procedure CodeOnChangeAtServer()
	Object.Code = cmGetValidName(TrimAll(Object.Code));
EndProcedure // CodeOnChangeAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CodeOnChange(pItem)
	CodeOnChangeAtServer();
EndProcedure // CodeOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure ValueTypeOnChangeAtServer()
	If Object.ValueType = cmGetStringTypeDescription(Object.ValueType.StringQualifiers.Length, Object.ValueType.StringQualifiers.AllowedLength) Then
		Items.ChoiceListValues.Enabled = True;
		Items.GroupChoiceParameters.Enabled = False;
	Else
		Items.ChoiceListValues.Enabled = False;
		Items.GroupChoiceParameters.Enabled = True;
	EndIf;
EndProcedure // ValueTypeOnChange

// --------------------------------------------------------------------------------
&AtClient
Procedure ValueTypeOnChange(pItem)
	ValueTypeOnChangeAtServer();
EndProcedure // ValueTypeOnChange
