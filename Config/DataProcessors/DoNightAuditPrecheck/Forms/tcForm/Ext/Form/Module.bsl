
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	vObj = FormAttributeToValue("Object");
	vObj.DataProcessor = Catalogs.DataProcessors.DoNightAuditPrecheck;	
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
	#If ThickClientOrdinaryApplication Then
		Items.FormAction.Visible = False;
	#EndIf
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.FormOpenSettings.Visible = False;
		Items.FormOpenSettings.Enabled = False;
	EndIf;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure Print(pCommand)
	Spreadsheet.Print();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	Spreadsheet.Print(PrintDialogUseMode.Use);
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = GetNewPDFFileName(Object.AccountingDate);
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, Spreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure SendByEMail(pCommand)
	vEmail = TrimAll(Object.EMail);
	If Not IsBlankString(vEmail) Then
		SendByEMailAtServer();
	Else
		ShowMessageBox(, NStr("en = 'E-Mail is not specified!'; de = 'Die E-Mail ist in den Bearbeitungseinstellungen nicht angegeben!'; ru = 'E-Mail не указан в настройках обработки!'"));
	EndIf;
EndProcedure // SendByEMail

// -----------------------------------------------------------------------------
&AtClient
Procedure OpenSettings(pCommand)
	If tcOnServer.cmIsInRole("Administrator") Then
		OpenForm("DataProcessor.DoNightAuditPrecheck.Form.tcSettingsForm", New Structure("DataProcessor", Object.DataProcessor), ThisObject, UUID,,, New NotifyDescription("AfterCloseSettings", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'The setting is available only to the administrator!'; de = 'Die Einstellung steht nur dem Administrator zur Verfügung!'; ru = 'Настройка доступна только администратору!'"));
	EndIf;	
EndProcedure // OpenSettings

// -----------------------------------------------------------------------------
&AtClient
Procedure RunChecks(pCommand)
	If Not ValueIsFilled(Object.Hotel) Then
		ShowMessageBox(, NStr( "en = 'Field ""Hotel"" is not filled.'; ru = 'Поле ""Отель"" не заполнено.'"));
		Return;
	EndIf;
	RunChecksAtServer();
EndProcedure // RunChecks

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure SendByEMailAtServer()
	vFileName = GetNewPDFFileName(Object.AccountingDate);

	vSubject = NStr("en='Night audit preparation checks at ';ru='Подготовка к ночному аудиту от ';de='Vorbereitung auf das Nacht-Audit '") + Format(Object.AccountingDate, "DF=dd.MM.yyyy");
	vFullFileName = cmGetFullFileName(vFileName, TempFilesDir());
	vFileType = SpreadsheetDocumentFileType.PDF;
	Spreadsheet.Write(vFullFileName, vFileType);
	vFilesMap = New Map;
	vFilesMap.Insert(vFileName, vFullFileName);
	JobsScheduled.cmSendFilesByEMail(vSubject, vSubject, TrimAll(Object.EMail), vFilesMap, , True);		
	DeleteFiles(vFullFileName);
EndProcedure

// -----------------------------------------------------------------------------
&AtServerNoContext
Function GetNewPDFFileName(pDate)
	vFileName = StrTemplate(NStr("en = 'Night_audit_preparation_checks_%1.pdf'; de = 'Vorbereitung_auf_das_Nachtaudit_%1.pdf'; ru = 'Подготовка_к_ночному_аудиту_%1.pdf'"), Format(pDate, "DF=yyyyMMdd"));
	Return vFileName;
EndFunction // GetNewPDFFileName

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterCloseSettings(pValue, pExtraParams) Export 
	AfterCloseSettingsAtServer();	
EndProcedure // AfterCloseSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure AfterCloseSettingsAtServer()
	vObj = FormAttributeToValue("Object");
	vObj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(vObj, "Object");
EndProcedure // AfterCloseSettingsAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RunChecksAtServer()
	Spreadsheet.Clear();
	vObj = FormAttributeToValue("Object");
	vObj.pmDoNightAuditPrecheck(False, Spreadsheet);
	ValueToFormAttribute(vObj, "Object");
EndProcedure // RunChecks

#EndRegion
