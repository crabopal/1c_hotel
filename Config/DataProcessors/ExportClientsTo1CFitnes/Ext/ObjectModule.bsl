
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure - Not use
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // pmLoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // pmSaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	// For API compatibility	
EndProcedure // pmFillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//  Run data processor in silent mode
//
// Parameters:
//  pParameter		 - Structure - Not use
//  pIsInteractive	 - Boolean	 - Is interactive
//
Procedure pmRun(pParameter = Undefined, pIsInteractive = False) Export
			    
	Check = CheckInteractionParameters(InteractionParameters); 
	If Not Check = True Then 
		Raise Check;	
	EndIf;
	
	vClients = GetClientsToExport();
	
	If vClients.Count() > 0 Then
		vAnswer = Write2Fitnes(vClients);
		If vAnswer.StatusCode = 200 Then
			vObjInteractionParameters = InteractionParameters.GetObject();
			vObjInteractionParameters.LastFullSynchronizationTime = CurrentSessionDate();
			vObjInteractionParameters.Write();	
		EndIf;
	Else 
		vObjInteractionParameters = InteractionParameters.GetObject();
		vObjInteractionParameters.LastFullSynchronizationTime = CurrentSessionDate();
		vObjInteractionParameters.Write();
	EndIf;
EndProcedure // pmRun

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function Write2Fitnes(pClients)
	// Open connection and send data to http
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	
	vCodeHotelArr	 = New Structure;    
	vClientsArr 	 = New Structure;
	vResult		 	 = New Structure;                  
	
	vIndex = 0;
	
	For Each vEl In pClients Do	
		vClient = New  Structure;
		vClient.Insert("FirstName",						vEl.FirstName); 
		vClient.Insert("SecondName",					vEl.SecondName);
		vClient.Insert("LastName",						vEl.LastName);
		vClient.Insert("CodeClient", 					vEl.Code);
		vClient.Insert("DateOfBirth",					Format(vEl.DateOfBirth, "DLF=Д"));
		vClient.Insert("Phone",							vEl.Phone );
		vClient.Insert("Email",							vEl.EMail);
		vClient.Insert("Citizenship",					vEl.Citizenship.ISOCode3);   
		vClient.Insert("Address",						vEl.Address);
		
		vClient.Insert("IdentityDocumentType", 			vEl.IdentityDocumentType.Description);
		vClient.Insert("IdentityDocumentSeries",		vEl.IdentityDocumentSeries);
		vClient.Insert("IdentityDocumentNumber",		vEl.IdentityDocumentNumber);
		vClient.Insert("IdentityDocumentUnitCode",     	vEl.IdentityDocumentUnitCode);
		vClient.Insert("IdentityDocumentValidToDate",	vEl.IdentityDocumentValidToDate);
		vClient.Insert("IdentityDocumentIssueDate",		vEl.IdentityDocumentIssueDate);
		vClient.Insert("IdentityDocumentIssuedBy",		vEl.IdentityDocumentIssuedBy);
			  		
		vClientsArr.Insert("Client" + Format(vIndex, "NFD=0; NZ=0; NG="), vClient);
		vIndex = vIndex + 1;
	EndDo;
			
	vCodeHotelArr.Insert("Code", TrimAll(InteractionParameters.Hotel.Code));
	
	vResult.Insert("Hotel", vCodeHotelArr);
	vResult.Insert("Clients", vClientsArr);
				
	WriteJSON(JSONWriter, vResult);	 
	vResult = JSONWriter.Close();
	
	Return SendHTTPRequest(vResult);
EndFunction // Write2Fitnes 

// -----------------------------------------------------------------------------
Function CheckInteractionParameters(InteractionParameters)
		If Not ValueIsFilled(InteractionParameters) Then
			Raise NStr("en = '1C:Fitnes interface service address should be specified!'; 
					   |de = '1C:Fitnes-Schnittstellendienstadresse sollte angegeben werden!'; 
					   |ru = 'Укажите интеграцию для 1С:Фитнеса!'");	
		EndIf;                     
		
		If Not ValueIsFilled(InteractionParameters.Hotel) Then
			Raise NStr("en = 'Specify the hotel in the integration of 1C:Fitness!'; 
					   |de = 'Geben Sie das Hotel bei der Integration von 1C:Fitness an!'; 
					   |ru = 'Укажите гостиницу в интеграции 1С:Фитнес!'");
		EndIf;
		
		If IsBlankString(InteractionParameters.HttpAddress) Then
			Raise NStr("en = 'Specify the address to the http service in the 1C:Fitness integration!'; 
					   |de = 'Geben Sie die Adresse zum http-Dienst in der 1C:Fitness-Integration an!'; 
					   |ru = 'Укажите адрес к http службе в интеграции 1С:Фитнес!'");
		EndIf;
		
		If IsBlankString(InteractionParameters.WebhookURL) Then
			Raise NStr("en = 'Specify http resource in 1C:Fitness integration!'; 
					   |de = 'Geben Sie die HTTP-Ressource in der 1C:Fitness-Integration an!'; 
					   |ru = 'Укажите http ресурс в интеграции 1С:Фитнес!'");
		EndIf;
		
		If IsBlankString(InteractionParameters.Login) Then
			Raise NStr("en = 'Enter your login in 1C:Fitness integration!'; 
					   |de = 'Geben Sie Ihr Login in die 1C:Fitness-Integration ein!'; 
					   |ru = 'Укажите логин в интеграции 1С:Фитнес!'");
		EndIf;
		
		If IsBlankString(InteractionParameters.Password) Then
			Raise NStr("en = 'Specify the password in 1C:Fitness integration!'; 
					   |de = 'Geben Sie das Passwort in der 1C:Fitness-Integration an!'; 
					   |ru = 'Укажите пароль в интеграции 1С:Фитнес!'");
		EndIf;
		
		Return True;
EndFunction // CheckInteractionParameters

// -----------------------------------------------------------------------------
Function GetClientsToExport()
	vQuery				=	New Query;
	vQuery.Text			=
	"SELECT
	|	ClientChangeHistorySliceLast.Client AS Client
	|FROM
	|	InformationRegister.ClientChangeHistory.SliceLast(
	|			,
	|			Period >= &qPeriodFrom
	|				AND NOT Client.DeletionMark
	|				AND NOT Client.IsFolder) AS ClientChangeHistorySliceLast";
	
	vQuery.SetParameter("qPeriodFrom", InteractionParameters.LastFullSynchronizationTime);
	
	Return vQuery.Execute().Unload().UnloadColumn("Client");
EndFunction // GetClientsToExport

// --------------------------------------------------------------------------------
Function SendHTTPRequest(pRequestBody)
	
	vResult = New Structure("StatusCode, Body, Error, Raw");
    vFuncName = NStr("en = 'Fitness.SendHTTPRequest'; de = 'Fitness.SendHTTPRequest'; ru = 'Fitness.SendHTTPRequest'");
	Try           
		vHTTPServer = TrimAll(InteractionParameters.HttpAddress); 
		vRequestURL = TrimAll(InteractionParameters.WebhookURL); 
		vUser = InteractionParameters.Login;
		vPassword = InteractionParameters.Password;
										
		vHTTPConnection = New HTTPConnection(vHTTPServer,, vUser, vPassword);
		vHTTPRequest = New HTTPRequest(vRequestURL);
		 
		vHTTPRequest.SetBodyFromString(pRequestBody);
		vRequestBody = pRequestBody;
		
		vRs = vHTTPConnection.Post(vHTTPRequest);
				
		vResult.StatusCode	= vRs.StatusCode;
		vResult.Body 		= vRs.GetBodyAsString();  
		
		If Not vResult.StatusCode = 200 Then  
			vMsg = NStr("en = '%1, Failed to send request! Status code: %2'; 
						|de = '%1, Anfrage konnte nicht gesendet werden! Status code: %2'; 
						|ru = '%1, Не удалось отправить запрос! Статус кода: %2'");
			vError = StrTemplate(vMsg, String(InteractionParameters), String(vResult.StatusCode));
			WriteLogEvent(vFuncName, EventLogLevel.Warning, ,CurrentSessionDate(), "" + vError);
			vResult.Error = vError;
			vLogEventType = Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, vLogEventType, vRequestBody, vResult.Body, vError);	
		EndIf;
	Except
		vMsg = NStr("en = '%1, Failed to send request! Status code: %2'; 
					|de = '%1, Anfrage konnte nicht gesendet werden! Status code: %2'; 
					|ru = '%1, Не удалось отправить запрос! Статус кода: %2'");
		vError = StrTemplate(vMsg, String(InteractionParameters), String(vResult.StatusCode));
		WriteLogEvent(vFuncName, EventLogLevel.Warning, ,CurrentSessionDate(), "" + vError);
		vResult.Error = vError;
		vLogEventType = Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(InteractionParameters, vFuncName, vLogEventType, , , vError);	
	EndTry;
	
	If InteractionParameters.DebugMode Then
		vLogStructure = New Structure;
		vLogStructure.Insert("Action", 						vFuncName);
		vLogStructure.Insert("ExternalSystemInteractions", 	String(InteractionParameters));
		vLogStructure.Insert("RequestURL", 					vRequestURL);
		If StrLen(vRequestURL) > 100 Then
			vMap = New Map;
			vMap.Insert("RequestURL", 	vRequestURL);
			vMap.Insert("RequestBody", 	vRequestBody);
			vRequestBody = Catalogs.DataConvertationRules.MapToJSON(vMap);
		EndIf;   
		vLogStructure.Insert("RequestBody", 				vRequestBody);
		vLogStructure.Insert("ResponseStatus", 				vResult.StatusCode);
		vLogStructure.Insert("ResponseBody", 				vResult.Body);
		vLogStructure.Insert("Error", 						vResult.Error);
		
		Catalogs.ExternalSystemInteractions.WriteLog(InteractionParameters, vLogStructure);	
	EndIf;
	
	Return vResult;	
EndFunction // SendHTTPRequest

#EndRegion 
