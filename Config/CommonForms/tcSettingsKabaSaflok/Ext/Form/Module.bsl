
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
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
		vParams.Property("WriteTrack1", WriteTrack1);
		vParams.Property("Track1Length", Track1Length);
		vParams.Property("WriteTrack2", WriteTrack2);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("ConnectionType", ConnectionType);
		vParams.Property("LicenseCode", LicenseCode);
		vParams.Property("IsFormatMessage74Bytes", IsFormatMessage74Bytes);
	Except
		ResetSettings();
	EndTry;
	ConnectionType = Enums.ConnectionTypes.TCPIP;
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtServer
Procedure FillCheckProcessingAtServer(pCancel, pCheckedAttributes)		
	pCheckedAttributes.Add("ServerName");
	pCheckedAttributes.Add("EncoderNumber");
EndProcedure // FillCheckProcessingAtServer

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
	AssignedAuthorizations = "";
	EncoderNumber = "";
	PCId = "";
	Port = "";
	ServerName = "";	
	AddMinutes = 0;
	SubtractMinutes = 0;
	IsFormatMessage74Bytes = False;
	AllowDynamicAuthorizations = False;
	DoKeyCardsFromFoliosOnly = False;
	UseRoomLockCodes = False;
	WriteTrack1 = False;
	Track1Length = 0;
	WriteTrack2 = False;
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	ConnectionType = Enums.ConnectionTypes.TCPIP;
	LicenseCode = "";
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
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("WriteTrack2", WriteTrack2);
	vParams.Insert("WriteTrack1", WriteTrack1);
	vParams.Insert("Track1Length", Track1Length);
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("ConnectionType", ConnectionType);
	vParams.Insert("DoGuestNamesTransliteration", DoGuestNamesTransliteration);
	vParams.Insert("LicenseCode", LicenseCode);
	vParams.Insert("IsFormatMessage74Bytes", IsFormatMessage74Bytes);
	vParams.Insert("IsDebug", IsDebug);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.AssignedAuthorizations = AssignedAuthorizations;
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.PCId = PCId;
	objDoorLocksParameters.Port = Port;
	objDoorLocksParameters.ServerName = ServerName;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.AllowDynamicAuthorizations = AllowDynamicAuthorizations;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes;
	objDoorLocksParameters.WriteTrack1 = WriteTrack1;
	objDoorLocksParameters.Track1Length = Track1Length;
	objDoorLocksParameters.WriteTrack2 = WriteTrack2;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.ConnectionType = ConnectionType;
	objDoorLocksParameters.DoGuestNamesTransliteration = DoGuestNamesTransliteration;
	objDoorLocksParameters.LicenseCode = LicenseCode;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion

