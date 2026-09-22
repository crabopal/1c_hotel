
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
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	Obj.pmRun();
   		pCancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ExportDirStartChoice(Item, ChoiceData, StandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ExportDir", Object );
EndProcedure

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
	vAddressStorage = "";

	UnloadAtServer(vMsg, vAddressStorage);
	
	If Not IsBlankString(vMsg) Then
		ShowMessageBox(,vMsg);
		Return;
	EndIf;	
	
	If Not IsBlankString(vAddressStorage) Then
		vPath = GetFullFileName(Object.PoliceExportFormat, Object.ExportDir);
		vOp = New TransferableFileDescription(vPath, vAddressStorage);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("UnloadEnd", ThisObject), vArr, , False);
        Return;
	EndIf;	
	
	UnloadPart();
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
Procedure UnloadEnd(ReceivedFiles, AdditionalParameters) Export
	
	UnloadPart();

EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure UnloadPart()
	
	ShowMessageBox( , NStr("en = 'Processing completed! Export files were created.'; ru = 'Выполнение процедуры закончено! Файлы сформированы.'; de = 'Verarbeitung abgeschlossen! Export-Datei erstellt wurde.'"));

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure UnloadAtServer(pMsg, pAddressStorage)
	vObj = FormAttributeToValue("Object");
	
	vErrors = vObj.pmRun( , , True, pAddressStorage);

	// Print errors if found
	If vErrors.Count() > 0 Then
		PrintErrors(vErrors);
		Items.GroupErrors.Show();
	Else
		// Processing completed
		Items.GroupErrors.Hide();
	EndIf;

EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure PrintErrors(pErrors)
	// Choose template
	vSpreadsheet = SpreadsheetDocumentErrors;
	vSpreadsheet.Clear();
	vTemplate = DataProcessors.ExportGuestsToPolice.GetTemplate("ErrorsList");
	For Each vErrRow In pErrors Do
		If vErrRow.Document = Undefined Then
			If NOT IsBlankString(vErrRow.SuccessText) Then
				// Result
				vResultText = vTemplate.GetArea("ResultText");
				vResultText.Parameters.mSuccessText = vErrRow.SuccessText;
				vSpreadsheet.Put(vResultText);
				Break;
			EndIf;
			Continue;
		EndIf;
	EndDo;
	
	
	// Print errors
	vCurDocument = Undefined;
	i = 0;
	For Each vErrRow In pErrors Do
		If vErrRow.Document = Undefined Then
			Continue;
		EndIf;
		If i = 0 Then
			// Header
			vHeader = vTemplate.GetArea("Header");
			vSpreadsheet.Put(vHeader);
		EndIf;
		i = i + 1;
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
	
	If i > 0 Then
		// Footer
		vFooter = vTemplate.GetArea("Footer");
		vSpreadsheet.Put(vFooter);
	EndIf;
	// Setup default attributes
	cmSetDefaultPrintFormSettings(vSpreadsheet, PageOrientation.Portrait, True, , True);
	// Check authorities
	cmSetSpreadsheetProtection(vSpreadsheet);
EndProcedure // PrintErrors

// -----------------------------------------------------------------------------
&AtServer
Function GetFullFileName(Val pExportFormat, Val pFileCatalog) Export
	vFileName = "";
	If pExportFormat = Enums.PoliceExportFormat.gencat Then
		vFileName = TrimAll(Object.PoliceHotelID)+ "." + Format(Object.FileSeqNumber, "ND=3; NLZ=; NG=");
	Else
		vFileName = TrimAll(Object.PoliceHotelID) + "_" + Format(CurrentSessionDate(), "DF=yyyyMMdd") + "_" + Format(Object.FileSeqNumber, "NG=") + ".csv";
	EndIf;
		
	pFileCatalog = TrimAll(pFileCatalog);
	If Right(pFileCatalog, 1) = "\" Then
		Return pFileCatalog + vFileName;
	ElsIf Right(pFileCatalog, 1) = "/" Then
		Return pFileCatalog + vFileName;
	Else
		Return pFileCatalog + "\" + vFileName; // Windows format by default
	EndIf;
EndFunction // cmGetFullFileName

#EndRegion
