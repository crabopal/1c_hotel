
#Region FormCommandsEventHandlers

// ---------------------------------------------------------------------------------
&AtClient
Procedure RustDesk(Command)
	RunSupport("RustDesk");
EndProcedure

#EndRegion

#Region Private

// ---------------------------------------------------------------------------------
&AtClient
Async Procedure RunSupport(pSystem)  
	Modified = False;
	ReadOnly = True;
	vExtenAttach = Await AttachFileSystemExtensionAsync();
	If Not vExtenAttach Then
		Await InstallFileSystemExtensionAsync();
		vExtenAttach = Await AttachFileSystemExtensionAsync();	
	EndIf;  
	If Not vExtenAttach Then         
		vErr = NStr("en = 'Your browser does not support file operations in 1C!'; 
					|de = 'Ihr Browser unterstützt keine Dateioperationen in 1C!'; 
					|ru = 'Браузер не поддерживает работу с файлами в 1С!'");
		DoMessageBoxAsync(vErr);
		Return;
	EndIf;	
	vFileName = pSystem + ".exe";  
	vFileCatalog = Await TempFilesDirAsync();
	vFile = New File(vFileCatalog + vFileName);
	If Not Await vFile.ExistsAsync() Then
		vTempAddress = GetTemplateSupportConnection(pSystem);  
		Await GetFileFromServerAsync(vTempAddress, vFile.FullName);
	EndIf;
	Await RunAppAsync(vFile.FullName); 
	Close();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Function GetTemplateSupportConnection(pSystem)
	vAdrr = PutToTempStorage(GetCommonTemplate(pSystem), UUID);
	Return vAdrr;
EndFunction  // GetTemplateSupportConnection  

#EndRegion
