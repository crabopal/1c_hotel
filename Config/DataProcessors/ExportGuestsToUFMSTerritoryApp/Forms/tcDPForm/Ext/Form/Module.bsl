
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
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Selected accommodation
	ExportType = 0;
	Object.Accommodations.Clear();
	AccommodationsList.Clear();
	If Parameters.Property("Accommodation") And 
	   ValueIsFilled(Parameters.Accommodation) Then
		ExportType = 1;
		vAccRow = Object.Accommodations.Add();
		vAccRow.Accommodation = Parameters.Accommodation;
		AccommodationsList.Add(Parameters.Accommodation);
		Object.PeriodFrom = BegOfDay(Parameters.Accommodation.CheckInDate);
		Object.PeriodTo = CurrentSessionDate();
		If Not IsBlankString(Object.ExportDirForeigners) Then
			Object.ExportForeigners = True;
		EndIf;
		If Not IsBlankString(Object.ExportDirRussian) Then
			Object.ExportRussians = True;
		EndIf;
	ElsIf Parameters.Property("Accommodations") And 
	      TypeOf(Parameters.Accommodations) = Type("ValueList") And Parameters.Accommodations.Count() > 0 Then
		ExportType = 1;
		For Each vAccItem In Parameters.Accommodations Do
			If ValueIsFilled(vAccItem.Value) Then
				vAccRow = Object.Accommodations.Add();
				vAccRow.Accommodation = vAccItem.Value;
				AccommodationsList.Add(vAccItem.Value);
				Object.PeriodFrom = Min(Object.PeriodFrom, BegOfDay(vAccRow.Accommodation.CheckInDate));
			EndIf;
		EndDo;
		Object.PeriodTo = CurrentSessionDate();
		If Not IsBlankString(Object.ExportDirForeigners) Then
			Object.ExportForeigners = True;
		EndIf;
		If Not IsBlankString(Object.ExportDirRussian) Then
			Object.ExportRussians = True;
		EndIf;
	EndIf;
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Form appearance
	SettingsFormAppearance();
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
		GenerateOnOpen = True;
	EndIf;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	If GenerateOnOpen Then
		GenerateOnOpen = False;
		Unload(Commands.Unload);
	EndIf;
EndProcedure // OnOpen

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportDirForeignersStartChoice(Item, ChoiceData, StandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ExportDirForeigners", Object );
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportDirRussianStartChoice(Item, ChoiceData, StandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ExportDirRussian", Object );
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ReceiverOnChange(pItem)
	SettingsFormAppearance();
EndProcedure // ReceiverOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure PeriodToOnChange(pItem)
	If ValueIsFilled(Object.PeriodTo) And BegOfDay(Object.PeriodTo) = Object.PeriodTo Then
		Object.PeriodTo = EndOfDay(Object.PeriodTo);
	EndIf;
EndProcedure // PeriodToOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportTypeOnChange(pItem)
	ExportTypeOnChangeAtServer();
EndProcedure // ExportTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AccommodationsOnChange(pItem)
	Object.Accommodations.Clear();
	For Each vAccListItem In AccommodationsList Do
		If ValueIsFilled(vAccListItem.Value) Then
			vAccRow = Object.Accommodations.Add();
			vAccRow.Accommodation = vAccListItem.Value;
		EndIf;
	EndDo;
EndProcedure // AccommodationsOnChange

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
Procedure Unload(Command)
	vMsg = "";
	vAddressStorageForeigners = "";
	vAddressStorageRussian = "";

	UnloadAtServer(vMsg, vAddressStorageForeigners, vAddressStorageRussian);
	
	If Not IsBlankString(vMsg) Then
		ShowMessageBox(,vMsg);
	EndIf;	
	
	If Not IsBlankString(vAddressStorageForeigners) And vAddressStorageForeigners <> "<empty>" Then
		vForeignersPath = GetForeignersZIPFileName();
		vOp = New TransferableFileDescription(vForeignersPath, vAddressStorageForeigners);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("AfterForeignersFilesGet", ThisObject), vArr, , False);
	EndIf;	
	
	If Not IsBlankString(vAddressStorageRussian) And vAddressStorageRussian <> "<empty>" Then
		vRussiansPath = GetForm5ZIPFileName();
		vOp = New TransferableFileDescription(vRussiansPath, vAddressStorageRussian);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("AfterRussiansFilesGet", ThisObject), vArr, , False);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UnloadWithErrors(Command)
	vMsg = "";
	vAddressStorageForeigners = "";
	vAddressStorageRussian = "";

	UnloadAtServer(vMsg, vAddressStorageForeigners, vAddressStorageRussian, True);
	
	If Not IsBlankString(vMsg) Then
		ShowMessageBox(,vMsg);
	EndIf;	
	
	If Not IsBlankString(vAddressStorageForeigners) And vAddressStorageForeigners <> "<empty>" Then
		vForeignersPath = GetForeignersZIPFileName();
		vOp = New TransferableFileDescription(vForeignersPath, vAddressStorageForeigners);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("AfterForeignersFilesGet", ThisObject), vArr, , False);
	EndIf;	
	
	If Not IsBlankString(vAddressStorageRussian) And vAddressStorageRussian <> "<empty>" Then
		vRussiansPath = GetForm5ZIPFileName();
		vOp = New TransferableFileDescription(vRussiansPath, vAddressStorageRussian);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("AfterRussiansFilesGet", ThisObject), vArr, , False);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriod(pCommand)
	SelectPeriod(); 
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
&AtServer
Function GetForeignersZIPFileName()
	If Object.Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vPath = cmGetFullFileName("", TrimAll(Object.ExportDirForeigners)) + "\";
	Else
		vPath = cmGetFullFileName("OUT", TrimAll(Object.ExportDirForeigners));
	EndIf;
	vObj = FormAttributeToValue("Object");
	Return vPath + vObj.pmGetForeignersZIPFileName();
EndFunction // GetForeignersZIPFileName

// -----------------------------------------------------------------------------
&AtServer
Function GetForm5ZIPFileName()
	If Object.Receiver = Enums.GuestDataExportHeaderTypesRu.Elpost Then
		vPath = cmGetFullFileName("", TrimAll(Object.ExportDirRussian)) + "\";
	Else
		vPath = cmGetFullFileName("OUT", TrimAll(Object.ExportDirRussian));
	EndIf;
	vObj = FormAttributeToValue("Object");
	Return vPath + vObj.pmGetForm5ZIPFileName();
EndFunction // GetForm5ZIPFileName

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterForeignersFilesGet(pResult, pParams) Export
	
	ShowMessageBox( , NStr("en = 'Processing completed! Export file was created.'; ru = 'Выполнение процедуры выгрузки иностранцев закончено! Файл сформирован.'; de = 'Verarbeitung abgeschlossen! Export-Datei erstellt wurde.'"));
	
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterRussiansFilesGet(pResult, pParams) Export
	
	ShowMessageBox( , NStr("en = 'Processing completed! Export file was created.'; ru = 'Выполнение процедуры выгрузки россиян закончено! Файл сформирован.'; de = 'Verarbeitung abgeschlossen! Export-Datei erstellt wurde.'"));
	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UnloadAtServer(pMsg, pAddressStorageForeigners, pAddressStorageRussian, pIgnoreErrors = False)
	vObj = FormAttributeToValue("Object");
	
	vErrors = vObj.pmRun(, , True, pAddressStorageForeigners, pAddressStorageRussian, pIgnoreErrors);

	// Print errors if found
	If vErrors.Count() > 0 And Not pIgnoreErrors Then
		PrintErrors(vErrors);
		// Processing completed with errors
		pMsg = NStr("en = 'Errors found in the data! All guests were not exported to the files.'; ru = 'Найдены ошибки в выгружаемых данных! Гости в файлы не выгружены.'; de = 'Fehler in den Daten gefunden! Gäste wurden nicht in die Datei exportiert.'");
		Items.GroupErrors.Show();
	Else
		// Processing completed
		Items.GroupErrors.Hide();
	EndIf;
EndProcedure // UnloadAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintErrors(pErrors)
	// Choose template
	vSpreadsheet = SpreadsheetDocumentErrors;
	vSpreadsheet.Clear();
	vTemplate = DataProcessors.ExportGuestsToUFMSTerritoryApp.GetTemplate("ErrorsList");
	
	// Header
	vHeader = vTemplate.GetArea("Header");
	vSpreadsheet.Put(vHeader);

	// Print errors
	vCurDocument = Undefined;
	For Each vErrRow In pErrors Do
		// Fill row parameters
		mDocNumber = cmGetDocumentNumberPresentation(vErrRow.Document.Number);
		mDocDate = Format(vErrRow.Document.Date, "DF='dd.MM.yy'");
		dDocument = vErrRow.Document;
		mGuest = "";
		If ValueIsFilled(vErrRow.Document.Guest) Then
			vGuest = vErrRow.Document.Guest;
			mGuest = TrimAll(TrimAll(vGuest.LastName) + " " + TrimAll(vGuest.FirstName) + " " + TrimAll(vGuest.SecondName));
		EndIf;
		dGuest = vErrRow.Document.Guest;
		mError = TrimAll(vErrRow.ErrorText);
		// Output row
		If vErrRow.Document <> vCurDocument Then
			vCurDocument = vErrRow.Document;
			// Get area
			vDoc = vTemplate.GetArea("Doc");
			// Set row parameters
			vDoc.Parameters.mDocNumber = mDocNumber;
			vDoc.Parameters.mDocDate = mDocDate;
			vDoc.Parameters.dDocument = dDocument;
			vDoc.Parameters.mGuest = mGuest;
			vDoc.Parameters.dGuest = dGuest;
			vDoc.Parameters.mError= mError;
			vSpreadsheet.Put(vDoc);
		Else
			// Get area
			vRow = vTemplate.GetArea("Row");
			// Set row parameters
			vRow.Parameters.dDocument = dDocument;
			vRow.Parameters.dGuest = dGuest;
			vRow.Parameters.mError= mError;
			vSpreadsheet.Put(vRow);
		EndIf;
	EndDo;
	
	// Footer
	vFooter = vTemplate.GetArea("Footer");
	vSpreadsheet.Put(vFooter);

	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // PrintErrors

// -----------------------------------------------------------------------------
&AtServer
Procedure SettingsFormAppearance()
	Items.GroupHotel.Visible = True;
	Items.GroupCompany.Visible = True;
	Items.GroupEmployee.Visible = True;
	Items.GroupExtID.Visible = True;
	Items.GroupHotel2.Visible = True;
	Items.GroupHotelAdress.Visible = True;
	Items.GroupOfficialOrganID.Visible = True;
	Items.OfficialOrganID.Visible = True;
	Items.TaxAuthorityID.Visible = True;
	Items.Company.Visible = True;
	Items.NoticeFromID.Visible = True;
	Items.GroupEmployee2.Visible = True;
	If Object.Receiver = PredefinedValue("Enum.GuestDataExportHeaderTypesRu.Elpost") Then
		Items.GroupHotel.Visible = False;
		Items.GroupCompany.Visible = False;
		Items.GroupEmployee.Visible = False;
	ElsIf Object.Receiver = PredefinedValue("Enum.GuestDataExportHeaderTypesRu.KonturFMS") Then
		Items.GroupHotelAdress.Visible = False;
		Items.GroupHotel2.Visible = False;
		Items.OfficialOrganID.Visible = False;
		Items.TaxAuthorityID.Visible = False;
		Items.GroupCompany.Visible = False;
		Items.GroupEmployee2.Visible = False;
	ElsIf Object.Receiver = PredefinedValue("Enum.GuestDataExportHeaderTypesRu.Vega") Then
		Items.GroupExtID.Visible = False;
		Items.GroupHotelAdress.Visible = False;
		Items.GroupOfficialOrganID.Visible = False;
		Items.Company.Visible = False;
		Items.NoticeFromID.Visible = False;
		Items.GroupCompany.Visible = False;
		Items.GroupEmployee.Visible = False;
	EndIf;
	ExportTypeOnChangeAtServer();
EndProcedure // SettingsFormAppearance

// -----------------------------------------------------------------------------
&AtServer
Procedure ExportTypeOnChangeAtServer()
	If ExportType = 0 Then
		Items.Accommodations.Enabled = False;
		Object.Accommodations.Clear();
		AccommodationsList.Clear();
	Else
		Items.Accommodations.Enabled = True;
	EndIf;
EndProcedure // ExportTypeOnChangeAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure SelectPeriod()
	vChoosePeriodDialog = New StandardPeriodEditDialog();
	vChoosePeriodDialog.Period.StartDate = Object.PeriodFrom;
	vChoosePeriodDialog.Period.EndDate = Object.PeriodTo;
	vChoosePeriodDialog.Period.Variant = StandardPeriodVariant.Custom;
	vChoosePeriodDialog.Show(New NotifyDescription("ChoosePeriodAfterChoice", ThisObject));
EndProcedure // ChoosePeriod

// -----------------------------------------------------------------------------
&AtClient
Procedure ChoosePeriodAfterChoice(pPeriod, pExtraParams) Export
	If pPeriod <> Undefined Then
		Object.PeriodFrom = pPeriod.StartDate;
		Object.PeriodTo = EndOfDay(pPeriod.EndDate);    
	EndIf;
EndProcedure

#EndRegion
