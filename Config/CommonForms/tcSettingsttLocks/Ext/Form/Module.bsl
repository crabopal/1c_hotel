
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	If Parameters.Property("DoorLockSystemParameters") Then
		DoorLockSystemParameters = Parameters.DoorLockSystemParameters;	
	EndIf;
	
	For i = 1 To 256 Do
		Items.Port.ChoiceList.Add("COM" + Format(i, "NFD=0; NZ=0; NG="));
	EndDo;
	
	Try
		vObjDoorLocksParameters = DoorLockSystemParameters.GetObject();
		vParams = vObjDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
		vParams.Property("InteractionParameters", InteractionParameters);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
		vParams.Property("Port", Port);
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
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
	ThisForm.Close();
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
Procedure ResetSettings()
	AddMinutes = 0;
	SubtractMinutes = 0;
	DoKeyCardsFromFoliosOnly = False;
	UseRoomLockCodes = False;
	ReturnCardUID = False;
	ConvertCardIDToDec = False;
	InteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	Port = "COM1";
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("InteractionParameters", InteractionParameters);
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("Port", Port);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.InteractionParameters = InteractionParameters;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly; 
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes; 
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.Port = Port;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.ConvertUUIDToDecimal = ConvertCardIDToDec;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion

