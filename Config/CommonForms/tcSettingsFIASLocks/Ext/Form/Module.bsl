
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
		vParams.Property("HotelPassword", KeyCoder);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("InteractionParameters", InteractionParameters);
		vParams.Property("KeyCoder", KeyCoder);
		vParams.Property("WorkstationID", WorkstationID);
		vParams.Property("AssignedAuthorizations", AssignedAuthorizations);
		vParams.Property("ExtensionRooms", ExtensionRooms);
		vParams.Property("DefaultRoom", DefaultRoom);
		vParams.Property("DoDataTransliteration", DoDataTransliteration);
		vParams.Property("SubtractMinutes", SubtractMinutes);
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
	KeyCoder = "";
	AddMinutes = 0;
	SubtractMinutes = 0;
	DoKeyCardsFromFoliosOnly = False;
	DoDataTransliteration = False;
	InteractionParameters = Catalogs.ExternalSystemInteractions.EmptyRef();
	DefaultRoom = Catalogs.Rooms.EmptyRef();
	KeyCoder = "";
	WorkstationID = "";
	AssignedAuthorizations = "";
	ExtensionRooms = "";
EndProcedure // ResetSettings

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("HotelPassword", KeyCoder);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("AddMinutes", AddMinutes);  
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("InteractionParameters", InteractionParameters);
	vParams.Insert("KeyCoder", KeyCoder);
	vParams.Insert("WorkstationID", WorkstationID);
	vParams.Insert("AssignedAuthorizations", AssignedAuthorizations);
	vParams.Insert("ExtensionRooms", ExtensionRooms);                       
	vParams.Insert("DefaultRoom", DefaultRoom);
	vParams.Insert("DoDataTransliteration", DoDataTransliteration);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;    
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.AssignedAuthorizations = AssignedAuthorizations; 
	objDoorLocksParameters.DefaultRoom = DefaultRoom;
	objDoorLocksParameters.DoGuestNamesTransliteration = DoDataTransliteration;  
	objDoorLocksParameters.InteractionParameters = InteractionParameters;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion
