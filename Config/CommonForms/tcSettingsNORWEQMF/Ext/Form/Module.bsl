
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)  
	#If ThickClientOrdinaryApplication Then
		Items.FormInstall.Visible = False;	
	#Else	
		Items.FormInstall.Visible = True;	
	#EndIf
	
	If Parameters.Property("DoorLockSystemParameters") Then
		DoorLockSystemParameters = Parameters.DoorLockSystemParameters;	
	EndIf;
	Try
		vObjDoorLocksParameters = DoorLockSystemParameters.GetObject();
		vParams = vObjDoorLocksParameters.DoorLockSystemConnectionParameters.Get();
		vParams.Property("LockType", LockType);
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("AddMinutes", AddMinutes); 
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
		vParams.Property("LockType", LockType); 
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
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
	CommandSaveAtServer();
	Notify("Catalogs.DoorLockSystemParameters.Write");
	Close();
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandClose(pCommand)
	Close();
EndProcedure // CommandSaveAndClose

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSave(pCommand)
	CommandSaveAtServer();
	Notify("Catalogs.DoorLockSystemParameters.Write");
EndProcedure // CommandSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetSettings1(pCommand)
	ResetSettings();
EndProcedure // ResetSettings1

// -----------------------------------------------------------------------------
&AtClient
Procedure Install(pCommand)
	BeginInstallAddIn(,"CommonTemplate.AddInLocksProUSB");
EndProcedure // Install

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ResetSettings()
	AddMinutes = 0; 
	SubtractMinutes = 0;
	ReturnCardUID = False;
	DoKeyCardsFromFoliosOnly = False;
	LockType = 5;
	UseRoomLockCodes = False;
	DefaultRoom = Catalogs.Rooms.EmptyRef();   
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;   
	vParams.Insert("LockType", LockType);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("SubtractMinutes", SubtractMinutes); 
	vParams.Insert("GuestCardOption", LockType);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("DefaultRoom", DefaultRoom); 
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.Write();	
EndProcedure // CommandSaveAtServer

#EndRegion
