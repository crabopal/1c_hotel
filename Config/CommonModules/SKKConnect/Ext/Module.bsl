
#Region Public

// ---------------------------------------------------------------------------------
Procedure Sync() Export
	
	vInterectionParameters 	= GetInteractionParameters();
	vCurrentSessionDate		= CurrentSessionDate();
	If Not ValueIsFilled(vInterectionParameters) Then	
		Return;
	EndIf;
	
	GetOrders(vInterectionParameters);
	vReservationList 	= GetReservationsToUpdate(vInterectionParameters.LastFullSynchronizationTime, vInterectionParameters);
	vUpdateResult 		= UpdateOrder(vInterectionParameters, vReservationList);
	
	vExternalQuotaCodes = New Array;
	For Each vReservation In vReservationList Do
		vHashText		= String(vReservation.Hotel.UUID()) + String(vReservation.RoomType.UUID()) + String(vReservation.CheckInDate) + String(vReservation.CheckOutDate);
		
		vDataHashing = New DataHashing(HashFunction.MD5);	
		vDataHashing.Append(vHashText);
		vExternalCode	 = StrReplace(vDataHashing.HashSum, " ", "");
		
		If vExternalQuotaCodes.Find(vExternalCode) = Undefined Then
			vExternalQuotaCodes.Add(vExternalCode);
		EndIf;
		
	EndDo;
	
	If vExternalQuotaCodes.Count() > 0 Then
		UpdateQuota(vInterectionParameters, vExternalQuotaCodes);
	EndIf;
	
	vObj = vInterectionParameters.GetObject();
	vObj.LastFullSynchronizationTime = vCurrentSessionDate;
	vObj.Write();
	
EndProcedure

// ---------------------------------------------------------------------------------
Procedure InitializeJSONSettings() Export
	
	#Region Load
	
	// subscribe
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "subscribe", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ 	""url"":""http://192.162.154.12/app/listener/"" }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_subscribe_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "subscribe", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	// quota
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "quota", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ 	""quotaList"": [ 		{ 			""GUID"":""123-1233-1234-123"", 			""branchGUID"":""123-1233-1234-122"", 			""classGUID"":""123-1233-1234-123"", 			""dateFrom"":""2018-12-11T00:00:00"", 			""dateTo"":""2018-12-31T00:00:00"", 			""amount"":9 		} 	] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_quota_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "quota", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	// quota/update/
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "quota/update", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ 	""quotaList"": [ 		{ 			""GUID"":""123-1233-1234-123"", 			""amount"":9 		} 	] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_quota/update_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "quota/update", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	// orders/update/
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "orders/update", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""ordersList"":[ { ""ID"":1231241, ""status"":{ ""GUID"":""312-123123-123123-112"" }, ""number"":""123123123"", ""date"":""2018-12-11T00:00:00"", ""file"":""iVBORw0KGgoAAAANSUhEUgAAACYAAAABAQMAAACIWk5jAAAABlBMVEUAAADf398zft1XAAAAAXRSTlMAQObYZgAAAAtJREFUCB1jOAMCAAv6A/3MLzcFAAAAAElFTkSuQmCC"", ""fileName"":""scan.png"" } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_orders/update_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "orders/update", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	#EndRegion
	
	#Region Upload
	
	// reset
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "reset", Enums.DataConvertationTypes.JSONUpload);
	
	If vRules = Undefined Then 
		vJSONString						= "{ 	""tn"":""12376123ghgadsdh1hdas8dnnnudasdnasdaj23n"" }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONUpload;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_reset_Response";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "reset", Enums.DataConvertationTypes.JSONUpload, vLoadRule.Ref);
	EndIf;
	
	// quota	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "quota", Enums.DataConvertationTypes.JSONUpload);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""data"": { ""update"":10, ""add"":12, ""errors"":3 }, ""errors"":[ { ""errorCode"":1000, ""errorMessage"":""Не найден филиал"", ""errorData"":{ ""GUIDs"" : [ ""323-1233-1234-123"" ] } }, { ""errorCode"":1001, ""errorMessage"":""Не найдена категория"", ""errorData"":{ ""GUIDs"" : [ ""123-1233-1234-123"", ""223-1233-1234-123"" ] } } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONUpload;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_quota_Response";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "quota", Enums.DataConvertationTypes.JSONUpload, vLoadRule.Ref);
	EndIf;
	
	// quota/update/
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "quota/update", Enums.DataConvertationTypes.JSONUpload);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""data"": { ""update"":10, ""errors"":1 }, ""errors"":[ { ""errorCode"":1002, ""errorMessage"":""Квота не найдена"", ""errorData"":{ ""GUIDs"" : [ ""123-1233-1234-123"" ] } } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONUpload;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_quota/update_Response";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "quota/update", Enums.DataConvertationTypes.JSONUpload, vLoadRule.Ref);
	EndIf;
	
	// orders
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "orders", Enums.DataConvertationTypes.JSONUpload);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""data"":[ { ""cancellationList"":[ { ""id"":123444, ""reason"":{ ""GUID"":""1231-123123-123123-1211"" } } ], ""orderList"":[ { ""id"":123344, ""quote"":{ ""GUID"":""1233-123123-123123-1231"" }, ""amount"":2, ""peoples"":[ { ""ID"":12312442, ""applicant"":1, ""lastName"":""Иванов"", ""name"":""Иван"", ""secondName"":""Иванович"", ""birthday"":""1918-12-11T00:00:00"", ""sex"":""M"", ""phone"":""+7-903-888-78-79"", ""email"":""ivan@ivanov.ru"", ""address"":{ ""fiasID"":""3123123123123123123"", ""dadata"":{}, ""raw"":""дедушкина деревня"" }, ""snils"":""123-12341123-123 79"", ""lgota"":{ ""GUID"":""1233-123123-123123-1232"" }, ""rank"":{ ""GUID"":""1233-123123-124123-2232"", ""active"":1 }, ""sertificate"":{ ""date"":""2018-11-11T00:00:00"", ""number"":""1"", ""diagnosis"":""A50.0"", ""source"":""Поликлиника"", ""fileURL"":""/local/getfile.php?token=3sad123123mnbn1b23124142nnm1231213msdm12m3hdjakdkkj"" } }, { ""ID"":12312443, ""applicant"":0, ""lastName"":""Иванов"", ""name"":""Василий"", ""secondName"":""Иванович"", ""birthday"":""1908-12-11T00:00:00"", ""sex"":""M"", ""snils"":""123-12341123-123 79"", ""lgota"":{ ""ID"":""123123123"", ""name"":""Некая льгота"" }, ""sertificate"":{ ""date"":""2018-11-11T00:00:00"", ""number"":""2"", ""diagnosis"":""A50.0"", ""source"":""Поликлиника"", ""fileURL"":""/local/getfile.php?token=3sad123123mnbn1b23124142nnm1231213msdm12m3hdjakdkkj"" } } ] } ] } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONUpload;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_orders_Response";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "orders", Enums.DataConvertationTypes.JSONUpload, vLoadRule.Ref);
	EndIf;
	
	#EndRegion
	
EndProcedure // InitializeJSONSettings

// ---------------------------------------------------------------------------------
Function GetInteractionParameters() Export
	
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	ExternalSystemInteractions.Ref AS Ref
	|FROM
	|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
	|WHERE
	|	NOT ExternalSystemInteractions.DeletionMark
	|	AND ExternalSystemInteractions.IsActive
	|	AND ExternalSystemInteractions.InteractionID = &qInteractionID";
	vQuery.SetParameter("qInteractionID", "skkpodmoskovie.ru");
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
		Break;
	EndDo;
	
	Return vResult;
	
EndFunction // GetInteractionParameters

// ---------------------------------------------------------------------------------
// Api/reset/
Procedure UpdateToken(pInterectionParameters) Export
	
	Try
		vResult 		= New Structure("Token, ErrorDescription", "", "");
		vMessageName 	= "reset";
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/reset/", "GET", "reset");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONUpload);
			If vRules = Undefined Then
				vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResult.ErrorDescription);
				Return;
			EndIf;
			
			vJSONStructure 		= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);	
			
			If vJSONStructure.Property("tn") Then
				vResult.Token = vJSONStructure.tn;
				
				vInterectionParametersObj = pInterectionParameters.GetObject();
				vInterectionParametersObj.SessionID = vResult.Token;
				vInterectionParametersObj.Write();
				
				vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResult.ErrorDescription);
			Else
				vResult.ErrorDescription = "Didnt recive new token from SKK api!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;	
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResult.ErrorDescription);
			EndIf;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResponseDescription.StatusDescription);
		EndIf;
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/quota/
Procedure SendQuota(pInterectionParameters) Export
	
	Try
		vMessageName = "quota";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetQuotaJSON(pInterectionParameters);
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		If ValueIsFilled(vJSON.ErrorDescription) Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, , vJSON.ErrorDescription);
		EndIf;
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/quota/", "POST", "quota", vJSON.JSONString, "JSON");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		EndIf;
		
		vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
		
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, vResponse.Body, vResponseDescription.StatusDescription);	
		
		If vResponseDescription.Success Then
			CleanEmptyQuotaIDs(pInterectionParameters);
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/quota/update/
Procedure UpdateQuota(pInterectionParameters, pExternalCodes = Undefined) Export
	
	Try
		vMessageName 	= "quota/update";
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetQuotaUpdateJSON(pInterectionParameters, pExternalCodes);
		
		If ValueIsFilled(vJSON.ErrorDescription) Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, , vJSON.ErrorDescription);
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/quota/update/", "POST", "quota/update", vJSON.JSONString, "JSON");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, vResponse.Body, vResponseDescription.StatusDescription);
		EndIf;
		
		vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
			
		If vResponseDescription.Success Then
			CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes);
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/quota/update/annulation
Procedure AnnulQuota(pInterectionParameters, pExternalCodes = Undefined) Export
	Try
		vMessageName 	= "quota/update/annulation";
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetQuotaAnnulJSON(pInterectionParameters, pExternalCodes);
		
		If ValueIsFilled(vJSON.ErrorDescription) Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, , vJSON.ErrorDescription);
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/quota/update/annulation", "POST", "quota/update", vJSON.JSONString, "JSON");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, vResponse.Body, vResponseDescription.StatusDescription);
		EndIf;
		
		vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
		
		If vResponseDescription.Success Then
			CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes);
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/subscribe/
Procedure Subscribe(pInterectionParameters) Export
	
	Try
		vMessageName = "subscribe";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetSubscribeJSON(pInterectionParameters);
		
		If ValueIsFilled(vJSON.ErrorDescription) Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, , vJSON.ErrorDescription);
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/subscribe/", "POST", "subscribe", vJSON.JSONString, "JSON");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		EndIf;
		
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, vResponse.Body, vResponseDescription.StatusDescription);
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/subscribe/off/
Procedure Unsubscribe(pInterectionParameters) Export
	
	Try
		vMessageName = "Unsubscribe";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/subscribe/off/", "GET", "subscribe");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		EndIf;
		
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResponseDescription.StatusDescription);
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/orders/
Procedure GetOrders(pInterectionParameters) Export
	
	Try
		vMessageName 	= "orders";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/orders/", "GET", "orders");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, vResponse.Body, vResponseDescription.StatusDescription);	
		EndIf;
				
		If vResponseDescription.Success Then
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
			ProcessOrders(pInterectionParameters, vJSONStructure);	
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/orders/update/
Function UpdateOrder(pInterectionParameters, pReservationList, pCustomCode = Undefined) Export
	
	vResult = False;
	Try
		vMessageName 	= "orders/update";
		
		If pInterectionParameters = Undefined Then
			Return vResult;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		If TypeOf(pReservationList) <> Type("Array") Then
			vReservationList = New Array;
			vReservationList.Add(pReservationList);
		Else
			vReservationList = pReservationList;	
		EndIf;
		
		vJSON 		= GetOrderUpdateJSON(pInterectionParameters, vReservationList, pCustomCode);
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/orders/update/", "POST", "orders/update", vJSON.JSONString, "JSON");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		vResult					= vResponseDescription.Success;
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONStringNoFile, vResponse.Body, vResponseDescription.StatusDescription);
		EndIf;
		
		vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
		CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);

		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetReservationsToUpdate(pPeriodFrom, pInterectionParameters) Export
	
	vResult = New Array;
	
	vDocumentTypes 	= New Array;
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_accepted"));
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined"));
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False); 
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Reservations.Ref AS Ref
		|INTO ReservationsChanged
		|FROM
		|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriodFrom, ) AS ReservationChangeHistorySliceLast
		|		LEFT JOIN Document.Reservation AS Reservations
		|		ON ReservationChangeHistorySliceLast.Reservation = Reservations.Ref
		|WHERE
		|	Reservations.ReservationStatus <> ReservationChangeHistorySliceLast.ReservationStatus
		|	AND Reservations.ExternalCode <> """"
		|	AND Reservations.ReservationStatus <> &qReservationStatus
		|	AND Reservations.Guest <> &qEmptyGuest
		|	AND ReservationChangeHistorySliceLast.Reservation.AccommodationTemplate <> &qEmptyAccommodationTemplate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservation.Ref AS Ref
		|INTO ReservationsFileChanged
		|FROM
		|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
		|		LEFT JOIN Document.Reservation AS Reservation
		|		ON GuestGroupAttachments.GuestGroup = Reservation.GuestGroup
		|			AND GuestGroupAttachments.ReservationNumber = Reservation.Number
		|WHERE
		|	GuestGroupAttachments.Period >= &qPeriodFrom
		|	AND Reservation.ExternalCode <> """"
		|	AND Reservation.ReservationStatus <> &qReservationStatus
		|	AND GuestGroupAttachments.DocumentType IN(&qDocumentTypes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReservationsChanged.Ref AS Ref,
		|	ReservationsChanged.Ref.Number AS Number
		|FROM
		|	ReservationsChanged AS ReservationsChanged
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ReservationsFileChanged.Ref,
		|	ReservationsFileChanged.Ref.Number
		|FROM
		|	ReservationsFileChanged AS ReservationsFileChanged
		|
		|ORDER BY
		|	Number";
	
	vQuery.SetParameter("qDocumentTypes", 				vDocumentTypes);
	vQuery.SetParameter("qPeriodFrom", 					pPeriodFrom);
	vQuery.SetParameter("qReservationStatus", 			vReservationStatus);
	vQuery.SetParameter("qEmptyAccommodationTemplate", 	Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", 					Catalogs.Clients.EmptyRef());
	
	vReservationsTable = vQuery.Execute().Unload();	
	
	vResultNumbers = New Array;
	For Each vRow In vReservationsTable Do		
		If vResultNumbers.Find(vRow.Number) = Undefined Then
			vResultNumbers.Add(vRow.Number);
		EndIf;
	EndDo;
	
	For Each vRow In vResultNumbers Do
		vRef = vReservationsTable.Find(vRow, "Number").Ref;
		vResult.Add(vRef);
	EndDo;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Procedure SetVirtualQuotaCode(pReservationStatus, pHotel, pRoomType, pCheckInDate, pCheckOutDate, pGuest, pInteractionID, rExternalCode) Export
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInteractionID, "ReservationStatusesDefault", pInteractionID, False);
	
	vDeleteExternalCode = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInteractionID, "DeleteExternalCode", pReservationStatus, True);
	If ValueIsFilled(vDeleteExternalCode) Then
		rExternalCode = "";	
		Return;
	EndIf;
	
	If vReservationStatus = pReservationStatus And Not ValueIsFilled(pGuest) Then
		vHashText		= String(pHotel.UUID()) + String(pRoomType.UUID()) + String(pCheckInDate) + String(pCheckOutDate);
		
		vDataHashing = New DataHashing(HashFunction.MD5);	
		vDataHashing.Append(vHashText);
		rExternalCode	 = StrReplace(vDataHashing.HashSum, " ", "");
		
		vRecMng 					= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecMng.Hotel 				= pHotel;
		vRecMng.ExternalSystemCode 	= pInteractionID;
		vRecMng.ObjectTypeName 		= "SSKQuota";
		vRecMng.ObjectExternalCode 	= rExternalCode;
		vRecMng.Write(True);			
	EndIf;
	
EndProcedure

// ---------------------------------------------------------------------------------
Function GetHashSum(pText) Export
	
	vResult	= Undefined;
	
	vDataHashing = New DataHashing(HashFunction.MD5);	
	vDataHashing.Append(pText);
	vResult = StrReplace(vDataHashing.HashSum, " ", "");
	
	Return vResult;
	
EndFunction

#EndRegion

#Region Internal

// ---------------------------------------------------------------------------------
// Creating reservations
Procedure ProcessOrders(pInterectionParameters, pJSONStructure)
	
	vOrderData 		= Undefined;
	vMessageName 	= "ProcessOrders";
	vNoHotelCode	= "68f6595b-bcd3-11e8-9a45-999999999999";
	Try
		If pJSONStructure <> Undefined And pJSONStructure.Property("data", vOrderData) Then
			If vOrderData <> Undefined Then
				
				vQuotaChanged 		= False;
				vReservationArray	= New Array;
				vFailedOrders		= New Array;
				vExternalQuotaCodes	= New Array;
				
				If vOrderData.Property("orderList") Then
					For Each vOrderDataRow In vOrderData.orderList Do
						
						vQuoteStructure 	= Undefined;
						vGUID 				= Undefined;
						vReservationsList 	= Undefined;
						vFirstReservation	= True;
						vExternalCode 		= Undefined;
						vAmount				= 0;
						vPeoples			= Undefined;
						vMainAddress		= "";
						vGuestGroup			= Undefined;
						vReservationCode	= Undefined;
						
						vHotel 				= Undefined;
						vDefaultRoomType 	= Undefined;
						vDefaultRoomRate 	= Undefined;
						vDefaultReservationStatus = Undefined;
						vType = "";
						vOrderDataRow.Property("type", vType);
						vType = String(vType);
						vSko		= Undefined;
						vHotelCode 	= "";
						vOrderDataRow.Property("sko", vSko);
						If vSko <> Undefined Then
							vSko.Property("GUID", vHotelCode);
							vHotelCode = String(vHotelCode);
						EndIf;
						
						If Not (vOrderDataRow.Property("id", vExternalCode) And vOrderDataRow.Property("amount", vAmount) And  vOrderDataRow.Property("peoples", vPeoples)) Then
							vError			= "Missing id, amount or peoples parameters!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							If vOrderDataRow.Property("id", vExternalCode) Then 
								vFailedOrders.Add(vExternalCode);
							EndIf;
							Continue;
						EndIf;
						
						If vType = "1" Then
							If Not vOrderDataRow.Property("quote", vQuoteStructure) Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing quote parameter!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;
							
							If vQuoteStructure = Undefined Or Not vQuoteStructure.Property("GUID", vGUID) Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing GUID parameter!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;
						Else
							
							vHotels = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "Hotels",,,,vHotelCode);
							If vHotels.Count() > 0 Then
								vHotel 				= vHotels[0].RefKey1;
								vDefaultRoomRate	= vHotel.RoomRate;
								vDateFrom = "";
								vOrderDataRow.Property("dateFrom", vDateFrom);
								
								vDateFrom 	= Date(Left(StrReplace(vDateFrom, "-", ""), 8));
								vPeriodFrom	= BegOfMonth(vDateFrom);
								vPeriodTo	= EndOfMonth(vDateFrom);
								vCheckInDate = vPeriodFrom;
							Else
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find hotel by ID:" + vHotelCode;
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
								
								vNoHotel = New Array;
								vNoHotel.Add(vExternalCode);
								UpdateOrder(pInterectionParameters, vNoHotel, vNoHotelCode);
								Continue;	
							EndIf;
							
							vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "RoomTypes",,, vHotel);
							
							If vRoomTypes.Count() > 0 Then
								vDefaultRoomType = vRoomTypes[0].RefKey1;	
							Else
								vError			= "Default room type is not filled in settings!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;
														
							vDefaultReservationStatuses = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "DefaultReservationStatus");	
							If vDefaultReservationStatuses.Count() > 0 Then
								vDefaultReservationStatus = vDefaultReservationStatuses[0].RefKey1;
							EndIf;
							
							If Not ValueIsFilled(vDefaultReservationStatus) Then
								vError			= "Default reservation status is not filled in settings!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;
						EndIf;
						
						vExistedReservation = GetReservationByExternalCode(vExternalCode);
						
						If vExistedReservation <> Undefined Then
							vError			= "Order ID:" + vExternalCode + Chars.LF + "Dublicate! Reservation:" + vExistedReservation;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							vFailedOrders.Add(vExternalCode);
							Continue;
						EndIf;
						
						If vType = "1" Then
							vReservationsList = GetQuotaReservations(pInterectionParameters, vGUID);
							
							If vReservationsList = Undefined Or vReservationsList.Count() = 0 Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find quota by ID!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;
							vHotel 				= vReservationsList[0].Ref.Hotel;
							vDefaultRoomType 	= vReservationsList[0].Ref.RoomType;
							vCheckInDate 		= vReservationsList[0].Ref.CheckInDate;
						EndIf;
						
						vCurrentDate = CurrentSessionDate();
										
						vAgesArray 			= New Array;
						vBirthDatesArray 	= New Array;
						For Each vGuestRow In vPeoples Do
							If vGuestRow.Property("birthday") Then
								vDateString = StrReplace(vGuestRow.birthday, "T", "");
								vDateString = StrReplace(vDateString, "-", "");
								vDateString = StrReplace(vDateString, ":", "");
								vBirthday 	= Date(vDateString);
								vBirthDatesArray.Add(vBirthday);
								vAge		= cmGetClientAge(vBirthday, vCheckInDate);
								vAgesArray.Add(vAge);
							Else
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing birthday parameter in peoples array!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);	
							EndIf;
						EndDo;
						
						If vAgesArray.Count() <> vAmount Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Wrong amount of guests!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							vFailedOrders.Add(vExternalCode);
							Continue;
						EndIf;
						
						// Seearch template by ages
						vAccomodationTemplateList 			= cmGetAccommodationTemplateDetailsByGuestsQuantity(0, vAgesArray.Count(), vAgesArray, vHotel, False);
						
						// Filter Templates by roomType
						vClearArray = New Array;
						For Each vTemplateRow In vAccomodationTemplateList Do
							If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType, "RoomType") = Undefined Then
								vClearArray.Add(vTemplateRow);
							EndIf;						 
						EndDo;
						For Each vClearRow In vClearArray Do
							vAccomodationTemplateList.Delete(vClearRow);
						EndDo;
						
						// Seearch template by adults only						
						If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
							vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAgesArray.Count(), 0, Undefined, vHotel, False);	
							
							// Filter Templates by roomType
							vClearArray = New Array;
							For Each vTemplateRow In vAccomodationTemplateList Do
								If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType, "RoomType") = Undefined Then
									If ValueIsFilled(vDefaultRoomType) And Not vDefaultRoomType.IsFolder And ValueIsFilled(vDefaultRoomType.RoomClass) And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType.RoomClass, "RoomClass") <> Undefined Then
										Continue;
									Else
										vClearArray.Add(vTemplateRow);
									EndIf;
								EndIf;						 
							EndDo;
							For Each vClearRow In vClearArray Do
								vAccomodationTemplateList.Delete(vClearRow);
							EndDo;
						EndIf;
						
						// Get default template
						vAccomodationTemplate 		= Undefined;
						If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
							vAccomodationTemplate = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "AccommodationTemplates", "Default");;	
						EndIf;
						
						// Filter templates by IsForFolioSplit
						If vAccomodationTemplate = Undefined Then
							If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find accomodation type!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							Else
								If vType = "1" And vAmount = 1 And vReservationsList[0].Ref.NumberOfBedsPerRoom > 1 Then
									For Each vTemplateRow In vAccomodationTemplateList Do
										If vTemplateRow.AccommodationTemplate.IsForFolioSplit Then
											vAccomodationTemplate = vTemplateRow.AccommodationTemplate;
											Break;	
										EndIf;
									EndDo;
								Else
									For Each vTemplateRow In vAccomodationTemplateList Do
										If Not vTemplateRow.AccommodationTemplate.IsForFolioSplit Then
											vAccomodationTemplate = vTemplateRow.AccommodationTemplate;
											Break;	
										EndIf;
									EndDo;
								EndIf;
							EndIf;
						EndIf;
						
						
						If vAccomodationTemplate = Undefined Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find accomodation type with folio split!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							vFailedOrders.Add(vExternalCode);
							Continue;
						EndIf;
						
						If vAccomodationTemplate.AccommodationTypes.Count() = 0 Then
							vError			= "Accomodation Template:" + vAccomodationTemplate + Chars.LF + "Accomodation type is empty!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							vFailedOrders.Add(vExternalCode);
							Continue;
						EndIf;
						
						If vType = "1" Then
							// Now find real reservation with template
							vReservationsList = GetQuotaReservations(pInterectionParameters, vGUID, Undefined, vAmount);
							
							If vReservationsList = Undefined Or vReservationsList.Count() = 0 Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find quota by ID!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							EndIf;						
							
							i = 0;
							vLastReservationBuffer 	= Undefined;
							vReservationObj			= Undefined;
							vReservationStatus 		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Order", False);
							If vReservationStatus = Undefined Or Not ValueIsFilled(vReservationStatus) Then
								vError			= "Failed to find default reservation status by externalcode: ""Order""";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;	
							Else
								
								vCustomer 		= Undefined;
								vPostalAddress 	= "";
								BeginTransaction();
								Try
									For Each vAccomodationType In vAccomodationTemplate.AccommodationTypes Do
										
										If vReservationsList.Count() >= i + 1 Then
											
											vReservationObj			= Documents.Reservation.CreateDocument();
											vReservationObj.Hotel 	= vReservationsList[i].Ref.Hotel; 
											vReservationObj.Fill(vReservationsList[i].Ref);
											If i = 0 Then
												vReservationObj.AccommodationTemplate = vAccomodationTemplate;
												
												vGuestGroupObj = vReservationObj.GuestGroup.GetObject();
												vGuestGroupObj.CreateDate = vCurrentDate;
												vGuestGroupObj.Write();
											EndIf;
											
											vLastReservationBuffer = vReservationObj;
										Else
											vReservationObj 		= vLastReservationBuffer.Copy();
											vReservationObj.Date	= vLastReservationBuffer.Date + 1;
											vReservationObj.Number 	= vLastReservationBuffer.Number;
											vReservationObj.AccommodationTemplate = Undefined;
										EndIf;
										
										If vReservationObj <> Undefined Then
											
											vClientData 	= GetClientData(pInterectionParameters, vPeoples, vBirthDatesArray, vAgesArray, i, vReservationObj.Hotel, vOrderDataRow, vMessageName, vCurrentDate);
											vClient 		= vClientData.Client;
											vClientType		= vClientData.ClientType;
											vCustomer		= vClientData.Customer;
											vCertificate	= vClientData.Certificate;
											// (доработка 1 - получение доп. льготы
											vscanExtCategory	= vClientData.scanExtCategory;
											// )доработка 1 - получение доп. льготы
											vEmail			= vClientData.Email;
											vPhone			= vClientData.Phone;
											
											vReservationObj.ReservationStatus 	= vReservationStatus;
											vReservationObj.AccommodationType	= vAccomodationType.AccommodationType;
											vReservationObj.ExternalCode 		= vExternalCode;
											
											vRoomRate	= GetExceptionalRoomRateByClientType(vClientType, vReservationObj.Hotel, pInterectionParameters);
											If vRoomRate <> Undefined Then
												vReservationObj.RoomRate = vRoomRate;
											EndIf;
											
											vReservationObj.HotelProduct = vReservationObj.RoomRate.HotelProductType;
																						
											vReservationObj.Guest 				= vClient;
											vReservationObj.EMail				= vEmail;
											vReservationObj.Phone				= vPhone;
											vReservationObj.ClientType 			= vClientType;
											vReservationObj.Customer			= vCustomer;
											vReservationObj.NumberOfAdults		= vAccomodationTemplate.NumberOfAdults;
											vReservationObj.NumberOfTeenagers	= vAccomodationTemplate.NumberOfTeenagers;
											vReservationObj.NumberOfChildren	= vAccomodationTemplate.NumberOfChildren;
											vReservationObj.NumberOfInfants		= vAccomodationTemplate.NumberOfInfants;
											
											vReservationObj.SourceOfBusiness	= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "SourcesOfBusiness", "Default");
											vReservationObj.pmCalculateResources();
											vReservationObj.pmCalculateServices( , , , , , vReservationObj.IsForFolioSplit);
											
											If ValueIsFilled(vGuestGroup) Then
												vReservationObj.GuestGroup = vGuestGroup;
											EndIf;
											
											If ValueIsFilled(vReservationCode) Then
												vReservationObj.Number = vReservationCode;
											EndIf;
											
											vReservationObj.Write(DocumentWriteMode.Posting);
											vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
											
											vQuotaChanged = True;
											
											If vFirstReservation Then
												vFirstReservation = False;
												vReservationArray.Add(vReservationObj.Ref);
											EndIf;
											
											vExternalQuotaCodes.Add(vGUID);
											
											vGuestGroup			= vReservationObj.GuestGroup;
											vReservationCode 	= vReservationObj.Number;
											
											i = i + 1;
											
											vCertificateInfo 	= New Structure("date, number, diagnosis, source");
											vGetFile 			= False;
											If vCertificate <> Undefined Then
												vGetFile = True;
												FillPropertyValues(vCertificateInfo, vCertificate);
												
												If ValueIsFilled(vCertificateInfo.date) Then
													vDateString 			= StrReplace(vCertificateInfo.date, "T", "");
													vDateString 			= StrReplace(vDateString, "-", "");
													vDateString 			= StrReplace(vDateString, ":", "");
													vCertificateInfo.date 	= Date(vDateString);
												EndIf;
											EndIf;
											
											WriteCertificateToCustomReservationFields(vReservationObj.Ref, vCertificateInfo.number, vCertificateInfo.date, vCertificateInfo.source, vCertificateInfo.diagnosis);
											
											If vGetFile Then
												GetClientFile(pInterectionParameters, vClient, vReservationObj.Number, vReservationObj.GuestGroup, vCertificateInfo);
												// (доработка 1 - получение доп. льготы
											ElsIf vscanExtCategory <> Undefined Then
												GetClientFile_scanExtCategory(pInterectionParameters, vClient, vReservationObj.Number, vReservationObj.GuestGroup);
												// )доработка 1 - получение доп. льготы	
											EndIf;
											
										Else
											vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to create reservation!";
											vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
											InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
											vFailedOrders.Add(vExternalCode);
											Break;	
										EndIf;
										
									EndDo;
									
									CommitTransaction();
								Except
									If TransactionActive() Then
										RollbackTransaction();
									EndIf;
									
									vError			= ErrorDescription();
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
									Continue;
								EndTry;
							EndIf;
						Else
														
							vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
							vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
							vAccomodationTypes 			= vAccomodationTemplate.AccommodationTypes;
							vLastAccommodationType		= Undefined;
							vRoomUUID					= String(New UUID);
							vCertificates				= New Array;
							// (доработка 1 - получение доп. льготы
							vscanExtCategories			= New Array;
							// )доработка 1 - получение доп. льготы
							For i=1 To vAmount Do
								
								vClientData = GetClientData(pInterectionParameters, vPeoples, vBirthDatesArray, vAgesArray, i - 1, vHotel, vOrderDataRow, vMessageName, vCurrentDate);
								If i = 1 Then
									vMainGuest.ClientCode 	= vClientData.Client.ExternalCode;
								EndIf;
								
								vCertificates.Add(vClientData.Certificate);
								// (доработка 1 - получение доп. льготы
								vscanExtCategories.Add(vClientData.scanExtCategory);
								// )доработка 1 - получение доп. льготы
								
								vClient 			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
								vClient.ClientCode 	= vClientData.Client.ExternalCode;
								If vAccomodationTypes.Count() < i Then
									vAccomodationType		= vLastAccommodationType;	
								Else
									vAccomodationType 		= vAccomodationTypes[i-1].AccommodationType.Code;
									vLastAccommodationType 	= vAccomodationType;
								EndIf;
								
								vExternalGroupReservationRow           			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
								If i = 1 Then
									vExternalGroupReservationRow.ReservationCode   	= vExternalCode;	
								Else
									vExternalGroupReservationRow.ReservationCode   	= vExternalCode + "/" + i;
								EndIf;
								
								vExternalGroupReservationRow.GroupCode       	= vExternalCode;
								vExternalGroupReservationRow.GroupClient     	= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));;
								vExternalGroupReservationRow.ReservationStatus  = vDefaultReservationStatus.Code;
								vExternalGroupReservationRow.PeriodFrom      	= vPeriodFrom;
								vExternalGroupReservationRow.PeriodTo      		= vPeriodTo;
								vExternalGroupReservationRow.Hotel        		= vHotel.Code;
								vExternalGroupReservationRow.RoomType      		= TrimAll(vDefaultRoomType.Code);
								vExternalGroupReservationRow.AccommodationType  = TrimAll(vAccomodationType);
								vExternalGroupReservationRow.NumberOfRooms    	= 1;
								vExternalGroupReservationRow.NumberOfPersons  	= 1;
								vExternalGroupReservationRow.ExternalSystemCode = pInterectionParameters.InteractionID;
								vExternalGroupReservationRow.DoPosting      	= True;
								vExternalGroupReservationRow.Room         		= vRoomUUID;
								vExternalGroupReservationRow.ID          		= vExternalCode;
								vExternalGroupReservationRow.Client 			= vClient;
								If vClientData.Customer <> Undefined Then
									vExternalGroupReservationRow.Customer		= TrimAll(vClientData.Customer.Code);
								EndIf;

								If vClientData.ClientType <> Undefined Then
									vExternalGroupReservationRow.ClientType		= TrimAll(vClientData.ClientType.Code);
								EndIf;
								
								vExternalGroupReservationRow.RoomRate = TrimAll(vDefaultRoomRate.Code);
								
								vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
							EndDo;
							
							vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
							If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then								
								vError			= "Failed to create reservation: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + vExternalCode;
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vFailedOrders.Add(vExternalCode);
								Continue;
							Else
								vReservationRow = vAnswerXDTO.ExternalReservationStatusRow[0];
								vReservationRef	= Documents.Reservation.GetRef(New UUID(vReservationRow.UUID));
								
								If vReservationRef <> Undefined Then
									vReservationArray.Add(vReservationRef.Ref);
								EndIf;
								
								i = 0;
								// (доработка 1 - получение доп. льготы
								vArrayInd = New Array;
								// )доработка 1 - получение доп. льготы
								
								For Each vCertificateRow In vCertificates Do
									vCertificateInfo 	= New Structure("date, number, diagnosis, source");
									vGetFile 			= False;
									If vCertificateRow <> Undefined Then
										vGetFile = True;
										// (доработка 1 - получение доп. льготы
										vArrayInd.Add(i);
										// )доработка 1 - получение доп. льготы
										
										FillPropertyValues(vCertificateInfo, vCertificateRow);
										
										If ValueIsFilled(vCertificateInfo.date) Then
											vDateString 			= StrReplace(vCertificateInfo.date, "T", "");
											vDateString 			= StrReplace(vDateString, "-", "");
											vDateString 			= StrReplace(vDateString, ":", "");
											vCertificateInfo.date 	= Date(vDateString);
										EndIf;
									EndIf;
									
									vReservationRow = vAnswerXDTO.ExternalReservationStatusRow[i];
									vReservationRef	= Documents.Reservation.GetRef(New UUID(vReservationRow.UUID));
									
									If vReservationRef <> Undefined Then
										WriteCertificateToCustomReservationFields(vReservationRef.Ref, vCertificateInfo.number, vCertificateInfo.date, vCertificateInfo.source, vCertificateInfo.diagnosis);
										
										If vGetFile Then
											GetClientFile(pInterectionParameters, vReservationRef.Guest, vReservationRef.Number, vReservationRef.GuestGroup, vCertificateInfo);
										EndIf;
									Else
										vError			= "Failed to find reservation to write file! " + vReservationRow.ReservationNumber;
										vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);	
									EndIf;
									i = i + 1;
								EndDo;
								// (доработка 1 - получение доп. льготы
								i = 0;
								For Each scanExtCategoryRow In vscanExtCategories Do
									vGetFile 			= False;
									If vArrayInd.Find(i) <> Undefined Then
										i = i + 1;
										Continue;
									EndIf;	
									If scanExtCategoryRow <> Undefined Then
										vGetFile = True;
									EndIf;
									
									vReservationRow = vAnswerXDTO.ExternalReservationStatusRow[i];
									vReservationRef	= Documents.Reservation.GetRef(New UUID(vReservationRow.UUID));
									
									If vReservationRef <> Undefined Then
										If vGetFile Then
											GetClientFile_scanExtCategory(pInterectionParameters, vReservationRef.Guest, vReservationRef.Number, vReservationRef.GuestGroup);
										EndIf;
									Else
										vError			= "Failed to find reservation to write file! " + vReservationRow.ReservationNumber;
										vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);	
									EndIf;
									i = i + 1;
								EndDo;
								// )доработка 1 - получение доп. льготы
							EndIf;
						EndIf;
					EndDo;					
				EndIf;
				
				If vOrderData.Property("cancellationList") Then
					vExternalCodesArray = New Array;
					For Each vCancellationDataRow In vOrderData.cancellationList Do			
						vExternalCodesArray.Add(vCancellationDataRow.id);						
					EndDo;
					
					vReservationsToAnnulate = GetReservationsByExternalCodes(vExternalCodesArray);
					vAnnulationStatus		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", False);
					If vAnnulationStatus <> Undefined Then
						
						BeginTransaction();
						For Each vCancellationDataRow In vOrderData.cancellationList Do	
							vNumber 	= Undefined;
							vGuestGroup = Undefined;
							vAnnulationRows = vReservationsToAnnulate.FindRows(New Structure("ExternalCode", vCancellationDataRow.id));
							If vAnnulationRows <> Undefined And vAnnulationRows.Count() > 0 Then
								vReturnReservation = Undefined;
								vAnnulationReason = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "UsualActionReasons", vCancellationDataRow.reason.GUID);
								vFirstReservation = True;
								For Each vAnnulationRow In vAnnulationRows Do
									If vFirstReservation Then
										vFirstReservation = False;
										vReservationArray.Add(vAnnulationRow.Ref);
									EndIf;
									vReservationObj 					= vAnnulationRow.Ref.GetObject();
									vReservationObj.AnnulationReason 	= vAnnulationReason;
									vReservationObj.ReservationStatus	= vAnnulationStatus;
									vReservationObj.Write(DocumentWriteMode.Posting);
									vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
									
									vQuotaChanged 	= True;
									vHashText		= String(vReservationObj.Hotel.UUID()) + String(vReservationObj.RoomType.UUID()) + String(vReservationObj.CheckInDate) + String(vReservationObj.CheckOutDate);
									
									vDataHashing = New DataHashing(HashFunction.MD5);	
									vDataHashing.Append(vHashText);
									vExternalCode	 = StrReplace(vDataHashing.HashSum, " ", "");
									
									If vExternalQuotaCodes.Find(vExternalCode) = Undefined Then
										vExternalQuotaCodes.Add(vExternalCode);
									EndIf;
									
								EndDo;
							EndIf;													
						EndDo;		
						CommitTransaction();
						
					Else
						vError			= "Failed to find annulation status by externalcode: ""GuestAnnulation""";
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
					EndIf;
					
				EndIf;
				
				If vReservationArray.Count() > 0 Then
					UpdateOrder(pInterectionParameters, vReservationArray); 
				EndIf;
				
				If vFailedOrders.Count() > 0 Then
					UpdateOrder(pInterectionParameters, vFailedOrders);
					UpdateQuota(pInterectionParameters);
				ElsIf vQuotaChanged And vExternalQuotaCodes.Count() > 0 Then
					UpdateQuota(pInterectionParameters, vExternalQuotaCodes);
				EndIf;
				
			Else
				vError			= "Missing data parameter!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
			EndIf;
		Else
			vError			= "Empty response!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
		EndIf;
	Except
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// Api/orders/file/{ИД_гостя}/
Procedure GetClientFile(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, pCeritifcateInfo)
	
	Try
		vMessageName 	= "orders/file";
		
		If pInterectionParameters = Undefined Or Not ValueIsFilled(pClient) Or Not ValueIsFilled(pClient.ExternalCode) Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vURL 					= "/api/orders/file/" + pClient.ExternalCode + "/";
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, vURL, "POST", "orders/file");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vURL, , String(pReservationNumber) + Chars.LF + String(pClient) + Chars.LF + vResponseDescription.StatusDescription);
		EndIf;		
		
		If vResponseDescription.Success Then
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			WriteClientFile(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, vJSONStructure, pCeritifcateInfo);
			// (доработка 1 - получение доп. льготы
			WriteClientFile_scanExtCategory(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, vJSONStructure);
			// )доработка 1 - получение доп. льготы
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , String(pClient) + vError);	
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// (доработка 1 - получение доп. льготы
// -----------------------------------------------------------------------------
Procedure GetClientFile_scanExtCategory(pInterectionParameters, pClient, pReservationNumber, pGuestGroup)
	
	Try
		vMessageName 	= "orders/file";
		
		If pInterectionParameters = Undefined Or Not ValueIsFilled(pClient) Or Not ValueIsFilled(pClient.ExternalCode) Then
			Return;
		EndIf;
		
		If Not ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vURL 					= "/api/orders/file/" + pClient.ExternalCode + "/";
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, vURL, "POST", "orders/file");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vURL, , String(pReservationNumber) + Chars.LF + String(pClient) + Chars.LF + vResponseDescription.StatusDescription);
		EndIf;		
		
		If vResponseDescription.Success Then
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			// (доработка 1 - получение доп. льготы
			WriteClientFile_scanExtCategory(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, vJSONStructure);
			// )доработка 1 - получение доп. льготы
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , String(pClient) + vError);	
	EndTry;
	
EndProcedure

#Region JSON_generation

// ---------------------------------------------------------------------------------
Function GetQuotaJSON(pInterectionParameters)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaList(pInterectionParameters);
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetQuotaUpdateJSON(pInterectionParameters, pExternalCodes = Undefined)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota/update";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaList(pInterectionParameters, pExternalCodes);
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetQuotaAnnulJSON(pInterectionParameters, pExternalCodes = Undefined)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota/update";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaAnnulList(pInterectionParameters, pExternalCodes);
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetSubscribeJSON(pInterectionParameters)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "subscribe";
	
	vParams 			= New Structure("url");
	vParams.url 		= pInterectionParameters.WebhookURL;
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetOrderUpdateJSON(pInterectionParameters, pReservationArray, pCustomCode = Undefined)
	
	vResult 		= New Structure("JSONString, JSONStringNoFile, ErrorDescription", "", "");
	vMessageName 	= "orders/update";
	
	vParams 				= New Structure("ordersList", New Array);
	vParamsNoFile 			= New Structure("ordersList", New Array);
	For Each vReservation In pReservationArray Do
		If TypeOf(vReservation) = Type("DocumentRef.Reservation") Then 
			GetReservationDetails(pInterectionParameters, vReservation, vParams.ordersList, vParamsNoFile.ordersList);
		Else
			GetFailedOrderDetails(pInterectionParameters, vReservation, vParams.ordersList, vParamsNoFile.ordersList, pCustomCode);
		EndIf;
	EndDo;
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 				= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParamsNoFile);
	vResult.JSONStringNoFile 	= vJSONString;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

#EndRegion 

#Region Data

// ---------------------------------------------------------------------------------
Function GetQuotaList(pInterectionParameters, pExternalCodes = Undefined, pOnlyEmpty = False)
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False);
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Reservation.ExternalCode AS GUID,
	|	Reservation.CheckInDate AS CheckInDate,
	|	Reservation.CheckOutDate AS CheckOutDate,
	|	SUM(CASE
	|			WHEN Reservation.DeletionMark
	|				THEN 0
	|			ELSE Reservation.NumberOfBeds
	|		END) AS amount,
	|	Reservation.Hotel AS Hotel,
	|	Reservation.RoomType AS RoomType
	|INTO vReservations
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus = &qReservationStatus
	|	AND Reservation.ExternalCode <> """"
	|	AND Reservation.Guest = &qEmptyGuest
	|	AND CASE
	|			WHEN &qExternalCodesFilled
	|				THEN Reservation.ExternalCode IN (&qExternalCodes)
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	Reservation.CheckInDate,
	|	Reservation.CheckOutDate,
	|	Reservation.Hotel,
	|	Reservation.RoomType,
	|	Reservation.ExternalCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
	|	ExternalSystemsObjectCodesMappings.Hotel AS Hotel
	|INTO vQuotaCodes
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""SSKQuota""
	|	AND CASE
	|			WHEN &qExternalCodesFilled
	|				THEN ExternalSystemsObjectCodesMappings.ObjectExternalCode IN (&qExternalCodes)
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(vQuotaCodes.ObjectExternalCode, vReservations.GUID) AS GUID,
	|	vReservations.CheckInDate AS CheckInDate,
	|	vReservations.CheckOutDate AS CheckOutDate,
	|	ISNULL(vReservations.amount, 0) AS amount,
	|	ISNULL(vReservations.Hotel, vQuotaCodes.Hotel) AS Hotel,
	|	vReservations.RoomType AS RoomType
	|FROM
	|	vQuotaCodes AS vQuotaCodes
	|		INNER JOIN vReservations AS vReservations
	|		ON vQuotaCodes.ObjectExternalCode = vReservations.GUID
	|WHERE
	|	CASE
	|			WHEN &qOnlyEmpty
	|				THEN ISNULL(vReservations.amount, 0) = 0
	|			ELSE TRUE
	|		END";
	
	vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qExternalSystemCode", pInterectionParameters.InteractionID);   
	vQuery.SetParameter("qExternalCodesFilled", ValueIsFilled(pExternalCodes));
	vQuery.SetParameter("qExternalCodes", pExternalCodes);
	vQuery.SetParameter("qOnlyEmpty", pOnlyEmpty);
	
	vResult = vQuery.Execute().Unload();
	vResult.Columns.Add("branchGUID");
	vResult.Columns.Add("classGUID");
	vResult.Columns.Add("dateFrom");
	vResult.Columns.Add("dateTo");
	
	For Each vRow In vResult Do
		vRow.branchGUID = cmGetObjectExternalSystemCodeByRef(vRow.Hotel, pInterectionParameters.InteractionID, "Hotels", vRow.Hotel);
		vRow.classGUID 	= cmGetObjectExternalSystemCodeByRef(vRow.Hotel, pInterectionParameters.InteractionID, "RoomTypes", vRow.RoomType);	
		
		vRow.dateFrom 	= Format(BegOfDay(vRow.CheckInDate),"DF='yyyy-MM-dd""T""HH:mm:ss'");
		vRow.dateTo 	= Format(BegOfDay(vRow.CheckOutDate),"DF='yyyy-MM-dd""T""HH:mm:ss'");
	EndDo;
	
	Return vResult;
	
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetQuotaAnnulList(pInterectionParameters, pExternalCodes = Undefined, pOnlyEmpty = False)
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False);
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode
	|INTO ExtQuotaCodes
	|FROM
	|	InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
	|WHERE
	|	ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
	|	AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""SSKQuota""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservation.ExternalCode AS ExternalCode
	|INTO Res
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus = &qReservationStatus
	|	AND Reservation.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExtQuotaCodes.ObjectExternalCode AS GUID,
	|	0 AS amount
	|FROM
	|	ExtQuotaCodes AS ExtQuotaCodes
	|		LEFT JOIN Res AS Res
	|		ON ExtQuotaCodes.ObjectExternalCode = Res.ExternalCode
	|WHERE
	|	Res.ExternalCode IS NULL";
	
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qExternalSystemCode", pInterectionParameters.InteractionID);   
	
	vResult = vQuery.Execute().Unload();

	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetQuotaReservations(pInterectionParameters, pGUID, pAccomodationTemplate = Undefined, pNumberOfBeds = Undefined)
	
	vResult = Undefined;
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False);
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Reservation.Ref AS Ref,
	|	Reservation.Number AS Number,
	|	Reservation.GuestGroup AS GuestGroup,
	|	Reservation.ExternalCode AS ExternalCode
	|INTO MainReservation
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	NOT Reservation.DeletionMark
	|	AND Reservation.ReservationStatus = &qReservationStatus
	|	AND Reservation.ExternalCode = &qGUID
	|	AND Reservation.Guest = &qEmptyGuest
	|	AND Reservation.AccommodationTemplate <> &qEmptyAccommodationTemplate
	|	AND CASE
	|			WHEN &qAccommodationTemplateFilled
	|				THEN Reservation.AccommodationTemplate = &qAccommodationTemplate
	|			ELSE TRUE
	|		END
	|	AND CASE
	|			WHEN &qNumberOfBedsFilled
	|				THEN CASE
	|						WHEN &qNumberOfBeds >= 2
	|							THEN Reservation.NumberOfBeds >= 2
	|						ELSE Reservation.NumberOfBeds >= 1
	|					END
	|			ELSE TRUE
	|		END
	|
	|ORDER BY
	|	Reservation.NumberOfBeds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.SortCode AS SortCode
	|FROM
	|	MainReservation AS MainReservation
	|		LEFT JOIN Document.Reservation AS Reservation
	|		ON MainReservation.Number = Reservation.Number
	|			AND MainReservation.GuestGroup = Reservation.GuestGroup
	|			AND MainReservation.ExternalCode = Reservation.ExternalCode
	|WHERE
	|	NOT Reservation.DeletionMark
	|
	|ORDER BY
	|	SortCode";
	
	vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qGUID", pGUID); 
	vQuery.SetParameter("qAccommodationTemplateFilled", ValueIsFilled(pAccomodationTemplate));
	vQuery.SetParameter("qAccommodationTemplate", pAccomodationTemplate);
	vQuery.SetParameter("qNumberOfBedsFilled", ValueIsFilled(pNumberOfBeds));
	vQuery.SetParameter("qNumberOfBeds", pNumberOfBeds);
	
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetClientData(pInterectionParameters, pPeoples, pBirthDatesArray, pAgesArray, pID, pHotel, pOrderDataRow, pMessageName, pCurrentDate)
	
	// (доработка 1 - получение доп. льготы
	vResult = New Structure("Client, ClientType, Customer, Email, Phone, Certificate, scanExtCategory", Undefined, Undefined, Undefined, Undefined, Undefined, Undefined);
	// )доработка 1 - получение доп. льготы
	
	vPostalAddress		= "";
	vMainAddress		= "";                                            
	vRelationshipCode 	= "";
	vRelationship 		= "";
	vCurrentClientRow = pPeoples[pID];
	If vCurrentClientRow.Property("relation") Then
		If vCurrentClientRow.relation.GUID<> Undefined Then
			vRelationshipCode 	= vCurrentClientRow.relation.GUID;
		EndIf;
		If vCurrentClientRow.relation.name<> Undefined Then
			vRelationship 		= vCurrentClientRow.relation.name;	
		EndIf;
	EndIf;      
	
	vRank = "";
	If vCurrentClientRow.Property("rank") Then
		vRank = vCurrentClientRow.rank.GUID;
	EndIf;
	
	vRankCaregory = "";
	If vCurrentClientRow.Property("rankCategory") Then
		vRankCaregory = vCurrentClientRow.rankCategory.GUID;
	EndIf;
	
	vClientType = GetClientType(pInterectionParameters, vCurrentClientRow.lgota.GUID, vRank, vRelationshipCode, pAgesArray[pID], vCurrentClientRow.applicant, vRankCaregory);
	If vClientType = Undefined Then
		vError			= "Order ID:" + pOrderDataRow.id + Chars.LF + "Failed to find client type!";
		vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
	EndIf;
	
	vClientCategoriestMapping = GetClientCatergoriesMapping();
	vClient = cmGetClientByFullnameAndBirthDate(vCurrentClientRow.lastName, vCurrentClientRow.name, vCurrentClientRow.secondName, pBirthDatesArray[pID]);
	
	If Not ValueIsFilled(vClient) Then
		vClientObj 				= Catalogs.Clients.CreateItem();
		vClientObj.Author		= SessionParameters.CurrentUser;
		vClientObj.CreateDate	= pCurrentDate;
		vClientObj.Language		= pHotel.Language;
		vClientObj.Citizenship	= pHotel.Citizenship;
		vClientObj.ExternalCode = vCurrentClientRow.id;
		vClientObj.LastName 	= vCurrentClientRow.lastName;
		vClientObj.FirstName 	= vCurrentClientRow.name;
		vClientObj.SecondName 	= vCurrentClientRow.secondName;
		vClientObj.DateOfBirth 	= pBirthDatesArray[pID];
		If vCurrentClientRow.sex = "M" Then 
			vClientObj.Sex 			= Enums.Sex.Male;
		Else
			vClientObj.Sex 			= Enums.Sex.Female;
		EndIf;
		
		vCurrentClientRow.Property("email", vClientObj.EMail);
		vCurrentClientRow.Property("phone", vClientObj.Phone);
		
		vParsedAddress 	= "";
		vAddress		= Undefined;
		If vCurrentClientRow.Property("address", vAddress) Then
			vFlat = "";
			If vAddress.Property("flat") Then 
				vFlat = vAddress.flat;
			EndIf;
			vRegion ="";
			If vAddress.Property("region") Then 
				vRegion = vAddress.region;
			EndIf;
			vCity = "";
			If vAddress.Property("city") Then 
				vCity = vAddress.city;
			EndIf;  
			vStreet = "";
			If vAddress.Property("street") Then 
				vStreet = vAddress.street;
			EndIf;
			vHous = "";
			If vAddress.Property("hous") Then 
				vHous = vAddress.hous;
			EndIf;
			
			vCountry = "";
			If vAddress.Property("country") Then 
				If vAddress.country.Property("GUID") Then 
					vCountryByCode = Catalogs.Countries.FindByCode(vAddress.country.GUID);
					If ValueIsFilled(vCountryByCode) Then
						vCountry = vCountryByCode;
					EndIf;
				EndIf;
			EndIf;
			
			vAddress.Property("raw", vPostalAddress);
			
			vParsedAddress = cmBuildAddress(vCountry, "", vRegion, "", vCity, vStreet, vHous, vFlat);	
		EndIf;
		
		If Not ValueIsFilled(vMainAddress) Then
			If ValueIsFilled(vParsedAddress) Then
				vMainAddress = vParsedAddress;
			Else			
				vMainAddress = vPostalAddress;
			EndIf;	
		EndIf;
		
		vClientObj.PostalAddress 	= vMainAddress;
		
		If vCurrentClientRow.applicant <> 1 Then
			vClientObj.Relationship = vRelationship; 
		EndIf;
		
		vCurrentClientRow.Property("snils", vClientObj.SocialSecurityNumber);
		
		If vCurrentClientRow.Property("rank") Then 
			vClientObj.MilitaryRank = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "MilitaryRanks", vCurrentClientRow.rank.GUID);
			If vCurrentClientRow.rank.active = 1 Then
				vClientObj.InReserve 	= False;
			Else
				vClientObj.InReserve 	= True;	
			EndIf;
			
			If vCurrentClientRow.rank.GUID = vClientCategoriestMapping.ПенсионерМО Then
				vClientObj.InReserve = True;	
			EndIf;
			
		EndIf;
		
		If vCurrentClientRow.Property("lgota") Then 
			vClientObj.ClientType = vClientType;												
		EndIf;
		
		// (доработка 1 - получение доп. льготы
		If vCurrentClientRow.Property("extCategory") Then
			vExtraCategory = Catalogs.ExtraCategories.FindByCode(vCurrentClientRow.extCategory.code);
			If vClientType = Undefined Then
				vError			= "extCategory: " + vCurrentClientRow.extCategory.code + Chars.LF + "Failed to find!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
			Else
				vClientObj.ExtraCategory = vExtraCategory;
			EndIf;
		EndIf;
		// )доработка 1 - получение доп. льготы
		
		vClientObj.Write();
		
		vClient = vClientObj.Ref;
	Else
		vClientObj 	= vClient.GetObject();
		
		If vCurrentClientRow.Property("rank") Then 
			vClientObj.MilitaryRank = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "MilitaryRanks", vCurrentClientRow.rank.GUID);
			If vCurrentClientRow.rank.active = 1 Then
				vClientObj.InReserve 	= False;
			Else
				vClientObj.InReserve 	= True;	
			EndIf;
			
			If vCurrentClientRow.rank.GUID = vClientCategoriestMapping.ПенсионерМО Then
				vClientObj.InReserve = True;	
			EndIf;
			
		EndIf;
		
		vClientObj.ExternalCode = vCurrentClientRow.id;
		
		If Not ValueIsFilled(vClient.ClientType) Then 											
			vClientObj.ClientType = vClientType;
		EndIf;
		
		// (доработка 1 - получение доп. льготы
		If vCurrentClientRow.Property("extCategory") Then
			vExtraCategory = Catalogs.ExtraCategories.FindByCode(vCurrentClientRow.extCategory.code);
			If vClientType = Undefined Then
				vError			= "extCategory: " + vCurrentClientRow.extCategory.code + Chars.LF + "Failed to find!";
				vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
			Else
				vClientObj.ExtraCategory = vExtraCategory;
			EndIf;
		EndIf;
		// )доработка 1 - получение доп. льготы
		
		vClientObj.Write();
	EndIf;
	
	If vCurrentClientRow.applicant = 1 Then
		vResult.Customer = CreateCustomerFromGuest(vClient);
	EndIf;
	
	vCurrentClientRow.Property("email",	vResult.Email);
	vCurrentClientRow.Property("phone", vResult.Phone);
	vCurrentClientRow.Property("certificate", vResult.Certificate);
	// (доработка 1 - получение доп. льготы
	vCurrentClientRow.Property("scanExtCategory", vResult.scanExtCategory);
	// )доработка 1 - получение доп. льготы
	
	vResult.Client 		= vClient;
	vResult.ClientType	= vClientType;
	
	Return vResult;
EndFunction

// ---------------------------------------------------------------------------------
Function GetReservationDetails(pInterectionParameters, pReservationRef, rResult = Undefined, rResultNoFile = Undefined)
	
	If rResult = Undefined Then
		rResult = New Array;
	EndIf;
	
	If rResultNoFile = Undefined Then
		rResultNoFile = New Array;
	EndIf;

	vReservationStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses", pReservationRef.ReservationStatus);
	
	vStatusStructure = New Structure;
	vStatusStructure.Insert("GUID", vReservationStatusGUID);
	
	vExternalCode 	= pReservationRef.ExternalCode;
	vIndexPos 		= StrFind(vExternalCode, "/");
	If vIndexPos > 0 Then
		vExternalCode = Left(vExternalCode, vIndexPos - 1);	
	EndIf;
	vResultStructure = New Structure;
	vResultStructure.Insert("ID", vExternalCode);
	vResultStructure.Insert("status", vStatusStructure);
	vResultStructure.Insert("number", pReservationRef.Number);
	vResultStructure.Insert("date", Format(pReservationRef.GuestGroup.CreateDate, "DF='yyyy-MM-dd""T""HH:mm:ss'"));
		
	vFile = GetOrderFile(pInterectionParameters, pReservationRef);
	vResultStructure.Insert("file", vFile.file);
	vResultStructure.Insert("fileName", vFile.fileName);
	
	vResultStructureNoFile = New Structure("ID, status, number, date, fileName");
	FillPropertyValues(vResultStructureNoFile, vResultStructure);
	
	rResultNoFile.Add(vResultStructureNoFile);
	rResult.Add(vResultStructure);
	
	Return rResult;

EndFunction

// ---------------------------------------------------------------------------------
Function GetFailedOrderDetails(pInterectionParameters, pOrderID, rResult = Undefined, rResultNoFile = Undefined, pCustomCode = Undefined)
	
	If rResult = Undefined Then
		rResult = New Array;
	EndIf;
	
	If rResultNoFile = Undefined Then
		rResultNoFile = New Array;
	EndIf;

	If pCustomCode <> Undefined Then
		vReservationStatusDeclineCode 	= pCustomCode;	
	Else
		vReservationStatusDeclineCode 	= "68f6595b-bcd3-11e8-9a45-111111111111";
	EndIf;
	
	vStatusStructure = New Structure;
	vStatusStructure.Insert("GUID", vReservationStatusDeclineCode);
	
	vResultStructure = New Structure;
	vResultStructure.Insert("ID", pOrderID);
	vResultStructure.Insert("status", vStatusStructure);
	vResultStructure.Insert("number", "");
	vResultStructure.Insert("date", "");
	
	vResultStructure.Insert("file", "");
	vResultStructure.Insert("fileName", "");	
	
	rResultNoFile.Add(vResultStructure);
	rResult.Add(vResultStructure);
	
	Return rResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetReservationsByExternalCodes(pExternalCodesArray)
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Reservation.Ref AS Ref,
	|	Reservation.ExternalCode AS ExternalCode,
	|	Reservation.SortCode AS SortCode
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ExternalCode IN(&qExternalCodes)
	|	AND NOT Reservation.DeletionMark
	|
	|ORDER BY
	|	SortCode";
	
	vQuery.SetParameter("qExternalCodes", pExternalCodesArray);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Procedure WriteClientFile(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, pJSONStructure, pCeritifcateInfo)
	
	Try
		vData = Undefined;
		If pJSONStructure <> Undefined And pJSONStructure.Property("data", vData) Then
			
			If vData <> Undefined And vData.Property("certificate") Then
				vCurrentDate				= CurrentSessionDate();
				vRegMng 					= InformationRegisters.GuestGroupAttachments.CreateRecordManager();
				vRegMng.Client 				= pClient;
				vRegMng.DocumentType		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate");
				
				vRegMng.ReservationNumber 	= pReservationNumber;
				vRegMng.GuestGroup 			= pGuestGroup;
				vRegMng.FileName			= vData.certificate.fileName;
				vRegMng.FileLoadTime		= vCurrentDate;
				vRegMng.FileLastChangeTime	= vCurrentDate;
				vRegMng.Period				= vCurrentDate;
				vRegMng.DocumentNumber		= pCeritifcateInfo.number;
				vBinaryData					= Base64Value(vData.certificate.file);
				vRegMng.ExtFile				= New ValueStorage(vBinaryData);
				vRegMng.Write(True);
			EndIf;
			
		EndIf;
	Except
		vError = ErrorDescription();
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
// (доработка 1 - получение доп. льготы
Procedure WriteClientFile_scanExtCategory(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, pJSONStructure)
	
	Try
		vData = Undefined;
		If pJSONStructure <> Undefined And pJSONStructure.Property("data", vData) Then
			
			If vData <> Undefined And vData.Property("scanExtCategory") Then
				vCurrentDate				= CurrentSessionDate()+1;
				vRegMng 					= InformationRegisters.GuestGroupAttachments.CreateRecordManager();
				vRegMng.Client 				= pClient;
				vRegMng.DocumentType		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "scanExtCategory");
				
				vRegMng.ReservationNumber 	= pReservationNumber;
				vRegMng.GuestGroup 			= pGuestGroup;
				vRegMng.FileName			= vData.scanExtCategory.fileName;
				vRegMng.FileLoadTime		= vCurrentDate;
				vRegMng.FileLastChangeTime	= vCurrentDate;
				vRegMng.Period				= vCurrentDate;
				vBinaryData					= Base64Value(vData.scanExtCategory.file);
				vRegMng.ExtFile				= New ValueStorage(vBinaryData);
				vRegMng.Write(True);
			EndIf;
				
		EndIf;
	Except
		vError = ErrorDescription();
	EndTry;
	
EndProcedure

// ---------------------------------------------------------------------------------
Function GetOrderFile(pInterectionParameters, pReservationRef)
	
	vResult = New Structure("file, fileName", "", "");
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	GuestGroupAttachments.ExtFile AS ExtFile,
	|	GuestGroupAttachments.FileName AS FileName
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|WHERE
	|	GuestGroupAttachments.GuestGroup = &qGuestGroup
	|	AND GuestGroupAttachments.ReservationNumber = &qReservationNumber
	|	AND GuestGroupAttachments.DocumentType IN(&qDocumentTypes)";
	
	vDocumentTypes 	= New Array;
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_accepted"));
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined"));
	
	vQuery.SetParameter("qDocumentTypes", 		vDocumentTypes);
	vQuery.SetParameter("qGuestGroup",	 		pReservationRef.GuestGroup);
	vQuery.SetParameter("qReservationNumber",	pReservationRef.Number);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		If vSelectionDetailRecords.ExtFile <> Undefined Then
			Try
				vResult.file 		= Base64String(vSelectionDetailRecords.ExtFile.Get());
				vResult.fileName 	= vSelectionDetailRecords.FileName;
			Except
				vError = ErrorDescription();
			EndTry;
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetExceptionalRoomRateByClientType(pClientType, pHotel, pInterectionParameters)	
	
	vResult = Undefined;
		
	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "ExceptionalRoomRates",, pHotel, pClientType);
	
	If vRoomRates.Count() > 0 Then
		vResult = vRoomRates[0].RoomRate;	
	EndIf;
	
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetClientCatergoriesMapping()
	
	vResult = New Structure;
	
	vResult.Insert("ДействующийВоеннослужащий", 						"338ecc3c-ec9d-11e3-8c21-001e671d53e4");
	vResult.Insert("ПенсионерМО", 										"c7c21f84-ec9a-11e3-8c21-001e671d53e4");
	vResult.Insert("ЧленыСемьиВоеннослужащего", 						"c57a7b14-9fc4-11e4-8208-001e671d53e4");
	vResult.Insert("ДетиИнвалидыСДетстваДействующегоВоеннослужащего", 	"a777777-3d39-11e3-b197-001e671d53e4");
	vResult.Insert("Вдовы", 											"a888888-3d39-11e3-b197-001e671d53e4");
	vResult.Insert("ЧленыСемьиПенсионераМО", 							"24eaf0a3-ea5b-11e3-8c21-001e671d53e4");
	vResult.Insert("ДетиИнвалидыСДетстваПенсионераМО", 					"a666666-3d39-11e3-b197-001e671d53e4");
	vResult.Insert("ВдовыВоеннослужащих", 								"a000000-3d39-11e3-b197-001e671d53e4");
	vResult.Insert("СторонниеЛица", 									"a8554408-3d39-11e3-b197-001e671d53e4");

	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function GetClientType(pInterectionParameters, pClientCategoryID, pMilitaryRankID, pRelationship, pAge, pApplicant, pMilitaryGroupID)
	
	vResult = Undefined;
	vCode	= "";
	
	vClientTypes 			= InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "clienttypes");
	vDefaultClientTypes 	= InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "DefaultClientType");
	
	vDefaultClientType = Undefined;
	If vDefaultClientTypes.Count() > 0 Then
		vDefaultClientType = vDefaultClientTypes[0].RefKey1;	
	EndIf;

	
	If pApplicant = 1 Then
		vApplicant = True;
	Else
		vApplicant = False;
	EndIf;
	
	vFilter = New Structure;
	vFilter.Insert("Applicant", 		vApplicant);
	vFilter.Insert("ClientTypeID", 		pClientCategoryID);
	vFilter.Insert("MilitaryRankID", 	pMilitaryRankID);
	vFilter.Insert("MilitaryGroupID", 	pMilitaryGroupID);
	vFilter.Insert("RelationID", 		pRelationship);		
	
	vFoundClientTypes = vClientTypes.FindRows(vFilter);
	
	For Each vClientTypesRow In vFoundClientTypes Do		
		If pAge >= 0 Then
			vAgeCheckFrom = False;
			If vClientTypesRow.AgeFrom >= 0 Then
				If pAge >= vClientTypesRow.AgeFrom Then
					vAgeCheckFrom = True;
				EndIf;
			Else
				vAgeCheckFrom = True;	
			EndIf;
			
			vAgeCheckTo = False;
			If vClientTypesRow.AgeTo > 0 Then
				If pAge < vClientTypesRow.AgeTo Then
					vAgeCheckTo = True;
				EndIf;
			Else
				vAgeCheckTo = True;	
			EndIf;
			
			If vAgeCheckFrom And vAgeCheckTo Then
				vResult = vClientTypesRow.RefKey1;
				Break;
			EndIf;
		Else
			vResult = vClientTypesRow.RefKey1;
			Break;
		EndIf;
	EndDo;

	
	If vResult = Undefined Then
		vResult = vDefaultClientType;	
	EndIf;
		
	Return vResult;
	
EndFunction

// ---------------------------------------------------------------------------------
Function CreateCustomerFromGuest(pGuest)
	
	vResult = Undefined;
	If ValueIsFilled(pGuest) Then
		vCreateNew = True;
		// Try to find customer with guest full name
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Customers.Ref AS Ref,
		|	Customers.LegacyName AS LegacyName,
		|	Customers.Description AS Description
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	(NOT Customers.DeletionMark)
		|	AND (NOT Customers.IsFolder)
		|	AND Customers.Description = &qDescription
		|ORDER BY
		|	Description";
		vQry.SetParameter("qDescription", Upper(TrimAll(pGuest.FullName)));
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vCreateNew = False;
			For Each vQryResRow In vQryRes Do
				vResult = vQryResRow.Ref;
				Break;
			EndDo;
		EndIf;
		If vCreateNew Then
			vCustObj = Catalogs.Customers.CreateItem();
			vIndividualsFolder = Constants.IndividualsFolder.Get();
			If Not ValueIsFilled(vIndividualsFolder) Then
				vIndividualsFolder = Catalogs.Customers.IndividualsFolder;
			EndIf;
			vCustObj.Parent = vIndividualsFolder;
			vCustObj.pmFillAttributesWithDefaultValues();
			vCustObj.Description = pGuest.FullName;
			vCustObj.LegacyName = pGuest.FullName + 
								?(ValueIsFilled(pGuest.DateOfBirth), ", " + Format(pGuest.DateOfBirth, "DF=dd.MM.yyyy"), "") + 
								?(IsBlankString(pGuest.IdentityDocumentNumber), "", ", " + TrimAll(pGuest.IdentityDocumentType) + " " + TrimAll(pGuest.IdentityDocumentSeries) + " " + TrimAll(pGuest.IdentityDocumentNumber));
			vCustObj.LegacyAddress = pGuest.Address;
			vCustObj.Phone = pGuest.Phone;
			vCustObj.Fax = pGuest.Fax;
			vCustObj.EMail = pGuest.EMail;
			vCustObj.Language = pGuest.Language;
			vCustObj.IdentityDocumentIssueDate = pGuest.IdentityDocumentIssueDate;
			vCustObj.IdentityDocumentIssuedBy = pGuest.IdentityDocumentIssuedBy;
			vCustObj.IdentityDocumentNumber = pGuest.IdentityDocumentNumber;
			vCustObj.IdentityDocumentSeries = pGuest.IdentityDocumentSeries;
			vCustObj.IdentityDocumentType = pGuest.IdentityDocumentType;
			vCustObj.IdentityDocumentValidToDate = pGuest.IdentityDocumentValidToDate;
			vCustObj.DateOfBirth = pGuest.DateOfBirth;
			vCustObj.Client = pGuest;
			vCustObj.IsIndividual = True;
			vCustObj.pmFillPlannedPaymentMethodFromChargingRules();
			vCustObj.Write();
			vCustObj.pmWriteToCustomerChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
			vResult = vCustObj.Ref;
		EndIf;
	EndIf;
	
	Return vResult;
	
EndFunction // CreateCustomerFromGuest

// ---------------------------------------------------------------------------------
Procedure WriteCertificateToCustomReservationFields(pReservation, pCertifNum, pIssueDate, pIssueWhom, pMKB10)
	
	vCodes = New Array;
	vCodes.Add("CertifNum");
	vCodes.Add("IssueDate");
	vCodes.Add("IssueWhom");
	vCodes.Add("MKB10");

	vCertifNumRef 	= Undefined;
	vIssueDateRef 	= Undefined;
	vIssueWhomRef 	= Undefined;
	vMKB10Ref 		= Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ReservationCustomAttributes.Ref AS Ref,
		|	ReservationCustomAttributes.Code AS Code
		|FROM
		|	ChartOfCharacteristicTypes.ReservationCustomAttributes AS ReservationCustomAttributes
		|WHERE
		|	ReservationCustomAttributes.Code IN(&qCodes)";
	
	vQuery.SetParameter("qCodes", vCodes);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vCode = TrimAll(vSelectionDetailRecords.Code);
		If vCode = "CertifNum" Then
			vCertifNumRef = vSelectionDetailRecords.Ref;	
		ElsIf vCode = "IssueDate" Then
			vIssueDateRef = vSelectionDetailRecords.Ref;		
		ElsIf vCode = "IssueWhom" Then
			vIssueWhomRef = vSelectionDetailRecords.Ref;		
		ElsIf vCode = "MKB10" Then 
			vMKB10Ref = vSelectionDetailRecords.Ref;	
		EndIf;
	EndDo;
	
	If ValueIsFilled(vCertifNumRef) And ValueIsFilled(pCertifNum) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vCertifNumRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pCertifNum;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vIssueDateRef) And ValueIsFilled(pIssueDate) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vIssueDateRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pIssueDate;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vIssueWhomRef) And ValueIsFilled(pIssueWhom) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vIssueWhomRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pIssueWhom;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vMKB10Ref) And ValueIsFilled(pMKB10) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vMKB10Ref;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = Catalogs.ICD10.FindByCode(TrimAll(pMKB10));
		vRecMng.Write(True);
	EndIf;
	
EndProcedure

// ---------------------------------------------------------------------------------
Function GetReservationByExternalCode(pExternalCode)
	
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	Reservation.Ref AS Ref,
		|	Reservation.ExternalCode AS ExternalCode
		|FROM
		|	Document.Reservation AS Reservation
		|WHERE
		|	Reservation.Posted
		|	AND NOT Reservation.DeletionMark
		|	AND Reservation.ExternalCode = &qExternalCode";
	
	vQuery.SetParameter("qExternalCode", pExternalCode);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
	EndDo;
	
	Return vResult;
	
EndFunction

#EndRegion

// ---------------------------------------------------------------------------------
Procedure CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes = Undefined)
	
	vQuotaList = GetQuotaList(pInterectionParameters, pExternalCodes, True);
	
	For Each vRow In vQuotaList Do
		vRecMng 					= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecMng.Hotel 				= vRow.Hotel;
		vRecMng.ExternalSystemCode 	= pInterectionParameters.InteractionID;
		vRecMng.ObjectTypeName 		= "SSKQuota";
		vRecMng.ObjectExternalCode 	= vRow.GUID;
		vRecMng.Delete();
	EndDo;
	
EndProcedure

// ---------------------------------------------------------------------------------
Procedure CheckResponseForTokenUpdate(pInterectionParameters, pJSONStructure)
	
	Try
		If pJSONStructure.Property("needUpdate") And pJSONStructure.needUpdate = 1 Then
			UpdateToken(pInterectionParameters);	
		EndIf;
	Except
	EndTry;

EndProcedure

// ---------------------------------------------------------------------------------
Function CheckResponseStatus(pResponse)
	
	vResult = New Structure("Success, StatusDescription");
	
	If pResponse.StatusCode = 0 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Неизвестный статус. Системная ошибка, сообщить в случае возникновения";
	ElsIf pResponse.StatusCode = 200 Then
		vResult.Success 			= True;
		vResult.StatusDescription 	= "	Удачное выполнение команды";
	ElsIf pResponse.StatusCode = 207 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Удачное выполнение команды, но данные обработаны частично";
	ElsIf pResponse.StatusCode = 400 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "В запросе отсутствуют необходимые для команды параметры";
	ElsIf pResponse.StatusCode = 401 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Не переданы авторизационные данные";
	ElsIf pResponse.StatusCode = 403 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Не успешная авторизация. Передан не известный или просроченный токен";
	ElsIf pResponse.StatusCode = 404 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Неизвестная команда";
	ElsIf pResponse.StatusCode = 500 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Ошибка сервера";
	Else
		vResult.Success 			= False;
		vResult.StatusDescription 	= "Неизвестный статус ответа!";
	EndIf;
	
	Return vResult;
	
EndFunction       

#EndRegion
