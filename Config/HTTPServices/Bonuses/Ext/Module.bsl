
#Region Public

// -----------------------------------------------------------------------------
Function GetBonusesAmount_POST(pRequest)
    WriteLogEvent("GetBonusesAmount_POST", EventLogLevel.Information, , , pRequest.GetBodyAsString());
    
    vResult = New Structure("Success, Errors, Amount, ResponseCode", False, New Array, 0, 200);
    
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("Token");
	vParamsArray.Add("Card");
    
    // Get request parameters
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vResult.ResponseCode = 400;
		vResult.Errors.Add(vRequestParams.Error); 
        WriteLogEvent("GetBonusesAmount_POST", EventLogLevel.Error, , , vRequestParams.Error);
    Else
        // Get external interaction
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);					
		
		If Not ValueIsFilled(vInteraction) Then
			vResult.ResponseCode = 403;
            vMsg = NStr("en = 'Interaction with given interaction ID is not found!'; de = 'Interaction with given interaction ID is not found!'; ru = 'Не удалось идентифицировать внешнюю систему по токену!'");
			vResult.Errors.Add(vMsg); 
        Else
            If vInteraction.DebugMode Then
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_POST", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , "JSON", 99999);
            EndIf;
            vCardID = vRequestParams.Card; 
            If StrLen(vCardID) < 36 Then
                // Get valid phone number
                vCardID 	= SMS.GetValidPhoneNumber(vCardID);
                vCardID 	= StrReplace(vCardID, "+", "");
            EndIf;
			If ValueIsFilled(vCardID) Then
				vCards = Catalogs.DiscountCards.GetActiveBonusesCards(vCardID);
                If vCards.Count() = 0 Then
                    vResult.ResponseCode = 403;
                    vMsg = Nstr("en = 'Failed to find card!'; ru = 'Карта не найдена!'");
                    vResult.Errors.Add(vMsg); 
                    If vInteraction.DebugMode Then
                        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_POST", Enums.ExternalSystemEventTypes.Error, "ID: " + vCardID , , vMsg);
                    EndIf;
                Else
                    vCard  = vCards[0].Ref;
                    vCardParam = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard);
                    vResult.Amount = vCardParam.BalanceAmount; 
                    vResult.Success	= True; 
                    If vInteraction.DebugMode Then
                        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_POST", Enums.ExternalSystemEventTypes.Info,  , , Nstr("en = 'Find card :'; ru = 'Карта найдена: '")+String(vCard));
                    EndIf;
                EndIf;
			Else
				vResult.ResponseCode = 400;
				vMsg = Nstr("en = 'Card id is empty!'; de = 'Card id is empty!'; ru = 'ID карты не может быть пустым.'"); 
                vResult.Errors.Add(vMsg); 
				vResult.Success	= False; 
                If vInteraction.DebugMode Then
                    InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_POST", Enums.ExternalSystemEventTypes.Error, , , vMsg);
                EndIf;
            EndIf;
        EndIf;
    EndIf;
    
    // Responce generate
    vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
    vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
    vResponse.SetBodyFromString(vRequestBody); 
    
    Return vResponse;
EndFunction // GetBonusesAmount_POST            

// -----------------------------------------------------------------------------
Function GetBonusesAmount_GET(pRequest)
    WriteLogEvent("GetBonusesAmount_GET", EventLogLevel.Information, , , pRequest.GetBodyAsString());
    
    vResult = New Structure("Success, Errors, Amount, ResponseCode", False, New Array, 0, 200);
    // Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("Token");
	vParamsArray.Add("Card");
    
    // Get request parameters
	vRequestParams = cmCheckRequestParameters("QueryOptions", vParamsArray, , pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vResult.ResponseCode = 400;
		vResult.Errors.Add(vRequestParams.Error); 
        WriteLogEvent("GetBonusesAmount_GET", EventLogLevel.Error, , , vRequestParams.Error);
    Else
        // Get external interaction
        vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);					
        
        If Not ValueIsFilled(vInteraction) Then
            vResult.ResponseCode = 403;
            vMsg = NStr("en = 'Interaction with given interaction ID is not found!'; de = 'Interaction with given interaction ID is not found!'; ru = 'Не удалось идентифицировать внешнюю систему по токену!'");
            vResult.Errors.Add(vMsg); 
        Else
            If vInteraction.DebugMode Then
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_GET", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , "JSON", 99999);
            EndIf;
             vCardID = vRequestParams.Card;
            If StrLen(vCardID) < 36 Then
                // Get valid phone number
                vCardID 	= SMS.GetValidPhoneNumber(vCardID);
                vCardID 	= StrReplace(vCardID, "+", "");
            EndIf;
            If ValueIsFilled(vCardID) Then
                vCards = Catalogs.DiscountCards.GetActiveBonusesCards(vCardID);
                If vCards.Count() = 0 Then
                    vResult.ResponseCode = 403;
                    vMsg = Nstr("en = 'Failed to find card!'; ru = 'Карта не найдена!'");
                    vResult.Errors.Add(vMsg); 
                    If vInteraction.DebugMode Then
                        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_GET", Enums.ExternalSystemEventTypes.Error, "ID: " + vCardID , , vMsg);
                    EndIf;
                Else
                    vCard  = vCards[0].Ref;
                    vCardParam = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCard);
                    vResult.Amount = vCardParam.BalanceAmount;
                    vResult.Success	= True; 
                    If vInteraction.DebugMode Then
                        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_GET", Enums.ExternalSystemEventTypes.Info,  , , Nstr("en = 'Find card :'; ru = 'Карта найдена: '")+String(vCard));
                    EndIf;
                EndIf;
            Else
                vResult.ResponseCode = 400;
                vMsg = Nstr("en = 'Card id is empty!'; de = 'Card id is empty!'; ru = 'ID карты не может быть пустым.'"); 
                vResult.Errors.Add(vMsg); 
                vResult.Success	= False; 
                If vInteraction.DebugMode Then
                    InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "GetBonusesAmount_GET", Enums.ExternalSystemEventTypes.Error, , , vMsg);
                EndIf;
            EndIf;
        EndIf;
    EndIf;

    // Responce generate
    vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
    vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
    vResponse.SetBodyFromString(vRequestBody); 
    
    Return vResponse;
EndFunction // GetBonusesAmount_GET

// -----------------------------------------------------------------------------
Function AddBonuses_POST(pRequest)
	vResponse 		= New HTTPServiceResponse(200); 	
	Return vResponse;
EndFunction // AddBonuses_POST

// -----------------------------------------------------------------------------
Function StartBonusesPayment_POST(pRequest)
    WriteLogEvent("StartBonusesPayment_POST", EventLogLevel.Information, , , pRequest.GetBodyAsString());
    
    vResult = New Structure("Success, Errors, CodeIsSent, TransactionID, ResponseCode", False, New Array, False, "", 400);
    
    // Initialize mandatory params
    vParamsArray = New Array;
    vParamsArray.Add("Token");
    vParamsArray.Add("Card");
    vParamsArray.Add("Amount");
    
    vNonMandatoryParamsArray = New Array;
    vNonMandatoryParamsArray.Add("Author");
    vNonMandatoryParamsArray.Add("Room");
    vNonMandatoryParamsArray.Add("GuestGroup");
    vNonMandatoryParamsArray.Add("Guest");
    vNonMandatoryParamsArray.Add("Remarks");
    
    // Get request parameters
    vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
    vInteraction = Undefined;
    If ValueIsFilled(vRequestParams.Error) Then
        vResult.ResponseCode = 400;
        vResult.Errors.Add(vRequestParams.Error); 
        WriteLogEvent("StartBonusesPayment_POST", EventLogLevel.Error, , , vRequestParams.Error);
    Else
        // Get external interaction
        vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);					
        
        If Not ValueIsFilled(vInteraction) Then
            vResult.ResponseCode = 403;
            vMsg = NStr("en = 'Interaction with given interaction ID is not found!'; de = 'Interaction with given interaction ID is not found!'; ru = 'Не удалось идентифицировать внешнюю систему по токену!'");
            vResult.Errors.Add(vMsg); 
        Else
            If vInteraction.DebugMode Then
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "StartBonusesPayment_POST", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , "Input_JSON", 99999);
            EndIf;
            Try
                vStartBonusesPaymentResult 	= StartBonusesPayment(vInteraction, vRequestParams.Card, vRequestParams.Amount, vRequestParams.Author, vRequestParams.Room, vRequestParams.GuestGroup, vRequestParams.Guest, vRequestParams.Remarks);
                vResult.CodeIsSent 		= vStartBonusesPaymentResult.CodeIsSent;
                vResult.Success         = vStartBonusesPaymentResult.Success;
                vResult.TransactionID   = vStartBonusesPaymentResult.TransactionID;
                If ValueIsFilled(vStartBonusesPaymentResult.Error) Then
                    vResult.Errors.Add(vStartBonusesPaymentResult.Error);	
                    vResult.ResponseCode = 300;
                Else
                    vResult.ResponseCode = 200;
                EndIf;
            Except
                vError 		= ErrorDescription();
                vResult.Errors.Add(vError);
                vResult.ResponseCode = 400;
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "StartBonusesPayment_POST", Enums.ExternalSystemEventTypes.Error, , Catalogs.DataConvertationRules.MapToJSON(vResult), "JSON", 99999);
            EndTry;
        EndIf;
    EndIf;    
    // Responce generate
    vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
    vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
    vResponse.SetBodyFromString(vRequestBody); 
    If Not vInteraction = Undefined And vInteraction.DebugMode Then
        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "StartBonusesPayment_POST", Enums.ExternalSystemEventTypes.Info, , vRequestBody, "End", 99999);
    EndIf;
    Return vResponse;
EndFunction // StartBonusesPayment_POST

// -----------------------------------------------------------------------------
Function FinishBonusesPayment_POST(pRequest)
    WriteLogEvent("FinishBonusesPayment_POST", EventLogLevel.Information, , , pRequest.GetBodyAsString());
    
    vResult = New Structure("Success, Errors, Amount, ResponseCode", False, New Array, False, "", 400);
    
    // Initialize mandatory params
    vParamsArray = New Array;
    vParamsArray.Add("Token");
    vParamsArray.Add("TransactionID");
    vParamsArray.Add("AuthorizationCode");
    
    // Get request parameters
    vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
    vInteraction = Undefined;
    
    If ValueIsFilled(vRequestParams.Error) Then
        vResult.ResponseCode = 400;
        vResult.Errors.Add(vRequestParams.Error); 
        WriteLogEvent("FinishBonusesPayment_POST", EventLogLevel.Error, , , vRequestParams.Error);
    Else
        // Get external interaction
        vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);					
        If Not ValueIsFilled(vInteraction) Then
            vResult.ResponseCode = 403;
            vMsg = NStr("en = 'Interaction with given interaction ID is not found!'; de = 'Interaction with given interaction ID is not found!'; ru = 'Не удалось идентифицировать внешнюю систему по токену!'");
            vResult.Errors.Add(vMsg); 
        Else
            If vInteraction.DebugMode Then
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "FinishBonusesPayment_POST", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , "Input_JSON", 99999);
            EndIf;
            Try
                vFinishBonusesPaymentResult = FinishBonusesPayment(vInteraction, vRequestParams.TransactionID, vRequestParams.AuthorizationCode);
                vResult.Success	= vFinishBonusesPaymentResult.Success;
                vResult.Amount	= AccumulationRegisters.Bonuses.mmGetBalanceByCard(vFinishBonusesPaymentResult.Card).BalanceAmount;
                If ValueIsFilled(vFinishBonusesPaymentResult.Error) Then
                    vResult.Errors.Add(vFinishBonusesPaymentResult.Error);	
                    vResult.ResponseCode = 300;
                Else
                    vResult.ResponseCode = 200; 
                EndIf;
            Except
                vError 		= ErrorDescription();
                vResult.Errors.Add(vError);
                vResult.ResponseCode = 500;
                InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "FinishBonusesPayment_POST", Enums.ExternalSystemEventTypes.Error, , Catalogs.DataConvertationRules.MapToJSON(vResult), "JSON", 99999);
            EndTry;
        EndIf;
    EndIf;    
    // Responce generate
    vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
    vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
    vResponse.SetBodyFromString(vRequestBody); 
    If Not vInteraction = Undefined And vInteraction.DebugMode Then
        InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "FinishBonusesPayment_POST", Enums.ExternalSystemEventTypes.Info, , vRequestBody, "End", 99999);
    EndIf;
    Return vResponse;    
EndFunction // FinishBonusesPayment_POST

// -----------------------------------------------------------------------------
Function RequestCode_POST(pRequest)
		
	vResult = New Structure("Success, CardsCount, CodeIsSent, ErrorDescription, ResponseCode, CodeLifeTimeLeft", False, 0, False, "", 200, 0);
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("Token");
	vParamsArray.Add("Card");
	
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("DateOfBirth");
	vNonMandatoryParamsArray.Add("DebugMode");
	
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vResult.ResponseCode 		= 400;
		vResult.ErrorDescription 	= vRequestParams.Error; 
	 	vResult.Success				= False;
	Else
		Try
			vDateOfBirth = Date(vRequestParams.DateOfBirth);
		Except
			vDateOfBirth = Undefined;
		EndTry;
		
		vExternalSystemInteractions = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);					
		
		If Not ValueIsFilled(vExternalSystemInteractions) Then
			vResult.ResponseCode 		= 403;
			vResult.ErrorDescription 	= "Не удалось идентифицировать внешнюю систему по токену."; 
			vResult.Success				= False; 
		Else
			
			vPhone 	= SMS.GetValidPhoneNumber(vRequestParams.Card);
			vPhone 	= StrReplace(vPhone, "+", "");
			
			If ValueIsFilled(vPhone) Then
				// 1. try to identify client with discount card number. the clients registered in discount cards have a priority
				vCards 		= Catalogs.DiscountCards.GetActiveDiscountCards(vPhone, vDateOfBirth);
				vClients	= Undefined;
				vClient 	= Undefined;
				vCard		= Undefined;
				
				If vCards = Undefined Or vCards.Count() = 0 Then
					// 2. in case no discount cards found try to find in general Clients or Customer Catalogs
					vClients = GetClientsByPhoneAndDateOfBirth(vPhone, vDateOfBirth);
					If vClients <> Undefined And vClients.Count() > 0 Then
						vClient = vClients[0].Ref;
					EndIf;
				ElsIf vCards.Count() = 1 Or (vCards.Count() > 1 And ValueIsFilled(vDateOfBirth)) Or ( Not vExternalSystemInteractions.UniqueProfilesControl) Then 
					vClient = vCards[0].Client;
					vCard	= vCards[0].Ref;
				EndIf;
				
				If vCards <> Undefined Then
					vResult.CardsCount 	= vCards.Count();
				EndIf;
				
				If vExternalSystemInteractions.UniqueProfilesControl And vResult.CardsCount > 1 And Not ValueIsFilled(vDateOfBirth) Then 
					vResult.Success 			= True;
					vResult.CodeIsSent			= False;
					vResult.ErrorDescription 	= "Требуется указать дату рождения.";
				Else
					vResult.Success 	= True;
					vLastSentCodeData	= InformationRegisters.ClientVerificationCodes.GetLastSentCodeAndDate(vPhone); 
					If vExternalSystemInteractions.SMSVerificationCodeLifeTime > 0 Then
						vCodeLifeTime = vExternalSystemInteractions.SMSVerificationCodeLifeTime;
					Else
						vCodeLifeTime = 2;
					EndIf;
										
					vCodeTime = CurrentSessionDate() - vLastSentCodeData.DateSent;
					If (vCodeTime / 60) >= vCodeLifeTime Then
						vAuthorizationCode	= InformationRegisters.ClientVerificationCodes.GenerateRandomCode();
						If vRequestParams.DebugMode = True Then
							vResult.CodeIsSent	= True;	
						Else
							vResult.CodeIsSent	= SMS.SendMessage("Код авторизации: " + vAuthorizationCode, vPhone, , , vClient, , , , vResult.ErrorDescription);
						EndIf;
						If vResult.CodeIsSent = True Then
							vRcdMgr = InformationRegisters.ClientVerificationCodes.CreateRecordManager();
							vRcdMgr.Phone 				= vPhone;
							vRcdMgr.VerificationCode 	= vAuthorizationCode;
							vRcdMgr.IsSent 				= True;
							vRcdMgr.DateSent 			= CurrentSessionDate();
							vRcdMgr.IsUsed 				= False;
							vRcdMgr.DateUsed 			= '00010101';
							If ValueIsFilled(vCard) Then
								vRcdMgr.Client = vCard
							Else
								vRcdMgr.Client = vClient;
							EndIf;
							vRcdMgr.Write(True);
						Else
							vResult.ResponseCode 	= 500;
							vResult.Success 		= False;	
						EndIf;
					Else
						vResult.Success 			= True;
						vResult.CodeIsSent 			= False;
						vResult.CodeLifeTimeLeft 	= (vCodeLifeTime * 60) - vCodeTime;
						vResult.ErrorDescription 	= "Повторно отправить код можно будет через: " + vResult.CodeLifeTimeLeft;
					EndIf;
				EndIf;
			Else
				vResult.ResponseCode 		= 400;
				vResult.ErrorDescription 	= "Телефон не может быть пустым."; 
				vResult.Success				= False; 	
			EndIf;
		EndIf;
	EndIf;
	
	vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
	vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
	vResponse.SetBodyFromString(vRequestBody); 
	
	Return vResponse;
	
EndFunction // RequestCode_POST

// -----------------------------------------------------------------------------
Function VerifyClient_POST(pRequest)
		
	vResult = New Structure("Success, ErrorDescription, ResponseCode", False, "", 200);
	
	// Initialize mandatory params
	vParamsArray = New Array;
	vParamsArray.Add("Token");
	vParamsArray.Add("Card");
	vParamsArray.Add("VerificationCode");
		
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, , pRequest);
	
	If ValueIsFilled(vRequestParams.Error) Then
		vResult.ResponseCode 		= 400;
		vResult.ErrorDescription 	= vRequestParams.Error; 
		vResult.Success				= False;
	Else
		vExternalSystemInteractions = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams.Token);
		If Not ValueIsFilled(vExternalSystemInteractions) Then
			vResult.ResponseCode 		= 403;
			vResult.ErrorDescription 	= NStr("en = 'The external system could not be identified by token.'; de = 'Das externe System konnte nicht per Token identifiziert werden.'; ru = 'Не удалось идентифицировать внешнюю систему по токену.'"); 
			vResult.Success				= False; 
		Else
			vPhone 						= SMS.GetValidPhoneNumber(vRequestParams.Card);
			vPhone 						= StrReplace(vPhone, "+", "");
			vVerifyResult 				= InformationRegisters.ClientVerificationCodes.VerifyCode(vExternalSystemInteractions, vPhone, vRequestParams.VerificationCode);
			vResult.Success 			= vVerifyResult.Success;
			vResult.ErrorDescription 	= vVerifyResult.ErrorDescription;
			InsertClientDataInResponse(vVerifyResult.Client, vResult, vExternalSystemInteractions);
		EndIf;
	EndIf;
	
	vResponse 		= New HTTPServiceResponse(vResult.ResponseCode); 
	vRequestBody	= Catalogs.DataConvertationRules.MapToJSON(vResult);
	vResponse.SetBodyFromString(vRequestBody); 
	
	Return vResponse;

EndFunction // VerifyClient_POST

// -----------------------------------------------------------------------------
Function IssueCardPOST(pRequest)
	vResponseCode = 200;
	vResponseBodyMap = New Map;
	vResponseBodyMap.Insert("ErrorDescription", "");
	vInteraction = Undefined;
	
	vParamsArray = New Array;
	vParamsArray.Add("Token");	
	vParamsArray.Add("CardType");
	vParamsArray.Add("CardID");	
	vParamsArray.Add("Amount");
	
	vNonMandatoryParamsArray = New Array;
	vNonMandatoryParamsArray.Add("Description");
	vNonMandatoryParamsArray.Add("ValidFrom");
	vNonMandatoryParamsArray.Add("ValidTo");
	vNonMandatoryParamsArray.Add("Remarks");
	vNonMandatoryParamsArray.Add("Source");
	vNonMandatoryParamsArray.Add("Customer");
	vNonMandatoryParamsArray.Add("Client");
	vNonMandatoryParamsArray.Add("Payment");
		
	// Read request body
	vRequestParams = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest, True);
	
	If Not ValueIsFilled(vRequestParams["Error"]) Then
		If Not IsBlankString(vRequestParams["Token"]) Then
			vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(vRequestParams["Token"]);
			If ValueIsFilled(vInteraction) Then
				If Not IsBlankString(vRequestParams["CardID"]) Then			
					vDiscountCard = cmGetDiscountCardById(vRequestParams["CardID"]);
					If Not ValueIsFilled(vDiscountCard) Then
						vCreditCardTypes = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "DiscountTypes", vRequestParams["CardType"]); 
						If ValueIsFilled(vCreditCardTypes) Then
							BeginTransaction(DataLockControlMode.Managed); 
							Try    
								vCustomer = Catalogs.Customers.EmptyRef();
								If vRequestParams["Customer"] <> Undefined And Not IsBlankString(vRequestParams["Customer"]) Then
									vCustomer = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "Customers", vRequestParams["Customer"]); 
								EndIf;
								vSource = Catalogs.SourcesOfBusiness.EmptyRef();
								If vRequestParams["Source"] <> Undefined And Not IsBlankString(vRequestParams["Source"]) Then
									vSource = cmGetObjectRefByExternalSystemCode(vInteraction.Hotel, vInteraction.InteractionID, "SourcesOfBusiness", vRequestParams["Source"]);
								EndIf;
								vDiscountCard = WriteDiscountCard(vInteraction.Hotel, vRequestParams["CardID"], vRequestParams["Description"], vCreditCardTypes, 
																  vRequestParams["ValidFrom"], vRequestParams["ValidTo"], vRequestParams["Client"], vCustomer, vSource, vRequestParams["Remarks"]);          							  
								WritePaymentByDiscountCard(vInteraction, vRequestParams["Amount"], vRequestParams["Payment"], vDiscountCard);
								vResponseBodyMap.Insert("UUID", vDiscountCard.UUID());
								vResponseBodyMap.Insert("CardNumber", TrimAll(vDiscountCard.Code));
								CommitTransaction();
							Except      
								If TransactionActive() Then
									RollbackTransaction();
								EndIf;
								vErrorInfo = ErrorInfo();
								vResponseBodyMap["ErrorDescription"] = BriefErrorDescription(vErrorInfo);
								vResponseCode = 400;
							EndTry;	
						Else
							vResponseBodyMap["ErrorDescription"] = NStr("en = 'Card type not found'; de = 'Kartentyp nicht gefunden'; ru = 'Тип карты не найден'");
							vResponseCode = 400;
						EndIf;	
					Else
						vResponseBodyMap["ErrorDescription"] = NStr("en = 'Card with ID provided already exist'; de = 'Karte mit bereitgestelltem Ausweis ist bereits vorhanden'; ru = 'Карта с таким ID уже существует'");
						vResponseCode = 400;
					EndIf;
				Else
					vResponseBodyMap["ErrorDescription"] = NStr("en = 'Card ID is empty'; de = 'Karten-ID ist leer'; ru = 'ID карты пустой'");
					vResponseCode = 400;
				EndIf;
			Else
				vResponseBodyMap["ErrorDescription"] = NStr("en = 'Access deny'; de = 'Zugriff verweigern'; ru = 'Доступ запрещен'");
				vResponseCode = 401;
			EndIf; 
		Else
			vResponseBodyMap["ErrorDescription"] = NStr("en = 'Access deny'; de = 'Zugriff verweigern'; ru = 'Доступ запрещен'");
			vResponseCode = 401;
		EndIf;
	Else
		vResponseBodyMap["ErrorDescription"] = vRequestParams["Error"];
		vResponseCode = 400;
	EndIf;
	
	vResponseBody = Catalogs.DataConvertationRules.MapToJSON(vResponseBodyMap);	
	If ValueIsFilled(vInteraction) And (vInteraction.DebugMode Or vResponseCode <> 200) Then
		If vResponseCode <> 200 Then 
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "IssueCard_POST", Enums.ExternalSystemEventTypes.Error, pRequest.GetBodyAsString(), vResponseBody, vResponseBodyMap["ErrorDescription"], 99999);		
		Else
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "IssueCard_POST", Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), vResponseBody, vResponseBodyMap["ErrorDescription"], 99999);
		EndIf;
	ElsIf vResponseCode <> 200 Then
		WriteLogEvent("IssueCard_POST", EventLogLevel.Error, , , vResponseBodyMap["ErrorDescription"]);
	EndIf;
	
	pResponse = New HTTPServiceResponse(vResponseCode);
	pResponse.SetBodyFromString(vResponseBody, TextEncoding.UTF8);
	Return pResponse;
EndFunction // IssueCardPOST

// -----------------------------------------------------------------------------
Function GetCreditCardByText(pText, pCardOwner, pCreateNew = False, pPaymentMethod = Undefined) Export
	// Check card owner
	If Not ValueIsFilled(pCardOwner) Then
		Return Catalogs.CreditCards.EmptyRef();
	EndIf;
	Try
		// Parse credit card data to fields
		vCardData = cmParseCreditCardData(pText);
		If pPaymentMethod <> Undefined Then
			If ValueIsFilled(pPaymentMethod.CardType) Then
				vCardData.CardType = pPaymentMethod.CardType;
			EndIf;
			If ValueIsFilled(pPaymentMethod.CardOwner) Then
				vCardData.CardOwner = pPaymentMethod.CardOwner;
			EndIf;
		EndIf;
		// Get card number
		vCardNumber = vCardData.CardNumber;
		// Search cards with given owner and number
		vQry = New Query();
		vQry.Text = 
		"SELECT
		|	CreditCards.Ref AS CreditCard
		|FROM
		|	Catalog.CreditCards AS CreditCards
		|WHERE
		|	CreditCards.CardOwner = &qCardOwner
		|	AND CreditCards.CardNumber = &qCardNumber
		|	AND CreditCards.DeletionMark = FALSE";
		vQry.SetParameter("qCardOwner", pCardOwner);
		vQry.SetParameter("qCardNumber", vCardNumber);
		vCards = vQry.Execute().Unload();
		If vCards.Count() > 0 Then
			// Return first found
			Return vCards.Get(0).CreditCard;
		Else
			// Create new card if necessary
			If pCreateNew Then
				If Not ValueIsFilled(vCardData.CardHolder) Or Not ValueIsFilled(vCardData.CardType) Then
					vCardObj = Catalogs.CreditCards.CreateItem();
					vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
					FillPropertyValues(vCardObj, vCardData);
					If Not ValueIsFilled(vCardObj.CardOwner) Then
						vCardObj.CardOwner = pCardOwner;
					EndIf;
					vCardObj.Author = SessionParameters.CurrentUser;
					vCardObj.CreateDate = CurrentSessionDate(); 
					vCardObj.Write();    
					Return vCardObj.Ref;
				Else
					vCardObj = Catalogs.CreditCards.CreateItem();
					vCardObj.Description = cmGetCreditCardDescription(vCardNumber);
					FillPropertyValues(vCardObj, vCardData);
					If Not ValueIsFilled(vCardObj.CardOwner) Then
						vCardObj.CardOwner = pCardOwner;
					EndIf;
					vCardObj.Author = SessionParameters.CurrentUser;
					vCardObj.CreateDate = CurrentSessionDate();
					vCardObj.Write();
					Return vCardObj.Ref;
				EndIf;
			Else
				Return Catalogs.CreditCards.EmptyRef();
			EndIf;
		EndIf;
	Except
		vErrInfo = ErrorInfo();
		WriteLogEvent(NStr("en='CreditCards.GetCreditCardByText';ru='КредитныеКарты.GetCreditCardByText';de='Kreditkarten.GetCreditCardByText'"), EventLogLevel.Warning, Metadata.Catalogs.CreditCards, , cmGetRootErrorDescription(vErrInfo));
		Return Catalogs.CreditCards.EmptyRef();
	EndTry;
EndFunction // GetCreditCardByText

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function GetClientsByPhoneAndDateOfBirth(pPhone, pDateOfBirth = Undefined)
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	Clients.Ref AS Ref,
		|	FALSE AS isCustomer,
		|	Clients.Code AS Code,
		|	Clients.DiscountType AS DiscountType,
		|	Clients.DiscountType.SortCode AS DiscountTypeSortCode
		|FROM
		|	Catalog.Clients AS Clients
		|WHERE
		|	NOT Clients.DeletionMark
		|	AND Clients.Phone = &qPhone
		|	AND CASE
		|			WHEN &qDateOfBirthFilled
		|				THEN Clients.DateOfBirth = &qDateOfBirth
		|			ELSE TRUE
		|		END
		|
		|UNION ALL
		|
		|SELECT
		|	Customers.Ref,
		|	TRUE,
		|	Customers.Code,
		|	Customers.DiscountType,
		|	Customers.DiscountType.SortCode
		|FROM
		|	Catalog.Customers AS Customers
		|WHERE
		|	NOT Customers.DeletionMark
		|	AND Customers.Phone = &qPhone
		|
		|ORDER BY
		|	DiscountTypeSortCode DESC,
		|	isCustomer,
		|	Code DESC";
	
	vQuery.SetParameter("qDateOfBirth", pDateOfBirth);
	vQuery.SetParameter("qDateOfBirthFilled", ValueIsFilled(pDateOfBirth));
	vQuery.SetParameter("qPhone", pPhone);
	
	vResult = vQuery.Execute().Unload();
	
	Return vResult;
EndFunction // GetClientsByPhoneAndDateOfBirth

// -----------------------------------------------------------------------------
Procedure InsertClientDataInResponse(pClient, rResult, pInteractionParams = Undefined)
	If rResult.Success Then
		rResult.ErrorDescription = "";
		
		If ValueIsFilled(pClient) Then
			vClient		= Undefined;
			vCardUUID 	= Undefined;
			If TypeOf(pClient) = Type("CatalogRef.DiscountCards") Then
				vCardUUID 	= TrimAll(pClient.UUID());
				vClient		= pClient.Client;
			EndIf;
			
			If vClient = Undefined Then
				vClient = pClient;	
			EndIf;
			
			rResult.Insert("CardUUID", vCardUUID);
			
			If TypeOf(vClient) = Type("CatalogRef.Customers") Then
				
				rResult.Insert("IsCustomer",	True);
				rResult.Insert("ProfileCode", 	TrimAll(vClient.Code));
				rResult.Insert("CustomerName",	vClient.Description);
				
			ElsIf TypeOf(vClient) = Type("CatalogRef.Clients")  Then
				
				rResult.Insert("IsCustomer", False);
				rResult.Insert("ProfileCode", 		TrimAll(vClient.Code));
				rResult.Insert("CustomerName",		vClient.FirstName + " " + vClient.SecondName);		
				rResult.Insert("ClientCode",		TrimAll(vClient.Code));
				rResult.Insert("ClientLastName",	vClient.LastName);
				rResult.Insert("ClientFirstName",	vClient.FirstName);
				rResult.Insert("ClientSecondName",	vClient.SecondName);
				rResult.Insert("ClientSex",			String(vClient.Sex));
				rResult.Insert("ClientCitizenship",	TrimAll(vClient.Citizenship.Description));
				rResult.Insert("ClientBirthDate",	Format(vClient.DateOfBirth, "DF=dd.MM.yyyy"));
				rResult.Insert("ClientPhone",		vClient.Phone);
				rResult.Insert("ClientEMail",		vClient.EMail);
				rResult.Insert("DiscountDescription", TrimAll(vClient.DiscountType));
				rResult.Insert("Discount",			?(ValueIsFilled(vClient.DiscountType), vClient.DiscountType.GetObject().pmGetDiscount(), 0));
				
			EndIf;
			
			If ValueIsFilled(vClient.DiscountType) Then
				rResult.Insert("RoomDiscount",		0);
				rResult.Insert("ServicesDiscount",	0);
			EndIf;
			
			rResult.Insert("ClientType", TrimAll(vClient.ClientType.Description));
			
		EndIf;
	EndIf;
EndProcedure // InsertClientDataInResponse

// -----------------------------------------------------------------------------
Function StartBonusesPayment(pInteraction, pCardIdentifier, pAmount, pAuthor, pRoom, pGuestGroup, pGuest, pRemarks)
	vResult = New Structure("Success, CodeIsSent, TransactionID, Error", True, False, "", "");
	
    If Number(pAmount) <= 0 Then
		vResult.Success = False;
		vResult.Error 	= Nstr("en = 'The payment amount can not be 0 or less!'; de = 'Der Zahlungsbetrag darf nicht 0 oder weniger sein!'; ru = 'Сумма платежа не может быть 0 или меньше!'");
		Return vResult;
	EndIf;
	Try
        vCardParams	= GetCardByIdentifier(pInteraction, pCardIdentifier);
        vCard = vCardParams.Card;
		If Not ValueIsFilled(vCard) Then
			vResult.Success = False;
			vResult.Error 	= Nstr("en = 'Failed to find card!'; de = 'Karte konnte nicht gefunden werden!'; ru = 'Карта не найдена!'");
			Return vResult;	
		EndIf;
        vBonusesAmount = AccumulationRegisters.Bonuses.mmGetBalanceByCard(vCardParams.Card, CurrentSessionDate()).BalanceAmount;
		If vBonusesAmount >= Number(pAmount) Then 
			vNewDocObj = Documents.BonusesPayment.CreateDocument();
			vNewDocObj.Fill(vCard);
			vNewDocObj.Author = pAuthor;
			vNewDocObj.OperationType = Enums.BonusesPaymentTypes.Expense;
			vNewDocObj.Source = pInteraction.Description;
			vNewDocObj.BonusesAmount = Number(pAmount);
			vNewDocObj.BonusesQuantity = Round(vNewDocObj.BonusesAmount*vNewDocObj.BonusRate, 2);
			vNewDocObj.Room = pRoom;
			vNewDocObj.GuestGroup = pGuestGroup;
			vNewDocObj.Guest = pGuest;
			vNewDocObj.Remarks = pRemarks;
			vNewDocObj.AuthorizationCode = GenerateRandomCode(4);
			If vCardParams.isUUID Then
				vNewDocObj.Status = "completed";
				vNewDocObj.Write(DocumentWriteMode.Posting);
				vResult.TransactionID = String(vNewDocObj.Ref.UUID());
				// Sent code
				vResult.Success = True;
				vResult.CodeIsSent = False;
				vResult.Error = "";	
			Else
				vNewDocObj.Status = "waiting for authorization";
				vNewDocObj.Write(DocumentWriteMode.Write);
				vResult.TransactionID = String(vNewDocObj.Ref.UUID());
				// Sent code
				vError = "";
                vPhone = "";
				If ValueIsFilled(vCard.Client) Then
					vPhone = TrimAll(vCard.Client.Phone); 
				EndIf;
				vResult.Success	= SMS.SendMessage(NStr("en='Payment authorization code '; ru='Код авторизации платежа '; de='Zahlungsautorisierungscode '")+vNewDocObj.AuthorizationCode, vPhone, vError, vCardParams.Hotel);
				vResult.CodeIsSent = vResult.Success;
				vResult.Error = vError;	
			EndIf;
		Else
			vResult.Success = False;
			vResult.Error = Nstr("en = 'Card balance is not enough for this operation!'; de = 'Das Kartenguthaben reicht für diesen Vorgang nicht aus!'; ru = 'Баланс карты меньше суммы операции!'");
		EndIf;
	Except
		vResult.Success = False;
		vError = ErrorDescription();
		vResult.Error = vError;
	EndTry;
	
	Return vResult;
EndFunction // StartBonusesPayment

// -----------------------------------------------------------------------------
Function FinishBonusesPayment(pInteraction, pTransactionID, pAuthorizationCode)
    vResult 	= New Structure("Success, Error, Card", True, "", Catalogs.DiscountCards.EmptyRef());
    Try
    	Try
    		vBonusesPaymentRef = Documents.BonusesPayment.GetRef(New UUID(pTransactionID));
    	Except
    	EndTry;
    	If Not ValueIsFilled(vBonusesPaymentRef) Or vBonusesPaymentRef.IsEmpty() Then
    		vResult.Success = False;
    		vResult.Error 	= Nstr("en = 'Failed to find Bonuses payment document!'; de = 'Boni-Zahlung-Dokument konnte nicht gefunden werden!'; ru = 'Документ ""Платеж/пополнение бонусами"" не найден""'");
    		Return vResult;		
    	EndIf;
    	vHotel = pInteraction.Hotel;
    	If Not ValueIsFilled(vHotel) Then
    		vResult.Success = False;
    		vResult.Error 	= "Failed to find hotel!";
    		Return vResult;	
    	EndIf;
    	If vBonusesPaymentRef.Hotel = vHotel Then
    		If vBonusesPaymentRef.Status = "waiting for authorization" Then
				If vBonusesPaymentRef.AuthorizationCode = pAuthorizationCode Then
					vExtSystemCode = pInteraction.InteractionID;
					If ValueIsFilled(vBonusesPaymentRef.GuestGroup) Then
						vExternalPaymentData = New Structure("LoyaltyCardID", vBonusesPaymentRef.Card.Identifier);
						vRes =  cmWriteExternalPayment("", vBonusesPaymentRef.GuestGroup.Code, vBonusesPaymentRef.Guest.Code, 
														vBonusesPaymentRef.Guest.FullName, "", "", vBonusesPaymentRef.Guest.FullName, 
														pInteraction.BonusesPaymentMethod.Code, vBonusesPaymentRef.BonusesAmount, vHotel.FolioCurrency.Code, "", vHotel.Code, vExtSystemCode, 
														"", "", "", "", 
														, "", "", "XDTO", vExternalPaymentData);
						If IsBlankString(vRes.ErrorDescription) Then
							vResult.Card = vBonusesPaymentRef.Card;
						Else 
							vResult.Success = False;
							vResult.Error 	= vRes.ErrorDescription;
						EndIf;	  
					Else	
						vBonusesPaymentDocObj 					= vBonusesPaymentRef.GetObject();
						vBonusesPaymentDocObj.Status 			= "completed";
						vBonusesPaymentDocObj.Write(DocumentWriteMode.Posting);
						
						vResult.Card = vBonusesPaymentDocObj.Card;
					EndIf;
    			Else
    				vResult.Success = False;
    				vResult.Error 	= Nstr("en = 'Wrong authorization code!'; de = 'Falscher Autorisierungscode!'; ru = 'Неверный код авторизации!''");
    				Return vResult;	
    			EndIf;
    		Else
    			vResult.Success = False;
    			vResult.Error 	= Nstr("en = 'Transaction already completed or canceled!'; de = 'Transaktion bereits abgeschlossen oder abgebrochen!'; ru = 'Транзакция уже завершена или отменена!'");
    			Return vResult;	
    		EndIf;
    	Else
    		vResult.Success = False;
    		vResult.Error 	= Nstr("en = 'Hotel in the document is not equal to the hotel received by the token!'; de = 'Das Hotel im Dokument entspricht nicht dem Hotel, das der Token erhalten hat!'; ru = 'Отель в документе не равен отелю, полученному по токену!'");
    		Return vResult;	
    	EndIf;
    Except
    	vResult.Success = False;
    	vError 			= ErrorDescription();
    	vResult.Error 	= vError;
    EndTry;
    
    Return vResult;
EndFunction // FinishBonusesPayment
 
// -----------------------------------------------------------------------------
Function GetCardByIdentifier(pInteraction, pCardIdentifier)
	vResult = New Structure("Hotel, Card, isUUID", Catalogs.Hotels.EmptyRef(), Catalogs.DiscountCards.EmptyRef(), False);
	
	vHotel = pInteraction.Hotel;
	vResult.Hotel = vHotel;
	
	If Not ValueIsFilled(vHotel) Then
		Return vResult;
	EndIf;
    If StrLen(pCardIdentifier) > 30 Then
        // Try to get card from UUID
        Try
            vCard = Catalogs.DiscountCards.GetRef(New UUID(pCardIdentifier));
            If ValueIsFilled(vCard) And Not vCard.GetObject() = Undefined Then
                vResult.Card = vCard;
                vResult.isUUID = True;
                Return vResult;
            Endif;	
        Except
        EndTry;
    Else
        // Get valid phone number
        pCardIdentifier = SMS.GetValidPhoneNumber(pCardIdentifier);
        pCardIdentifier = StrReplace(pCardIdentifier, "+", "");
    EndIf;
   	vCards = Catalogs.DiscountCards.GetActiveBonusesCards(pCardIdentifier);
    For each vRow in vCards Do
        vResult.Card = vRow.Ref;
        Break;
    EndDo;
	Return vResult;
EndFunction // GetCardByIdentifier

// -----------------------------------------------------------------------------
Function GenerateRandomCode(pCharacters = 4)
	vResult = "";
	vRandom = new RandomNumberGenerator();
	i = 0;
	While i < pCharacters Do
		vResult = vResult + String(vRandom.RandomNumber(0, 9)); 
		i = i + 1;
	EndDo;
	Return String(vResult);
EndFunction // GenerateRandomCode

// -----------------------------------------------------------------------------
Function WriteDiscountCard(pHotel, pCardID, pDescription, pDicountType, pValidFrom, pValidTo, pClient, pCustomer, pSource, pRemarks)
	vDCObj = Catalogs.DiscountCards.CreateItem();
	vDCObj.CreateHotel = pHotel; 
	vDCObj.Identifier = TrimAll(pCardID); 
	If pDescription <> Undefined And Not IsBlankString(pDescription) Then
		vDCObj.Description = TrimAll(pDescription);
	Else
		vDCObj.Description = TrimAll(vDCObj.Identifier);	
	EndIf;
	vDCObj.DiscountType = pDicountType;
	vDCObj.LoyaltyType = vDCObj.DiscountType.LoyaltyType;
	If ValueIsFilled(pValidFrom) Then
		vDCObj.ValidFrom = XMLValue(Type("Date"), pValidFrom);
	EndIf;
	vValidTo = Undefined;
	If ValueIsFilled(pValidTo) Then
		vValidTo = BegOfDay(XMLValue(Type("Date"), pValidTo));
	EndIf;
	If ValueIsFilled(vValidTo) Then
		vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
		If vValidTo > vDCObj.ValidFrom Then
			vDCObj.ValidTo = vValidTo;
		EndIf;
	ElsIf vDCObj.DiscountType.Validity > 0 Then
		vDCObj.ValidFrom = BegOfDay(CurrentSessionDate());
		vDCObj.ValidTo = vDCObj.ValidFrom + vDCObj.DiscountType.Validity * 86400;
	Else
		vDCObj.ValidFrom = '00010101';
		vDCObj.ValidTo = '00010101';
	EndIf;
	If pClient <> Undefined Then
		vCode = ?(pClient["Code"] <> Undefined, pClient["Code"], "");
		vLastName = ?(pClient["LastName"] <> Undefined, pClient["LastName"], "");
		vFirstName = ?(pClient["FirstName"] <> Undefined, pClient["FirstName"], "");
		vSecondName = ?(pClient["SecondName"] <> Undefined, pClient["SecondName"], ""); 
		vPhone = ?(pClient["Phone"] <> Undefined, pClient["Phone"], "");
		vEmail = ?(pClient["Email"] <> Undefined, pClient["Email"], "");
		If Not IsBlankString(vCode) Then
			vDCObj.Client = cmGetClientByCode(vCode);	
		EndIf;
		If Not ValueIsFilled(vDCObj.Client) And Not IsBlankString(vLastName) And Not IsBlankString(vFirstName) Then
			If Not IsBlankString(vPhone) Then
				vDCObj.Client = cmGetClientByFullnameAndPhone(vLastName, vFirstName, vSecondName, vPhone);	
			EndIf;
			If Not ValueIsFilled(vDCObj.Client) And Not IsBlankString(vEmail) Then
				vDCObj.Client = cmGetClientByFullnameAndEmail(vLastName, vFirstName, vSecondName, vEmail);	
			EndIf;  
			If Not ValueIsFilled(vDCObj.Client) Then
				vClient = Catalogs.Clients.CreateItem();
				vClient.LastName = vLastName;
				vClient.FirstName = vFirstName;
				vClient.SecondName = vSecondName;
				vClient.Phone = vPhone;
				vClient.EMail = vEmail;
				vClient.Write();
				vDCObj.Client = vClient.Ref; 
			EndIf;
		EndIf;
	EndIf;	 
	vDCObj.Customer = pCustomer;
	vDCObj.Source = pSource;
	vDCObj.Remarks = ?(pRemarks <> Undefined, TrimAll(pRemarks), "");
	vDCObj.Folio = Catalogs.DiscountCards.CreateFolio(TrimAll(vDCObj.Identifier), vDCObj.LoyaltyType, vDCObj.Client, vDCObj.Customer);
	vDCObj.Write();
	Return vDCObj.Ref;
EndFunction // WriteDiscountCard 

// -----------------------------------------------------------------------------
Procedure WritePaymentByDiscountCard(pInteraction, pAmount, pPayment, pDiscountCard)
	If pPayment <> Undefined Then 
		vMessage = "";
		If pPayment["Amount"] = Undefined Or pPayment["Amount"] <= 0 Then 
			vMessage = vMessage + NStr("en = 'Amount less than or equal to zero'; de = 'Betrag kleiner oder gleich Null'; ru = 'Сумма меньше или равна нулю'") + Chars.LF;	
		EndIf;     
		vCurrency = cmGetObjectRefByExternalSystemCode(pInteraction.Hotel, pInteraction.InteractionID, "Currencies", pPayment["Currency"]);	
		If Not ValueIsFilled(vCurrency) Then
			vMessage = vMessage + NStr("en = 'Payment currency not found'; de = 'Zahlungswährung nicht gefunden'; ru = 'Не найдена валюта платежа'") + Chars.LF;	
		EndIf;
		vPaymentMethod = cmGetObjectRefByExternalSystemCode(pInteraction.Hotel, pInteraction.InteractionID, "PaymentMethods", pPayment["PaymentMethod"]);
		If Not ValueIsFilled(vPaymentMethod) Then
			vMessage = vMessage + NStr("en = 'Payment method not found'; de = 'Zahlungsmethode nicht gefunden'; ru = 'Способ оплаты не найдена'") + Chars.LF;	
		EndIf;  
		If pPayment["PaymentID"] = Undefined Or IsBlankString(pPayment["PaymentID"]) Then
			vMessage = vMessage + NStr("en = 'Unique payment code not specified'; de = 'Eindeutiger Zahlungscode nicht angegeben'; ru = 'Не указан уникальный код платежа'") + Chars.LF;	
		EndIf;
		If Not IsBlankString(vMessage) Then
			Raise vMessage;	
		EndIf; 
		vPaymentRef = cmGetPaymentByExternalSystemCode(pInteraction.Hotel, pPayment["PaymentID"]);
		If ValueIsFilled(vPaymentRef) Then
			vPayment = vPaymentRef.GetObject();	
		Else
			vPayment = Documents.Payment.CreateDocument();
			vPayment.pmFillAttributesWithDefaultValues();
		EndIf;        
		vPayment.Fill(pDiscountCard.Folio);
		vPayment.Sum = pPayment["Amount"];
		vPayment.PaymentCurrency = vCurrency;
		vPayment.PaymentMethod = vPaymentMethod;
		vPayment.DiscountCard = pDiscountCard;
		vPayment.ExternalCode = pPayment["PaymentID"];
		vPayment.MerchantID = pPayment["MerchantID"];         	
		vPayment.ReferenceNumber = pPayment["ReferenceNumber"];
		vPayment.OrderNumber = pPayment["OrderNumber"];
		vPayment.AuthorizationCode = pPayment["AuthCode"];
		If pPayment["PaymentDate"] <> Undefined Then 
			vPaymentDate = XMLValue(Type("Date"), pPayment["PaymentDate"]); 
			If ValueIsFilled(vPaymentDate) Then
				vPayment.Date = vPaymentDate;
			EndIf;
		EndIf;
		vPayment.CreditCard = GetCreditCardByText(pPayment["CardDescription"], pDiscountCard.Client, True, vPaymentMethod);
		vPayment.Write(DocumentWriteMode.Posting);
	ElsIf cmCheckUserPermissions("HavePermissionToAddManualBonusesOperation") Then
		If pAmount <= 0 Then
			Raise NStr("en = 'Amount less than or equal to zero'; de = 'Betrag kleiner oder gleich Null'; ru = 'Сумма меньше или равна нулю'");	
		EndIf;
		vBonusesOperation = Documents.BonusesOperation.CreateDocument();
		vBonusesOperation.Fill(pDiscountCard);                          
		vBonusesOperation.BonusesQuantity = pAmount; 
		vBonusesOperation.Write(DocumentWriteMode.Posting);
	Else
		Raise NStr("en = 'No payment data to activate the card'; de = 'Keine Zahlungsdaten zur Aktivierung der Karte'; ru = 'Нет информации о платеже для активации карты'");	
	EndIf;
EndProcedure // WritePaymentByDiscountCard

#EndRegion
