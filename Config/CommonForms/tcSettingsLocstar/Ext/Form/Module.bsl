
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
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("SubtractMinutes", SubtractMinutes); 
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
		vParams.Property("KeyCardType", KeyCardType);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("CardWaitingTime", CardWaitingTime);
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
	BeginInstallAddIn(,"CommonTemplate.AddInLocksLocstar");
EndProcedure // Install

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ResetSettings()
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	KeyCardType = "";
	AddMinutes = 0;
	SubtractMinutes = 0;
	CardWaitingTime = 0;
	ReturnCardUID = False;
	DoKeyCardsFromFoliosOnly = False;
	ConvertCardIDToDec = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("KeyCardType", KeyCardType);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	vParams.Insert("UseRoomLockCodes", True);
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("CardWaitingTime", CardWaitingTime);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.KeyCardType = KeyCardType; 
	objDoorLocksParameters.UseRoomLockCodes = True;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion
