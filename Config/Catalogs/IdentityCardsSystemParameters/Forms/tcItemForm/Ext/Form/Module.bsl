#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	RefreshDisplay();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Object.CardReaderType = Enums.CardReaderTypes.ISD And Not ValueIsFilled(Object.ExternalInteraction) Then
		Message = New UserMessage;
		Message.Text = NStr("en = 'It is necessary to fill in the ISD connection settings'; 
							|de = 'Es ist notwendig, die ISD-Verbindungseinstellungen einzugeben'; 
							|ru = 'Необходимо заполнить настройки подключения к ISD'");
		Message.Field = "Object.ExternalInteraction";
		Message.Message();
		pCancel = True;
	EndIf;	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CardReaderTypeOnChange(Item)
	RefreshDisplay();
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
	
	OpenForm("CommonForm.tcTestConnectionCardReader", New Structure("IdentityCardsSystemParameter", Object.Ref), ThisObject, UUID);
EndProcedure // CheckConnection

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	Items.HardwareDriver.Visible = False;
	Items.FormOpenHardwareSettings.Visible = False;
	Items.GroupParameters.Visible = True;
	If Object.CardReaderType = Enums.CardReaderTypes.NativeDriver1C Then
		Items.HardwareDriver.Visible = True;
		Items.FormOpenHardwareSettings.Visible = True;
		Items.GroupParameters.Visible = False;
	ElsIf Object.CardReaderType = Enums.CardReaderTypes.IronLogicZ2 Then
		If Not IsBlankString(Object.Prefix) Then
			Object.Prefix = "";
		EndIf;
		If Not IsBlankString(Object.Suffix) Then
			Object.Suffix = "";
		EndIf;
		Items.Prefix.Enabled = False;
		Items.Suffix.Enabled = False;
	Else
		Items.Prefix.Enabled = True;
		Items.Suffix.Enabled = True;
	EndIf;
EndProcedure // RefreshDisplay

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenHardwareSettingsEnd(pValue, pExtraParams) Export
	Read();
EndProcedure // OpenHardwareSettings

#EndRegion