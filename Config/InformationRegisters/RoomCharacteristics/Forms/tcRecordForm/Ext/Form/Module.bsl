// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Check user rights to use item
	If Not cmCheckUserPermissions("HavePermissionToManageRoomInventory") Then
		ThisForm.ReadOnly = True;
	EndIf;
	
	// Set value type
	If Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.HallArea") Or
	   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.LavatoryArea") Or
	   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.LivingArea") Or
	   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.TotalArea") Then
		Items.RoomCharacteristicValue.TypeRestriction = tcOnServer.GetNumberTypeDescription(10, 2, True);
	ElsIf Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.IsAdaptedForDisabled") Then
		Items.RoomCharacteristicValue.TypeRestriction = tcOnServer.GetBooleanTypeDescription();
	ElsIf ValueIsFilled(Record.RoomCharacteristic) Then
		Items.RoomCharacteristicValue.TypeRestriction = Record.RoomCharacteristic.ValueType;
	EndIf;
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure RoomCharacteristicOnChange(pItem)
	If ValueIsFilled(Record.RoomCharacteristic) Then
		If Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.HallArea") Or
		   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.LavatoryArea") Or
		   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.LivingArea") Or
		   Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.TotalArea") Then
			If TypeOf(Record.RoomCharacteristicValue) <> Type("Number") Then
				Record.RoomCharacteristicValue = 0;
				Items.RoomCharacteristicValue.TypeRestriction = tcOnServer.GetNumberTypeDescription(10, 2, True);
			EndIf;
		ElsIf Record.RoomCharacteristic = PredefinedValue("ChartOfCharacteristicTypes.RoomCharacteristicTypes.IsAdaptedForDisabled") Then
			If TypeOf(Record.RoomCharacteristicValue) <> Type("Boolean") Then
				Record.RoomCharacteristicValue = False;
				Items.RoomCharacteristicValue.TypeRestriction = tcOnServer.GetBooleanTypeDescription();
			EndIf;
		Else
			SetValueTypeAtServer();
		EndIf;
	EndIf;
EndProcedure // RoomCharacteristicOnChange

// --------------------------------------------------------------------------------
&AtServer
Procedure SetValueTypeAtServer()
	Items.RoomCharacteristicValue.TypeRestriction = Record.RoomCharacteristic.ValueType;
	Record.RoomCharacteristicValue = Record.RoomCharacteristic.ValueType.AdjustValue();
EndProcedure // SetValueTypeAtServer
