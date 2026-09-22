
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	RefreshDisplay();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure NotificationProcessing(pEventName, pParameter, pSource)
	If pEventName = "Catalogs.DoorLockSystemParameters.Write" Then
		Read();	
	EndIf;
EndProcedure // NotificationProcessing

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure DoorLockSystemTypeOnChange(pItem)
	RefreshDisplay();	
EndProcedure // DoorLockSystemTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CommandOpenSettings(pCommand)
	If Not Modified Then
		If ValueIsFilled(Object.DoorLockSystemType) Then
			If Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Hoist") Then
				OpenForm("DataProcessor.HoistDoorLockSystemDriver.Form.Settings", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.BonwinAutonomous") Then
				OpenForm("CommonForm.tcSettingsBonwinAutonomous", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocks") Then
				OpenForm("CommonForm.tcSettingsILocks", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocksOnline") Then
				OpenForm("CommonForm.tcSettingsILocksOnline", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OZLocks") Then
				OpenForm("CommonForm.tcSettingsOZLocks", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaIlco") Then
				OpenForm("CommonForm.tcSettingsKabaIlco", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaSaflok") Then
				OpenForm("CommonForm.tcSettingsKabaSaflok",New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.TimeLox2300") Then
				OpenForm("CommonForm.tcSettingsTimeLox", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OmniTec") Then
				OpenForm("CommonForm.tcSettingsOmniTec", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Locstar") Then
				OpenForm("CommonForm.tcSettingsLocstar", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.IronLogic") Then
				OpenForm("CommonForm.tcSettingsIronLogic", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FIAS") Then
				OpenForm("CommonForm.tcSettingsFIASLocks", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.ttLock") Then
				OpenForm("CommonForm.tcSettingsttLocks", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB") Then
				OpenForm("CommonForm.tcSettingsProUSB", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.HAFELE") Then
				OpenForm("CommonForm.tcSettingsHAFELE", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.NORWEQMF") Or Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FHBS") Then
				OpenForm("CommonForm.tcSettingsNORWEQMF", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Novilock") Then
				OpenForm("CommonForm.tcSettingsNovilock", New Structure("DoorLockSystemParameters", Object.Ref));
			ElsIf Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaMagnetic") Or
				  Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaProximity") Then
				OpenForm("CommonForm.tcSettingsInhova", New Structure("DoorLockSystemParameters", Object.Ref));
			EndIf;
		EndIf;
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'All changes must be saved!'; de = 'Alle änderungen müssen gespeichert werden!'; ru = 'Все изменения должны быть сохранены!'"));	
	EndIf;
EndProcedure // CommandOpenSettings

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtServer
Procedure RefreshDisplay()
	If ValueIsFilled(Object.DoorLockSystemType) Then
		If Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.BonwinAutonomous") Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocks") Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.iLocksOnline") Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OZLocks") Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaIlco")Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.KabaSaflok")Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.TimeLox2300") Or 
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.OmniTec") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Locstar") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.IronLogic") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FIAS") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.ttLock") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.proUSB") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.HAFELE") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.NORWEQMF") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.FHBS") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.Novilock") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaMagnetic") Or
		   Object.DoorLockSystemType = PredefinedValue("Enum.DoorLockSystems.InhovaProximity") Then
			Items.Group_Main.Enabled = False;
		Else
			Items.Group_Main.Enabled = True;
		EndIf;
	Else
		Items.Group_Main.Enabled = True;
	EndIf;
EndProcedure // RefreshDisplay

#EndRegion