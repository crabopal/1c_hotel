
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
		vParams.Property("WriteTrack2", WriteTrack2);
		vParams.Property("WriteTrack1", WriteTrack1);
		vParams.Property("Track1Length", Track1Length);
		vParams.Property("BytesToConvert", BytesToConvert);
		vParams.Property("DeniedAuthorizations", DeniedAuthorizations);    
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("ConvertUUIDToDecimal", ConvertUUIDToDecimal); 
		vParams.Property("DefaultRoom", DefaultRoom);
	Except
		ResetSettings();                                   
	EndTry;
EndProcedure // OnCreateAtServer

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
	Port = "";
	ServerName = "";
	DeniedAuthorizations = "";
	AddMinutes = 0;
	SubtractMinutes = 0;
	AllowDynamicAuthorizations = False;
	DoKeyCardsFromFoliosOnly = False;
	UseRoomLockCodes = False;
	WriteTrack2 = False;
	WriteTrack1 = False;
	ConvertUUIDToDecimal = False;
	ReturnCardUID = False;
	Track1Length = 0;     
	BytesToConvert = Enums.BytesToConvert.EmptyRef();
	DefaultRoom = Catalogs.Rooms.EmptyRef();
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
	vParams.Insert("WriteTrack2", WriteTrack2);
	vParams.Insert("WriteTrack1", WriteTrack1);        
	vParams.Insert("Track1Length", Track1Length);    
	vParams.Insert("ConvertUUIDToDecimal", ConvertUUIDToDecimal); 
	vParams.Insert("BytesToConvert", BytesToConvert);  
	vParams.Insert("DeniedAuthorizations", DeniedAuthorizations);
	vParams.Insert("DefaultRoom", DefaultRoom);                    
	vParams.Insert("ReturnCardUID", ReturnCardUID);  
	vParams.Insert("ConnectionType", Enums.ConnectionTypes.TCPIP);
	vParams.Insert("DoGuestNamesTransliteration", DoGuestNamesTransliteration);
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
	objDoorLocksParameters.WriteTrack2 = WriteTrack2; 
	objDoorLocksParameters.WriteTrack1 = WriteTrack1;
	objDoorLocksParameters.Track1Length = Track1Length;  
	objDoorLocksParameters.DeniedAuthorizations = DeniedAuthorizations;
	objDoorLocksParameters.BytesToConvert = BytesToConvert;
	objDoorLocksParameters.ConvertUUIDToDecimal = ConvertUUIDToDecimal;     
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.ConnectionType = Enums.ConnectionTypes.TCPIP;
	objDoorLocksParameters.DoGuestNamesTransliteration = DoGuestNamesTransliteration;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion
