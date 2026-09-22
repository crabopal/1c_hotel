
#Region Public

// -----------------------------------------------------------------------------
//  Function - Get images scanner driver module
//
// Parameters:
//  pMsg - String	 - The string to which the error message is written.
//  pRef - 			 - 
// 
// Returns:
//  CommonModule - or Undefined
//
Function cmGetImagesScannerDriverModule(pMsg = "", pRef = Undefined) Export
	vModule = "";
	If pRef = Undefined Then
		// Check parameters
		vWstn = SessionParameters.CurrentWorkstation;
		If Not ValueIsFilled(vWstn) 
			Or Not vWstn.HasConnectionToImagesScanner
			Or Not ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
			pMsg =  NStr("en = 'No scanning devices connected'; 
						 |de = 'Keine Scangeräte angeschlossen'; 
						 |ru = 'Нет подключенных устройств сканирования'");
			Return Undefined;
		EndIf;
		pRef = vWstn.ImagesScannerConnectionParameters;
	EndIf;
	Try
		If pRef.ImageScannerDriver = Enums.ImageScannerDrivers.CognitiveScanifyAPI Then
			vModule = "tcCognitiveImageScannerDriver";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.AbbyyPassportReaderSDKEngine Then
			vModule = "tcPassportReaderImageScannerDriver";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.ContentAIPassportReaderSDKEngine Then
			vModule = "tcPassportReaderImageScannerDriver";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.SmartPassportBoxEngine Then
			vModule = "tcSmartPassportBoxEngine";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.SmartPassportBoxEngineREST Then
			vModule = "tcSmartPassportBoxEngineREST";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.Scan1C Then
			vModule = "tcScan1C";
		ElsIf pRef.ImageScannerDriver = Enums.ImageScannerDrivers.Regula Then
			vModule = "tcRegula";
		Else
			pMsg = NStr("en = 'Unknown equipment type: '; de = 'Unbekannter Gerätetyp: '; ru = 'Неизвестный тип оборудования: '") + pRef.ImageScannerDriver;
			Return Undefined;
		EndIf;
	Except
		Return Undefined;
	EndTry;
	Return vModule;
EndFunction // GetImagesScannerDriverDataProcessor

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMsg - String	 - The string to which the error message is written.
// 
// Returns:
//  CommonModule - or Undefined
//
Function cmGetWebCamDriverModule(pMsg = "") Export
	// Check parameters
	vWstn = SessionParameters.CurrentWorkstation;
	If Not ValueIsFilled(vWstn) Then
		pMsg = NStr("en = 'Not specified workplace'; de = 'Nicht spezifizierter Arbeitsplatz'; ru = 'Не указано рабочее место'");
		Return Undefined;
	EndIf;
	If Not vWstn.HasConnectionToWEBCamera Or Not ValueIsFilled(vWstn.WEBCamConnectionParameters) Then
		pMsg = NStr("en = 'No scanning devices connected'; de = 'Keine Scangeräte angeschlossen'; ru = 'Нет подключенных устройств сканирования'");
		Return Undefined;
	EndIf;
	Return "tcWebCamDriver";
EndFunction // GetWebCamDriverModule

// -----------------------------------------------------------------------------
//  Get images scanner parameters
//
// Parameters:
//  pParam	 - String	 - Name attribute.
//  rMassege - String	 - The string to which the error message is written.
// 
// Returns:
//  Value - Images scanner parameter
//
Function cmGetImagesScannerParameters(pParam, rMassege = "") Export
	vConnParams = Undefined;
	If ValueIsFilled(SessionParameters.CurrentWorkstation) Then
		vWstn = SessionParameters.CurrentWorkstation;
		If vWstn.HasConnectionToImagesScanner And ValueIsFilled(vWstn.ImagesScannerConnectionParameters) Then
			vWstnConnParams = vWstn.ImagesScannerConnectionParameters;
			vConnParams = vWstnConnParams[pParam];
		EndIf;
	EndIf;
	Return vConnParams;
EndFunction // GetImagesScannerParameters

// -----------------------------------------------------------------------------
//  Get images scanner parameters
//
// Parameters:
//  pParam			 - String	 - attribute name whose value is to be obtained.
//  pAttributeName	 - String	 - the name of the element`s attribute for which you need to get the CatalogRef.
//  pAttribute		 - String	 - the value of the element`s attribute for which you need to get the CatalogRef.
//  rMessage		 - 			 - 
// 
// Returns:
//  Value - Images scanner parameter
//
Function cmGetImagesScannerParametersByAttribute(pParam, pAttributeName, pAttribute, rMessage = "") Export
	vConnParams = Undefined;
	If pAttribute = "Scan1C" Then
		vAttrVal = Enums.ImageScannerDrivers.Scan1C;
	ElsIf pAttribute = "SmartPassportBoxEngine" Then
		vAttrVal = Enums.ImageScannerDrivers.SmartPassportBoxEngine;
	ElsIf pAttribute = "SmartPassportBoxEngineREST" Then
		vAttrVal = Enums.ImageScannerDrivers.SmartPassportBoxEngineREST;
	ElsIf pAttribute = "CognitiveScanifyAPI" Then
		vAttrVal = Enums.ImageScannerDrivers.CognitiveScanifyAPI;
	ElsIf pAttribute = "AbbyyPassportReaderSDKEngine" Then
		vAttrVal = Enums.ImageScannerDrivers.AbbyyPassportReaderSDKEngine;
	ElsIf pAttribute = "Regula" Then
		vAttrVal = Enums.ImageScannerDrivers.Regula;
	ElsIf pAttribute = "ContentAIPassportReaderSDKEngine" Then
		vAttrVal = Enums.ImageScannerDrivers.ContentAIPassportReaderSDKEngine;
	EndIf;
	
	vWstnConnParams = tcOnServer.cmGetCatalogItemRefByAttribute("ImageScannerConnectionParameters", pAttributeName, False, vAttrVal);
	If Not ValueIsFilled(vWstnConnParams) Then
		Raise (StrTemplate(NStr("en = 'The parameter for connecting image scanners for %1 was not found!'; 
								|de = 'Der Parameter zum Anschließen von Bildscannern für %1 wurde nicht gefunden'; 
								|ru = 'Не найден параметр подключения сканеров изображений для %1!'"), pAttribute));
	EndIf;
	vConnParams = vWstnConnParams[pParam];
		
	Return vConnParams;
EndFunction // GetImagesScannerParametersByAttribute

// -----------------------------------------------------------------------------
//  Gets connection hardware for workstation
//
// Parameters:
//  qWorkstation - 	 - CatalogRef.Workstations - Ref on catalog workstation
//  	If qWorkstation = undefined, then return connection hardware for current workstation
// 
// Returns:
//  Structure - Structure hardware or empty structure, if didn't was found workstation
//
Function GetConnectionHardware(qWorkstation = Undefined) Export
	vCH = New Structure("DoorLockSystemParameters,
						|CreditCardsProcessingSystemParameters,
						|IdentityCardsProcessingSystemParameters,
						|RibbonPrinterConnectionParameters,
						|BarcodesScannerConnectionParameters,
						|ImagesScannerConnectionParameters,
						|WEBCamConnectionParameters,
						|AdobeReaderParameters,
						|CashRegisters,
						|SimpleCalls"); 
	
	vWstn = qWorkstation;
	If vWstn = Undefined Then
		vWstn = SessionParameters.CurrentWorkstation;
	EndIf;	
	
	If Not vWstn = Undefined Then 
		FillHardware(vCH, "HasConnectionToDoorLockSystem", 				 "DoorLockSystemParameters", 				vWstn);
		FillHardware(vCH, "HasConnectionToCreditCardsProcessingSystem",  "CreditCardsProcessingSystemParameters", 	vWstn);
		FillHardware(vCH, "HasConnectionToIdentityCardsProcessingSystem","IdentityCardsProcessingSystemParameters", vWstn);
		FillHardware(vCH, "HasConnectionToRibbonPrinter", 				 "RibbonPrinterConnectionParameters", 		vWstn);
		FillHardware(vCH, "HasConnectionToBarcodesScanner", 			 "BarcodesScannerConnectionParameters", 	vWstn);
		FillHardware(vCH, "HasConnectionToImagesScanner", 				 "ImagesScannerConnectionParameters", 		vWstn);
		FillHardware(vCH, "HasConnectionToWEBCamera", 					 "WEBCamConnectionParameters", 				vWstn);
		FillHardware(vCH, "HasConnectionToAdobeReader", 				 "AdobeReaderParameters", 					vWstn);
		FillHardware(vCH, "HasConnectionCashRegisters", 				 "CashRegisters", 							vWstn);
		FillHardware(vCH, "HasConnectionToSimpleCalls", 				 "SimpleCalls", 							vWstn);
	EndIf;	
	Return vCH;
EndFunction // GetWorkstationEquipment

// --------------------------------------------------------------------------------
//
// Parameters:
//  pInteractionParameter	 - CatalogRef.ExternalSystemInteractions - Ref
// 
// Returns:
//  Boolean - True or False
//
Function CheckActiveInteractionYandexVision(pInteractionParameter) Export
	If ValueIsFilled(pInteractionParameter) And pInteractionParameter.IsActive 
		And pInteractionParameter.IntegrationType = Enums.Integrations.YandexVision Then
		Return True;
	EndIf;
	
	Return False;
EndFunction // CheckInteractionParameterByImageScanner

// -------------------------------------------------------------------------
//  Get scan configuration by it's external code
//
// Parameters:
//  pExtCode - String	 - Configuration external code (dType or ID for Regula)
// 
// Returns:
//  CatalogRef.ScanConfigurations, Undefined - Scan configuration or undefined if not found
//
Function GetScanConfigurationByExternalCode(pExtCode) Export
	Return Catalogs.ScanConfigurations.GetScanConfigurationByExternalCode(pExtCode);
EndFunction // GetScanConfigurationByIDOrType

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Procedure FillHardware(pHardware, pHasConnectionName, pDeviceAttributeName, pWorkstation)
	If pHasConnectionName <> "HasConnectionToSimpleCalls" Then
		vHWRef = pWorkstation[pDeviceAttributeName];
		If pHasConnectionName = "HasConnectionCashRegisters" Then
			// Fill cash registers
			vCashRegisters = vHWRef;
			If vCashRegisters.Count() > 0 Then
				vListCashRegisters = New Array;
				For Each vRow In vCashRegisters Do
					vHWRef = vRow.CashRegister;
					If ValueIsFilled(vHWRef) Then
						vListCashRegisters.Add(tcOnServer.cmGetAtributeAsArray(vHWRef));
					EndIf;	
				EndDo;
				If vListCashRegisters.Count() > 0 Then
					pHardware[pDeviceAttributeName] = New Structure("CashRegisters, HasConnection", vListCashRegisters, True);
				Else
					pHardware[pDeviceAttributeName] = New Structure("HasConnection", False);
				EndIf;	
			Else
				pHardware[pDeviceAttributeName] = New Structure("HasConnection", False);
			EndIf;	
		ElsIf pWorkstation[pHasConnectionName] And ValueIsFilled(vHWRef) Then
			// Fill other Hardware
			pHardware[pDeviceAttributeName] = tcOnServer.cmGetAtributeAsArray(vHWRef);
			pHardware[pDeviceAttributeName].Insert("HasConnection", True);
		Else
			// Set value "not connected"
			pHardware[pDeviceAttributeName] = New Structure("HasConnection", False);	
		EndIf;	
	Else
		pHardware[pDeviceAttributeName] = New Structure("HasConnection, WorkStationAlreadyRun, Workstation", pWorkstation[pHasConnectionName], pWorkstation["WorkStationAlreadyRun"], pWorkstation);	
	EndIf;
EndProcedure // FillHardware()

#EndRegion
