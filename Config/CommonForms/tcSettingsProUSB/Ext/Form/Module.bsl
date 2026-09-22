
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
		vParams.Property("HotelPassword", HotelPassword);
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("AddMinutes", AddMinutes); 
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
		vParams.Property("proUSB", proUSB); 
		vParams.Property("UseRoomLockCodes", UseRoomLockCodes);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("AssignedAuthorizations", AssignedAuthorizations);
		vParams.Property("Deadbolt", Deadbolt);
	Except
		ResetSettings();
	EndTry;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSaveAndClose(pCommand)
	If ValueIsFilled(HotelPassword) Then 
		CommandSaveAtServer();
		Notify("Catalogs.DoorLockSystemParameters.Write");
		ThisForm.Close();
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
	If ValueIsFilled(HotelPassword) Then 
		CommandSaveAtServer();
		Notify("Catalogs.DoorLockSystemParameters.Write");
	EndIf;
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
	HotelPassword = "";
	AddMinutes = 0; 
	SubtractMinutes = 0;
	ReturnCardUID = False;
	DoKeyCardsFromFoliosOnly = False;
	proUSB = False;
	UseRoomLockCodes = False;
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	AssignedAuthorizations = 0;   
	Deadbolt = 0;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("HotelPassword", HotelPassword);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("SubtractMinutes", SubtractMinutes); 
	vParams.Insert("proUSB", proUSB);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	vParams.Insert("UseRoomLockCodes", UseRoomLockCodes);
	vParams.Insert("DefaultRoom", DefaultRoom); 
	vParams.Insert("AssignedAuthorizations", AssignedAuthorizations);
	vParams.Insert("Deadbolt", Deadbolt);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.LicenseCode = HotelPassword;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.UseRoomLockCodes = UseRoomLockCodes;
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.AssignedAuthorizations = Format(AssignedAuthorizations, "NFD=0; NZ=0; NG=");
	objDoorLocksParameters.Write();	
EndProcedure // CommandSaveAtServer

#EndRegion
