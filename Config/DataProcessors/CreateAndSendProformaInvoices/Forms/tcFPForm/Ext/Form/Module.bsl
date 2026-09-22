
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
	vObj.pmLoadDataProcessorAttributes(?(Parameters.Property("Parameters"), Parameters.Parameters, Undefined));
	ValueToFormAttribute(vObj, "Object");
	
	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	Else
		FillScheduledJobStatus();
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);	
	
	// Run data processor if neccessary
	GenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen") Then
		GenerateOnOpen = Parameters.GenerateOnOpen;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If GenerateOnOpen Then
		ActionsExecute(Commands.ActionsExecute);
		pCancel = True;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure // HotelClearing

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
	If Not ValueIsFilled(Object.PeriodFrom) Then
		ShowMessageBox( , NStr("de='Das Datum des Zeitraumbeginns für die Auswahl von gruppen muss angegeben werden!';en='You have to specify groups choice period from date!';ru='Необходимо указать дату начала периода отбора групп для создания счетов-требований!'"));
		Return;
	EndIf;	
	If Not ValueIsFilled(Object.PeriodTo) Then
		ShowMessageBox( , NStr("de='Das Datum des Zeitraumendes für die Auswahl von gruppen muss angegeben werden!';en='You have to specify groups choice period to date!';ru='Необходимо указать дату окончания периода отбора групп для создания счетов-требований!'"));
		Return;
	EndIf;
	
	vSpreadsheet = ActionsExecuteAtServer();
	If Not IsBlankString(Object.PrinterName) Then
		vSpreadsheet.PrinterName = TrimAll(Object.PrinterName);
	EndIf;
	vCaption = NStr("en='Proforma-invoices for the period from '; ru='Счета на оплату за период с '; de='Proforma-rechnungen für periode von '") + Format(Object.PeriodFrom, "DF=dd.MM.yyyy") + NStr("en=' to '; ru=' по '; de=' zu '") + Format(Object.PeriodTo, "DF=dd.MM.yyyy") + ?(ValueIsFilled(Object.Customer), ", " + TrimAll(Object.Customer), "") + ", " + TrimAll(Object.Hotel);
	vFileName = "Proforma-invoices-" + ?(ValueIsFilled(Object.Customer), StrReplace(TrimAll(Object.Customer), " ", "-") + "-", "") + Format(Object.PeriodFrom, "DF=yyyy-MM-dd") + ".pdf";
	vSpreadsheet.Show(vCaption, vFileName, True);
	
	// Processing completed
	ShowMessageBox( , NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"), 5);
EndProcedure //  ActionsExecute

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Show(New NotifyDescription("AfterChoosePeriod", ThisObject));
EndProcedure // ChoosePeriod

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
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Function ActionsExecuteAtServer()
	vObj = FormAttributeToValue("Object");
	vSpreadsheet = vObj.pmDoProcess(True);
	ValueToFormAttribute(vObj, "Object");
	Return vSpreadsheet;
EndFunction // ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterChoosePeriod(pPeriod, pAdditionalParameters) Export
	If Not pPeriod = Undefined Then
		Object.PeriodFrom = pPeriod.StartDate;
		Object.PeriodTo = pPeriod.EndDate;
	EndIf;
EndProcedure // ChoosePeriodEnd

#EndRegion    
