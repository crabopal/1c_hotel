
#Region FormEventHandlers

//-----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	// Load DP parameters
	Obj = FormAttributeToValue("Object");
	vDataProcessor = Undefined;
	If Parameters.Property("DataProcessor", vDataProcessor) Then
		Obj.DataProcessor = vDataProcessor;
	EndIf;
	Obj.pmLoadDataProcessorAttributes();
	ValueToFormAttribute(Obj,"Object");

	// User rights
	If Not tcOnServer.cmIsInRole("Administrator") Then
		Items.GroupParameters.Visible = False;
	EndIf;
	
	// Check protection system
	tcProtection.cmCheckForm(ThisObject);
	// Let's set the properties of the form
	tcOnServer.cmSetFormProperties(ThisObject);
	
	// Run data processor if neccessary
	vGenerateOnOpen = False;
	If Parameters.Property("GenerateOnOpen", vGenerateOnOpen) And vGenerateOnOpen <> Undefined And vGenerateOnOpen Then
    	Obj.pmRun();
   		pCancel = True;
	EndIf;
EndProcedure //OnCreateAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure ExportDirStartChoice(pItem, pChoiceData, pStandardProcessing)
	tcOnClientWorkWithFiles.cmChooseDirectoryOnClient("ExportDir", Object);
EndProcedure //ExportDirStartChoice

#EndRegion

#Region FormCommandsEventHandlers

//-----------------------------------------------------------------------------
&AtClient
Procedure SaveSettings(pCommand)
	If ValueIsFilled(Object.DataProcessor) Then
		Save_AtServer();
	EndIf;
EndProcedure //SaveSettings

//-----------------------------------------------------------------------------
&AtClient
Procedure Unload(pCommand)
	vMsg = "";
	vAddressStorage = "";

	UnloadAtServer(vMsg, vAddressStorage);
	
	If Not IsBlankString(vMsg) Then
		ShowMessageBox(, vMsg);
		Return;
	EndIf;	
	
	If Not IsBlankString(vAddressStorage) Then
		vPath = GetFullFileName(Object.ExportDir);
		vOp = New TransferableFileDescription(vPath, vAddressStorage);
		vArr = New Array;
		vArr.Add(vOp);
		BeginGettingFiles(New NotifyDescription("UnloadEnd", ThisObject), vArr, , False);
        Return;
	EndIf;	
	
	UnloadPart();
EndProcedure //Unload 

#EndRegion

#Region Private

//-----------------------------------------------------------------------------
&AtServer
Procedure Save_AtServer()
	If ValueIsFilled(Object.DataProcessor) Then
		// Save DP parameters
		vObj = FormAttributeToValue("Object");
		vObj.pmSaveDataProcessorAttributes();
	EndIf;
EndProcedure //Save_AtServer

//-----------------------------------------------------------------------------
&AtClient
Procedure UnloadEnd(pReceivedFiles, pAdditionalParameters) Export
	UnloadPart();
EndProcedure //UnloadEnd

//-----------------------------------------------------------------------------
&AtClient
Procedure UnloadPart()	
	ShowMessageBox( , NStr("en = 'Processing completed! Export files were created.'; 
						   |de = 'Verarbeitung abgeschlossen! Export-Datei erstellt wurde.'; 
						   |ru = 'Выполнение процедуры закончено! Файлы сформированы.'"));
EndProcedure //UnloadPart

//-----------------------------------------------------------------------------
&AtServer
Procedure UnloadAtServer(pMsg, pAddressStorage)
	vObj = FormAttributeToValue("Object");	
	vObj.pmRun( , , True, pAddressStorage);
EndProcedure //UnloadAtServer

//-----------------------------------------------------------------------------
&AtServer
Function GetFullFileName(Val pFileCatalog)
	vFileName = "";
	vFileName = TrimAll(Object.Hotel) + "_" + Format(CurrentSessionDate(), "DF=yyyyMMdd") + ".zip";
		
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
