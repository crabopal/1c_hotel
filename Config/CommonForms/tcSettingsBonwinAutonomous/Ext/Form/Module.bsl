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
		vParams.Property("ConnectionType", ConnectionType);
		vParams.Property("SectorNumber", SectorNumber);
		vParams.Property("HotelPassword", HotelPassword);
		vParams.Property("LockType", LockType);
		vParams.Property("OtherLock1", OtherLock1);
		vParams.Property("OtherLock2", OtherLock2);
		vParams.Property("OtherLock3", OtherLock3);
		vParams.Property("OtherLock4", OtherLock4);
		vParams.Property("OtherLock5", OtherLock5);
		vParams.Property("OtherLock6", OtherLock6);
		vParams.Property("OtherLock7", OtherLock7);
		vParams.Property("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
		vParams.Property("ReturnCardUID", ReturnCardUID);
		vParams.Property("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
		vParams.Property("ChangeLocationOfTheFile", ChangeLocationOfTheFile);
		vParams.Property("NameOfTheFolder", NameOfTheFolder);
		vParams.Property("FileName", FileName);
		vParams.Property("SubtractMinutes", SubtractMinutes);
		vParams.Property("AddMinutes", AddMinutes);
		vParams.Property("ConvertCardIDToDec", ConvertCardIDToDec);
	Except
		ResetSettings();
	EndTry;
	If Not ValueIsFilled(FileName) Then
		FileName = "bwusbapi";	
	EndIf;
	If SectorNumber = 0 Then
		If LockType = "8038" Or LockType = "8938" Then
			SectorNumber = 31;
			Items.SectorNumber.MaxValue = 31;
			Items.SectorNumber.MinValue = 17;
		Else
			SectorNumber = 15;
			Items.SectorNumber.MaxValue =15;
			Items.SectorNumber.MinValue = 1;		
		EndIf;	
	EndIf;
	Refresh();
EndProcedure // OnCreateAtServer

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
EndProcedure

// -----------------------------------------------------------------------------
Procedure Refresh()
	Items.LockType.ChoiceList.Clear();
	If ConnectionType Then
		Items.LockType.ChoiceList.Add("801","BW801IC");
		Items.LockType.ChoiceList.Add("802","BW802TM");
		Items.LockType.ChoiceList.Add("8031","BW803M1 (8031)");
		Items.LockType.ChoiceList.Add("804","BW804TEMIC");
		Items.LockType.ChoiceList.Add("8090","BW8090");
		Items.LockType.ChoiceList.Add("809","BW809RFEM");
		Items.LockType.ChoiceList.Add("8032","BW803M1 (8032)");
		Items.LockType.ChoiceList.Add("8038","BW8038M1");
	Else
		Items.LockType.ChoiceList.Add("823","BW823MFL");
		Items.LockType.ChoiceList.Add("893","BW883/828/808 (893)");
		Items.LockType.ChoiceList.Add("8938","BW8838/8288/8088 (8938)");
	EndIf;
	
	If AllowDynamicAuthorizations Then
		Items.OtherLock1.Enabled = True;
		Items.OtherLock2.Enabled = True;
		Items.OtherLock3.Enabled = True;
		Items.OtherLock4.Enabled = True;
		Items.OtherLock5.Enabled = True;
		Items.OtherLock6.Enabled = True;
		Items.OtherLock7.Enabled = True;
	Else
		Items.OtherLock1.Enabled = False;
		Items.OtherLock2.Enabled = False;
		Items.OtherLock3.Enabled = False;
		Items.OtherLock4.Enabled = False;
		Items.OtherLock5.Enabled = False;
		Items.OtherLock6.Enabled = False;
		Items.OtherLock7.Enabled = False;		
	EndIf;
	
	If LockType = "8032" Or LockType = "8038" Or LockType = "893" Or LockType = "8938" Then
		Items.SectorNumber.Visible = True;
		Items.AllowDynamicAuthorizations.Visible = True;
		Items.OtherLock1.Visible = True;
		Items.OtherLock2.Visible = True;
		Items.OtherLock3.Visible = True;
		Items.OtherLock4.Visible = True;
		Items.OtherLock5.Visible = True;
		Items.OtherLock6.Visible = True;
		Items.OtherLock7.Visible = True;	
	Else
		Items.SectorNumber.Visible = False;
		AllowDynamicAuthorizations = False;
		Items.AllowDynamicAuthorizations.Visible = False;
		Items.OtherLock1.Visible = False;
		Items.OtherLock2.Visible = False;
		Items.OtherLock3.Visible = False;
		Items.OtherLock4.Visible = False;
		Items.OtherLock5.Visible = False;
		Items.OtherLock6.Visible = False;
		Items.OtherLock7.Visible = False;	
	EndIf;
	Items.GroupFilePath.Visible = ChangeLocationOfTheFile;
EndProcedure // Refresh

// -----------------------------------------------------------------------------
&AtServer
Procedure CommandSaveAtServer()
	vParams = New Structure;
	vParams.Insert("ConnectionType", ConnectionType);
	vParams.Insert("SectorNumber", SectorNumber);
	vParams.Insert("HotelPassword", HotelPassword);
	vParams.Insert("LockType", LockType);
	vParams.Insert("OtherLock1", OtherLock1);
	vParams.Insert("OtherLock2", OtherLock2);
	vParams.Insert("OtherLock3", OtherLock3);
	vParams.Insert("OtherLock4", OtherLock4);
	vParams.Insert("OtherLock5", OtherLock5);
	vParams.Insert("OtherLock6", OtherLock6);
	vParams.Insert("OtherLock7", OtherLock7);
	vParams.Insert("AllowDynamicAuthorizations", AllowDynamicAuthorizations);
	vParams.Insert("ReturnCardUID", ReturnCardUID);
	vParams.Insert("DoKeyCardsFromFoliosOnly", DoKeyCardsFromFoliosOnly);
	vParams.Insert("ChangeLocationOfTheFile", ChangeLocationOfTheFile);
	vParams.Insert("NameOfTheFolder", NameOfTheFolder);
	vParams.Insert("FileName", FileName);
	vParams.Insert("SubtractMinutes", SubtractMinutes);
	vParams.Insert("AddMinutes", AddMinutes);
	vParams.Insert("ConvertCardIDToDec", ConvertCardIDToDec);
	objDoorLocksParameters = DoorLockSystemParameters.GetObject();
	objDoorLocksParameters.DoorLockSystemConnectionParameters = New ValueStorage(vParams);
	objDoorLocksParameters.LicenseCode = HotelPassword;
	objDoorLocksParameters.AssignedAuthorizations = OtherLock1 + ";" + OtherLock2 + ";" + OtherLock3 + ";" + OtherLock4 + ";" + OtherLock5 + ";" + OtherLock6 + ";" + OtherLock7;
	objDoorLocksParameters.AllowDynamicAuthorizations = AllowDynamicAuthorizations;
	objDoorLocksParameters.ReturnCardUID = ReturnCardUID;
	objDoorLocksParameters.DoKeyCardsFromFoliosOnly = DoKeyCardsFromFoliosOnly;
	objDoorLocksParameters.AddMinutes = AddMinutes;
	objDoorLocksParameters.SubtractMinutes = SubtractMinutes;
	objDoorLocksParameters.Write();
	
EndProcedure // CommandSaveAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure CommandSaveAndClose(pCommand)
	If ValueIsFilled(LockType) And ValueIsFilled(HotelPassword) And ValueIsFilled(FileName) Then 
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
	If ValueIsFilled(LockType) And ValueIsFilled(HotelPassword) And ValueIsFilled(FileName) Then 
		CommandSaveAtServer();
		Notify("Catalogs.DoorLockSystemParameters.Write");
	EndIf;
EndProcedure // CommandSave

// -----------------------------------------------------------------------------
&AtClient
Procedure ConnectionTypeOnChange(pItem)
	Refresh();
EndProcedure // ConnectionTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure AllowDynamicAuthorizationsOnChange(pItem)
	Refresh();
EndProcedure // ConnectionTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure LockTypeOnChange(pItem)
	Refresh();
	If LockType = "8038" Or LockType = "8938" Then
		SectorNumber = 31;
		Items.SectorNumber.MaxValue = 31;
		Items.SectorNumber.MinValue = 17;
	Else
		SectorNumber = 15;
		Items.SectorNumber.MaxValue =15;
		Items.SectorNumber.MinValue = 1;		
	EndIf;
EndProcedure // LockTypeOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ChangeLocationOfTheFileOnChange(pItem)
	Refresh();
EndProcedure // ChangeLocationOfTheFileOnChange

// -----------------------------------------------------------------------------
&AtClient
Procedure ResetSettings1(pCommand)
	ResetSettings();
	Refresh();
EndProcedure // ResetSettings1

// -----------------------------------------------------------------------------
&AtClient
Procedure Install(pCommand)
	BeginInstallAddIn(,"CommonTemplate.AddInLocksBonwinAutonomous");
EndProcedure // Install
