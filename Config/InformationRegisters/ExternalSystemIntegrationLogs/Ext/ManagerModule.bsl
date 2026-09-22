
#Region Public

// --------------------------------------------------------------------------------
//
// Parameters:
//  pData			 - Object - Data
//  pReceiverNode	 - IntegrationServices.DataExchangeInterfaces - Data exchange interfaces
//
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// NOTHING SO FAR
EndProcedure // ExchangePlansRecordChanges

// --------------------------------------------------------------------------------
//  Procedure - Write log
//
// Parameters:
//  pExternalSystem	 - CtalogRef.ExternalSystemInteractions	 - Ref
//  pFunctionName	 - String								 - FunctionName
//  pEventType		 - Enums.ExternalSystemEventTypes		 - Enum ref
//  pRequest		 - String								 - Request
//  pResponse		 - String								 - Response
//  pDescription	 - String								 - Description
//  pMaxLogLength	 - Number								 - MaxLogLength
//  pUUID			 - 										 - UUID row
//  pTimestamp		 - Date									 - Timestamp
//
Procedure WriteLog(pExternalSystem, pFunctionName, pEventType, pRequest = Undefined, pResponse = Undefined, pDescription = Undefined, pMaxLogLength = 20000, pUUID="", pTimestamp = Undefined) Export
	
	If Not (ValueIsFilled(pExternalSystem) And ValueIsFilled(pFunctionName) And ValueIsFilled(pEventType)) Then
		Return;
	EndIf;
	
	vMaxLogLenght = pMaxLogLength; 
	If pExternalSystem.MaxLogLenght > vMaxLogLenght Then
		vMaxLogLenght = pExternalSystem.MaxLogLenght;
	ElsIf vMaxLogLenght = 0 Then
		vMaxLogLenght = 20000;
	EndIf;
	
	vRequest = "";
	If TypeOf(pRequest) = Type("Structure") Or TypeOf(pRequest) = Type("Map") Or TypeOf(pRequest) = Type("Array") Then
		vRequest = Catalogs.DataConvertationRules.MapToJSON(pRequest);
	Else
		vRequest = pRequest;
	EndIf;
	
	vResponse = "";
	If TypeOf(pResponse) = Type("Structure") Or TypeOf(pResponse) = Type("Map") Or TypeOf(pResponse) = Type("Array") Then
		vResponse = Catalogs.DataConvertationRules.MapToJSON(pResponse);
	Else
		vResponse = pResponse;
	EndIf;
	
	vDescription = "";
	If TypeOf(pDescription) = Type("Structure") Or TypeOf(pDescription) = Type("Map") Or TypeOf(pDescription) = Type("Array") Then
		vDescription = Catalogs.DataConvertationRules.MapToJSON(pDescription);
	Else
		vDescription = pDescription;
	EndIf;
	
	vRequest		= Left(vRequest, vMaxLogLenght);
	vResponse		= Left(vResponse, vMaxLogLenght);
	vDescription	= Left(vDescription, vMaxLogLenght);
	If IsBlankString(pUUID) Then
		pUUID		= String(New UUID());
	EndIf;
	
	If pTimestamp = Undefined Then
		pTimestamp = CurrentSessionDate();
	EndIf;
		
	vQuerry = New Query;
	vQuerry.Text = 
	"SELECT
	|	ExternalSystemInteractions.DataProcessor AS DataProcessor
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	ExternalSystemInteractions.IsActive
	|	AND NOT ExternalSystemInteractions.DeletionMark
	|	AND ExternalSystemInteractions.Status = VALUE(Enum.IntegrationStatuses.Success)
	|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.ExternalLogSystem)
	|	AND NOT ExternalSystemInteractions.UseClient";
	vDataProcessors = vQuerry.Execute().Unload();
	
	vDataProcessor = Undefined;
	If vDataProcessors.Count() > 0 Then
		vDataProcessor = vDataProcessors[0].DataProcessor;
	EndIf;
	
	If vDataProcessor <> Undefined Then
		vDPO = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessor, True);
		If vDPO <> Undefined Then
			If vDPO.WriteLog(pTimestamp, vDescription, pExternalSystem, pFunctionName, pEventType, pUUID, vResponse, vRequest) Then
				Return;	
			EndIf;
		EndIf;
	EndIf;
		
	Try
		vRecMng					= InformationRegisters.ExternalSystemIntegrationLogs.CreateRecordManager();
		vRecMng.ExternalSystem	= pExternalSystem;
		vRecMng.FunctionName	= pFunctionName;
		vRecMng.EventType		= pEventType;
		vRecMng.Request			= vRequest;
		vRecMng.Response		= vResponse;
		vRecMng.Description		= vDescription;
		vRecMng.UUID			= pUUID;
		vRecMng.Period			= pTimestamp;

		vRecMng.Write(True);
	Except
		vErrParams = New Map();
		vErrParams.Insert("ExternalSystem", String(pExternalSystem));
		vErrParams.Insert("FunctionName", pFunctionName);
		vErrParams.Insert("EventType", String(pEventType));
		vErrParams.Insert("Request", vRequest);
		vErrParams.Insert("Response", vResponse);
		vErrParams.Insert("Description", vDescription);
		vErrParams.Insert("UUID", pUUID);
		vErrParams.Insert("Period", pTimestamp);
		vErrParams.Insert("Error", ErrorDescription());
		
		vErrJson = Catalogs.DataConvertationRules.MapToJSON(vErrParams);
		WriteLogEvent("WriteExternalSystemIntegrationLogs", EventLogLevel.Error, , , vErrJson);
	EndTry;
EndProcedure

#EndRegion

#Region FormEventHandlers

// --------------------------------------------------------------------------------
Procedure FormGetProcessing(pFormType, pParameters, pSelectedForm, pAdditionalInformation, pStandardProcessing)
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND ExternalSystemInteractions.IsActive
	|	AND ExternalSystemInteractions.Status = VALUE(Enum.IntegrationStatuses.Success)
	|	AND ExternalSystemInteractions.IntegrationType = VALUE(Enum.Integrations.ExternalLogSystem)";
	If Not vQ.Execute().IsEmpty() Then
		pStandardProcessing = False;
		pSelectedForm = "ExternalDataSource.ExternalLogs.Table.ExternalLogs.ListForm";
	EndIf;                                             
EndProcedure // FormGetProcessing

#EndRegion
