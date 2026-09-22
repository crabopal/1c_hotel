
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	Form20171123 = False;
	Form20200914 = False;
	Form20250205 = False;
	Height = 297;
	Width = 210;
	cmSetSpreadsheetProtection(Items.DocumentSpreadsheet);
	If Parameters.Property("SelForeignerRegistryRecord") Then
		SelForeignerRegistryRecord = Parameters.SelForeignerRegistryRecord;
		SelObjectPrintForm = Parameters.ObjectPrintingForm;
		SelLanguage = Catalogs.Languages.EmptyRef();
		SelHotel = SelForeignerRegistryRecord.Hotel;
		If ValueIsFilled(SelForeignerRegistryRecord) And 
		   ValueIsFilled(SelForeignerRegistryRecord.ParentDoc) And 
		   ValueIsFilled(SelForeignerRegistryRecord.ParentDoc.Company) Then
			If  SelForeignerRegistryRecord.CheckInDate < '20210223' Then
				If Not IsBlankString(SelForeignerRegistryRecord.ParentDoc.Company.DocumentGivingRightToProvidePremises) Then 
					Form20200914 = True;
				Else
					Form20171123 = True;
				EndIf;  
			ElsIf SelForeignerRegistryRecord.CheckInDate >= '20250205' Then  
				Form20250205 = True;
			EndIf;
		EndIf;
		If Parameters.ObjectPrintingForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintNotificationForm Then
			Items.FormGroupPrintByPages.Visible = True;
		ElsIf Parameters.ObjectPrintingForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm Then
			Items.FormGroupPrintByPages.Visible = True;
		Else
			Items.FormGroupPrintByPages.Visible = False;
		EndIf;
	Else
		Items.FormGroupPrintByPages.Visible = False;
	EndIf;
	Title = cmNStr(TrimAll(Parameters.ObjectPrintingForm));
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	// Basic checks
	If Not ValueIsFilled(SelForeignerRegistryRecord) Then
		ShowMessageBox(,NStr("ru='Должна быть выбрана запись журнала регистрации иностранных граждан!';de='Ein Eintrag im Registrierbuch für ausländische Gäste muss gewählt sein!';en='Foreigner registry record should be selected!'"));
		Return;
	EndIf;
	// Get employee that will sign notification form
	FillEmployee();
	// Wait for employee selection
	AttachIdleHandler("WaitForEmployeeInput", 1, False);
EndProcedure // OnOpen

// -----------------------------------------------------------------------------
&AtClient
Procedure OnReopen()
	rDoPrint = Undefined;
	vError = Print();
	If vError <> "" Then
		ShowMessageBox(,vError);
		Close();
	Else
		If rDoPrint <> Undefined Then
			rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
			Close();
		EndIf;
	EndIf;
EndProcedure // OnReopen

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintButton(pCommand)
	SelSpreadsheet.Print();
	Close();
EndProcedure // Print

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePrinter(pCommand)
	SelSpreadsheet.Print(PrintDialogUseMode.Use);
	Close();
EndProcedure // ChoosePrinter

// -----------------------------------------------------------------------------
&AtClient
Procedure SaveAsPDF(pCommand)
	vFilePath = "";
	If ValueIsFilled(SelForeignerRegistryRecord) Then
		vFilePath = StrReplace(tcOnServer.cmGetMetadataMethodOrAttribiteByRef(SelForeignerRegistryRecord, "Presentation") + " " + StrReplace(TrimAll(tcOnServer.cmGetAttributeByRef(SelForeignerRegistryRecord, "Number")), "/", "-"), " ", "_");
	EndIf;
	vFileType = SpreadsheetDocumentFileType.PDF;
	tcOnClient.SaveSpreadsheetToFile(vFileType, vFilePath, SelSpreadsheet);
EndProcedure // SaveAsPDF

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintPage1Button(pCommand)
	If SelObjectPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm") Then
		vPrintForeignerDepartureNotificationApplication = False;
		If ValueIsFilled(SelForeignerRegistryRecord) Then
			vHotel = tcOnServer.cmGetAttributeByRef(SelForeignerRegistryRecord, "Hotel");
			vPrintForeignerDepartureNotificationApplication = tcOnServer.cmGetAttributeByRef(vHotel, "PrintForeignerDepartureNotificationApplication");
		EndIf;
		If vPrintForeignerDepartureNotificationApplication Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 44);
		Else
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 74);
		EndIf;
	Else
		If Form20171123 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 86);
		ElsIf Form20200914 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 85); 
		ElsIf Form20250205 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 89); 
		Else
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(1, , 72);
		EndIf;
	EndIf;
	SelSpreadsheet.Print(True);
	SelSpreadsheet.PrintArea = Undefined;
EndProcedure // PrintPage1Button

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintPage2Button(pCommand)
	If SelObjectPrintForm = PredefinedValue("Catalog.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm") Then
		vPrintForeignerDepartureNotificationApplication = False;
		If ValueIsFilled(SelForeignerRegistryRecord) Then
			vHotel = tcOnServer.cmGetAttributeByRef(SelForeignerRegistryRecord, "Hotel");
			vPrintForeignerDepartureNotificationApplication = tcOnServer.cmGetAttributeByRef(vHotel, "PrintForeignerDepartureNotificationApplication");
		EndIf;
		If vPrintForeignerDepartureNotificationApplication Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(45, , 88);
		Else
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(75, , 149);
		EndIf;
	Else
		If Form20171123 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(87, , 170);
		ElsIf Form20200914 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(86, , 166);  
		ElsIf Form20250205 Then
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(90, , 162); 
		Else
			SelSpreadsheet.PrintArea = SelSpreadsheet.Area(73, , 141);
		EndIf;
	EndIf;
	SelSpreadsheet.Print(True);
	SelSpreadsheet.PrintArea = Undefined;
EndProcedure // PrintPage2Button

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintPage3Button(pCommand)
	If SelObjectPrintForm <> PredefinedValue("Catalog.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm") Then
		If Not Form20171123 And Not Form20200914  Then
			If Form20250205 Then
				SelSpreadsheet.PrintArea = SelSpreadsheet.Area(163, , 240); 
			Else
				SelSpreadsheet.PrintArea = SelSpreadsheet.Area(142, , 213);
          	EndIf;
			SelSpreadsheet.Print(True);
			SelSpreadsheet.PrintArea = Undefined; 
		EndIf;
	EndIf;
EndProcedure // PrintPage3Button

// -----------------------------------------------------------------------------
&AtClient
Procedure PrintPage4Button(pCommand)
	If SelObjectPrintForm <> PredefinedValue("Catalog.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm") Then
		If Not Form20171123 And Not Form20200914 Then
			If Form20250205 Then
				SelSpreadsheet.PrintArea = SelSpreadsheet.Area(241, , 318); 
			Else
				SelSpreadsheet.PrintArea = SelSpreadsheet.Area(214, , 281);
          	EndIf;
			SelSpreadsheet.Print(True);
			SelSpreadsheet.PrintArea = Undefined;
		EndIf;
	EndIf;
EndProcedure // PrintPage4Button

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Function Print(rDoPrint = Undefined)
	// Basic checks
	If Not ValueIsFilled(SelForeignerRegistryRecord.Hotel) Then
		Return NStr("ru='У документа должна быть указана гостиница!';de='Bei dem Dokument muss das Hotel angegeben sein!';en='Hotel attribute should be filled!'");
	EndIf;
	vMessage = "";
	Documents.ForeignerRegistryRecord.Print(SelForeignerRegistryRecord, SelObjectPrintForm, SelEmployee, SelSpreadsheet, vMessage, rDoPrint);
	Return vMessage;
EndFunction//Print 

// -----------------------------------------------------------------------------
&AtClient
Procedure WaitForEmployeeInput() Export
	If ValueIsFilled(SelEmployee) And ValueIsFilled(SelForeignerRegistryRecord) Then
		DetachIdleHandler("WaitForEmployeeInput");
		// Print notification
		rDoPrint = Undefined;
		vError = Print(rDoPrint);
		If vError <> "" Then
			ShowMessageBox(,vError);
		Else
			If rDoPrint <> Undefined Then
				rDoPrint.Spreadsheet.Print(PrintDialogUseMode[rDoPrint.PrintDialogUseMode]);
				Close();
			EndIf;
		EndIf;
	EndIf;
EndProcedure // WaitForEmployeeInput

// -----------------------------------------------------------------------------
// Returns False if current user has canceled operation
// -----------------------------------------------------------------------------
&AtClient
Procedure FillEmployee()
	// Do nothing if employee is filled
	vEmpList = New ValueList;
	If FillEmployeeAtServer(vEmpList) Then
		Return;
	Else
		If vEmpList.Count() > 1 Then
			vEmpList.ShowChooseItem(New NotifyDescription("FillEmployeeAfterEmployeeChoice", ThisObject, New Structure()), NStr("ru='Выберите сотрудника, который будет подписывать форму уведомления.'; de='Wählen Sie den Mitarbeiter, der die Benachrichtigungsunterlagen unterschreiben wird.'; en='Choose employee to sign notification form'"));
		ElsIf vEmpList.Count() = 1 Then
			vEmployeeItem = vEmpList.Get(0);
			FillEmployeeAfterEmployeeChoice(vEmployeeItem, New Structure());
		Else
			ShowMessageBox(, NStr("ru='Не найдены пользователи с правами подписывать уведомления о регистрации иностранных граждан!'; de='Es wurden keine Nutzer mit Rechten gefunden, Benachrichtigungen über die Registrierung ausländischer Bürger zu unterzeichnen!'; en='No employees found with permission to sign foreigner registration notification forms!'"));
		EndIf;
	EndIf;
EndProcedure // FillEmployee

// -----------------------------------------------------------------------------
&AtClient
Procedure FillEmployeeAfterEmployeeChoice(pEmployeeItem, pExtraParams) Export
	If pEmployeeItem <> Undefined Then
		SelEmployee = pEmployeeItem.Value;
	EndIf;
EndProcedure // FillEmployeeAfterEmployeeChoice

// -----------------------------------------------------------------------------
&AtServer
Function FillEmployeeAtServer(pEmpList)
	If Not SelObjectPrintForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintNotificationForm And 
	   Not SelObjectPrintForm = Catalogs.ObjectPrintingForms.ForeignerRegistryRecordPrintDepartureNotificationForm Then
		SelEmployee = SessionParameters.CurrentUser;
		Return True;
	EndIf;	
	// Get list of employees with permission to sign foreigner registration notification form
	vEmps = cmGetEmployeesWithPermissionToSignNotificationForm(SelHotel);
	// If the current employee is in the permitted list then use it
	vCurEmpRow = vEmps.Find(SessionParameters.CurrentUser, "Employee");
	If Not vCurEmpRow = Undefined Then
		SelEmployee = SessionParameters.CurrentUser;
		Return True;
	Else
		// Choose one employee from the list
		pEmpList.LoadValues(vEmps.UnloadColumn("Employee"));
	EndIf;
	Return False;
EndFunction	//FillEmployeeAtServer

#EndRegion
