
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pFileTempStorage - Strung	 - Temp storage address
//  rMessage		 - Strung	 - Error message
// 
// Returns:
//  Map, Undefined - Result
//
Function GetDataHardwareDriverFromFile(pFileTempStorage, rMessage) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.GetDataHardwareDriverFromFile(pFileTempStorage, rMessage);
	#Else
		vDataHardwareDriver = New Map;
		
		Try
			If Not IsTempStorageURL(pFileTempStorage) Then
				Raise NStr("en = 'Error reading file'; de = 'Fehler beim Lesen der Datei'; ru = 'Ошибка чтения файла'");
			EndIf;
			
			// BSLLS:MissingTempStorageDeletion-off
			vFileBinaryData = GetFromTempStorage(pFileTempStorage);
			If vFileBinaryData = Undefined Then
				Raise NStr("en = 'Error reading file'; de = 'Fehler beim Lesen der Datei'; ru = 'Ошибка чтения файла'");
			EndIf;
			// BSLLS:MissingTempStorageDeletion-on
			
			vStream = vFileBinaryData.OpenStreamForRead();
			
			vZipFileReader = New ZipFileReader(vStream);
			
			vInfoFile = vZipFileReader.Items.Find("INFO.XML");
			If vInfoFile = Undefined Then
				vZipFileReader.Close();
				vStream.Close();
				Raise NStr("en = 'INFO.XML file is missing'; de = 'Die Datei INFO.XML fehlt'; ru = 'Файл INFO.XML отсутствует'");
			EndIf;
			
			// BSLLS:UsingSynchronousCalls-off
			vTempFile = TempFilesDir() + "/" + TrimAll(New UUID());
			// BSLLS:UsingSynchronousCalls-on
			
			vZipFileReader.Extract(vInfoFile, vTempFile);
			vZipFileReader.Close();
			
			vStream.Close();
			
			vTextReader = New TextReader(vTempFile + "/" + "INFO.XML", TextEncoding.UTF8);
			
			vXMLReader = New XMLReader;
			vXMLReader.SetString(vTextReader.Read());
			vXMLReader.MoveToContent();
			
			If vXMLReader.Name = "drivers" And vXMLReader.NodeType = XMLNodeType.StartElement Then
				While vXMLReader.Read() Do
					If vXMLReader.Name = "component" And vXMLReader.NodeType = XMLNodeType.StartElement Then
						vProgID = TrimAll(vXMLReader.AttributeValue("progid"));
						vTypeName = TrimAll(vXMLReader.AttributeValue("type"));
						vDescription = TrimAll(vXMLReader.AttributeValue("name"));
						vDriverVersion = TrimAll(vXMLReader.AttributeValue("version"));
						
						vDataHardwareDriver.Insert("Description", vDescription);
						vDataHardwareDriver.Insert("ConnectedHardwareType", GetConnectedHardwareTypeByTypeName(vTypeName));
						vDataHardwareDriver.Insert("ObjectID", GetObjectIDByProgID(vProgID));
						vDataHardwareDriver.Insert("DriverVersion", vDriverVersion);
					EndIf;
				EndDo;
			EndIf;
			
			vXMLReader.Close();
			
			vTextReader.Close();
			
			// BSLLS:UsingSynchronousCalls-off
			DeleteFiles(vTempFile);
			// BSLLS:UsingSynchronousCalls-on
		Except
			rMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			vDataHardwareDriver = Undefined;
		EndTry;
		
		Return vDataHardwareDriver;
	#EndIf
EndFunction // GetDataHardwareDriverFromFile

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareDriver	 - CatalogRef.HardwareDrivers	 - Hardware driver
// 
// Returns:
//  String - Result
//
Function GetHardwareDriverURL(pHardwareDriver) Export
	Return tcOnServer.cmGetURL(pHardwareDriver, "Driver");
EndFunction // GetHardwareDriverURL

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardware	 - Arbitrary - Hardware
// 
// Returns:
//  Map - Result
//
Function GetDataDevices(pHardware) Export
	Return tcConnectedHardwareOnServer.GetDataDevices(pHardware);
EndFunction // GetDataDevices

// --------------------------------------------------------------------------------
// 
// Returns:
//  Number - Result
//
Function DriverInterfaceRevision() Export
	
	vInterfaceRevision = 4005;
	Return vInterfaceRevision;
	
EndFunction // DriverInterfaceRevision

// --------------------------------------------------------------------------------
//
// Parameters:
//  pType	 - String	 - Type
// 
// Returns:
//  EnumRef.ConnectedHardwareTypes - Result
//
Function GetConnectedHardwareTypeByTypeName(pType) Export
	vConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.EmptyRef");
	If pType = "POSTerminal" Or pType = "ЭквайринговыйТерминал" Then
		vConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.POSTerminal");
	ElsIf pType = "BarcodeScanner" Or pType = "СканерШтрихкода" Then
		vConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.BarcodeScanner");
	ElsIf pType = "CardReader" Or pType = "СчитывательМагнитныхКарт" Then
		vConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.CardReader");
	EndIf;
	Return vConnectedHardwareType;
EndFunction // GetConnectedHardwareTypeByTypeName

// --------------------------------------------------------------------------------
//
// Parameters:
//  pConnectedHardwareType	 - EnumRef.ConnectedHardwareTypes	 - Hardware types
// 
// Returns:
//  String - Result
//
Function GetTypeNameByConnectedHardwareType(pConnectedHardwareType) Export
	vType = "";
	If pConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.POSTerminal") Then
		vType = "ЭквайринговыйТерминал";
	ElsIf pConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.BarcodeScanner") Then
		vType = "СканерШтрихкода";
	ElsIf pConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.CardReader") Then
		vType = "СчитывательМагнитныхКарт";
	EndIf;
	Return vType;
EndFunction // GetTypeNameByConnectedHardwareType

// --------------------------------------------------------------------------------
//
// Parameters:
//  pProgID	 - String	 - ProgID
// 
// Returns:
//  String - Result
//
Function GetObjectIDByProgID(pProgID) Export
	Return TrimAll(StrReplace(pProgID, "AddIn.", ""));
EndFunction // GetObjectIDByProgId

// --------------------------------------------------------------------------------
//
// Parameters:
//  pParameters		 - Structure					 - Parameters
//  pHardwareType	 - EnumRef.ConnectedHardwareTypes	 - Hardware type
// 
// Returns:
//  String - Result
//
Function GetParametersXML(pParameters, pHardwareType = Undefined) Export
	#If WebClient Then
		vResult = tcConnectedHardwareOnServer.GetParametersXML(pParameters, pHardwareType);
	#Else
		vResult = "";
		If pParameters = Undefined Then
			Return vResult;
		EndIf;
		
		vXMLWriter = New XMLWriter;
		vXMLWriter.SetString("UTF-8");
		vXMLWriter.WriteXMLDeclaration();
		vXMLWriter.WriteStartElement("Parameters");
		
		If Not IsBlankString(pHardwareType) Then
			vXMLWriter.WriteStartElement("Parameter");
			vXMLWriter.WriteAttribute("Name", "EquipmentType");
			vXMLWriter.WriteAttribute("Value", GetTypeNameByConnectedHardwareType(pHardwareType));
			vXMLWriter.WriteEndElement();
		EndIf;
		
		vPrefixLength = 2;
		vBeginName = 3;
		For Each vParameter In pParameters Do
			If Left(vParameter.Key, vPrefixLength) <> "P_" Then
				Continue;
			EndIf;
			
			vXMLWriter.WriteStartElement("Parameter");
			vXMLWriter.WriteAttribute("Name", Mid(vParameter.Key, vBeginName));
			vXMLWriter.WriteAttribute("Value", XMLString(vParameter.Value));
			vXMLWriter.WriteEndElement();
		EndDo;
		vXMLWriter.WriteEndElement();
		vResult = vXMLWriter.Close();
	#EndIf
	Return vResult;
EndFunction // GetParametersXML

// --------------------------------------------------------------------------------
//
// Parameters:
//  pXMLParameters	 - String	 - XMLParameters
// 
// Returns:
//  Structure - Result
//
Function LoadXMLParameters(pXMLParameters) Export
	#If WebClient Then
		vParameters = tcConnectedHardwareOnServer.LoadXMLParameters(pXMLParameters);
	#Else
		vParameters = New Structure;
		
		If IsBlankString(pXMLParameters) Then
			Return vParameters;
		EndIf;
		
		vXMLReader = New XMLReader;
		vXMLReader.SetString(pXMLParameters);
		vXMLReader.MoveToContent();
		
		If vXMLReader.Name <> "Parameters" Or vXMLReader.NodeType <> XMLNodeType.StartElement Then
			Return vParameters;
		EndIf;
		
		While vXMLReader.Read() Do
			If vXMLReader.Name <> "Parameter" Or vXMLReader.NodeType <> XMLNodeType.StartElement Then
				Continue;
			EndIf;
			
			vParameterName = vXMLReader.AttributeValue("Name");
			vParameterValue = vXMLReader.AttributeValue("Value");
			If vParameterName = "EquipmentType" Then
				Continue;
			EndIf;
			
			vParameterName = "P_" + vParameterName;
			vParameters.Insert(vParameterName, vParameterValue);
		EndDo;
	#EndIf
	Return vParameters;
EndFunction // LoadXMLParameters

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStringXML	 - String	 - XML string
// 
// Returns:
//  Structure - Result
//
Function ReadRootElementXML(pStringXML) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.ReadRootElementXML(pStringXML);
	#Else
		vResult = New Structure();
		If Not IsBlankString(pStringXML) Then
			vXMLReader = New XMLReader;
			vXMLReader.SetString(pStringXML);
			vXMLReader.MoveToContent();
			If vXMLReader.NodeType = XMLNodeType.StartElement Then
				If vXMLReader.AttributeCount() > 0 Then
					While vXMLReader.ReadAttribute() Do
						vResult.Insert(vXMLReader.Name, vXMLReader.Value);
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		Return vResult;
	#EndIf
EndFunction // ReadRootElementXML

// --------------------------------------------------------------------------------
//
// Parameters:
//  pResult				 - Boolean			 - Result
//  pErrorDescription	 - String, Undefined - Error description
//  pHardware			 - Arbitrary		 - Hardware
// 
// Returns:
//  Structure - Result
//
Function ResultOperationOnHardware(pResult = False, pErrorDescription = Undefined, pHardware = Undefined) Export
	vResultOperation = New Structure;
	vResultOperation.Insert("Result" , pResult);
	vResultOperation.Insert("ErrorDescription", pErrorDescription);
	vResultOperation.Insert("LoadingError", False);
	vResultOperation.Insert("Hardware", pHardware);
	Return vResultOperation;
EndFunction // ResultOperationOnHardware

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMethodDriver		 - String, Undefined - Method driver
//  pErrorDescription	 - String, Undefined - Error description
//  pWriteInLogEvent	 - Boolean			 - Write in log event
// 
// Returns:
//  Structure - Result
//
Function DriverCallError(pMethodDriver = Undefined, pErrorDescription = Undefined, pWriteInLogEvent = False) Export
	If Not IsBlankString(pMethodDriver) Then
		vMessage = NStr("en = 'Error calling driver method <%1>.'; de = 'Fehler beim Aufrufen der Treibermethode <%1>.'; ru = 'Ошибка вызова метода драйвера <%1>.'");
		vMessage = StrTemplate(vMessage, pMethodDriver); 
	Else
		vMessage = NStr("en = 'This hardware type does not support this command.'; de = 'Dieser Hardwaretyp unterstützt diesen Befehl nicht.'; ru = 'Данный тип оборудования не поддерживает данную команду.'");
	EndIf;
	
	If Not IsBlankString(pErrorDescription) Then
		vMessage = vMessage + Chars.LF + pErrorDescription;
	EndIf;
	
	If pWriteInLogEvent Then
		WriteInLogEvent(vMessage);
	EndIf;
	
	vResultOperation = ResultOperationOnHardware(False, vMessage);
	Return vResultOperation;
EndFunction // DriverCallError

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMap - Structure, Map	 - Map
// 
// Returns:
//  String - Result
//
Function MapToJson(pMap) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.MapToJson(pMap);
	#Else
		Try
			vJSONWriter = New JSONWriter;
			vJSONWriter.SetString();
			WriteJSON(vJSONWriter, pMap,, "MapToJsonTransformations", tcConnectedHardwareOnClientServer);
			Return vJSONWriter.Close();
		Except
			Return "";
		EndTry;
	#EndIf
EndFunction // MapToJson

// --------------------------------------------------------------------------------
//
// Parameters:
//  pName		 - String	 - Name
//  pValue		 - Arbitrary - Value
//  pExtraParams - Arbitrary - Extra params
//  pCancel		 - Boolean	 - Cancel
// 
// Returns:
// String  - Result
//
Function MapToJsonTransformations(pName, pValue, pExtraParams, pCancel) Export
	Return TrimAll(pValue);
EndFunction // MapToJsonTransformations

// --------------------------------------------------------------------------------
//
// Parameters:
//  pJson	 - String	 - JSON
//  pMap	 - Boolean	 - Map
// 
// Returns:
//  Undefined, Structure, Map - Result
//
Function JsonToMap(pJson, pMap = False) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.JsonToMap(pMap);
	#Else
		Try
			vJSONReader =New JSONReader;
			vJSONReader.SetString(pJson);
			Return ReadJSON(vJSONReader, pMap);
		Except
			Return Undefined;
		EndTry;
	#EndIf
EndFunction // JsonToMap

#Region POSTerminal

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDataOperations	 - Structure - Data operations
// 
// Returns:
//  String - Result
//
Function GetPOSTerminalXMLParameters(pDataOperations) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.GetPOSTerminalXMLParameters(pDataOperations);
	#Else
		vXMLWriter = New XMLWriter();
		vXMLWriter.SetString("UTF-8");
		vXMLWriter.WriteXMLDeclaration();
		vXMLWriter.WriteStartElement("OperationParameters");
		
		vMerchantNumber  = ?(pDataOperations.MerchantNumber <> Undefined, pDataOperations.MerchantNumber, 0);
		
		vXMLWriter.WriteAttribute("MerchantNumber", XMLString(vMerchantNumber));
		
		If Not IsBlankString(pDataOperations.ConsumerPresentedQR) Then
			vXMLWriter.WriteAttribute("ConsumerPresentedQR",  XMLString(pDataOperations.ConsumerPresentedQR));
		EndIf;
		
		vUseBiometrics = ?(pDataOperations.UseBiometrics <> Undefined, pDataOperations.UseBiometrics, False);
		vXMLWriter.WriteAttribute("UseBiometrics", ?(vUseBiometrics, "1", "0"));
		
		vAmount = ?(pDataOperations.Amount <> Undefined, pDataOperations.Amount, 0);
		vXMLWriter.WriteAttribute("Amount", XMLString(vAmount));
		
		vAmountOriginalTransaction = ?(pDataOperations.AmountOriginalTransaction <> Undefined, pDataOperations.AmountOriginalTransaction, 0);
		vXMLWriter.WriteAttribute("AmountOriginalTransaction", XMLString(vAmountOriginalTransaction));
		
		vCardNumber = ?(pDataOperations.CardNumber <> Undefined, pDataOperations.CardNumber, "");
		If Not IsBlankString(vCardNumber) Then
			vXMLWriter.WriteAttribute("CardNumber", XMLString(vCardNumber));
		EndIf;
		
		vCardNumberHash = ?(pDataOperations.CardNumberHash <> Undefined, pDataOperations.CardNumberHash, "");
		If Not IsBlankString(vCardNumberHash) Then
			vXMLWriter.WriteAttribute("CardNumberHash", XMLString(vCardNumberHash));
		EndIf;
		
		vReceiptNumber = ?(pDataOperations.ReceiptNumber <> Undefined, pDataOperations.ReceiptNumber, "");
		If Not IsBlankString(vReceiptNumber) Then
			vXMLWriter.WriteAttribute("ReceiptNumber", XMLString(vReceiptNumber));
		EndIf;
		
		vRRNCode = ?(pDataOperations.RRNCode <> Undefined, pDataOperations.RRNCode, "");
		If Not IsBlankString(vRRNCode) Then
			vXMLWriter.WriteAttribute("RRNCode", XMLString(vRRNCode));
		EndIf;
		
		vAuthorizationCode = ?(pDataOperations.AuthorizationCode <> Undefined, pDataOperations.AuthorizationCode, "");
		If Not IsBlankString(vAuthorizationCode) Then
			vXMLWriter.WriteAttribute("AuthorizationCode", XMLString(vAuthorizationCode));
		EndIf;
		
		vXMLWriter.WriteEndElement();
		Return vXMLWriter.Close();
	#EndIf
EndFunction // GetPOSTerminalXMLParameters

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStringXML	 - String	 - XML
// 
// Returns:
//  Array - Result
//
Function OperationByCards(pStringXML) Export
	#If WebClient Then
		Return tcConnectedHardwareOnServer.OperationByCards(pStringXML);
	#Else
		vResult = New Array;
		If Not IsBlankString(pStringXML) Then
			Return vResult;
		EndIf;
		
		vXMLReader = New XMLReader; 
		vXMLReader.УстановитьСтроку(pStringXML);
		vXMLReader.ПерейтиКСодержимому(); 
		
		If vXMLReader.Name = "Table" And vXMLReader.NodeType = XMLNodeType.StartElement Then
			While vXMLReader.Read() Do
				If vXMLReader.Name = "Record" And vXMLReader.NodeType = XMLNodeType.StartElement Then
					vOperation = OperationByCardsParameters();
					vOperation.TypeOperation = vXMLReader.AttributeValue("TypeOperation");
					vOperation.MerchantNumber = vXMLReader.AttributeValue("MerchantNumber");
					vOperation.CardNumber = vXMLReader.AttributeValue("CardNumber");
					If vXMLReader.AttributeValue("CardNumberHash") <> Undefined Then
						vOperation.CardNumberHash = vXMLReader.AttributeValue("CardNumberHash");
					EndIf;
					If vXMLReader.AttributeValue("Amount") <> Undefined Then
						vOperation.Amount = Number(vXMLReader.AttributeValue("Amount"));
					EndIf;
					If vXMLReader.AttributeValue("DateTime") <> Undefined Then
						vOperation.DateTime = Number(vXMLReader.AttributeValue("DateTime"));
					EndIf;
					vOperation.RRNCode = vXMLReader.AttributeValue("RRNCode");
					vOperation.AuthorizationCode = vXMLReader.AttributeValue("AuthorizationCode");
					vResult.Add(vOperation);
				EndIf;
			EndDo;
		EndIf;
		Return vResult;
	#EndIf
EndFunction // OperationByCards

#EndRegion

#Region Hardware

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Structure - Result
//
Function ConnectHardware(pHardwareData) Export
	vObjectDriver = GetObjectDriver(pHardwareData);
	If vObjectDriver = Undefined Then
		vResultOperation = DriverLoadingError(pHardwareData);
		Return vResultOperation;
	EndIf;
	
	If pHardwareData.Connected Then
		vResultOperation = ResultOperationOnHardware(True);
		Return vResultOperation;
	EndIf;
	
	vInterfaceRevision = 2005;
	vDescriptionReceived = True;
	vDriverDescription = DriverDescriptionParameters();
	Try
		vInterfaceRevision = vObjectDriver.GetInterfaceRevision();
	Except
		vDescriptionReceived = False;
	EndTry;
	
	If Not vDescriptionReceived Then
		Try
			vResult = vObjectDriver.GetDescription(vDriverDescription.Name, vDriverDescription.Description, vDriverDescription.EquipmentType,
					vInterfaceRevision, vDriverDescription.IntegrationComponent, vDriverDescription.MainDriverInstalled, vDriverDescription.DownloadURL);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Return DriverCallError("GetDescription", vErrorMessage, True);
		EndTry;
	EndIf;
	pHardwareData.InterfaceRevision = vInterfaceRevision;
	vDriverDescription.InterfaceRevision = vInterfaceRevision;
	
	If IsBlankString(pHardwareData.InterfaceRevision) Or pHardwareData.InterfaceRevision = 0 Then
		vErrorDescription = NStr("en = 'The driver interface revision is not defined.'; de = 'Die Treiberschnittstellenrevision ist nicht definiert.'; ru = 'Ревизия интерфейса драйвера не определена.'");
		vResultOperation = ResultOperationOnHardware(False, vErrorDescription);
		Return vResultOperation;
	Else
		vDriverDescription.InterfaceRevisionPresentation = InterfaceRevisionPresentation(pHardwareData.InterfaceRevision);
	EndIf;
	
	If pHardwareData.InterfaceRevision > 4002 Then
		Try
			vResult = vObjectDriver.ConnectEquipment(pHardwareData.DeviceID, GetTypeNameByConnectedHardwareType(pHardwareData.ConnectedHardwareType), pHardwareData.ParametersValueXML);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Return DriverCallError("ConnectEquipment", vErrorMessage, True);
		EndTry;
	Else
		vResult = SetDriverParameters(vObjectDriver, pHardwareData, True, False);
		If Not vResult Then
			Return DriverCallError("SetDriverParameters");
		EndIf;
	
		vResult = SetDriverParameters(vObjectDriver, pHardwareData, False);
		If Not vResult Then
			Return DriverCallError("SetDriverParameters");
		EndIf;
	
		Try
			vResult = vObjectDriver.Open(pHardwareData.DeviceID);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Return DriverCallError("Open", vErrorMessage, True);
		EndTry;
	EndIf;
	
	If Not vResult Then
		vResultOperation = GetDriverError(vObjectDriver, True);
		Return vResultOperation;
	EndIf;
	
	// CashRegisters
	vKKT = False;
	If vKKT Then
		vResult = LineLength(vObjectDriver, pHardwareData);
	EndIf;
	
	If pHardwareData.ConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.POSTerminal") Then
		vResult = TerminalParameters(vObjectDriver, pHardwareData);
	EndIf;
	
	pHardwareData.Connected = True;
	
	vObjectDriverData = GetObjectDriverDataMap(vObjectDriver);
	FillPropertyValues(vObjectDriverData, pHardwareData);
	SetPersistentObject(pHardwareData.PersistentObjectKey, vObjectDriverData);
	
	vResultOperation = ResultOperationOnHardware(True);
	Return vResultOperation;
EndFunction // ConnectHardware

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Structure - Result
//
Function DisconnectHardware(pHardwareData, pSkipHoldConnection = False) Export
	If Not ValueIsFilled(pHardwareData) Or ((pHardwareData.HoldConnection Or pHardwareData.ConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.BarcodeScanner") Or pHardwareData.ConnectedHardwareType = PredefinedValue("Enum.ConnectedHardwareTypes.CardReader")) And Not pSkipHoldConnection) Then
		Return ResultOperationOnHardware(True);
	EndIF;
	
	vObjectDriver = pHardwareData.ObjectDriver;
	If vObjectDriver = Undefined Then
		vObjectDriver = GetObjectDriver(pHardwareData);
	EndIf;
	
	If Not pHardwareData.Connected Or vObjectDriver = Undefined Then
		Return ResultOperationOnHardware(True);
	EndIf;
	
	vMethod = "DisconnectEquipment";
	Try
		If pHardwareData.InterfaceRevision > 4002 Then
			vResult = vObjectDriver.DisconnectEquipment(pHardwareData.DeviceID);
			vResultOperation = ResultOperationOnHardware(vResult);
		Else
			vMethod = "Close";
			vResult = vObjectDriver.Close(pHardwareData.DeviceID);
			vResultOperation = ResultOperationOnHardware(vResult);
		EndIf;
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Return DriverCallError(vMethod, vErrorMessage);
	EndTry;
	
	If Not vResult Then
		GetDriverError(vObjectDriver, True);
	Else
		pHardwareData.Connected = False;
		SetPersistentObject(pHardwareData.PersistentObjectKey, Undefined);
	EndIf;
	
	Return vResultOperation;
EndFunction // DisconnectHardware

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Structure - Result
//
Function GetHardwareDriverDescription(pHardwareData) Export
	vObjectDriver = GetObjectDriver(pHardwareData);
	If vObjectDriver = Undefined Then
		vResultOperation = DriverLoadingError(pHardwareData);
		Return vResultOperation;
	EndIf;
	
	vDescriptionReceived = True;
	vDriverDescription = DriverDescriptionParameters();
	Try
		vResult = vObjectDriver.GetDescription(vDriverDescription.DriverDescriptionXML);
	Except
		vInterfaceRevision = 2005;
		vDescriptionReceived = False;
	EndTry;
	
	If Not vDescriptionReceived Then
		Try
			vResult = vObjectDriver.GetDescription(vDriverDescription.Name, vDriverDescription.Description, vDriverDescription.EquipmentType,
					vInterfaceRevision, vDriverDescription.IntegrationComponent, vDriverDescription.MainDriverInstalled, vDriverDescription.DownloadURL);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Return DriverCallError("GetDescription", vErrorMessage, True);
		EndTry;
	EndIf;
	
	If Not vResult Then
		GetDriverError(vObjectDriver, True);
	EndIf;
	
	If Not vDescriptionReceived Then
		vDriverVersion = "";
		Try
			vDriverVersion = vObjectDriver.GetVersion();
		Except
			vDriverVersion = "";
		EndTry;
		vDriverDescription.DriverVersion = vDriverVersion;
		vDriverDescription.InterfaceRevision = vInterfaceRevision;
	Else
		vDriverDescriptionParameters = GetDriverDescription(vDriverDescription.DriverDescriptionXML);
		FillPropertyValues(vDriverDescription, vDriverDescriptionParameters);
		
		vInterfaceRevision = 0;
		Try
			vInterfaceRevision = vObjectDriver.GetInterfaceRevision();
		Except
			vInterfaceRevision = 0;
		EndTry;
		vDriverDescription.InterfaceRevision = vInterfaceRevision;
	EndIf;
	
	If vDriverDescription.InterfaceRevision >= 4000 And vDriverDescription.LocalizationSupported Then
		vLocalizationPattern = "";
		Try
			vResult = vObjectDriver.GetLocalizationPattern(vLocalizationPattern);
			
			If vResult Then
				vDriverDescription.LocalizationPattern = vLocalizationPattern;
			EndIf;
		Except
			vErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error getting driver localization template.'; de = 'Fehler beim Abrufen der Treiberlokalisierungsvorlage.'; ru = 'Ошибка получения шаблон локализации драйвера.'") + Chars.LF + vErrorDescription);
			vResult = False;
		EndTry;
		If Not vResult Then
			GetDriverError(vObjectDriver, True);
		EndIf;
	EndIf;
	
	vDriverDescription.InterfaceRevisionPresentation = InterfaceRevisionPresentation(vDriverDescription.InterfaceRevision);
	pHardwareData.InterfaceRevision = vDriverDescription.InterfaceRevision;
	
	If Not vDriverDescription.InterfaceRevision > 4002 Then
		vResult = SetDriverParameters(vObjectDriver, pHardwareData, True, False);
		If Not vResult Then
			Return DriverCallError("SetDriverParameters");
		EndIf;
	EndIf;
	
	vResult = DriverParameters(vObjectDriver, vDriverDescription, pHardwareData);
	
	vResultOperation = ResultOperationOnHardware(vResult);
	vResultOperation.Insert("DriverDescription", vDriverDescription);
	Return vResultOperation;
EndFunction // GetHardwareDriverDescription

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Structure - Result
//
Function TestConnections(pHardwareData) Export
	vObjectDriver = GetObjectDriver(pHardwareData);
	If vObjectDriver = Undefined Then
		vResultOperation = DriverLoadingError(pHardwareData);
		Return vResultOperation;
	EndIf;
	
	vIsConnected = pHardwareData.Connected;
	If vIsConnected Then
		DisconnectHardware(pHardwareData, True);
	EndIf;
	vInterfaceRevision = InterfaceRevision(vObjectDriver, pHardwareData);
	
	vResult = False;
	vTestResult = "";
	vActivatedDemoMode = ""; 
	If vInterfaceRevision > 4002 Then
		Try
			vResult = vObjectDriver.EquipmentTest(GetTypeNameByConnectedHardwareType(pHardwareData.ConnectedHardwareType),
				pHardwareData.ParametersValueXML, vTestResult, vActivatedDemoMode);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Return DriverCallError("EquipmentTest", vErrorMessage);
		EndTry;
		If Not vResult Then
			GetDriverError(vObjectDriver, True);
		EndIf;
	Else
		vResult = SetDriverParameters(vObjectDriver, pHardwareData);
		If vResult Then
			Try
				vResult = vObjectDriver.DeviceTest(vTestResult, vActivatedDemoMode);
			Except
				vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				Return DriverCallError("DeviceTest", vErrorMessage);
			EndTry;
			If Not vResult Then
				GetDriverError(vObjectDriver, True);
			EndIf;
		Else
			Return DriverCallError("SetDriverParameters");
		EndIf;
	EndIf;
	
	vResultOperation = ResultOperationOnHardware(vResult);
	vResultOperation.Insert("ResultOperation" , vTestResult);
	vResultOperation.Insert("ActivatedDemoMode", vActivatedDemoMode);
	
	If vIsConnected Then
		vResultConnectOperation = ConnectHardware(pHardwareData);
		If Not vResultConnectOperation.Result Then
			tcCommonFunctionOnClientServer.UserMessage(vResultConnectOperation.ErrorDescription);
		EndIf;
	EndIf;
	Return vResultOperation;
EndFunction // TestConnections

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Structure - Result
//
Function HardwareAutoSetup(pHardwareData) Export
	vObjectDriver = GetObjectDriver(pHardwareData);
	If vObjectDriver = Undefined Then
		vResultOperation = DriverLoadingError(pHardwareData);
		Return vResultOperation;
	EndIf;
	
	vInterfaceRevision = InterfaceRevision(vObjectDriver, pHardwareData);
	
	vResult = False;
	
	#If Server Or ExternalConnection Then
		vShowAutoSettingsWindow = False;
	#Else
		vShowAutoSettingsWindow = True;
	#EndIf
	
	vTimeOut = 60;
	vParametersValueXML = "";
	
	If vInterfaceRevision > 4002 Then
		Try
			vResult = vObjectDriver.EquipmentAutoSetup(GetTypeNameByConnectedHardwareType(pHardwareData.ConnectedHardwareType),
				pHardwareData.ParametersValueXML, vParametersValueXML, vShowAutoSettingsWindow, vTimeOut);
		Except
			vResult = False;
		EndTry;
		
		If Not vResult Then
			GetDriverError(vObjectDriver, True);
		EndIf;
		
		vResultOperation = ResultOperationOnHardware(vResult);
		vResultOperation.Insert("ParametersValueXML", vParametersValueXML);
		vResultOperation.Insert("ParametersValue", LoadXMLParameters(vParametersValueXML));
	Else
		vErrorDescription = NStr("en = 'The driver does not support the operation.'; de = 'Der Treiber unterstützt den Vorgang nicht.'; ru = 'Драйвер не поддерживает операцию.'");
		vResultOperation = ResultOperationOnHardware(False, vErrorDescription);
	EndIf;
	
	Return vResultOperation;
EndFunction // HardwareAutoSetup

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardwareData		 - Structure - Hardware data
//  pExecutionParameters - Structure - Execution parameters
// 
// Returns:
//  Structure - Result
//
Function AdditionalCommands(pHardwareData, pExecutionParameters) Export
	vResultOperation = GetHardwareDriverDescription(pHardwareData);
	If vResultOperation.Result Then
		vObjectDriver = pHardwareData.ObjectDriver;
		
		If pHardwareData.InterfaceRevision < 4003 Then
			vResult = SetDriverParameters(vObjectDriver, pHardwareData);
			If Not vResult Then
				Return DriverCallError("SetDriverParameters");
			EndIf;
		EndIf;
		
		Try
			vResult = vObjectDriver.DoAdditionalAction(pExecutionParameters.NameActions);
		Except
			vResultOperation = ResultOperationOnHardware(False, NStr("en = 'Error execution additional action.'; de = 'Fehler bei der Ausführung zusätzlicher Aktionen.'; ru = 'Ошибка выполнения дополнительного действия.'"));
			Return vResultOperation;
		EndTry;
		
		vResultOperation = ResultOperationOnHardware(True);
		If Not vResult Then
			vResultOperation = GetDriverError(vObjectDriver, True);
		EndIf;
	Else
		Return vResultOperation;
	EndIf;
	
	Return vResultOperation;
EndFunction // AdditionalCommands

// --------------------------------------------------------------------------------
//
// Parameters:
//  pObjectDriver	 - Arbitrary - Object driver
//  pHardwareData	 - Structure - Hardware data
// 
// Returns:
//  Number - Result
//
Function InterfaceRevision(pObjectDriver, pHardwareData) Export
	Try
		vInterfaceRevision = pObjectDriver.GetInterfaceRevision();
	Except
		vInterfaceRevision = 2005;
	EndTry;
	pHardwareData.Insert("InterfaceRevision", vInterfaceRevision);
	
	Return vInterfaceRevision;
EndFunction // InterfaceRevision

// -----------------------------------------------------------------------------
//
// Parameters:
//  pObjectDriver	 - Arbitrary - Driver
// 
// Returns:
//  String - Result
//
Function GetDriverError(pObjectDriver, pWriteInLog = False) Export
	vMessage = "";
	
	pObjectDriver.GetLastError(vMessage);
	vResultOperation = ResultOperationOnHardware(False, vMessage);
	
	If pWriteInLog Then
		WriteInLogEvent(vMessage);
	EndIf;
	
	Return vResultOperation;
EndFunction // GetDriverError

#EndRegion

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetObjectDriver(pHardwareData)
	vObjectDriverData = GetPersistentObject(pHardwareData.PersistentObjectKey);
	If vObjectDriverData <> Undefined Then
		vObjectDriver = vObjectDriverData.ObjectDriver;
		FillPropertyValues(pHardwareData, vObjectDriverData);
		Return vObjectDriver;
	EndIf;
	
	vParameters = ConnectionParameters();
	vParameters.SecureConnection = pHardwareData.SecureConnection;
	
	vResultConnection = ConnectComponent(pHardwareData.ObjectID, GetHardwareDriverURL(pHardwareData.HardwareDriver), vParameters);
	If vResultConnection.Connected Then
		vObjectDriver = vResultConnection.ObjectDriver;
		vObjectDriverData = GetObjectDriverDataMap(vObjectDriver);
		FillPropertyValues(pHardwareData, vObjectDriverData);
		SetPersistentObject(pHardwareData.PersistentObjectKey, vObjectDriverData);
	Else
		DriverCallError("ConnectComponent", vResultConnection.ErrorDescription);
	EndIf;
	
	Return vObjectDriver;
EndFunction // GetObjectDriver

// --------------------------------------------------------------------------------
Function ConnectComponent(pObjectID, pHardwareDriverURL, pParameters)
	If pParameters = Undefined Then
		pParameters = ConnectionParameters();
	EndIf;
	
	vResultConnection = ResultConnection();
	
	If IsBlankString(pObjectID) Then
		vResultConnection.ErrorDescription = NStr("en = 'The component identifier is not indicated.'; de = 'Die Komponentenkennung ist nicht angegeben.'; ru = 'Идентификатор компоненты не указан.'");
		Return vResultConnection;
	EndIf;
	
	vSymbolicName = СтрЗаменить(pObjectID, ".", "_");
	
	Try
		#If MobileAppClient Or MobileClient Then
			vResultConnection.Connected = AttachAddIn(pHardwareDriverURL, vSymbolicName);
		#Else
			vResultConnection.Connected = AttachAddIn(pHardwareDriverURL, vSymbolicName, , TypeConnectionComponents(pParameters.SecureConnection));
		#EndIf
	Except
		vResultConnection.Connected = False;
	EndTry;
	
	If vResultConnection.Connected Then
		Try
			vProgID = "AddIn." + vSymbolicName + "." + pObjectID;
			vResultConnection.ObjectDriver = New(vProgID);
		Except
			vResultConnection.Connected = False;
		EndTry;
	Else
		vResultConnection.ErrorDescription = StrTemplate(
		NStr("en = 'Failed to connect the external component ""%1"" on the client
		|%2
		|for:
		|%3'; de = 'Die externe Komponente ""%1"" nicht mit dem Client anschließen
		|%2
		|für:
		|%3'; ru = 'Не удалось подключить внешнюю компоненту ""%1"" на клиенте
		|%2
		|по причине:
		|%3'"), pObjectID, pHardwareDriverURL, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndIf;
	
	Return vResultConnection;
EndFunction // ConnectComponent

// --------------------------------------------------------------------------------
Function DriverParameters(pObjectDriver, pDriverDescription, pHardwareData)
	vDriverParameters = "";
	Try
		If pDriverDescription.InterfaceRevision > 4002 Then
			vResult = pObjectDriver.EquipmentParameters(GetTypeNameByConnectedHardwareType(pHardwareData.ConnectedHardwareType), vDriverParameters);
		Else
			vResult = pObjectDriver.GetParameters(vDriverParameters);
		EndIf;
		pDriverDescription.HardwareParameters = vDriverParameters;
	Except
		vErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error retrieving driver parameters.'; de = 'Fehler beim Abrufen der Treiberparameter.'; ru = 'Ошибка получения параметров драйвера.'") + Chars.LF + vErrorDescription);
		Return False;
	EndTry;
	
	If Not vResult Then
		GetDriverError(pObjectDriver, True);
	EndIf;
	
	vAdditionalActions = "";
	Try
		vResult = pObjectDriver.GetAdditionalActions(vAdditionalActions);
	Except
		vErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		tcCommonFunctionOnClientServer.UserMessage(NStr("en = 'Error getting driver description.'; de = 'Fehler beim Abrufen der Treiberbeschreibung.'; ru = 'Ошибка получения описания драйвера.'") + Chars.LF + vErrorDescription);
		Return False;
	EndTry;
	
	If Not vResult Then
		GetDriverError(pObjectDriver, True);
	EndIf;
	
	pDriverDescription.AdditionalActions = vAdditionalActions;
	pDriverDescription.Installed = True;
	
	Return True;
EndFunction // DriverParameters

// --------------------------------------------------------------------------------
Function SetDriverParameters(pObjectDriver, pHardwareData, pSetHardwareType = True, pSetParameters = True)
	If pSetHardwareType And pHardwareData.Property("ConnectedHardwareType") Then
		Try
			vResult = pObjectDriver.SetParameter("EquipmentType", GetTypeNameByConnectedHardwareType(pHardwareData.ConnectedHardwareType));
		Except
			Return False;
		EndTry;
		
		If Not vResult Then
			GetDriverError(pObjectDriver, True);
		EndIf;
	EndIf;
	
	If pSetParameters And pHardwareData.ParametersValue <> Undefined Then
		For Each vParameter In pHardwareData.ParametersValue Do
			If Left(vParameter.Key, 2) = "P_" Then
				vParameterValue = vParameter.Value;
				vParameterName = Mid(vParameter.Key, 3);
				Try
					vResult = pObjectDriver.SetParameter(vParameterName, vParameterValue);
				Except
					Return False;
				EndTry;
				
				If Not vResult Then
					GetDriverError(pObjectDriver, True);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	Return True;
EndFunction // SetDriverParameters

// --------------------------------------------------------------------------------
Function LineLength(pObjectDriver, pHardwareData)
	Try
		vResult = pObjectDriver.GetLineLength(pHardwareData.DeviceID, pHardwareData.LineLength);
	Except
		vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Return DriverCallError("GetLineLength", vErrorMessage, True);
	EndTry;
	
	If Not vResult Then
		vResultOperation = GetDriverError(pObjectDriver, True);
		Return vResultOperation;
	EndIf;
	
	vResultOperation = ResultOperationOnHardware(True);
	Return vResultOperation;
EndFunction // LineLength

// --------------------------------------------------------------------------------
Function TerminalParameters(pObjectDriver, pHardwareData)
	If pHardwareData.InterfaceRevision >= 3004 Then
		Try
			vResultOperationXML = "";
			vResult = pObjectDriver.TerminalParamters(pHardwareData.DeviceID, vResultOperationXML);
			
			If vResult Then
				vTerminalParameters = ReadRootElementXML(vResultOperationXML);
				If vTerminalParameters.Property("TerminalID") And Not IsBlankString(vTerminalParameters.TerminalID) Then
					pHardwareData.TerminalID = vTerminalParameters.TerminalID;
				EndIf;
				If vTerminalParameters.Property("AcquiringBankIdentifier") And Not IsBlankString(vTerminalParameters.AcquiringBankIdentifier) Then
					pHardwareData.AcquiringBankIdentifier = vTerminalParameters.AcquiringBankIdentifier;
				EndIf;
				pHardwareData.PrintSlipOnTerminal = vTerminalParameters.Property("PrintSlipOnTerminal") And Upper(vTerminalParameters.PrintSlipOnTerminal) = "TRUE";
				pHardwareData.ShortSlip = vTerminalParameters.Property("ShortSlip") And Upper(vTerminalParameters.ShortSlip) = "TRUE";
				pHardwareData.CashWithdrawal = vTerminalParameters.Property("CashWithdrawal") And Upper(vTerminalParameters.CashWithdrawal) = "TRUE";
				pHardwareData.ElectronicCertificates = vTerminalParameters.Property("ElectronicCertificates") And Upper(vTerminalParameters.ElectronicCertificates) = "TRUE";
				pHardwareData.PartialCancellation = vTerminalParameters.Property("PartialCancellation") And Upper(vTerminalParameters.PartialCancellation) = "TRUE";
				pHardwareData.ConsumerPresentedQR = vTerminalParameters.Property("ConsumerPresentedQR") And Upper(vTerminalParameters.ConsumerPresentedQR) = "TRUE";
				pHardwareData.ListCardTransactions = vTerminalParameters.Property("ListCardTransactions") And Upper(vTerminalParameters.ListCardTransactions) = "TRUE";
				pHardwareData.ReturnElectronicCertificateByBasketID = vTerminalParameters.Property("ReturnElectronicCertificateByBasketID") And Upper(vTerminalParameters.ReturnElectronicCertificateByBasketID) = "TRUE";
				pHardwareData.PurchaseWithEnrollment = vTerminalParameters.Property("PurchaseWithEnrollment") And Upper(vTerminalParameters.PurchaseWithEnrollment) = "TRUE";
				vResultOperation = ResultOperationOnHardware(True);
			EndIf;
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			vResultOperation = DriverCallError("TerminalParamters", vErrorMessage, True);
		EndTry;
	Else
		Try
			pHardwareData.PrintSlipOnTerminal = pObjectDriver.PrintSlipOnTerminal();
			vResultOperation = ResultOperationOnHardware(True);
		Except
			vErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			vResultOperation =  DriverCallError("TerminalParamters", vErrorMessage, True);
		EndTry;
	EndIf;
	Return vResultOperation;
EndFunction // TerminalParameters

// --------------------------------------------------------------------------------
Function GetObjectDriverDataMap(pObjectDriver)
	vObjectDriverData = New Structure;
	vObjectDriverData.Insert("ObjectDriver", pObjectDriver);
	vObjectDriverData.Insert("Connected", False);
	vObjectDriverData.Insert("DeviceID", "");
	vObjectDriverData.Insert("InterfaceRevision", "");
	
	vObjectDriverData.Insert("LineLength", 0);
	
	vObjectDriverData.Insert("TerminalID", "");
	vObjectDriverData.Insert("AcquiringBankIdentifier", "");
	vObjectDriverData.Insert("PrintSlipOnTerminal", False);
	vObjectDriverData.Insert("ShortSlip", False);
	vObjectDriverData.Insert("CashWithdrawal", False);
	vObjectDriverData.Insert("ElectronicCertificates", False);
	vObjectDriverData.Insert("PartialCancellation", False);
	vObjectDriverData.Insert("ConsumerPresentedQR", False);
	vObjectDriverData.Insert("ListCardTransactions", False);
	vObjectDriverData.Insert("ReturnElectronicCertificateByBasketID", False);
	vObjectDriverData.Insert("PurchaseWithEnrollment", False);
	Return vObjectDriverData;
EndFunction // GetObjectDriverDataMap

// -----------------------------------------------------------------------------
Function GetPersistentObject(pName)
	vObject = Undefined;
	#If Not Server And Not ExternalConnection Then
		If Not amHardwarePersistentObjects.Property(pName, vObject) Then
			amHardwarePersistentObjects.Insert(pName, vObject);
		EndIf;
	#EndIf
	Return vObject;
EndFunction // GetPersistentObject 

// -----------------------------------------------------------------------------
Procedure SetPersistentObject(pName, pValue)
	#If Not Server And Not ExternalConnection Then
		amHardwarePersistentObjects.Insert(pName, pValue);
	#EndIf
EndProcedure // SetPersistentObject

// --------------------------------------------------------------------------------
Function DriverDescriptionParameters()
	vResult = New Structure();
	vResult.Insert("Installed", False);
	vResult.Insert("DriverVersion");
	vResult.Insert("IntegrationComponentVersion", "");
	vResult.Insert("Name", "");
	vResult.Insert("Description", "");
	vResult.Insert("EquipmentType", "" );
	vResult.Insert("IntegrationComponent", False);
	vResult.Insert("MainDriverInstalled", False);
	vResult.Insert("InterfaceRevision", DriverInterfaceRevision());
	vResult.Insert("InterfaceRevisionPresentation");
	vResult.Insert("DownloadURL", "");
	vResult.Insert("HardwareParameters", "");
	vResult.Insert("AdditionalActions", "");
	vResult.Insert("LocalizationSupported", False);
	vResult.Insert("LocalizationPattern", "");
	vResult.Insert("HardwareDriverVersion", "");
	vResult.Insert("DriverDescriptionXML", "");
	vResult.Insert("LogIsEnabled", False);
	vResult.Insert("LogPath", "");
	vResult.Insert("IsEmulator", False);
	vResult.Insert("EnvironmentInformation", "");
	vResult.Insert("AutoSetup", False);
	
	Return vResult;
EndFunction // DriverDescriptionParameters

// --------------------------------------------------------------------------------
Function GetDriverDescription(pStringXML)
	
	XMLParameters = ReadRootElementXML(pStringXML);
	
	Parameters = DriverDescriptionParameters();
	Parameters.Name = ?(XMLParameters.Property("Name"), XMLParameters.Name, "");
	Parameters.Description = ?(XMLParameters.Property("Description"), XMLParameters.Description, "");
	Parameters.EquipmentType = ?(XMLParameters.Property("EquipmentType"), XMLParameters.EquipmentType, "");
	Parameters.DriverVersion = ?(XMLParameters.Property("DriverVersion"), XMLParameters.DriverVersion, "");
	Parameters.IntegrationComponentVersion = ?(XMLParameters.Property("IntegrationComponentVersion"), XMLParameters.IntegrationComponentVersion, "");
	Parameters.DownloadURL = ?(XMLParameters.Property("DownloadURL"), XMLParameters.DownloadURL, "");
	Parameters.LogPath = ?(XMLParameters.Property("LogPath"), XMLParameters.LogPath, "");
	Parameters.IntegrationComponent = XMLParameters.Property("IntegrationComponent") And Upper(XMLParameters.IntegrationComponent) = "TRUE";
	Parameters.MainDriverInstalled = XMLParameters.Property("MainDriverInstalled") And Upper(XMLParameters.MainDriverInstalled) = "TRUE";
	Parameters.LogIsEnabled = XMLParameters.Property("LogIsEnabled") And Upper(XMLParameters.LogIsEnabled) = "TRUE";
	Parameters.LocalizationSupported = XMLParameters.Property("LocalizationSupported") And Upper(XMLParameters.LocalizationSupported) = "TRUE";
	Parameters.IsEmulator = XMLParameters.Property("IsEmulator") And Upper(XMLParameters.IsEmulator) = "TRUE";
	Parameters.EnvironmentInformation = ?(XMLParameters.Property("EnvironmentInformation"), XMLParameters.EnvironmentInformation, "");
	Parameters.AutoSetup = XMLParameters.Property("AutoSetup") And Upper(XMLParameters.AutoSetup) = "TRUE";
	
	Return Parameters;
	
EndFunction // GetDriverDescription

// --------------------------------------------------------------------------------
Function InterfaceRevisionPresentation(pInterfaceRevision)
	
	If pInterfaceRevision >= 5000 Then
		vResult = "5." + String(pInterfaceRevision - 5000);
	ElsIf pInterfaceRevision >= 4000 Then
		vResult = "4." + String(pInterfaceRevision - 4000);
	ElsIf pInterfaceRevision >= 3000 Then
		vResult = "3." + String(pInterfaceRevision - 3000);
	ElsIf pInterfaceRevision >= 2000 Then
		vResult = "2." + String(pInterfaceRevision - 2000);
	ElsIf pInterfaceRevision > 1000 Then
		vResult = "1." + String(pInterfaceRevision - 1000);
	Else
		vResult = "";
	EndIf;
	
	Return vResult;
	
EndFunction // InterfaceRevisionPresentation

// --------------------------------------------------------------------------------
Function ConnectionParameters()
	
	vParameters = New Structure;
	vParameters.Insert("SecureConnection", Undefined);
	
	Return vParameters;
	
EndFunction // ConnectionParameters

// --------------------------------------------------------------------------------
Function TypeConnectionComponents(pIsolated)
	If pIsolated = Undefined Then
		Return Undefined;
	EndIf;
	
	#If Not WebClient And Not MobileClient And Not MobileAppClient Then
		vAddInAttachmentType = AddInAttachmentType.NotIsolated;
		If pIsolated Then
			vAddInAttachmentType = AddInAttachmentType.Isolated;
		EndIf;
		
		Return vAddInAttachmentType;
	#Else
		Return Undefined;
	#EndIf
EndFunction // TypeConnectionComponents

// --------------------------------------------------------------------------------
Function DriverLoadingError(pConnectionParameters, pErrorDescription = "")
	vMessage = NStr(
	"en = '%1: Failed to load device driver.
	|Check that the driver is correctly installed and registered in the system.
	|%2'; de = '%1: Gerätetreiber konnte nicht geladen werden.
	|Überprüfen Sie, ob der Treiber korrekt installiert und im System registriert ist.
	|%2'; ru = '%1: Не удалось загрузить драйвер устройства.
	|Проверьте, что драйвер корректно установлен и зарегистрирован в системе.
	|%2'");
	vMessage = StrTemplate(vMessage, pConnectionParameters.Description, pErrorDescription);
	vResultOperation = ResultOperationOnHardware(False, vMessage);
	vResultOperation.LoadingError = True;
	Return vResultOperation;
EndFunction // DriverLoadingError

// --------------------------------------------------------------------------------
Procedure WriteInLogEvent(pMessage)
	tcConnectedHardwareOnServer.WriteErrorInLogEvent(NStr("en = 'Connected hardware.'; de = 'Angeschlossene Hardware.'; ru = 'Подключаемое оборудование.'"), pMessage);
EndProcedure // WriteInLogEvent

// --------------------------------------------------------------------------------
Function ResultConnection()
	vResult = New Structure;
	vResult.Insert("Connected", False);
	vResult.Insert("ErrorDescription", "");
	vResult.Insert("ObjectDriver", Undefined);
	Return vResult;
EndFunction // ResultConnection

// --------------------------------------------------------------------------------
Function OperationByCardsParameters()
	vResult = New Structure;
	vResult.Insert("TypeOperation");
	vResult.Insert("MerchantNumber");
	vResult.Insert("CardNumber");
	vResult.Insert("CardNumberHash");
	vResult.Insert("Amount", 0);
	vResult.Insert("RRNCode");
	vResult.Insert("AuthorizationCode");
	vResult.Insert("DateTime");
	Return vResult;
EndFunction // POSTerminalOperationByCardsParameters

#EndRegion
