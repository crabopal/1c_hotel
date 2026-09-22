
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)  
	vObj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		vObj.DataProcessor = vDataProcessor;
	EndIf;
	
	vObj.pmLoadDataProcessorAttributes();
	vObj.pmFillCurrenciesList();
	ValueToFormAttribute(vObj, "Object"); 
	
	vCurrList = vObj.Currencies.UnloadColumn("Currency"); 
	
	CurrencyRates.Parameters.SetParameterValue("qListCurr", vCurrList);
	CurrencyRates.Parameters.SetParameterValue("qHotel", Object.Hotel);
	CurrencyRates.Parameters.SetParameterValue("qRPer", Object.PeriodTo);
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ExecuteF(pCommand)
	ExecuteAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure Clear(pCommand)
	CurrencyRates.Filter.Items.Clear();
	Items.CurrencyRates.Refresh();
	CurrencyRates.Parameters.SetParameterValue("qListCurr", Undefined);
	CurrencyRates.Parameters.SetParameterValue("qHotel", Undefined);
	CurrencyRates.Parameters.SetParameterValue("qRPer", Undefined);
	ClearServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodClick(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = Object.PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = Object.PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));   
	ChoosePeriodClickAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure FillCurrenciesListAction(pCommand)
	If (Object.PeriodFrom > Object.PeriodTo) Then 
		vMessage = NStr("en = 'Incorrect dates settings!'; de = 'Falsche Datumseinstellungen!'; ru = 'Некорректно введены даты!'");
        tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	FillCurrenciesListActionAtServer();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure SaveAttributesSetting(pCommand)
	SaveAttributesSettingAtServer();
EndProcedure 

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillCurrenciesListActionAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadDataProcessorAttributes();
	vObj.pmFillCurrenciesList();
	ValueToFormAttribute(vObj, "Object");
	
	vCurrList = vObj.Currencies.UnloadColumn("Currency");
	CurrencyRates.Parameters.SetParameterValue("qListCurr", vCurrList);
	CurrencyRates.Parameters.SetParameterValue("qHotel", Object.Hotel);
	CurrencyRates.Parameters.SetParameterValue("qRPer", Object.PeriodTo);
EndProcedure 

// --------------------------------------------------------------------------------
&AtServer
Procedure ClearServer()
	CurrencyRates.Filter.Items.Clear();
	Items.CurrencyRates.Refresh();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ChoosePeriodClickAtServer()
	PeriodFrom = BegOfDay(Object.PeriodFrom);
	PeriodTo = EndOfDay(Object.PeriodTo);
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		Object.PeriodFrom = pPeriod.StartDate;
		Object.PeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure ExecuteAtServer()
	If Object.Currencies.Count() = 0 Then      
		vText = NStr("en = 'Fill currencies list!'; de = 'Währungsliste ausfüllen!'; ru = 'Заполните список валют!'");
		tcCommonFunctionOnClientServer.UserMessage(vText);
		Return;
	EndIf;	
	vObj = FormAttributeToValue("Object");
	// Load rates interactively
	vObj.pmLoadCurrencyRates(True);
	ValueToFormAttribute(vObj, "Object");
	// Refresh rates in the list 
	RefreshCurrencyRates();
	Items.CurrencyRates.Refresh();
	
EndProcedure

// --------------------------------------------------------------------------------   
&AtServer
Procedure RefreshCurrencyRates()
	ActualCurrencyRates = InformationRegisters.CurrencyRates.SliceLast( , New Structure("Hotel", Object.Hotel));
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure SaveAttributesSettingAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmSaveDataProcessorAttributes();
EndProcedure 

#EndRegion
