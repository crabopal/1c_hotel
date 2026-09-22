
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vCashRegister = Undefined;
	vCloseOfCashRegisterDay = Undefined;
	vSelObjectPrintForm = Undefined;
	
	If Parameters.Property("CashRegister", vCashRegister) Then
		If ValueIsFilled(vCashRegister) Then
			Report.CashRegister = vCashRegister;
			FillParametersByCashRegister(vCashRegister);
		EndIf;
	EndIf;	
	
	If Parameters.Property("CloseOfCashRegisterDay", vCloseOfCashRegisterDay) Then 
		FillPropertyValues(Report,vCloseOfCashRegisterDay);
		Report.CloseOfCashRegisterDay = vCloseOfCashRegisterDay; 
		Report.DateTo =  vCloseOfCashRegisterDay.Date;
	EndIf;	
	
	If Parameters.Property("SelObjectPrintForm", vSelObjectPrintForm) Then 
		SelObjectPrintForm = vSelObjectPrintForm;
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Check attributes
	If CheckAttributes() Then
		rDoPrint = Undefined;
		GenerateAtServer(rDoPrint);
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ZReportTypeOnChange(Item)
	SetStatusReportNotGenerate();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Generate(pCommand)
	// Check attributes
	If CheckAttributes() Then
		rDoPrint = Undefined;
		GenerateAtServer(rDoPrint);
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
		EndIf;
		Items.CashReportSpreadsheet.StatePresentation.Visible = False;
	EndIf;
EndProcedure // Generate

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	CashReportSpreadsheet.Print(PrintDialogUseMode.Use);
	ThisForm.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	CashReportSpreadsheet.Print(PrintDialogUseMode.DontUse);
	ThisForm.Close();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(Report.CloseOfCashRegisterDay) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(Report.CloseOfCashRegisterDay, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(Report.CloseOfCashRegisterDay, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, CashReportSpreadsheet);
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Function CheckAttributes()
	If Not ValueIsFilled(Report.CloseOfCashRegisterDay) Then
		ShowMessageBox(,NStr("ru = 'Не указан документ закрытия кассовой смены!'; " + 
		"en = 'Close of cash register day document is not set!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	If Not tcOnServer.cmGetAttributeByRef(Report.CloseOfCashRegisterDay,"Posted") Then
		ShowMessageBox(,NStr("ru = 'Документ закрытия кассовой смены должен быть проведен!'; " + 
		"en = 'Close of cash register day document should be posted!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	If Not ValueIsFilled(Report.ZReportType) Then
		ShowMessageBox(,NStr("ru = 'Не выбран тип формы Z-Отчета!'; " + 
		"en = 'Z-Report type is not selected!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	Return True;
EndFunction // CheckAttributes

// -----------------------------------------------------------------------------
&AtServer
Procedure GenerateAtServer(rDoPrint = Undefined)
	// Get output spreadsheet
	vSpreadsheet = CashReportSpreadsheet;
	
	// Load external printing form template
	vExtTemplate = cmReadExternalSpreadsheetDocumentTemplate(SelObjectPrintForm);
	
	// Print
	vReportObj = FormAttributeToValue("Report");
	vReportObj.pmGenerateZReport(vSpreadsheet, vExtTemplate);
	
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
	// Get and fill workstation print form settings
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWorkstationPrintSettings = SessionParameters.CurrentWorkstation.WorkstationPrintSettings;
		If ValueIsFilled(vWorkstationPrintSettings) Then
			// Try to find records for the current object print form
			vFilter = New Structure("ObjectPrintingForm, IsActive", SelObjectPrintForm, True); 
			vPrintSettingsSet = vWorkstationPrintSettings.PrintFormsList.FindRows(vFilter);
			If vPrintSettingsSet.Count() > 0 Then
				For Each vPrintSettings In vPrintSettingsSet Do
					// Fill settings
					cmSetSpreadsheetSettings(vSpreadsheet, vPrintSettings);
					// Check printing direction
					If vPrintSettings.PrintDirection <> Enums.PrintDirections.Screen Then
						vName = cmGetPrintFormFileName(vPrintSettings, NStr("en='Cash register Z-Report';ru='Кассовый Z-Отчет';de='Z-Bericht der Kasse'")) + " " + TrimAll(Report.CashRegister) + " " + Format(Report.DateTo, "DF='yyyy-MM-dd HHmm'");
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, , rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SetStatusReportNotGenerate()
	Items.CashReportSpreadsheet.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	Items.CashReportSpreadsheet.StatePresentation.Text = НСтр("en = 'The report has not been formed. Click ""Generate"" to obtain a report.'; ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.'; de = 'Der Bericht wurde nicht gebildet. Klicken Sie auf ""Generieren"", um einen Bericht zu erhalten.'");
	Items.CashReportSpreadsheet.StatePresentation.Visible = True;
	ClearSpreadsheet();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure ClearSpreadsheet()
	CashReportSpreadsheet.Clear();
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure FillParametersByCashRegister(pCashRegister)
	vObj = FormAttributeToValue("Report");
	vObj.XReportType = pCashRegister.XReportType;
	vObj.Company = pCashRegister.Owner;
	ValueToFormAttribute(vObj, "Report");
EndProcedure //  FillParametersByCashRegister()

#EndRegion
