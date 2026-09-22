
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
		vParams.Property("EncoderNumber", EncoderNumber);
		vParams.Property("ReturnCardUID", ReturnCardUID); 
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("AddMinutes", AddMinutes);   
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
	If ValueIsFilled(EncoderNumber) Then 
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
	If ValueIsFilled(EncoderNumber) Then 
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
	BeginInstallAddIn(,"CommonTemplate.AddInLocksiLocks");
EndProcedure // Install

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ResetSettings()
	ConnectionType = True;
	SectorNumber = 15;
	HotelPassword = "";
	LockType = "";
	OtherLock1 = "000000";
	OtherLock2 = "000000";
	OtherLock3 = "000000";
	OtherLock4 = "000000";
	OtherLock5 = "000000";
	OtherLock6 = "000000";
	OtherLock7 = "000000";
	SubtractMinutes = 0;
	AddMinutes = 0;
	AllowDynamicAuthorizations = False;
	ReturnCardUID = False;
	DoKeyCardsFromFoliosOnly = False;
	ChangeLocationOfTheFile = False;
	ChangeLocationOfTheFile = False;
	NameOfTheFolder = "";
	FileName = "bwusbapi"; 
	ConvertCardIDToDec = False;
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("EncoderNumber", EncoderNumber);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AddMinutes", AddMinutes);   
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.EncoderNumber = EncoderNumber;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.AddMinutes = AddMinutes; 
	objDoorLocksParameters.ConvertUUIDToDecimal = ConvertCardIDToDec;
	objDoorLocksParameters.Write();
EndProcedure // CommandSaveAtServer

#EndRegion
