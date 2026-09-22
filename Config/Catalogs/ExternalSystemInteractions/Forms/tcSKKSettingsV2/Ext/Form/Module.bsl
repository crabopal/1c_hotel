
#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure LogFolderStartChoice(pItem, pChoiceData, pStandardProcessing)
	vFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	vFileDialog.Directory = TrimAll(Object.LogFolder);
	vFileDialog.Show(New NotifyDescription("LogFolderAfterChoice", ThisForm));
EndProcedure // LogFolderStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure InitializeSKKSettings(pCommand)
	InitializeSKKSettingsAtServer();
EndProcedure // InitializeHPGSettings

// --------------------------------------------------------------------------------
&AtClient
Procedure SyncSettings(pCommand)
	
	OpenForm("DataProcessor.SKKV2.Form.Form");
	
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtClient
Procedure LogFolderAfterChoice(pFilesArray, pExtraParams) Export
	If pFilesArray <> Undefined Then
		If pFilesArray.Count() = 1 Then
			Object.LogFolder = TrimAll(pFilesArray.Get(0));
		EndIf;
	EndIf;
EndProcedure // LogFolderAfterChoice

// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure InitializeSKKSettingsAtServer()
	SKKConnectV2.InitializeJSONSettings();
EndProcedure // InitializeHPGSettingsAtServer

#EndRegion
