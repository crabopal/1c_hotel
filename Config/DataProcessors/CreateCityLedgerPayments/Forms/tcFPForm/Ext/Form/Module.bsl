
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
	ValueToFormAttribute(vObj,"Object");
	
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
EndProcedure //  OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If GenerateOnOpen Then
		ActionsExecute(Commands.ActionsExecute);
		pCancel = True;
	EndIf;
EndProcedure //  OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure HotelClearing(pItem, pStandardProcessing)
	If Not tcOnServer.cmIsInRole("RightsToChooseHotel") Then
		pStandardProcessing = False;
	EndIf;
EndProcedure //  HotelClearing

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
EndProcedure //  BackgroundJob

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(pCommand)
	If Not ValueIsFilled(Object.AccountingDate) Then
		ShowMessageBox( , NStr("de='Das Datum muss angegeben werden!';en='You have to specify date!';ru='Необходимо указать дату!'"));
		Return;
	EndIf;	
	
	vInvoicesList = New ValueList();
	vPrintFormType = "";
	vMessageText = ActionsExecuteAtServer(vInvoicesList, vPrintFormType);
	If IsBlankString(vMessageText) Then
		If ValueIsFilled(Object.PaymentsReport) Then
			GenerateReport();
		EndIf;
	EndIf;
	If ValueIsFilled(Object.InvoicePrintForm) And vInvoicesList.Count() > 0 Then
		vPrintForm = tcOnServer.cmGetAtributeAsArray(Object.InvoicePrintForm);
		vLanguage = tcOnServer.cmGetSessionParametersAttribute("CurrentLanguage");
		If ValueIsFilled(vPrintForm.Language) Then
			vLanguage = vPrintForm.Language;
		EndIf;
		// Load external print form
		If ValueIsFilled(vPrintForm.ExternalProcessing) Then 
			Try
				OpenExternalProcedureForm(vPrintForm.ExternalProcessing, vPrintForm.Ref, vInvoicesList, vLanguage);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en='Failed to load external print form!';ru='Не удалось загрузить внешнюю печатную форму!';de='Das externe Druckformular konnte nicht geladen werden!'"), MessageStatus.Attention);
			EndTry;
		ElsIf ValueIsFilled(vPrintForm.Report) Then
			Try
				OpenExternalReportForm(vPrintForm.Report, vPrintForm.Ref, vInvoicesList, vLanguage);
			Except
				tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to load external print form!'; de = 'Das externe Druckformular konnte nicht geladen werden!'; ru = 'Не удалось загрузить внешнюю печатную форму!'"), MessageStatus.Attention);
			EndTry;
		Else
			OpenForm("Document.Settlement.Form.tcInvoicePrintForm", New Structure("Invoices, Language, PrintForm, PrintFormType", vInvoicesList, vLanguage, vPrintForm.Ref, vPrintFormType), ThisObject, UUID);
		EndIf;
	EndIf;
	
	// Processing completed
	ShowMessageBox(, NStr("en = 'Processing completed!'; de = 'Die Prozedur ist abgeschlossen!'; ru = 'Выполнение процедуры закончено!'"), 5);
EndProcedure // ActionsExecute

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalProcedureForm(pExtProcRef, pPrintFormTypeRef, pInvoicesList, pLanguage)
	#If ThickClientOrdinaryApplication Then
		vExtProcData = pExtProcRef.ExternalProcessingStorage.Get();
		vExtProcPath = GetTempFileName(".efd");
		vExtProcData.Write(vExtProcPath);
		vExtProcObj = ExternalDataProcessors.Create(vExtProcPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm, Invoices, Language", Undefined, pPrintFormTypeRef, pInvoicesList, pLanguage);
		FillPropertyValues(vExtProcObj, vStruct);
		vFrm = vExtProcObj.GetForm();
		vFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtProcPath);
	#Else
		vURL = GetURL(pExtProcRef, "ExternalProcessingStorage");
		vName = ConnectExternalDataProcessor(vURL, "ExternalInvoicePrintingForm");
		vParams = New Structure("InputParameter, ObjectPrintingForm, Invoices, Language", Undefined, pPrintFormTypeRef, pInvoicesList, pLanguage);
	    vFrm = GetForm("ExternalDataProcessor." + vName + ".ObjectForm", vParams);
		vFrm.Open();
	#EndIf
EndProcedure // OpenExternalProcedureForm

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenExternalReportForm(pExtRepRef, pPrintFormTypeRef, pInvoicesList, pLanguage)
	#If ThickClientOrdinaryApplication Then
		vExtRepData = pExtRepRef.ExternalProcessingStorage.Get();
		vExtRepPath = GetTempFileName(".erf");
		vExtRepData.Write(vExtRepPath);
		vExtRepObj = ExternalReports.Create(vExtRepPath, False);
		vStruct = New Structure("InputParameter, ObjectPrintingForm, Invoices, Language", Undefined, pPrintFormTypeRef, pInvoicesList, pLanguage);
		FillPropertyValues(vExtRepObj, vStruct);
		// Fill reference to the report catalog item
		vExtRepObj.Report = pPrintFormTypeRef.Report;
		// Load report catalog item attributes
		vExtRepObj.pmLoadReportAttributes();
		// Open report's default form
		vExtRepFrm = vExtRepObj.GetForm();
		vExtRepFrm.GenerateOnFormOpen = True;
		vExtRepFrm.Open();
		BeginDeletingFiles(New NotifyDescription, vExtRepPath);
	#Else
		vReportRef = tcOnServer.cmGetAttributeByRef(pPrintFormTypeRef, "Report");
		vURL = GetURL(pExtRepRef, "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(pExtRepRef, "FileName"), ".erf", ""));
		vParams = New Structure("FillingValues, GenerateOnOpen, PrinterName", New Structure("ReportRef, Invoices, Language", vReportRef, pInvoicesList, pLanguage), True, TrimAll(Object.PrinterName));
		OpenForm("ExternalReport." + vName + ".Form", vParams, ThisObject, vReportRef);
	#EndIf
EndProcedure // OpenExternalReportForm

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
Function ActionsExecuteAtServer(rInvoicesList = Undefined, rPrintFormType = "")
	vDPObj = FormAttributeToValue("Object");
	vMessageText = vDPObj.pmDoProcess(True, rInvoicesList, rPrintFormType);
	ValueToFormAttribute(vDPObj, "Object");
	
	If Not IsBlankString(vMessageText) Then
		SetObjectAndFormAttributeConformity(vDPObj, "Object");
		
		// Show message
		vUM = New UserMessage();
		vUM.SetData(vDPObj);
		vUM.Field = "AccountingDate";
		vUM.Text = vMessageText;
		vUM.Message();
	EndIf;
	
	Return vMessageText;
EndFunction //  ActionsExecuteAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateReport()
	vManagedReportForm = Undefined;
	vReportObj = tcOnServer.cmGetAtributeAsArray(Object.PaymentsReport);
	If vReportObj.IsExternal Then
		vURL = GetURL(vReportObj.Report, "ExternalProcessingStorage"); 
		vName = ConnectExternalReport(vURL, StrReplace(tcOnServer.cmGetAttributeByRef(vReportObj.Report,"FileName"),".erf",""));
		vParams = New Structure("FillingValues, GenerateOnOpen, PrinterName", New Structure("ReportRef", Object.PaymentsReport), True, TrimAll(Object.PrinterName));
		OpenForm("ExternalReport." + vName + ".Form", vParams, ThisObject, Object.PaymentsReport);
	Else	
		If vReportObj.Report = Undefined Then
			Raise Nstr("en = 'You must fill the handler in the report settings'; de = 'Sie müssen den Handler in den Berichteinstellungen ausfüllen'; ru = 'Необходимо заполнить обработчик в настройках отчета'");
		Else
			OpenForm("Report." + vReportObj.Report + ".Form", New Structure("FillingValues, GenerateOnOpen, PrinterName", New Structure("ReportRef", Object.PaymentsReport), True, TrimAll(Object.PrinterName)), ThisObject, Object.PaymentsReport);
		EndIf; 
	EndIf;	
EndProcedure //  GenerateReport

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalReport(pPath, pName = "", pUseSafeMode = False)
	Return ExternalReports.Connect(pPath, pName, pUseSafeMode);
EndFunction //  ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtServer
Function ConnectExternalDataProcessor(pPath, pName = "", pUseSafeMode = False)
	Return ExternalDataProcessors.Connect(pPath, pName, pUseSafeMode);
EndFunction // ConnectExternalDataProcessor

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(pResult, pAdditionalParameters) Export
	FillScheduledJobStatus();
EndProcedure //  AfterUpdateBackgroundJob

#EndRegion
