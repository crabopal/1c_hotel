
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("FileTempStorage") And Not IsBlankString(Parameters.FileTempStorage) Then
		FileTempStorage = Parameters.FileTempStorage;
		FillDataHardwareDriver();
	EndIf;
	
	SetVisible();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If IsBlankString(FileTempStorage) And Not pCurrentObject.IsNew() Then
		Return;
	EndIf;
	
	Try
		If IsBlankString(FileTempStorage) Or Not IsTempStorageURL(FileTempStorage) Then
			Raise NStr("en = 'Error saving driver'; de = 'Fehler beim Speichern des Treibers'; ru = 'Ошибка сохранения драйвера'");
		EndIf;
		
		vFileBinaryData = GetFromTempStorage(FileTempStorage);
		If vFileBinaryData = Undefined Then
			Raise NStr("en = 'Error saving driver'; de = 'Fehler beim Speichern des Treibers'; ru = 'Ошибка сохранения драйвера'");
		EndIf;
	Except
		tcCommonFunctionOnClientServer.UserMessage(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		pCancel = True;
		Return;
	EndTry;
	
	pCurrentObject.Driver = New ValueStorage(vFileBinaryData);
EndProcedure // BeforeWriteAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure AfterWriteAtServer(pCurrentObject, pWriteParameters)
	FileTempStorage = "";
	SetVisible();
EndProcedure // AfterWriteAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ConnectedHardwareTypeOnChange(pItem)
	SetVisible();
EndProcedure // ConnectedHardwareTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Async Procedure InstallDriver(pCommand)
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	Await tcConnectionHardwareAtClient.InstallDriverAsync(Object.Ref);
EndProcedure // InstallDriver

// --------------------------------------------------------------------------------
&AtClient
Async Procedure UpdateDriver(pCommand)
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	FileTempStorage = Await tcConnectionHardwareAtClient.LoadHardwareDriver(UUID);
	If IsBlankString(FileTempStorage) Then
		Return;
	EndIf;
	
	FillDataHardwareDriver();
EndProcedure // UpdateDriver

// --------------------------------------------------------------------------------
&AtClient
Async Procedure SaveDriver(pCommand)
	If Modified And Not Write() Then
		Return;
	EndIf;
	
	vGetFilesDialogParameters = New GetFilesDialogParameters(NStr("en = 'File driver'; de = 'Filel Draivera'; ru = 'Файл драйвера'"));
	Await GetFileFromServerAsync(tcConnectedHardwareOnClientServer.GetHardwareDriverURL(Object.Ref), tcOnServer.GetValidFileName(Object.Description) + ".zip", vGetFilesDialogParameters);
EndProcedure // SaveDriver

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillDataHardwareDriver()
	vMessage = "";
	vDataHardwareDriver = tcConnectedHardwareOnClientServer.GetDataHardwareDriverFromFile(FileTempStorage, vMessage);
	If vDataHardwareDriver = Undefined Then
		tcCommonFunctionOnClientServer.UserMessage(vMessage);
		Return;
	EndIf;
	
	If IsBlankString(Object.Description) Then
		Object.Description = vDataHardwareDriver["Description"];
	EndIf;
	
	Object.ConnectedHardwareType = vDataHardwareDriver["ConnectedHardwareType"];
	Object.ObjectID = vDataHardwareDriver["ObjectID"];
	Object.DriverVersion = vDataHardwareDriver["DriverVersion"];
	Modified = True;
EndProcedure // FillDataHardwareDriver

// --------------------------------------------------------------------------------
&AtServer
Procedure SetVisible()
	vIsNew = Not ValueIsFilled(Object.Ref);
	vShowHoldСonnection = Object.ConnectedHardwareType <> Enums.ConnectedHardwareTypes.BarcodeScanner And Object.ConnectedHardwareType <> Enums.ConnectedHardwareTypes.CardReader;
	
	Items.FormInstallDriver.Visible = Not vIsNew;
	Items.FormGroupFile.Visible = Not vIsNew;
	Items.HoldСonnection.Visible = vShowHoldСonnection;
EndProcedure // SetVisible

#EndRegion