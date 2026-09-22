
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	BarcodesScannerConnectionParameter = Parameters.BarcodesScannerConnectionParameter;
	If Not ValueIsFilled(BarcodesScannerConnectionParameter) Then
		pCancel = True;
		Return;
	EndIf;
	
	vParametersBarcode = New Structure; 
	vParametersBarcode.Insert("CodeType", 16);
	vParametersBarcode.Insert("Barcode", "https://1c-hotel.ru/");
	vParametersBarcode.Insert("InPixels", True);
	vParametersBarcode.Insert("Width", 250);
	vParametersBarcode.Insert("Height", 250);
	vParametersBarcode.Insert("TextVisible", True);
	QRCode = PutToTempStorage(tcSystemBarcodePrinterDriver.pmGetPictureCode(vParametersBarcode), UUID);
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	#IF Not ThickClientOrdinaryApplication THEN
		vRC = New Map;
		vBarcodesScannerConnectionParameter = tcOnServer.cmGetAtributeAsArray(BarcodesScannerConnectionParameter);
		
		tcConnectionHardwareAtClient.cmDisconnectScanner(vBarcodesScannerConnectionParameter, vRC);
		amBarcodesScanner = Undefined;
		amBarcodesScanner = tcConnectionHardwareAtClient.cmConnectScanner(vBarcodesScannerConnectionParameter, vRC);
		If amBarcodesScanner = Undefined Then
			vErrorCode = vRC.Get("RC_CODE");
			vErrorDescription = vRC.Get(vErrorCode);
			vMessage = StrTemplate(NStr("en = 'Error connecting to barcodes scanner! Error code: %1. Error description: %2'; 
										|de = 'Fehler beim Verbinden mit dem Barcode-Scanner! Fehlercode: %1. Fehlerbeschreibung: %2'; 
										|ru = 'Ошибка подключения сканера штрихкодов! Код ошибки: %1. Описание ошибки: %2'", CurrentSystemLanguage()),
										vErrorCode, vErrorDescription);
			tcCommonFunctionOnClientServer.UserMessage(vMessage);
			pCancel = True;
			Return;
		EndIf;
	#EndIf
EndProcedure // OnOpen

// --------------------------------------------------------------------------------
&AtClient
Procedure ExternalEvent(pSource, pEvent, pData)
	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	vEventData = tcConnectionHardwareAtClient.cmGetExternalEventResultInputDevice(pSource, pEvent, pData);
	If IsBlankString(vEventData.DeviceData) Then
		Return;
	EndIf;
	
	If vEventData.DeviceType = "BarCodeScaner" Then
		BarCode = vEventData.DeviceData;
	EndIf;
EndProcedure // ExternalEvent

#EndRegion