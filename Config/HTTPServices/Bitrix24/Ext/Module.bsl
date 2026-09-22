#Region EventHandlers 

// -----------------------------------------------------------------------------
Function auth(pRequest)
	Response = New HTTPServiceResponse(200);
	Response.SetBodyFromString("OK");
	Return Response;
EndFunction // Auth

// -----------------------------------------------------------------------------
Function DealBooking(pRequest)
	vResponseParam = GetEmptyResponceStructure();
	Try
		// Initialize params
		vParamsArray = New Array; 
		vParamsArray.Add("token");
		vParamsArray.Add("checkindate");
		vParamsArray.Add("checkoutdate");

		vNonMandatoryParamsArray = New Array;
		vNonMandatoryParamsArray.Add("dealid");
		vNonMandatoryParamsArray.Add("hotel");
		vNonMandatoryParamsArray.Add("adults");
		vNonMandatoryParamsArray.Add("kids1");
		vNonMandatoryParamsArray.Add("kids2");
		vNonMandatoryParamsArray.Add("kids3");
		vNonMandatoryParamsArray.Add("client");

		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			vResponseParam.ErrorDescription = vInputParameters.Error;
			Return GetResponce(vResponseParam);
		EndIf;
		// Check filling
		If Not CheckFilling(vParamsArray, vInputParameters, vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Convert date
		vInputParameters.CheckInDate = ReadJSONDate(vInputParameters.checkindate, JSONDateFormat.ISO);
		vInputParameters.CheckOutDate = ReadJSONDate(vInputParameters.checkoutdate, JSONDateFormat.ISO);
		// Get Hotel
		vHotel = Undefined;
		If ValueIsFilled(vInputParameters.Hotel) Then
			vHotel = cmGetHotelByCode(vInputParameters.Hotel, vInputParameters.token);	
		EndIf;	
		// Get interaction  
		vInteraction = GetInteraction(vInputParameters.token, vHotel, vResponseParam.ErrorDescription);
		If Not IsBlankString(vResponseParam.ErrorDescription) Then
			Return GetResponce(vResponseParam);
		EndIf;
		// Log  
		vDebugMode = False;
		If ValueIsFilled(vInteraction) Then
			vDebugMode = vInteraction.DebugMode; 
			If ValueIsFilled(vInteraction.Hotel) And vInteraction.Hotel <> vHotel Then
				vHotel = vInteraction.Hotel;
			EndIf;	
		EndIf;
		vInputParameters.Insert("Interaction", vInteraction);
		If vDebugMode Then
			vMsg = NStr("en='Start of processing';ru='Начало выполнения';de='Anfang der Ausführung'");
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DealBooking.Start",
				Enums.ExternalSystemEventTypes.Info, pRequest.GetBodyAsString(), , vMsg);
		EndIf;
        If Not ValueIsFilled(vHotel) Then
			vResponseParam.ErrorDescription = NStr("en = 'Couldn''t find hotel'; de = 'Hotel konnte nicht gefunden werden'; ru = 'Не удалось определить гостиницу'");	
			Return GetResponce(vResponseParam, vInteraction, "DealBooking.Error");
		EndIf;      
		vInputParameters.Hotel = vHotel;
		// Get client
		vGuest = GetClient(vInputParameters, vInteraction); 
		vInputParameters.Insert("Guest", vGuest);
		// Get guest group
		vGuestGroup = GetGuestGoup(vInputParameters, vInteraction);
		vInputParameters.Insert("GuestGroup", vGuestGroup);
		// Create external ref
		vResponseParam.ExternaBookinglRef = CreateExternalBookingRef(vInputParameters, vInteraction);
		vResponseParam.Success = True;
	Except
		vErr = ErrorInfo();
		WriteLogEvent("DealBooking.Error", EventLogLevel.Error, , , DetailErrorDescription(vErr));

		vResponseParam.ErrorDescription = BriefErrorDescription(vErr);
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(vInteraction, "DealBooking.Error",
			Enums.ExternalSystemEventTypes.Error, , DetailErrorDescription(vErr), "Error");
	EndTry;
	Return GetResponce(vResponseParam, vInteraction, "DealBooking.Finish");
EndFunction // DealBooking 

#EndRegion     

#Region Private

// -----------------------------------------------------------------------------
Function CheckFilling(pCheckParams, pSource, pErr = "")
	vCheck = True;
	vMsg = NStr("en = 'Parameter %1 is empty';de = 'Parameter %1 fehlt';ru = 'Параметр %1 не заполнен'");
	For Each vId In pCheckParams Do
		If Not ValueIsFilled(pSource[vId]) Then
			pErr = pErr + Chars.LF + StrTemplate(vMsg, vId);
			vCheck = False;
		EndIf;
	EndDo;
	Return vCheck;
EndFunction

// -----------------------------------------------------------------------------
Function GetEmptyResponceStructure()
	vResponseParam = New Structure;
	vResponseParam.Insert("ErrorDescription", "");
	vResponseParam.Insert("Success", False);
	vResponseParam.Insert("ExternaBookinglRef", "");
	Return vResponseParam;
EndFunction

// -----------------------------------------------------------------------------
Function GetResponce(pParams, pInteraction = Undefined, pRequestDescription = "Bitrix24")
    // Check result
	If pParams.Success Then
		vResponse = New HTTPServiceResponse(200);
		vEventType = Enums.ExternalSystemEventTypes.Info;
	Else
		vResponse = New HTTPServiceResponse(400);
		vEventType = Enums.ExternalSystemEventTypes.Error;
	EndIf;
    // Generate json
	vJson = Catalogs.DataConvertationRules.MapToJSON(pParams);
    // Log
	If Not pInteraction = Undefined And pInteraction.DebugMode Then
		vMsg = NStr("en = 'Response'; de = 'Antwort'; ru = 'Ответ'");
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(pInteraction, pRequestDescription, vEventType, ,
			vJson, vMsg, 999999999);
	EndIf;
	vResponse.Headers.Insert("Content-type", "application/JSON; charset=utf-8");	
    // Set response
	vResponse.SetBodyFromString(vJson);
	Return vResponse;
EndFunction //  ErrorResponce()

// -----------------------------------------------------------------------------
Function GetInteraction(pToken, pHotel = Undefined, pMsg = "")
	vInteraction =  Undefined;
	If pToken = Undefined Or IsBlankString(pToken) Then
		pMsg = NStr("en = 'Token not set'; de = 'Token festgelegt'; ru = 'Не указан token'");
	Else
		vInteraction = Catalogs.ExternalSystemInteractions.GetExternalSystemInteractionsByInteractionID(pToken, pHotel);
		If Not ValueIsFilled(vInteraction) Then
			pMsg = NStr("en='Interaction with given token is not found!'; 
			|de='Interaction with given token is not found!'; 
			|ru='В справочнике внешних взаимодействий не существует взаимодействия с переданным token!'");
		EndIf;
	EndIf;
	Return vInteraction;
EndFunction //  GetInteraction()

// -----------------------------------------------------------------------------
Function GetGuestGoup(pInputParameters, pInteraction)  
	vGuestGroup = Catalogs.GuestGroups.EmptyRef();
	If ValueIsFilled(pInputParameters.dealid) Then
		// Try find guwst group by deal id
		vGuestGroupMaps = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteraction, "deals", ,,,,Format(pInputParameters.dealid, "NG="));
		If vGuestGroupMaps.Count() > 0 Then
			vGuestGroup = vGuestGroupMaps[0].RefKey1; 
		Else
			// Not found, add
			vGuestGroup = AddGuestGroup(pInputParameters); 
			InformationRegisters.ExternalSystemIntegrationData.WriteData(pInteraction, "deals", "updatePeriod", vGuestGroup, Undefined, CurrentSessionDate(), Format(pInputParameters.dealid, "NG="));
		EndIf; 
	Else
		// Not found, add
		vGuestGroup = AddGuestGroup(pInputParameters);
	EndIf;  
	
	Return vGuestGroup;
EndFunction	// GetGuestGoup()

// -----------------------------------------------------------------------------
Function GetClient(pInputParameters, pInteraction)     
	vClient = Catalogs.Clients.EmptyRef();  
	vInputClientParam = pInputParameters.client; 
	If TypeOf(vInputClientParam) = Type("Structure") Then
		If ValueIsFilled(vInputClientParam.clientid) Then
			// Try find client by id
			vClientMaps = InformationRegisters.ExternalSystemIntegrationData.GetData(pInteraction, "clients", ,,,,Format(vInputClientParam.clientid, "NG="));
			If vClientMaps.Count() > 0 Then
				vClient = vClientMaps[0].RefKey1;  
			EndIf; 
			If Not ValueIsFilled(vClient) And ValueIsFilled(vInputClientParam.firstname) Then 
				vClient = AddClient(vInputClientParam);
 
				InformationRegisters.ExternalSystemIntegrationData.WriteData(pInteraction, "clients", "updatePeriod", vClient, Undefined, CurrentSessionDate(), Format(vInputClientParam.clientid, "NG="));
			EndIf;	
		Else
			If ValueIsFilled(vInputClientParam.firstname) Then
				vClient = AddClient(vInputClientParam);	
			EndIf;	
		EndIf;      
	EndIf;	
	Return vClient;
EndFunction

// -----------------------------------------------------------------------------
Function AddClient(Val pClientParams)  
	// Create new client
	vClientObj = Catalogs.Clients.CreateItem();
	vClientObj.FirstName = TrimAll(pClientParams.firstname);
	vClientObj.SecondName = TrimAll(pClientParams.secondname);
	vClientObj.LastName = TrimAll(pClientParams.lastname);
	vClientObj.Phone = TrimAll(pClientParams.phone);
	vClientObj.EMail = TrimAll(pClientParams.email);
	vClientObj.Remarks = TrimAll(pClientParams.remarks);  
	vClientObj.Write(); 
	vClientObj.pmWriteToClientChangeHistory(CurrentSessionDate(), SessionParameters.CurrentUser);   
	Return vClientObj.Ref;
EndFunction // AddClient()

// -----------------------------------------------------------------------------
Function AddGuestGroup(Val pParams)
	// Create new guest group
	vGuestGroupObj = Catalogs.GuestGroups.CreateItem();
	vGuestGroupObj.Owner = pParams.Hotel;  
	vGuestGroupObj.Client = pParams.Guest;
	vGuestGroupFolder = pParams.Hotel.GetObject().pmGetGuestGroupFolder();
	If ValueIsFilled(vGuestGroupFolder) Then
		vGuestGroupObj.Parent = vGuestGroupFolder;
		vGuestGroupObj.SetNewCode();
	EndIf;
	If ValueIsFilled(vGuestGroupObj.Owner) Then
		vGuestGroupObj.OneCustomerPerGuestGroup = vGuestGroupObj.Owner.OneCustomerPerGuestGroup;
	EndIf;
	vGuestGroupObj.Write();
	// Fill reference
	vGuestGroup = vGuestGroupObj.Ref;
	Return vGuestGroup.Ref;
EndFunction // AddGuestGroup()

// -----------------------------------------------------------------------------
Function CreateExternalBookingRef(pInputParameters, pInteraction)
	
	vExtRef = pInteraction.WSHost + "#" + GetURL(Metadata.DataProcessors.CRMDealBooking, "DealBooking", pInputParameters);  
	Return vExtRef;
	
EndFunction // CreateExternalBookingRef() 

#EndRegion