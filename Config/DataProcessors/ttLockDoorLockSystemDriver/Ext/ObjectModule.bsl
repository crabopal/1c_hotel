
#Region Public

// -----------------------------------------------------------------------------
//
// Parameters:
//  pParameter	 - Structure	 - ataprocessor parameter
//
Procedure pmLoadDataProcessorAttributes(pParameter = Undefined) Export
	cmLoadDataProcessorAttributes(ThisObject, pParameter);
EndProcedure // LoadDataProcessorAttributes

// -----------------------------------------------------------------------------
//
Procedure pmSaveDataProcessorAttributes() Export
	cmSaveDataProcessorAttributes(ThisObject);
EndProcedure // SaveDataProcessorAttributes

// -----------------------------------------------------------------------------
//  Initialize attributes with default values
//  Attention: This procedure could be called AFTER some attributes initialization
//  routine, so it SHOULD NOT reset attributes being set before
//
Procedure pmFillAttributesWithDefaultValues() Export
	
EndProcedure // FillAttributesWithDefaultValues

// -----------------------------------------------------------------------------
//
// Parameters:
//  pDate	 - Date	 - Date 
//  pMessage - String	 - Return message 
// 
// Returns:
//  Boolean - result
//
Function CheckAuth_AccessToken(pDate, pMessage) Export
	vHeader = New Map;
	vHeader.Insert("Content-Type", "application/x-www-form-urlencoded");
	
	vData = "client_id=" + TrimAll(ExternalInteraction.OAuth_ClientID);
	vData = vData + "&client_secret=" + TrimAll(ExternalInteraction.OAuth_ClientSecret);
	
	If ValueIsFilled(ExternalInteraction.OAuth_RefreshToken) Then
		vData = vData + "&grant_type=refresh_token";
		vData = vData + "&refresh_token=" + TrimAll(ExternalInteraction.OAuth_RefreshToken);
	Else
		vData = vData + "&username=" + TrimAll(ExternalInteraction.Login);
		
		vDataHashing = New DataHashing(HashFunction.MD5);
		vDataHashing.Append(ExternalInteraction.Password);
		
		vData = vData + "&password=" + Lower(StrReplace(vDataHashing.HashSum, " ", ""));
	EndIf;
	
	pResponse = SendQuery(vData, "/oauth2/token", vHeader, "POST", pMessage);
	
	If TypeOf(pResponse) = Type("Structure") Then
		If pResponse.Success Then
			vIntParObj						= ExternalInteraction.GetObject();
			vIntParObj.SessionStartTime		= pDate;
			vIntParObj.SessionTimeout		= pResponse.expires_in;
			vIntParObj.OAuth_AccessToken	= pResponse.access_token; 
			vIntParObj.OAuth_RefreshToken	= pResponse.refresh_token;
			vIntParObj.Write();
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction // CheckAuth_AccessToken

// --------------------------------------------------------------------------------
//
// Parameters:
//  pMessage - String	 - Message
// 
// Returns:
//  String - Result
//
Function GetHotelInfo(pMessage) Export
	vHeader = New Map;
	vHeader.Insert("Content-Type", "application/x-www-form-urlencoded");
	
	vInitialTimestamp = '19700101';
	vMilliseconds = 1000;
	
	vData = "clientId=" + TrimAll(ExternalInteraction.OAuth_ClientID);
	vData = vData + "&clientSecret=" + TrimAll(ExternalInteraction.OAuth_ClientSecret);
	vData = vData + "&date=" + Format((ToUniversalTime(CurrentSessionDate()) - vInitialTimestamp) * vMilliseconds, "NFD=0; NG=");
	
	vResponse = SendQuery("", "/v3/hotel/getInfo?" + vData, vHeader, "GET", pMessage);
	
	If TypeOf(vResponse) <> Type("Structure") Or Not vResponse.Success Then
		Return "";
	EndIf;
	
	Return vResponse["hotelInfo"];
EndFunction // GetHotelInfo

// -----------------------------------------------------------------------------
//
// Parameters:
//  pResponse	 - HttpResponce	 - Http responce
//  pMessage	 - String		 - Return message
// 
// Returns:
//  Boolean - result
//
Function pmNewKey(pResponse, pMessage) Export
	IdentificationCard = Catalogs.IdentificationCards.EmptyRef();
	
	vDate = CurrentSessionDate();
	
	If ExternalInteraction.SessionStartTime + ExternalInteraction.SessionTimeout <= vDate Then
		If Not CheckAuth_AccessToken(vDate, pMessage) Then
			Return False;
		EndIf;
	EndIf;
	
	vData = "clientId=" + TrimAll(ExternalInteraction.OAuth_ClientID);
	vData = vData + "&accessToken=" + TrimAll(ExternalInteraction.OAuth_AccessToken);
	
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		pMessage = NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'");
		Return False;
	EndIf;
	vData = vData + "&lockId=" + vRoomCode;
	
	vData = vData + "&keyboardPwdType=3";
	vData = vData + "&keyboardPwdName=test";
	
	vCheckInDate = CheckInDate;
	If DoorLockSystemParameters.SubtractMinutes <> 0 Then
		vCheckInDate = vCheckInDate - DoorLockSystemParameters.SubtractMinutes*60;
	EndIf;
	vData = vData + "&startDate=" + Format((ToUniversalTime(vCheckInDate) - '19700101') * 1000, "NFD=0; NG=");
	
	vCheckOutDate = CheckOutDate;
	If DoorLockSystemParameters.AddMinutes <> 0 Then
		vCheckOutDate = vCheckOutDate + DoorLockSystemParameters.AddMinutes*60;
	EndIf;
	vData = vData + "&endDate=" + Format((ToUniversalTime(vCheckOutDate) - '19700101') * 1000, "NFD=0; NG=");
	
	vData = vData + "&date=" + Format((ToUniversalTime(vDate) - '19700101') * 1000, "NFD=0; NG=");
	
	pResponse = SendQuery(vData, "/v3/keyboardPwd/get" + "?" + vData, New Map, "GET", pMessage);
	
	If TypeOf(pResponse) = Type("Structure") Then
		If pResponse.Success Then
			IdentificationCard = cmGetClientIdentificationCard(pResponse.keyboardPwd, Undefined, ParentDoc, Folio, Guest, Room, CheckInDate, CheckOutDate, false, pResponse.keyboardPwdId);
			cmWriteKeyCardSecuritySystemEvent("NEW", "", Room, vData, vCheckInDate, vCheckOutDate, ParentDoc, Guest);
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction // NewKey

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage - String	 - Message
// 
// Returns:
//  Array - Card data
//
Function pmVerify(pMessage) Export
	vResult = New Array;
	
	vDate = CurrentSessionDate();
	
	If ExternalInteraction.SessionStartTime + ExternalInteraction.SessionTimeout <= vDate Then
		If Not CheckAuth_AccessToken(vDate, pMessage) Then
			Return vResult;
		EndIf;
	EndIf;
	
	vHeader = New Map;
	
	vType = "/v3/lock/listKeyboardPwd?";
	
	vType = vType + "clientId=" + TrimAll(ExternalInteraction.OAuth_ClientID);
	vType = vType + "&accessToken=" + TrimAll(ExternalInteraction.OAuth_AccessToken);
	
	vRoomCode = TrimR(Room);
	If ValueIsFilled(Room) Then
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) And ValueIsFilled(DoorLockSystemParameters.DefaultRoom) Then
		Room = DoorLockSystemParameters.DefaultRoom;
		vRoomCode = TrimR(Room);
		If DoorLockSystemParameters.UseRoomLockCodes Then
			If Not IsBlankString(Room.LockCode) Then
				vRoomCode = TrimR(Room.LockCode);
			Else
				vRoomCode = "";
			EndIf;
		EndIf;
	EndIf;
	If IsBlankString(vRoomCode) Then
		pMessage = NStr("en='Room has no key card door lock!';ru='В номере нет электронного замка!';de='Im Zimmer ist kein elektronisches Schloss vorhanden!'");
		Return vResult;
	EndIf;
	vType = vType + "&lockId=" + vRoomCode;
	vType = vType + "&pageSize=10";
	vType = vType + "&date=" + Format((ToUniversalTime(vDate) - '19700101') * 1000, "NFD=0; NG=");   
	
	vResponse = SendQuery("", vType + "&pageNo=1", New Map, "GET", pMessage);
	
	If TypeOf(vResponse) = Type("Structure") Then
		If vResponse.Success Then
			For Each vRow In vResponse.list Do
				vResult.Add(vRow);
			EndDo; 
		Else
			Return vResult;
		EndIf;
	Else
		Return vResult;
	EndIf;
	
	vPageSize = vResponse.pageSize;
	
	For i = 2 To vPageSize Do
		vResponse = SendQuery("", vType + "&pageNo=" + Format(i, "NFD=0; NG="), New Map, "GET", pMessage);
		If TypeOf(vResponse) = Type("Structure") Then
			If vResponse.Success Then
				For Each vRow In vResponse.list Do
					vResult.Add(vRow);
				EndDo; 
			Else
				Return vResult;
			EndIf;
		Else  
			Return vResult;
		EndIf;
	EndDo;
	
	Return vResult;
EndFunction //  pmVerify

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
Function SendQuery(pJSON, pType, pHeader, pMethod = "POST", pMessage)
	vHTTPServer = "api.ttlock.com";
	If ValueIsFilled(ExternalInteraction.HttpServer) Then
		vHTTPServer = StrReplace(StrReplace(ExternalInteraction.HttpServer, "https://", ""), "http://", "");
		If Right(TrimAll(vHTTPServer), 1) = "/" Then
			vHTTPServer = Left(vHTTPServer, StrLen(vHTTPServer) - 1);
		EndIf;
	EndIf;
	Try
		// HTTP
		vSSLSecure = Undefined;
		If ExternalInteraction.HttpUseSsl Then
			vSSLSecure = New OpenSSLSecureConnection(Undefined, Undefined);
		EndIf;
		
		// HTTP connection
		vHTTPConnection = New HTTPConnection(vHTTPServer,,,,, 15, vSSLSecure);
		
		// Send query
		vHTTPRequest = New HTTPRequest(TrimAll(pType), pHeader);
		If ValueIsFilled(pJSON) Then
			vHTTPRequest.SetBodyFromString(pJSON, TextEncoding.UTF8);
		EndIf;
		
		vRS = vHTTPConnection.CallHTTPMethod(pMethod, vHTTPRequest);
		
		vRSString = vRS.GetBodyAsString(TextEncoding.UTF8);
		If ExternalInteraction.DebugMode Then
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Info, pJSON, vRSString,, ExternalInteraction.MaxLogLenght);
		EndIf;
		
		vResponse = Catalogs.DataConvertationRules.JSONtoStructure(vRSString);
		
		vResponse.Insert("Success", False);
		
		If vRS.StatusCode = 200 Then
			If Not vResponse.Property("errcode") Or vResponse.errcode = 0 Then
				vResponse.Success = True;
			Endif;
		EndIf;
		
		If vResponse.Property("errmsg") Then
			pMessage = vResponse.errmsg;
			InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType, Enums.ExternalSystemEventTypes.Error, pJSON, vRSString,, ExternalInteraction.MaxLogLenght);
		EndIf;
		Return vResponse;
	Except
		vError = ErrorInfo();
		InformationRegisters.ExternalSystemIntegrationLogs.WriteLog(ExternalInteraction, pType+".SendQuery", Enums.ExternalSystemEventTypes.Error, pJSON,"","Failed to send post query! " + DetailErrorDescription(vError), ExternalInteraction.MaxLogLenght);
		pMessage = BriefErrorDescription(vError); 
		Return pMessage;
	EndTry;
EndFunction //  SendQuery

#EndRegion
