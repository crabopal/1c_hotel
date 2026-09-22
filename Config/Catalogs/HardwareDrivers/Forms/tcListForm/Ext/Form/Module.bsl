
#Region EventHandlers

// --------------------------------------------------------------------------------
&AtClient
Async Procedure CreateHardwareDriver(pCommand)
	vFileTempStorage = Await tcConnectionHardwareAtClient.LoadHardwareDriver(UUID);
	If IsBlankString(vFileTempStorage) Then
		Return;
	EndIf;
	
	OpenForm("Catalog.HardwareDrivers.ObjectForm", New Structure("FileTempStorage", vFileTempStorage), ThisObject, UUID);
EndProcedure // CreateHardwareDriver

#EndRegion