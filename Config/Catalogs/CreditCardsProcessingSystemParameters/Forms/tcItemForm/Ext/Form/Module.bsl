
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	SetVisible();
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	tcCommonFunctionOnClientServer.TextMessage(NStr("en='Terminal replied: ';ru='Ответ терминала: ';de='Antwort des Terminals: '") + TrimAll(pSource) + " - " + TrimAll(pEvent) + " - " + TrimAll(pData));
EndProcedure // ExternalEvent

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If Object.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.UCSSystemDriver Then
		If IsBlankString(Object.TerminalNumber) Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Terminal number is not filled in'; de = 'Terminalnummer nicht erfasst'; ru = 'Не заполнен номер терминала'"), , "Object.TerminalNumber", , True);
			pCancel = True;
		EndIf;
	EndIf;
	
	If Object.CreditCardsProcessingSystemType = Enums.CreditCardsProcessingSystems.NativeDriver1C Then
		If Not ValueIsFilled(Object.HardwareDriver) Then
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'The hardware driver is not filled in'; de = 'Der Hardwaretreiber ist nicht ausgefüllt'; ru = 'Не заполнен драйвер оборудования'"), , "Object.HardwareDriver", , True);
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // FillCheckProcessingAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure PrintSlipUsingTerminalPrinterOnChange(pItem)
	If Object.PrintSlipUsingTerminalPrinter Then
		If Object.PrintSlipInCheque Then
			Object.PrintSlipInCheque = False;
		EndIf;
		Items.PrintSlipInCheque.Enabled = False;
	Else
		Items.PrintSlipInCheque.Enabled = True;
	EndIf;
EndProcedure // PrintSlipUsingTerminalPrinterOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckConnection(Command)
	If Not ValueIsFilled(Object.CreditCardsProcessingSystemType) Then
		ShowMessageBox(, NStr("en='Pay card processing system type should be filled!';ru='Выберите тип системы процессинга кредитных карт!';de='Wählen Sie den Typ des Kreditkarten-Bearbeitungssystems!'"));
		Return;
	EndIf;
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write() Then
			Return;
		EndIf;	
	EndIf;	
	vPayCardProcessor = tcOnClient.cmGetModulTO(Object.Ref);
	// Run check connection routine
	vPayCardProcessor.pmCheckConnection(tcOnServer.cmGetAtributeAsArray(Object.Ref));
	// Refresh form
	Read();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Install(pCommand)
	If Not CheckFilling() Or Not Write() Then
		Return;
	EndIf;
	
	vDriver = tcOnClient.cmGetModulTO(Object.Ref);
	If vDriver = Undefined Then
		ShowMessageBox(, Nstr("en = 'Work with driver this device is not supported'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;
	
	vDriver.pmInstall(Object.CreditCardsProcessingSystemType);
EndProcedure // Install

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenHardwareSettings(pCommand)
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.tcHardwareDriverSettings", New Structure("Hardware", Object.Ref), ThisObject, UUID, , , New NotifyDescription("OpenHardwareSettingsEnd", ThisObject));
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenHardwareSettingsEnd(pValue, pExtraParams) Export
	If pValue = Undefined Then
		Return;
	EndIf;
	
	OpenHardwareSettingsEndAtServer(pValue);
	Read();
EndProcedure // OpenHardwareSettings

// --------------------------------------------------------------------------------
&AtClient
Procedure SetVisible()
	#If WebClient Then
		ReadOnly = True;
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Not supported in web client'; de = 'Wird im Webclient nicht unterstützt'; ru = 'Не поддерживается в веб-клиенте'"));
		Return;
	#EndIf
	
	Items.SaveCreditCardsData.Enabled = True;
	Items.TerminalNumber.Visible = True;
	Items.FormCheckConnection.Visible = False;
	Items.GroupCommandCode.Visible = False;
	Items.FormInstall.Visible = False;
	Items.PrintSlipUsingTerminalPrinter.Visible = True;
	Items.Timeout.Visible = False;
	Items.MerchantID.Visible = False;
	Items.SlipCharLineLength.Visible = False;
	Items.MultiTrackReader.Visible = False;
	Items.CurrentDeviceNumber.Visible = False;
	Items.HardwareDriver.Visible = False;
	Items.FormOpenHardwareSettings.Visible = False;
	If Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.AtolPayCardSystemsDriver") Then
		Items.CurrentDeviceNumber.Visible = True;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = True;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.TrPosPOSTerminalsDriver") Then
		Items.FormCheckConnection.Visible = True;
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.INPASPulsarSystemDriver") Then
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.INPASDualConnectorDriver82") Or 
		Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.INPASDualConnectorDriver83") Then
		Items.FormCheckConnection.Visible = True;
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.NativeDriver1C") Then
		Items.MerchantID.Visible = True;
		Items.HardwareDriver.Visible = True;
		Items.FormOpenHardwareSettings.Visible = True;
		Items.TerminalNumber.Visible = False;
		Items.FormCheckConnection.Visible = False;
		Items.PrintSlipUsingTerminalPrinter.Visible = False;
		Items.PrintSlipInCheque.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.UCSSystemDriver") Then
		Items.FormCheckConnection.Visible = True;
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
		Items.SaveCreditCardsData.Enabled = False;
		If Object.SaveCreditCardsData Then
			Object.SaveCreditCardsData = False;
		EndIf;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.UCSNativeSystemDriver") Then
		Items.FormInstall.Visible = True;
		Items.FormCheckConnection.Visible = True;
		Items.Timeout.Visible = True;
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = False;
		Items.MultiTrackReader.Visible = False;
		Items.SaveCreditCardsData.Enabled = False;
		If Object.SaveCreditCardsData Then
			Object.SaveCreditCardsData = False;
		EndIf;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankSBRFCOMSystemDriver") Then
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
		Items.SaveCreditCardsData.Enabled = False;
		If Object.SaveCreditCardsData Then
			Object.SaveCreditCardsData = False;
		EndIf;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankSBRFSystemDriver") Then
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = False;
		Items.MultiTrackReader.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNTSystemDriver") Or Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.SberbankPilotNT33_33SystemDriver") Then
		Items.FormInstall.Visible = True;
		Items.FormCheckConnection.Visible = True;
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = False;
		Items.MultiTrackReader.Visible = False;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.EMVGateCOM1C") Then
		Items.CurrentDeviceNumber.Visible = False;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = False;
		Items.SaveCreditCardsData.Enabled = True;
		Items.FormCheckConnection.Visible = True;
		If Object.SaveCreditCardsData Then
			Object.SaveCreditCardsData = False;
		EndIf;
	ElsIf Object.CreditCardsProcessingSystemType = PredefinedValue("Enum.CreditCardsProcessingSystems.Arcus2SystemsDriver") Then
		Items.CurrentDeviceNumber.Visible = False;
		Items.TerminalNumber.Visible = False;
		Items.SlipCharLineLength.Visible = False;
		Items.PrintSlipUsingTerminalPrinter.Visible = False;
		Items.GroupCommandCode.Visible = True;
		Items.FormCheckConnection.Visible = True;
	Else
		Items.CurrentDeviceNumber.Visible = True;
		Items.SlipCharLineLength.Visible = True;
		Items.MultiTrackReader.Visible = True;
	EndIf;
EndProcedure // SetVisible

// --------------------------------------------------------------------------------
&AtServer
Procedure OpenHardwareSettingsEndAtServer(pValue)
	Read();
EndProcedure // OpenHardwareSettingsEndAtServer

#EndRegion
