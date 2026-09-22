
#Region EventHandlers

// --------------------------------------------------------------------------------
//  Function - clientGET
//  JSON or QueryOptions
//  Mandatory:
//  - token - Catalogs.InteractionsParameters.Code
//  
//  Non-mandatory:
//  - card
//  - folioNumber
//  - room
//  - phone
//
// Parameters:
//  pRequest - HttpQuery - Input params
// 
// Returns:
//  HTTPServiceResponse - Result
//
Function clientGET(pRequest)
	WriteLogEvent("HTTP_api_ClientGET", EventLogLevel.Information, , , "Request recieved");
	vSuccess				= True;
	vErrorDescription		= "";
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("token");
	
	// Initialize non mandatory params
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("card");
	vNonMandatoryParamsArray.Add("phone");
	vNonMandatoryParamsArray.Add("folioNumber");
	vNonMandatoryParamsArray.Add("room");
	vNonMandatoryParamsArray.Add("hotel");
	vNonMandatoryParamsArray.Add("share");
	vNonMandatoryParamsArray.Add("cardtype");

	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
	
	// If failed try to read request query options
	If ValueIsFilled(vRequestParams.Error) Then
		vRequestParams 	= cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);
	EndIf;
	
	If Not (ValueIsFilled(vRequestParams.card) Or ValueIsFilled(vRequestParams.folioNumber) Or ValueIsFilled(vRequestParams.room) Or ValueIsFilled(vRequestParams.phone)) Then
		vRequestParams.Error = vRequestParams.Error + "Missing <card>, <folioNumber>, <room> parameters! At least one of them must be filled."	
	EndIf;
	
	If ValueIsFilled(vRequestParams.Error) Then
		vSuccess 			= False;
		vErrorDescription 	= vRequestParams.Error; 
	EndIf;
	
	If vSuccess And ValueIsFilled(vRequestParams.token) Then
		WriteLogEvent("HTTP_api_ClientGET", EventLogLevel.Information, , , "Token:" + vRequestParams.token + Chars.LF + "Card:" + vRequestParams.card);
		vInteractionParameters = GetInteractionParameters(vRequestParams.token);
		If ValueIsFilled(vInteractionParameters) Then
			vHotelCode = "";
			If ValueIsFilled(vRequestParams.hotel) Then
				vHotelCode = Trimall(vRequestParams.hotel);
			ElsIf ValueIsFilled(vInteractionParameters.Hotel) Then
				vHotelCode = TrimAll(vInteractionParameters.Hotel.Code);
			EndIf;	

			vClientsArray 	= New Array;
			If ValueIsFilled(vRequestParams.card) Then
				If vRequestParams.Property("share") And ((TypeOf(vRequestParams.share) = Type("Boolean") And vRequestParams.share) Or (TypeOf(vRequestParams.share) = Type("String") And Lower(vRequestParams.share) = "true")) Then
					vRoom = GetRoomByCard(vInteractionParameters, vRequestParams.card);  
					If ValueIsFilled(vRoom) Then
						vClientsArray = GetHotelGuestsList(, TrimAll(vRoom), TrimAll(vRoom.Owner.Code), vInteractionParameters, vRequestParams);
					Else
						vSuccess = False;
						vErrorDescription = vErrorDescription + NStr("en='Unknown card!';ru='Неизвестная карта!';de='Unbekannte Karte!'");
					EndIf;
				Else
					vClientData = GetClientData(vInteractionParameters, vRequestParams.card);
					vClientsArray.Add(vClientData);
				EndIf;
			ElsIf ValueIsFilled(vRequestParams.folioNumber) Then
				vClientData = GetFolioDescription(vRequestParams.folioNumber, vHotelCode,vInteractionParameters, vRequestParams);
				vClientsArray.Add(vClientData);
			ElsIf ValueIsFilled(vRequestParams.room) Then
				vClientsArray = GetHotelGuestsList(, vRequestParams.room, vHotelCode, vInteractionParameters, vRequestParams); 
			ElsIf ValueIsFilled(vRequestParams.phone) Then
				vClientsArray = GetClientInfoByPhone(vRequestParams.phone, vHotelCode, vInteractionParameters);
			Else
				vSuccess = False;
				vRequestParams.Error = vRequestParams.Error + "Missing <card>, <folioNumber>, <room> parameters! At least one of them must be maintain and filled."	
			EndIf;
		Else
			vSuccess = False;
			vErrorDescription = vErrorDescription + "Not authorized" + Chars.LF;
		EndIf;
	Else
		vSuccess = False;
		vErrorDescription = vErrorDescription + "Token parameter is empty!" + Chars.LF;	
	EndIf;
	
	If vSuccess Then
		
		vResult = Catalogs.DataConvertationRules.MapToJSON(vClientsArray);

		vResponse = New HTTPServiceResponse(200);
		vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
		vResponse.SetBodyFromString(vResult);		
	Else
		WriteLogEvent("HTTP_api_ClientGET", EventLogLevel.Error, , , vErrorDescription);
		vJSONResponse 	= New JSONWriter;
		vJSONResponse.ValidateStructure = False;
		vJSONResponse.SetString();
		vJSONResponse.WriteStartObject();			
		vJSONResponse.WritePropertyName("ErrorDescription");
		vJSONResponse.WriteValue(vErrorDescription);
		vJSONResponse.WriteEndObject();	
		vResult = vJSONResponse.Close();
		
		vResponse = New HTTPServiceResponse(400);
		vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
		vResponse.SetBodyFromString(vResult);
	EndIf;
	
	Return vResponse;
EndFunction // ClientGET

// --------------------------------------------------------------------------------
Function chargePOST(pRequest)
	WriteLogEvent("HTTP_api_chargePOST", EventLogLevel.Information,,,"Request recieved");
	vSuccess				= True;
	vErrorDescription		= "";
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("token");
	vParamsArray.Add("card");
	vParamsArray.Add("sum");
	vParamsArray.Add("id");

	// Initialize non mandatory params
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("POS");
	vNonMandatoryParamsArray.Add("Remarks");
	vNonMandatoryParamsArray.Add("Details");
	vNonMandatoryParamsArray.Add("Currency");
	vNonMandatoryParamsArray.Add("ServiceTypes");
	
	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		
	If ValueIsFilled(vRequestParams.Error) Then
		vSuccess 			= False;
		vErrorDescription 	= vRequestParams.Error; 
	EndIf;

	If vSuccess Then
		Try
			vInteractionParameters = GetInteractionParameters(vRequestParams.token);
			If ValueIsFilled(vInteractionParameters) Then
				vRemarks = "id =" + String(vRequestParams.id) + "; " +String(vRequestParams.Remarks);
				BeginTransaction();
				If ValueIsFilled(vRequestParams.ServiceTypes) Then
					For Each vRow In vRequestParams.ServiceTypes Do
						vServiceCode = "";
						If ValueIsFilled(vRequestParams.POS) and ValueIsFilled(vRow.ServiceType) Then
							vServiceCode = String(vRequestParams.POS) + "/" + String(vRow.ServiceType); 
						ElsIf ValueIsFilled(vRow.ServiceType) Then 
							vServiceCode = String(vRow.ServiceType);
						ElsIf ValueIsFilled(vRequestParams.POS) Then
							vServiceCode = String(vRequestParams.POS);	
						EndIf;
						vChargeResult 	= cmChargeExternalService(vRequestParams.card, vServiceCode, vRow.sum, 1, vRemarks, String(vRequestParams.Details), String(vRequestParams.Currency), vInteractionParameters.InteractionID);
						If ValueIsFilled(vChargeResult) Then
							vSuccess = False;
							vErrorDescription = vErrorDescription + vChargeResult + Chars.LF;
							Break;
						EndIf;
					EndDo;
				Else
					vChargeResult 	= cmChargeExternalService(vRequestParams.card, String(vRequestParams.POS), vRequestParams.sum, 1, vRemarks, String(vRequestParams.Details), String(vRequestParams.Currency), vInteractionParameters.InteractionID);	
					If ValueIsFilled(vChargeResult) Then
						vSuccess = False;
						vErrorDescription = vErrorDescription + vChargeResult + Chars.LF;
					EndIf;
				EndIf;		
			Else
				vSuccess 			= False;
				vErrorDescription 	= vErrorDescription + "Not authorized" + Chars.LF;
			EndIf;
		Except
			vSuccess 			= False;
			vErrorDescription 	= vErrorDescription + ErrorDescription();	
		EndTry;
	EndIf;
	
	If vSuccess Then
		CommitTransaction();
		vResponse = New HTTPServiceResponse(200);
		vResponse.Headers.Insert("Content-Type", "text/html;charset=utf-8");
		vResponse.SetBodyFromString("OK");
	Else
		RollbackTransaction();
		WriteLogEvent("HTTP_api_chargePOST", EventLogLevel.Error, , , vErrorDescription);
		vResponse = New HTTPServiceResponse(400);
		vResponse.Headers.Insert("Content-Type", "text/html;charset=utf-8");
		vResponse.SetBodyFromString(vErrorDescription);
	EndIf;
	
	Return vResponse;
EndFunction // ChargePOST

// --------------------------------------------------------------------------------
Function writeClientFeedbackPOST(pRequest)
	WriteLogEvent("HTTP_api_writeClientFeedbackPOST", EventLogLevel.Information,,,"Request recieved");
	vSuccess				= True;
	vErrorDescription		= "";
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("token");
	vParamsArray.Add("clientID");
	vParamsArray.Add("surveyID");
	vParamsArray.Add("questions");
	
	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
		
	If ValueIsFilled(vRequestParams.Error) Then
		vSuccess 			= False;
		vErrorDescription 	= vRequestParams.Error; 
	EndIf;

	BeginTransaction();
	Try
		If vSuccess Then
			vInteractionParameters = GetInteractionParameters(vRequestParams.token);
			If ValueIsFilled(vInteractionParameters) Then
				vAccRef = SMS.GetClientDocumentByMyFolioId(vRequestParams.clientID);
				If ValueIsFilled(vAccRef) Then
					vSurvey = GetSurveyByID(vRequestParams.surveyID);
					If ValueIsFilled(vSurvey) Then
						vClientFeedbackObj = Documents.ClientFeedback.CreateDocument();
						vClientFeedbackObj.Survey = vSurvey;
						vClientFeedbackObj.Fill(vAccRef);
						For Each vQuestion In vRequestParams.questions Do
							For Each vSurveyQuestion In vSurvey.Questions Do
								If vSurveyQuestion.FeedbackQuestion.ExternalCode = vQuestion.id Then
									vNewAnswerRow 					= vClientFeedbackObj.Answers.Add();
									vNewAnswerRow.FeedbackQuestion 	= vSurveyQuestion.FeedbackQuestion;
									vNewAnswerRow.Answer			= vQuestion.Answer;
								EndIf;
							EndDo;
						EndDo;
						vClientFeedbackObj.Write();
					Else
						vSuccess 			= False;
						vErrorDescription 	= "Failed to find survey by id";
					EndIf;
				Else
					vSuccess 			= False;
					vErrorDescription 	= "Failed to find accommodation by client id";
				EndIf;
			Else
				vSuccess 			= False;
				vErrorDescription 	= "Not authorized";
			EndIf;
		EndIf;
	Except
		vSuccess 			= False;
		vErrorDescription 	= ErrorDescription();
	EndTry;	
	
	If vSuccess Then
		CommitTransaction();
		vResponse = New HTTPServiceResponse(200);
		vResponse.Headers.Insert("Content-Type", "text/html;charset=utf-8");
		vResponse.SetBodyFromString("OK");
	Else
		RollbackTransaction();
		WriteLogEvent("HTTP_api_writeClientFeedbackPOST", EventLogLevel.Error, , , vErrorDescription);
		vResponse = New HTTPServiceResponse(400);
		vResponse.Headers.Insert("Content-Type", "text/html;charset=utf-8");
		vResponse.SetBodyFromString(vErrorDescription);
	EndIf;
	
	Return vResponse;
EndFunction // WriteClientFeedbackPOST

// --------------------------------------------------------------------------------
Function getSurveysGET(pRequest)
	WriteLogEvent("HTTP_api_getSurveysGET", EventLogLevel.Information, , , "Request recieved");
	vSuccess				= True;                                     
	vErrorDescription		= "";
	vSurveys				= Undefined;
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("token");
	
	// Initialize non mandatory params
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("surveyID");
	
	// Read request body
	vRequestParams = cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vSuccess 			= False;
		vErrorDescription 	= vRequestParams.Error; 
	EndIf;
	
	vInteractionParameters = GetInteractionParameters(vRequestParams.token);
	If ValueIsFilled(vInteractionParameters) Then
		vSurveys = GetSurveysByHotel(vInteractionParameters.Hotel, vRequestParams.surveyID);
	Else
		vSuccess 			= False;
		vErrorDescription 	= "Not authorized";
	EndIf;
	
	If vSuccess and vSurveys <> Undefined Then
		vJSONResponse 	= New JSONWriter;
		vJSONResponse.ValidateStructure = False;
		vJSONResponse.SetString();
		vJSONResponse.WriteStartObject();
		vJSONResponse.WritePropertyName("surveys");
		vJSONResponse.WriteStartArray();
		For Each vSurvey In vSurveys Do
			If Not IsBlankString(vSurvey.Ref.ExternalCode) Then
				vJSONResponse.WriteStartObject();
				vJSONResponse.WritePropertyName("id");
				vJSONResponse.WriteValue(vSurvey.Ref.ExternalCode);
				vJSONResponse.WritePropertyName("questions");
				vJSONResponse.WriteStartArray();
				For Each vQuestion In vSurvey.Ref.Questions Do
					If Not IsBlankString(vQuestion.FeedbackQuestion.ExternalCode) Then 
						vJSONResponse.WriteStartObject();
						vJSONResponse.WritePropertyName("id");
						vJSONResponse.WriteValue(vQuestion.FeedbackQuestion.ExternalCode);
						vJSONResponse.WritePropertyName("text");
						vJSONResponse.WriteValue(vQuestion.FeedbackQuestion.QuestionText);				
						If vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Number Then
							vJSONResponse.WritePropertyName("answerType");
							vJSONResponse.WriteValue("number");
							vJSONResponse.WritePropertyName("answerNumberRestrictionFrom");
							vJSONResponse.WriteValue(vQuestion.FeedbackQuestion.AnswerNumberRestrictionFrom);
							vJSONResponse.WritePropertyName("answerNumberRestrictionTo");
							vJSONResponse.WriteValue(vQuestion.FeedbackQuestion.AnswerNumberRestrictionTo);
						ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.List Then
							vJSONResponse.WritePropertyName("answerType");
							vJSONResponse.WriteValue("list");
							vJSONResponse.WritePropertyName("answers");
							vJSONResponse.WriteStartArray();
							For Each vAnswer In vQuestion.FeedbackQuestion.AnswerVariants Do
								vJSONResponse.WriteStartObject();
								vJSONResponse.WritePropertyName("text");
								vJSONResponse.WriteValue(vAnswer.AnswerText);
								vJSONResponse.WriteEndObject();
							EndDo;
							vJSONResponse.WriteEndArray();
						ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.Boolean Then
							vJSONResponse.WritePropertyName("answerType");
							vJSONResponse.WriteValue("boolean");
						ElsIf vQuestion.FeedbackQuestion.AnswerType = Enums.AnswerTypes.String Then
							vJSONResponse.WritePropertyName("answerType");
							vJSONResponse.WriteValue("string");
						EndIf;
						vJSONResponse.WriteEndObject();
					EndIf;
				EndDo;
				vJSONResponse.WriteEndArray();
				vJSONResponse.WriteEndObject();
			EndIf;
		EndDo;
		vJSONResponse.WriteEndArray();
		vJSONResponse.WriteEndObject();
		vResult = vJSONResponse.Close();
		
		vResponse = New HTTPServiceResponse(200);
		vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
		vResponse.SetBodyFromString(vResult);		
	Else
		WriteLogEvent("HTTP_api_getSurveysGET", EventLogLevel.Error,,,vErrorDescription);
		vJSONResponse 	= New JSONWriter;
		vJSONResponse.ValidateStructure = False;
		vJSONResponse.SetString();
		vJSONResponse.WriteStartObject();			
		vJSONResponse.WritePropertyName("ErrorDescription");
		vJSONResponse.WriteValue(vErrorDescription);
		vJSONResponse.WriteEndObject();	
		vResult = vJSONResponse.Close();
		
		vResponse = New HTTPServiceResponse(400);
		vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
		vResponse.SetBodyFromString(vResult);
	EndIf;
	
	Return vResponse;
EndFunction // GetSurveysGET

// --------------------------------------------------------------------------------
Function createSurveyPOST(pRequest)

	vResponse = New HTTPServiceResponse(400);
	vResponse.Headers.Insert("Content-Type", "text/html;charset=utf-8");
	vResponse.SetBodyFromString("Not yet implemented");

EndFunction // CreateSurveyPOST

// --------------------------------------------------------------------------------
Function HPGDataRequest(pRequest)
	// An example of request
	// {
	// "messageName": "HPGDataRequest",
	// "token": "550e8400-e29b-41d4-a716-446655440000",
	// "externalSystemCode": "HPG",
	// "requestID": "2019-03-15T12:27:23",
	// "hotelCode": "001",
	// "debugMode": "true",
	// "periodFrom": "2019-01-01T00:00:00"
	// }
	
	vSuccess				= True;
	vErrorDescription		= "";
	vResponseCode			= 200;
	vDebugJSON				= "";
	vInteractionParameters 	= Undefined;
	
	Try
		vParamsArray = New Array;
		vParamsArray.Add("messageName");
		vParamsArray.Add("token");
		vParamsArray.Add("externalSystemCode");
		vParamsArray.Add("requestID");
		vParamsArray.Add("hotelCode");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("debugMode");
		vNonMandatoryParamsArray.Add("periodFrom");
		
		// Read request body
		vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vRequestParams.Error) Then
			vSuccess 			= False;
			vErrorDescription 	= vRequestParams.Error;
			vResponseCode		= 400;
		EndIf;
		
		If vSuccess Then
			// Read interaction parameters
			vInteractionParameters = HPGConnect.GetInteractionParameters(vRequestParams.token, vRequestParams.externalSystemCode, vRequestParams.hotelCode);
			If vInteractionParameters <> Undefined Then
				vPeriodFrom = Undefined;
				If Not IsBlankString(vRequestParams.periodFrom) Then
					vPeriodFrom = cmGetDateFromTimestampPresentation(vRequestParams.periodFrom);
				EndIf;
				If lower(vRequestParams.debugMode) = "true" Then
					vResult = HPGConnect.HPGDataRequest(vRequestParams.externalSystemCode, vInteractionParameters, vRequestParams.requestID, True, vPeriodFrom);
					If IsBlankString(vResult.ErrorDescription) Then
						vDebugJSON = vResult.JSONString;
					Else
						vDebugJSON = vResult.ErrorDescription;	
					EndIf;
				Else
					vParametersArray = New Array;
					vParametersArray.Add(vRequestParams.externalSystemCode);
					vParametersArray.Add(vInteractionParameters);
					vParametersArray.Add(vRequestParams.requestID);
					vParametersArray.Add(False);
					vParametersArray.Add(vPeriodFrom);
					If AsyncCalls.CheckForExistingBackgroundJobsInRegister("HTTPService_HPG_HPGDataRequest").Count() = 0 Then 
						AsyncCalls.StartBackgroundJobWithRecordInRegister("HTTPService_HPG_HPGDataRequest", "HPGDataRequest", "HPGConnect.HPGDataRequest", vParametersArray);
					EndIf;
				EndIf;
			Else
				vSuccess 			= False;
				vErrorDescription 	= "Failed to find interaction parameters";
				vResponseCode		= 401;
			EndIf;
		EndIf;
	Except
		vSuccess 			= False;
		vErrorDescription 	= ErrorDescription();
		vResponseCode		= 400;
	EndTry;
	
	vResponseRules = Catalogs.DataConvertationRules.GetRules("HPG", "HPGDataRequest", Enums.DataConvertationTypes.JSONLoad);
	If vResponseRules <> Undefined Then
		If lower(vRequestParams.debugMode) = "true" And Not IsBlankString(vDebugJSON) Then
			vParams = New Structure;
			vParams.Insert("requestID", 		vRequestParams.requestID);
			vParams.Insert("success",			vSuccess);
			vParams.Insert("errorDescription",	vErrorDescription);
			
			vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vResponseRules, vParams);
			vJSONString = Left(vJSONString, StrLen(vJSONString) - 1);
			vJSONString = vJSONString + ", " + vDebugJSON;
			vJSONString = vJSONString + "}";
			
			vResponse = New HTTPServiceResponse(vResponseCode);
			vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");	
			vResponse.SetBodyFromString(vJSONString);
		Else
			vParams = New Structure;
			vParams.Insert("requestID", 		vRequestParams.requestID);
			vParams.Insert("success",			vSuccess);
			vParams.Insert("errorDescription",	vErrorDescription);
			
			vJSONString = Catalogs.DataConvertationRules.ValueTreeToJSON(vResponseRules, vParams);
			
			vResponse = New HTTPServiceResponse(vResponseCode);
			vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
			vResponse.SetBodyFromString(vJSONString);
		EndIf;
	Else
		vResponse = New HTTPServiceResponse(501);	
	EndIf;
	
	Return vResponse;
EndFunction // HPGDataRequest

// --------------------------------------------------------------------------------
Function PushGET(pRequest)
	
	WriteLogEvent("HTTP_api_PushGET", EventLogLevel.Information, , , "Request recieved");
	vResponseCode = 200;
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("ExternalSystemID");
	
	vRequestParams 	= cmCheckRequestParameters("QueryOptions", vParamsArray, , pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vResponseCode 		= 400;
		vErrorDescription 	= vRequestParams.Error; 
	Else
		vInterectionParameters = GetInteractionParametersByID(vRequestParams.ExternalSystemID); 
		
		If vInterectionParameters = Undefined Then
			vResponseCode 		= 403;
			vErrorDescription 	= "Unknown interection system ID.";
		Else
			If vInterectionParameters.IntegrationType = Enums.Integrations.SKK Then
				If vInterectionParameters.DebugMode Then
					SKKConnect.GetOrders(vInterectionParameters);
				Else
					vParams = New Array;
					vParams.Add(vInterectionParameters);
					AsyncCalls.StartBackgroundJobWithRecordInRegister(vInterectionParameters, "api Push", "SKKConnect.GetOrders", vParams, vInterectionParameters.UUID());
				EndIf;	
			Else
				vResponseCode 		= 403;
				vErrorDescription 	= "Unknown interection system ID.";	
			EndIf;
		EndIf;
		
	EndIf;
	
	Response = New HTTPServiceResponse(vResponseCode);
	Return Response;
	
EndFunction // PushGET

// --------------------------------------------------------------------------------
//  Gets Room Events from External System
Function RoomPOST(pRequest)
	
	vResultStructure			= New Structure("Success, Error");
	vResponseCode				= 200;	
	vResultStructure.Success 	= True;
	vInteractionParameters		= Catalogs.ExternalSystemInteractions.EmptyRef();
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("token");
	
	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
	
	// If failed try to read request query options
	If ValueIsFilled(vRequestParams.Error) Then
		vRequestParams 	= cmCheckRequestParameters("QueryOptions", vParamsArray, , pRequest);
	EndIf;

	If ValueIsFilled(vRequestParams.Error) Then
		vResultStructure.Success 	= False;
		vResultStructure.Error 		= vRequestParams.Error;
		vResponseCode				= 401;
	EndIf;
	
	If vResultStructure.Success Then
		vInteractionParameters = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.token);
		If Not ValueIsFilled(vInteractionParameters) Or Not ValueIsFilled(vRequestParams.token) Then
			vResultStructure.Success 	= False;
			vResultStructure.Error 		= "Wrong token"; 
			vResponseCode				= 401;
		EndIf;		
	EndIf;
			
	vJSONString	= Catalogs.DataConvertationRules.MapToJSON(vResultStructure);
	vResponse 	= New HTTPServiceResponse(vResponseCode);
	vResponse.SetBodyFromString(vJSONString);
	
	vRequeuestBody 			= pRequest.GetBodyAsString();
	If vResultStructure.Success Then
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteractionParameters, "RoomPOST", Enums.ExternalSystemEventTypes.Success, vRequeuestBody, vJSONString, vResultStructure.Error, 50000);
	Else
		WriteLogEvent("RoomPOST", EventLogLevel.Error,,,vResultStructure.Error);
	EndIf;
	
	Return vResponse;

EndFunction // RoomPOST

// --------------------------------------------------------------------------------
Function wifiGET(pRequest)
	
	vResult			= New Structure("Success, URL, ReservationNumber, CheckInDate, CheckOutDate, Error", True, "", "", "", "", "");
	vResponseCode	= 200;
	
	Try
		vParamsArray = New Array;
		vParamsArray.Add("token");
		vParamsArray.Add("room");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("DateOfBirth");
		vNonMandatoryParamsArray.Add("LastName");
		vNonMandatoryParamsArray.Add("Phone");

		// Read request body
		vRequestParams = cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);
		
		If ValueIsFilled(vRequestParams.Error) Then
			vResult.Success 	= False;
			vResult.Error 		= vRequestParams.Error;
			vResponseCode		= 400;
		Else
			
			If Not ( ValueIsFilled(vRequestParams.DateOfBirth) Or ValueIsFilled(vRequestParams.LastName) Or ValueIsFilled(vRequestParams.Phone)) Then
				vResult.Success 	= False;
				vResult.Error 		= "Missing identity parameter (DateOfBirth, LastName or Phone)!";
				vResponseCode		= 400;	
			EndIf;
			
		EndIf;
				
		If vResult.Success Then 
			vInteractionParameters 	= GetInteractionParametersByTokenAndSystem(vRequestParams.Token);
			If vInteractionParameters <> Undefined Then 
				If ValueIsFilled(vRequestParams.DateOfBirth) Then
					vRequestDate = Date(vRequestParams.DateOfBirth);
				Else
					vRequestDate = Undefined;
				EndIf;
				
				vAccommodation 	= GetAccommodationByRoom(vInteractionParameters.Hotel, vRequestParams.Room, vRequestDate, vRequestParams.LastName, vRequestParams.Phone);
				
				vRoom = cmGetRoomByCode(vRequestParams.Room, vInteractionParameters.Hotel.Code, vRequestParams.Token);
				If vAccommodation = Undefined Then
					If Not ValueIsFilled(vRoom) Then
						vResult.Error 		= "Wrong room number!";
					ElsIf ValueIsFilled(vRoom) Then
						vResult.Error 		= "Guest not found in room!";
					EndIf;
					vResult.Success 	= False;
					vResponseCode		= 200;
				Else
					vResult.Success 	= vAccommodation.IsInHouse;
					vResult.ReservationNumber = vAccommodation.Ref.Number;
					vResult.CheckInDate = Format(vAccommodation.Ref.CheckInDate, "DF='yyyy-MM-dd HH:mm'");
					vResult.CheckOutDate = Format(vAccommodation.Ref.CheckOutDate, "DF='yyyy-MM-dd HH:mm'");
					vResult.URL 		= GetHotel365URL(vAccommodation.Ref);
					vResponseCode		= 200;	
				EndIf;
			Else
				vResult.Success = False;
				vResult.Error	= "Failed to find interaction parameters";
				vResponseCode 	= 401;	
			EndIf;
			
		EndIf;
	
	Except
		vResult.Success 	= False;
		vResult.Error 		= ErrorDescription();
		vResponseCode		= 400;
	EndTry;
	vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult);

	Response = New HTTPServiceResponse(vResponseCode);
	Response.SetBodyFromString(vResponseBody);
	Return Response;
	
EndFunction // WifiGET

// --------------------------------------------------------------------------------
Function GetHotel365URL(pAccRef)
	Return "";
EndFunction // GetHotel365URL

// --------------------------------------------------------------------------------
Function requestPOST(pRequest)
	
	vResult	= New Map;
	vResult.Insert("Success", 	True);
	vResult.Insert("Error", 	"");
	
	vResponseCode	= 200;
	
	Try
		vParamsArray = New Array;
		vParamsArray.Add("token");
		vParamsArray.Add("dataTypes");
		
		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("periodFrom"); // Format 20190627
		vNonMandatoryParamsArray.Add("debugMode");

		// Read request body
		vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vRequestParams.Error) Then
			vResult.Insert("Success", 	False);
			vResult.Insert("Error", 	vRequestParams.Error);
			vResponseCode = 400;
		EndIf;
		
		If vResult["Success"] Then
			// Read interaction parameters
			vInteractionParameters = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.token);
			If vInteractionParameters <> Undefined Then
				
				vAdditionalParameters = New Structure;
				If ValueIsFilled(vRequestParams.periodFrom) Then
					vAdditionalParameters.Insert("PeriodFrom", Date(vRequestParams.periodFrom));
				EndIf;
				
				
				If lower(vRequestParams.debugMode) = "true" And vInteractionParameters.DebugMode Then
					vDataRequestResult = ProlongedOperations.ExternalSystemDataRequest(vInteractionParameters, vRequestParams.dataTypes, vAdditionalParameters, true);
					vResult.Insert("DataRequestResult", vDataRequestResult); 
				Else										
					vParametersArray = New Array;
					vParametersArray.Add(vInteractionParameters);
					vParametersArray.Add(vRequestParams.dataTypes);
					vParametersArray.Add(vAdditionalParameters);
					If AsyncCalls.CheckForExistingBackgroundJobsInRegister("HTTPService_api_request").Count() = 0 Then 
						AsyncCalls.StartBackgroundJobWithRecordInRegister("HTTPService_api_request", "ExternalSystemDataRequest", "ProlongedOperations.ExternalSystemDataRequest", vParametersArray);
					EndIf;
				EndIf;
				
			Else
				vResult.Insert("Success", 	False);
				vResult.Insert("Error", 	"Failed to find interaction parameters");
				vResponseCode = 401;
			EndIf;
		EndIf;
	Except
		vSuccess 			= False;
		vErrorDescription 	= ErrorDescription();
		vResponseCode		= 400;
	EndTry;
	
	vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult);
	
	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.Headers.Insert("Content-Type", "application/json;charset=utf-8");
	vResponse.SetBodyFromString(vResponseBody);
	
	Return vResponse;
	
EndFunction // RequestPOST

// --------------------------------------------------------------------------------
Function echoPOST(pRequest)
	vStrRequest = pRequest.GetBodyAsString();
	Response = New HTTPServiceResponse(200);
	Response.SetBodyFromString(vStrRequest);
	Return Response;
EndFunction // EchoPOST

// --------------------------------------------------------------------------------
Function echoGET(pRequest)
	vStrRequest = pRequest.GetBodyAsString();
	Response = New HTTPServiceResponse(200);
	Response.SetBodyFromString(vStrRequest);
	Return Response;
EndFunction // EchoGET

// --------------------------------------------------------------------------------
Function interfacePOST(pRequest)
	vResult = New Structure("Response, Success, Error", New Array, True, "");
	vResponseCode = 200; 
	vResponseBody = "";
	
	vInteraction = Undefined;
	vRequestBody = pRequest.GetBodyAsString();
	vRequestHeaders = New Map(pRequest.Headers);
	
	vVersion = vRequestHeaders["Version"];
	
	Try
		vToken = vRequestHeaders["Token"]; 
		
		If vToken <> Undefined Then
			
			vDataProcessors = Undefined;
			
			vInteraction = GetInteractionParametersByTokenAndSystem(vToken);
			If vInteraction <> Undefined Then
				vDataProcessors = vInteraction.DataProcessor;	
			Else
				vDataProcessors = GetDataProcessorsByTokenAndSystem(vToken);		
			EndIf;
			
			If vDataProcessors <> Undefined Then
				If ValueIsFilled(vDataProcessors) Then 
					vObjDataProcessors = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessors, True);
					
					vResult.Response = vObjDataProcessors.HTTPRequest(vRequestBody, vRequestHeaders, vResult.Success, vResult.Error, vVersion);
				Else
					vResult.Success = False;
					vResult.Error 	= "Data processor not specified";
					vResponseCode	= 401;	
				EndIf;
			Else
				vResult.Success = False;
				vResult.Error 	= "Failed to find interaction parameters";
				vResponseCode	= 401;		
			EndIf;
		Else
			vResult.Success = False;
			vResult.Error 	= "Token not specified";
			vResponseCode	= 401;	
	    EndIf;
	Except
		vResult.Success = False;
		vResult.Error 	= ErrorDescription();
		vResponseCode	= 400;
	EndTry;       
		
	If vVersion = "2" Then             
		If vResult.Success And vResponseCode = 200 Then
			vResponseBody = vResult.Response;
		Else
			vResponseBody = vResult.Error 	
		EndIf;
	Else
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult);	
	EndIf;
	
	If ValueIsFilled(vInteraction) And vInteraction.DebugMode Or Not vResult.Success Or vResponseCode <> 200 Then
		vMapRequest = New Map;
		vMapRequest.Insert("Body", cmReplaceControlCharacters(vRequestBody)); 
		vMapRequest.Insert("Headers", vRequestHeaders);
		vJSONRequest = Catalogs.DataConvertationRules.MapToJSON(vMapRequest);
		If Not vResult.Success Or vResponseCode <> 200 Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "POST api/interface/", Enums.ExternalSystemEventTypes.Error, vJSONRequest, cmReplaceControlCharacters(vResponseBody), vResult.Error);	
		ElsIf vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "POST api/interface/", Enums.ExternalSystemEventTypes.Info, vJSONRequest, cmReplaceControlCharacters(vResponseBody), vResult.Error);	
		EndIf;
	EndIf;
	
	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.SetBodyFromString(vResponseBody);
	Return vResponse;
EndFunction // InterfacePOST

// --------------------------------------------------------------------------------
Function interfaceGET(pRequest)
	vResult = New Structure("Response, Success, Error", New Array, True, "");
	vResponseCode = 200; 
	vResponseBody = "";
	
	vInteraction = Undefined;
	vRequestBody = pRequest.GetBodyAsString();
	vRequestHeaders = New Map(pRequest.Headers);
	
	vVersion = vRequestHeaders["Version"];
	
	Try
		vToken = vRequestHeaders["Token"]; 
		
		If vToken <> Undefined Then
			
			vDataProcessors = Undefined;
			
			vInteraction = GetInteractionParametersByTokenAndSystem(vToken);
			If vInteraction <> Undefined Then
				vDataProcessors = vInteraction.DataProcessor;	
			Else
				vDataProcessors = GetDataProcessorsByTokenAndSystem(vToken);		
			EndIf;
			
			If vDataProcessors <> Undefined Then
				If ValueIsFilled(vDataProcessors) Then 
					vObjDataProcessors = Catalogs.DataProcessors.CreateDataProcessorByProcessing(vDataProcessors, True);
					
					vResult.Response = vObjDataProcessors.HTTPRequest(vRequestBody, vRequestHeaders, vResult.Success, vResult.Error, vVersion);
				Else
					vResult.Success = False;
					vResult.Error 	= "Data processor not specified";
					vResponseCode	= 401;	
				EndIf;
			Else
				vResult.Success = False;
				vResult.Error 	= "Failed to find interaction parameters";
				vResponseCode	= 401;		
			EndIf;
		Else
			vResult.Success = False;
			vResult.Error 	= "Token not specified";
			vResponseCode	= 401;	
	    EndIf;
	Except
		vResult.Success = False;
		vResult.Error 	= ErrorDescription();
		vResponseCode	= 400;
	EndTry;       
		
	If vVersion = "2" Then             
		If vResult.Success And vResponseCode = 200 Then
			vResponseBody = vResult.Response;
		Else
			vResponseBody = vResult.Error 	
		EndIf;
	Else
		vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult);	
	EndIf;
	
	If ValueIsFilled(vInteraction) And vInteraction.DebugMode Or Not vResult.Success Or vResponseCode <> 200 Then
		vMapRequest = New Map;
		vMapRequest.Insert("Body", cmReplaceControlCharacters(vRequestBody)); 
		vMapRequest.Insert("Headers", vRequestHeaders);
		vJSONRequest = Catalogs.DataConvertationRules.MapToJSON(vMapRequest);
		If Not vResult.Success Or vResponseCode <> 200 Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "POST api/interface/", Enums.ExternalSystemEventTypes.Error, vJSONRequest, cmReplaceControlCharacters(vResponseBody), vResult.Error);	
		ElsIf vInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "POST api/interface/", Enums.ExternalSystemEventTypes.Info, vJSONRequest, cmReplaceControlCharacters(vResponseBody), vResult.Error);	
		EndIf;
	EndIf;
	
	vResponse = New HTTPServiceResponse(vResponseCode);
	vResponse.SetBodyFromString(vResponseBody);
	Return vResponse;
EndFunction // interfaceGET

// --------------------------------------------------------------------------------
//  Get the list of scheduled jobs and checks it's running
//  in case there is no info about the last job - the job is writen and restarted
//  can be used as outside call to ping the database and foce to start void scheduled jobs
//
// Parameters:
//  pRequest - HTTPServiceRequest - 
// 
// Returns:
//  HTTPServiceResponse - 
//
Function CheckJobsGET(pRequest)
	vResult			= New Structure("Success, Error, Jobs", True, "", New Array);
	vResponseCode	= 200;
	
	vJobsCount = 0;
	Try
		vParamsArray = New Array;
		vParamsArray.Add("Token");
		
		vNonMandatoryParamsArray = New Array;

		// Read request body
		vRequestParams = cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);
		
		If ValueIsFilled(vRequestParams.Error) Then
			vResult.Success 	= False;
			vResult.Error 		= vRequestParams.Error;
			vResponseCode		= 400;
		Else
			If IsBlankString(vRequestParams.Token) Then
				vResult.Success 	= False;
				vResult.Error 		= "Missing identity parameter `Token`!";
				vResponseCode		= 400;	
			EndIf;
		EndIf;
				
		If vResult.Success Then 
			vInteraction 	= GetInteractionParametersByTokenAndSystem(vRequestParams.Token);
			
			If vInteraction <> Undefined Then 
				
				vJobs = ScheduledJobs.GetScheduledJobs(New Structure("Use", True));
				
				vJobsCount = vJobs.Count();
				If vJobs.Count() = 0 Then
					If vInteraction.DebugMode Then
						vMsg = NStr("en = 'Absent Scheduled jobs with the ""Use'' flag'; 
									|de = 'Fehlende geplante Aufgaben mit dem Flag ""Verwenden""'; 
									|ru = 'Отсутствуют Регламентные задания с признаком ""Использование""'");
						InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CheсkJobs",
								Enums.ExternalSystemEventTypes.Info, "Token: " + vRequestParams.Token , , vMsg);
					EndIf;			
				EndIf;
				
				vCurTime = "00010101" + Format(Hour(CurrentDate()),"ND=2; NZ=00; NLZ=") + 
							Format(Minute(CurrentDate()),"ND=2; NZ=00; NLZ=") +
							Format(Second(CurrentDate()),"ND=2; NZ=00; NLZ=");
				vTime = Date(vCurTime);
				
				For Each vJob In vJobs Do
					vJobBeginTime = vJob.Schedule.BeginTime;
					If vJobBeginTime > vTime Then
						vResult.Jobs.Add(TrimAll(vJob.Metadata.Name) + " - " + NStr("en = 'Job is scheduled to : '; de = 'Job  ist geplant auf: '; ru = 'Задание запланировано на время: '") + vJobBeginTime);
					ElsIf vJob.LastJob = Undefined Then
						vJob.Write();
						vWrite = True;
						vResult.Jobs.Add(TrimAll(vJob.Metadata.Name) + " - " + nStr("en = 'Job is restarted'; de = 'Job wird neu gestartet'; ru = 'Перезапущено'"));
					Else
						If IsBlankString(vJob.LastJob.ErrorInfo) Then
							vResult.Jobs.Add(TrimAll(vJob.Metadata.Name) + " - " + nStr("en = 'Job is working:'; de = 'Job ist Arbeit:'; ru = 'Работает нормально:'") + NStr("en = ' begin time: '; de = ' Startzeit: '; ru = ' время старта: '") + vJob.LastJob.Begin);
						Else
							vJobTextDescription = TrimAll(vJob.Metadata.Name) + " - " +
							nStr("en = 'Job is working:'; de = 'Job ist Arbeit:'; ru = 'Работает:'") +
							NStr("en = ' begin time: '; de = ' Startzeit: '; ru = ' время старта: '") + vJob.LastJob.Begin;
							If vJob.LastJob.ErrorInfo <> Undefined Then 
								vJobTextDescription = vJobTextDescription + NStr("en = ' with error - '; de = ' mit Fehler - '; ru = ' с ошибкой - '") + vJob.LastJob.ErrorInfo.Description;
							EndIf;
							vResult.Jobs.Add(vJobTextDescription);
						EndIf;
					EndIf;

				EndDo;
				
			Else
				vResult.Success = False;
				vResult.Error	= "Failed to find interaction parameters by token";
				vResponseCode 	= 401;	
			EndIf;
		EndIf;
	Except
		vResult.Success 	= False;
		vResult.Error 		= ErrorDescription();
		vResponseCode		= 400;
	EndTry;
	
	vLogResponse = Catalogs.DataConvertationRules.MapToJSON(vResult);
	If ValueIsFilled(vInteraction) And vInteraction.DebugMode Then
		if vResult.Success Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CheсkJobs", Enums.ExternalSystemEventTypes.Info, , vLogResponse,NStr("en = 'Jobs count: '; de = 'Jobs zählen: '; ru = 'Проверено заданий: '") + vJobsCount);
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "CheсkJobs", Enums.ExternalSystemEventTypes.Error, , vLogResponse, vResult.Error);
		EndIf;
	EndIf;
	
	vResponseBody = "<html><head><title>Jobj Scheduled</title></head><body>";
	vResponseBody = vResponseBody + "<p>" + XMLString(SessionParameters.CurrentHotel) + "</p>";
	vResponseBody = vResponseBody + "<p>Sucess=" + XMLString(vResult.Success) + "</p>";
	vResponseBody = vResponseBody + ?(IsBlankString(vResult.Error), "", "<p>Error: " + XMLString(vResult.Error) + "</p>");
	vResponseBody = vResponseBody + "<ul>";
	For Each JobDescription In vResult.Jobs Do
		vResponseBody = vResponseBody + "<li>" + JobDescription;
	EndDo;
	vResponseBody = vResponseBody + "</ul>";

	Response = New HTTPServiceResponse(vResponseCode);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString(vResponseBody);
	Return Response;
	
EndFunction // CheсkJobsGET

// --------------------------------------------------------------------------------
//  Get the list tickets for ISD
Function getISDTicketsGET(pRequest)
	vResult			= New Structure("Response, Success, Error", New Array, True, "");
	vResponseCode	= 200;
	
	Try
		vParamsArray = New Array;
		vParamsArray.Add("token");
		
		vNonMandatoryParamsArray = New Array;
        vNonMandatoryParamsArray.Add("CheckInDate");
		vNonMandatoryParamsArray.Add("LastName");
		vNonMandatoryParamsArray.Add("FirstName");
		
		// Read request body
		vRequestParams = cmCheckRequestParameters("QueryOptions", vParamsArray, vNonMandatoryParamsArray, pRequest);
		
		If ValueIsFilled(vRequestParams.Error) Then
			vResult.Success 	= False;
			vResult.Error 		= vRequestParams.Error;
			vResponseCode		= 400;
		Else
			If IsBlankString(vRequestParams.Token) Then
				vResult.Success 	= False;
				vResult.Error 		= "Missing identity parameter `token`!";
				vResponseCode		= 400;	
			EndIf;
		EndIf;
				
		If vResult.Success Then 
			vInteraction 	= GetInteractionParametersByTokenAndSystem(vRequestParams.Token);
			vRequestParams.CheckInDate = ReadJSONDate(vRequestParams.CheckInDate, JSONDateFormat.ISO);  
			vDocs = New Array;
			If vInteraction <> Undefined Then 
				If vInteraction.DebugMode Then
					vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
					InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "getISDTicketsGET.Start",
					Enums.ExternalSystemEventTypes.Info, Catalogs.DataConvertationRules.MapToJSON(vRequestParams), , vMsg, 999999);	
				EndIf;
				
				vQuery = New Query;
				vQuery.Text = 
				"SELECT
				|	Reservation.Number AS Number
				|INTO ResTab
				|FROM
				|	Document.Reservation AS Reservation
				|WHERE
				|	Reservation.Posted 
				|	AND BEGINOFPERIOD(Reservation.CheckInDate, DAY) = &qCheckInDate
				|	AND Reservation.Guest.LastName = &qLastName
				|	AND Reservation.Hotel = &qHotel
				|	AND Reservation.Guest.FirstName LIKE &qFirstName
				|
				|GROUP BY
				|	Reservation.Number
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	ReservationCustomAttributeValues.Owner AS Reservation,
				|	ReservationCustomAttributeValues.Characteristic.Code AS Code,
				|	ReservationCustomAttributeValues.CharacteristicValue AS Value,
				|	ReservationCustomAttributeValues.Owner.ReservationStatus.Description AS ReservationStatus,
				|	ReservationCustomAttributeValues.Owner.CheckInDate AS CheckInDate,
				|	ReservationCustomAttributeValues.Owner.CheckOutDate AS CheckOutDate,
				|	ReservationCustomAttributeValues.Owner.Guest AS Guest,
				|	ReservationCustomAttributeValues.Owner.AccommodationType.Description AS AccommodationType
				|FROM
				|	InformationRegister.ReservationCustomAttributeValues AS ReservationCustomAttributeValues
				|WHERE
				|	ReservationCustomAttributeValues.Owner.Posted
				|	AND ReservationCustomAttributeValues.Owner.Number IN
				|			(SELECT
				|				ResTab.Number AS Number
				|			FROM
				|				ResTab AS ResTab)
				|
				|GROUP BY
				|	ReservationCustomAttributeValues.Owner,
				|	ReservationCustomAttributeValues.Characteristic.Code,
				|	ReservationCustomAttributeValues.CharacteristicValue,
				|	ReservationCustomAttributeValues.Owner.ReservationStatus.Description,
				|	ReservationCustomAttributeValues.Owner.CheckInDate,
				|	ReservationCustomAttributeValues.Owner.CheckOutDate,
				|	ReservationCustomAttributeValues.Owner.Guest,
				|	ReservationCustomAttributeValues.Owner.AccommodationType.Description
				|TOTALS BY
				|	Reservation";
				
				vQuery.SetParameter("qCheckInDate", BegOfDay(vRequestParams.CheckInDate));
				vQuery.SetParameter("qLastName", vRequestParams.LastName);
				vQuery.SetParameter("qFirstName", vRequestParams.FirstName + "%");
				vQuery.SetParameter("qHotel", vInteraction.Hotel);
				
				vQueryResult = vQuery.Execute();
				
				vResHead = vQueryResult.Select(QueryResultIteration.ByGroups);
				While vResHead.Next() Do    
					vRow = New Structure("Guest, Reservation, AccommodationType, ReservationStatus, CheckInDate, CheckOutDate, ORDER, ORDERBAR, TICKET");   
					vRow.Guest = TrimAll(vResHead.Guest.FullName);  
					vRow.AccommodationType = TrimAll(vResHead.AccommodationType);
					vRow.ReservationStatus = TrimAll(vResHead.ReservationStatus);
					vRow.CheckInDate = vResHead.CheckInDate;
					vRow.CheckOutDate = vResHead.CheckOutDate;
					vRow.Reservation = vResHead.Reservation.Number;

					vResDetails = vResHead.Select();
					While vResDetails.Next() Do 
						If TrimAll(vResDetails.Code) = "NORDER" Then
							vRow.ORDER = TrimAll(vResDetails.Value);	
						ElsIf TrimAll(vResDetails.Code) = "NORDERBAR" Then	
							vRow.ORDERBAR = TrimAll(vResDetails.Value);
						ElsIf TrimAll(vResDetails.Code) = "NTICKET" Then
							vRow.TICKET = TrimAll(vResDetails.Value);	
						EndIf;
					EndDo;
					vDocs.Add(vRow);
				EndDo; 
				vResult.Response = vDocs;
			Else
				vResult.Success = False;
				vResult.Error	= "Failed to find interaction parameters by token";
				vResponseCode 	= 401;	
			EndIf;
		EndIf;
	Except
		vResult.Success = False;
		vResult.Error 	= ErrorDescription();
		vResponseCode	= 400;
	EndTry;
	vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResult);
	If vInteraction.DebugMode Then
		vMsg = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "getISDTicketsGET.End",
		Enums.ExternalSystemEventTypes.Info, , vResponseBody , vMsg, 999999);	
	EndIf;
	Response = New HTTPServiceResponse(vResponseCode);  
	Response.Headers.Insert("Content-Type", "application/json;charset=utf-8");
	Response.SetBodyFromString(vResponseBody);
	Return Response;
EndFunction // GetISDTicketsGET

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
Function GetInteractionParameters(pToken)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.Code = &qToken";
	
	vQuery.SetParameter("qToken", pToken);
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
EndFunction // GetInteractionParameters

// --------------------------------------------------------------------------------
Function GetInteractionParametersByID(pInteractionID)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ExternalSystemInteractions.Ref AS Ref
		|FROM
		|	Catalog.ExternalSystemInteractions AS ExternalSystemInteractions
		|WHERE
		|	ExternalSystemInteractions.IsActive
		|	AND NOT ExternalSystemInteractions.DeletionMark
		|	AND ExternalSystemInteractions.InteractionID = &qInteractionID";
	
	vQuery.SetParameter("qInteractionID", pInteractionID);
	
	vQueryResult = vQuery.Execute().Unload();
	For Each vRow In vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
EndFunction // GetInteractionParametersByID

// --------------------------------------------------------------------------------
Function GetRoomByCard(pInteractionParameters, pIdentifier)
	vRoom = Catalogs.Rooms.EmptyRef();
	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Room AS Room
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND (IdentificationCards.Identifier = &qIdentifier
	|			OR IdentificationCards.CardUID = &qIdentifier)
	|
	|ORDER BY
	|	IdentificationCards.CreateDate DESC,
	|	IdentificationCards.Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vCards = vQry.Execute().Unload();
	If vCards.Count() > 0 Then
		vRoom = vCards.Get(0).Room; 
	EndIf;
	Return vRoom;
EndFunction // GetRoomByCard

// --------------------------------------------------------------------------------
Function GetClientData(pInteractionParameters, pIdentifier)
	WriteLogEvent(NStr("en='Get client identification card balance';ru='Получение баланса по карте идентификации клиента';de='Erhalten der Bilanz nach der Kundenidentifikationskarte'"), EventLogLevel.Information, , , 
				NStr("en='Card identifier: ';ru='Идентификатор карты: ';de='Kartenidentifikator: '") + pIdentifier + Chars.LF + 
				NStr("en='External system code: ';ru='Код внешней системы: ';de='Externe System Code: '") + pInteractionParameters.InteractionID);
	
	vResult = New Structure("LastName, FirstName, SecondName, Hotel, Room, CheckInDate, CheckOutDate, IsCheckedOut, IsBlocked, BlockReason, Remarks, Photo,
	|Balance, Client, CreditLimit, Card, GuestGroup, Customer, FolioCurrency, RoomRate, Discount, DiscountType, DiscountCard, ClientCode, FolioNumber, MealBoardTerm");
	
	vResult.LastName 		= "";
	vResult.FirstName 		= "";
	vResult.SecondName 		= "";
	vResult.Hotel 			= "";
	vResult.Room 			= "";
	vResult.CheckInDate 	= "";
	vResult.CheckOutDate 	= "";
	vResult.IsCheckedOut 	= True;
	vResult.IsBlocked 		= True;
	vResult.BlockReason 	= "";
	vResult.Remarks 		= "";
	vResult.Photo 			= "";
	vResult.Balance 		= 0;
	vResult.Client 			= "";
	vResult.Card 			= "";
	vResult.CreditLimit 	= 0;
	vResult.GuestGroup 		= "";
	vResult.Customer 		= "";
	vResult.FolioCurrency 	= "";
	vResult.RoomRate 		= "";
	vResult.Discount 		= 0;
	vResult.DiscountType 	= "";
	vResult.DiscountCard 	= "";
	vResult.ClientCode 		= "";
	vResult.FolioNumber 	= "";
	vResult.MealBoardTerm 	= "";
	
	// Initialize return string
	vRetStr 			= "";
	vBalance 			= 0;
	vLimit 				= 0;
	vClientFullName 	= "";
	vHotelName 			= "";
	vRoomCode 			= "";
	vCheckInDate 		= '00010101';
	vCheckOutDate 		= '00010101';
	vIsCheckedOut 		= True;
	vIsBlocked 			= True;
	vBlockReason 		= "";
	vCreditLimit 		= 0;
	vCard				= "";
	vGuestGroupCode		= 0;
	vCustomerName 		= "";
	vPaymentMethodName 	= "";
	vFolioCurrencyCode 	= "";
	vRoomRateCode 		= "";
	vDiscount 			= 0;
	vDiscountType 		= Undefined;
	vDiscountCard 		= Undefined;
	vClientCode 		= "";	
	vOrdersXDTO 		= Undefined;
	vPhone 				= Undefined;
	vDateOfBirth 		= Undefined;

	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.ParentDoc AS ParentDoc,
	|	IdentificationCards.Identifier AS Identifier,
	|	IdentificationCards.Client AS Client
	|INTO IdentificationCards
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IdentificationCards.Ref AS Ref,
	|	IdentificationCards.CreateDate AS CreateDate,
	|	IdentificationCards.Code AS Code,
	|	IdentificationCards.Description AS Description,
	|	IdentificationCards.IsBlocked AS IsBlocked,
	|	IdentificationCards.IsCheckedOut AS IsCheckedOut,
	|	"""" AS Identifier,
	|	IdentificationCards.ParentDoc AS ParentDoc,
	|	IdentificationCards.Folio AS Folio,
	|	IdentificationCards.GuestGroup AS GuestGroup,
	|	IdentificationCards.Client AS Client,
	|	IdentificationCards.Room AS Room,
	|	IdentificationCards.DateTimeFrom AS DateTimeFrom,
	|	IdentificationCards.DateTimeTo AS DateTimeTo,
	|	IdentificationCards.Hotel AS Hotel,
	|	IdentificationCards.BlockReason AS BlockReason,
	|	ISNULL(IdentificationCards.IdentificationCardType.DoNotUseChargingRules, FALSE) AS DoNotUseChargingRules,
	|	ISNULL(IdentificationCards.IdentificationCardType.ExternalSystemsAllowed, &qEmptyString) AS ExternalSystemsAllowed,
	|	1 AS SortCode,
	|	IdentificationCards.Identifier AS Card
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND (IdentificationCards.Identifier = &qIdentifier
	|			OR IdentificationCards.CardUID = &qIdentifier)
	|
	|UNION ALL
	|
	|SELECT
	|	DiscountCards.Ref,
	|	ISNULL(Folios.Date, DiscountCards.ValidFrom),
	|	DiscountCards.Code,
	|	DiscountCards.Description,
	|	DiscountCards.IsBlocked,
	|	ISNULL(NOT Folios.ParentDoc.AccommodationStatus.IsInHouse, TRUE),
	|	DiscountCards.Identifier,
	|	Folios.ParentDoc,
	|	Folios.Ref,
	|	Folios.GuestGroup,
	|	DiscountCards.Client,
	|	Folios.Room,
	|	ISNULL(Folios.DateTimeFrom, &qEmptyDate),
	|	ISNULL(Folios.DateTimeTo, &qEmptyDate),
	|	ISNULL(Folios.Hotel, &qCurrentHotel),
	|	DiscountCards.Remarks,
	|	FALSE,
	|	&qEmptyString,
	|	CASE
	|		WHEN Folios.Ref IS NULL
	|			THEN 3
	|		ELSE 2
	|	END,
	|	ISNULL(IdentificationCards.Identifier, """")
	|FROM
	|	Catalog.DiscountCards AS DiscountCards
	|		LEFT JOIN Document.Folio AS Folios
	|			LEFT JOIN IdentificationCards AS IdentificationCards
	|			ON Folios.ParentDoc = IdentificationCards.ParentDoc
	|				AND Folios.Client = IdentificationCards.Client
	|		ON (NOT Folios.IsClosed)
	|			AND (NOT Folios.DeletionMark)
	|			AND (Folios.Client = DiscountCards.Client
	|					AND Folios.Client <> &qEmptyClient
	|				OR Folios.ParentDoc.DiscountCard = DiscountCards.Ref)
	|			AND (Folios.Customer = &qEmptyCustomer
	|				OR Folios.Customer <> &qEmptyCustomer
	|					AND Folios.Customer.IsIndividual)
	|			AND (Folios.Hotel.AdditionalServicesFolioCondition = &qEmptyString
	|				OR Folios.Hotel.AdditionalServicesFolioCondition <> &qEmptyString
	|					AND Folios.Description LIKE ""%"" + Folios.Hotel.AdditionalServicesFolioCondition + ""%"")
	|WHERE
	|	NOT DiscountCards.DeletionMark
	|	AND DiscountCards.Identifier = &qIdentifier
	|	AND DiscountCards.ValidFrom <= &qCurrentDate
	|	AND (DiscountCards.ValidTo = &qEmptyDate
	|			OR DiscountCards.ValidTo <> &qEmptyDate
	|				AND DiscountCards.ValidTo >= &qCurrentDate)
	|
	|ORDER BY
	|	SortCode,
	|	CreateDate DESC,
	|	Code DESC";
	vQry.SetParameter("qIdentifier", TrimAll(pIdentifier));
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyString", "                                                  ");
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vQry.SetParameter("qEmptyDate", '00010101');
	vQry.SetParameter("qCurrentHotel", SessionParameters.CurrentHotel);
	vCards 		= vQry.Execute().Unload();
	vCardRow 	= Undefined;
	
	If vCards.Count() > 0 Then
		vCardRow = vCards.Get(0);
		
		// Check if external system is allowed
		If Not IsBlankString(pInteractionParameters.InteractionID) And Not IsBlankString(vCardRow.ExternalSystemsAllowed) Then
			If Find(vCardRow.ExternalSystemsAllowed, TrimAll(pInteractionParameters.InteractionID)) = 0 Then
				vErrorMessage = TrimAll(vCardRow.Ref.IdentificationCardType) + NStr("en=' card is not allowed!'; ru=' карта не принимается!'; de=' Karte ist nicht erlaubt!'");
				vResult.IsBlocked 	= True;
				vResult.BlockReason = Left(vErrorMessage, 100);
				Return vResult;
			EndIf;
		EndIf;
		
		// Get folio from the client identification card
		vFolioCondition = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "");
		vFolioRef = vCardRow.Folio;
		vHotel = Undefined;
		If ValueIsFilled(vFolioRef) Then
			vHotel = vFolioRef.Hotel;
			vIsCheckedOut = vFolioRef.IsClosed;
			If vFolioRef.IsClosed Then
				vCreditLimit = 0;
			ElsIf ValueIsFilled(vFolioRef.Hotel) Then
				If vFolioRef.Hotel.NoCreditLimit Then
					vCreditLimit = 999999999;
				Else
					vCreditLimit = vFolioRef.CreditLimit;
				EndIf;
			EndIf;
			vCustomerName = ?(ValueIsFilled(vFolioRef.Customer), TrimAll(vFolioRef.Customer.Description), "");
			vPaymentMethodName = ?(ValueIsFilled(vFolioRef.PaymentMethod), TrimAll(vFolioRef.PaymentMethod.Description), "");
			vFolioCurrencyCode = ?(ValueIsFilled(vFolioRef.FolioCurrency), TrimAll(vFolioRef.FolioCurrency.Code), "");
			If vCardRow.DoNotUseChargingRules Or IsBlankString(vFolioCondition) Or Not IsBlankString(vFolioCondition) And Find(vFolioRef.Description, vFolioCondition) > 0 Then
				vBalance = vFolioRef.GetObject().pmGetBalance('39991231235959', , , vLimit);
				vBalance = vBalance - vLimit;
			EndIf;
			If ValueIsFilled(vFolioRef.ParentDoc) And 
				(TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolioRef.ParentDoc) = Type("DocumentRef.Reservation")) Then
				vRoomRateCode = ?(ValueIsFilled(vFolioRef.ParentDoc.RoomRate), TrimAll(vFolioRef.ParentDoc.RoomRate.Description), "");
				If vFolioRef.ParentDoc.ServicePackage.IsMealBoardTerm Then
					vResult.MealBoardTerm = vFolioRef.ParentDoc.ServicePackage.Code;
				EndIf;
			EndIf;
			vResult.FolioNumber = vFolioRef.Number;
		EndIf;
		vClientFullName = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.FullName), "");
		vPhone = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.Phone), Undefined);
		vDateOfBirth = ?(ValueIsFilled(vCardRow.Client), vCardRow.Client.DateOfBirth, Undefined);
		vClientCode = ?(ValueIsFilled(vCardRow.Client), TrimAll(vCardRow.Client.Code), "");
		vHotelName = ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.Description), "");
		vRoomCode = ?(ValueIsFilled(vCardRow.Room), TrimAll(vCardRow.Room.Description), "");
		vCheckInDate = vCardRow.DateTimeFrom;
		vCheckOutDate = vCardRow.DateTimeTo;
		vIsBlocked = vCardRow.IsBlocked;
		vBlockReason = TrimAll(vCardRow.BlockReason);
		vGuestGroupCode	= ?(ValueIsFilled(vCardRow.GuestGroup), Number(vCardRow.GuestGroup.Code), 0);
		vCard = vCardRow.Card;  
		
		// Get discount data
		If ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountCard) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountCard = vCardRow.Folio.FolioDiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.Folio) And ValueIsFilled(vCardRow.Folio.FolioDiscountType) And Not ValueIsFilled(vCardRow.ParentDoc) Then
			vDiscountType = vCardRow.Folio.FolioDiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) 
			And	ValueIsFilled(vCardRow.ParentDoc.DiscountCard) Then
			vDiscountCard = vCardRow.ParentDoc.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		ElsIf ValueIsFilled(vCardRow.ParentDoc) And 
			(TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vCardRow.ParentDoc) = Type("DocumentRef.ResourceReservation")) 
			And	ValueIsFilled(vCardRow.ParentDoc.DiscountType) Then
			vDiscountType = vCardRow.ParentDoc.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
		Else
			If ValueIsFilled(vCardRow.Client) Then
				If ValueIsFilled(vCardRow.Client.DiscountType) Then
					vDiscountType = vCardRow.Client.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vCardRow.Client);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vCardRow.Hotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		// Add balances from the other parent document client folios
		If ValueIsFilled(vCardRow.ParentDoc) And ValueIsFilled(vFolioRef) And Not vCardRow.DoNotUseChargingRules Then
			// Check if this folio is in charging rules
			vChargingRulesFolios = New ValueList();
			vCardFolioIsInChargingRules = False;
			vCardParentDoc = vCardRow.ParentDoc;
			If TypeOf(vCardParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vCardParentDoc) = Type("DocumentRef.Reservation") Then
				vCardParentDocGuestGroup = vCardParentDoc.GuestGroup;
				vChargingRules = vCardParentDoc.ChargingRules;
				If vChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
					vCardFolioIsInChargingRules = True;
				Else
					If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
						vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
						If vCardParentDocGuestGroupChargingRules.Find(vFolioRef, "ChargingFolio") <> Undefined Then
							vCardFolioIsInChargingRules = True;
						EndIf;
					EndIf;
				EndIf;
				For Each vPDCRRow In vChargingRules Do
					If vChargingRulesFolios.FindByValue(vPDCRRow.ChargingFolio) = Undefined Then
						vChargingRulesFolios.Add(vPDCRRow.ChargingFolio);
					EndIf;
				EndDo;
				If ValueIsFilled(vCardParentDocGuestGroup) And vCardParentDocGuestGroup.ChargingRules.Count() > 0 Then
					vCardParentDocGuestGroupChargingRules = vCardParentDocGuestGroup.ChargingRules;
					For Each vPDGGCRRow In vCardParentDocGuestGroupChargingRules Do
						If vChargingRulesFolios.FindByValue(vPDGGCRRow.ChargingFolio) = Undefined Then
							vChargingRulesFolios.Add(vPDGGCRRow.ChargingFolio);
						EndIf;
					EndDo;
				EndIf;
			ElsIf TypeOf(vCardParentDoc) = Type("DocumentRef.ResourceReservation") Then
				If vFolioRef = vCardParentDoc.ChargingFolio Then
					vCardFolioIsInChargingRules = True;
				EndIf;
				If ValueIsFilled(vCardParentDoc.ChargingFolio) Then
					If vChargingRulesFolios.FindByValue(vCardParentDoc.ChargingFolio) = Undefined Then
						vChargingRulesFolios.Add(vCardParentDoc.ChargingFolio);
					EndIf;
				EndIf;
			EndIf;
			If vCardFolioIsInChargingRules Then
				vQryBalances =  New Query();
				vQryBalances.Text = 
				"SELECT
				|	ClientAccountsBalance.Folio AS Folio,
				|	ClientAccountsBalance.FolioCurrency AS FolioCurrency,
				|	ISNULL(ClientAccountsBalance.Folio.Hotel.NoCreditLimit, FALSE) AS NoCreditLimit,
				|	ClientAccountsBalance.Folio.IsClosed AS IsClosed,
				|	ClientAccountsBalance.Folio.CreditLimit AS CreditLimit,
				|	ISNULL(ClientAccountsBalance.SumBalance, 0) + ISNULL(ClientAccountsBalance.LimitBalance, 0) AS ClientBalance
				|FROM
				|	AccumulationRegister.Accounts.Balance(
				|			&qBalancesPeriod,
				|			Folio <> &qFolio
				|				AND Folio IN (&qChargingRulesFolios)
				|				AND Folio.ParentDoc = &qParentDoc
				|				AND (Folio.Customer = &qEmptyCustomer
				|					OR Folio.Customer <> &qEmptyCustomer AND Folio.Customer.IsIndividual)
				|				AND (Folio.Description LIKE &qFolioDescription
				|					OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance";
				vQryBalances.SetParameter("qBalancesPeriod", '39991231235959');
				vQryBalances.SetParameter("qFolio", vFolioRef);
				vQryBalances.SetParameter("qChargingRulesFolios", vChargingRulesFolios);
				vQryBalances.SetParameter("qParentDoc", vCardRow.ParentDoc);
				vQryBalances.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
				vQryBalances.SetParameter("qFolioDescription", "%" + ?(ValueIsFilled(vCardRow.Hotel), TrimAll(vCardRow.Hotel.AdditionalServicesFolioCondition), "") + "%");
				vQryBalances.SetParameter("qFolioDescriptionIsEmpty", ?(ValueIsFilled(vCardRow.Hotel), IsBlankString(vCardRow.Hotel.AdditionalServicesFolioCondition), True));
				vFolios = vQryBalances.Execute().Unload();
				For Each vFoliosRow In vFolios Do
					If vFoliosRow.FolioCurrency = vFolioRef.FolioCurrency Then
						vBalance = vBalance + vFoliosRow.ClientBalance;
						If Not vFoliosRow.IsClosed Then
							If vFoliosRow.NoCreditLimit Then
								vCreditLimit = 999999999;
							Else
								vCreditLimit = Max(vCreditLimit, vFoliosRow.CreditLimit);
							EndIf;
						EndIf;
					Else
						vBalance = vBalance + cmConvertCurrencies(vFoliosRow.ClientBalance, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel));
						If Not vFoliosRow.IsClosed Then
							If vFoliosRow.NoCreditLimit Then
								vCreditLimit = 999999999;
							Else
								vCreditLimit = Max(vCreditLimit, cmConvertCurrencies(vFoliosRow.CreditLimit, vFoliosRow.FolioCurrency, , vFolioRef.FolioCurrency, , CurrentSessionDate(), ?(ValueIsFilled(vCardRow.Hotel), vCardRow.Hotel, vFolioRef.Hotel)));
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		// Add client bonuses
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vCardRow.ParentDoc) Then
			If ValueIsFilled(vCardRow.ParentDoc.DiscountCard) Then
				vDocDiscountCard = vCardRow.ParentDoc.DiscountCard;
			EndIf;
		EndIf;
		If ValueIsFilled(vCardRow.Client) And ValueIsFilled(vFolioRef) Then
			vClientObj = vCardRow.Client.GetObject();
			vBonus = 0;
			vBonusAmount = vClientObj.pmGetBonusesAmount(vFolioRef.Hotel, vFolioRef.FolioCurrency, vDocDiscountCard, vBonus);
			If vCreditLimit < 999999999 Then
				vCreditLimit = vCreditLimit + vBonusAmount;
			EndIf;
		EndIf;
	Else
		vIsBlocked = True;
		vBlockReason = NStr("en='Unknown card!';ru='Неизвестная карта!';de='Unbekannte Karte!'");
	EndIf;
	
	// Build return string in CSV format
	vRetStr = Format(vBalance, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
	"""" + cmRemoveComma(vClientFullName) + """" + "," + 
	"""" + cmRemoveComma(vHotelName) + """" + "," + 
	"""" + vRoomCode + """" + "," + 
	"""" + Format(vCheckInDate, "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
	"""" + Format(vCheckOutDate, "DF='dd.MM.yyyy HH:mm'") + """" + "," + 
	?(vIsCheckedOut, 1, 0) + "," + 
	?(vIsBlocked, 1, 0) + "," + 
	"""" + cmRemoveComma(vBlockReason) + """" + "," + 
	Format(vCreditLimit, "ND=17; NFD=2; NDS=.; NZ=; NG=") + "," + 
	Format(vGuestGroupCode, "ND=12; NFD=0; NZ=; NG=") + "," + 
	"""" + cmRemoveComma(vCustomerName) + """" + "," + 
	"""" + cmRemoveComma(vPaymentMethodName) + """" + "," + 
	"""" + vFolioCurrencyCode + """" + "," + 
	"""" + vRoomRateCode + """" + "," + 
	?(vDiscount <> 0, Format(vDiscount, "ND=6; NFD=2; NDS=.; NZ=; NG="), "0") + "," +
	"""" + ?(ValueIsFilled(vDiscountType), cmRemoveComma(vDiscountType.Description), "") + """" + "," + 
	"""" + ?(ValueIsFilled(vDiscountCard), cmRemoveComma(vDiscountCard.Identifier), "") + """" + "," + 
	"""" + vClientCode + """" + "," +
	"""" + vCard + """";
	WriteLogEvent(NStr("en='Get client identification card balance';ru='Получение баланса по карте идентификации клиента';de='Erhalten der Bilanz nach der Kundenidentifikationskarte'"), EventLogLevel.Information, , , NStr("en='Return string: ';ru='Строка возврата: ';de='Zeilenrücklauf: '") + vRetStr);
	
	vResult.Balance 			= vBalance;
	vResult.Client 				= vClientFullName;
	vResult.Hotel 				= vHotelName;
	vResult.Room 				= vRoomCode;
	If ValueIsFilled(vCheckInDate) Then
		vResult.CheckInDate 		= vCheckInDate;
	EndIf;
	If ValueIsFilled(vCheckOutDate) Then
		vResult.CheckOutDate 		= vCheckOutDate;
    EndIf;
	vResult.IsCheckedOut 		= vIsCheckedOut;
	vResult.IsBlocked 			= vIsBlocked;
	vResult.BlockReason 		= Left(vBlockReason, 100);
	vResult.CreditLimit 		= vCreditLimit;
	vResult.Card 				= vCard;
	vResult.GuestGroup 			= vGuestGroupCode;
	vResult.Customer 			= vCustomerName;
	vResult.FolioCurrency 		= vFolioCurrencyCode;
	vResult.RoomRate 			= vRoomRateCode;
	vResult.Discount 			= vDiscount;
	vResult.DiscountType 		= ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
	vResult.DiscountCard 		= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
	vResult.ClientCode 			= vClientCode;
	
	If vCardRow <> Undefined Then
		If ValueIsFilled(vCardRow.Client) Then
			vResult.LastName 		= vCardRow.Client.LastName;
			vResult.FirstName 		= vCardRow.Client.FirstName;
			vResult.SecondName 		= vCardRow.Client.SecondName;
			vResult.Remarks 		= vCardRow.Client.Remarks;
			vPhoto = vCardRow.Client.Photo.Get();
			If vPhoto <> Undefined Then 
				If TypeOf(vPhoto) = Type("Picture") Then
					vPhoto = vPhoto.GetBinaryData();
				EndIf;
				If TypeOf(vPhoto) = Type("BinaryData") Then 
					vResult.Photo  = Base64String(vPhoto);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	Return vResult;
EndFunction // GetClientData

// --------------------------------------------------------------------------------
Function GetFolioDescription(pFolioNumber, pHotelCode = "", pInteractionParameters, pRequestParams)
	// Log input parameters
	WriteLogEvent(NStr("en='Get folio description';ru='Получить данные лицевого счета';de='Daten der Personenkontos erhalten'"), EventLogLevel.Information, , , 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pInteractionParameters.InteractionID + Chars.LF + 
	NStr("en='Hotel: ';ru='Гостиница: ';de='Hotel: '") + pHotelCode + Chars.LF + 
	NStr("en='Folio number: ';ru='Номер фолио: ';de='Folionummer: '") + pFolioNumber);
	
	// Initialize return parameters
	vResult = New Structure("LastName, FirstName, SecondName, Hotel, Room, CheckInDate, CheckOutDate, IsCheckedOut, IsBlocked, BlockReason, Remarks, Photo,
	|Balance, Client, CreditLimit, Card, CardTypeCode, CardTypeDescription, OtherCardsGuest, GuestGroup, Customer, FolioCurrency, RoomRate, Discount, DiscountType, DiscountCard, ClientCode, FolioNumber, MealBoardTerm");
	
	vResult.LastName 		= "";
	vResult.FirstName 		= "";
	vResult.SecondName 		= "";
	vResult.Hotel 			= "";
	vResult.Room 			= "";
	vResult.CheckInDate 	= "";
	vResult.CheckOutDate 	= "";
	vResult.IsCheckedOut 	= False;
	vResult.IsBlocked 		= False;
	vResult.BlockReason 	= "";
	vResult.Remarks 		= "";
	vResult.Photo 			= "";
	vResult.Balance 		= 0;
	vResult.Client 			= "";
	vResult.CreditLimit 	= 0;
	vResult.Card			= "";
	vResult.CardTypeCode	= "";
	vResult.CardTypeDescription	= "";
	vResult.OtherCardsGuest = New Array;
	vResult.GuestGroup 		= "";
	vResult.Customer 		= "";
	vResult.FolioCurrency 	= "";
	vResult.RoomRate 		= "";
	vResult.Discount 		= 0;
	vResult.DiscountType 	= "";
	vResult.DiscountCard 	= "";
	vResult.ClientCode 		= "";
	vResult.FolioNumber 	= "";
	vResult.MealBoardTerm 	= "";
		
	// Get hotel
	vHotel = SessionParameters.CurrentHotel;
	If Not IsBlankString(pHotelCode) Then
		vHotel = cmGetHotelByCode(pHotelCode, pInteractionParameters.InteractionID);
	EndIf;
	
	// Get folio reference by folio number
	vFolio = cmFindFolioByNumber(pFolioNumber, vHotel);
	If Not ValueIsFilled(vFolio) Then
		WriteLogEvent(NStr("en='Get folio description';ru='Получить данные лицевого счета';de='Daten der Personenkontos erhalten'"), EventLogLevel.Warning, , , 
		NStr("en='Folio was not found!';ru='Лицевой счет не найден по номеру!';de='Das Personenkonto wurde nach der Nummer nicht gefunden!'"));
		vResult.IsBlocked 		= True;
		vResult.BlockReason 	= NStr("en='Folio was not found!';ru='Лицевой счет не найден по номеру!';de='Das Personenkonto wurde nach der Nummer nicht gefunden!'");
		Return vResult;
	EndIf;
	If ValueIsFilled(vFolio.Hotel) Then
		vHotel = vFolio.Hotel;
	EndIf;
	If vFolio.IsClosed Then
		vResult.IsCheckedOut 	= True;
		vResult.IsBlocked 		= True;
		vResult.BlockReason 	= NStr("en='Folio is closed!';ru='Лицевой счет закрыт!';de='Das Personenkonto ist geschlossen!'");
	EndIf;
	If Not ValueIsFilled(vFolio.Customer) And Not ValueIsFilled(vFolio.Client) Then
		vResult.IsBlocked 		= True;
		vResult.BlockReason 	= NStr("en='It is not allowed to charge this folio. Folio owner is not specified.';ru='Лицевой счет нельзя использовать для данного способа закрытия заказа! Не задан владелец фолио.';de='Das Personenkonto darf nicht für diese Art der Bestellschließung verwendet werden! Der Folio-Besitzer ist nicht angegeben.'");
		Return vResult;	
	EndIf;
	
	// Get folio balance
	vLimit = 0;
	vFolioBalance = vFolio.GetObject().pmGetBalance( , , , vLimit);
	vFolioBalance = vFolioBalance + vLimit;
	
	// Get discount data
	vDiscount = 0;
	vDiscountType = Undefined;
	vDiscountCard = Undefined;
	If ValueIsFilled(vFolio.FolioDiscountCard) Then
		vDiscountCard = vFolio.FolioDiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		If ValueIsFilled(vDiscountType) Then
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		EndIf;
	ElsIf ValueIsFilled(vFolio.FolioDiscountType) Then
		vDiscountType = vFolio.FolioDiscountType;
		vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) 
		And	ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
		vDiscountCard = vFolio.ParentDoc.DiscountCard;
		vDiscountType = vDiscountCard.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) 
		And	ValueIsFilled(vFolio.ParentDoc.DiscountType) Then
		vDiscountType = vFolio.ParentDoc.DiscountType;
		vDiscount = vFolio.ParentDoc.Discount;
	ElsIf ValueIsFilled(vFolio.Client) Then
		If ValueIsFilled(vFolio.Client.DiscountType) Then
			vDiscountType = vFolio.Client.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			vDiscountCard = cmGetDiscountCardByClient(vFolio.Client);
			If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
				vDiscountType = vDiscountCard.DiscountType;
				vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
			EndIf;
		EndIf;
	EndIf;
	If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
	EndIf;
	
	vCreditLimit = vFolio.CreditLimit;
	If vFolio.IsClosed Then
		vCreditLimit = 0;
	Else
		If ValueIsFilled(vHotel) And vHotel.NoCreditLimit Then
			vCreditLimit = 999999999;
		EndIf;
	EndIf;
	
	// Add client bonuses
	If ValueIsFilled(vFolio.Client) Then
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vFolio.ParentDoc) And 
			(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation") 
			Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.ResourceReservation")) 
			And	ValueIsFilled(vFolio.ParentDoc.DiscountCard) Then
			vDocDiscountCard = vFolio.ParentDoc.DiscountCard;
		EndIf;
		vClientObj = vFolio.Client.GetObject();
		vBonus = 0;
		vBonusAmount = vClientObj.pmGetBonusesAmount(vFolio.Hotel, vFolio.FolioCurrency, vDocDiscountCard, vBonus);
		If vCreditLimit < 999999999 Then
			vCreditLimit = vCreditLimit + vBonusAmount;
		EndIf;
	EndIf;
	
	If ValueIsFilled(vFolio.ParentDoc) And 
		(TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Accommodation") Or TypeOf(vFolio.ParentDoc) = Type("DocumentRef.Reservation")) Then
		vResult.RoomRate = ?(ValueIsFilled(vFolio.ParentDoc.RoomRate), TrimAll(vFolio.ParentDoc.RoomRate.Description), "");
		If vFolio.ParentDoc.ServicePackage.IsMealBoardTerm Then
			vResult.MealBoardTerm = vFolio.ParentDoc.ServicePackage.Code;
		EndIf;
	EndIf;
	
	// Build XDTO return object
	If ValueIsFilled(vFolio.Client) Then
		vResult.LastName 		= vFolio.Client.LastName;
		vResult.FirstName 		= vFolio.Client.FirstName;
		vResult.SecondName 		= vFolio.Client.SecondName;
		vResult.Remarks 		= vFolio.Client.Remarks;
		vPhoto = vFolio.Client.Photo.Get();
		If vPhoto <> Undefined Then 
			If TypeOf(vPhoto) = Type("Picture") Then
				vPhoto = vPhoto.GetBinaryData();
			EndIf;
			If TypeOf(vPhoto) = Type("BinaryData") Then 
				vResult.Photo  = Base64String(vPhoto);
			EndIf;
		EndIf;
	EndIf;
	vResult.Balance 		= vFolioBalance;
	vResult.FolioNumber 	= TrimAll(vFolio.Number);
	vResult.Hotel 			= TrimAll(vHotel.Description);
	vResult.Room 			= TrimAll(vFolio.Room);
	vResult.CheckInDate 	= vFolio.DateTimeFrom;
	vResult.CheckOutDate 	= vFolio.DateTimeTo;
	vResult.GuestGroup 		= ?(ValueIsFilled(vFolio.GuestGroup), vFolio.GuestGroup.Code, 0);
	vResult.FolioCurrency 	= TrimAll(vFolio.FolioCurrency.Code);
	vResult.CreditLimit 	= vCreditLimit;
	vResult.Client 			= ?(ValueIsFilled(vFolio.Client), TrimAll(vFolio.Client.FullName), "");
	vResult.ClientCode 		= ?(ValueIsFilled(vFolio.Client), TrimAll(vFolio.Client.Code), "");
	vResult.Customer 		= ?(ValueIsFilled(vFolio.Customer), TrimAll(vFolio.Customer.Description), "");
	vResult.Discount 		= vDiscount;
	vResult.DiscountType 	= ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
	vResult.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
	
	vCardType = Undefined;
	If pRequestParams.Property("cardtype") And pRequestParams.cardtype <> "all" And ValueIsFilled(pRequestParams.cardtype) Then
		vCardType = Catalogs.IdentificationCardTypes.FindByCode(pRequestParams.cardtype);
	EndIf;
	
	// Card
	vCardAns = GetIdentificationCard(vFolio.ParentDoc, vCardType);
	If ValueIsFilled(vCardAns) Then
		vResult.Card = TrimAll(vCardAns.Identifier);
		If ValueIsFilled(vCardAns.IdentificationCardType) Then
			vResult.CardTypeCode= TrimAll(vCardAns.IdentificationCardType.Code);
			vResult.CardTypeDescription	= TrimAll(vCardAns.IdentificationCardType.Description);
		EndIf;
	EndIf;
	If pRequestParams.Property("cardtype") And ValueIsFilled(pRequestParams.cardtype) And pRequestParams.cardtype = "all" Then
		// Add other cards
		vCards = GetIdentificationCards(vFolio.ParentDoc);
		vOtherCardsGuest = New Array;
		For Each vRowCard In vCards Do
			vCurCard = vRowCard.Ref;
			If vCurCard = vCardAns Then
				Continue;
			EndIf;	
			vNewRow = New Structure("DateTimeFrom, DateTimeTo, Card, CardTypeCode, CardTypeDescription", "", "", "", "", "");
			vNewRow.DateTimeFrom = vCurCard.DateTimeFrom;
			vNewRow.DateTimeTo = vCurCard.DateTimeTo;
			vNewRow.Card = vCurCard.Identifier;
			If ValueIsFilled(vCurCard.IdentificationCardType) Then
				vNewRow.CardTypeCode = vCurCard.IdentificationCardType.Code;
				vNewRow.CardTypeDescription = vCurCard.IdentificationCardType.Description;
			EndIf;
			vOtherCardsGuest.Add(vNewRow);
		EndDo;
		vResult.OtherCardsGuest = vOtherCardsGuest;
	EndIf;	
	
	Return vResult;
EndFunction // GetFolioDescription 

// --------------------------------------------------------------------------------
Function GetIdentificationCard(pParentDoc, pCardType = Undefined)
	vIdentification = Undefined;
	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND IdentificationCards.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	IdentificationCards.CreateDate DESC,
	|	IdentificationCards.Code DESC";
	If ValueIsFilled(pCardType) Then
		vQry.Text = StrReplace(vQry.Text, "AND IdentificationCards.ParentDoc = &qParentDoc", "AND IdentificationCards.ParentDoc = &qParentDoc AND IdentificationCards.IdentificationCardType = &qIdentificationCardType");
		vQry.SetParameter("qIdentificationCardType", pCardType);
	EndIf;	
	vQry.SetParameter("qParentDoc", pParentDoc);
	vCards = vQry.Execute().Unload();
	If vCards.Count() > 0 Then
		vIdentification = vCards.Get(0).Ref; 
	EndIf;
	Return vIdentification;
EndFunction // GetIdentificationCard

// --------------------------------------------------------------------------------
Function GetIdentificationCards(pParentDoc, pCardType = Undefined)
	// Try to find client identification card by identifier
	vQry =  New Query();
	vQry.Text = 
	"SELECT
	|	IdentificationCards.Ref AS Ref
	|FROM
	|	Catalog.IdentificationCards AS IdentificationCards
	|WHERE
	|	NOT IdentificationCards.DeletionMark
	|	AND IdentificationCards.ParentDoc = &qParentDoc
	|
	|ORDER BY
	|	IdentificationCards.CreateDate DESC,
	|	IdentificationCards.Code DESC";
	If ValueIsFilled(pCardType) Then
		vQry.Text = StrReplace(vQry.Text, "AND IdentificationCards.ParentDoc = &qParentDoc", "AND IdentificationCards.ParentDoc = &qParentDoc AND IdentificationCards.IdentificationCardType = &qIdentificationCardType");
		vQry.SetParameter("qIdentificationCardType", pCardType);
	EndIf;	
	vQry.SetParameter("qParentDoc", pParentDoc);
	vCards = vQry.Execute().Unload();
	Return vCards;
EndFunction // GetIdentificationCards

// --------------------------------------------------------------------------------
Function GetHotelGuestsList(pGuestName = "", pRoomCode = "", pHotelName = "", pInteractionParameters, pRequestParams)
	// Initialize return parameters
	vResultArray 	= New Array;
	
	
	// Initialize input parameters
	If pGuestName = Undefined Then
		pGuestName = "";
	EndIf;
	If pRoomCode = Undefined Then
		pRoomCode = "";
	EndIf;
	If pHotelName = Undefined Then
		pHotelName = "";
	EndIf;
	
	vExtSystemCode = "TraktirFO3";
	If Not IsBlankString(pInteractionParameters.InteractionID) Then
		vExtSystemCode = TrimR(pInteractionParameters.InteractionID);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelName, vExtSystemCode);
	// Find room by code
	vRoomCode = TrimR(pRoomCode);
	vRoom = cmGetRoomByCode(pRoomCode, pHotelName, vExtSystemCode);
	If ValueIsFilled(vRoom) Then
		vRoomCode = TrimR(vRoom.Description);
		vHotel = vRoom.Owner;
	EndIf;		
	
	// Log input parameters
	WriteLogEvent(NStr("en='Get list of hotel guests';ru='Получить список гостей гостиницы';de='Liste der Hotelgäste erhalten'"), EventLogLevel.Information, , , 
	NStr("en='Guest name: ';ru='Имя гостя: ';de='Name des Gastes: '") + pGuestName + Chars.LF +
	NStr("en='Room code: ';ru='Код номера: ';de='Zimmercode: '") + pRoomCode + " (" + vRoom + ")" + Chars.LF +
	NStr("en='Hotel name: ';ru='Название гостиницы: ';de='Bezeichnung des Hotels: '") + pHotelName + " (" + TrimAll(vHotel) + ")" + Chars.LF + 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pInteractionParameters.InteractionID + " (" + TrimAll(vExtSystemCode) + ")");
	
	// Try to find guests by input parameters
	vQry = New Query();
	vQry.Text = 
	"SELECT DISTINCT
	|	RoomInventory.Guest AS Guest,
	|	RoomInventory.Guest.FullName AS GuestFullName,
	|	ISNULL(RoomInventory.Guest.Code, &qEmptyString) AS GuestCode,
	|	RoomInventory.Hotel AS Hotel,
	|	RoomInventory.Hotel.Description AS HotelDescription,
	|	RoomInventory.Room.Description AS RoomDescription,
	|	RoomInventory.Room.SortCode AS RoomSortCode,
	|	RoomInventory.Recorder.CheckInDate AS CheckInDate,
	|	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
	|	RoomInventory.Recorder.AccommodationType AS AccommodationType,
	|	RoomInventory.Recorder.AccommodationType.SortCode AS AccommodationTypeSortCode,
	|	RoomInventory.Recorder.Number AS AccommodationCode,
	|	RoomInventory.Recorder.DiscountCard AS DiscountCard,
	|	RoomInventory.Recorder.DiscountType AS DiscountType,
	|	CASE
	|		WHEN ISNULL(RoomInventory.Recorder.ServicePackage.IsMealBoardTerm, FALSE)
	|			THEN RoomInventory.Recorder.ServicePackage
	|		ELSE UNDEFINED
	|	END AS MealBoardTerm,
	|	ISNULL(RoomInventory.GuestGroup.Code, 0) AS GuestGroupCode,
	|	RoomInventory.Customer.Description AS CustomerDescription,
	|	RoomInventory.PlannedPaymentMethod.Description AS PlannedPaymentMethodDescription,
	|	ISNULL(ClientBalances.ClientBalance, 0) + ISNULL(ClientBalances.ClientLimit, 0) AS ClientBalance,
	|	ISNULL(ClientCreditLimit.CreditLimit, 0) AS CreditLimit,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency
	|		ELSE ClientBalances.FolioCurrency
	|	END AS FolioCurrency,
	|	CASE
	|		WHEN ClientBalances.FolioCurrency IS NULL
	|			THEN ClientCreditLimit.FolioCurrency.Code
	|		ELSE ClientBalances.FolioCurrency.Code
	|	END AS FolioCurrencyCode,
	|	RoomInventory.Guest.FirstName AS GuestFirstName,
	|	RoomInventory.Guest.SecondName AS GuestSecondName,
	|	RoomInventory.Guest.LastName AS GuestLastName,
	|	RoomInventory.Guest.DiscountCard.IsBlocked AS GuestDiscountCardIsBlocked,
	|	RoomInventory.Recorder AS Recorder
	|FROM
	|	(SELECT
	|		RoomInventoryMovements.Guest AS Guest,
	|		RoomInventoryMovements.Hotel AS Hotel,
	|		RoomInventoryMovements.Room AS Room,
	|		RoomInventoryMovements.Recorder AS Recorder,
	|		RoomInventoryMovements.GuestGroup AS GuestGroup,
	|		RoomInventoryMovements.Customer AS Customer,
	|		RoomInventoryMovements.PlannedPaymentMethod AS PlannedPaymentMethod
	|	FROM
	|		AccumulationRegister.RoomInventory AS RoomInventoryMovements
	|	WHERE
	|		RoomInventoryMovements.IsAccommodation
	|		AND RoomInventoryMovements.IsInHouse
	|		AND RoomInventoryMovements.RecordType = &qRecordType
	|		AND RoomInventoryMovements.PeriodFrom <= &qCurrentDate
	|		AND (RoomInventoryMovements.PeriodTo >= &qCurrentDate
	|				OR RoomInventoryMovements.PeriodTo = RoomInventoryMovements.Recorder.CheckOutDate)
	|		AND RoomInventoryMovements.Guest <> &qEmptyClient
	|		AND (RoomInventoryMovements.Hotel.Description = &qHotelName
	|				OR RoomInventoryMovements.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (RoomInventoryMovements.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (RoomInventoryMovements.Guest.Description LIKE &qGuestName
	|				OR &qEmptyGuestName)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VirtualGuests.Guest,
	|		VirtualGuests.Hotel,
	|		VirtualGuests.Room,
	|		VirtualGuests.Ref,
	|		VirtualGuests.GuestGroup,
	|		VirtualGuests.Customer,
	|		VirtualGuests.PlannedPaymentMethod
	|	FROM
	|		Document.Accommodation AS VirtualGuests
	|	WHERE
	|		VirtualGuests.Posted
	|		AND VirtualGuests.AccommodationStatus.IsActive
	|		AND VirtualGuests.AccommodationStatus.IsInHouse
	|		AND VirtualGuests.Room.IsVirtual
	|		AND VirtualGuests.CheckInDate <= &qCurrentDate
	|		AND VirtualGuests.CheckOutDate >= &qCurrentDate
	|		AND VirtualGuests.Guest <> &qEmptyClient
	|		AND (VirtualGuests.Hotel.Description = &qHotelName
	|				OR VirtualGuests.Hotel.Code = &qHotelName
	|				OR &qEmptyHotel)
	|		AND (VirtualGuests.Room.Description = &qRoomCode
	|				OR &qEmptyRoomCode)
	|		AND (VirtualGuests.Guest.Description LIKE &qGuestName
	|				OR &qEmptyGuestName)) AS RoomInventory
	|		LEFT JOIN (SELECT
	|			ClientAccountsBalance.FolioCurrency AS FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc AS FolioParentDoc,
	|			SUM(ClientAccountsBalance.SumBalance) AS ClientBalance,
	|			SUM(ClientAccountsBalance.LimitBalance) AS ClientLimit
	|		FROM
	|			AccumulationRegister.Accounts.Balance(
	|					&qBalancesPeriod,
	|					NOT Folio.IsClosed
	|						AND (Folio.Customer = &qEmptyCustomer
	|							OR Folio.Customer <> &qEmptyCustomer
	|								AND Folio.Customer.IsIndividual
	|							OR Folio.Description LIKE &qFolioDescription
	|								AND NOT &qFolioDescriptionIsEmpty)
	|						AND (Folio.Description LIKE &qFolioDescription
	|							OR &qFolioDescriptionIsEmpty)) AS ClientAccountsBalance
	|		
	|		GROUP BY
	|			ClientAccountsBalance.FolioCurrency,
	|			ClientAccountsBalance.Folio.ParentDoc) AS ClientBalances
	|		ON RoomInventory.Recorder = ClientBalances.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientBalances.FolioCurrency
	|		LEFT JOIN (SELECT
	|			ClientFolios.FolioCurrency AS FolioCurrency,
	|			ClientFolios.ParentDoc AS FolioParentDoc,
	|			MAX(CASE
	|					WHEN ClientFolios.Hotel.NoCreditLimit
	|						THEN 999999999
	|					WHEN ClientFolios.Customer <> &qEmptyCustomer
	|							AND NOT ClientFolios.Customer.IsIndividual
	|							AND ClientFolios.Description LIKE &qFolioDescription
	|							AND NOT &qFolioDescriptionIsEmpty
	|						THEN 999999999
	|					ELSE ClientFolios.CreditLimit
	|				END) AS CreditLimit
	|		FROM
	|			Document.Folio AS ClientFolios
	|		WHERE
	|			NOT ClientFolios.IsClosed
	|			AND (ClientFolios.Customer = &qEmptyCustomer
	|					OR ClientFolios.Customer <> &qEmptyCustomer
	|						AND ClientFolios.Customer.IsIndividual
	|					OR ClientFolios.Description LIKE &qFolioDescription
	|						AND NOT &qFolioDescriptionIsEmpty)
	|			AND (ClientFolios.Description LIKE &qFolioDescription
	|					OR &qFolioDescriptionIsEmpty)
	|		
	|		GROUP BY
	|			ClientFolios.FolioCurrency,
	|			ClientFolios.ParentDoc) AS ClientCreditLimit
	|		ON RoomInventory.Recorder = ClientCreditLimit.FolioParentDoc
	|			AND RoomInventory.Recorder.Hotel.FolioCurrency = ClientCreditLimit.FolioCurrency
	|
	|ORDER BY
	|	HotelDescription,
	|	RoomSortCode,
	|	AccommodationTypeSortCode,
	|	GuestFullName";
	vQry.SetParameter("qBalancesPeriod", '39991231235959');
	vQry.SetParameter("qEmptyCustomer", Catalogs.Customers.EmptyRef());
	vQry.SetParameter("qEmptyClient", Catalogs.Clients.EmptyRef());
	vQry.SetParameter("qRecordType", AccumulationRecordType.Expense);
	vQry.SetParameter("qHotelName", TrimR(pHotelName));
	vQry.SetParameter("qEmptyHotel", IsBlankString(pHotelName));
	vQry.SetParameter("qGuestName", Upper(TrimR(pGuestName)) + "%");
	vQry.SetParameter("qEmptyGuestName", IsBlankString(pGuestName));
	vQry.SetParameter("qRoomCode", TrimR(vRoomCode));
	vQry.SetParameter("qEmptyRoomCode", IsBlankString(vRoomCode));
	vQry.SetParameter("qEmptyString", "");
	vQry.SetParameter("qFolioDescription", "%" + TrimAll(vHotel.AdditionalServicesFolioCondition) + "%");
	vQry.SetParameter("qFolioDescriptionIsEmpty", IsBlankString(vHotel.AdditionalServicesFolioCondition));
	vQry.SetParameter("qCurrentDate", CurrentSessionDate());
	vGuests = vQry.Execute().Unload();
	For Each vGuestsRow In vGuests Do
		vResult 		= New Structure("LastName, FirstName, SecondName, Hotel, Room, CheckInDate, CheckOutDate, IsCheckedOut, IsBlocked, BlockReason, Remarks, Photo,
		|Balance, Client, CreditLimit, Card, CardTypeCode, OtherCardsGuest, CardTypeDescription, GuestGroup, Customer, FolioCurrency, RoomRate, Discount, DiscountType, DiscountCard, ClientCode, FolioNumber, MealBoardTerm");
		
		vResult.LastName 		= "";
		vResult.FirstName 		= "";
		vResult.SecondName 		= "";
		vResult.Hotel 			= "";
		vResult.Room 			= "";
		vResult.CheckInDate 	= "";
		vResult.CheckOutDate 	= "";
		vResult.IsCheckedOut 	= False;
		vResult.IsBlocked 		= False;
		vResult.BlockReason 	= "";
		vResult.Remarks 		= "";
		vResult.Photo 			= "";
		vResult.Balance 		= 0;
		vResult.Client 			= "";
		vResult.CreditLimit 	= 0;
		vResult.Card 			= "";
		vResult.CardTypeCode	= "";
		vResult.CardTypeDescription	= "";
		vResult.OtherCardsGuest = New Array;
		vResult.GuestGroup 		= "";
		vResult.Customer 		= "";
		vResult.FolioCurrency 	= "";
		vResult.RoomRate 		= "";
		vResult.Discount 		= 0;
		vResult.DiscountType 	= "";
		vResult.DiscountCard 	= "";
		vResult.ClientCode 		= "";
		vResult.FolioNumber 	= "";
		vResult.MealBoardTerm 	= "";

		vGuest = vGuestsRow.Guest;
		
		// Get discount data
		vDiscount = 0;
		vDiscountType = Undefined;
		vDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDiscountCard = vGuestsRow.DiscountCard;
			vDiscountType = vDiscountCard.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		ElsIf ValueIsFilled(vGuestsRow.DiscountType) Then
			vDiscountType = vGuestsRow.DiscountType;
			vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
		Else
			If ValueIsFilled(vGuest) Then
				If ValueIsFilled(vGuest.DiscountType) Then
					vDiscountType = vGuest.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vGuest);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
		EndIf;
		
		vIsRoomShare = False;
		If ValueIsFilled(vGuestsRow.AccommodationType) And vGuestsRow.AccommodationType.Type <> Enums.AccomodationTypes.Room Then
			vIsRoomShare = True;
		EndIf;
		
		// Document discount card
		vDocDiscountCard = Undefined;
		If ValueIsFilled(vGuestsRow.DiscountCard) Then
			vDocDiscountCard = vGuestsRow.DiscountCard;
		EndIf;
		
		// Add client bonuses
		If ValueIsFilled(vGuest) And ValueIsFilled(vGuestsRow.FolioCurrency) Then
			vClientObj = vGuest.GetObject();
			vBonus = 0;
			vBonusAmount = vClientObj.pmGetBonusesAmount(vGuestsRow.Hotel, vGuestsRow.FolioCurrency, vDocDiscountCard, vBonus);
			If vGuestsRow.CreditLimit < 999999999 Then
				vGuestsRow.CreditLimit = vGuestsRow.CreditLimit + vBonusAmount;
			EndIf;
		EndIf;
				
		// Build XDTO return object
		vThereIsOpenFolio = False;
		IF ValueIsFilled(vGuestsRow.Recorder) Then
			For Each vChargingRulesRow In vGuestsRow.Recorder.ChargingRules Do
				If Not vChargingRulesRow.ChargingFolio.IsClosed Then
					vThereIsOpenFolio = True;
					Break;
				EndIf;
			EndDo;
			
			vResult.RoomRate 		= ?(ValueIsFilled(vGuestsRow.Recorder.RoomRate), TrimAll(vGuestsRow.Recorder.RoomRate.Description), "");
			If vThereIsOpenFolio and vGuestsRow.Recorder.AccommodationStatus.IsInHouse Then 
				vResult.Client 			= vGuestsRow.GuestFullName;
				vResult.LastName 		= vGuestsRow.GuestLastName;
				vResult.FirstName 		= vGuestsRow.GuestFirstName;
				vResult.SecondName 		= vGuestsRow.GuestSecondName;
				vResult.ClientCode 		= vGuestsRow.GuestCode;
				vPhoto = vGuest.Photo.Get();
				If vPhoto <> Undefined Then 
					If TypeOf(vPhoto) = Type("Picture") Then
						vPhoto = vPhoto.GetBinaryData();
					EndIf;
					If TypeOf(vPhoto) = Type("BinaryData") Then 
						vResult.Photo  = Base64String(vPhoto);
					EndIf;
				EndIf;
				vResult.Hotel 			= cmRemoveComma(vGuestsRow.HotelDescription);
				vResult.Room 			= TrimAll(vGuestsRow.RoomDescription);
				vResult.CheckInDate 	= Date(vGuestsRow.CheckInDate);
				vResult.CheckOutDate 	= Date(vGuestsRow.CheckOutDate);
				vResult.GuestGroup 		= vGuestsRow.GuestGroupCode;
				vResult.Customer 		= cmRemoveComma(vGuestsRow.CustomerDescription);
				vResult.Balance 		= vGuestsRow.ClientBalance;
				vResult.CreditLimit 	= vGuestsRow.CreditLimit;
				vResult.FolioCurrency 	= TrimAll(vGuestsRow.FolioCurrencyCode);
				vResult.Discount 		= vDiscount;
				vResult.DiscountType 	= ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
				vResult.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
				vResult.Remarks    		= TrimAll(vGuest.Remarks);
				vResult.MealBoardTerm   = ?(ValueIsFilled(vGuestsRow.MealBoardTerm), TrimAll(vGuestsRow.MealBoardTerm.Code), "");
				
				vCardType = Undefined;
				If pRequestParams.Property("cardtype") And pRequestParams.cardtype <> "all" And ValueIsFilled(pRequestParams.cardtype) Then
					vCardType = Catalogs.IdentificationCardTypes.FindByCode(pRequestParams.cardtype);
				EndIf;

				// Card
				vCardAns = GetIdentificationCard(vGuestsRow.Recorder, vCardType);
				If ValueIsFilled(vCardAns) Then
					vResult.Card = TrimAll(vCardAns.Identifier);
					If ValueIsFilled(vCardAns.IdentificationCardType) Then
						vResult.CardTypeCode= TrimAll(vCardAns.IdentificationCardType.Code);
						vResult.CardTypeDescription	= TrimAll(vCardAns.IdentificationCardType.Description);
					EndIf;
				EndIf;
				If pRequestParams.Property("cardtype") And pRequestParams.cardtype = "all" Then
					// Add other cards
					vCards = GetIdentificationCards(vGuestsRow.Recorder);
					vOtherCardsGuest = New Array;
					For Each vRowCard In vCards Do
						vCurCard = vRowCard.Ref;
						If vCurCard = vCardAns Then
							Continue;
						EndIf;	
						vNewRow = New Structure("DateTimeFrom, DateTimeTo, Card, CardTypeCode, CardTypeDescription", "", "", "", "", "");
					    vNewRow.DateTimeFrom = vCurCard.DateTimeFrom;
						vNewRow.DateTimeTo = vCurCard.DateTimeTo;
						vNewRow.Card = vCurCard.Identifier;
						If ValueIsFilled(vCurCard.IdentificationCardType) Then
							vNewRow.CardTypeCode = vCurCard.IdentificationCardType.Code;
							vNewRow.CardTypeDescription = vCurCard.IdentificationCardType.Description;
						EndIf;
						vOtherCardsGuest.Add(vNewRow);
					EndDo;
					vResult.OtherCardsGuest = vOtherCardsGuest;
				EndIf;	
				vResultArray.Add(vResult);
			EndIf;		
		EndIf;

	EndDo;
		
	Return vResultArray;
EndFunction // GetHotelGuestsList

// --------------------------------------------------------------------------------
Function InitClientStruct()
	vResult 		= New Structure("LastName, FirstName, SecondName, Hotel, Room, CheckInDate, CheckOutDate, IsCheckedOut, IsBlocked, BlockReason, Remarks, Photo,
		|Balance, Client, CreditLimit, Card, GuestGroup, Customer, FolioCurrency, RoomRate, Discount, DiscountType, DiscountCard, ClientCode, FolioNumber, MealBoardTerm, Reservations");
		
		vResult.LastName 		= "";
		vResult.FirstName 		= "";
		vResult.SecondName 		= "";
		vResult.Hotel 			= "";
		vResult.Room 			= "";
		vResult.CheckInDate 	= "";
		vResult.CheckOutDate 	= "";
		vResult.IsCheckedOut 	= False;
		vResult.IsBlocked 		= False;
		vResult.BlockReason 	= "";
		vResult.Remarks 		= "";
		vResult.Photo 			= "";
		vResult.Balance 		= 0;
		vResult.Client 			= "";
		vResult.CreditLimit 	= 0;
		vResult.Card 			= "";
		vResult.GuestGroup 		= "";
		vResult.Customer 		= "";
		vResult.FolioCurrency 	= "";
		vResult.RoomRate 		= "";
		vResult.Discount 		= 0;
		vResult.DiscountType 	= "";
		vResult.DiscountCard 	= "";
		vResult.ClientCode 		= "";
		vResult.FolioNumber 	= "";
		vResult.MealBoardTerm 	= "";
		vResult.Reservations	= "";
	Return vResult;

EndFunction // InitClientStruct

// --------------------------------------------------------------------------------
Function GetClientInfoByPhone(pPhone, pHotelName = "", pInteractionParameters)
	// Initialize return parameters
	vClientsArray 	= New Array;
	
	
	// Initialize input parameters
	If pHotelName = Undefined Then
		pHotelName = "";
	EndIf;
	
	If Not IsBlankString(pInteractionParameters.InteractionID) Then
		vExtSystemCode = TrimR(pInteractionParameters.InteractionID);
	EndIf;
	vHotel = cmGetHotelByCode(pHotelName, vExtSystemCode);
	
	// Log input parameters
	WriteLogEvent(NStr("en='Get client by phone number';ru='Получить список гостей по телефону';de='Liste der Hotelgäste erhalten'"), EventLogLevel.Information, , , 
	NStr("en='Phone: ';ru='Телефон: ';de='Telefon: '") + pPhone + Chars.LF +
	NStr("en='Hotel name: ';ru='Название гостиницы: ';de='Bezeichnung des Hotels: '") + pHotelName + " (" + TrimAll(vHotel) + ")" + Chars.LF + 
	NStr("en='External system code: ';ru='Код внешней системы: ';de='Code des externen Systems: '") + pInteractionParameters.InteractionID + " (" + TrimAll(vExtSystemCode) + ")");
	
	// Try to find guests by input parameters
	vQry = New Query();
	vQry.Text = 
	"SELECT
		|	Customers.Ref AS Client,
		|	TRUE AS IsCustomer
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	Customers.Ref IN HIERARCHY (VALUE(Catalog.Customers.IndividualsFolder))
		|	AND NOT Customers.IsFolder
		|	AND NOT Customers.DeletionMark
		|	AND Customers.Phone = &qPhone
		|
		|UNION ALL
		|
		|SELECT
		|	Clients.Ref,
		|	FALSE
		|FROM
		|	Catalog.Clients AS Clients
		|WHERE
		|	NOT Clients.IsFolder
		|	AND NOT Clients.DeletionMark
		|	AND Clients.Phone = &qPhone
		|
		|ORDER BY
		|	IsCustomer DESC";
	
	vQry.SetParameter("qPhone", pPhone);

	qRes = vQry.Execute().Select();
	While qRes.Next() Do
		vClientData = InitClientStruct();

		If qRes.IsCustomer Then
			vClientData.Customer 		= cmRemoveComma(qRes.Client.Description);
		Else
			vGuest = qRes.Client;
			
			// Get discount data
			vDiscount = 0;
			vDiscountType = Undefined;
			vDiscountCard = Undefined;
			If ValueIsFilled(vGuest) Then
				If ValueIsFilled(vGuest.DiscountType) Then
					vDiscountType = vGuest.DiscountType;
					vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
				Else
					vDiscountCard = cmGetDiscountCardByClient(vGuest);
					If ValueIsFilled(vDiscountCard) And ValueIsFilled(vDiscountCard.DiscountType) Then
						vDiscountType = vDiscountCard.DiscountType;
						vDiscount = vDiscountType.GetObject().pmGetDiscount(, , vHotel);
					EndIf;
				EndIf;
			EndIf;
			If ValueIsFilled(vDiscountType) And vDiscountType.DoNotExportToExternalInterfaces Then
				vDiscount = 0;
				vDiscountType = Undefined;
				vDiscountCard = Undefined;
			EndIf;
			
			// Add client bonuses
			If ValueIsFilled(vGuest) Then
				vClientObj = vGuest.GetObject();
				vBonus = 0;
				vBonusAmount = vClientObj.pmGetBonusesAmount(vHotel, vHotel.FolioCurrency, vDiscountCard, vBonus);
			EndIf;
			vClientData.Discount 		= vDiscount;
			vClientData.DiscountType 	= ?(ValueIsFilled(vDiscountType), TrimAll(vDiscountType.Description), "");
			vClientData.DiscountCard 	= ?(ValueIsFilled(vDiscountCard), TrimAll(vDiscountCard.Identifier), "");
			vClientData.Remarks    		= TrimAll(vGuest.Remarks);
				
			vClientData.Client 			= vGuest.FullName;
			vClientData.LastName 		= vGuest.LastName;
			vClientData.FirstName 		= vGuest.FirstName;
			vClientData.SecondName 		= vGuest.SecondName;
			vClientData.ClientCode 		= vGuest.Code;
			vPhoto = vGuest.Photo.Get();
			If vPhoto <> Undefined Then 
				If TypeOf(vPhoto) = Type("Picture") Then
					vPhoto = vPhoto.GetBinaryData();
				EndIf;
				If TypeOf(vPhoto) = Type("BinaryData") Then 
					vClientData.Photo  = Base64String(vPhoto);
				EndIf;
			EndIf;
			vClientData.Hotel 			= cmRemoveComma(vHotel);
			
			vQ = New Query("SELECT
			               |	RoomInventory.Recorder AS Recorder,
			               |	RoomInventory.Recorder.Number AS Number,
			               |	RoomInventory.Recorder.GuestGroup AS GuestGroup,
			               |	RoomInventory.Recorder.Customer AS Customer,
			               |	RoomInventory.Recorder.CheckInDate AS CheckInDate,
			               |	RoomInventory.Recorder.CheckOutDate AS CheckOutDate,
			               |	RoomInventory.Recorder.RoomType AS RoomType,
			               |	RoomInventory.Recorder.Room AS Room,
			               |	RoomInventory.Recorder.RoomRate AS RoomRate,
			               |	RoomInventory.Recorder.AccommodationStatus AS AccommodationStatus,
			               |	RoomInventory.Recorder.AccommodationStatus.IsInHouse AS InHouse,
			               |	RoomInventory.Recorder.ReservationStatus AS ReservationStatus
			               |FROM
			               |	AccumulationRegister.RoomInventory AS RoomInventory
			               |WHERE
			               |	RoomInventory.Guest = &qGuest
			               |
			               |GROUP BY
			               |	RoomInventory.Recorder,
			               |	RoomInventory.Recorder.CheckInDate,
			               |	RoomInventory.Recorder.CheckOutDate,
			               |	RoomInventory.Recorder.RoomType,
			               |	RoomInventory.Recorder.Room,
			               |	RoomInventory.Recorder.RoomRate,
			               |	RoomInventory.Recorder.AccommodationStatus,
			               |	RoomInventory.Recorder.ReservationStatus,
			               |	RoomInventory.Recorder.Number,
			               |	RoomInventory.Recorder.GuestGroup,
			               |	RoomInventory.Recorder.AccommodationStatus.IsInHouse,
			               |	RoomInventory.Recorder.Customer
			               |
			               |ORDER BY
			               |	RoomInventory.Recorder.CheckOutDate");
			vQ.SetParameter("qGuest",vGuest);
			qReservations = vQ.Execute().Select();
			vReservationsArray = New Array;
			While qReservations.Next() Do
				vResStruct = New Structure("Status,CheckInDate,CheckOutDate,Room, RoomType, RoomRate,DiscountCard, GuestGroup, Number,AppURL");
				FillPropertyValues(vResStruct,qReservations);
				If ValueIsFilled(qReservations.AccommodationStatus) Then
					vResStruct.Status = qReservations.AccommodationStatus;
					If qReservations.AccommodationStatus.IsInHouse Then
						// Accommodation
						vClientData.Room 			= TrimAll(qReservations.Room);
						vClientData.CheckInDate 	= Date(qReservations.CheckInDate);
						vClientData.CheckOutDate 	= Date(qReservations.CheckOutDate);
						vClientData.GuestGroup 		= qReservations.GuestGroup;
						vClientData.Customer 		= cmRemoveComma(qReservations.Customer);
					EndIf;
				Else
					vResStruct.Status = qReservations.ReservationStatus;
				EndIf;
				If Not IsBlankString(pInteractionParameters.InfobaseURL) Then
					vResStruct.AppURL = TrimAll(pInteractionParameters.InfobaseURL)+"#"+GetURL(qReservations.Recorder);
				EndIf;

				vReservationsArray.Add(vResStruct);				
			EndDo;
			vClientData.Reservations = vReservationsArray;
		EndIf;	
		vClientsArray.Add(vClientData);
	EndDo;
		
	Return vClientsArray;
EndFunction // GetClientInfoByPhone

// --------------------------------------------------------------------------------
Function GetSurveyByID(pID)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Surveys.Ref AS Ref
		|FROM
		|	Catalog.Surveys AS Surveys
		|WHERE
		|	NOT Surveys.IsFolder
		|	AND NOT Surveys.DeletionMark
		|	AND Surveys.ExternalCode = &qID";
	
	vQuery.SetParameter("qID", pID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	For Each vRow In vQueryResult Do
		Return vRow.Ref;
	EndDo;
	
	Return Undefined;
EndFunction // GetSurveyByID

// --------------------------------------------------------------------------------
Function GetSurveysByHotel(pHotel, pID = Undefined)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Surveys.Ref AS Ref
		|FROM
		|	Catalog.Surveys AS Surveys
		|WHERE
		|	NOT Surveys.IsFolder
		|	AND NOT Surveys.DeletionMark
		|	AND (Surveys.Hotel = &qHotel
		|			OR Surveys.Hotel = &qEmptyHotel)
		|	AND Surveys.ExternalCode <> """"
		|	AND CASE
		|			WHEN &idFilled
		|				THEN Surveys.ExternalCode = &id
		|			ELSE TRUE
		|		END";
	
	vQuery.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("idFilled", ValueIsFilled(pID));
	vQuery.SetParameter("id", pID);
	
	vQueryResult = vQuery.Execute().Unload();
	
	Return vQueryResult;
EndFunction // GetSurveysByHotel

// --------------------------------------------------------------------------------
Function GetInteractionParametersByTokenAndSystem(pToken)
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
	vQuery.SetParameter("qInteractionID", pToken);
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
		Break;
	EndDo;
	
	Return vResult;
EndFunction // GetInteractionParametersByTokenAndSystem

// --------------------------------------------------------------------------------
Function GetDataProcessorsByTokenAndSystem(pKey)
	vResult = Undefined;
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	DataProcessors.Ref AS Ref
		|FROM
		|	Catalog.DataProcessors AS DataProcessors
		|WHERE
		|	DataProcessors.Key = &qKey
		|	AND NOT DataProcessors.IsFolder
		|	AND NOT DataProcessors.DeletionMark";
	vQuery.SetParameter("qKey", pKey);
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vResult = vSelectionDetailRecords.Ref; 
		Break;
	EndDo;
	
	Return vResult;
EndFunction // GetDataProcessorsByTokenAndSystem

// --------------------------------------------------------------------------------
Function GetAccommodationByRoom(pHotel, pRoom, pDateOfBirth = Undefined, pLastName = Undefined, pPhone = Undefined)
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	Accommodation.Ref AS Ref,
		|	Accommodation.GuestGroup AS GuestGroup,
		|	Accommodation.AccommodationStatus.IsInHouse AS IsInHouse
		|FROM
		|	Document.Accommodation AS Accommodation
		|WHERE
		|	NOT Accommodation.DeletionMark
		|	AND Accommodation.Room.Description LIKE &qRoom
		|	AND CASE
		|			WHEN &qLastNameFilled
		|				THEN Accommodation.Guest.LastName = &qLastName
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qDateOfBirthFilled
		|				THEN Accommodation.Guest.DateOfBirth = &qDateOfBirth
		|			ELSE TRUE
		|		END
		|	AND CASE
		|			WHEN &qPhoneFilled
		|				THEN Accommodation.Guest.Phone = &qPhone
		|			ELSE TRUE
		|		END
		|	AND Accommodation.Hotel = &qHotel
		|	AND Accommodation.Posted
		|	AND Accommodation.AccommodationStatus.IsActive
		|	AND Accommodation.AccommodationStatus.IsInHouse";
	
	vQuery.SetParameter("qDateOfBirth", 		pDateOfBirth);
	vQuery.SetParameter("qDateOfBirthFilled", 	ValueIsFilled(pDateOfBirth));
	vQuery.SetParameter("qHotel", 				pHotel);
	vQuery.SetParameter("qLastName", 			pLastName);
	vQuery.SetParameter("qLastNameFilled", 		ValueIsFilled(pLastName));
	vQuery.SetParameter("qPhone", 				pPhone);
	vQuery.SetParameter("qPhoneFilled", 		ValueIsFilled(pPhone));
	If Not IsBlankString(pPhone) Then
		pPhone = SMS.GetValidPhoneNumber(pPhone);
	EndIf;		
	vQuery.SetParameter("qRoom", pRoom);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		Return vSelectionDetailRecords; 
	EndDo;
	
	Return Undefined;
	
EndFunction // GetAccommodationByRoom

#EndRegion
