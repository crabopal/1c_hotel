// --------------------------------------------------------------------------------------------------------------
// API for aramba.ru
// --------------------------------------------------------------------------------------------------------------

#Region Public

 // --------------------------------------------------------------------------------------------------------------
// Send SMS function
//
// Params:
//
// pPhones - phones list as comma separated string
// pMessage - SMS message text
//
// Extra params:
//
// pUseTranslit - translit message or not (1 or 0)
// pDeliveryDate - time for SMS to be delivered (DDMMYYhhmm, h1-h2, 0ts, +m)
// pMessageID - message identifier. SMS gateway will set it if not specified
// pMessageFormat - SMS message format (0 - plain-sms, 1 - flash-sms, 2 - wap-push, 3 - hlr, 4 - bin, 5 - bin-hex, 6 - ping-sms)
// pSender - sender name (Sender ID)
// pExtraParams - extra parameters string ("valid=01:00&maxsms=3&tz=2")
//
// Returns list of (<id>, <number of sms segments>, <cost>, <balance>) in case of successfull send
// or list of (<id>, -<error code>) in case of error
// --------------------------------------------------------------------------------------------------------------
Function SendSMS(pLogin, pPassword, pPhones, pMessage, pSender, pDeliveryDate = "") Export
	vErr = "";
	vStruct = New Structure("Success, MessageID, NumberOfSegments, Cost, Balance, Result, ErrorDescription", False, "", 0, 0, 0, "", "");
	vHTTPRes = New Map;
	
	vParam = New Structure;
	vParam.Insert("SenderId", pSender);
	vParam.Insert("SendDateTime", Null);
	vParam.Insert("UseRecepientTimeZone", False);
	vParam.Insert("PhoneNumber", pPhones);
	vParam.Insert("Text", pMessage);
	
	vJson = Catalogs.DataConvertationRules.MapToJSON(vParam);
	// Call SMSAramba API  
    vResString = SendCommand(vJson, pPassword, "/singleSms", vHTTPRes, True, vErr);
	Try
		vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
	Except
		Raise NStr("en='Check your internet connection';ru='Проверьте подключение к интернету';de='Überprüfen Sie den Internetanschluss'");
	EndTry; 
	// Processing the request results
	If vHTTPRes.StatusCode = 200 OR vHTTPRes.StatusCode = 201 Then
		vStruct.Success = True;
		vStruct.MessageID = vResStruct.Id;
		vStruct.NumberOfSegments = Undefined;
		vStruct.Cost = vResStruct.Cost;
		vStruct.Balance = Undefined;
		vStruct.Result = "OK";
	Else
		vStruct.Success = False;
		If vHTTPRes.StatusCode = 400 Then
			vStruct.Result = "InvalidParameters";
		ElsIf vHTTPRes.StatusCode = 401 Then
			vStruct.Result = "InvalidCredentials";
		ElsIf vHTTPRes.StatusCode = 402 Then
			vStruct.Result = "InvalidBalance";
		ElsIf vHTTPRes.StatusCode = 403 Then
			vStruct.Result = "Forbidden";
		ElsIf vHTTPRes.StatusCode = 404 Then
			vStruct.Result = "InvalidDate";
		ElsIf vHTTPRes.StatusCode = 500 Then
			vStruct.Result = "DatabaseOffline";
		EndIf;
		vStruct.ErrorDescription = ?(IsBlankString(vErr), SMS.ServerResponseDescription(vStruct.Result).Text, vErr);
	EndIf;
    Return vStruct;
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
//  Check status of SMS being sent
//
// Parameters:
//  pLogin		 - 	 - 
//  pPassword	 - 	 - 
//  pMessageID	 - 	 - Message ID
//  pPhone		 - 	 - phone number
// 
// Returns:
//  Structure - Params
//
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	vErr = "";
	vHTTPRes = New Map;
	vStruct = New Structure("Success, StatusChangeTime, Result, Status, ErrorDescription", False, '00010101', "", "", "");
	
	// Call SMSAramba API
    vResString = SendCommand(pMessageID, pPassword, "/singleSms/", vHTTPRes, False, vErr);
	vResStruct = Catalogs.DataConvertationRules.JSONtoStructure(vResString);
	// Processing the request results
	If (vHTTPRes.StatusCode = 200 OR vHTTPRes.StatusCode = 201) AND TypeOf(vResStruct) = Type("Structure") Then
		vStruct.Success = True;
		If vResStruct.Status = "Enroute" Then
			vStruct.Status = "EnRoute";
		ElsIf vResStruct.Status = "Delivered" Then
			vStruct.Status = "Delivered";
		ElsIf vResStruct.Status = "Undeliverable" Then
			vStruct.Status = "UnDeliverable";
		EndIf;
		vStruct.StatusChangeTime = CurrentDate();
	Else
		vStruct.Success = False;
		If vHTTPRes.StatusCode = 400 Then
			vStruct.Result = "InvalidParameters";
		ElsIf vHTTPRes.StatusCode = 401 Then
			vStruct.Result = "InvalidCredentials";
		ElsIf vHTTPRes.StatusCode = 402 Then
			vStruct.Result = "InvalidBalance";
		ElsIf vHTTPRes.StatusCode = 403 Then
			vStruct.Result = "Forbidden";
		ElsIf vHTTPRes.StatusCode = 404 Then
			vStruct.Result = "InvalidDate";
		ElsIf vHTTPRes.StatusCode = 500 Then
			vStruct.Result = "DatabaseOffline";
		EndIf;
		vStruct.Status = "Error";
		vStruct.ErrorDescription = ?(IsBlankString(vErr), SMS.ServerResponseDescription(vStruct.Status).Text, vErr);
	EndIf;
		
	Return vStruct;
EndFunction // GetStatus

// --------------------------------------------------------------------------------------------------------------
// Returns clients balance
//
// Returns balance as number or 0 if error
// --------------------------------------------------------------------------------------------------------------
Function GetBalance(pLogin, pPassword, rErrorCode, rErrorDescription) Export
	vHTTPRes = New Map;
	rErrorCode = "";
	rErrorDescription = "";
	
    // Call SMSAramba API       
    vRes = SendCommand(Undefined, pPassword, "/balance", vHTTPRes, False, rErrorDescription);
	If Not IsBlankString(rErrorDescription) Then
		rErrorCode = "Exception";
		Return 0;
	EndIf;
	// Processing the request results 
	If vHTTPRes.StatusCode = 200 AND (Not IsBlankString(vRes)) Then
        Return Number(vRes);
	Else
		If vHTTPRes.StatusCode = 400 Then
			rErrorCode = "InvalidParameters";
		ElsIf vHTTPRes.StatusCode = 401 Then
			rErrorCode = "InvalidCredentials";
		ElsIf vHTTPRes.StatusCode = 402 Then
			rErrorCode = "InvalidBalance";
		ElsIf vHTTPRes.StatusCode = 403 Then
			rErrorCode = "Forbidden";
		ElsIf vHTTPRes.StatusCode = 404 Then
			rErrorCode = "InvalidDate";
		ElsIf vHTTPRes.StatusCode = 500 Then
			rErrorCode = "DatabaseOffline";
		EndIf;
		rErrorDescription = SMS.ServerResponseDescription(rErrorCode).Text;
		Return 0;
    EndIf;
EndFunction // GetBalance

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------------------
// Read data from SMSAramba
// --------------------------------------------------------------------------------------------------------------
Function HTTPQuery(pData, pPassword, pType, pHTTPRes, pIsPOSTRequest, rErr)
    vRes = ""; 
	rErr = "";
    Try
		// HTTP connection
		vProxy = cmGetInternetProxy(SessionParameters.CurrentWorkstation.InternetConnectionSettings, False, "sms.1chotel.ru");
		vHTTPCon = Undefined;
		If vProxy <> Undefined Then
			vHTTPCon = New HTTPConnection("api.aramba.ru", , , , vProxy, ,New OpenSSLSecureConnection(Undefined, Undefined));
		Else
			vHTTPCon = New HTTPConnection("api.aramba.ru",,,,,, New OpenSSLSecureConnection(Undefined, Undefined));
		EndIf;
		// HTTP request headers   
		vHeaders = New Map();
		vHeaders.Insert("Accept", "application/json");
		vHeaders.Insert("Content-Type", "application/json");
		vHeaders.Insert("Authorization", "ApiKey " + pPassword);	
        // Select type of HTTP request
		If pIsPOSTRequest Then
			vHTTPRequest = New HTTPRequest(pType, vHeaders);
			vHTTPRequest.SetBodyFromString(pData);
			pHTTPRes = vHTTPCon.Post(vHTTPRequest);
		Else
			vHTTPRequest = New HTTPRequest(pType + pData, vHeaders);
			pHTTPRes = vHTTPCon.Get(vHTTPRequest);
		EndIf;
		vRes = pHTTPRes.GetBodyAsString();	
    Except
        rErr = ErrorDescription();
        Return "";
    EndTry;
    Return vRes;
EndFunction // HTTPPost

// --------------------------------------------------------------------------------------------------------------
// Call SMSAramba API. Build URL and try 3 times to read data from server
// --------------------------------------------------------------------------------------------------------------
Function SendCommand(pData, pPassword, pType, pHTTPRes, pIsPOSTRequest, rErr)
	vRes = "";
	rErr = "";
	// Try 3 times   
    For i = 1 To 3 Do
		If i > 1 Then
			// Wait a bit
			vCurrentTime = CurrentSessionDate();
			vTargetTime = CurrentSessionDate() + 1;
			While vCurrentTime <= vTargetTime Do
				vCurrentTime = CurrentSessionDate();
			EndDo;
		EndIf;
		vRes = HTTPQuery(pData, pPassword, pType, pHTTPRes, pIsPOSTRequest, rErr);  
        If Not IsBlankString(vRes) Then
            Break;
        EndIf;
    EndDo;   
	If IsBlankString(vRes) Then
		WriteLogEvent(NStr("en='SMSC.ErrorSendingRequest'; de='SMSC.ErrorSendingRequest'; ru='SMSC.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , "api.aramba.ru" + pType, rErr);
        vRes = "," // Empty reply
    EndIf;                       
    Return vRes;
EndFunction // SendCommand
	
#EndRegion
