
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareDriver	 - CatalogRef.HardwareDrivers	 - Hardware driver
//
Async Function InstallDriverAsync(pHardwareDriver) Export
	Return InstallAddInAsync(tcConnectedHardwareOnClientServer.GetHardwareDriverURL(pHardwareDriver));
EndFunction // InstallDriverAsync

// --------------------------------------------------------------------------------
//
// Parameters:
//  pUUID	 - UUID, Undefined	 - UUID form
// 
// Returns:
//  String - Result
//
Async Function LoadHardwareDriver(pUUID = Undefined) Export
	vPutFilesDialogParameters = New PutFilesDialogParameters(NStr("en = 'File driver'; de = 'Filel Draivera'; ru = 'Файл драйвера'"), False, "zip (*.zip)|*.zip", 0);
	
	vStoredFileDescription = Await PutFileToServerAsync( , , , vPutFilesDialogParameters, pUUID);
	If vStoredFileDescription = Undefined Or vStoredFileDescription.PutFileCanceled Then
		Return "";
	EndIf;
	
	Return vStoredFileDescription.Address;
EndFunction // LoadHardwareDriver

// --------------------------------------------------------------------------------
//  Connect barcode scanner
//
// Parameters:
//  pScannerSystemParameters - Structure	 - 
//  amRC					 - Driver	 - 
// 
// Returns:
//  Addin - Driver 
//
Function cmConnectScanner(pScannerSystemParameters, amRC) Export
	Try
		vErr = NStr("en='Error using barcodes scanner! Error code: ';ru='Ошибка работы с сканером штрихкодов! Код ошибки: ';de='Fehler bei der Arbeit mit dem Strichcodescanner! Fehlercode: '");
		// Create reader object  
		// ACC:561-off
		If pScannerSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.NativeDriver1C") Then
			vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pScannerSystemParameters.Ref);
			If vHardwareData = Undefined Then
				Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
			EndIf;
			
			vResultOperation = tcConnectedHardwareOnClientServer.ConnectHardware(vHardwareData);
			If Not vResultOperation.Result Then
				Raise vResultOperation.ErrorDescription;
			EndIf;
			Return New Structure("ScanData", "");
		ElsIf pScannerSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.RS232_1C") Then
			Try
				AttachAddIn("AddIn.Scanner");
				vScanner = New("AddIn.Scanner");
			Except
				LoadAddIn("ScanOPOS.dll");
				vScanner = New("AddIn.Scanner");
			EndTry;
		Else
			Try
				AttachAddIn("AddIn.Scaner45");
				vScanner = New("AddIn.Scaner45");
			Except
				LoadAddIn("Scaner1C.dll");
				vScanner = New("AddIn.Scaner45");
			EndTry;
		EndIf;
		// ACC:561-on
		RC_UNKNOWN = 99;
		RC_LOGICAL_DEVICE_NOT_FOUND = -9;
		// Set current logical device number
		vScanner.CurrentDeviceNumber = ?(pScannerSystemParameters.LogicalDeviceNumber = 0, 1, pScannerSystemParameters.LogicalDeviceNumber);
		If vScanner.ResultCode = RC_LOGICAL_DEVICE_NOT_FOUND Then
			vScanner.AddDevice();
			If CheckResult(vScanner, amRC, vErr) <> 0 Then
				Return Undefined;
			EndIf;  
			// Save logical device number
			tcOnServer.SaveLogicalDeviceNumber(pScannerSystemParameters.Ref, vScanner.CurrentDeviceNumber);
		ElsIf CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Do not lock logical devices
		vScanner.LockDevices = 0;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;  
		
		// Set scanner connection parameters
		vScanner.Model = 0;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Port
		vPortNumber = 1;
		If Not IsBlankString(pScannerSystemParameters.Port) Then
			vPortNumber = Number(Mid(TrimAll(pScannerSystemParameters.Port), 4));
		EndIf;
		vScanner.PortNumber = vPortNumber;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Baud rate
		vBaudRate = 7;
		If pScannerSystemParameters.BaudRate > 0 Then
			If pScannerSystemParameters.BaudRate = 1200 Then
				vBaudRate = 3;
			ElsIf pScannerSystemParameters.BaudRate = 2400 Then
				vBaudRate = 4;
			ElsIf pScannerSystemParameters.BaudRate = 4800 Then
				vBaudRate = 5;
			ElsIf pScannerSystemParameters.BaudRate = 9600 Then
				vBaudRate = 7;
			EndIf;
		EndIf;
		vScanner.BaudRate = vBaudRate;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop flag
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Data bits
		vDataBits = 4;
		If ValueIsFilled(pScannerSystemParameters.DataBits) Then
			If pScannerSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits7") Then
				vDataBits = 3;
			ElsIf pScannerSystemParameters.DataBits = PredefinedValue("Enum.DataBits.Bits8") Then
				vDataBits = 4;
			EndIf;
		EndIf;
		vScanner.DataBits = vDataBits;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Parity
		vParity = 0;
		If ValueIsFilled(pScannerSystemParameters.Parity) Then
			If pScannerSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Even") Then
				vParity = 2;
			ElsIf pScannerSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Odd") Then
				vParity = 1;
			ElsIf pScannerSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.None") Then
				vParity = 0;
			ElsIf pScannerSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Mark") Then
				vParity = 3;
			ElsIf pScannerSystemParameters.Parity = PredefinedValue("Enum.ParityTypes.Space") Then
				vParity = 4;
			EndIf;
		EndIf;
		vScanner.Parity = vParity;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		// Stop bits
		vStopBits = 0;
		If ValueIsFilled(pScannerSystemParameters.StopBits) Then
			If pScannerSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits1") Then
				vStopBits = 0;
			ElsIf pScannerSystemParameters.StopBits = PredefinedValue("Enum.StopBits.Bits2") Then
				vStopBits = 2;
			EndIf;
		EndIf;
		vScanner.StopBits = vStopBits;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;
		
		// Prefix and suffix
		vScanner.Prefix = GetCharsFromCodes(pScannerSystemParameters.Prefix);
		vScanner.Suffix = GetCharsFromCodes(pScannerSystemParameters.Suffix);
		
		// Set scanner object properties
		vScanner.DataEventEnabled = 1;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;  
		vScanner.OldVersion = 0;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;  
		vScanner.AutoDisable = 1;
		If CheckResult(vScanner, amRC, vErr) <> 0 Then
			Return Undefined;
		EndIf;  
		// Switch scanner on
		If vScanner.DeviceEnabled = 0 Then
			vScanner.DeviceEnabled = 1;
			If CheckResult(vScanner,amRC, vErr) <> 0 Then
				Return Undefined;
			EndIf;  
		EndIf;
		// Clear events
		If vScanner.DataCount > 0 Then
			vScanner.DeleteEvent();
			vScanner.DataEventEnabled = 1;
		EndIf; 
	Except 
		tcOnServer.AddError(amRC, RC_UNKNOWN, NStr("en = 'Barcodes scanner connection error: '; 
												  |de = 'Fehler beim Anschluss des Strichcodelesers: '; 
												  |ru = 'Ошибка подключения сканера штрихкодов: '") + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	
	Return vScanner;
EndFunction // ConnectScanner

// --------------------------------------------------------------------------------
Procedure cmDisconnectScanner(pScannerSystemParameters, amRC) Export
	RC_UNKNOWN = 99;
	#IF Not ThickClientOrdinaryApplication THEN
		Try
			If pScannerSystemParameters.CardReaderType = PredefinedValue("Enum.CardReaderTypes.NativeDriver1C") Then
				vHardwareData = tcConnectedHardwareOnServer.GetDataDevices(pScannerSystemParameters.Ref);
				If vHardwareData = Undefined Then
					Raise NStr("en = 'Error getting hardware parameters'; de = 'Fehler beim Abrufen der Hardwareparameter'; ru = 'Ошибка получения параметров оборудования'");
				EndIf;
				
				tcConnectedHardwareOnClientServer.DisconnectHardware(vHardwareData, True);
			Else
				If amBarcodesScanner = Undefined Then
					Return;
				EndIf;
				
				amBarcodesScanner.CurrentDeviceNumber = ?(pScannerSystemParameters.LogicalDeviceNumber = 0, 1, pScannerSystemParameters.LogicalDeviceNumber);
				amBarcodesScanner.DeviceEnabled = 0;
			EndIf;
		Except
			tcOnServer.AddError(amRC, RC_UNKNOWN, NStr("en='Barcodes scanner disconnect error: ';ru='Ошибка отключения сканера штрихкодов: ';de='Fehler beim Abschalten des Strichcodelesers:'") + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EndTry;
	#EndIf
EndProcedure // DisconnectScanner

// --------------------------------------------------------------------------------
//  Process the scanner input result
//
// Parameters:
//  pValue	 - String	 - String
//
Procedure ProcessScannerInputResult(pValue) Export
	If Not StrLen(pValue) = 36 Then
		Return;
	EndIf;	
	// Get Reservation
	vReservation = tcOnServer.GetDocumentRefByUUID("Reservation",pValue);
	If Not ValueIsFilled(vReservation) Then
		ShowMessageBox(,NStr("en='Clients are not found';ru='Гости не найдены';de='Kunden nicht gefunden'"));
		Return;
	EndIf;
	
	vCheckInDate = tcOnServer.cmGetAttributeByRef(vReservation, "CheckInDate");
	vResStatusArr =  tcOnServer.cmGetAtributeAsArray(tcOnServer.cmGetAttributeByRef(vReservation, "ReservationStatus"));
	
	vErr = "";
	If vResStatusArr.IsCheckIn Then
		vErr = NStr("ru='Гость уже заехал.'; en='Guest have already checked-in'; de='Gäste haben bereits eingecheckt'");
		Return;
	ElsIf vResStatusArr.IsAnnulation Then
		vErr = NStr("ru='Бронь была аннулирована'; en='Reservation is canceled'; de='Reservierung storniert'");
	ElsIf BegOfDay(vCheckInDate) <> BegOfDay(tcOnServer.cmGetServerCurrentSessionDate()) Then
		vErr = NStr("ru='Дата заезда не совпадает с текущей датой'; en='Check-in date is not the same as the current date'; de='Check-in-Datum ist nicht das gleiche wie das aktuelle Datum'");
	EndIf;
	
	If Not IsBlankString(vErr) Then
		ShowMessageBox(,vErr);
		Return;
	EndIf;	
	
	OpenForm("CommonForm.tcExpressCheckInForm", New Structure("Key", vReservation));
EndProcedure	

// --------------------------------------------------------------------------------
// Function - Get external event result
//
// Parameters:
//  pSource	 - String - Event Source 
//  pEvent	 - String - Event input device
//  pData	 - String - Data input device
// 
// Returns:
//  String - Result of reading from input device 
//
Function cmGetExternalEventResultInputDevice(pSource, pEvent, pData) Export
	vEventData = New Structure("Source, Event, Data, DeviceType, DeviceData", pSource, pEvent, pData, "Unknown", "");
	#IF NOT MobileClient THEN
		If pSource = "MagneticStripeCardReader" Or IsRFIDReaderExternalEvent(pSource) Then
			If pEvent = "MagneticStripeCardValue" Or IsRFIDReaderExternalEvent(pEvent) Then
				If amReaderMC <> Undefined Then
					// Retrieve track 2 data
					#IF ThickClientOrdinaryApplication THEN
						vCard = amIdentityCardSystemDriver.pmGetTrack2(amReaderMC);
					#ELSIF ThinClient Or WebClient Or ThickClientManagedApplication THEN
						vCard = tcOnClient.GetTrack2(amReaderMC, amIdentityCardsProcessing);
					#ENDIF
					
					vEventData.DeviceType = GetDeviceTypeByEvent("TracksData");
					vEventData.DeviceData = TrimAll(GetCardIdentifier(vCard));
					
					// Delete event
					amReaderMC.DeleteEvent();
					amReaderMC.DataEventEnabled = 1;
				EndIf;
			EndIf;
		ElsIf pSource = "BarCodeScaner" Then
			If pEvent = "BarCodeValue" Then
				#IF ThickClientOrdinaryApplication THEN
					If amReaderMC <> Undefined Then
						vCard = amBarcodesScannerDriver.pmGetScanData(amReaderMC);
						
						vEventData.DeviceType = GetDeviceTypeByEvent("Barcode");
						vEventData.DeviceData = TrimAll(GetCardIdentifier(vCard));
						
						// Delete event
						amReaderMC.DeleteEvent();
						amReaderMC.DataEventEnabled = 1;
					EndIf;
				#ELSIF ThinClient Or WebClient Or ThickClientManagedApplication THEN
					If amBarcodesScanner <> Undefined Then
						vEventData.DeviceType = GetDeviceTypeByEvent("Barcode");
						vEventData.DeviceData = TrimAll(GetCardIdentifier(amBarcodesScanner.ScanData));
						
						// Delete event
						amBarcodesScanner.DeleteEvent();
						amBarcodesScanner.DataEventEnabled = 1;
					EndIf;
				#ENDIF
			EndIf;
		Else
			For Each vHardwarePersistentObjectRow In amHardwarePersistentObjects Do
				vHardware = vHardwarePersistentObjectRow.Value;
				If vHardware.DeviceID <> pSource Then
					Continue;
				EndIf;
				
				vEventData.DeviceType = GetDeviceTypeByEvent(pEvent);
				If StrFind(pEvent, "Base64") > 0 Then
					vEventData.DeviceData = GetCardIdentifier(GetStringFromBinaryData(GetBinaryDataFromBase64String(pData), TextEncoding.UTF8));
				Else
					vEventData.DeviceData = GetCardIdentifier(TrimAll(pData));
				EndIf;
				Break;
			EndDo;
		EndIf;
	#ENDIF
	Return vEventData;
EndFunction // GetExternalEventResultInputDevice

// --------------------------------------------------------------------------------
Function GetCardIdentifier(pCardData) Export 
	vCardID = pCardData;
	If StrLen(pCardData) > 3 Then
		// Remove prefix and suffix chars
		If Right(pCardData, 3) = "+++" Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 3);
		ElsIf Right(pCardData, 2) = "?," Then
			vCardID = Mid(TrimAll(pCardData), 2);
			vCardID = Left(vCardID, StrLen(vCardID) - 2);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 1110 And CharCode(Mid(pCardData, 2, 1)) = 59 And CharCode(Mid(pCardData, 15, 1)) = 58 Then
			vCardID = Mid(pCardData, 3, 12);
		ElsIf CharCode(Left(pCardData, 1)) = 186 And CharCode(Mid(pCardData, 14, 1)) = 191 Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Left(pCardData, 1) = ";" And Mid(pCardData, 14, 1) = "?" Then
			vCardID = Mid(pCardData, 2, 12);
		ElsIf Upper(Right(pCardData, 7)) = "NO CARD" And StrLen(TrimAll(pCardData)) > 7 Then
			vCardID = TrimAll(Left(TrimAll(pCardData), StrLen(TrimAll(pCardData)) - 7));
		ElsIf StrFind(vCardID, "Mifare[") > 0 Then
			vCardID = TrimAll(Right(vCardID, StrLen(vCardID) - StrFind(vCardID, "Mifare[") - 6));
		EndIf;
	Else
		vCardID = "";
	EndIf;
	Return vCardID;
EndFunction // GetCardIdentifier

#EndRegion

#Region Private

// ------------------------------------------------------------------------------
Function CheckResult(pDevice,amRC, pError)
	vResultCode = pDevice.ResultCode;
	vResultDescription = pDevice.ResultDescription;
	If vResultCode <> 0 Then
		tcOnServer.AddError(amRC,vResultCode, pError + TrimAll(vResultDescription));
	EndIf;
	Return vResultCode;
EndFunction // CheckResult

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
EndFunction // GetCharsFromCodes

// -----------------------------------------------------------------------------
Function IsRFIDReaderExternalEvent(pStr) 
	If Lower(pStr) = "ironlogic z-2" Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // IsRFIDReaderExternalEvent

// --------------------------------------------------------------------------------
Function GetDeviceTypeByEvent(pEvent)
	vDeviceType = "";
	If pEvent = "Штрихкод" Or pEvent = "ШтрихкодBase64" Or pEvent = "Barcode" Or pEvent = "BarcodeBase64" Then
		vDeviceType = "BarCodeScaner";
	ElsIf pEvent = "ДанныеКарты" Or pEvent = "ДанныеКартыBase64" Or pEvent = "TracksData" Or pEvent = "TracksDataBase64" Then
		vDeviceType = "MagneticStripeCardReader";
	ElsIf  pEvent = "НажатиеКлавиши" Or pEvent = "KeyPress" Then
		vDeviceType = "Keyboard";
	Else
		vDeviceType = "Unknown";
	EndIf;
	Return vDeviceType;
EndFunction // GetDeviceTypeByEvent

#EndRegion
