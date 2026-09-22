
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj, "Object");

	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		ReadOnly = True;
		Items.ReportsList.ReadOnly = True;
		Items.Hotel.ReadOnly = True;
	Else
		FillScheduledJobStatus();
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
		
	// Run data processor if neccessary
	GenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen") And Parameters.GenerateOnOpen <> Undefined Then
		GenerateOnOpen = Parameters.GenerateOnOpen;
	EndIf;    
	
	Items.GroupMail.Visible = Object.SendEMail;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If GenerateOnOpen Then
		// Do processing
		rDoPrint = Undefined;
		Run(rDoPrint);
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
			pCancel = True;
		EndIf;
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportsListFileSaveCatalogStartChoice(Item, ChoiceData, StandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("FileSaveCatalog", Items.ReportsList.CurrentData);
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReportsListOnStartEdit(pItem, pNewRow, pClone)
	vCurRow = Items.ReportsList.CurrentData;
	If Not vCurRow = Undefined Then
		If pNewRow And Not pClone Then
			vCurRow.IsActive = True;
			vCurRow.PrintDirection = PredefinedValue("Enum.PrintDirections.Screen");
			vCurRow.PageOrientation = PredefinedValue("Enum.PageOrientations.Portrait");
			vCurRow.FitToPage = False;
			vCurRow.PrintScale = 100;
			vCurRow.Copies = 1;
			vCurRow.Collate = False;
			vCurRow.CopiesPerPage = PredefinedValue("Enum.CopiesPerPage.One");
			vCurRow.BlackAndWhite = False;
			vCurRow.TopMargin = 10;
			vCurRow.BottomMargin = 10;
			vCurRow.LeftMargin = 10;
			vCurRow.RightMargin = 10;
			vCurRow.HeaderSize = 10;
			vCurRow.FooterSize = 10;
		EndIf;
	EndIf;
EndProcedure

// ------------------------------------------------------------------------------
&AtClient
Procedure SendEMailOnChange(pItem)
	If Object.SendEMail = True Then
		Items.GroupMail.Visible = True;   
	Else 
		Items.GroupMail.Visible = False;  
	EndIf;
EndProcedure // SendEMailOnChange

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(Command)
	If ValueIsFilled(Object.DataProcessor) Then
		Save_AtServer();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure BackgroundJob(Command)
	
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
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ActionsExecute(Command)
	// Do processing
	rDoPrint = Undefined;
	Run(rDoPrint);
	If rDoPrint <> Undefined Then
		rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
	EndIf;
	
	// Processing completed
	ShowMessageBox(, NStr("en='Processing completed!';ru='Выполнение процедуры закончено!';de='Die Prozedur ist abgeschlossen!'"));
EndProcedure

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterUpdateBackgroundJob(Result, AdditionalParameters) Export
	
	FillScheduledJobStatus();

EndProcedure

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
Procedure Run(rDoPrint = Undefined)
	vObj = FormAttributeToValue("Object");
	vObj.pmRunAndSendReports(True, rDoPrint);
EndProcedure // Run

#EndRegion
