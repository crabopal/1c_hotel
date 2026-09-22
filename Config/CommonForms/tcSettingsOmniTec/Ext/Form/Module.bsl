
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
		vParams.Property("Port", Port);
		vParams.Property("ServerName", ServerName);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("ConnectionType", ConnectionType);
		vParams.Property("ReturnCardUID", ReturnCardUID);
		ConnectionTypePresentation = ?(ConnectionType = Enums.ConnectionTypes.OmniTecDLL, 0, 1);
	Except
		ResetSettings();
	EndTry;
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)
	If ConnectionType = Enums.ConnectionTypes.TCPIP Then
		pCheckedAttributes.Add("ServerName");
		pCheckedAttributes.Add("Port");			
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
	Port = "";
	ServerName = "";	
	AddMinutes = 0;
	SubtractMinutes = 0;
	AllowDynamicAuthorizations = False;
	DoKeyCardsFromFoliosOnly = False;
	UseRoomLockCodes = False; 
	ReturnCardUID = False;
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	ConnectionType = Enums.ConnectionTypes.RS232;
	RefreshDisplay(True);
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("AssignedAuthorizations", AssignedAuthorizations);
	vParams.Insert("EncoderNumber", EncoderNumber);
	vParams.Insert("Port", Port);
	vParams.Insert("ServerName", ServerName);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("ConnectionType", ConnectionType);
	vParams.Insert("DoGuestNamesTransliteration", DoGuestNamesTransliteration);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.AssignedAuthorizations = AssignedAuthorizations;
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.Port = Port;
	objDoorLocksParameters.ServerName = ServerName;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.AllowDynamicAuthorizations = AllowDynamicAuthorizations;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.ConnectionType = ConnectionType;
	objDoorLocksParameters.DoGuestNamesTransliteration = DoGuestNamesTransliteration;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay(pClear = False)
	If ConnectionTypePresentation = 0 Then
		ConnectionType = Enums.ConnectionTypes.OmniTecDLL;
		Items.GroupServerNameAndPort.Visible = False;
		If pClear Then
			ServerName = "";
			Port = "";
		EndIf;
	Else
		ConnectionType = Enums.ConnectionTypes.TCPIP;
		Items.GroupServerNameAndPort.Visible = True;
	EndIf;
	DoGuestNamesTransliteration = True;
	WindowOptionsKey = UUID;
EndProcedure // RefreshDisplay

#EndRegion

