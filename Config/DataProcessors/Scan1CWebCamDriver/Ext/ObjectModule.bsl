// -----------------------------------------------------------------------------
Function GetColorDepth()
	vColorDepthCode = 2;
	vColorDepth = Undefined;
	If ValueIsFilled(WEBCamConnectionParameters.ColorDepth) Then
		vColorDepth = WEBCamConnectionParameters.ColorDepth;
	EndIf;
	If ValueIsFilled(vColorDepth) Then
		If vColorDepth = Enums.ColorDepths.RGB Then
			vColorDepthCode = 2;
		ElsIf vColorDepth = Enums.ColorDepths.Palette Then
			vColorDepthCode = 3;
		ElsIf vColorDepth = Enums.ColorDepths.Gray Then
			vColorDepthCode = 1;
		ElsIf vColorDepth = Enums.ColorDepths.BW Then
			vColorDepthCode = 0;
		EndIf;
	EndIf;
	Return vColorDepthCode;
EndFunction // GetColorDepth

// -----------------------------------------------------------------------------
Function pmGetListOfTWAINDevices(rMessage) Export
	vList = New ValueList();
	// Reset return status
	rMessage = "";
	// Try to load external component
	vScObj = Undefined;
	Try
		// Use 1CScan.dll
		#IF CLIENT THEN
			Try
				AttachAddIn("AddIn.ScanManager");
				vScObj = New("AddIn.ScanManager");
			Except
				LoadAddIn("1CScan.dll");
				vScObj = New("AddIn.ScanManager");
			EndTry;
		#ELSE
			vScObj = New("AddIn.ScanManager");
		#ENDIF
		// Get list of TWAIN devices
		If vScObj.SelectScanners() <> 1 Then
			Raise NStr("en='Failed to load TWAIN devices list!';ru='Не удалось получить список TWAIN устройств!';de='Es konnte keine Liste von TWAIN-Geräten eingeholte werden!'");
		EndIf;
		While vScObj.GetScanner() = 1 Do
			vList.Add(vScObj.ProductName);
		EndDo;
	Except
		rMessage = ErrorDescription();
	EndTry;
	vScObj = Undefined;
	Return vList;
EndFunction // pmGetListOfTWAINDevices

// -----------------------------------------------------------------------------
Function Connect(rMessage)
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		// Use 1CScan.dll
		vScObj = Undefined;
		#IF CLIENT THEN
			Try
				AttachAddIn("AddIn.ScanManager");
				vScObj = New("AddIn.ScanManager");
			Except
				LoadAddIn("1CScan.dll");
				vScObj = New("AddIn.ScanManager");
			EndTry;
		#ELSE
			vScObj = New("AddIn.ScanManager");
		#ENDIF
		// Set current TWAIN device
		vTwainDeviceName = "";
		If Not IsBlankString(WEBCamConnectionParameters.TwainDeviceName) Then
			vTwainDeviceName = TrimAll(WEBCamConnectionParameters.TwainDeviceName);
		EndIf;
		If vScObj.SelectScanners() <> 1 Then
			Raise NStr("en='Failed to load TWAIN devices list!';ru='Не удалось получить список TWAIN устройств!';de='Es konnte keine Liste von TWAIN-Geräten eingeholte werden!'");
		EndIf;
		If Not IsBlankString(vTwainDeviceName) Then
			While vScObj.GetScanner() = 1 Do
				If vScObj.ProductName = vTwainDeviceName Then
					Break;
				EndIf;
			EndDo;
		Else
			vScObj.GetScanner();
		EndIf;
		If vScObj.Connect() = 0 Then
			Raise NStr("en='Failed to switch to the WEB camera!';ru='Не удалось подключиться к WEB камере!';de='Es konnte kein Anschluss an die WEB-Kamera hergestellt werden!'");
		EndIf;
		// Set image color depth
		vColorDepthCode = GetColorDepth();
		If vScObj.SetParam("PixelType", vColorDepthCode) = -1 Then
			If vScObj.SetParam("PixelType", 2) = -1 Then
				If vScObj.SetParam("PixelType", 3) = -1 Then
					If vScObj.SetParam("PixelType", 1) = -1 Then
						vRes = vScObj.SetParam("PixelType", 0);
						If vRes = 0 Then
							Raise NStr("en='Failed to set color depth!';ru='Не удалось установить глубину цвета!';de='Die Farbentiefe konnte nicht festgelegt werden!'");
						EndIf;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		// OK
		Return vScObj;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // Connect

// -----------------------------------------------------------------------------
Procedure Disconnect(pScObj)
	Try
		pScObj.Disconnect();
		pScObj = Undefined;
	Except
	EndTry;
EndProcedure // Disconnect

// -----------------------------------------------------------------------------
Procedure ProcessException(pScObj, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, WEBCamConnectionParameters.Metadata(), WEBCamConnectionParameters, "Error description: " + rMessage);
	Disconnect(pScObj);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Function pmAcquireImage(pPictureStorage, rMessage) Export
	// Try to connect
	vScObj = Connect(rMessage);
	If vScObj = Undefined Then
		Return False;
	Else
		// Scanner was connected
		Try
			// Acquire image
			vPictFileName = GetTempFileName("jpg");
			vScObj.GetJPEGFile(vPictFileName, 90);
			pPictureStorage = New ValueStorage(New Picture(vPictFileName));
			DeleteFiles(vPictFileName);
			// Disconnect
			Disconnect(vScObj);
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vScObj, NStr("en='WEBCameraDriver.AcquireImage'; de='WEBCameraDriver.AcquireImage'; ru='WEBКамера.ПолучитьКартинку'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmAcquireImage
