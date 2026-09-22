
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	If Parameters.Property("DoorLockSystemParameters") Then
		DoorLockSystemParameters = Parameters.DoorLockSystemParameters;	
	EndIf;
	Try
		vObjDoorLocksParameters = DoorLockSystemParameters.GetObject();
		vParams = vObjDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
		vParams.Property("AssignedAuthorizations", AssignedAuthorizations);
		vParams.Property("EncoderNumber", EncoderNumber);
		vParams.Property("PCId", PCId);
		vParams.Property("Port", Port);
		vParams.Property("ServerName", ServerName);
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
	Else
		pCheckedAttributes.Add("ServerName");	
	EndIf;
EndProcedure // FillCheckProcessingAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTypePresentationOnChange(pItem)
	RefreshDisplay(True);
EndProcedure // ConnectionTypePresentationOnChange

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
	AssignedAuthorizations = "";
	EncoderNumber = "";
	PCId = "";
	Port = "";
	ServerName = "";	
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
	vParams.Insert("AssignedAuthorizations", AssignedAuthorizations);
	vParams.Insert("EncoderNumber", EncoderNumber);
	vParams.Insert("PCId", PCId);
	vParams.Insert("Port", Port);
	vParams.Insert("ServerName", ServerName);
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
	objDoorLocksParameters.AssignedAuthorizations = AssignedAuthorizations;
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.PCId = PCId;
	objDoorLocksParameters.Port = Port;
	objDoorLocksParameters.ServerName = ServerName;
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
		Items.ServerName.Visible = False;
		Items.EncoderNumber.Visible = False;
		Items.PCId.Visible = False;
		Items.BaudRate.Visible = True;
		Items.DataBits.Visible = True;
		Items.Parity.Visible = True;
		Items.StopBits.Visible = True;
		If pClear Then
			ServerName = "";
			EncoderNumber = "";
			PCId = "";
			Port = "";
		EndIf;
		Items.Port.Width = 0;
		Items.Port.TitleLocation = FormItemTitleLocation.Left;
		Items.Port.InputHint = NStr("en = '(COM1, COM2, ...)'; de = '(COM1, COM2, ...)'; ru = '(COM1, COM2, ...)'");
	Else
		ConnectionType = Enums.ConnectionTypes.TCPIP;
		Items.BaudRate.Visible = False;
		Items.DataBits.Visible = False;
		Items.Parity.Visible = False;
		Items.StopBits.Visible = False;
		Items.ServerName.Visible = True;
		Items.EncoderNumber.Visible = True;
		Items.PCId.Visible = True;
		If pClear Then
			BaudRate = 0;
			DataBits = Enums.DataBits.Bits8;
			Parity = Enums.ParityTypes.None;
			StopBits = Enums.StopBits.Bits1;
			Port = "";
		EndIf;
		Items.Port.Width = 6;
		Items.Port.TitleLocation = FormItemTitleLocation.None;
		Items.Port.InputHint = NStr("en = 'IP Port'; de = 'IP-Port'; ru = 'IP Порт'");
	EndIf;
	DoGuestNamesTransliteration = True;
	WindowOptionsKey = UUID;
EndProcedure // RefreshDisplay

#EndRegion
