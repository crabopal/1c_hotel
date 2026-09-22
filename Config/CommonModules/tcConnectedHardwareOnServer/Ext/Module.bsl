
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pHardware	 - Arbitrary - Hardware
// 
// Returns:
//  Map - Result
//
Function GetDataDevices(pHardware) Export
	If Not ValueIsFilled(pHardware) Or Not ValueIsFilled(pHardware.HardwareDriver) Then
		Return Undefined;
	EndIf;
	
	vHardwareDriver = pHardware.HardwareDriver;
	
	vDataDevices = New Structure;
	vDataDevices.Insert("Hardware", pHardware);
	vDataDevices.Insert("Description", pHardware.Description);
	
	vDataDevices.Insert("ParametersValue", Undefined);
	vDataDevices.Insert("HardwareParameters", "");
	vConnectionParameters = pHardware.ConnectionParameters.Get();
	If vConnectionParameters <> Undefined And TypeOf(vConnectionParameters) = Type("Structure") Then
		If vConnectionParameters.Property("ParametersValue") Then
			vDataDevices.ParametersValue = vConnectionParameters.ParametersValue;
		EndIf;
		If vConnectionParameters.Property("HardwareParameters") Then
			vDataDevices.HardwareParameters = vConnectionParameters.HardwareParameters;
		EndIf;
	EndIf;
	vDataDevices.Insert("ParametersValueXML", GetParametersXML(vDataDevices.ParametersValue, vHardwareDriver.ConnectedHardwareType));
	
	vDataDevices.Insert("HardwareDriver", vHardwareDriver);
	vDataDevices.Insert("ConnectedHardwareType", vHardwareDriver.ConnectedHardwareType);
	vDataDevices.Insert("ObjectID", vHardwareDriver.ObjectID);
	vDataDevices.Insert("DriverVersion", vHardwareDriver.DriverVersion);
	vDataDevices.Insert("SecureConnection", vHardwareDriver.SecureConnection);
	vDataDevices.Insert("HoldConnection", vHardwareDriver.HoldConnection);
	vDataDevices.Insert("PersistentObjectKey", StrTemplate("%1_%2", vDataDevices.ObjectID, StrReplace(TrimAll(vDataDevices.Hardware.UUID()), "-", "_")));
	
	vDataDevices.Insert("ApplicationSettingsXML", DriverApplicationParameters());
	vDataDevices.Insert("InterfaceRevision", tcConnectedHardwareOnClientServer.DriverInterfaceRevision());
	vDataDevices.Insert("DeviceID", "");
	vDataDevices.Insert("ObjectDriver", Undefined);
	vDataDevices.Insert("Connected", False);
	
	vDataDevices.Insert("LineLength", 0);
	
	vDataDevices.Insert("TerminalID", "");
	vDataDevices.Insert("AcquiringBankIdentifier", "");
	vDataDevices.Insert("PrintSlipOnTerminal", False);
	vDataDevices.Insert("ShortSlip", False);
	vDataDevices.Insert("CashWithdrawal", False);
	vDataDevices.Insert("ElectronicCertificates", False);
	vDataDevices.Insert("PartialCancellation", False);
	vDataDevices.Insert("ConsumerPresentedQR", False);
	vDataDevices.Insert("ListCardTransactions", False);
	vDataDevices.Insert("ReturnElectronicCertificateByBasketID", False);
	vDataDevices.Insert("PurchaseWithEnrollment", False);
	
	Return vDataDevices;
EndFunction // GetDataDevices

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
	Return tcConnectedHardwareOnClientServer.GetDataHardwareDriverFromFile(pFileTempStorage, rMessage);
EndFunction // GetDataHardwareDriverFromFile

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStringXML	 - String	 - XML string
// 
// Returns:
// Structure  - Result
//
Function ReadRootElementXML(pStringXML) Export
	Return tcConnectedHardwareOnClientServer.ReadRootElementXML(pStringXML);
EndFunction // ReadRootElementXML

// --------------------------------------------------------------------------------
//
// Parameters:
//  pEventName			 - String	 - Event name
//  pComment			 - String, Undefined - Comment
//  pPresentationLevel	 - String			 - Presentation level
//  pMetadata			 - Arbitrary		 - Metadata
//
Procedure WriteErrorInLogEvent(pEventName, pComment = Undefined, pPresentationLevel = "Error", pMetadata = Undefined) Export
	#If Not MobileAppServer Then
		If pComment = Undefined Then
			pComment = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndIf;
		vEventLogLevel = EventLevelByPresentation(pPresentationLevel);
		WriteLogEvent(pEventName, vEventLogLevel, pMetadata, , pComment);
	#EndIf
EndProcedure // WriteErrorInLogEvent

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
	 Return tcConnectedHardwareOnClientServer.GetParametersXML(pParameters, pHardwareType);
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
	Return tcConnectedHardwareOnClientServer.LoadXMLParameters(pXMLParameters);
EndFunction // LoadXMLParameters

// --------------------------------------------------------------------------------
//
// Parameters:
//  pStructure	 - Structure	 - Structure
// 
// Returns:
//  Structure - Result
//
Function GetCopyStructure(pStructure) Export
	Return ValueFromStringInternal(ValueToStringInternal(pStructure));
EndFunction // GetCopyStructure

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMap - Structure, Map	 - Map
// 
// Returns:
//  String - Result
//
Function MapToJson(pMap) Export
	Return tcConnectedHardwareOnClientServer.MapToJson(pMap);
EndFunction // MapToJson

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
	Return tcConnectedHardwareOnClientServer.JsonToMap(pJson, pMap);
EndFunction // JsonToMap

#Region POSTerminal

// --------------------------------------------------------------------------------
//
// Parameters:
//  pAuthorizationTypeCode	 - Number	 - Authorization type code
// 
// Returns:
//  EnumRef.AuthorizationTypes - Result
//
Function AuthorizationTypesByCode(pAuthorizationTypeCode) Export
	vMap = Enums.AuthorizationTypes.AuthorizationTypesByCode();
	Return vMap.Get(pAuthorizationTypeCode);
EndFunction // AuthorizationTypesByCode

// --------------------------------------------------------------------------------
//
// Parameters:
//  pAuthorizationType	 - EnumRef.AuthorizationTypes	 - Authorization type
// 
// Returns:
//  Number - Authorization type code
//
Function CodesByAuthorizationTypes(pAuthorizationType) Export
	vMap = Enums.AuthorizationTypes.CodesByAuthorizationTypes();
	Return vMap.Get(pAuthorizationType);
EndFunction // CodesByAuthorizationTypes

// --------------------------------------------------------------------------------
//
// Parameters:
//  pDataOperations	 - Structure	 - Data operations
// 
// Returns:
// String  - Result
//
Function GetPOSTerminalXMLParameters(pDataOperations) Export
	Return tcConnectedHardwareOnClientServer.GetPOSTerminalXMLParameters(pDataOperations);
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
	Return tcConnectedHardwareOnClientServer.OperationByCards(pStringXML);
EndFunction // OperationByCards

#EndRegion

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
//
// Parameters:
//  pPresentationLevel	 - String	 - Presentation level
// 
// Returns:
//  EventLogLevel - Result
//
Function EventLevelByPresentation(pPresentationLevel)
	vEventLogLevel = Undefined;
	If pPresentationLevel = "Information" Then
		vEventLogLevel = EventLogLevel.Information;
	ElsIf pPresentationLevel = "Warning" Then
		vEventLogLevel = EventLogLevel.Warning;
	ElsIf pPresentationLevel = "Note" Then
		vEventLogLevel = EventLogLevel.Note;
	Else
		vEventLogLevel = EventLogLevel.Error;
	EndIf;
	Return vEventLogLevel;
EndFunction // EventLevelByPresentation

// --------------------------------------------------------------------------------
Function DriverApplicationParameters()
	vApplicationName = Metadata.Synonym;
	vApplicationVersion = Metadata.Version;
	
	vXMLWriter = New XMLWriter;
	vXMLWriter.SetString("UTF-8");
	vXMLWriter.WriteXMLDeclaration();
	vXMLWriter.WriteStartElement("ApplicationSettings");
	vXMLWriter.WriteAttribute("ApplicationName", XMLString(vApplicationName));
	vXMLWriter.WriteAttribute("ApplicationVersion", XMLString(vApplicationVersion));
	vXMLWriter.WriteEndElement();
	vResult = vXMLWriter.Close();
	
	Return vResult;
EndFunction // DriverApplicationParameters

#EndRegion