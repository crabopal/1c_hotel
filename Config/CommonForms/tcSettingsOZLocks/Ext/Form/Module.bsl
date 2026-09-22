
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
	BeginInstallAddIn(,"CommonTemplate.AddInLocksOZLocks");
EndProcedure // Install

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure ResetSettings()
	HotelPassword = "";
	AddMinutes = 0;
	ReturnCardUID = False;
	DoKeyCardsFromFoliosOnly = False;	
EndProcedure

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("HotelPassword", HotelPassword);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.LicenseCode = HotelPassword;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.Write();
	
EndProcedure // CommandSaveAtServer

#EndRegion
