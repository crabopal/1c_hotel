
#Region Public

// -----------------------------------------------------------------------------
//  Connect images scanner
//
// Parameters:
//  rMessage - String	 - Return result message
//
Procedure pmConnect(rMessage="") Export
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		// Use Scan1C dll
		vSystemName = "Scan1C";
		
		// ACC:561-off
		vConnected = AttachAddIn("CommonTemplate.Scan1C", "Native", AddInType.Native);
		If Not vConnected Then
			InstallAddIn("CommonTemplate.Scan1C");
			vConnected = AttachAddIn("CommonTemplate.Scan1C", "Native", AddInType.Native);
		EndIf;
		// ACC:561-on
		
		If Not vConnected Then
			rMessage = StrTemplate(NStr("en = '%1 connection error.'; de = '%1 connection error.'; ru = 'Ошибка подключения %1.'"), vSystemName);
			Return;
		EndIf;
		
		amImageScannerInstance = New ("AddIn.Native.AddInNativeExtension");
	Except
		rMessage = ErrorDescription();
	EndTry;
EndProcedure // pmConnect

// -----------------------------------------------------------------------------
//  Disconnect images scanner
//
// Parameters:
//  pScObj	 - ComObject - ComObject images scanner
//
Procedure pmDisconnect(pScObj) Export
	Try
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
//  Scan document
//
// Parameters:
//  pInputParameters - Structure - Input parameters
//  pOuputParameters - Structure - Output parameters
//  rMessage		 - String	 - The string to which the error message is written.
//
Procedure ScanDocument(pInputParameters, pOuputParameters, rMessage="") Export
	If amImageScannerInstance.IsDevicePresent() Then
		// Try to scan document if scanner connected and input parameters are valid
		Try
			vScanConfiguration = pInputParameters.ScanConfiguration;
			
			If ValueIsFilled(vScanConfiguration) And ValueIsFilled(vScanConfiguration.ColorDepth) Then
				vColorDepth = vScanConfiguration.ColorDepth;
			ElsIf ValueIsFilled(pInputParameters.ColorDepth) Then
				vColorDepth = pInputParameters.ColorDepth;
			EndIf;
			If vColorDepth = PredefinedValue("Enum.ColorDepths.Gray") Then
				vColor = 1;
			ElsIf vColorDepth = PredefinedValue("Enum.ColorDepths.BW") Then
				vColor = 0;
			Else
				vColor = 2;
			EndIf;	
			
			If ValueIsFilled(vScanConfiguration) And ValueIsFilled(vScanConfiguration.PaperSize) Then
				vPaperSize = vScanConfiguration.PaperSize;
			ElsIf ValueIsFilled(pInputParameters.PaperSize) Then
				vPaperSize = pInputParameters.PaperSize;
			EndIf;
			
			If ValueIsFilled(vScanConfiguration) And vScanConfiguration.Rotation <> 0 Then
				vRotation = vScanConfiguration.Rotation;
			ElsIf pInputParameters.Rotation <> 0 Then
				vRotation = pInputParameters.Rotation;
			EndIf;
			
			amImageScannerInstance.BeginScan(False, pInputParameters.TwainDeviceName, "JPG", 300, vColor, vRotation, 0, 75, Undefined);
		Except
			rMessage = ErrorDescription();
		EndTry;
	Else
		Raise NStr("en = 'There are no connected TWAIN devices!'; de = 'Es sind keine TWAIN-Geräte angeschlossen!'; ru = 'Отсутствуют подключенные TWAIN устройства!'");
	EndIf;
EndProcedure // ScanDocument

// -----------------------------------------------------------------------------
//  Get list of TWAIN devices
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  ValueList - list of of available TWAIN devices
//
Function pmGetListOfTWAINDevices(rMessage="") Export
	// Try to attach external component
	pmConnect(rMessage);
	vList = New ValueList();
	// Reset return status
	rMessage = "";
	If amImageScannerInstance <> Undefined Then
		Try
			// Get list of TWAIN devices if at least one connected
			If amImageScannerInstance.IsDevicePresent() Then
				vDevicesString = amImageScannerInstance.EnumDevices();
				If vDevicesString = "" Then
					Raise NStr("en = 'Failed to load TWAIN devices list!'; de = 'Es konnte keine Liste von TWAIN-Geräten eingeholte werden!'; ru = 'Не удалось получить список TWAIN устройств!'");
				EndIf;
				For vRow = 1 To StrLineCount(vDevicesString) Do
					vList.Add(StrGetLine(vDevicesString, vRow));
				EndDo;
			EndIf;
		Except
			rMessage = ErrorDescription();
		EndTry;
	EndIf;
	pmDisconnect(amImageScannerInstance);
	Return vList;
EndFunction // pmGetListOfTWAINDevices

// -----------------------------------------------------------------------------
//  Get list of allowed scan configurations
//
// Parameters:
//  rMessage - String	 - Return result message
// 
// Returns:
//  ValueList - list of allowed scan configurations
//
Function pmGetListOfAllowedConfigurations(rMessage="") Export
	vList = New ValueList();
	rMessage = NStr("en = 'Recognition configurations are not used by this driver!'; de = 'Die Konfigurationen für die Erkennungen von Abbildungen werden von diesem Treiber nicht unterstützt'; ru = 'Конфигурации распознавания изображений не поддерживаются выбранным драйвером!'");
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

#EndRegion
