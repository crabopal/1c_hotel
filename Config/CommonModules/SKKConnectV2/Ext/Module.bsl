           
#Region Public

//-----------------------------------------------------------------------------
Procedure InitializeJSONSettings() Export
	
	#Region Load
	
	// Subscribe
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
	
	// Quota
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
	
	// Quota/update/
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
	
	// Orders/update/
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "orders/update", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""ordersList"":[ { ""ID"":1231241, ""status"":[{ ""GUID"":""312-123123-123123-112"" }], ""number"":""123123123"", ""date"":""2018-12-11T00:00:00"", ""files"":[ { ""name"":""filename.png"", ""body"":""iVBORw0KGgoAAAANSUhEUgAAAC"", ""description"":""filename"" } ], ""peoples"":[ { ""ID"":123422, ""state"":[{ ""GUID"":""312-123123-123123-112"" }] } ] } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_orders/update_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "orders/update", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	// Orders/addfiles/
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", "orders/addfiles", Enums.DataConvertationTypes.JSONLoad);
	
	If vRules = Undefined Then 
		vJSONString						= "{ ""ordersList"":[ { ""ID"":1231241, ""files"":[ {""name"":""filename.png"", ""body"":""iVBORw0KGgoAAAANSUhEUgAAACYAAAABAQMAAACIWk5jAAAABlBMVEUAAA"", ""description"":""filename"" } ] } ] }";
		
		vLoadRuleTree					= Catalogs.DataConvertationRules.JSONtoValueTree(vJSONString, True);
		vLoadRule 						= Catalogs.DataConvertationRules.CreateItem();
		vLoadRule.ConvertationType 		= Enums.DataConvertationTypes.JSONLoad;
		vLoadRule.LoadRuleTreeStorage 	= New ValueStorage(vLoadRuleTree);	
		vLoadRule.Description			= "SKK_orders/addfiles_Request";
		vLoadRule.Write();
		
		Catalogs.DataConvertationRules.WriteFunctionMapping("SKK", "orders/addfiles", Enums.DataConvertationTypes.JSONLoad, vLoadRule.Ref);
	EndIf;
	
	#EndRegion
	
	#Region Upload
	
	// Reset
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
	
	// Quota	
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
	
	// Quota/update/
	
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
	
	// Orders
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

// -----------------------------------------------------------------------------
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

//----------------------------------------------------------------------------- 
// Data sync
Procedure Sync(pDoUpdateQuota = True, pDoUpdateQuotaAfterChangeStatus = True, pDoGetFiles = True) Export
	
	vMessageName = "Sync"; 
	vInterectionParameters 	= GetInteractionParameters();
	vCurrentSessionDate		= CurrentSessionDate();
	If Not ValueIsFilled(vInterectionParameters) Then	
		Return;
	EndIf;
	
	GetOrders(vInterectionParameters, pDoUpdateQuota, pDoGetFiles);
	vReservations = GetReservationsToUpdateStatusChanged(vInterectionParameters.LastFullSynchronizationTime, vInterectionParameters);
	If vReservations.Count() > 0 Then	
		vUpdateResult = UpdateOrder(vInterectionParameters, vReservations);  
	EndIf;
		
	vExternalQuotaCodes = New Array;
	For each vReservationRow in vReservations Do
		vReservation = vReservationRow.Ref;
		
		If ValueIsFilled(vReservation.ParentDoc) Then
			vHashText		= String(vReservation.Hotel.UUID()) + String(vReservation.RoomType.UUID()) + String(vReservation.CheckInDate) + String(vReservation.CheckOutDate);
		
			vDataHashing = New DataHashing(HashFunction.MD5);	
			vDataHashing.Append(vHashText);
			vExternalCode	 = StrReplace(vDataHashing.HashSum, " ", "");
		
			If vExternalQuotaCodes.Find(vExternalCode) = Undefined Then
				vExternalQuotaCodes.Add(vExternalCode);
			EndIf;  
		EndIf;
		
	EndDo;
	
	vReservationsAddFiles = GetReservationsToUpdateFileChanged(vInterectionParameters.LastFullSynchronizationTime, vInterectionParameters); 

	If vReservationsAddFiles.Count() > 0 Then
		vUpdateAddFiles = AddFiles(vInterectionParameters, vReservationsAddFiles);
	EndIf;  
	
	vReservationsAddFilesMessageToSite = GetReservationsToUpdateFileChangedMessageToSite(vInterectionParameters.LastFullSynchronizationTime, vInterectionParameters);  

	If vReservationsAddFilesMessageToSite.Count() > 0 Then
		vUpdateAddFiles = AddFiles(vInterectionParameters, vReservationsAddFilesMessageToSite);
	EndIf;
	
	If pDoUpdateQuotaAfterChangeStatus Then
		If vExternalQuotaCodes.Count() > 0 Then
			UpdateQuota(vInterectionParameters, vExternalQuotaCodes);  
		EndIf; 
	Else
		If vExternalQuotaCodes.Count() > 0 Then 
			vError			= "Обновление квот после смены статуса из отеля выключено!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInterectionParameters, vMessageName, vLogEventType, , , vError);        
		EndIf;
	EndIf;
	
	vObj = vInterectionParameters.GetObject();
	vObj.LastFullSynchronizationTime = vCurrentSessionDate;
	vObj.Write();
	
EndProcedure

#Region SKK_api

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
// Api/quota/
Procedure SendQuota(pInterectionParameters, pHotel = Undefined, pExternalCodes = Undefined) Export
	
	Try
		If ValueIsFilled(pHotel) Then 
			vMessageName = "quota "+ pHotel.Description;
		Else
			vMessageName = "quota";
		EndIf;		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON = GetQuotaJSON(pInterectionParameters, pHotel, pExternalCodes);
		
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
		
		//If vResponseDescription.Success Then
		//	CleanEmptyQuotaIDs(pInterectionParameters);
		//EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
// Api/quota/update/
Procedure UpdateQuota(pInterectionParameters, pExternalCodes = Undefined) Export
	
	Try
		vMessageName 	= "quota/update";
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetQuotaUpdateJSON(pInterectionParameters, pExternalCodes);
		
		If ValueIsFilled(vJSON.ErrorDescription) Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, , vJSON.ErrorDescription);
		EndIf;
		
		If ValueIsFilled(vJSON.JSONString) Then
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
			
			//If vResponseDescription.Success Then
			//	CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes);
			//EndIf;
		EndIf;
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
// Api/quota/update/annulation
Procedure AnnulQuota(pInterectionParameters, pHotel = Undefined, pExternalCodes = Undefined) Export
	Try
		If ValueIsFilled(pHotel) Then 
			vMessageName = "quota/update "+ pHotel.Description;
		Else
			vMessageName 	= "quota/update"; 
		EndIf;
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vJSON 		= GetQuotaAnnulJSON(pInterectionParameters, pHotel, pExternalCodes);
		
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
		
		CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes);
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;	
EndProcedure

// -----------------------------------------------------------------------------
// Api/subscribe/
Procedure Subscribe(pInterectionParameters) Export
	
	Try
		vMessageName = "subscribe";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
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

// -----------------------------------------------------------------------------
// Api/subscribe/off/
Procedure Unsubscribe(pInterectionParameters) Export
	
	Try
		vMessageName = "Unsubscribe";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
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

// -----------------------------------------------------------------------------
// Api/orders/
Procedure GetOrders(pInterectionParameters, pDoUpdateQuota = True, pDoGetFiles = True) Export
	
	Try
		vMessageName 	= "orders";
		
		If pInterectionParameters = Undefined Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/orders/", "GET", "orders");
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
			ProcessOrders(pInterectionParameters, vJSONStructure, pDoUpdateQuota, pDoGetFiles);
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

// -----------------------------------------------------------------------------
// Api/orders/update/
Function UpdateOrder(pInterectionParameters, pReservations, pCustomCode = Undefined, pStatusChanged = True) Export
	
	vResult = False;
	Try
		vMessageName 	= "orders/update";
		
		If pInterectionParameters = Undefined Then
			Return vResult;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vReservations = Undefined;
		If TypeOf(pReservations) = Type("DocumentRef.Reservation") Or TypeOf(pReservations) = Type("DocumentRef.Accommodation") Then
			vReservations = New ValueTable();
			vReservations.Columns.Add("Ref");
			vReservations.Columns.Add("Number");
			vReservationsRow = vReservations.Add();
			vReservationsRow.Ref = pReservations;
			vReservationsRow.Number = pReservations.Number;
		Else
			vReservations = pReservations;
		EndIf;
		
		vJSON = GetOrderUpdateJSON(pInterectionParameters, vReservations, pCustomCode, pStatusChanged);
		
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

// -----------------------------------------------------------------------------
// Api/orders/file/{ИД_гостя}/
Procedure GetClientFile(pInterectionParameters, pReservation, pReservationNumber, pGuestGroup, pCeritifcateInfo) Export
	
	Try
		vMessageName 	= "orders/file";
		
		If pInterectionParameters = Undefined OR NOT ValueIsFilled(pReservation) OR NOT ValueIsFilled(pReservation.ExternalCode) Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		
		vExternalCode 	= pReservation.ExternalCode;
		vIndexPos 		= StrFind(vExternalCode, "/");
		If vIndexPos > 0 Then
			vExternalCode = Mid(vExternalCode, vIndexPos + 1, StrLen(vExternalCode) - vIndexPos);	
		EndIf;

		vURL 					= "/api/orders/file/" + vExternalCode + "/";    
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, vURL, "POST", "orders/file",);
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vURL, , String(pReservationNumber) + Chars.LF + String(pReservation.Guest) + Chars.LF + vResponseDescription.StatusDescription);
		EndIf;		
		
		If vResponseDescription.Success Then
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			WriteClientFile(pInterectionParameters, pReservation.Guest, pReservationNumber, pGuestGroup, vJSONStructure, pCeritifcateInfo);
			//(доработка 1 - получение доп. льготы
			WriteClientFile_scanExtCategory(pInterectionParameters, pReservation.Guest, pReservationNumber, pGuestGroup, vJSONStructure);
			//)доработка 1 - получение доп. льготы

		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , String(pReservation.Guest) + vError);	
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
// Доработка 1 - получение доп. льготы
Procedure GetClientFile_scanExtCategory(pInterectionParameters, pReservation, pReservationNumber, pGuestGroup)
	
	Try
		vMessageName 	= "orders/file";
		
		If pInterectionParameters = Undefined OR NOT ValueIsFilled(pReservation) OR NOT ValueIsFilled(pReservation.ExternalCode) Then
			Return;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vRequestHeaders = New Structure;
		vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
		vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
		
		vExternalCode 	= pReservation.ExternalCode;
		vIndexPos 		= StrFind(vExternalCode, "/");
		If vIndexPos > 0 Then
			vExternalCode = Mid(vExternalCode, vIndexPos + 1, StrLen(vExternalCode) - vIndexPos);	
		EndIf;

		vURL 					= "/api/orders/file/" + vExternalCode + "/";
		vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, vURL, "POST", "orders/file",);
		vResponseDescription 	= CheckResponseStatus(vResponse);
		
		If vResponseDescription.Success Then
			vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
		Else
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vURL, , String(pReservationNumber) + Chars.LF + String(pReservation.Guest) + Chars.LF + vResponseDescription.StatusDescription);
		EndIf;		
		
		If vResponseDescription.Success Then
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			//(доработка 1 - получение доп. льготы
			WriteClientFile_scanExtCategory(pInterectionParameters, pReservation.Guest, pReservationNumber, pGuestGroup, vJSONStructure);
			//)доработка 1 - получение доп. льготы
		EndIf;
		
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , String(pReservation.Guest) + vError);	
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
// Api/orders/addfiles/
Function AddFiles(pInterectionParameters, pReservations, pCustomCode = Undefined) Export
	
	vResult = False;
	Try
		vMessageName 	= "orders/addfiles";
		
		If pInterectionParameters = Undefined Then
			Return vResult;
		EndIf;
		
		If NOT ValueIsFilled(pInterectionParameters.SessionID) Then
			UpdateToken(pInterectionParameters);	
		EndIf;
		
		vReservations = Undefined;
		If TypeOf(pReservations) = Type("DocumentRef.Reservation") Or TypeOf(pReservations) = Type("DocumentRef.Accommodation") Then
			vReservations = New ValueTable();
			vReservations.Columns.Add("Ref");
			vReservations.Columns.Add("Number");
			vReservationsRow = vReservations.Add();
			vReservationsRow.Ref = pReservations;
			vReservationsRow.Number = pReservations.Number;
		Else
			vReservations = pReservations;
		EndIf;
		
		vJSON = GetAddFilesJSON(pInterectionParameters, vReservations, pCustomCode);
		If vJSON.JSONString <> "" Then
			vRequestHeaders = New Structure;
			vRequestHeaders.Insert("RequestCode", pInterectionParameters.SessionID);
			vRequestHeaders.Insert("RequestSign", pInterectionParameters.OAuth_AccessToken);
			
			vResponse 				= Catalogs.ExternalSystemInteractions.SendHTTPRequest(pInterectionParameters, vRequestHeaders, "/api/orders/addfiles/", "POST", "orders/addfiles", vJSON.JSONString, "JSON");
			vResponseDescription 	= CheckResponseStatus(vResponse);
			vResult					= vResponseDescription.Success;
			
			If vResponseDescription.Success Then
				vLogEventType 	= Enums.ExternalSystemEventTypes.Success;
			Else
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vJSON.JSONString, vResponse.Body, vResponseDescription.StatusDescription);
			EndIf;
			
			vJSONStructure 	= Catalogs.DataConvertationRules.JSONtoStructure(vResponse.Body);
			CheckResponseForTokenUpdate(pInterectionParameters, vJSONStructure);
		EndIf;
	Except
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, vRequestHeaders, , vError);	
	EndTry;
	
	Return vResult;
	
EndFunction

#EndRegion

// -----------------------------------------------------------------------------
Function GetReservationsToUpdateStatusChanged(pPeriodFrom, pInterectionParameters) Export
		
	vReservationStatusNoSend = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False); 
	vReservationStatusOrder = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Order", False);
	vReservationStatusFree = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Free", False);
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Reservations.Ref AS Ref,
		|	ReservationChangeHistorySliceLast.Period As Period
		|INTO ReservationsChanged
		|FROM
		|	InformationRegister.ReservationChangeHistory.SliceLast(&qPeriodFrom, ) AS ReservationChangeHistorySliceLast
		|		LEFT JOIN Document.Reservation AS Reservations
		|		ON ReservationChangeHistorySliceLast.Reservation = Reservations.Ref
		|WHERE
		|	(Reservations.ReservationStatus <> ReservationChangeHistorySliceLast.ReservationStatus Or Reservations.AnnulationReason <> ReservationChangeHistorySliceLast.AnnulationReason)
		|	AND Reservations.ExternalCode <> """"
		|	AND Reservations.ReservationStatus <> &qReservationStatusNoSend 
		|	AND Reservations.Guest <> &qEmptyGuest
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReservationsChanged.Ref AS Ref,
		|	ReservationsChanged.Ref.Number AS Number,
		|	ReservationsChanged.Period AS Period
		|FROM
		|	ReservationsChanged AS ReservationsChanged
		|GROUP BY
		|	 ReservationsChanged.Ref,
		|    ReservationsChanged.Ref.Number,
		|	 ReservationsChanged.Period 
		|ORDER BY
		|	ReservationsChanged.Ref.Number,
		|	ReservationsChanged.Ref.PointInTime";		
		
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom - 1);
	vQuery.SetParameter("qReservationStatusNoSend", vReservationStatusNoSend); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vReservationsTable = vQuery.Execute().Unload();	

	i = 0;
	While i < vReservationsTable.Count() Do
  		vRow = vReservationsTable.Get(i);
		vRowObj = vRow.Ref.GetObject();
		vLastDocState = vRowObj.pmGetPreviousObjectState(vRow.Period);
		
 		If vRow.Ref.ReservationStatus = vReservationStatusOrder And vLastDocState.ReservationStatus = vReservationStatusFree Then
   			vReservationsTable.Delete(i);
		Else
   			i = i + 1;
  		EndIf;
	EndDo;
	vReservationsTable.GroupBy("Ref, Number");	
	Return vReservationsTable;
EndFunction

// -----------------------------------------------------------------------------
Function GetReservationsToUpdateFileChanged(pPeriodFrom, pInterectionParameters) Export
	
	vDocumentTypes 	= New Array;
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_accepted"));
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined"));
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined_client"));   
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False); 
	//vReservationStatusNoSend = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", False); 
	vReservationStatusNoSend = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulationNew", False); 
	
	vQuery = New Query;
	vQuery.Text =   "SELECT
		|	Reservations.Ref AS Ref,
		|	Reservations.ReservationStatus AS ReservationStatus,
		|	Reservations.Number AS Number
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
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Reservation.Ref AS Ref,
		|	Reservation.ReservationStatus AS ReservationStatus,
		|	Reservation.Number AS Number
		|INTO ReservationsFileChanged
		|FROM
		|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
		|		LEFT JOIN Document.Reservation AS Reservation
		|		ON GuestGroupAttachments.GuestGroup = Reservation.GuestGroup
		|			AND GuestGroupAttachments.ReservationNumber = Reservation.Number
		|WHERE
		|	GuestGroupAttachments.Period > &qPeriodFrom
		|	AND Reservation.ExternalCode <> """"
		|	AND Reservation.ReservationStatus <> &qReservationStatus
		|	AND GuestGroupAttachments.DocumentType IN(&qDocumentTypes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReservationsFileChanged.Ref AS Ref,
		|	ReservationsFileChanged.Ref.Number AS Number,
		|	ReservationsFileChanged.Ref.PointInTime AS PointInTime
		|FROM
		|	ReservationsFileChanged AS ReservationsFileChanged
		|		LEFT JOIN ReservationsChanged AS ReservationsChanged
		|		ON ReservationsFileChanged.Number = ReservationsChanged.Number
		|			AND ReservationsFileChanged.ReservationStatus = ReservationsChanged.ReservationStatus
		|WHERE
		|	ReservationsChanged.Ref IS NULL
		|
		|ORDER BY
		|	Number,
		|	PointInTime";
			
	vQuery.SetParameter("qDocumentTypes", vDocumentTypes);
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom - 1);
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef());
	vReservationsTable = vQuery.Execute().Unload();	
	
	Return vReservationsTable;
EndFunction

// -----------------------------------------------------------------------------
Function GetReservationsToUpdateFileChangedMessageToSite(pPeriodFrom, pInterectionParameters) Export
	
	vDocumentTypes	= New Array;
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "messageToSite"));

	vQuery = New Query;
	vQuery.Text = "SELECT
		|			GuestGroupAttachments.ReservationNumber AS ReservationNumber,
		|			GuestGroupAttachments.GuestGroup AS GuestGroup
		|		INTO ReservationsFileChanged
		|		FROM
		|			InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
		|				
		|		WHERE
		|			GuestGroupAttachments.Period >= &qPeriodFrom
		|			AND GuestGroupAttachments.DocumentType IN(&qDocumentTypes)
		|		;
		|
		|		////////////////////////////////////////////////////////////////////////////////
		|		SELECT DISTINCT
		|			Reservation.Ref AS Ref,
		|			Reservation.Ref.Number AS Number,
		|			Reservation.Ref.PointInTime AS PointInTime
		|		FROM
		|			Document.Reservation AS Reservation
		|				INNER JOIN  ReservationsFileChanged as ReservationsFileChanged
		|				ON ReservationsFileChanged.GuestGroup = Reservation.GuestGroup
		|				AND ReservationsFileChanged.ReservationNumber = Reservation.Number
		|		WHERE
		|			Reservation.ExternalCode <> """"
		|";
	vQuery.SetParameter("qDocumentTypes", vDocumentTypes);
	vQuery.SetParameter("qPeriodFrom", pPeriodFrom);
	vReservationsTable = vQuery.Execute().Unload();	

	Return vReservationsTable;
EndFunction

// -----------------------------------------------------------------------------
Function GetGuestQuantitiesPerAgeGroupsNoQuota(pAdultsQuantity, pKidsQuantity, pKidsAgeArray, pAgeSettingsStruct = Undefined, pHotel) Export
	// Calculate number of adults, teenagers, children and infants
	If pAgeSettingsStruct = Undefined Then
		pAgeSettingsStruct = pHotel;
	EndIf;
	vAdultsQuantity = pAdultsQuantity;
	vTeenagersQuantity = 0;
	vChildrenQuantity = 0;
	vInfantsQuantity = 0;
	If pKidsAgeArray <> Undefined Then
		For Each vKidsAgeItem In pKidsAgeArray Do
			If pAgeSettingsStruct.InfantsMaxAge >= vKidsAgeItem And pAgeSettingsStruct.InfantsMaxAge <> 0 Then
				vInfantsQuantity = vInfantsQuantity + 1;
			ElsIf pAgeSettingsStruct.ChildrenMaxAge >= vKidsAgeItem And pAgeSettingsStruct.ChildrenMaxAge <> 0 Then
				vChildrenQuantity = vChildrenQuantity + 1;
			ElsIf pAgeSettingsStruct.TeenagersMaxAge >= vKidsAgeItem And pAgeSettingsStruct.TeenagersMaxAge <> 0 Then
				vTeenagersQuantity = vTeenagersQuantity + 1;
			Else
				vAdultsQuantity = vAdultsQuantity + 1;
			EndIf;
		EndDo;
		If pKidsAgeArray.Count() < pKidsQuantity Then
			vAdultsQuantity = vAdultsQuantity + pKidsQuantity - pKidsAgeArray.Count();
		EndIf;
	Else
		vChildrenQuantity = pKidsQuantity;
	EndIf;
	Return New Structure("AdultsQuantity, TeenagersQuantity, ChildrenQuantity, InfantsQuantity", vAdultsQuantity, vTeenagersQuantity, vChildrenQuantity, vInfantsQuantity); 
EndFunction // GetGuestQuantitiesPerAgeGroups

// -----------------------------------------------------------------------------
Procedure SetVirtualQuotaCode(pReservationStatus, pHotel, pRoomType, pCheckInDate, pCheckOutDate, pGuest, pInteractionID, rExternalCode) Export
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInteractionID, "ReservationStatusesDefault", pInteractionID, False);
	
	vDeleteExternalCode = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInteractionID, "DeleteExternalCode", pReservationStatus, True);
	If ValueIsFilled(vDeleteExternalCode) Then
		rExternalCode = "";	
		Return;
	EndIf;
	
	If vReservationStatus = pReservationStatus and NOT ValueIsFilled(pGuest) Then
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

// -----------------------------------------------------------------------------
Function GetHashSum(pText) Export
	
	vResult	= Undefined;
	
	vDataHashing = New DataHashing(HashFunction.MD5);	
	vDataHashing.Append(pText);
	vResult = StrReplace(vDataHashing.HashSum, " ", "");
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetAccommodationTemplateDetailsByGuestsQuantityNoQuota(pAdultsQuantity, pKidsQuantity, pKidsAgeArray, pHotel, pNoFolioSplit = True, pAgeSettingsStruct = Undefined) Export
	// Calculate number of adults, teenagers, children and infants
	vGuestsQuantityStruct = GetGuestQuantitiesPerAgeGroupsNoQuota(pAdultsQuantity, pKidsQuantity, pKidsAgeArray, pAgeSettingsStruct, pHotel);
	vAdultsQuantity = vGuestsQuantityStruct.AdultsQuantity;
	vTeenagersQuantity = vGuestsQuantityStruct.TeenagersQuantity;
	vChildrenQuantity = vGuestsQuantityStruct.ChildrenQuantity;
	vInfantsQuantity = vGuestsQuantityStruct.InfantsQuantity;
	// Get accommodation templates suitable for this number of adults and kids
	vQry = New Query;
	vQry.Text = 
	"SELECT
	|	AccommodationTemplates.Ref AS AccommodationTemplate
	|FROM
	|	Catalog.AccommodationTemplates AS AccommodationTemplates
	|WHERE
	|	(AccommodationTemplates.Hotel = &qHotel
	|			OR AccommodationTemplates.Hotel = &qEmptyHotel)
	|	AND AccommodationTemplates.DeletionMark = FALSE                      //// не было этой строки
	|	AND (NOT &qNoFolioSplit
	|			OR &qNoFolioSplit
	|				AND NOT AccommodationTemplates.IsForFolioSplit)
	|	AND (AccommodationTemplates.NumberOfAdults = &qNumberOfAdults
	|			AND AccommodationTemplates.NumberOfTeenagers = &qNumberOfTeenagers
	|			AND AccommodationTemplates.NumberOfChildren = &qNumberOfChildren
	|			AND AccommodationTemplates.NumberOfInfants = &qNumberOfInfants)
	|
	|ORDER BY
	|	AccommodationTemplates.Code";
	vQry.SetParameter("qHotel", pHotel);
	vQry.SetParameter("qNumberOfAdults", vAdultsQuantity);
	vQry.SetParameter("qNumberOfTeenagers", vTeenagersQuantity);
	vQry.SetParameter("qNumberOfChildren", vChildrenQuantity); 
	vQry.SetParameter("qNumberOfInfants", vInfantsQuantity);
	vQry.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQry.SetParameter("qNoFolioSplit", pNoFolioSplit);
	vAccTemplates = vQry.Execute().Unload();
	Return vAccTemplates;
EndFunction // cmGetAccommodationTemplateDetailsByGuestsQuantity

#EndRegion
 
#Region Private

// -----------------------------------------------------------------------------
// Creating reservations
Procedure ProcessOrders(pInterectionParameters, pJSONStructure, pDoUpdateQuota, pDoGetFiles)
	
	vOrderData 		= Undefined;
	vMessageName 	= "ProcessOrders";
	vNoHotelCode	= "68f6595b-bcd3-11e8-9a45-999999999999";

	vInterectionParameters 	= GetInteractionParameters();
	
	Try
		If pJSONStructure <> Undefined and pJSONStructure.Property("data", vOrderData) Then
			If vOrderData <> Undefined Then     
				
#Region InitialParameters				
				vReservationArrayAll = New Array;   
				vArrayForFiles = New Array;

				If vOrderData.Property("orderList") Then
					For each vOrderDataRow in vOrderData.orderList Do
						
						vReservationArray	= New Array;   
						vExternalQuotaCodes	= New Array;
						
						vQuoteStructure 	= Undefined;
						vGUID 				= Undefined;
						vReservationsList 	= Undefined;
						vExternalCode 		= Undefined;
						vAmount				= 0;
						vPeoples			= Undefined;
						vMainAddress		= "";
						vGuestGroup			= Undefined;
						vReservationCode	= Undefined;
						
						vHotel 				= Undefined;
						vDefaultRoomType 	= Undefined;
						vDefaultRoomRate 	= Undefined;
						
						vReservationStatus = Undefined; 
						
						vType = "";
						vOrderDataRow.Property("type", vType);
						vType = String(vType);  
						vMessage = "";
					    vOrderDataRow.Property("message",vMessage);
						
						vSko		= Undefined;
						vHotelCode 	= Undefined;
						vOrderDataRow.Property("sko", vSko);
						If vSko <> Undefined Then
							vSko.Property("GUID", vHotelCode);
							If vHotelCode <> Undefined Then
								vHotelCode = String(vHotelCode);  
							EndIf;
						EndIf;
													
						vErrorToRemarks = ""; 
					
						If NOT vOrderDataRow.Property("id", vExternalCode)  Then
							vError			= "Missing id parameters!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							Continue;
						EndIf; 
						If NOT vOrderDataRow.Property("amount", vAmount) Then
							vError			= "Missing amount parameters!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
						EndIf;

						If NOT vOrderDataRow.Property("peoples", vPeoples) Then
							vError			= "Missing peoples parameters!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							Continue; 
						EndIf;
						
						If vAmount =  0 Then
							vAmount = vPeoples.Count();;	
	                    EndIf;
						
						vIsError = False;   
						
						If vType = "1" Then
							If NOT vOrderDataRow.Property("quote", vQuoteStructure) Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing quote parameter!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vIsError = True;
							EndIf;
							If vQuoteStructure = Undefined OR NOT vQuoteStructure.Property("GUID", vGUID) Then
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing GUID quote parameter!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vIsError = True;
							EndIf; 
							
							vReservationsList = GetQuotaReservationsWithDeletionMark(pInterectionParameters, vGUID);
							If vReservationsList.Count() > 0 Then
								vHotel = vReservationsList.Get(0).Ref.Hotel;
								vDateFrom = vReservationsList[0].Ref.CheckInDate;  
								vDefaultRoomType =  vReservationsList[0].Ref.RoomType;
							Else
								vDateFrom = CurrentSessionDate();
								If vHotelCode <> Undefined Then
									vHotels = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "Hotels",,,,vHotelCode);
									If vHotels.Count() > 0 Then
										vHotel = vHotels[0].RefKey1;   
										vRoomType 	= cmGetObjectRefByExternalSystemCode(vHotel, pInterectionParameters.InteractionID, "DefaultRoomType", "DefaultRoomType", False);
										If ValueIsFilled(vRoomType) Then
											vDefaultRoomType = vRoomType;
										Else
											vError			= "Тип номера для свободной заявки не задан в ExternalSystemsObjectCodesMappings!";
											vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
											InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
											vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "RoomTypes",,, vHotel);  //Данные внешних систем взаимодействий
											
											If vRoomTypes.Count() > 0 Then
												vDefaultRoomType = vRoomTypes[0].RefKey1;	
											Else
												vError			= "Default room type is not filled in settings ExternalSystemIntegrationData!";
												vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
												InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
												Continue;
											EndIf;
										EndIf;

									Else
										vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find hotel in ExternalSystemIntegrationData by ID:" + vHotelCode;
										vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
										Continue;	
									EndIf;  
								Else       
									vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Для квотной заявки совсем нет квоты в программе и нет кода филиала (sko)";
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
									Continue;	
								Endif;							
							EndIf;
						Else   // vType = "0"
							If vHotelCode <> Undefined Then
								vHotels = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "Hotels",,,,vHotelCode);
								If vHotels.Count() > 0 Then
									vHotel 				= vHotels[0].RefKey1;
									vDefaultRoomRate	= vHotel.RoomRate;
								Else
									vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find hotel in ExternalSystemIntegrationData by ID:" + vHotelCode;
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
									Continue;	
								EndIf;  
							Else       
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "В свободной заявке нет кода филиала (sko)";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , vGUID, vError);
								Continue;	
							Endif;   
							
							vDateFrom = "";
							vOrderDataRow.Property("dateFrom", vDateFrom);
							If vDateFrom <> Undefined Then
								vDateFrom 	= Date(Left(StrReplace(vDateFrom, "-", ""), 8));  
							Else  
								vError			= "В свободной заявке нет даты заезда (dateFrom)!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vDateFrom = CurrentSessionDate() + 7*24*3600;								
							EndIf;   
							
							vRoomType 	= cmGetObjectRefByExternalSystemCode(vHotel, pInterectionParameters.InteractionID, "DefaultRoomType", "DefaultRoomType", False);
							If ValueIsFilled(vRoomType) Then
								vDefaultRoomType = vRoomType;
							Else
								vError			= "Тип номера для свободной заявки не задан в ExternalSystemsObjectCodesMappings!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "RoomTypes",,, vHotel);  //Данные внешних систем взаимодействий
								
								If vRoomTypes.Count() > 0 Then
									vDefaultRoomType = vRoomTypes[0].RefKey1;	
								Else
									vError			= "Default room type is not filled in settings ExternalSystemIntegrationData!";
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
									Continue;
								EndIf;
							EndIf;
						EndIf; 
						
						vExistedReservation = GetReservationByExternalCode(vExternalCode);    
						If vExistedReservation <> Undefined Then
							vError			= "Order ID:" + vExternalCode + Chars.LF + "Dublicate! Reservation:" + vExistedReservation;
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);     
							
							vUpdateResult = UpdateOrder(vInterectionParameters, vExistedReservation.Ref); 
							
							Continue; 
						EndIf;   
#EndRegion				
						
#Region SearchTemplate					
						vAgesArray 			= New Array;   
						vAgesChildArray 	= New Array;
						vBirthDatesArray 	= New Array;
						For each vGuestRow in vPeoples Do
							If vGuestRow.Property("birthday") Then
								vDateString = StrReplace(vGuestRow.birthday, "T", "");
								vDateString = StrReplace(vDateString, "-", "");
								vDateString = StrReplace(vDateString, ":", "");
								vBirthday 	= Date(vDateString);
								vBirthDatesArray.Add(vBirthday);
								vAge		= cmGetClientAge(vBirthday, vDateFrom);
								vAgesArray.Add(vAge); 
								If vAge < 18  Then
									vAgesChildArray.Add(vAge);
								EndIf;
							Else
								vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Missing birthday parameter in peoples array!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);	
							EndIf;
						EndDo;
						If vAgesArray.Count() <> vAmount Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Не у всех гостей указана дата рождения!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
						EndIf;  
						
						// Seearch template by ages
						vAccomodationTemplateList 	= cmGetAccommodationTemplateDetailsByGuestsQuantity(vAgesArray.Count() - vAgesChildArray.Count(), vAgesChildArray.Count(), vAgesChildArray, vHotel, False);
						
						// Filter Templates by roomType
						vClearArray = New Array;
						For each vTemplateRow in vAccomodationTemplateList Do
							If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType, "RoomType") = Undefined Then
								vClearArray.Add(vTemplateRow);
							EndIf;						 
						EndDo;
						For each vClearRow in vClearArray Do
							vAccomodationTemplateList.Delete(vClearRow);
						EndDo;
						
						// Search template by adults only						
						If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Не нашли шаблон размещения с учетом возрастов!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);

							
							vAccomodationTemplateList = cmGetAccommodationTemplateDetailsByGuestsQuantity(vAgesArray.Count(), 0, Undefined, vHotel, False);	
							// Filter Templates by roomType
							vClearArray = New Array;
							For each vTemplateRow in vAccomodationTemplateList Do
								If vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType, "RoomType") = Undefined Then
									If ValueIsFilled(vDefaultRoomType) And Not vDefaultRoomType.IsFolder And ValueIsFilled(vDefaultRoomType.RoomClass) And vTemplateRow.AccommodationTemplate.RoomTypes.Find(vDefaultRoomType.RoomClass, "RoomClass") <> Undefined Then
										Continue;
									Else
										vClearArray.Add(vTemplateRow);
									EndIf;
								EndIf;						 
							EndDo;
							For each vClearRow in vClearArray Do
								vAccomodationTemplateList.Delete(vClearRow);
							EndDo;
						EndIf;

						If vAccomodationTemplateList = Undefined or vAccomodationTemplateList.Count() = 0 Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Не нашли шаблон размещения без учета возрастов!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							Continue;
						Else
							// на одного если бронь, то нужно просто с раздельными счетами шаблон
							If vType = "1" AND vAmount = 1 AND vReservationsList.Count() > 0 AND vReservationsList[0].Ref.NumberOfBedsPerRoom > 1 Then
								For each vTemplateRow in vAccomodationTemplateList Do
									If vTemplateRow.AccommodationTemplate.IsForFolioSplit Then
										vAccomodationTemplate = vTemplateRow.AccommodationTemplate;
										Break;	
									EndIf;
								EndDo;
							Else
								For each vTemplateRow in vAccomodationTemplateList Do
									If NOT vTemplateRow.AccommodationTemplate.IsForFolioSplit Then
										vAccomodationTemplate = vTemplateRow.AccommodationTemplate;
										Break;	
									EndIf;
								EndDo;
							EndIf;
						EndIf;
						
						If vAccomodationTemplate = Undefined Then
							vError			= "Order ID:" + vOrderDataRow.id + Chars.LF + "Failed to find accomodation type with folio split!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							Continue;
						EndIf;
						
						If vAccomodationTemplate.AccommodationTypes.Count() = 0 Then
							vError			= "Accomodation Template:" + vAccomodationTemplate + Chars.LF + "Accomodation type is empty!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							Continue;
						EndIf;						
#EndRegion				
				
#Region CreateOrder					
				If vType = "1"  Then
						If Not vIsError Then  
							//квотная заявка пришла в норм виде 
							vErrorToFreeOrder = "";
							vIsError = CreateOrderByQuota(pInterectionParameters, vMessageName, vOrderDataRow, vAccomodationTemplate, vBirthDatesArray, vAgesArray, vGUID, vArrayForFiles, vReservationArray, vExternalQuotaCodes, vErrorToFreeOrder);
							If vIsError Then  
								// не смогли создать квотную, пробуем создать с ошибкой
								vIsErrorQuota = False;
								// статус брони Квотная заявка с ошибкой  
								vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Error", False);
								If vReservationStatus = Undefined OR NOT ValueIsFilled(vReservationStatus) Then
									vError			= "В настройках ExternalSystemsObjectCodesMappings не задан статус для Квотной заявки с ошибкой!";
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
									vIsErrorQuota = True;
								Endif; 
								vReservationsList = GetQuotaReservationsWithDeletionMark(pInterectionParameters, vGUID);  
								If vReservationsList = Undefined OR vReservationsList.Count() = 0 Then
									////// квоты нет даже помеченной на удаление

									vDateFrom = CurrentSessionDate() + 7*24*3600;
									vDefaultRoomRate = vHotel.RoomRate; 
									vRoomType 	= cmGetObjectRefByExternalSystemCode(vHotel, pInterectionParameters.InteractionID, "DefaultRoomType", "DefaultRoomType", False);
									If ValueIsFilled(vRoomType) Then
										vDefaultRoomType = vRoomType;
									Else
										vError			= "Тип номера по умолчанию не задан в ExternalSystemsObjectCodesMappings!";
										vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
										InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
										vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "RoomTypes",,, vHotel);  
										If vRoomTypes.Count() > 0 Then
											vDefaultRoomType = vRoomTypes[0].RefKey1;	
										Else
											vError			= "Тип номера по умолчанию не задан в ExternalSystemIntegrationData!";
											vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
											InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
											vIsErrorQuota = True;
										EndIf;
									EndIf;
									vErrorToRemarks = "Внимание!!! Заявка по квоте, но квоты в программе нет совсем! Дата заезда и категория номера НЕ из заявки! Ошибка: " + vErrorToFreeOrder;
									If Not vIsErrorQuota Then
										vIsError = CreateOrderFree(pInterectionParameters, vMessageName, vOrderDataRow,  vAccomodationTemplate, vBirthDatesArray, vAgesArray, vArrayForFiles, vReservationArray, vHotel, vDateFrom, vDefaultRoomRate, vDefaultRoomType, vErrorToRemarks, vReservationStatus)
									EndIf;
								Else 
                                    ////// квота есть, но не смогли создать квотную заявку
									vHotel 	= vReservationsList[0].Ref.Hotel;
									vDefaultRoomType = vReservationsList[0].Ref.RoomType; 
									vDefaultRoomRate = vHotel.RoomRate; 
									vDateFrom = vReservationsList[0].Ref.CheckInDate;  
									vErrorToRemarks = "Внимание!!! Заявка по квоте, но нет доступной квоты! Дата заезда и категория номера как в заявке! Ошибка: " + vErrorToFreeOrder;
									vIsError = CreateOrderFree(pInterectionParameters, vMessageName, vOrderDataRow,  vAccomodationTemplate, vBirthDatesArray, vAgesArray, vArrayForFiles, vReservationArray, vHotel, vDateFrom, vDefaultRoomRate, vDefaultRoomType, vErrorToRemarks, vReservationStatus)
								EndIf;	
							EndIf;
						Else  
							// в квотной заявке не указана квота, так пришло с сайт
							vIsErrorNoQuota = False;
							// статус брони Квотная заявка с ошибкой  
							vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Error", False);
							If vReservationStatus = Undefined OR NOT ValueIsFilled(vReservationStatus) Then
								vError			= "В настройках ExternalSystemsObjectCodesMappings не задан статус для Квотной заявки с ошибкой!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vIsErrorNoQuota = True;
							Endif; 
							
							vDateFrom = CurrentSessionDate() + 7*24*3600;
							vDefaultRoomRate = vHotel.RoomRate;  
							
							vRoomType 	= cmGetObjectRefByExternalSystemCode(vHotel, pInterectionParameters.InteractionID, "DefaultRoomType", "DefaultRoomType", False);
							If ValueIsFilled(vRoomType) Then
								vDefaultRoomType = vRoomType;
							Else
								vError			= "Тип номера по умолчанию не задан в ExternalSystemsObjectCodesMappings!";
								vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
								vRoomTypes = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "RoomTypes",,, vHotel);  
								If vRoomTypes.Count() > 0 Then
									vDefaultRoomType = vRoomTypes[0].RefKey1;	
								Else
									vError			= "Тип номера по умолчанию не задан в ExternalSystemIntegrationData!";
									vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
									InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
									vIsErrorNoQuota = True;
								EndIf;
							EndIf;
							
                       		If  Not vIsErrorNoQuota Then
								vErrorToRemarks = "Внимание!!! Заявка по квоте, но в заявке с сайта не указан GUID квоты! Дата заезда и категория номера НЕ из заявки!";
								vIsError = CreateOrderFree(pInterectionParameters, vMessageName, vOrderDataRow,  vAccomodationTemplate, vBirthDatesArray, vAgesArray, vArrayForFiles, vReservationArray, vHotel, vDateFrom, vDefaultRoomRate, vDefaultRoomType, vErrorToRemarks, vReservationStatus)
							EndIf;
						EndIf;
					ElsIf  vType = "0" Then  
						// параметры для свободной заполнены изначально
						vErrorToRemarks ="";
						vIsError = CreateOrderFree(pInterectionParameters, vMessageName, vOrderDataRow,  vAccomodationTemplate, vBirthDatesArray, vAgesArray, vArrayForFiles, vReservationArray, vHotel, vDateFrom, vDefaultRoomRate, vDefaultRoomType, vErrorToRemarks)
					EndIf;     
					
					If vReservationArray.Count() > 0 Then
						UpdateOrder(pInterectionParameters, vReservationArray);
					EndIf;     		
					If  pDoUpdateQuota Then
						If vExternalQuotaCodes.Count() > 0 Then
							UpdateQuota(pInterectionParameters, vExternalQuotaCodes);
						EndIf;   
					Else
						If vExternalQuotaCodes.Count() > 0 Then
							vError			= "Обновление квот после получения заявок с сайта выключено!";
							vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
							InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
						EndIf;	
					EndIf;
				EndDo; 
					
#EndRegion				

#Region	GetClientFile		

				// Получение сканов и доп льгот
				If pDoGetFiles Then
					For Each vArrayForFilesRow In vArrayForFiles Do
						If vArrayForFilesRow.vCertificate <> Undefined Then
							GetClientFile(pInterectionParameters, vArrayForFilesRow.vReservationObj.Ref,  vArrayForFilesRow.vReservationObj.Number,  vArrayForFilesRow.vReservationObj.GuestGroup, vArrayForFilesRow.vCertificate);  
						ElsIf  vArrayForFilesRow.vscanExtCategory <> Undefined Then 
 							GetClientFile_scanExtCategory(pInterectionParameters, vArrayForFilesRow.vReservationObj.Ref, vArrayForFilesRow.vReservationObj.Number, vArrayForFilesRow.vReservationObj.GuestGroup);
						EndIf; 
					EndDo;
				Else 
					If vArrayForFiles.Count() > 0 Then
						vError			= "Получение файлов с сайта выключено!";
						vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
				     EndIf;
				EndIf;
			EndIf; 
#EndRegion				
			
#Region	CancellationList		
			If vOrderData.Property("cancellationList") Then
					vExternalCodesArray = New Array;
					For each vCancellationDataRow in vOrderData.cancellationList Do
						If vCancellationDataRow.Peoples.Count() > 0 Then
							vCounter  = 0;
							vPeoples = vCancellationDataRow.Peoples;
							For Each vPeop In vPeoples Do 
								vGuestId = Format(vPeop.id, "ЧГ=");
								vExternalCodesArray.Add(vCancellationDataRow.id + "/" + vGuestId);
								vCounter = vCounter + 1;
							EndDo;
						EndIf;
					EndDo;
					
					vReservationsToAnnulate = GetReservationsByExternalCodes(vExternalCodesArray);
					vAnnulationStatus		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulationNew", False);
										
					If vAnnulationStatus <> Undefined Then
						vCounter = 0;
						vLastExternalCode = "";
						vLastGuestGroup = Undefined;
						vLastReservationRef = Undefined;
						For Each vAnnulationRow in vReservationsToAnnulate Do  //vOrderData.cancellationList	
							
							vCurrentGuestGroup = vAnnulationRow.Ref.GuestGroup;

							If vLastGuestGroup = Undefined Then 
								vLastGuestGroup = vCurrentGuestGroup;
							EndIf;
							
							vIndexPos = StrFind(vAnnulationRow.ExternalCode, "/");
							vCurExternalCode = Left(vAnnulationRow.ExternalCode, vIndexPos - 1);
							If vCurExternalCode <> vLastExternalCode Then 
								vCounter = 0;
								vLastExternalCode = vCurExternalCode;
							EndIf;
							For Each vRow In vOrderData.cancellationList Do
								If vRow.ID = vCurExternalCode Then
									vCurRow = vRow;
								EndIf;
							EndDo;
							
							vReturnReservation = Undefined;
							vAnnulationReason = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "UsualActionReasons", vCurRow.peoples[vCounter].reason.GUID);
							
							Try
								BeginTransaction(DataLockControlMode.Managed);
								
								vIsToChangeStatus = False;
								
								// Cancel reservation of the appropriate guest
								vReservationObj = vAnnulationRow.Ref.GetObject();
								vReservationObj.AnnulationReason = vAnnulationReason; 
								If vReservationObj.ReservationStatus = vAnnulationStatus Then     
									vIsToChangeStatus = True;	
								EndIf; 
								
								If  vIsToChangeStatus Then
									vUpdateResult = UpdateOrder(vInterectionParameters, vAnnulationRow.Ref); 
								EndIf;   
								
								vReservationObj.ReservationStatus = vAnnulationStatus;
								vReservationObj.Write(DocumentWriteMode.Posting);
								vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
								
								// Get array of other guests in the same room
								vOtherRoomGuests = cmGetOneRoomReservations(vReservationObj.Number, vReservationObj.GuestGroup, vReservationObj.CheckInDate, vReservationObj.CheckOutDate);
								vOtherRoomGuestsArray = vOtherRoomGuests.UnloadColumn("Ref");
								// Remove reservations that will be further cancelled too
								n = 0;
								While n < vOtherRoomGuestsArray.Count() Do
									vOtherRoomGuestsDoc = vOtherRoomGuestsArray.Get(n);
									If vReservationsToAnnulate.Find(vOtherRoomGuestsDoc, "Ref") <> Undefined Then
										vOtherRoomGuestsArray.Delete(n);
									Else
										n = n + 1;
									EndIf;
								EndDo;
										
								// Change template and accommodation types of the other guests in the room
								If vOtherRoomGuestsArray.Count() > 0 Then
									vAccTemplateNew = cmGetAccommodationTemplateByDocsArray(vOtherRoomGuestsArray, vReservationObj.RoomType, vReservationObj.Hotel, vReservationObj.IsForFolioSplit);
									If ValueIsFilled(vAccTemplateNew) And vAccTemplateNew.AccommodationTypes.Count() = vOtherRoomGuestsArray.Count() Then
										n = 0;
										For Each vOtherRoomGuestsDoc In vOtherRoomGuestsArray Do
											vOtherRoomGuestsDocObj = vOtherRoomGuestsDoc.GetObject();
											If n = 0 Then
												If vOtherRoomGuestsDocObj.AccommodationTemplate <> vAccTemplateNew Then
													vOtherRoomGuestsDocObj.AccommodationTemplate = vAccTemplateNew;
												Else
													// Docs were already processed
													Break;
												EndIf;
											Else
												vOtherRoomGuestsDocObj.AccommodationTemplate = Catalogs.AccommodationTemplates.EmptyRef();
											EndIf;
											vOtherRoomGuestsDocObj.AccommodationType = vAccTemplateNew.AccommodationTypes.Get(n).AccommodationType;
											vOtherRoomGuestsDocObj.pmCalculateResources();
											vOtherRoomGuestsDocObj.pmUpdateFirstChangeHistoryRecord();		
											vOtherRoomGuestsDocObj.Write(DocumentWriteMode.Posting);
											vOtherRoomGuestsDocObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
											
											n = n + 1;
										EndDo;
									EndIf;
								EndIf;
								
								CommitTransaction();
							Except
								vError = "Ошибка выполнения отмены брони!" + Chars.LF + cmGetRootErrorDescription(ErrorInfo());
								If TransactionActive() Then
									RollbackTransaction();
								EndIf;
								vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
								InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							EndTry;
							
							//If vCurrentGuestGroup <> vLastGuestGroup And vLastReservationRef <> Undefined Then
							//	Try
							//		vEDPRef = Catalogs.ExternalDataProcessors.FindByCode(1111);
							//		vEDPObj = cmGetExternalDataProcessorObject(vEDPRef);
							//		
							//		vSpreadSheet = New SpreadsheetDocument;
							//		vEDPObj.pmPrintAnnul(vSpreadSheet, vLastReservationRef, vLastReservationRef.Guest.Language, , );
							//		vDocTypeCodeAnnul = 11; // Ответ на отказ клиента
							//	
							//		vDocType = Catalogs.GuestGroupAttachmentDocumentTypes.FindByCode(vDocTypeCodeAnnul);
							//		If ValueIsFilled(vDocType) Then  								
							//			vReason = "";
							//			If ValueIsFilled(vLastReservationRef.AnnulationReason) Then
							//				vReason = vLastReservationRef.AnnulationReason.Description; 
							//			EndIf;  								
							//			vEDPObj.pmSavePDF(vSpreadSheet, False, False, vLastReservationRef.Number, vLastGuestGroup, CurrentSessionDate(), vDocType, ,False, vReason);
							//			
							//			vLastGuestGroup = vCurrentGuestGroup;	
							//		Else  
							//			vError			= "Тип документа 'Ответ на отказ клиента' не найден по коду - ""11""";
							//			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							//			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							//		EndIf; 
							//	Except  
							//		vError			= "Не получилось создать или сохранить ответ на отказ клиента!";
							//		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
							//		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
							//	EndTry;								
							//EndIf;
							
							vHashText		= String(vReservationObj.Hotel.UUID()) + String(vReservationObj.RoomType.UUID()) + String(vReservationObj.CheckInDate) + String(vReservationObj.CheckOutDate);
							
							vDataHashing = New DataHashing(HashFunction.MD5);	
							vDataHashing.Append(vHashText);
							vExternalCode	 = StrReplace(vDataHashing.HashSum, " ", "");

							vLastReservationRef = vAnnulationRow.Ref;

							vCounter = vCounter + 1;
						EndDo;  
						
						//If vLastReservationRef <> Undefined Then 
						//	Try	
						//		vEDPRef = Catalogs.ExternalDataProcessors.FindByCode(1111);
						//		vEDPObj = cmGetExternalDataProcessorObject(vEDPRef);
						//		
						//		vSpreadSheet = New SpreadsheetDocument;
						//		vEDPObj.pmPrintAnnul(vSpreadSheet, vLastReservationRef, vLastReservationRef.Guest.Language, , );
						//		vDocTypeCodeAnnul = 11; //Ответ на отказ клиента 
						//		
						//		vDocType = Catalogs.GuestGroupAttachmentDocumentTypes.FindByCode(vDocTypeCodeAnnul);
						//		If ValueIsFilled(vDocType) Then  								
						//			vReason = "";
						//			If ValueIsFilled(vLastReservationRef.AnnulationReason) Then
						//				vReason = vLastReservationRef.AnnulationReason.Description; 
						//			EndIf;  								
						//			vEDPObj.pmSavePDF(vSpreadSheet, False, False, vLastReservationRef.Number, vLastReservationRef.GuestGroup, CurrentSessionDate(), vDocType, ,False, vReason); 
						//		Else  
						//			vError			= "Тип документа 'Ответ на отказ клиента' не найден по коду - ""11""";
						//			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						//			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
						//		EndIf;
						//	Except
						//		vError			= "Не получилось создать или сохранить ответ на отказ клиента!";
						//		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						//		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
						//	EndTry;  
						//EndIf;
					Else
						vError			= "Failed to find annulation status by externalcode: ""GuestAnnulationNew""";
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
					EndIf; 
					
					//если гость заехал, но случайно нажал отмену путевки	
					vReservationsCheckedIn = GetAccByExternalCodes(vExternalCodesArray);
					For Each vCheckedInRow In vReservationsCheckedIn Do 	
						If vCheckedInRow.AccIsActive Then     
							vUpdateResult = UpdateOrder(vInterectionParameters, vCheckedInRow.ParentDoc); 
						EndIf;
                   	EndDo;
					
				EndIf;
#EndRegion				
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
		vError			= ErrorDescription();
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, vMessageName, vLogEventType, , , vError);
	EndTry; 
EndProcedure

#Region JSON_generation

// -----------------------------------------------------------------------------
Function GetQuotaJSON(pInterectionParameters, pHotel,  pExternalCodes = Undefined)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaList(pInterectionParameters, pHotel,  pExternalCodes, False, True);
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetQuotaUpdateJSON(pInterectionParameters, pExternalCodes = Undefined)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota/update";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaList(pInterectionParameters, Undefined, pExternalCodes, False, True);
	If vParams.quotaList.Count() = 0 Then
		Return vResult;	
	EndIf;
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetQuotaAnnulJSON(pInterectionParameters, pHotel = Undefined, pExternalCodes = Undefined)
	
	vResult 		= New Structure("JSONString, ErrorDescription", "", "");
	vMessageName 	= "quota/update";
	
	vParams 			= New Structure("quotaList", New Array);
	vParams.quotaList 	= GetQuotaAnnulList(pInterectionParameters, pHotel, pExternalCodes);
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetAddFilesJSON(pInterectionParameters, pReservations, pCustomCode = Undefined)
	
	vResult = New Structure("JSONString, ErrorDescription", "", "");
	vMessageName = "orders/addfiles";
	                            
	vParams = New Structure("ordersList", New Array);
	
	vCurNumber = "";
	vCurReservations = New Array;
	For each vReservationsRow in pReservations Do
		If vCurNumber <> vReservationsRow.Number Then
			If vCurNumber <> "" And vCurReservations.Count() > 0 Then
				If TypeOf(vReservationsRow.Ref) = Type("DocumentRef.Reservation") Then 
					GetAddFilesDetails(pInterectionParameters, vCurReservations, vParams.ordersList);
				Else
					GetFailedOrderDetails(pInterectionParameters, vReservationsRow.Ref, vParams.ordersList, , pCustomCode);
				EndIf;
				
				vCurReservations.Clear();	
			EndIf;
			
			vCurNumber = vReservationsRow.Number;       
		EndIf;
		vCurReservations.Add(vReservationsRow.Ref);
	EndDo;
	If vCurNumber <> "" And vCurReservations.Count() > 0 Then
		If TypeOf(vReservationsRow.Ref) = Type("DocumentRef.Reservation") Then 
			GetAddFilesDetails(pInterectionParameters, vCurReservations, vParams.ordersList);
		Else
			GetFailedOrderDetails(pInterectionParameters, vReservationsRow.Ref, vParams.ordersList, , pCustomCode);
		EndIf;
	EndIf;
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	If vParams.ordersList.Count() <> 0 Then	
		vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
		vResult.JSONString 	= vJSONString;
	EndIf;
	Return vResult;
	 
EndFunction

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
Function GetOrderUpdateJSON(pInterectionParameters, pReservations, pCustomCode = Undefined, pStatusChanged)	
	vResult = New Structure("JSONString, JSONStringNoFile, ErrorDescription", "", "");
	
	vMessageName = "orders/update";
	
	vParams = New Structure("ordersList", New Array);
	vParamsNoFile = New Structure("ordersList", New Array);
	vCurNumber = "";
	vCurReservations = New Array;
	For each vReservationsRow in pReservations Do
		If vCurNumber <> vReservationsRow.Number Then
			If vCurNumber <> "" And vCurReservations.Count() > 0 Then
				If TypeOf(vReservationsRow.Ref) = Type("DocumentRef.Reservation") Then 
					GetReservationDetails(pInterectionParameters, vCurReservations, vParams.ordersList, vParamsNoFile.ordersList, pStatusChanged);
				Else
					GetFailedOrderDetails(pInterectionParameters, vReservationsRow.Ref, vParams.ordersList, vParamsNoFile.ordersList, pCustomCode);
				EndIf;
				
				vCurReservations.Clear();	
			EndIf;
			
			vCurNumber = vReservationsRow.Number;       
		EndIf;
		vCurReservations.Add(vReservationsRow.Ref);
	EndDo;
	If vCurNumber <> "" And vCurReservations.Count() > 0 Then
		If TypeOf(vReservationsRow.Ref) = Type("DocumentRef.Reservation") Then 
			GetReservationDetails(pInterectionParameters, vCurReservations, vParams.ordersList, vParamsNoFile.ordersList, pStatusChanged);
		Else
			GetFailedOrderDetails(pInterectionParameters, vReservationsRow.Ref, vParams.ordersList, vParamsNoFile.ordersList, pCustomCode);
		EndIf;
	EndIf;
	
	vRules = Catalogs.DataConvertationRules.GetRules("SKK", vMessageName, Enums.DataConvertationTypes.JSONLoad);
	If vRules = Undefined Then
		vResult.ErrorDescription = "Failed to find data convertation rules for SKK - " + vMessageName;
		Return vResult;
	EndIf;
	
	vJSONString 				= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParamsNoFile);
	vResult.JSONStringNoFile  	= vJSONString;
	
	vJSONString 		= Catalogs.DataConvertationRules.ValueTreeToJSON(vRules, vParams);
	vResult.JSONString 	= vJSONString;
	
	Return vResult;
	 
EndFunction

#EndRegion

#Region CreateOrder

// -----------------------------------------------------------------------------
Function CreateOrderByQuota(pInterectionParameters, pMessageName, pOrderDataRow, pAccomodationTemplate, pBirthDatesArray, pAgesArray, pGUID, pArrayForFiles, pReservationArray, pExternalQuotaCodes, pErrorToFreeOrder)
	pIsError = False;
	
	pAmount = "";
	pPeoples ="";
	vExternalCode = "";	  
	vMessage = "";
	pOrderDataRow.Property("amount", pAmount);
	pOrderDataRow.Property("peoples", pPeoples); 
	pOrderDataRow.Property("id", vExternalCode); 
	pOrderDataRow.Property("message",vMessage);

	vGuestGroup	= Undefined;  
	vReservationCode = Undefined;  
	vFirstReservation	= True; 
	vFirstReservationRef = Undefined;

	//статус квотной заявки
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Order", False);
	If vReservationStatus = Undefined OR NOT ValueIsFilled(vReservationStatus) Then
		vError			= "Не нашли статус квотной заявки в настройках!";
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
		pIsError = True; 
		pErrorToFreeOrder = "Не нашли статус квотной заявки в настройках!"
	Endif; 
	
	vReservationsList = GetQuotaReservations(pInterectionParameters, pGUID, Undefined);
	If vReservationsList = Undefined OR vReservationsList.Count() = 0 Then
		vError			= "Заявка ID:" + pOrderDataRow.id + Chars.LF + "Не нашли свободную квоту по ID!";
		vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , pGUID, vError);
 		pIsError = True;  
		pErrorToFreeOrder = "Заявка по квоте! Не нашли свободную квоту для квотной заявки!";

		vReservationsList = GetQuotaReservationsWithDeletionMark(pInterectionParameters, pGUID, Undefined);
		If vReservationsList = Undefined OR vReservationsList.Count() = 0 Then
			vError			= "Заявка ID:" + pOrderDataRow.id + Chars.LF + "Не нашли квоту по ID!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , pGUID, vError);
			pIsError = True;  
			pErrorToFreeOrder = "Заявка по квоте! Не нашли квоту даже в настройках!";
		EndIf;
	EndIf;					

	If Not pIsError Then
		i = 0;
		vLastReservationBuffer 	= Undefined;
		vReservationObj			= Undefined;

		vCustomer 		= Undefined;
		vPostalAddress 	= "";
		BeginTransaction();
		Try
			For each vAccomodationType in pAccomodationTemplate.AccommodationTypes Do
				vReservationObj = Undefined;     
				If vAccomodationType.AccommodationType.Type <> Enums.AccomodationTypes.AdditionalBed Then
					vRes =  GetQuotaReservations(pInterectionParameters, pGUID, Undefined);
					If vRes.Count() > 0 Then
						vReservationObj			= Documents.Reservation.CreateDocument();
						vReservationObj.Hotel 	= vRes.Get(0).Ref.Hotel; 
						vReservationObj.Fill(vRes.Get(0).Ref);
						If i = 0 Then
							vReservationObj.AccommodationTemplate = pAccomodationTemplate;
							
							vGuestGroupObj = vReservationObj.GuestGroup.GetObject();
							vGuestGroupObj.CreateDate = CurrentSessionDate();
							vGuestGroupObj.Write();
						EndIf;
						
						vLastReservationBuffer = vReservationObj;
					Else
						If TransactionActive() Then
							RollbackTransaction();
						EndIf;
						
						vError			= "Не хватило квот на основные места заявки!";
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
						pIsError = True;   
						pErrorToFreeOrder = "Заявка по квоте! Не хватило квот на все основные места заявки!";
						Break;
					EndIf;
				Else  
					vReservationObj 		= vLastReservationBuffer.Copy();
					vReservationObj.Date	= vLastReservationBuffer.Date + 1;
					vReservationObj.Number 	= vLastReservationBuffer.Number;
					vReservationObj.AccommodationTemplate = Undefined;
				EndIf;
				
				If vReservationObj <> Undefined Then
					
					vClientData 	= GetClientData(pInterectionParameters, pPeoples, pBirthDatesArray, pAgesArray, i, vReservationObj.Hotel, pOrderDataRow, pMessageName);
					vClient 		= vClientData.Client;
					vClientType		= vClientData.ClientType;
					vCustomer		= vClientData.Customer;
					vCertificate	= vClientData.Certificate;
					vscanExtCategory = vClientData.scanExtCategory; 
					vEmail			= vClientData.Email;
					vPhone			= vClientData.Phone;
					
					vReservationObj.ReservationStatus 	= vReservationStatus;
					vReservationObj.AccommodationType	= vAccomodationType.AccommodationType;
					vReservationObj.ExternalCode 		= String(vExternalCode) + "/" + pPeoples[i].ID;
					
					//vRoomRate	= GetExceptionalRoomRateByClientType(vClientType, vReservationObj.Hotel, pInterectionParameters);
					//If vRoomRate <> Undefined Then
					//	vReservationObj.RoomRate = vRoomRate;
					//EndIf;
					If vClientData.RoomRate <> Undefined Then
						vReservationObj.RoomRate = vClientData.RoomRate ;
					EndIf;
					
					vReservationObj.HotelProduct = vReservationObj.RoomRate.HotelProductType;
					
					vReservationObj.Guest 				= vClient;
					vReservationObj.EMail				= vEmail;
					vReservationObj.Phone				= vPhone;
					vReservationObj.ClientType 			= vClientType;
					vReservationObj.Customer			= vCustomer;
					vReservationObj.NumberOfAdults		= pAccomodationTemplate.NumberOfAdults;
					vReservationObj.NumberOfTeenagers	= pAccomodationTemplate.NumberOfTeenagers;
					vReservationObj.NumberOfChildren	= pAccomodationTemplate.NumberOfChildren;
					vReservationObj.NumberOfInfants		= pAccomodationTemplate.NumberOfInfants;  
					If vMessage<>"" Then 
						If vReservationObj.Remarks <> "" Then
							vReservationObj.Remarks	= vReservationObj.Remarks + Chars.CR + Chars.CR + vMessage;  
						Else 
							vReservationObj.Remarks	= vMessage; 	
						Endif; 
					EndIf;
					
					If ValueIsFilled(vClient) And vClient.Age <> 0  Then 
						If vClient.Age < 18 Then
							vReservationObj.GuestAge = vClient.Age;  
						Else 
							vReservationObj.GuestAge = 0;  
						EndIf;
					Endif;     
					
					vReservationObj.SourceOfBusiness	= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "SourcesOfBusiness", "Default");
					vReservationObj.pmCalculateResources();
					vReservationObj.pmCalculateServices();
					
					If ValueIsFilled(vGuestGroup) Then
						vReservationObj.GuestGroup = vGuestGroup;
					EndIf;
					
					If ValueIsFilled(vReservationCode) Then
						vReservationObj.Number = vReservationCode;
					EndIf;
					
					vReservationObj.Write(DocumentWriteMode.Posting);
					vReservationObj.pmWriteToReservationChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);
					
					vCertificateInfo = New Structure("date, number, diagnosis, source");
					If vCertificate <> Undefined Then
						FillPropertyValues(vCertificateInfo, vCertificate);
						IF ValueIsFilled(vCertificateInfo.date) Then
							vDateString 			= StrReplace(vCertificateInfo.date, "T", "");
							vDateString 			= StrReplace(vDateString, "-", "");
							vDateString 			= StrReplace(vDateString, ":", "");
							vCertificateInfo.date 	= Date(vDateString);
						EndIf; 
						WriteCertificateToCustomReservationFields(vReservationObj.Ref, vCertificateInfo.number, vCertificateInfo.date, vCertificateInfo.source, vCertificateInfo.diagnosis);
					EndIf; 
					
					// для получения файлов
					If  vClientData.Certificate <> Undefined Or vClientData.scanExtCategory <> Undefined Then
						vStructureFiles  = New Structure("vReservationObj, vCertificate, vscanExtCategory", vReservationObj, vClientData.Certificate, vClientData.scanExtCategory); 
						pArrayForFiles.Add(vStructureFiles);  
					EndIf;
					
					If vFirstReservation Then
						vFirstReservation = False;
						vFirstReservationRef = vReservationObj.Ref ;
					EndIf;
					
					vGuestGroup			= vReservationObj.GuestGroup;
					vReservationCode 	= vReservationObj.Number;
					
					i = i + 1;
					
				Else 
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
					vErr = ErrorDescription();
					vError			= "Заявка ID: " + pOrderDataRow.id + Chars.LF +  vErr;
					vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
					pIsError = True; 
					pErrorToFreeOrder = "Заявка по квоте!" + vErr;
					Break;	
				EndIf;
			EndDo;  
			
			If Not pIsError Then
				CommitTransaction();
				pReservationArray.Add(vFirstReservationRef);
				pExternalQuotaCodes.Add(pGUID);
			Else
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;	
			EndIf;
		Except
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			vErr			= ErrorDescription(); 
			vError			= "Заявка ID: " + pOrderDataRow.id + Chars.LF +  vErr;
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
			pIsError = True;
			pErrorToFreeOrder =  "Заявка по квоте!" + vErr;
		EndTry;
	EndIf;
	Return pIsError;
EndFunction

// -----------------------------------------------------------------------------
Function CreateOrderFree(pInterectionParameters, pMessageName, pOrderDataRow,  pAccomodationTemplate, pBirthDatesArray, pAgesArray, pArrayForFiles, pReservationArray, pHotel, pDateFrom, pDefaultRoomRate, pDefaultRoomType, pErrorToRemarks, pStatus = Undefined)
	pIsError = False;  
	
	pAmount = "";
	pPeoples ="";
	pExternalCode = "";	  
	pMessage = "";
	pOrderDataRow.Property("amount", pAmount);
	pOrderDataRow.Property("peoples", pPeoples);
	If pAmount =  0 Then
		pAmount = pPeoples.Count();;	
    EndIf;
	pOrderDataRow.Property("id", pExternalCode); 
	pOrderDataRow.Property("message",pMessage);   
	
	vFirstReservation	= True;
	
	If pStatus = Undefined Then
		// статус брони Свободная  
		vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Free", False);
		If vReservationStatus = Undefined OR NOT ValueIsFilled(vReservationStatus) Then
			vError			= "В настройках не задан статус для Свободной заявки!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
			pIsError = True;
		Endif;
	Else 
		// статус брони с ошибкой
		vReservationStatus = pStatus;
	EndIf;	
	
	If Not pIsError Then 
		BeginTransaction();
		Try
			vExternalGroupReservation 	= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalGroupReservation"));
			vMainGuest 					= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
			vAccomodationTypes 			= pAccomodationTemplate.AccommodationTypes;
			vLastAccommodationType		= Undefined;
			vRoomUUID					= String(New UUID);
			vStructureFilesArray = New Array;
			For i=1 to pAmount Do
				
				vClientData = GetClientData(pInterectionParameters, pPeoples, pBirthDatesArray, pAgesArray, i - 1, pHotel, pOrderDataRow, pMessageName);
				If i = 1 Then
					vMainGuest.ClientCode 	= vClientData.Client.ExternalCode;
				EndIf;
				
				vCertificate	= vClientData.Certificate;
				//vscanExtCategory = vClientData.scanExtCategory; 

				vCertificateInfo = New Structure("date, number, diagnosis, source");
				If vCertificate <> Undefined Then
					FillPropertyValues(vCertificateInfo, vCertificate);
					IF ValueIsFilled(vCertificateInfo.date) Then
						vDateString 			= StrReplace(vCertificateInfo.date, "T", "");
						vDateString 			= StrReplace(vDateString, "-", "");
						vDateString 			= StrReplace(vDateString, ":", "");
						vCertificateInfo.date 	= Date(vDateString);
					EndIf; 
				EndIf; 
					
				// для получения файлов
				If  vClientData.Certificate <> Undefined Or vClientData.scanExtCategory <> Undefined Then
					vStructureFiles  = New Structure("vReservationObj, vCertificate, vscanExtCategory", Undefined, vCertificateInfo, vClientData.scanExtCategory); 
					vStructureFilesArray.Add(vStructureFiles);  
				Else
					vStructureFiles  = New Structure("vReservationObj, vCertificate, vscanExtCategory", Undefined, Undefined, Undefined); 
					vStructureFilesArray.Add(vStructureFiles);
				EndIf;

				vClient = XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));
				vClient.ClientCode 	= vClientData.Client.ExternalCode;
				If vAccomodationTypes.Count() < i Then
					vAccomodationType		= vLastAccommodationType;	
				Else
					vAccomodationType 		= vAccomodationTypes[i-1].AccommodationType.Code;
					vLastAccommodationType 	= vAccomodationType;
				EndIf;
				
				vExternalGroupReservationRow           			= XDTOFactory.Create(XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/","WriteExternalGroupReservationRow"));
				vExternalGroupReservationRow.ReservationCode   	= String(pExternalCode) + "/" + pPeoples[i-1].ID;	
				
				vExternalGroupReservationRow.GroupCode       	= pExternalCode;
				vExternalGroupReservationRow.GroupClient     	= ChannelManagers.CopyXDTO(vMainGuest, XDTOFactory.Type("http://www.1chotel.ru/interfaces/reservation/", "WriteExternalClient"));;
				vExternalGroupReservationRow.ReservationStatus  = vReservationStatus.Code;
				vExternalGroupReservationRow.PeriodFrom      	= pDateFrom; 
				vExternalGroupReservationRow.PeriodTo      		= EndOfDay(pDateFrom + (pDefaultRoomRate.DefaultDuration - 1) * 86400);
				vExternalGroupReservationRow.Hotel        		= pHotel.Code;
				vExternalGroupReservationRow.RoomType      		= TrimAll(pDefaultRoomType.Code);
				vExternalGroupReservationRow.AccommodationType  = TrimAll(vAccomodationType);
				vExternalGroupReservationRow.NumberOfRooms    	= 1;
				vExternalGroupReservationRow.NumberOfPersons  	= 1;
				vExternalGroupReservationRow.ExternalSystemCode = pInterectionParameters.InteractionID;
				vExternalGroupReservationRow.DoPosting      	= True;
				vExternalGroupReservationRow.Room         		= vRoomUUID;
				vExternalGroupReservationRow.ID          		= pExternalCode;
				vExternalGroupReservationRow.Client 			= vClient;   
				
				If vClientData.Customer <> Undefined Then
					vExternalGroupReservationRow.Customer		= TrimAll(vClientData.Customer.Code);
				EndIf;
				
				If vClientData.ClientType <> Undefined Then
					vExternalGroupReservationRow.ClientType		= TrimAll(vClientData.ClientType.Code);
				EndIf;

				If vClientData.RoomRate <> Undefined Then
					vExternalGroupReservationRow.RoomRate		= TrimAll(vClientData.RoomRate.Code);
				Else
					vExternalGroupReservationRow.RoomRate = TrimAll(pDefaultRoomRate.Code);
				EndIf;
				
				vExternalGroupReservation.WriteExternalGroupReservationRow.Add(vExternalGroupReservationRow);
			EndDo;
			
			vAnswerXDTO = cmWriteExternalGroupReservation(vExternalGroupReservation, , True);
			If ValueIsFilled(vAnswerXDTO.ErrorDescription) Then								
				vError			= "Failed to create reservation: " + vAnswerXDTO.ErrorDescription + "; Booking №:" + pExternalCode;
				vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
				InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);

				pIsError = True;  
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;	
			Else
				vReservationRow = vAnswerXDTO.ExternalReservationStatusRow[0];
				vReservationRef	= Documents.Reservation.GetRef(New UUID(vReservationRow.UUID));
				
				For Each vRow In vAnswerXDTO.ExternalReservationStatusRow Do
					vRef = Documents.Reservation.GetRef(New UUID(vRow.UUID));
					vReservationObj = vRef.GetObject();
					vReservationObj.EMail = vReservationObj.Customer.Email;
					
					vReservationObj.Phone = vReservationObj.Customer.Phone;
					vReservationObj.HotelProduct = vReservationObj.RoomRate.HotelProductType;
					vReservationObj.SourceOfBusiness = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "SourcesOfBusiness", "Default");
					If pMessage<>"" Then 
						If vReservationObj.Remarks <> "" Then
							vReservationObj.Remarks	= vReservationObj.Remarks + Chars.CR + Chars.CR + pMessage;  
						Else 
							vReservationObj.Remarks	= pMessage; 	
						Endif; 
					EndIf; 
					If pErrorToRemarks<>"" Then 
						If  vReservationObj.Remarks <> "" Then
							vReservationObj.Remarks = vReservationObj.Remarks + Chars.CR + Chars.CR + pErrorToRemarks; 
						Else     
							vReservationObj.Remarks = vReservationObj.Remarks+ pErrorToRemarks; 
						Endif;
					EndIf;
					vReservationObj.Write(DocumentWriteMode.Write);
				EndDo;
				
				If vReservationRef <> Undefined Then
					If vFirstReservation Then
						vFirstReservation = False;    
						pReservationArray.Add(vReservationRef.Ref);
					EndIf;
				EndIf;
				
				i = 0;
				For each vStructureFilesArrayRow in vStructureFilesArray Do
					vReservationRow = vAnswerXDTO.ExternalReservationStatusRow[i];
					vReservationRef	= Documents.Reservation.GetRef(New UUID(vReservationRow.UUID));
					
					If vReservationRef <> Undefined Then 
						vStructureFilesArrayRow.vReservationObj =  vReservationRef.Ref;  
						pArrayForFiles.Add(vStructureFilesArrayRow); 
						If vStructureFilesArrayRow.vCertificate <> Undefined Then
							WriteCertificateToCustomReservationFields(vReservationRef.Ref, vStructureFilesArrayRow.vCertificate.number, vStructureFilesArrayRow.vCertificate.date, vStructureFilesArrayRow.vCertificate.source, vStructureFilesArrayRow.vCertificate.diagnosis);
						EndIf;
					Else
						vError			= "Failed to find reservation to write file! " + vReservationRow.ReservationNumber;
						vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);	
					EndIf;
					i = i + 1;
				EndDo; 
				CommitTransaction(); 
			EndIf;  
		Except
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			vError			= ErrorDescription();
			vLogEventType 	= Enums.ExternalSystemEventTypes.Error;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);
			pIsError = True;
		EndTry;
	EndIf;
	Return  pIsError;
EndFunction

#EndRegion 

#Region Data

// -----------------------------------------------------------------------------
Function GetQuotaList(pInterectionParameters, pHotel = Undefined, pExternalCodes = Undefined, pOnlyEmpty = False, pNoEmpty = False)
	
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
	|	AND (Reservation.Hotel = &qHotel  OR &qIsHotelEmpty) 
	|	AND Reservation.ExternalCode <> """"
	|	AND Reservation.CheckInDate > &qCurrentDate
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
	|	AND (ExternalSystemsObjectCodesMappings.Hotel = &qHotel  OR &qIsHotelEmpty) 
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
	|		END
	|	   AND		CASE
	|				WHEN &qNoEmpty
	|					THEN ISNULL(vReservations.amount, 0) <> 0
	|				ELSE TRUE
	|		END";
	
	//vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qExternalSystemCode", pInterectionParameters.InteractionID);   
	vQuery.SetParameter("qExternalCodesFilled", ValueIsFilled(pExternalCodes));   // если  неопределено, то все квоты, если пусто, то без квот, если не пусто, тов множестве квот
	vQuery.SetParameter("qExternalCodes", pExternalCodes);
	vQuery.SetParameter("qOnlyEmpty", pOnlyEmpty);
	vQuery.SetParameter("qCurrentDate", EndOfDay(CurrentSessionDate()));
 	vQuery.SetParameter("qIsHotelEmpty", Not ValueIsFilled(pHotel));
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qNoEmpty", pNoEmpty);
	
	vResult = vQuery.Execute().Unload();
	vResult.Columns.Add("branchGUID");
	vResult.Columns.Add("classGUID");
	vResult.Columns.Add("dateFrom");
	vResult.Columns.Add("dateTo");
	
	For each vRow in vResult Do
		vRow.branchGUID = cmGetObjectExternalSystemCodeByRef(vRow.Hotel, pInterectionParameters.InteractionID, "Hotels", vRow.Hotel);
		vRow.classGUID 	= cmGetObjectExternalSystemCodeByRef(vRow.Hotel, pInterectionParameters.InteractionID, "RoomTypes", vRow.RoomType, True);	
		
		vRow.dateFrom 	= Format(BegOfDay(vRow.CheckInDate),"DF='yyyy-MM-dd""T""HH:mm:ss'");
		vRow.dateTo 	= Format(BegOfDay(vRow.CheckOutDate),"DF='yyyy-MM-dd""T""HH:mm:ss'");
	EndDo;
	
	i = 0;
	While i < vResult.Count() Do
  		vRow = vResult.Get(i);
 		If Not ValueIsFilled(vRow.classGUID) Then
   			vResult.Delete(i);
		Else
   			i = i + 1;
  		EndIf;
	EndDo;
	
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetQuotaAnnulList(pInterectionParameters,  pHotel = Undefined, pExternalCodes = Undefined, pOnlyEmpty = False)
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False);
	
	vQuery = New Query;
	vQuery.Text = "SELECT
|		Reservation.ExternalCode AS GUID,
|		Reservation.CheckInDate AS CheckInDate,
|		Reservation.CheckOutDate AS CheckOutDate,
|		SUM(CASE
|				WHEN Reservation.DeletionMark
|					THEN 0
|				ELSE Reservation.NumberOfBeds
|			END) AS amount,
|		Reservation.Hotel AS Hotel,
|		Reservation.RoomType AS RoomType
|	INTO vReservations
|	FROM
|		Document.Reservation AS Reservation
|	WHERE
|		Reservation.ReservationStatus = &qReservationStatus
|	   AND (Reservation.Hotel = &qHotel  OR &qIsHotelEmpty) 
|		AND Reservation.ExternalCode <> """"""""
|		AND Reservation.CheckInDate > &qCurrentDate
|		AND Reservation.Guest = &qEmptyGuest
|		AND CASE
|				WHEN &qExternalCodesFilled
|					THEN Reservation.ExternalCode IN (&qExternalCodes)
|				ELSE TRUE
|			END
|	
|	GROUP BY
|		Reservation.CheckInDate,
|		Reservation.CheckOutDate,
|		Reservation.Hotel,
|		Reservation.RoomType,
|		Reservation.ExternalCode
|	;
|	
|	////////////////////////////////////////////////////////////////////////////////
|	SELECT
|		ExternalSystemsObjectCodesMappings.ObjectExternalCode AS ObjectExternalCode,
|		ExternalSystemsObjectCodesMappings.Hotel AS Hotel
|	INTO vQuotaCodes
|	FROM
|		InformationRegister.ExternalSystemsObjectCodesMappings AS ExternalSystemsObjectCodesMappings
|	WHERE
|		ExternalSystemsObjectCodesMappings.ExternalSystemCode = &qExternalSystemCode
|		AND (ExternalSystemsObjectCodesMappings.Hotel = &qHotel  OR &qIsHotelEmpty) 
|		AND ExternalSystemsObjectCodesMappings.ObjectTypeName = ""SSKQuota""
|		AND CASE
|				WHEN &qExternalCodesFilled
|					THEN ExternalSystemsObjectCodesMappings.ObjectExternalCode IN (&qExternalCodes)
|				ELSE TRUE
|			END
|	;

|	////////////////////////////////////////////////////////////////////////////////
|	SELECT
|		ISNULL(vQuotaCodes.ObjectExternalCode, vReservations.GUID) AS GUID,
|		vReservations.CheckInDate AS CheckInDate,
|		vReservations.CheckOutDate AS CheckOutDate,
|		ISNULL(vReservations.amount, 0) AS amount,
|		ISNULL(vReservations.Hotel, vQuotaCodes.Hotel) AS Hotel,
|		vReservations.RoomType AS RoomType
|	FROM
|		vQuotaCodes AS vQuotaCodes
|			LEFT JOIN vReservations AS vReservations
|			ON vQuotaCodes.ObjectExternalCode = vReservations.GUID
|	WHERE
|		 ISNULL(vReservations.amount, 0) = 0
|";	
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qExternalSystemCode", pInterectionParameters.InteractionID);   
	vQuery.SetParameter("qExternalCodesFilled", ValueIsFilled(pExternalCodes));   // если  неопределено, то все квоты, если пусто, то без квот, если не пусто, тов множестве квот
	vQuery.SetParameter("qExternalCodes", pExternalCodes);
	vQuery.SetParameter("qOnlyEmpty", pOnlyEmpty);
	vQuery.SetParameter("qCurrentDate", EndOfDay(CurrentSessionDate()));
 	vQuery.SetParameter("qIsHotelEmpty", Not ValueIsFilled(pHotel));
	vQuery.SetParameter("qHotel", pHotel);   
	
	vResult = vQuery.Execute().Unload();  

	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
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
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	NOT Reservation.DeletionMark
	|	AND Reservation.ReservationStatus = &qReservationStatus
	|	AND Reservation.ExternalCode = &qGUID
	|	AND Reservation.Guest = &qEmptyGuest
	|ORDER BY
	|	SortCode";
	
	vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qGUID", pGUID); 
	
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetQuotaReservationsWithDeletionMark(pInterectionParameters, pGUID, pAccomodationTemplate = Undefined, pNumberOfBeds = Undefined)
	
	vResult = Undefined;
	
	vReservationStatus = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", pInterectionParameters.InteractionID, False);
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Reservation.Ref AS Ref,
	|	Reservation.Number AS Number,
	|	Reservation.GuestGroup AS GuestGroup,
	|	Reservation.ExternalCode AS ExternalCode
	|FROM
	|	Document.Reservation AS Reservation
	|WHERE
	|	Reservation.ReservationStatus = &qReservationStatus
	|	AND Reservation.ExternalCode = &qGUID
	|	AND Reservation.Guest = &qEmptyGuest
	|ORDER BY
	|	SortCode";
	
	vQuery.SetParameter("qEmptyAccommodationTemplate", Catalogs.AccommodationTemplates.EmptyRef()); 
	vQuery.SetParameter("qEmptyGuest", Catalogs.Clients.EmptyRef()); 
	vQuery.SetParameter("qReservationStatus", vReservationStatus);
	vQuery.SetParameter("qGUID", pGUID); 
	
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function GetClientData(pInterectionParameters, pPeoples, pBirthDatesArray, pAgesArray, pID, pHotel, pOrderDataRow, pMessageName)
	
	vResult = New Structure("Client, ClientType, Customer, Email, Phone, Certificate, scanExtCategory, RoomRate", Undefined, Undefined, Undefined, Undefined, Undefined, Undefined,Undefined);

	vClientType = Catalogs.ClientTypes.EmptyRef();
	vRoomRate = Catalogs.RoomRates.EmptyRef();
	vExtraCategory = Catalogs.ExtraCategories.EmptyRef();
	
	vPostalAddress		= "";
	vMainAddress		= "";                                            
	vRelationshipCode 	= "";
	vRelationship 		= "";
	vCurrentClientRow = pPeoples[pID];
	If vCurrentClientRow.Property("relation") Then
		If  vCurrentClientRow.relation.Property("GUID") And vCurrentClientRow.relation.GUID <> Undefined Then
			vRelationshipCode 	= vCurrentClientRow.relation.GUID;
		EndIf;
		If  vCurrentClientRow.relation.Property("name") And vCurrentClientRow.relation.name <> Undefined Then
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
	
	If vCurrentClientRow.Property("lgota") And vCurrentClientRow.lgota.Property("categoryCode") Then
		vClientType = Catalogs.ClientTypes.FindByCode(vCurrentClientRow.lgota.categoryCode);
		If Not ValueIsFilled(vClientType) Then
			vError			= "categoryCode: " + vCurrentClientRow.lgota.categoryCode + Chars.LF + "Failed to find!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
		EndIf;
	EndIf;
	If Not ValueIsFilled(vClientType) Then 
		vClientType = GetClientType(pInterectionParameters, vCurrentClientRow.lgota.GUID, vRank, vRelationshipCode, pAgesArray[pID], vCurrentClientRow.applicant, vRankCaregory, pHotel);
		If Not ValueIsFilled(vClientType) Then
			vError			= "Order ID:" + pOrderDataRow.id + Chars.LF + "Failed to find client type!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
		EndIf;  
	EndIf;   
	
	If Not ValueIsFilled(vRoomRate) Then 
		vRoomRate = GetRoomRate(pInterectionParameters, vCurrentClientRow.lgota.GUID, vRank, vRelationshipCode, pAgesArray[pID], vCurrentClientRow.applicant, vRankCaregory, pHotel);
		If Not ValueIsFilled(vRoomRate) Then
			vError			= "Order ID:" + pOrderDataRow.id + Chars.LF + "Failed to find room rate!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
		EndIf;  
	EndIf;   

	//(доработка 1 - получение доп. льготы
	If vCurrentClientRow.Property("extCategory") Then
		vExtraCategory = Catalogs.ExtraCategories.FindByCode(vCurrentClientRow.extCategory.code);
		If Not ValueIsFilled(vExtraCategory) Then
			vError			= "extCategory: " + vCurrentClientRow.extCategory.code + Chars.LF + "Failed to find!";
			vLogEventType 	= Enums.ExternalSystemEventTypes.Warning;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInterectionParameters, pMessageName, vLogEventType, , , vError);										
		EndIf;
	EndIf;
	//)доработка 1 - получение доп. льготы        
		
	vClientCategoriestMapping = GetClientCatergoriesMapping();
	vClient = GetClientByFullnameBirthDateAndSocialSecurityNumber(vCurrentClientRow.lastName, vCurrentClientRow.name, vCurrentClientRow.secondName, pBirthDatesArray[pID], vCurrentClientRow.snils);
	
	If Not ValueIsFilled(vClient) Then
		vClientObj 				= Catalogs.Clients.CreateItem();
		vClientObj.Author		= SessionParameters.CurrentUser;
		vClientObj.CreateDate	= CurrentSessionDate();
		vClientObj.Language		= pHotel.Language;
		vClientObj.Citizenship	= pHotel.Citizenship;
		vClientObj.ExternalCode = vCurrentClientRow.id;
		vClientObj.LastName 	= Title(vCurrentClientRow.lastName);
		vClientObj.FirstName 	= Title(vCurrentClientRow.name);
		vClientObj.SecondName 	= Title(vCurrentClientRow.secondName);
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
				If vAddress.Property("building") Then
					vHous = vHous + " к." + vAddress.building;
				EndIf;
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
			//If vAddress.Property("dadata") Then 
			//	vParsedAddress = cmBuildAddress(vAddress.dadata.country, vAddress.dadata.postal_code, vRegion, vAddress.dadata.area_with_type, vCity, vStreet, vHous, vFlat);
			//Else
			
			vParsedAddress = cmBuildAddress(vCountry, "", vRegion, "", vCity, vStreet, vHous, vFlat);	
			
			//EndIf;
		EndIf;
		
		If NOT ValueIsFilled(vMainAddress) Then
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
		If Mid(vClientObj.SocialSecurityNumber, 12, 1) = "-" Then
			vSocialSecurityNumber = Left(vClientObj.SocialSecurityNumber, 11) + " " + Mid(vClientObj.SocialSecurityNumber, 13, 2);
			vClientObj.SocialSecurityNumber =  vSocialSecurityNumber;
		EndIf;
		
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
		
		//If vCurrentClientRow.Property("lgota") Then 
		If ValueIsFilled(vClientType) Then
			vClientObj.ClientType = vClientType;												
		EndIf;
		  
		If ValueIsFilled(vExtraCategory) Then
			vClientObj.ExtraCategory = vExtraCategory;
		EndIf;
		
		vClientObj.Write();
		
		vClient = vClientObj.Ref;
	Else
		vClientObj 	= vClient.GetObject();
		
		vCurrentClientRow.Property("phone", vClientObj.Phone);
		vCurrentClientRow.Property("email", vClientObj.EMail);
		
		If vClientObj.SocialSecurityNumber = "" Then
			vCurrentClientRow.Property("snils", vClientObj.SocialSecurityNumber); 
		EndIf; 
		If Mid(vClientObj.SocialSecurityNumber, 12, 1) = "-" Then
			vSocialSecurityNumber = Left(vClientObj.SocialSecurityNumber, 11) + " " + Mid(vClientObj.SocialSecurityNumber, 13, 2);
			vClientObj.SocialSecurityNumber =  vSocialSecurityNumber;
		EndIf;
		
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
		
		//If NOT ValueIsFilled(vClient.ExternalCode) Then 											
		vClientObj.ExternalCode = vCurrentClientRow.id;
		//EndIf;
		
		//If vCurrentClientRow.Property("lgota") Then 
		If ValueIsFilled(vClientType) Then
			vClientObj.ClientType = vClientType;												
		EndIf;
		  
		If ValueIsFilled(vExtraCategory) Then
			vClientObj.ExtraCategory = vExtraCategory;
		EndIf;
		
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
				If vAddress.Property("building") Then
					vHous = vHous + " к." + vAddress.building;
				EndIf;
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
		
		If NOT ValueIsFilled(vMainAddress) Then
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

		vClientObj.Write();
	EndIf;
	
	If vCurrentClientRow.applicant = 1 Then
		vResult.Customer = CreateCustomerFromGuest(vClient, pHotel);
	EndIf;
	
	vCurrentClientRow.Property("email",	vResult.Email);
	vCurrentClientRow.Property("phone", vResult.Phone);
	vCurrentClientRow.Property("certificate", vResult.Certificate);
	//(доработка 1 - получение доп. льготы
	vCurrentClientRow.Property("scanExtCategory", vResult.scanExtCategory);
	//)доработка 1 - получение доп. льготы

	
	vResult.Client 		= vClient;
	vResult.ClientType	= vClientType;
	vResult.RoomRate	= vRoomRate;
	
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetReservationDetails(pInterectionParameters, pReservations, rResult = Undefined, rResultNoFile = Undefined, pStatusChanged = True)
	If rResult = Undefined Then
		rResult = New Array;
	EndIf;                      
	If rResultNoFile = Undefined Then
		rResultNoFile = New Array;
	EndIf;
	
	pReservationRef = pReservations.Get(0);

	vStatusAgreed = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Agreed", False);
	vStatusDenied = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Denied", False);
	vStatusAnnulation = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", False);
	vStatusAnnulationNew = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulationNew", False);
	vStatusOrder = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Order", False);
	vStatusFree = cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Free", False);
	vStatusHotelAgreed = Catalogs.ReservationStatuses.FindByCode(30); // Добавить соответствия ReservationStatusesDefault
	vStatusHotelDenied = Catalogs.ReservationStatuses.FindByCode(50);
	
	vReservationStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses", pReservationRef.ReservationStatus);	
	
	vResultStructure = New Structure;

	vExternalCode 	= pReservationRef.ExternalCode;  
	If vExternalCode = "" Then
		vExternalCode = GetExternalCodeFromAcc(pReservationRef);	
	EndIf;
	
	vIndexPos = StrFind(vExternalCode, "/");
	If vIndexPos > 0 Then
		vExternalCode = Left(vExternalCode, vIndexPos - 1);	
	EndIf;
	vResultStructure.Insert("ID", vExternalCode);
		
	
	vStatusesToSearch 	= New Array;
	vStatusesToSearch.Add(vStatusAgreed);
	vStatusesToSearch.Add(vStatusDenied);
	vStatusesToSearch.Add(vStatusAnnulation);   
	vStatusesToSearch.Add(vStatusAnnulationNew);
	vStatusesToSearch.Add(vStatusHotelAgreed);
	vStatusesToSearch.Add(vStatusHotelDenied);
	
	vPeoplesArray = New Array;
	vGuestsRef = New Array;
	If pStatusChanged = True Then
		
		If vReservationStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses",vStatusOrder) Or vReservationStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses",vStatusFree) Then
			vStatusStructure = New Structure;
			vStatusStructure.Insert("GUID", vReservationStatusGUID);
			vResultStructure.Insert("status", vStatusStructure);
			vResultStructure.Insert("number", pReservationRef.Number);
			vResultStructure.Insert("date", Format(pReservationRef.GuestGroup.CreateDate, "DF='yyyy-MM-dd""T""HH:mm:ss'"));
		EndIf;
	
		For Each vReservation In pReservations Do
			vPeoplesStructure = New Structure; 
			
			vCode = vReservation.ExternalCode; 
			If vCode = "" Then
				vCode = GetExternalCodeFromAcc(vReservation);	
			EndIf;  
			
			vGuestsRef.Add(vReservation);
			vGuestStatus = vReservation.ReservationStatus;
			If vGuestStatus= vStatusHotelAgreed Then
				vGuestStatus = vStatusAgreed;
			ElsIf vGuestStatus.IsCheckIn  Then  //если гость уже заехал, но случайно нажал отмену
				vGuestStatus = vStatusAgreed;
			Elsif vGuestStatus = vStatusHotelDenied Then
				vGuestStatus = vStatusDenied;
			EndIf;
			vGuestReason =  vReservation.AnnulationReason;
			If vGuestStatus = vStatusAgreed Or vGuestStatus = vStatusAnnulation Or vGuestStatus = vStatusDenied Or vGuestStatus = vStatusAnnulationNew Then
				vIndexPos 		= StrFind(vCode, "/");
				If vIndexPos > 0 Then 
					vPeopleCode = Mid(vCode, vIndexPos + 1, StrLen(vCode));
					If StrLen(vPeopleCode) > 2 Then 
						vPeoplesStructure.Insert("ID", vPeopleCode);
						
						vGuestStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses", vGuestStatus);
						vGuestStatusStructure = New Structure;
						vGuestStatusStructure.Insert("GUID", vGuestStatusGUID);
						vPeoplesStructure.Insert("state", vGuestStatusStructure); 
						If ValueIsFilled(vGuestReason) And vGuestStatus = vStatusDenied Then
							vGuestReasonGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "UsualActionReasons", vGuestReason);
							vGuestReasonStructure = New Structure;
							vGuestReasonStructure.Insert("GUID", vGuestReasonGUID);
							vPeoplesStructure.Insert("cancelReasonOuter", vGuestReasonStructure);
						EndIf;  						
						vPeoplesArray.Add(vPeoplesStructure);   
					Else 
						vPeopleCode = vReservation.Guest.ExternalCode;
						vPeoplesStructure.Insert("ID", vPeopleCode);
						vGuestStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses", vGuestStatus);
						
						vGuestStatusStructure = New Structure;
						vGuestStatusStructure.Insert("GUID", vGuestStatusGUID);
						vPeoplesStructure.Insert("state", vGuestStatusStructure);   
						If ValueIsFilled(vGuestReason) And vGuestStatus = vStatusDenied Then
							vGuestReasonGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "UsualActionReasons", vGuestReason);
							vGuestReasonStructure = New Structure;
							vGuestReasonStructure.Insert("GUID", vGuestReasonGUID);
							vPeoplesStructure.Insert("cancelReasonOuter", vGuestReasonStructure);
						EndIf; 
						vPeoplesArray.Add(vPeoplesStructure);
					EndIf;
				Else
					vPeopleCode = vReservation.Guest.ExternalCode;
					vPeoplesStructure.Insert("ID", vPeopleCode);
					vGuestStatusGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatuses", vGuestStatus);
					
					vGuestStatusStructure = New Structure;
					vGuestStatusStructure.Insert("GUID", vGuestStatusGUID);
					vPeoplesStructure.Insert("state", vGuestStatusStructure);   
					If ValueIsFilled(vGuestReason)And vGuestStatus = vStatusDenied Then
						vGuestReasonGUID = cmGetObjectExternalSystemCodeByRef(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "UsualActionReasons", vGuestReason);
						vGuestReasonStructure = New Structure;
						vGuestReasonStructure.Insert("GUID", vGuestReasonGUID);
						vPeoplesStructure.Insert("cancelReasonOuter", vGuestReasonStructure);
					EndIf;
					vPeoplesArray.Add(vPeoplesStructure);
				EndIf;
			EndIf;
		EndDo;
	Else 
		vGuestsRef.Add(pReservationRef);
	EndIf;
	
	vFiles = GetOrderFile(pInterectionParameters, vGuestsRef);
	vResultStructure.Insert("files", vFiles);

	If vPeoplesArray.Count() > 0 Then
		vResultStructure.Insert("peoples", vPeoplesArray);
		vResultStructureNoFile = New Structure("ID, status, number, date, peoples");
	Else
		vResultStructureNoFile = New Structure("ID, status, number, date");
	EndIf;

	FillPropertyValues(vResultStructureNoFile, vResultStructure);
	
	rResultNoFile.Add(vResultStructureNoFile);
	rResult.Add(vResultStructure);
	
	Return rResult;

EndFunction

// -----------------------------------------------------------------------------
Function GetAddFilesDetails(pInterectionParameters, pReservations, rResult = Undefined)
	If rResult = Undefined Then
		rResult = New Array;
	EndIf;                      
	vGuestsRef = New Array;
	
	For Each vRow In pReservations Do 
		vGuestsRef.Add(vRow);
	EndDo;
	pReservationRef = pReservations.Get(0);
	
	vResultStructure = New Structure;

	vExternalCode 	= pReservationRef.ExternalCode;
	vIndexPos 		= StrFind(vExternalCode, "/");
	If vIndexPos > 0 Then
		vExternalCode = Left(vExternalCode, vIndexPos - 1);	
	EndIf;
	vResultStructure.Insert("ID", vExternalCode);
			
	vFiles = GetOrderFile(pInterectionParameters, vGuestsRef);
	vResultStructure.Insert("files", vFiles);
	If vFiles.Count() <> 0 Then
		rResult.Add(vResultStructure);
	EndIf;
	
	Return rResult;

EndFunction

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
Function GetReservationsByExternalCodes(pExternalCodesArray)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Reservations.Ref AS Ref,
	|	Reservations.ExternalCode AS ExternalCode,
	|	Reservations.SortCode AS SortCode
	|FROM
	|	Document.Reservation AS Reservations
	|WHERE
	|	Reservations.ExternalCode IN(&qExternalCodes)
	|	AND Reservations.Posted
	|
	|ORDER BY
	|	SortCode";
	vQuery.SetParameter("qExternalCodes", pExternalCodesArray);
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;
EndFunction

// -----------------------------------------------------------------------------
Procedure WriteClientFile(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, pJSONStructure, pCeritifcateInfo)
	
	Try
		vData = Undefined;
		If pJSONStructure <> Undefined and pJSONStructure.Property("data", vData) Then
			
			If vData <> Undefined and vData.Property("certificate") Then
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

// -----------------------------------------------------------------------------
// Доработка 1 - получение доп. льготы
Procedure WriteClientFile_scanExtCategory(pInterectionParameters, pClient, pReservationNumber, pGuestGroup, pJSONStructure)
	
	Try
		vData = Undefined;
		If pJSONStructure <> Undefined and pJSONStructure.Property("data", vData) Then
			
			If vData <> Undefined and vData.Property("scanExtCategory") Then
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
				//vRegMng.DocumentNumber		= pCeritifcateInfo.number;
				vBinaryData					= Base64Value(vData.scanExtCategory.file);
				vRegMng.ExtFile				= New ValueStorage(vBinaryData);
				vRegMng.Write(True);
			EndIf;
				
		EndIf;
	Except
		vError = ErrorDescription();
	EndTry;
	
EndProcedure

// -----------------------------------------------------------------------------
Function GetOrderFile(pInterectionParameters, pReservationRef)
	vFiles = New Array;
	
	vReservationStatusAgreed 		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Agreed", False);
	vReservationStatusDenied 		= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "Denied", False);
	vReservationStatusAnnulation	= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulation", False);
	//vReservationStatusAnnulationNew	= cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "ReservationStatusesDefault", "GuestAnnulationNew", False);

	vStatusHotelAgreed = Catalogs.ReservationStatuses.FindByCode(30);
	vStatusHotelDenied = Catalogs.ReservationStatuses.FindByCode(50);
	vPeriodFrom = pInterectionParameters.LastFullSynchronizationTime;
	
	vDocumentTypes = New Array;
	vGuestGroups = New Array;
	vReservationNumbers = New Array;
	
	If TypeOf(pReservationRef) = Type("Array") Then
		For Each vRef In pReservationRef Do
			If vRef.ReservationStatus = vReservationStatusAgreed Or vRef.ReservationStatus = vStatusHotelAgreed Then
				vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_accepted"));
			ElsIf vRef.ReservationStatus = vReservationStatusAnnulation Then
				vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined_client"));
			ElsIf  vRef.ReservationStatus = vReservationStatusDenied Or vRef.ReservationStatus = vStatusHotelDenied Then 
				vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined"));
			EndIf;
			
			vGuestGroups.Add(vRef.GuestGroup);
			vReservationNumbers.Add(vRef.Number);
		EndDo;
		
	Else
		vRef = pReservationRef;
		If vRef.ReservationStatus = vReservationStatusAgreed Or vRef.ReservationStatus = vStatusHotelAgreed Then
			vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_accepted"));
		ElsIf vRef.ReservationStatus = vReservationStatusAnnulation Then
			vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined_client"));
		ElsIf  vRef.ReservationStatus = vReservationStatusDenied Or vRef.ReservationStatus = vStatusHotelDenied Then 
			vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "certificate_declined"));
		EndIf;
		vGuestGroups.Add(vRef.GuestGroup);
		vReservationNumbers.Add(vRef.Number);
	EndIf;  
	vDocumentTypes.Add(cmGetObjectRefByExternalSystemCode(Catalogs.Hotels.EmptyRef(), pInterectionParameters.InteractionID, "GuestGroupAttachmentDocumentTypes", "messageToSite"));
	vGuestGroups.Add(vRef.GuestGroup);
	vReservationNumbers.Add(vRef.Number);
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	GuestGroupAttachments.ExtFile AS ExtFile,
	|	GuestGroupAttachments.FileName AS FileName
	|FROM
	|	InformationRegister.GuestGroupAttachments AS GuestGroupAttachments
	|WHERE
	|	GuestGroupAttachments.GuestGroup IN (&qGuestGroup)
	|	AND GuestGroupAttachments.ReservationNumber IN (&qReservationNumber)
	|	AND GuestGroupAttachments.DocumentType IN(&qDocumentTypes)
	|	AND GuestGroupAttachments.Period >= &qPeriodFrom";
	
	vQuery.SetParameter("qDocumentTypes", 		vDocumentTypes);
	vQuery.SetParameter("qGuestGroup",	 		vRef.GuestGroup);
	vQuery.SetParameter("qReservationNumber",	vRef.Number);
	vQuery.SetParameter("qPeriodFrom",			vPeriodFrom);
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		vResult = New Structure("body, name, description", "", "", "");
		
		If vRow.ExtFile <> Undefined Then
			Try
				vResult.body = Base64String(vRow.ExtFile.Get());
				vResult.name = vRow.FileName;
			Except
				vError = ErrorDescription();
			EndTry;
		EndIf;
		
		If vFiles.Count() = 0 Then
			vFiles.Add(vResult);
		EndIf;
		
		For Each vFile In vFiles Do 
			If vFile.name <> vResult.name Then 
				vFiles.Add(vResult);
			EndIf;
		EndDo;
	EndDo;
	
	Return vFiles;
EndFunction

//// -----------------------------------------------------------------------------
//Function GetExceptionalRoomRateByClientType(pClientType, pHotel, pInterectionParameters)	
//	
//	vResult = Undefined;
//		
//	vRoomRates = InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "ExceptionalRoomRates",, pHotel, pClientType);
//	
//	If vRoomRates.Count() > 0 Then
//		vResult = vRoomRates[0].RoomRate;	
//	EndIf;
//	
//	Return vResult;
//	
//EndFunction

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
Function GetClientType(pInterectionParameters, pClientCategoryID, pMilitaryRankID, pRelationship, pAge, pApplicant, pMilitaryGroupID, pHotel)
	
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
	vFilter.Insert("RefKey2", 			pHotel);		
	
	vFoundClientTypes = vClientTypes.FindRows(vFilter);
	
	For each vClientTypesRow in vFoundClientTypes Do		
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
			
			If vAgeCheckFrom AND vAgeCheckTo Then
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

// -----------------------------------------------------------------------------
Function GetRoomRate(pInterectionParameters, pClientCategoryID, pMilitaryRankID, pRelationship, pAge, pApplicant, pMilitaryGroupID, pHotel)
	
	vResult = Undefined;
	vCode	= "";
	
	vClientTypes 			= InformationRegisters.ExternalSystemIntegrationData.GetData(pInterectionParameters, "clienttypes");
	
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
	vFilter.Insert("RefKey2", 			pHotel);
	
	
	vFoundClientTypes = vClientTypes.FindRows(vFilter);
	
	For each vClientTypesRow in vFoundClientTypes Do		
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
			
			If vAgeCheckFrom AND vAgeCheckTo Then
				vResult = vClientTypesRow.RoomRate;  
				Break;
			EndIf;
		Else
			vResult = vClientTypesRow.RoomRate;  
			Break;
		EndIf;
	EndDo;
	
	Return vResult;
	
EndFunction

// -----------------------------------------------------------------------------
Function CreateCustomerFromGuest(pGuest, pHotel)
	
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
		|	NOT Customers.DeletionMark
		|	AND NOT Customers.IsFolder
		|	AND Customers.Description = &qDescription
		|	AND Customers.DateOfBirth = &qDateOfBirth
		|
		|ORDER BY
		|	Description";
		vQry.SetParameter("qDescription", Upper(TrimAll(pGuest.FullName)));
		vQry.SetParameter("qDateOfBirth", pGuest.DateOfBirth);
		vQryRes = vQry.Execute().Unload();
		If vQryRes.Count() > 0 Then
			vCreateNew = False;
			vCustList = New ValueList();
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
			vCustObj.AccountingCurrency = pHotel.BaseCurrency;
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

// -----------------------------------------------------------------------------
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
	
	If ValueIsFilled(vCertifNumRef) AND ValueIsFilled(pCertifNum) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vCertifNumRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pCertifNum;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vIssueDateRef) AND ValueIsFilled(pIssueDate) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vIssueDateRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pIssueDate;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vIssueWhomRef) AND ValueIsFilled(pIssueWhom) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vIssueWhomRef;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = pIssueWhom;
		vRecMng.Write(True);
	EndIf;
	
	If ValueIsFilled(vMKB10Ref) AND ValueIsFilled(pMKB10) Then
		vRecMng 					= InformationRegisters.ReservationCustomAttributeValues.CreateRecordManager();
		vRecMng.Characteristic 		= vMKB10Ref;
		vRecMng.Owner				= pReservation;
		vRecMng.CharacteristicValue = Catalogs.ICD10.FindByCode(TrimAll(pMKB10));
		vRecMng.Write(True);
	EndIf;
	
EndProcedure

// -----------------------------------------------------------------------------
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
		|	AND Reservation.ExternalCode LIKE &qExternalCode";
	
	vQuery.SetParameter("qExternalCode", String(pExternalCode)+"/%");
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
	EndDo;
	Return vResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetAccByExternalCodes(pExternalCodesArray)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Accommodations.Ref AS Ref,
	|	Accommodations.ParentDoc.Ref AS ParentDoc,
	|	Accommodations.ExternalCode AS ExternalCode,
	|	Accommodations.SortCode AS SortCode,
	|	Accommodations.AccommodationStatus.IsActive As AccIsActive
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.ExternalCode IN(&qExternalCodes)
	|	AND Accommodations.Posted
	|
	|ORDER BY
	|	SortCode";
	vQuery.SetParameter("qExternalCodes", pExternalCodesArray);
	vQueryResult = vQuery.Execute().Unload();
	Return vQueryResult;
EndFunction

// -----------------------------------------------------------------------------
Function GetExternalCodeFromAcc(pRes)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT TOP 1
	|	Accommodations.ExternalCode AS ExternalCode
	|FROM
	|	Document.Accommodation AS Accommodations
	|WHERE
	|	Accommodations.ParentDoc = &qResRef
	|	AND Accommodations.Posted  
	|	AND Accommodations.AccommodationStatus.IsActive 
	|
	|ORDER BY
	|	SortCode";
	vQuery.SetParameter("qResRef", pRes);
	vQueryResult = vQuery.Execute().Unload();
	If vQueryResult.Count() > 0 Then
		Return vQueryResult.Get(0).ExternalCode;
	Else
		Return "";
	EndIf;
EndFunction

#EndRegion
 
// -----------------------------------------------------------------------------
Procedure CleanEmptyQuotaIDs(pInterectionParameters, pExternalCodes = Undefined)
	
	vQuotaList = GetQuotaAnnulList(pInterectionParameters, Undefined, pExternalCodes, True);
	
	For each vRow in vQuotaList Do
		vRecMng 					= InformationRegisters.ExternalSystemsObjectCodesMappings.CreateRecordManager();
		vRecMng.ExternalSystemCode 	= pInterectionParameters.InteractionID;
		vRecMng.ObjectTypeName 		= "SSKQuota";
		vRecMng.ObjectExternalCode 	= vRow.GUID;   
		vRecMng.Hotel = vRow.Hotel;
		vRecMng.Read();
		If vRecMng.Selected() Then
			vRecMng.Delete();
		EndIf;
	EndDo;
EndProcedure

// -----------------------------------------------------------------------------
Procedure CheckResponseForTokenUpdate(pInterectionParameters, pJSONStructure)
	
	Try
		If pJSONStructure.Property("needUpdate") And pJSONStructure.needUpdate = 1 Then
			UpdateToken(pInterectionParameters);	
		EndIf;
	Except
	EndTry;

EndProcedure

// -----------------------------------------------------------------------------
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
		vResult.StatusDescription 	= "Удачное выполнение команды, но данные обработанны частично";
	ElsIf pResponse.StatusCode = 400 Then
		vResult.Success 			= False;
		vResult.StatusDescription 	= "В запросе отсутсвуют необходимые для команды параметры";
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

// -----------------------------------------------------------------------------
Function GetClientByFullnameBirthDateAndSocialSecurityNumber(pClientLastName, pClientFirstName, pClientSecondName, pClientBirthDate, pSocialSecurityNumber)
	vClient = Catalogs.Clients.EmptyRef(); 
	vSocialSecurityNumber1 = pSocialSecurityNumber; 
	If Mid(pSocialSecurityNumber, 12, 1) = "-" Then
		vSocialSecurityNumber2 = Left(pSocialSecurityNumber, 11) + " " + Mid(pSocialSecurityNumber, 13, 2);
	EndIf;

	// Try to find client by names and birth date and snils
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Clients.Ref AS Ref
	|FROM
	|	Catalog.Clients AS Clients
	|WHERE
	|	Clients.LastName = &qClientLastName
	|	AND Clients.FirstName = &qClientFirstName
	|	AND Clients.SecondName = &qClientSecondName
	|	AND Clients.DateOfBirth = &qClientBirthDate
	|	AND NOT Clients.DeletionMark
	|	AND NOT Clients.IsFolder
	|	AND (Clients.SocialSecurityNumber = &qSocialSecurityNumber1 OR Clients.SocialSecurityNumber = &qSocialSecurityNumber2)
	|
	|ORDER BY
	|	Clients.FullName DESC,
	|	Clients.DateOfBirth DESC,
	|	Clients.IdentityDocumentNumber DESC,
	|	Clients.CreateDate";
	vQry.SetParameter("qClientLastName", Title(TrimAll(pClientLastName)));
	vQry.SetParameter("qClientFirstName", Title(TrimAll(pClientFirstName)));
	vQry.SetParameter("qClientSecondName", Title(TrimAll(pClientSecondName)));
	vQry.SetParameter("qSocialSecurityNumber1", vSocialSecurityNumber1);  
	vQry.SetParameter("qSocialSecurityNumber2", vSocialSecurityNumber2);
	vQry.SetParameter("qClientBirthDate", pClientBirthDate);
	vClients = vQry.Execute().Unload();
	If vClients.Count() > 0 Then
		vClient = vClients.Get(0).Ref;  
	Else
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	Clients.Ref AS Ref
		|FROM
		|	Catalog.Clients AS Clients
		|WHERE
		|	Clients.LastName = &qClientLastName
		|	AND Clients.FirstName = &qClientFirstName
		|	AND Clients.SecondName = &qClientSecondName
		|	AND Clients.DateOfBirth = &qClientBirthDate
		|	AND NOT Clients.DeletionMark
		|	AND NOT Clients.IsFolder
		|	AND Clients.SocialSecurityNumber = """"
		|
		|ORDER BY
		|	Clients.FullName DESC,
		|	Clients.DateOfBirth DESC,
		|	Clients.IdentityDocumentNumber DESC,
		|	Clients.CreateDate";
		vQry.SetParameter("qClientLastName", Title(TrimAll(pClientLastName)));
		vQry.SetParameter("qClientFirstName", Title(TrimAll(pClientFirstName)));
		vQry.SetParameter("qClientSecondName", Title(TrimAll(pClientSecondName)));
		vQry.SetParameter("qClientBirthDate", pClientBirthDate);
		vClients = vQry.Execute().Unload();
		If vClients.Count() > 0 Then
			vClient = vClients.Get(0).Ref;  
		EndIf;
	EndIf;
	Return vClient;
EndFunction // GetClientByFullnameBirthDateAndSocialSecurityNumber

#EndRegion 
