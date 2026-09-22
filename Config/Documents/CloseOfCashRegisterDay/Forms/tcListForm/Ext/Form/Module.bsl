
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If ValueIsFilled(SessionParameters.CurrentUser) And ValueIsFilled(SessionParameters.CurrentUser.Customer) Then
		pCancel = True;
	EndIf;
	If Parameters.Property("SelCompany") Then
		SelCompany = Parameters.SelCompany;
		Items.SelCompany.Visible = True;
		If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
			Items.SelCompany.Enabled = True;
		Else
			Items.SelCompany.Enabled = False;
		EndIf;
	Else		
		If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
			Items.SelCompany.Visible = True;
			Items.SelCompany.Enabled = True;
		Else
			Items.SelCompany.Visible = False;
			Items.SelCompany.Enabled = False;
		EndIf;
	EndIf;
	If Parameters.Property("SelCashRegister") Then
		SelCashRegister = Parameters.SelCashRegister;
	EndIf;
	vCashRegistersList = New ValueList();
	If ValueIsFilled(SelCashRegister) Then
		vCashRegistersList.Add(SelCashRegister);
	Else
		If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
			vCashRegistersList = cmGetListOfAllCashRegisters(SelCompany);
		Else
			vCashRegistersList = cmGetListOfCashRegistersAllowed(SelCompany, SessionParameters.CurrentWorkstation);
		EndIf;
	EndIf;
	Items.SelCashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
	SelCashRegisterOnChangeAtServer();
	Items.FormPrintUnprintedCheque.Visible = IsInRole("Administrator");	
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCashRegisterOnChange(pItem)
	SelCashRegisterOnChangeAtServer();
EndProcedure // SelCashRegisterOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure SelCompanyOnChange(pItem)
	SelCompanyOnChangeAtServer();
EndProcedure // SelCompanyOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceHourXReport(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		ShowMessageBox(, NStr("en='You do not have rights to print cash register X-Report!'; ru='Нет прав на печать X-Отчета по ККМ на ФР!'; de='Sie haben keine Rechte, X-Berichte nach Registrierkassen mit dem Fiskaldrucker auszudrucken!'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;

	vList = GetCashRegisterList();
	If vList.Count() > 1 Then
		vList.ShowChooseItem(New NotifyDescription("CashRegisterPrintDeviceHourXReportCashRegisterAfterUserChoice", ThisForm, New Structure()), NStr("en='Select cash register please!'; ru='Выберите ККМ!'; de='Wählen Sie Registrierkasse!'"));
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 0 Then
			vUserChoiceItem = vList.Get(0);
		EndIf;
		CashRegisterPrintDeviceHourXReportCashRegisterAfterUserChoice(vUserChoiceItem, New Structure());
	EndIf;
EndProcedure // CashRegisterPrintDeviceHourXReport

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceXReport(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		ShowMessageBox(, NStr("en='You do not have rights to print cash register X-Report!'; ru='Нет прав на печать X-Отчета по ККМ на ФР!'; de='Sie haben keine Rechte, X-Berichte nach Registrierkassen mit dem Fiskaldrucker auszudrucken!'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;
	vList = GetCashRegisterList();
	If vList.Count() > 1 Then
		vList.ShowChooseItem(New NotifyDescription("CashRegisterPrintDeviceXReportAfterCashRegisterUserChoice", ThisForm, New Structure()), NStr("en='Select cash register please!'; ru='Выберите ККМ!'; de='Wählen Sie Registrierkasse!'"));
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 0 Then
			vUserChoiceItem = vList.Get(0);
		EndIf;
		CashRegisterPrintDeviceXReportAfterCashRegisterUserChoice(vUserChoiceItem, New Structure());
	EndIf;
EndProcedure // CashRegisterPrintDeviceXReport

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceCurrentStateOfCalculationsReport(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		ShowMessageBox(,NStr("en='You do not have rights to print cash register report!'; ru='Нет прав на печать отчета по ККМ на ФР!'; de='Sie haben keine Rechte, Berichte nach Registrierkassen mit dem Fiskaldrucker auszudrucken!'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return;
	EndIf;
	vList = GetCashRegisterList();
	If vList.Count() > 1 Then
		vList.ShowChooseItem(New NotifyDescription("CashRegisterPrintDeviceCurrentStateOfCalculationsReportAfterCashRegisterUserChoice", ThisForm, New Structure()), NStr("en='Select cash register please!';ru='Выберите ККМ!';de=' Wählen Sie Registrierkasse!'"));
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 0 Then
			vUserChoiceItem = vList.Get(0);
		EndIf;
		CashRegisterPrintDeviceCurrentStateOfCalculationsReportAfterCashRegisterUserChoice(vUserChoiceItem, New Structure());
	EndIf;
EndProcedure // CashRegisterPrintDeviceCurrentStateOfCalculationsReport

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterOpenPaymentSystemServiceFunctionsMenu(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		ShowMessageBox(, NStr("en='You do not have rights to open payment terminal service functions menu!'; ru='Нет прав на открытие меню сервисных функций платежного термнала!'; de='Sie haben keine Rechte, das Menü der Servicefunktionen des Zahlungsterminals zu öffnen!'"));
		Return;
	EndIf;
	
	vList = GetCashRegisterList();
	If vList.Count() > 1 Then
		vList.ShowChooseItem(New NotifyDescription("CashRegisterListAfterUserChoice", ThisObject), NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 0 Then
			vUserChoiceItem = vList.Get(0);
		EndIf;
		CashRegisterListAfterUserChoice(vUserChoiceItem, Undefined);
	EndIf;
EndProcedure // CashRegisterOpenPaymentSystemServiceFunctionsMenu

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterSetDeviceTime(pCommand)
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterZReport") Then
		ShowMessageBox(, NStr("en = 'You do not have rights to set cash register time!'; de = 'Sie haben keine Rechte, die Zeit im Fiskaldrucker einzurichten!'; ru = 'Нет прав на установку времени в ФР!'"));
		Return;
	EndIf;
	vCashRegistersList = GetCashRegister(); 
	If vCashRegistersList.Count() = 1 Then
		AfterCashRegisterUserChoice(vCashRegistersList[0], Undefined);	
	ElsIf vCashRegistersList.Count() > 1 Then
		vCashRegistersList.ShowChooseItem(New NotifyDescription("AfterCashRegisterUserChoice", ThisForm), NStr("en = 'Select cash register please!'; de = 'Wählen Sie Registrierkasse!'; ru = 'Выберите ККМ!'"));	
	EndIf;
EndProcedure // CashRegisterSetDeviceTime

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintUnprintedCheque(pCommand)
	OpenForm("CommonForm.tcPrintUnprintedChequeForm",, ThisForm, UUID);
EndProcedure // PrintUnprintedCheque

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceHourXReportCashRegisterAfterUserChoice(pUserChoiceItem, pExtraParameters) Export
	vMessage = "";
	If pUserChoiceItem <> Undefined Then
		vCashRegister = pUserChoiceItem.Value;
		vDriver = tcOnClient.cmGetModulTO(vCashRegister);
		If Not vDriver = Undefined And tcOnServer.cmGetAttributeByRef(vCashRegister, "IsControlledByProgram") Then
			vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(True, vCashRegister);
			vQuestion =  NStr("ru='Пожалуйста введите пароль ККМ...'; 
			                  |de='Input cash register password please...';
			                  |en='Input cash register password please...'");
			If IsBlankString(vPasswordKKM) Then
				vNotifyDescr = New NotifyDescription("AfterInputCashRegisterPasswordHourXReport", ThisForm, New Structure("Driver, rMessage, pObject", vDriver, vMessage, vCashRegister));
				OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisForm, , , , vNotifyDescr);
			Else
				vDriver.pmPrintHourXReport(vMessage, vCashRegister, vPasswordKKM);
			EndIf;
		Else
			ShowMessageBox(, Nstr("en = 'This device is not supported by the driver!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;	
EndProcedure // CashRegisterPrintDeviceHourXReportCashRegisterAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceXReportAfterCashRegisterUserChoice(pUserChoiceItem, pExtraParameters) Export
	vMessage = "";
	If pUserChoiceItem <> Undefined Then
		vCashRegister = pUserChoiceItem.Value;
		vDriver = tcOnClient.cmGetModulTO(vCashRegister);
		If Not vDriver = Undefined And tcOnServer.cmGetAttributeByRef(vCashRegister, "IsControlledByProgram") Then
			vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(True, vCashRegister);
			vQuestion = NStr("ru='Пожалуйста введите пароль ККМ...'; 
			                 |de='Input cash register password please...';
			                 |en='Input cash register password please...'");
			If IsBlankString(vPasswordKKM) Then
				vNotifyDescr = New NotifyDescription("AfterInputCashRegisterPassword", ThisForm, New Structure("Driver, rMessage, pObject", vDriver, vMessage, vCashRegister));
				OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisForm, , , , vNotifyDescr);
			Else
				If Not vDriver.pmPrintXReport(vMessage, vCashRegister, vPasswordKKM) Then
					ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
				EndIf;	
			EndIf;
		Else
			ShowMessageBox(, NStr("en = 'This device is not supported by the driver!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"), , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;	
EndProcedure // CashRegisterPrintDeviceXReportAfterCashRegisterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterPrintDeviceCurrentStateOfCalculationsReportAfterCashRegisterUserChoice(pUserChoiceItem, pExtraParameters) Export
	vMessage = "";
	If pUserChoiceItem <> Undefined Then
		vCashRegister = pUserChoiceItem.Value;
		vDriver = tcOnClient.cmGetModulTO(vCashRegister);
		If Not vDriver = Undefined And tcOnServer.cmGetAttributeByRef(vCashRegister, "IsControlledByProgram") Then
			vPasswordKKM = tcOnServer.cmGetUserPasswordKKM(True, vCashRegister);
			vQuestion = NStr("ru='Пожалуйста введите пароль ККМ...'; 
			                 |de='Input cash register password please...';
			                 |en='Input cash register password please...'");
			If IsBlankString(vPasswordKKM) Then
				vNotifyDescr = New NotifyDescription("AfterInputCashRegisterPasswordStateOfCalculationsReport", ThisForm, New Structure("Driver,rMessage,pObject", vDriver, vMessage, vCashRegister));
				OpenForm("CommonForm.tcInputCashRegisterPassword", New Structure("LabelDescription", vQuestion), ThisForm, , , , vNotifyDescr);
			Else
				If Not vDriver.pmPrintCurrentStateOfCalculationsReport(vMessage, vCashRegister, vPasswordKKM) Then
					ShowMessageBox(, vMessage, , NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
				EndIf;
			EndIf;
		Else
			ShowMessageBox(, Nstr("en = 'This device is not supported by the driver!'; ru = 'Работа с драйвером этого устройства не поддерживается'; de = 'Die Arbeit mit diesem Gerät nicht unterstützt wird!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		EndIf;	
	EndIf;	
EndProcedure // CashRegisterPrintDeviceCurrentStateOfCalculationsReportAfterCashRegisterUserChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetCreditCardsProcessingSystemList(pCashRegisters)
	vList = New ValueList(); 
	vCurrentWorkstation = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vCurrentWorkstation) Then
		Return vList;	
	EndIf; 
	
	vQry = New Query; 
	vQry.Text = 
	"SELECT
	|	ConnectedDevices.DeviceSettings AS DeviceSettings
	|FROM
	|	InformationRegister.ConnectedDevices AS ConnectedDevices
	|WHERE
	|	ConnectedDevices.Workstation = &qCurrentWorkstation
	|	AND ConnectedDevices.DeviceType = &qCreditCardProcessingSystem
	|	AND ConnectedDevices.IsActive
	|	AND (ConnectedDevices.DeviceSettings.Company = VALUE(Catalog.Companies.EmptyRef)
	|			OR ConnectedDevices.DeviceSettings.Company = &qCompany)";
	vQry.SetParameter("qCurrentWorkStation", SessionParameters.CurrentWorkstation);
	vQry.SetParameter("qCreditCardProcessingSystem", Enums.DeviceTypes.CreditCardsProcessingSystemParameters);
	vQry.SetParameter("qCompany", pCashRegisters.Owner);
	vList.LoadValues(vQry.Execute().Unload().UnloadColumn(0));
	
	Return vList;
EndFunction // GetCreditCardsProcessingSystemList

// -----------------------------------------------------------------------------
&AtServer
Function GetCashRegisterList()
	vList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vList = cmGetListOfAllCashRegisters();
	Else
		vList = cmGetListOfCashRegistersAllowed(, SessionParameters.CurrentWorkstation);
	EndIf;
	Return vList;
EndFunction // GetCashRegister

// -----------------------------------------------------------------------------
&AtClient
Function AfterInputCashRegisterPassword(pValue, pAdditionalParameters) Export
	vModule =  pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not vModule.pmPrintXReport(vMessage, pAdditionalParameters.pObject, pValue) Then
		ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
EndFunction // AfterInputCashRegisterPassword()

// -----------------------------------------------------------------------------
&AtClient
Function AfterInputCashRegisterPasswordHourXReport(pValue, pAdditionalParameters) Export
	vModule =  pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not vModule.pmPrintHourXReport(vMessage, pAdditionalParameters.pObject, pValue) Then
		ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
EndFunction // AfterInputCashRegisterPasswordHourXReport

// -----------------------------------------------------------------------------
&AtClient
Function AfterInputCashRegisterPasswordStateOfCalculationsReport(pValue, pAdditionalParameters) Export
	vModule =  pAdditionalParameters.Driver;
	vMessage = pAdditionalParameters.rMessage;
	If Not vModule.pmPrintCurrentStateOfCalculationsReport(vMessage, pAdditionalParameters.pObject, pValue) Then
		ShowMessageBox(,vMessage,,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;	
EndFunction // AfterInputCashRegisterPasswordStateOfCalculationsReport

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterListAfterUserChoice(pUserChoiceItem, pExtraParameters) Export
	vMessage = "";
	
	If pUserChoiceItem <> Undefined Then
		vCashRegister = pUserChoiceItem.Value;
	Else 
		vMessage = NStr("en='No cash register is selected!';ru='Не выбрана ККМ!';de='Keine Registrierkasse ist gewählt!'");
		ShowMessageBox(, vMessage);
		Return;
	EndIf;	
	
	vList = GetCreditCardsProcessingSystemList(vCashRegister);
	If vList.Count() > 1 Then
		vList.ShowChooseItem(New NotifyDescription("CreditCardsProcessingSystemAfterUserChoice", ThisObject, New Structure("CashRegister", vCashRegister)), NStr("en='Choose a payment terminal!';ru='Выберите платежный терминал!';de='Wählen Sie ein Zahlungsterminal!'"));	
	ElsIf vList.Count() > 0 Then
		CreditCardsProcessingSystemAfterUserChoice(vList.Get(0), New Structure("CashRegister", vCashRegister));
	Else
		ShowMessageBox(, NStr("en = 'You have not connected payment terminal!'; ru = 'Нет подключенного платежного термнала!'; de = 'Sie haben nicht angeschlossen Zahlungsterminal!'"));	
	EndIf;	
EndProcedure // CashRegisterListAfterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardsProcessingSystemAfterUserChoice(pUserChoiceItem, pExtraParameters) Export 
	If pUserChoiceItem = Undefined Then 
		vMessage = NStr("en='Payment terminal not selected!';ru='Не выбран платежный термнал!';de='Zahlungsterminal nicht ausgewählt!'");
		ShowMessageBox(, vMessage);
		Return;
	EndIf;
	
	vDriver = tcOnClient.cmGetModulTO(pUserChoiceItem.Value);
	If Not vDriver = Undefined Then
		If vDriver = tcCreditCardsProcessingSystemDriverUCS Then
			// Ask for operation type
			vUserChoice = Undefined;
			vUserChoices = New ValueList();
			vUserChoices.Add(2, NStr("en='Print short report'; ru='Печать краткого отчета'; de='Drucken Kurzbericht'"));
			vUserChoices.Add(3, NStr("en='Print detailed report'; ru='Печать детального отчета'; de='Drucken ausführlichen Bericht'"));
			vUserChoices.Add(1, NStr("en='Totals check (settlement)'; ru='Сверка итогов'; de='Überleitung der Ergebnisse'"));
			vUserChoices.ShowChooseItem(New NotifyDescription("UCSOperationTypeChoiceCompleted", ThisForm, New Structure("CashRegister, PaymentTerminal", pExtraParameters.CashRegister, GetCreditCardsProcessingSystemParameters(pUserChoiceItem.Value))), NStr("en='Operation type'; ru='Тип операции'; de='Betriebstyp'"));
		Else
			If Not vDriver.pmOpenServiceFunctionsMenu(vMessage, pExtraParameters.CashRegister, GetCreditCardsProcessingSystemParameters(pUserChoiceItem.Value)) Then
				ShowMessageBox(, vMessage);
			EndIf;
		EndIf;	
	Else
		ShowMessageBox(, Nstr("en = 'Working with this terminal driver is not supported'; ru = 'Работа с этим драйвером терминала не поддерживается'; de = 'Arbeiten mit diesem Terminal-Treiber wird nicht unterstützt'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
EndProcedure // CreditCardsProcessingSystemAfterUserChoice

// -----------------------------------------------------------------------------
&AtServer
Function GetCreditCardsProcessingSystemParameters(pPaymentTerminal)
	vArrPaymentTerminal = tcOnServer.cmGetAtributeAsArray(pPaymentTerminal);
	vArrPaymentTerminal.ConnectionParameters = vArrPaymentTerminal.ConnectionParameters.Get();
	Return vArrPaymentTerminal;
EndFunction	// GetCreditCardsProcessingSystemParameters

// -----------------------------------------------------------------------------
&AtClient
Procedure UCSOperationTypeChoiceCompleted(pOperationTypeItem, pExtraParameters) Export
	vMessage = "";
	If pOperationTypeItem <> Undefined Then
		If Not tcCreditCardsProcessingSystemDriverUCS.pmOpenServiceFunctionsMenu(vMessage, pExtraParameters.CashRegister, pExtraParameters.PaymentTerminal, pOperationTypeItem.Value) Then
			ShowMessageBox(, vMessage);
		EndIf;
	EndIf;
EndProcedure // UCSOperationTypeChoiceCompleted

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCashRegisterOnChangeAtServer()
	vFilter = List.Filter;
	vField = New DataCompositionField("CashRegister");
	// Find field
	vCancel = False;
	For Each vFilterItem In vFilter.Items Do
		If vFilterItem.LeftValue = vField  Then
			// Delete old
			vFilter.Items.Delete(vFilterItem);
			Break;
		EndIf;	
	EndDo;
	// Add a new item
	vFilterItem = vFilter.Items.Add(Type("DataCompositionFilterItem"));
	vFilterItem.LeftValue = vField;
	vFilterItem.Use = True;
	If ValueIsFilled(SelCashRegister) Then
		vFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		vFilterItem.RightValue = SelCashRegister;
	Else
		vFilterItem.ComparisonType = DataCompositionComparisonType.InList;
		vFilterItem.RightValue = Items.SelCashRegister.ChoiceList;
	EndIf;
EndProcedure // SelCashRegisterOnChangeAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure SelCompanyOnChangeAtServer()
	vCashRegistersList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vCashRegistersList = cmGetListOfAllCashRegisters(SelCompany);
	Else
		vCashRegistersList = cmGetListOfCashRegistersAllowed(SelCompany, SessionParameters.CurrentWorkstation);
	EndIf;
	Items.SelCashRegister.ChoiceList.LoadValues(vCashRegistersList.UnloadValues());
	If Items.SelCashRegister.ChoiceList.FindByValue(SelCashRegister) = Undefined Then
		SelCashRegister = Undefined;
		SelCashRegisterOnChangeAtServer();
	EndIf;
EndProcedure // SelCompanyOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCashRegisterUserChoice(pCashRegister, pExtraParams) Export
	If pCashRegister <> Undefined Then
		If tcOnServer.cmGetAttributeByRef(pCashRegister.Value, "IsControlledByProgram") Then
			vConfirmEn = "en='Set " + TrimAll(pCashRegister) + " cash register time to " + Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + "?'; ";
			vConfirmDe = "de='Set " + TrimAll(pCashRegister) + " cash register time to " + Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + "?'; ";
			vConfirmRu = "ru='Установить время ККМ " + TrimAll(pCashRegister) + " на " + Format(tcOnServer.cmGetServerCurrentSessionDate(), "DF='dd.MM.yyyy HH:mm'") + "?'";
			ShowQueryBox(New NotifyDescription("AfterShowQuery", ThisForm, pCashRegister.Value), NStr(vConfirmEn + vConfirmDe + vConfirmRu), QuestionDialogMode.YesNo, , DialogReturnCode.No, NStr("en='Confirm time change!';ru='Подтвердите установку времени в ККМ!';de='Bestätigen Sie die Zeiteinstellung in der Registrierkasse!'"));
		Else
			ShowMessageBox(, NStr("ru='Операция установки времени возможна только для ККМ в режиме фискального регистратора!';
			                  |de='Die Zeiteinstellung ist nur für die Registrierkasse im Fiskaldrucker-Modus möglich!'; 
			                  |en='Set device time operation is supported for automatic cash registers connected to the program only!'"));
		EndIf;
	EndIf;
EndProcedure // AfterCashRegisterUserChoice

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowQuery(pResult, pExtraParams) Export
	If pResult = DialogReturnCode.Yes Then
		vMessage = "";
		If Not SetDeviceTime(pExtraParams, vMessage) Then
			ShowMessageBox(, vMessage);
		Else
			ShowMessageBox(, NStr("en='Time was set successfully!';ru='Установка времени выполнена!';de='Zeiteinstellung ausgeführt!'"));
		EndIf;	
	EndIf;
EndProcedure // AfterShowQuery

// -----------------------------------------------------------------------------
&AtClient
Function SetDeviceTime(pCashRegister, rMessage) Export
	vDriver = tcOnClient.cmGetModulTO(pCashRegister);
	Return vDriver.pmSetDeviceTime(rMessage, pCashRegister);
EndFunction // SetDeviceTime

// -----------------------------------------------------------------------------
&AtServer
Function GetCashRegister()
	vList = New ValueList();
	If cmCheckUserPermissions("HavePermissionToViewAllCashRegisters") Then
		vList = cmGetListOfAllCashRegisters();
	Else
		vList = cmGetListOfCashRegistersAllowed(, SessionParameters.CurrentWorkstation);
	EndIf;
	Return vList;
EndFunction // GetCashRegister

#EndRegion
