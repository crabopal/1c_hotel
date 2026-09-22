// --------------------------------------------------------------------------------------------------------------
// API for smsc.ru
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
// Read data from SMSC
// --------------------------------------------------------------------------------------------------------------
Function HTTPGet(pAddr, pParams, rErr)
    vRes = "";
	rErr = "";
    Try
		// HTTP connection
		vProxy = cmGetInternetProxy(SessionParameters.CurrentWorkstation.InternetConnectionSettings, False, "sms.1chotel.ru");
		vHTTPCon = Undefined;
		If vProxy <> Undefined Then
			vHTTPCon = New HTTPConnection("smsc.ru", , , , vProxy);
		Else
			vHTTPCon = New HTTPConnection("smsc.ru");
		EndIf;
		// Write request parameters to the file and initialize response file name
		vResponseFileName = GetTempFileName("txt");
		// HTTP request headers
		vHeaders = New Map();
		vHeaders.Insert("Content-Type", "application/x-www-form-urlencoded");
		// GET request data
		vHTTPCon.Get(New HTTPRequest(TrimAll(pAddr) + "?" + TrimAll(pParams), vHeaders), vResponseFileName);
		vTxtResponse = New TextReader(vResponseFileName, "UTF-8");
		vRes = vTxtResponse.Read();
		// Delete temp files
		vTxtResponse.Close();
		vTxtResponse = Undefined;
		DeleteFiles(vResponseFileName);
    Except
        rErr = ErrorDescription();
        Return "";
    EndTry;
    Return vRes;
EndFunction // HTTPGet

// --------------------------------------------------------------------------------------------------------------
// Call SMSC API. Build URL and try 3 times to read data from server
// --------------------------------------------------------------------------------------------------------------
Function SendCommand(pLogin, pPassword, pCmd, pArgs = "", rErr)
	vRes = "";
	rErr = "";
    vAddr = "/sys/" + pCmd + ".php";
    vParams = "login=" + TrimAll(SMS.URLEncode(pLogin)) + "&psw=" + TrimAll(SMS.URLEncode(pPassword)) + "&fmt=1" + 
	          ?(Not IsBlankString(pArgs), "&" + TrimAll(pArgs), "");
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
       
        vRes = HTTPGet(vAddr, vParams, rErr);
        If Not IsBlankString(vRes) Then
            Break;
        EndIf;
    EndDo;   
	If IsBlankString(vRes) Then
		WriteLogEvent(NStr("en='SMSC.ErrorSendingRequest'; de='SMSC.ErrorSendingRequest'; ru='SMSC.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams, rErr);
        vRes = "," // Empty reply
    EndIf;                       
    Return SMS.Str2List(vRes);
EndFunction // SendCommand

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
	vMsgFormats = New Array(7);
	vMsgFormats[1] = "flash=1";
	vMsgFormats[2] = "push=1";
	vMsgFormats[3] = "hlr=1";
	vMsgFormats[4] = "bin=1";
	vMsgFormats[5] = "bin=2";
	vMessageFormat = 0;
	vExtraParams = "";
	// Call SMSC API
    vResList = SendCommand(pLogin, pPassword, 
	                            "send", "cost=3&phones=" + SMS.URLEncode(pPhones) + "&mes=" + SMS.URLEncode(pMessage) +
                                "&translit=0" + "&id=0" + ?(vMessageFormat > 0, "&" + vMsgFormats[vMessageFormat], "") +
	                            ?(IsBlankString(pSender), "", "&sender=" + SMS.URLEncode(pSender)) +
	                            ?(IsBlankString(pDeliveryDate), "", "&time=" + SMS.URLEncode(pDeliveryDate)) +
	                            ?(IsBlankString(vExtraParams), "", "&" + TrimAll(vExtraParams)), 
	                            vErr);
    // (id, cnt, cost, balance) или (id, -error)
	Try
		vRes = Number(vResList[1].Value);
	Except
		Raise NStr("en='Check your internet connection';ru='Проверьте подключение к интернету';de='Überprüfen Sie den Internetanschluss'");
	EndTry;
	If vRes > 0 Then
		vStruct.Success = True;
		vStruct.MessageID = vResList[0].Value;
		vStruct.NumberOfSegments = vRes;
		vStruct.Cost = Number(vResList[2].Value);
		vStruct.Balance = Number(vResList[3].Value);
		vStruct.Result = "OK";
	Else
		vStruct.Success = False;
		If vRes = -1 Then
			vStruct.Result = "InvalidParameters";
		ElsIf vRes = -2 Then
			vStruct.Result = "InvalidCredentials";
		ElsIf vRes = -3 Then
			vStruct.Result = "InvalidBalance";
		ElsIf vRes = -4 Then
			vStruct.Result = "UserBlocked";
		ElsIf vRes = -5 Then
			vStruct.Result = "InvalidDate";
		ElsIf vRes = -6 Then
			vStruct.Result = "MessageBlocked";
		ElsIf vRes = -7 Then
			vStruct.Result = "InvalidReceiverAddress";
		ElsIf vRes = -8 Then
			vStruct.Result = "UnDeliverable";
		ElsIf vRes = -9 Then
			vStruct.Result = "LimitOfAttemptsReached";
		EndIf;
		vStruct.ErrorDescription = ?(IsBlankString(vErr), SMS.ServerResponseDescription(vStruct.Result).Text, vErr);
    EndIf;
    Return vStruct;
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
// Check status of SMS being sent
//
// Parameters
// pMessageID - Message ID
// pPhone - phone number
//
// Returns structure:
// if success
// 	SMSStatus, StatusChangeTime, SMSErrorCode
// if error
// 	SMSErrorCode
// --------------------------------------------------------------------------------------------------------------
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	vErr = "";
	vStruct = New Structure("Success, StatusChangeTime, Result, Status, ErrorDescription", False, '00010101', "", "", "");
	
	// Call SMSC API
    vResList = SendCommand(pLogin, pPassword, "status", "phone=" + SMS.URLEncode(pPhone) + "&id=" + TrimAll(pMessageID), vErr);

    // (status, time, err) or (0, -error)
    vRes1 = Number(vResList[0].Value);
	vRes2 = 0;
	vRes2Str = vResList[1].Value;
	If ValueIsFilled(vRes2Str) Then
    	vRes2 = Number(vRes2Str);
    EndIf;
	If vRes2 >= 0 Then
		vStruct.Success = True;
		If vRes1 = -1 Or vRes1 = -3 Then
			vStruct.Status = "EnQueue";
		ElsIf vRes1 = 0 Then
			vStruct.Status = "EnRoute";
		ElsIf vRes1 = 1 Then
			vStruct.Status = "Delivered";
		ElsIf vRes1 = 2 Or vRes1 = 21 Then
			vStruct.Status = "Unknown";
		ElsIf vRes1 = 20 Then
			vStruct.Status = "UnDeliverable";
		ElsIf vRes1 = 22 Then
			vStruct.Status = "InvalidReceiverAddress";
		ElsIf vRes1 = 23 Then
			vStruct.Status = "MessageBlocked";
		ElsIf vRes1 = 24 Then
			vStruct.Status = "InvalidBalance";
		EndIf;
		vStruct.StatusChangeTime = SMS.Unix2Date(vRes2);
    Else
		vStruct.Success = False;
		If vRes2 = -1 Then
			vStruct.Status = "InvalidParameters";
		ElsIf vRes2 = -2 Then
			vStruct.Status = "InvalidCredentials";
		ElsIf vRes2 = -3 Then
			vStruct.Status = "MessageNotFound";
		ElsIf vRes2 = -4 Then
			vStruct.Status = "UserBlocked";
		ElsIf vRes2 = -9 Then
			vStruct.Status = "LimitOfAttemptsReached";
		Else
			vStruct.Status = "Error";
		EndIf;
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
	rErrorCode = "";
	rErrorDescription = "";
           
    vResList = SendCommand(pLogin, pPassword, "balance", , rErrorDescription);
	If Not IsBlankString(rErrorDescription) Then
		rErrorCode = "Exception";
		Return 0;
	EndIf;
	
	vRes1 = Number(vResList[0].Value);
    If vResList.Count() = 1 Then
        Return vRes1;
    Else
		vRes2 = Number(vResList[1].Value);
		If vRes2 = -1 Then
			rErrorCode = "InvalidParameters";
		ElsIf vRes2 = -2 Then
			rErrorCode = "InvalidCredentials";
		ElsIf vRes2 = -4 Then
			rErrorCode = "UserBlocked";
		ElsIf vRes2 = -9 Then
			rErrorCode = "LimitOfAttemptsReached";
		Else			
			rErrorCode = "Error";
		EndIf;
		rErrorDescription = SMS.ServerResponseDescription(rErrorCode).Text;
		Return 0;
    EndIf;
EndFunction // GetBalance