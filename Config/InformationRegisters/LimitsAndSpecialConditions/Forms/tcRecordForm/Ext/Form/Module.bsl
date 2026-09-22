// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("Owner") And ValueIsFilled(Parameters.Owner) Then
		If Record.Owner <> Parameters.Owner Then
			Record.Owner = Parameters.Owner;
		EndIf;
	EndIf;
	If ValueIsFilled(Record.Characteristic) Then
		If Record.Characteristic.IsImportantDate Then
			Items.Hotel.Visible = False;
		EndIf;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure CharacteristicOnChange(pItem)
	Items.CharacteristicValue.ChooseType = True;
	Items.Hotel.Visible = True;
	If ValueIsFilled(Record.Characteristic) Then
		vIsImportantDate = tcOnServer.cmGetAttributeByRef(Record.Characteristic, "IsImportantDate");
		If vIsImportantDate Then
			Items.Hotel.Visible = False;
		EndIf;
		vValueType = tcOnServer.cmGetAttributeByRef(Record.Characteristic, "ValueType");
		If vValueType = GetDateTypeDescription() Then
			Items.CharacteristicValue.ChooseType = False;
			Record.CharacteristicValue = '00010101';
		ElsIf vValueType = GetBooleanTypeDescription() Then
			Items.CharacteristicValue.ChooseType = False;
			Record.CharacteristicValue = False;
		ElsIf vValueType = GetNumberTypeDescription() Then
			Items.CharacteristicValue.ChooseType = False;
			Record.CharacteristicValue = 0;
		ElsIf vValueType = GetStringTypeDescription() Then
			Items.CharacteristicValue.ChooseType = False;
			Record.CharacteristicValue = "";
		EndIf;
	EndIf;
EndProcedure // CharacteristicOnChange

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetDateTypeDescription()
	Return cmGetDateTypeDescription();
EndFunction // GetDateTypeDescription

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetBooleanTypeDescription()
	Return cmGetBooleanTypeDescription();
EndFunction // GetBooleanTypeDescription

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetNumberTypeDescription()
	Return cmGetNumberTypeDescription(17, 2);
EndFunction // GetNumberTypeDescription

// --------------------------------------------------------------------------------
&AtServerNoContext
Function GetStringTypeDescription()
	Return cmGetStringTypeDescription(1024);
EndFunction // GetStringTypeDescription
