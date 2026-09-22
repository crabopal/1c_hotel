
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	Items.SetDoNotExportToTheAccountingSystem.Enabled = Object.CreateSettlement;
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	Else
		FillScheduledJobStatus();
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);	
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		vObj.pmRun();
		pCancel = True;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion  

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	HotelClearingAtServer(pStandardProcessing);
EndProcedure // HotelClearing

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportDirectoryStartChoice(pItem, pChoiceData, pStandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient(pItem.Name, Object, False); 
EndProcedure //  ExportDirectoryStartChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure MappingsOnEditEndAtServer(pItem)
	vRow = pItem.CurrentRow;
	vName = pItem.Name;
	If vRow <> Undefined Then
		If vName = "ServiceMappings1"  Then
			If ValueIsFilled(vRow.Service) And Not IsBlankString(vRow.IIKOMenuItem) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "Services", TrimR(vRow.Service.Code), TrimAll(vRow.IIKOMenuItem));
				ValueToFormAttribute(vObj, "Object");
			EndIf;
		ElsIf vName = "HotelMappings"  Then
			If ValueIsFilled(vRow.Hotel) And Not IsBlankString(vRow.IIKOBusiness) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(PredefinedValue("Catalog.Hotels.EmptyRef"), TrimR(Object.ExternalSystemCode), "Hotels", TrimR(vRow.Hotel.Code), TrimAll(vRow.IIKOBusiness));
				ValueToFormAttribute(vObj, "Object");
			EndIf;
		ElsIf vName = "CompanyMappings"  Then
			If ValueIsFilled(vRow.Company) And Not IsBlankString(vRow.IIKOCompany) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "Companies", TrimR(vRow.Company.Code), TrimAll(vRow.IIKOCompany));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "CustomerMappings"  Then
			If ValueIsFilled(vRow.Customer) And Not IsBlankString(vRow.IIKOCustomerName) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "Customers", TrimR(vRow.Customer.Code), TrimAll(vRow.IIKOCustomerName));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "CashRegisterMappings"  Then
			If ValueIsFilled(vRow.CashRegister) And Not IsBlankString(vRow.IIKOCashRegisterSerialNumber) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "CashRegisters", TrimR(vRow.CashRegister.Code), TrimAll(vRow.IIKOCashRegisterSerialNumber));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "PaymentMethodMappings"  Then
			If ValueIsFilled(vRow.PaymentMethod) And Not IsBlankString(vRow.IIKOPaymentMethodName) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "PaymentMethods", TrimR(vRow.PaymentMethod.Code), TrimAll(vRow.IIKOPaymentMethodName));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "CreditCardTypeMappings"  Then
			If ValueIsFilled(vRow.CreditCardType) And Not IsBlankString(vRow.IIKOCreditCardTypeName) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "CreditCardTypes", TrimR(vRow.CreditCardType.Code), TrimAll(vRow.IIKOCreditCardTypeName));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "UnitMappings"  Then
			If ValueIsFilled(vRow.Unit) And Not IsBlankString(vRow.IIKOUnitName) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "Units", TrimR(vRow.Unit.Code), TrimAll(vRow.IIKOUnitName));
				ValueToFormAttribute(vObj, "Object");
			EndIf;			
		ElsIf vName = "VATRateMappings"  Then
			If ValueIsFilled(vRow.VATRate) And Not IsBlankString(vRow.IIKOVATRate) Then
				vObj = FormAttributeToValue("Object");
				vObj.pmSaveExternalSystemObjectMapping(Object.Hotel, TrimR(Object.ExternalSystemCode), "VATRates", TrimR(vRow.VATRate.Code), TrimAll(vRow.IIKOVATRate));
				ValueToFormAttribute(vObj, "Object");
			EndIf;	
		Endif
	EndIf;
EndProcedure // ServiceMappings1OnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure ServiceMappings1OnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // ServiceMappings1OnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure //  HotelMappingsOnEditEnd 

// -----------------------------------------------------------------------------
&AtClient
Procedure CompanyMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // CompanyMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure CustomerMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // CustomerMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // CashRegisterMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure PaymentMethodMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // PaymentMethodMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure CreditCardTypeMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // CreditCardTypeMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure UnitMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // UnitMappingsOnEditEnd

// -----------------------------------------------------------------------------
&AtClient
Procedure VATRateMappingsOnEditEnd(pItem, pNewRow, pCancelEdit)
	MappingsOnEditEndAtServer(pItem);
EndProcedure // VATRateMappingsOnEditEnd

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		SaveSettingsAtServer();
	EndIf;
EndProcedure //  SaveSettings 

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(pCommand)
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) Then
		
		// Open settings form
		OpenForm("DataProcessor.ScheduledJobsManagementConsole.Form.tc_BackgroundJobSettingsForm", 
				New Structure("DataProcessor", vDP), 
				ThisObject,
				UUID, , , 
				New NotifyDescription("AfterUpdateBackgroundJob", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure // BackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	ActionsExecuteAtServer();
	If Object.CheckMappings Then
		// Check mappings please
		ShowMessageBox( , NStr("en='Fill mappings please!';ru='Пожалуйста заполните таблицы соответствий объектов!';de='Füllen Sie Mappings bitte!'"));
	Else			
		// Processing completed
		ShowMessageBox( , NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
	EndIf;
EndProcedure // ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionCheckMappings(pCommand)
	ActionCheckMappingsAtServer();
	If Object.CheckMappings Then
		// Check mappings please
		ShowMessageBox( , NStr("en='Fill mappings please!';ru='Пожалуйста заполните таблицы соответствий объектов!';de='Füllen Sie Mappings bitte!'"));
	Else			
		// Processing completed
		ShowMessageBox( , NStr("en='Mappings are OK!';ru='Таблицы соответствий заполнены корректно!';de='Mappings sind in Ordnung!'"));
	EndIf;
EndProcedure // ActionCheckMappings

// -----------------------------------------------------------------------------
&AtClient
Procedure ButtonChoosePeriod(pCommand)	
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = Object.DateFrom;
	vChoosePeriodDialog.Period.EndDate = Object.DateTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));
EndProcedure // ButtonChoosePeriodAtServer

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SaveSettingsAtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
		ValueToFormAttribute(vObj, "Object");
	EndIf;
EndProcedure //  SaveSettingsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(pResult, pAdditionalParameters) Export
	FillScheduledJobStatus();
EndProcedure // AfterUpdateBackgroundJob

// -----------------------------------------------------------------------------
&AtServer
Procedure FillScheduledJobStatus()
	vDP = Object.DataProcessor;
	If ValueIsFilled(vDP) And Not IsBlankString(vDP.Key) Then
		ArrayScheduledJob = ScheduledJobs.GetScheduledJobs(New Structure("Key", vDP.Key));
		
		If ArrayScheduledJob.Count() > 0 Then
			vScheduledJob = ArrayScheduledJob[0];
			If vScheduledJob.Use Then
				Items.DecorationBackgroundJob.Picture = PictureLib.CheckMark;
				Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Active'; de = 'Aktiv'; ru = 'Активно'");
			Else
				Items.DecorationBackgroundJob.Picture = PictureLib.Unpaid;
				Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Turned off'; de = 'Deaktiviert'; ru = 'Выключено'");
			EndIf;	
		Else 
			Items.DecorationBackgroundJob.Picture = PictureLib.Remove;
			Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Not configured'; de = 'Nicht konfiguriert'; ru = 'Не настроено'");
		EndIf;
	Else
		Items.DecorationBackgroundJob.Picture = PictureLib.Remove;
		Items.DecorationBackgroundJob.ToolTip = NStr("en = 'Not configured'; de = 'Nicht konfiguriert'; ru = 'Не настроено'");
	EndIf;
EndProcedure //  FillScheduledJobStatus

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadOrders(True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure ActionCheckMappingsAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadOrders(True, True);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // ActionCheckMappingsAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		Object.DateFrom = pPeriod.StartDate;
		Object.DateTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodAfterChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure HotelClearingAtServer(pStandardProcessing)
	If Not IsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;	
EndProcedure // HotelClearingAtServer

#EndRegion
