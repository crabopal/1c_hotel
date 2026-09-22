
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vCashRegister = Undefined;
	vCloseOfCashRegisterDay = Undefined;
	vSelObjectPrintForm = Undefined;
	
	If Parameters.Property("CashRegister", vCashRegister) Then
		FillParametersByCashRegister(vCashRegister);
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
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToPrintCashRegisterXReport") Then
		pCancel = True;
		ShowMessageBox(, NStr("en='You do not have rights to print program X-Report!'; ru='Нет прав на печать X-Отчета по ККМ в программе!'; de='Sie haben keine Rechte, X-Berichte nach Registrierkassen im Programm auszudrucken!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
	EndIf;
	
	vList = GetCashRegisterList();
	If ValueIsFilled(Report.CashRegister) Then
		vUserChoiceItem = vList.FindByValue(Report.CashRegister);
		If vUserChoiceItem = Undefined Then
			vUserChoiceItem = vList.Insert(0, Report.CashRegister);
		EndIf;
		OnOpenAfterCashRegisterUserChoice(vUserChoiceItem, New Structure());
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 1 Then
			vList.ShowChooseItem(New NotifyDescription("OnOpenAfterCashRegisterUserChoice", ThisForm, New Structure()), NStr("en='Select cash register please!';ru='Выберите ККМ!';de='Wählen Sie Registrierkasse!'"));
		Else
			If vList.Count() > 0 Then
				vUserChoiceItem = vList.Get(0);
				OnOpenAfterCashRegisterUserChoice(vUserChoiceItem, New Structure());
			Else 
				pCancel = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CashRegisterStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	vList = GetCashRegisterList();
	If vList.Count() > 1 Then
		ShowChooseFromList(New NotifyDescription("CashRegisterStartChoiceAfterUserChoice", ThisForm, New Structure()), vList, pItem);
	Else
		vUserChoiceItem = Undefined;
		If vList.Count() > 0 Then
			vUserChoiceItem = vList.Get(0);
		EndIf;
		CashRegisterStartChoiceAfterUserChoice(vUserChoiceItem, New Structure());
	EndIf;
	SetStatusReportNotGenerate();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure DateToOnChange(Item)
	SetStatusReportNotGenerate();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure XReportTypeOnChange(Item)
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
EndProcedure

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
	If Not ValueIsFilled(Report.CashRegister) Then
		ShowMessageBox(,NStr("ru = 'Для печати не выбрана ККМ!'; " + 
		                  "en = 'Cash register is not selected for printing!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	If Not ValueIsFilled(Report.XReportType) Then
		ShowMessageBox(,NStr("ru = 'Не выбран тип формы X-Отчета!'; " + 
		"en = 'X-Report type is not selected!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	If Not ValueIsFilled(Report.DateFrom) Then
		ShowMessageBox(,NStr("ru = 'Не заполнена дата начала смены!'; " + 
		                  "en = 'Cash register day start date is not selected!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
		Return False;
	EndIf;
	If Not ValueIsFilled(Report.DateTo) Then
		ShowMessageBox(,NStr("ru = 'Не заполнена дата окончания смены!'; " + 
		                  "en = 'Cash register day end date is not selected!'"),,NStr("en = 'ERROR'; ru = 'ОШИБКА'; de = 'ERROR'"));
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
	vReportObj.pmGenerateXReport(vSpreadsheet, vExtTemplate);
	
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
						cmDoSpreadsheetOutput(vSpreadsheet, vPrintSettings, vName, rDoPrint);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure // GenerateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpenAfterCashRegisterUserChoice(pUserChoiceItem, pExtraParams) Export
	If pUserChoiceItem <> Undefined Then
		FillParametersByCashRegister(pUserChoiceItem.Value);
		// Check attributes
		If CheckAttributes() Then
			rDoPrint = Undefined;
			GenerateAtServer(rDoPrint);
			If rDoPrint <> Undefined Then
				rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // OnOpenAfterCashRegisterUserChoice

// -----------------------------------------------------------------------------
&AtServer
Procedure FillParametersByCashRegister(pCashRegister)
	vObj = FormAttributeToValue("Report");
	vObj.DateTo = CurrentSessionDate();
	vObj.CashRegister = pCashRegister;
	vObj.Author = SessionParameters.CurrentUser;
	If ValueIsFilled(vObj.CashRegister) Then
		vObj.XReportType = pCashRegister.XReportType;
		vObj.Company = pCashRegister.Owner;
		vDateFrom = vObj.pmCalculateDateFrom(vObj.DateTo);
		If Not ValueIsFilled(vDateFrom) Then
			vObj.DateFrom = vObj.DateTo - 24*3600;
		Else
			vObj.DateFrom = vDateFrom;
		EndIf;
	EndIf;
	ValueToFormAttribute(vObj, "Report");
EndProcedure //  FillParametersByCashRegister()

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
Procedure CashRegisterStartChoiceAfterUserChoice(pUserChoiceItem, pExtraParams) Export
	If pUserChoiceItem <> Undefined Then
		FillParametersByCashRegister(pUserChoiceItem.Value);
	EndIf;
EndProcedure // CashRegisterStartChoiceAfterUserChoice

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

#EndRegion



