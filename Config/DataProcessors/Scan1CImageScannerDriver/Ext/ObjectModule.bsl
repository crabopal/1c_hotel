// -----------------------------------------------------------------------------
Function GetPaperSize(pScanConfiguration)
	vPSCode = "";
	vPS = Undefined;
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.PaperSize) Then
		vPS = pScanConfiguration.PaperSize;
	ElsIf ValueIsFilled(ImageScannerConnectionParameters.PaperSize) Then
		vPS = ImageScannerConnectionParameters.PaperSize;
	EndIf;
	If ValueIsFilled(vPS) Then
		If vPS = Enums.PaperSizes.A0 Then
			vPSCode = "A0";
		ElsIf vPS = Enums.PaperSizes.A1 Then
			vPSCode = "A1";
		ElsIf vPS = Enums.PaperSizes.A2 Then
			vPSCode = "A2";
		ElsIf vPS = Enums.PaperSizes.A3 Then
			vPSCode = "A3";
		ElsIf vPS = Enums.PaperSizes.A4 Then
			vPSCode = "A4";
		ElsIf vPS = Enums.PaperSizes.A5 Then
			vPSCode = "A5";
		ElsIf vPS = Enums.PaperSizes.A6 Then
			vPSCode = "A6";
		ElsIf vPS = Enums.PaperSizes.A7 Then
			vPSCode = "A7";
		ElsIf vPS = Enums.PaperSizes.A8 Then
			vPSCode = "A8";
		ElsIf vPS = Enums.PaperSizes.A9 Then
			vPSCode = "A9";
		ElsIf vPS = Enums.PaperSizes.A10 Then
			vPSCode = "A10";
		ElsIf vPS = Enums.PaperSizes.B3 Then
			vPSCode = "B3";
		ElsIf vPS = Enums.PaperSizes.B4 Then
			vPSCode = "B4";
		ElsIf vPS = Enums.PaperSizes.B5 Then
			vPSCode = "B5";
		ElsIf vPS = Enums.PaperSizes.B6 Then
			vPSCode = "B6";
		ElsIf vPS = Enums.PaperSizes.C4 Then
			vPSCode = "C4";
		ElsIf vPS = Enums.PaperSizes.C5 Then
			vPSCode = "C5";
		ElsIf vPS = Enums.PaperSizes.C6 Then
			vPSCode = "C6";
		ElsIf vPS = Enums.PaperSizes.A40 Then
			vPSCode = "4A0";
		ElsIf vPS = Enums.PaperSizes.A20 Then
			vPSCode = "2A0";
		ElsIf vPS = Enums.PaperSizes.USLET Then
			vPSCode = "USLET";
		ElsIf vPS = Enums.PaperSizes.USLEG Then
			vPSCode = "USLEG";
		ElsIf vPS = Enums.PaperSizes.USLEDGER Then
			vPSCode = "USLEDGER";
		ElsIf vPS = Enums.PaperSizes.USEXECUTIVE Then
			vPSCode = "USEXECUTIVE";
		EndIf;
	EndIf;
	Return vPSCode;
EndFunction // GetPaperSize

// -----------------------------------------------------------------------------
Function GetRotation(pScanConfiguration)
	vRotation = "";
	If ValueIsFilled(pScanConfiguration) And pScanConfiguration.Rotation <> 0 Then
		vRotation = pScanConfiguration.Rotation;
	ElsIf ImageScannerConnectionParameters.Rotation <> 0 Then
		vRotation = ImageScannerConnectionParameters.Rotation;
	EndIf;
	Return vRotation;
EndFunction // GetRotation

// -----------------------------------------------------------------------------
Function GetColorDepth(pScanConfiguration)
	vColorDepthCode = "";
	vColorDepth = Undefined;
	If ValueIsFilled(pScanConfiguration) And ValueIsFilled(pScanConfiguration.ColorDepth) Then
		vColorDepth = pScanConfiguration.ColorDepth;
	ElsIf ValueIsFilled(ImageScannerConnectionParameters.ColorDepth) Then
		vColorDepth = ImageScannerConnectionParameters.ColorDepth;
	EndIf;
	If ValueIsFilled(vColorDepth) Then
		If vColorDepth = Enums.ColorDepths.RGB Then
			vColorDepthCode = "RGB";
		ElsIf vColorDepth = Enums.ColorDepths.Palette Then
			vColorDepthCode = "PALETTE";
		ElsIf vColorDepth = Enums.ColorDepths.Gray Then
			vColorDepthCode = "GRAY";
		ElsIf vColorDepth = Enums.ColorDepths.BW Then
			vColorDepthCode = "BW";
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
	vScObj = pmConnect(rMessage);
	If vScObj <> Undefined Then
		Try
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
	EndIf;
	Return vList;
EndFunction // pmGetListOfTWAINDevices

// -----------------------------------------------------------------------------
Function pmGetListOfAllowedConfigurations(rMessage) Export
	vList = New ValueList();
	rMessage = NStr("en='Recognition configurations are not used by this driver!';ru='Конфигурации распознавания изображений не поддерживаются выбранным драйвером!';de='Die Konfigurationen für die Erkennungen von Abbildungen werden von diesem Treiber nicht unterstützt'");
	Return vList;
EndFunction // pmGetListOfAllowedConfigurations

// -----------------------------------------------------------------------------
Procedure Connect(pScObj, pTwainDeviceName)
	// Set current TWAIN device
	If pScObj.SelectScanners() <> 1 Then
		Raise NStr("en='Failed to load TWAIN devices list!';ru='Не удалось получить список TWAIN устройств!';de='Es konnte keine Liste von TWAIN-Geräten eingeholte werden!'");
	EndIf;
	If Not IsBlankString(pTwainDeviceName) Then
		While pScObj.GetScanner() = 1 Do
			If pScObj.ProductName = pTwainDeviceName Then
				Break;
			EndIf;
		EndDo;
	Else
		pScObj.GetScanner();
	EndIf;
	If pScObj.Connect() = 0 Then
		Raise NStr("en='Failed to switch to the scanner!';ru='Не удалось подключиться к сканеру!';de='Es konnte kein Anschluss an den Scanner hergestellt werden!'");
	EndIf;
	// Set resolution
	If pScObj.SetParam("XResolution", 300) = -1 Then
		vRes = pScObj.SetParam("XResolution", 100);
		If vRes = 0 Then
			Raise NStr("en='Failed to set resolution!';ru='Не удалось установить разрешение!';de='Die Auflösung konnte nicht festgelegt werden!'");
		EndIf;
	EndIf;
	If pScObj.SetParam("YResolution", 300) = -1 Then
		vRes = pScObj.SetParam("YResolution", 100);
		If vRes = 0 Then
			Raise NStr("en='Failed to set resolution!';ru='Не удалось установить разрешение!';de='Die Auflösung konnte nicht festgelegt werden!'");
		EndIf;
	EndIf;
EndProcedure // Connect

// -----------------------------------------------------------------------------
Function pmConnect(rMessage, pDummy = Undefined) Export
	#IF CLIENT THEN
		If amImageScannerDriver = Undefined Then
			amImageScannerDriver = ThisObject;
		EndIf;
	#ENDIF
	// Reset return status
	rMessage = "";
	// Try to load external component
	Try
		vTwainDeviceName = "";
		If Not IsBlankString(ImageScannerConnectionParameters.TwainDeviceName) Then
			vTwainDeviceName = TrimAll(ImageScannerConnectionParameters.TwainDeviceName);
		EndIf;
		// Use 1CScan.dll
		vScObj = Undefined;
		#IF CLIENT THEN
			If amImageScanner = Undefined Then
				Try
					AttachAddIn("AddIn.ScanManager");
					vScObj = New("AddIn.ScanManager");
				Except
					LoadAddIn("1CScan.dll");
					vScObj = New("AddIn.ScanManager");
				EndTry;
				Connect(vScObj, vTwainDeviceName);
				amImageScanner = vScObj;
			Else
				vScObj = amImageScanner;
			EndIf;
		#ELSE
			vScObj = New COMObject("AddIn.ScanManager");
			Connect(vScObj, vTwainDeviceName);
		#ENDIF
		// OK
		Return vScObj;
	Except
		rMessage = ErrorDescription();
		Return Undefined;
	EndTry;
EndFunction // pmConnect

// -----------------------------------------------------------------------------
Procedure pmDisconnect(pScObj, pDummy = Undefined) Export
	Try
		pScObj.Disconnect();
		pScObj = Undefined;
		#IF CLIENT THEN
			amImageScanner = Undefined;
		#ENDIF			
	Except
	EndTry;
EndProcedure // pmDisconnect

// -----------------------------------------------------------------------------
Procedure ProcessException(pScObj, pFunction, rMessage)
	tcCommonFunctionOnClientServer.TextMessage(rMessage, MessageStatus.Attention);
	WriteLogEvent(pFunction, EventLogLevel.Warning, ImageScannerConnectionParameters.Metadata(), ImageScannerConnectionParameters, "Error description: " + rMessage);
	pmDisconnect(pScObj);
EndProcedure // ProcessException

// -----------------------------------------------------------------------------
Procedure ConvertImage(pTargetFileName, pSourceFileName, pScObj)
	// Build active X object to rotate picture
	Try
		vGFLAx = New COMObject("GFLAx.GFLAx");
	Except
		vMessage = NStr("en='GFLAx (ActiveX/ASP component) should be installed first! Go to the current workstation item settings and press <Install GFLAx (ActiveX/ASP component)> button.';ru='ActiveX/ASP библиотека GFLAx не установлена! Для установки откройте карточку настроек рабочего места и нажмите на кнопку <Установить GFLAx (ActiveX/ASP библиотеку)>.';de='Die ActiveX/ASP-Bibliothek GFLAx wurde nicht installiert! Zur Installation öffnen Sie die Arbeitsplatzeinstellungen und wählen Sie <GFLAx (ActiveX/AP-Bibliothek) installieren)>.'");
		#IF CLIENT THEN
			DoMessageBox(vMessage);
		#ELSE
			ProcessException(pScObj, "ConvertImage", vMessage);
		#ENDIF
		Return;
	EndTry;
	Try
		vGFLAx.LoadBitmap(pSourceFileName);
		vGFLAx.SaveformatName = "jpeg";
		vGFLAx.SaveJPEGQuality = 30;
		vGFLAx.SaveBitmap(pTargetFileName);
		vGFLAx = Undefined;
	Except
		vMessage = NStr("en='Unsupported picture format!';ru='Формат картинки не поддерживается!';de='Format des Bilds wird nicht unterstützt!'") + Chars.LF + ErrorDescription();
		#IF CLIENT THEN
			DoMessageBox(vMessage);
		#ELSE
			ProcessException(pScObj, "ConvertImage", vMessage);
		#ENDIF
	EndTry;
EndProcedure // ConvertImage

// -----------------------------------------------------------------------------
Function pmScanDocument(pScanConfiguration, pPictureStorage, rMessage) Export
	// Try to connect
	vScObj = pmConnect(rMessage);
	If vScObj = Undefined Then
		Return False;
	Else
		// Scanner was connected
		Try
			// Set document paper size
			vPSCode = GetPaperSize(pScanConfiguration);
			If Not IsBlankString(vPSCode) Then
				If vScObj.SetParam("PaperSize", vPSCode) = 0 Then
					Raise NStr("en='Failed to set paper size!';ru='Не удалось установить размер бумаги!';de='Papiergröße konnte nicht festgelegt werden!'");
				EndIf;
			EndIf;
			// Set document rotation
			vRotation = GetRotation(pScanConfiguration);
			If Not IsBlankString(vRotation) Then
				If vScObj.SetParam("Rotation", vRotation) = 0 Then
					Raise NStr("en='Failed to set rotation degree!';ru='Не удалось установить угол поворота!';de='Der Drehwinkel konnte nicht festgelegt werden!'");
				EndIf;
			EndIf;
			// Set document color depth
			vColorDepthCode = GetColorDepth(pScanConfiguration);
			If Not IsBlankString(vColorDepthCode) Then
				If vScObj.SetParam("PixelType", vColorDepthCode) = 0 Then
					Raise NStr("en='Failed to set color depth!';ru='Не удалось установить глубину цвета!';de='Die Farbentiefe konnte nicht festgelegt werden!'");
				EndIf;
			EndIf;
			// Set scan resolution to 300 dpi
			If vScObj.SetParam("XResolution", 300) = 0 Then
				Raise NStr("en='Failed to set X resolution to 300 dpi!';ru='Не удалось установить разрешение по оси X в 300 dpi!';de='Die Auflösung der X-Achse im 300 dpi nicht eingestellt!'");
			EndIf;
			If vScObj.SetParam("YResolution", 300) = 0 Then
				Raise NStr("en='Failed to set Y resolution to 300 dpi!';ru='Не удалось установить разрешение по оси Y в 300 dpi!';de='Die Auflösung der Y-Achse im 300 dpi nicht eingestellt!'");
			EndIf;
			// Scan document
			vPictFileName = GetTempFileName();
			vScObj.GetBMPFile(vPictFileName);
			ConvertImage(vPictFileName + ".jpg", vPictFileName, vScObj);
			pPictureStorage = New ValueStorage(New Picture(vPictFileName + ".jpg"));
			Try
				DeleteFiles(vPictFileName);
				DeleteFiles(vPictFileName + ".jpg");
			Except
			EndTry;
			// Return success
			Return True;
		Except
			rMessage = ErrorDescription();
			ProcessException(vScObj, NStr("en='ImageScannerDriver.ScanDocument';ru='СканерИзображений.СканироватьДокумент';de='ImageScannerDriver.ScanDocument'"), rMessage);
		EndTry;
	EndIf;
	Return False;
EndFunction // pmScanDocument

// -----------------------------------------------------------------------------
Function pmRecognizeDocument(pClientDataScansObj, rMessage, pScObj = Undefined, pDummy = Undefined) Export
	rMessage = NStr("en='Image recognition feature is not supported by this driver!';ru='Функция распознавания изображений не поддерживается выбранным драйвером!';de='Die Bilderkennungsfunktion wird vom ausgewählten Treiber nicht unterstützt!'");
	Return False;
EndFunction // pmRecognizeDocument
