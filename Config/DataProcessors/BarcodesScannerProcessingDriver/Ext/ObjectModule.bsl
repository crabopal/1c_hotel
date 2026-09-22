
#Region Variables

// -----------------------------------------------------------------------------
Var RC;
Var RC_CODE; // Last error code
Var RC_OK Export; // Ok
Var RC_UNKNOWN;
Var RC_LOGICAL_DEVICE_NOT_FOUND;

#EndRegion   

#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  rErrorDescription	 - String - Error description 
// 
// Returns:
//  String -Error code 
//
Function pmGetLastError(rErrorDescription = "") Export
	vErrorDescription = RC.Get(RC_CODE);
	If vErrorDescription = Undefined Then
		rErrorDescription = "";
	Else
		rErrorDescription = vErrorDescription;
	EndIf;
	Return RC_CODE;
EndFunction //  pmGetLastError

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScanner - ComObject - Device driver
// 
// Returns:
//  ComObject - Device driver
//
Function pmConnect(pScanner = Undefined) Export
	Try
		If Not ValueIsFilled(BarcodesScannerConnectionParameters) Then
			Raise NStr("en='Barcodes scanner connection parameters are not set!';ru='Не установлены параметры подключения сканера штрихкодов!';de='Parameter fürs Anschließen des Strichcode-Scanners sind nicht festgelegt!'");
		EndIf;
		
		// Create reader object
		If pScanner = Undefined Then
			#IF CLIENT THEN
				Try
					AttachAddIn("AddIn.Scaner45");
					vScanner = New("AddIn.Scaner45");
				Except
					LoadAddIn("Scaner1C.dll");
					vScanner = New("AddIn.Scaner45");
				EndTry;
			#ELSE
				vScanner = New("AddIn.Scaner45");
			#ENDIF
		Else
			vScanner = pScanner;
		EndIf;
		
		// Set current logical device number
		vScanner.CurrentDeviceNumber = ?(BarcodesScannerConnectionParameters.LogicalDeviceNumber = 0, 1, BarcodesScannerConnectionParameters.LogicalDeviceNumber);
		If vScanner.ResultCode = RC_LOGICAL_DEVICE_NOT_FOUND Then
			vScanner.AddDevice();
			If CheckResult(vScanner) <> 0 Then
				Return Undefined;
			EndIf;  
			// Save logical device number
			vPrmObj = BarcodesScannerConnectionParameters.GetObject();
			vPrmObj.LogicalDeviceNumber = vScanner.CurrentDeviceNumber;
			vPrmObj.Write();
		ElsIf CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Do not lock logical devices
		vScanner.LockDevices = 0;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;  
		
		// Set scanner connection parameters
		vScanner.Model = 0;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Port
		vPortNumber = 1;
		If Not IsBlankString(BarcodesScannerConnectionParameters.Port) Then
			vPortNumber = Number(Mid(TrimAll(BarcodesScannerConnectionParameters.Port), 4));
		EndIf;
		vScanner.PortNumber = vPortNumber;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Baud rate
		vBaudRate = 7;
		If BarcodesScannerConnectionParameters.BaudRate > 0 Then
			If BarcodesScannerConnectionParameters.BaudRate = 1200 Then
				vBaudRate = 3;
			ElsIf BarcodesScannerConnectionParameters.BaudRate = 2400 Then
				vBaudRate = 4;
			ElsIf BarcodesScannerConnectionParameters.BaudRate = 4800 Then
				vBaudRate = 5;
			ElsIf BarcodesScannerConnectionParameters.BaudRate = 9600 Then
				vBaudRate = 7;
			EndIf;
		EndIf;
		vScanner.BaudRate = vBaudRate;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop flag
		vScanner.StopFlag = 0;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Data bits
		vDataBits = 4;
		If ValueIsFilled(BarcodesScannerConnectionParameters.DataBits) Then
			If BarcodesScannerConnectionParameters.DataBits = Enums.DataBits.Bits7 Then
				vDataBits = 3;
			ElsIf BarcodesScannerConnectionParameters.DataBits = Enums.DataBits.Bits8 Then
				vDataBits = 4;
			EndIf;
		EndIf;
		vScanner.DataBits = vDataBits;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Parity
		vParity = 0;
		If ValueIsFilled(BarcodesScannerConnectionParameters.Parity) Then
			If BarcodesScannerConnectionParameters.Parity = Enums.ParityTypes.Even Then
				vParity = 2;
			ElsIf BarcodesScannerConnectionParameters.Parity = Enums.ParityTypes.Odd Then
				vParity = 1;
			ElsIf BarcodesScannerConnectionParameters.Parity = Enums.ParityTypes.None Then
				vParity = 0;
			ElsIf BarcodesScannerConnectionParameters.Parity = Enums.ParityTypes.Mark Then
				vParity = 3;
			ElsIf BarcodesScannerConnectionParameters.Parity = Enums.ParityTypes.Space Then
				vParity = 4;
			EndIf;
		EndIf;
		vScanner.Parity = vParity;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop bits
		vStopBits = 0;
		If ValueIsFilled(BarcodesScannerConnectionParameters.StopBits) Then
			If BarcodesScannerConnectionParameters.StopBits = Enums.StopBits.Bits1 Then
				vStopBits = 0;
			ElsIf BarcodesScannerConnectionParameters.StopBits = Enums.StopBits.Bits2 Then
				vStopBits = 2;
			EndIf;
		EndIf;
		vScanner.StopBits = vStopBits;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Prefix and suffix
		vScanner.Prefix = GetCharsFromCodes(BarcodesScannerConnectionParameters.Prefix);
		vScanner.Suffix = GetCharsFromCodes(BarcodesScannerConnectionParameters.Suffix);
		
		// Set scanner object properties
		vScanner.DataEventEnabled = 1;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;  
		vScanner.OldVersion = 0;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;  
		vScanner.AutoDisable = 1;
		If CheckResult(vScanner) <> 0 Then
			Return Undefined;
		EndIf;  
		
		// Switch scanner on
		If vScanner.DeviceEnabled = 0 Then
			vScanner.DeviceEnabled = 1;
			If CheckResult(vScanner) <> 0 Then
				Return Undefined;
			EndIf;  
		EndIf;
		// Clear events
		If vScanner.DataCount > 0 Then
			vScanner.DeleteEvent();
			vScanner.DataEventEnabled = 1;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Barcodes scanner connection error: ';ru='Ошибка подключения сканера штрихкодов: ';de='Fehler beim Anschluss des Strichcodelesers: '") + ErrorDescription());
		Return Undefined;
	EndTry;
	Return vScanner;
EndFunction //  pmConnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScanner - ComObject - Device driver 
//
Procedure pmDisconnect(pScanner) Export
	Try
		If pScanner <> Undefined Then
			pScanner.CurrentDeviceNumber = ?(BarcodesScannerConnectionParameters.LogicalDeviceNumber = 0, 1, BarcodesScannerConnectionParameters.LogicalDeviceNumber);
			pScanner.DeviceEnabled = 0;
		EndIf;
	Except
		AddError(RC_UNKNOWN, NStr("en='Barcodes scanner disconnect error: ';ru='Ошибка отключения сканера штрихкодов: ';de='Fehler beim Abschalten des Strichcodelesers:'") + ErrorDescription());
	EndTry;
EndProcedure //  pmDisconnect

// -----------------------------------------------------------------------------
//
// Parameters:
//  pScanner - ComObject - Device driver
// 
// Returns:
//  String - Scan data 
//
Function pmGetScanData(pScanner) Export
	pScanner.CurrentDeviceNumber = ?(BarcodesScannerConnectionParameters.LogicalDeviceNumber = 0, 1, BarcodesScannerConnectionParameters.LogicalDeviceNumber);
	vScanData = TrimAll(pScanner.ScanData);
	Return vScanData;
EndFunction //  pmGetScanData

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure AddError(pErrorCode, pErrorText)
	RC_CODE = pErrorCode;
	RC.Insert(pErrorCode, pErrorText);
	WriteLogEvent(NStr("en='BarcodesScannerDriver.Error';ru='ДрайверСканераШтрихкодов.Ошибка';de='BarcodesScannerDriver.Error'"), EventLogLevel.Warning, , , pErrorText);
EndProcedure //  AddError

// ------------------------------------------------------------------------------
Function CheckResult(pScanner)
	RC_CODE = RC_OK;
	vResultCode = pScanner.ResultCode;
	vResultDescription = pScanner.ResultDescription;
	If vResultCode <> RC_OK Then
		AddError(vResultCode, NStr("en='Error using barcodes scanner! Error code: ';ru='Ошибка работы с сканером штрихкодов! Код ошибки: ';de='Fehler bei der Arbeit mit dem Strichcodescanner! Fehlercode: '") + TrimAll(vResultCode) + NStr("en=' Error description: ';ru=' Описание ошибки: ';de=' Fehlerbeschreibung: '") + TrimAll(vResultDescription));
	EndIf;
	Return vResultCode;
EndFunction //  CheckResult

// ------------------------------------------------------------------------------
Function GetCharsFromCodes(pStr) 
	vStr = "";
	If IsBlankString(pStr) Then
		Return vStr;
	EndIf;
	vPos = Find(pStr, "#");
	If vPos > 0 Then
		vStrCodes = TrimAll(Mid(pStr, vPos + 1));
		While vPos > 0 Do
			vPos = Find(vStrCodes, "#");
			If vPos = 0 Then
				vStr = vStr + Char(Number(vStrCodes));
			Else
				vStr = vStr + Char(Number(Left(vStrCodes, vPos - 1)));
				vStrCodes = TrimAll(Mid(vStrCodes, vPos + 1));
			EndIf;
		EndDo;
	Else
		vStr = TrimR(pStr);
	EndIf;
	Return vStr;
EndFunction //  GetCharsFromCodes

#EndRegion

#Region Initialize

// -----------------------------------------------------------------------------
// Initialize return codes map 
RC = New Map();
// Initialize return code constants
RC_OK = 0;
RC_CODE = RC_OK;
RC_UNKNOWN = 99; 
RC_LOGICAL_DEVICE_NOT_FOUND = -9;  

#EndRegion         



