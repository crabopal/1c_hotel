#Region Public

// -----------------------------------------------------------------------------
//  Function - Send query to bus
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pData					 - String								 - Data
//  pCommand				 - String								 - Command
// 
// Returns:
//  Boolean - Status
//
Function SendQueryToBus(pInteractionParameters, pData, pCommand) Export  	
	If ValueIsFilled(pInteractionParameters.HttpServer) Then	
		vHTTPServer = StrReplace(StrReplace(pInteractionParameters.HttpServer, "https://", ""), "http://", "");
	Else
		vHTTPServer = "127.0.0.1:5013";	
	EndIf;
	Try
	
		// HTTP connection
		vHTTPConnection = New HTTPConnection(vHTTPServer);
		
		vHeaders = New Map;
		vHeaders.Insert("Token", pInteractionParameters.InteractionID); 
		
		// Send query
		vHTTPRequest = New HTTPRequest(TrimAll(pCommand), vHeaders);

		vHTTPRequest.SetBodyFromString(pData, TextEncoding.UTF8);

		vRS = vHTTPConnection.CallHTTPMethod("POST", vHTTPRequest);
		
		If vRS.StatusCode = 200 Then
			If pInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQuery", Enums.ExternalSystemEventTypes.Info, pData, vRS.GetBodyAsString(TextEncoding.UTF8), "", pInteractionParameters.MaxLogLenght); 	
			EndIf;
			Return True;	
		Else   
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQuery", Enums.ExternalSystemEventTypes.Error, pData, vRS.GetBodyAsString(TextEncoding.UTF8), "Failed to send post query!", pInteractionParameters.MaxLogLenght);
			Return False;	
		EndIf;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQuery", Enums.ExternalSystemEventTypes.Error, pData, "", "Failed to send post query! " + BriefErrorDescription(vError), pInteractionParameters.MaxLogLenght); 
		Return False;
	EndTry;	
EndFunction // SendQueryToBus 

// -----------------------------------------------------------------------------
//  Function - Send query to web service
//
// Parameters:
//  pInteractionParameters	 - CatalogRef.ExternalSystemInteractions - Interaction parameters
//  pMethod					 - String								 - Method
//  pData					 - String								 - Data
//  pType					 - String								 - Type
//  pIsLogin				 - Boolean								 - Is login
// 
// Returns:
//  Map, String - Result
//
Function SendQueryToWebService(pInteractionParameters, pMethod, pData, pType, pIsLogin = False) Export  	
	Try  
		vHttp = StrReplace(StrReplace(pInteractionParameters.WSHost, "https://", ""), "http://", "");
		vHTTPServer = Left(vHttp, StrFind(vHttp, "/") - 1);
		vHttpAddress = Right(vHttp, StrLen(vHttp) - StrFind(vHttp, "/") + 1);	
		
		If Right(vHttpAddress, 1) <> "/" Then
			vHttpAddress = vHttpAddress + "/";	
		EndIf; 
		
		vHttpAddress = vHttpAddress + TrimAll(pType);
		
		vHTTPConnection = New HTTPConnection(TrimAll(vHTTPServer));
		
		vHeaders = New Map;
		vHeaders.Insert("Content-Type", "application/json");
		If Not pIsLogin Then
			vHeaders.Insert("Authorization", "Bearer " + pInteractionParameters.OAuth_AccessToken);
		EndIf;
		
		vHTTPRequest = New HTTPRequest(TrimAll(vHttpAddress), vHeaders);
		vHTTPRequest.SetBodyFromString(pData, TextEncoding.UTF8);

		vRS = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
		
		If vRS.StatusCode = 200 Then
			rResult = vRS.GetBodyAsString(TextEncoding.UTF8);
			If pInteractionParameters.DebugMode Then
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQueryToWebService." + pType, Enums.ExternalSystemEventTypes.Info, pData, vRS.GetBodyAsString(TextEncoding.UTF8), "", pInteractionParameters.MaxLogLenght); 	
			EndIf;  
			If Not IsBlankString(rResult) Then
				Return Catalogs.DataConvertationRules.JSONtoMap(rResult);
			Else 
				Return New Map;	
			EndIf;
		Else  
			rResult = vRS.GetBodyAsString(TextEncoding.UTF8);
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQueryToWebService." + pType, Enums.ExternalSystemEventTypes.Error, pData, vRS.GetBodyAsString(TextEncoding.UTF8), "Failed to send post query!", pInteractionParameters.MaxLogLenght);
			Return rResult;	
		EndIf;
	Except
		vError = ErrorInfo();
		rResult = "Failed to send post query! " + BriefErrorDescription(vError);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteractionParameters, "SendQueryToWebService." + pType, Enums.ExternalSystemEventTypes.Error, pData, "", rResult, pInteractionParameters.MaxLogLenght); 
		Return rResult;
	EndTry;	
EndFunction // SendQueryToWebService

#EndRegion