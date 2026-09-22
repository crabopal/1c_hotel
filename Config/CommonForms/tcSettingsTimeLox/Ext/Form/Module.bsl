
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	If Parameters.Property("DoorLockSystemParameters") Then
		DoorLockSystemParameters = Parameters.DoorLockSystemParameters;	
	EndIf;
	Items.Port.ChoiceList.Clear();
	For i = 1 To 256 Do
		Items.Port.ChoiceList.Add("COM" + i);
	EndDo;
	Try
		vObjDoorLocksParameters = DoorLockSystemParameters.GetObject();
		vParams = vObjDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
		vParams.Property("EncoderNumber", EncoderNumber);
		vParams.Property("Port", Port);
		vParams.Property("ExchangeFolder", ExchangeFolder);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("BaudRate", BaudRate);
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
		vParams.Property("WriteTrack2", WriteTrack2);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("ConnectionType", ConnectionType);
		vParams.Property("DataBits", DataBits);
		vParams.Property("StopBits", StopBits);
		vParams.Property("Parity", Parity);
		ConnectionTypePresentation = ?(ConnectionType = Enums.ConnectionTypes.RS232, 0, 1);
	Except
		ResetSettings();
	EndTry;
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If ConnectionType = Enums.ConnectionTypes.RS232 Then
		pCheckedAttributes.Add("Port");
		pCheckedAttributes.Add("EncoderNumber");
	Else
		pCheckedAttributes.Add("ExchangeFolder");
		pCheckedAttributes.Add("EncoderNumber");
	EndIf;
EndProcedure // FillCheckProcessingAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTypePresentationOnChange(pItem)
	RefreshDisplay(True);
EndProcedure // ConnectionTypePresentationOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ExchangeFolderStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = False;
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileAttachingFileSystemExtensionResult", ThisForm));
EndProcedure // ExchangeFolderStartChoice

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSaveAndClose(pCommand)
	If CheckFilling() Then
		CommandSaveAtServer();
		Notify("Catalogs.DoorLockSystemParameters.Write");
		Close();
	EndIf;
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandClose(pCommand)
	Close();
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSave(pCommand)
	If CheckFilling() Then
		CommandSaveAtServer();
		Notify("Catalogs.DoorLockSystemParameters.Write");
	EndIf;
EndProcedure // CommandSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetSettings1(pCommand)
	ResetSettings();
EndProcedure // ResetSettings1

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure ResetSettings()
	ConnectionTypePresentation = 0;
	EncoderNumber = "";
	Port = "";
	ExchangeFolder = "";	
	AddMinutes = 0;
	BaudRate = 0;
	SubtractMinutes = 0;
	AllowDynamicAuthorizations = False;
	DoKeyCardsFromFoliosOnly = False;
	UseRoomLockCodes = False;
	WriteTrack2 = False;
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	ConnectionType = Enums.ConnectionTypes.RS232;
	DataBits = Enums.DataBits.Bits8;
	StopBits = Enums.StopBits.Bits1;
	Parity = Enums.ParityTypes.None;
	RefreshDisplay(True);
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("EncoderNumber", EncoderNumber);
	vParams.Insert("Port", Port);
	vParams.Insert("ExchangeFolder", ExchangeFolder);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("BaudRate", BaudRate);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("WriteTrack2", WriteTrack2);
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("ConnectionType", ConnectionType);
	vParams.Insert("DataBits", DataBits);
	vParams.Insert("StopBits", StopBits);
	vParams.Insert("Parity", Parity);
	vParams.Insert("DoGuestNamesTransliteration", DoGuestNamesTransliteration);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.Port = Port;
	objDoorLocksParameters.ExchangeFolder = ExchangeFolder;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.BaudRate = BaudRate;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.AllowDynamicAuthorizations = AllowDynamicAuthorizations;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes;
	objDoorLocksParameters.WriteTrack2 = WriteTrack2;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.ConnectionType = ConnectionType;
	objDoorLocksParameters.DataBits = DataBits;
	objDoorLocksParameters.StopBits = StopBits;
	objDoorLocksParameters.Parity = Parity;
	objDoorLocksParameters.DoGuestNamesTransliteration = DoGuestNamesTransliteration;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay(pClear = False)
	If ConnectionTypePresentation = 0 Then
		ConnectionType = Enums.ConnectionTypes.RS232;
		Items.ExchangeFolder.Visible = False;
		Items.BaudRate.Visible = True;
		Items.DataBits.Visible = True;
		Items.Parity.Visible = True;
		Items.StopBits.Visible = True;
		Items.Port.Visible = True;
		If pClear Then
			ExchangeFolder = "";
		EndIf;
	Else
		ConnectionType = Enums.ConnectionTypes.FileExchange;
		Items.BaudRate.Visible = False;
		Items.DataBits.Visible = False;
		Items.Parity.Visible = False;
		Items.StopBits.Visible = False;
		Items.Port.Visible = False;
		Items.ExchangeFolder.Visible = True;
		If pClear Then
			BaudRate = 0;
			DataBits = Enums.DataBits.Bits8;
			Parity = Enums.ParityTypes.None;
			StopBits = Enums.StopBits.Bits1;
			Port = "";
		EndIf;
	EndIf;
	DoGuestNamesTransliteration = True;
	WindowOptionsKey = UUID;
EndProcedure // RefreshDisplay

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileAttachingFileSystemExtensionResult(pResult, pParam) Export
	If pResult Then
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension is being installing on your browser...'; ru='В браузер устанавливается расширение по работе с файлами...'; de='Dateisystemerweiterung wird in Ihrem Browser installiert...'"), MessageStatus.Information);
		BeginInstallFileSystemExtension(New NotifyDescription("LoadFromFileFileSystemExtensionInstallCompleted", ThisForm));
	EndIf;
EndProcedure // LoadFromFileAttachingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileFileSystemExtensionInstallCompleted(pParam) Export 
	BeginAttachingFileSystemExtension(New NotifyDescription("LoadFromFileInstallingFileSystemExtensionResult", ThisForm));
EndProcedure // LoadFromFileFileSystemExtensionInstallCompleted

// --------------------------------------------------------------------------------
&AtClient
Procedure LoadFromFileInstallingFileSystemExtensionResult(pResult, pParam) Export 
	If pResult Then
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='File system extension was successfully installed on your browser!'; ru='В браузер успешно установлено расширение по работе с файлами!'; de='Dateisystemerweiterung wurde erfolgreich in Ihrem Browser installiert!'"), MessageStatus.Information);
		OpenFileDialogToChooseFile();
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='Your browser does not support file operations in 1C!'; ru='Браузер не поддерживает работу с файлами в 1С!'; de='Ihr Browser unterstützt keine Dateioperationen in 1C!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // LoadFromFileInstallingFileSystemExtensionResult

// --------------------------------------------------------------------------------
&AtClient 
Procedure OpenFileDialogToChooseFile()
	vFileOpen = New FileDialog(FileDialogMode.ChooseDirectory);
	vFileOpen.Multiselect = False;
	vFileOpen.Title = NStr("en='Choose directory';ru='Выбрать папку';de='Ordner auswählen'");
	vFileOpen.Preview = False;
	vFileOpen.Show(New NotifyDescription("OpenFileDialogToChooseFileCompleted", ThisForm));
EndProcedure // OpenFileDialogToChooseFile

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenFileDialogToChooseFileCompleted(pFileArray, pParam) Export 
	If ValueIsFilled(pFileArray) Then
		ExchangeFolder = pFileArray[0];
	EndIf;
EndProcedure // OpenFileDialogToChooseFileCompleted

#EndRegion

