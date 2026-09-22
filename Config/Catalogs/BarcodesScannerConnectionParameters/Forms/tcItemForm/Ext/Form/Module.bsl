
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	SetAppirance();
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure CardReaderTypeOnChange(pItem)
	SetAppirance();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure OpenHardwareSettings(Command)
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.tcHardwareDriverSettings", New Structure("Hardware", Object.Ref), ThisObject, UUID, , , New NotifyDescription("OpenHardwareSettingsEnd", ThisObject));
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckConnection(pCommand)
	If Not ValueIsFilled(Object.CardReaderType) Then
		ShowMessageBox(, NStr("en = 'driver type should be filled!'; de = 'Wählen Sie den Typ des Fahrer'; ru = 'Выберите тип драйвера!'"));
		Return;
	EndIf;
	
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.tcTestConnectionBarcodesScanner", New Structure("BarcodesScannerConnectionParameter", Object.Ref), ThisObject, UUID);
EndProcedure // CheckConnection

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure SetAppirance()
	If Object.CardReaderType = Enums.CardReaderTypes.NativeDriver1C Then
		Items.HardwareDriver.Visible = True;
		Items.FormOpenHardwareSettings.Visible = True;
		Items.GroupParameters.Visible = False;
		Items.GroupPrefixSuffix.Visible = False;
	Else
		Items.HardwareDriver.Visible = False;
		Items.FormOpenHardwareSettings.Visible = False;
		Items.GroupParameters.Visible = True;
		Items.GroupPrefixSuffix.Visible = True;
	EndIf;
EndProcedure // SetAppirance

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenHardwareSettingsEnd(pValue, pExtraParams) Export
	Read();
EndProcedure // OpenHardwareSettings

#EndRegion
