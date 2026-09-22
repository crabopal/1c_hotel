// --------------------------------------------------------------------------------------------------------------
// API for wwww.microsms.com.cy
// --------------------------------------------------------------------------------------------------------------

#Region Public

// --------------------------------------------------------------------------------------------------------------
Function SendSMS(pLogin, pPassword, pPhones, pMessage, pSender, pDeliveryDate = "") Export
	vErr = "";
	vStruct = New Structure("Success, MessageID, NumberOfSegments, Cost, Balance, Result, ErrorDescription, Messageid", False, "", 0, 0, 0, "", "", "");

	pSender = TrimAll(Constants.SMSSenderName.Get());

	// Get current balance before sending SMS
	vBalanceBefore = 0;
	If GetBalanceCommand(pLogin, pPassword, , vErr, vBalanceBefore) Then
		// Call API
		vMessageID = "";
		vParams = "mobnu="+SMS.URLEncode(pPhones) + 
		          "&Title="+SMS.URLEncode(pSender) + 
		          "&Message=" + SMS.URLEncode(StrReplace(pMessage, Chars.LF, "/n")) +
		          "&Batchid=" + "batch" + Format(CurrentSessionDate(), "DF=yyyyMMddHHmmss") +
		          "&Dtype=1";
		vRes = SendSMSCommand(pLogin, pPassword, vParams, vErr, vMessageID);
		If vRes Then
			// Get balance after sending SMS
			vBalanceAfter = 0;
			If GetBalanceCommand(pLogin, pPassword, , vErr, vBalanceAfter) Then
				// Fill resulting structure
				vStruct.Success = True;
				vStruct.MessageID = vMessageID;
				vStruct.NumberOfSegments = SMS.GetNumberOfSegments(pMessage);
				vStruct.Cost = ?(vBalanceBefore >= vBalanceAfter, vBalanceBefore - vBalanceAfter, 0);
				vStruct.Balance = vBalanceAfter;
				vStruct.Result = "OK";
			Else
				vStruct.Success = False;
				vStruct.ErrorDescription = vErr;
			EndIf;
		Else
			vStruct.Success = False;
			vStruct.ErrorDescription = vErr;
		EndIf;
	Else
		vStruct.Success = False;
		vStruct.ErrorDescription = vErr;
	EndIf;
	
    Return vStruct;	
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	vErr = "";
	vStatus = "";
	vStatusStruct = New Structure("Success, StatusChangeTime, Result, Status, ErrorDescription", False, '00010101', "", "", "");

	// Call API
	vParams = "msgid="+SMS.URLEncode(pMessageID);
	vRes = GetStatusCommand(pLogin, pPassword, vParams, vErr, vStatus);
	If vRes Then
		vStatusStruct.Success = True;
		vStatusStruct.Status = vStatus;
		vStatusStruct.StatusChangeTime = CurrentSessionDate();
	Else
		vStatusStruct.Success = False;
		vStatusStruct.Status = "Error";
	EndIf;
	
	Return vStatusStruct;	
EndFunction // GetStatus

// --------------------------------------------------------------------------------------------------------------
Function GetBalance(pLogin, pPassword, rErrorCode, rErrorDescription) Export
	vBalance = 0;
	rErrorCode = "";
	rErrorDescription = "";

	// Call API
	vRes = GetBalanceCommand(pLogin, pPassword, , rErrorDescription, vBalance);
	If Not vRes Then
		rErrorCode = "ERR";
	EndIf;
	
	Return vBalance;
EndFunction // GetBalance

#EndRegion

#Region Private

// --------------------------------------------------------------------------------------------------------------
Function HTTPGet(pAddr, pParams)
    vResult = New Structure("StatusCode, Body, Error, Raw");
    Try
		// HTTP connection
		vHTTPConnection = New HTTPConnection("sms.logisoft-cy.com");
		// HTTP request headers
		vHeaders = New Map();
		// GET request data
		vHTTPRequest = New HTTPRequest(pAddr + "?" + TrimAll(pParams), vHeaders);
		vRs = vHTTPConnection.Get(vHTTPRequest);
		
		vResult.StatusCode	= vRs.StatusCode;
		vResult.Body 		= TrimAll(vRs.GetBodyAsString());
	Except
        vResult.Error = ErrorDescription();
    EndTry;
    Return vResult;
EndFunction // HTTPGet

// --------------------------------------------------------------------------------------------------------------
Function SendSMSCommand(pLogin, pPassword, pArgs = "", rErr, rMessageID)
	rMessageID = "";
	vRes = Undefined;
	rErr = "";
    vAddr = "/sendapiinter.asp";
    vParams = "usr=" + TrimAll(SMS.URLEncode(pLogin)) + "&psw=" + TrimAll(SMS.URLEncode(pPassword)) + ?(Not IsBlankString(pArgs), "&" + TrimAll(pArgs), "");
       
    vRes = HTTPGet(vAddr, vParams);
	If vRes = Undefined Then
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams, "");
		Return false;
	EndIf;        
	
	If vRes.StatusCode = 200 Then
		If lower(Left(vRes.Body, 2)) = "ok" Then
			rMessageID = TrimAll(Mid(vRes.Body, 4));
			vSplitterPos = StrFind(rMessageID, "|");
			If vSplitterPos > 0 Then
				rMessageID = TrimAll(Mid(rMessageID, vSplitterPos + 1));
			EndIf;
			Return true;
		Else
			If lower(Left(vRes.Body, 5)) = "error" Then
				vErrorCode = TrimAll(Mid(vRes.Body, 7));
				If vErrorCode = "5" Then
					rErr = "Server Maintenance. Contact the administrator";
				ElsIf vErrorCode = "10" Then
					rErr = "Service not currently in use. Contact the administrator";
				ElsIf vErrorCode = "15" Then
					rErr = "Service Unavailable. Contact the administrator";
				ElsIf vErrorCode = "20" Then
					rErr = "Internal Server Error. Contact the administrator";
				ElsIf vErrorCode = "25" Then
					rErr = "Bad Request";
				ElsIf vErrorCode = "43" Then
					rErr = "Username failed";
				ElsIf vErrorCode = "32" Then
					rErr = "The username was disabled. Contact the administrator";
				ElsIf vErrorCode = "37" Then
					rErr = "Account must be activated";
				ElsIf vErrorCode = "39" Then
					rErr = "Not available balance";
				ElsIf vErrorCode = "49" Then
					rErr = "Not available balance";
				ElsIf vErrorCode = "12" Then
					rErr = "Login error";
				ElsIf vErrorCode = "47" Then
					rErr = "Incorrect Password";
				ElsIf vErrorCode = "48" Then
					rErr = "Generic Login fail";
				ElsIf vErrorCode = "50" Then
					rErr = "IP is Blocked. Contact the administrator";
				Else
					rErr = "Unknown error code received!";
				EndIf;
				WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams,"status="+vRes.StatusCode+", body="+vRes.Body+"; "+ rErr);
			Else
				rErr = vRes.Body;
				WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams,"status="+vRes.StatusCode+", body="+vRes.Body+";");
			EndIf;
			Return false;
		EndIf;
	Else
		rErr = vRes.Error;
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams,"status="+vRes.StatusCode+", body="+vRes.Body+"; "+ rErr);
		Return false;
	EndIf;
	Return True;    
EndFunction // SendSMSCommand

// --------------------------------------------------------------------------------------------------------------
Function GetStatusCommand(pLogin, pPassword, pArgs = "", rErr, rStatus)
	rStatus = "";
	vRes = Undefined;
	rErr = "";
    vAddr = "/getapilogsinter.asp";
    vParams = "usr=" + TrimAll(SMS.URLEncode(pLogin)) + "&psw=" + TrimAll(SMS.URLEncode(pPassword)) + ?(Not IsBlankString(pArgs), "&" + TrimAll(pArgs), "");
       
    vRes = HTTPGet(vAddr, vParams);
	If vRes = Undefined Then
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams, "");
		rErr = "Failed to send HTTP GET request!";
		Return false;
	EndIf;        
	
	If vRes.StatusCode = 200 Then
		If lower(Left(vRes.Body, 5)) = "error" Then
			vErrorCode = TrimAll(Mid(vRes.Body, 7));
			If vErrorCode = "12" Then
				rErr = "Login Error. Contact administrator";
			ElsIf vErrorCode = "32" Then
				rErr = "The username was disabled. Contact the administrator";
			ElsIf vErrorCode = "37" Then
				rErr = "Account must be activated";
			ElsIf vErrorCode = "43" Then
				rErr = "Username failed";
			ElsIf vErrorCode = "47" Then
				rErr = "Incorrect Password";
			ElsIf vErrorCode = "49" Then
				rErr = "Login Failed";
			ElsIf vErrorCode = "50" Then
				rErr = "IP is Blocked. Contact the administrator";
			Else
				rErr = "Unknown error code received! - " + vErrorCode;
			EndIf;
			Return false;
		Else
			If lower(Left(vRes.Body, 5)) = "<?xml" Then
				vStatusStartPos = StrFind(vRes.Body, "<status>");
				If vStatusStartPos > 0 Then
					vStatusEndPos = StrFind(vRes.Body, "</status>");
					If vStatusEndPos > vStatusStartPos Then
						rStatus = Mid(vRes.Body, vStatusStartPos + 8, vStatusEndPos - (vStatusStartPos + 8));
					EndIf;
				EndIf;
				If IsBlankString(rStatus) Then
					rStatus = "Unknown";
				EndIf;
				Return true;
			Else
				rErr = "Unknown data format received!" + Chars.LF + vRes.Body;
				Return false;
			EndIf;
		EndIf;
	Else
		rErr = vRes.Error;
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams,"status="+vRes.StatusCode+", body="+vRes.Body+"; "+ rErr);
		Return false;
	EndIf;
EndFunction // GetStatusCommand

// --------------------------------------------------------------------------------------------------------------
Function GetBalanceCommand(pLogin, pPassword, pArgs = "", rErr, rBalance)
	rBalance = 0;
	vRes = Undefined;
	rErr = "";
    vAddr = "/getapilogsinter.asp";
    vParams = "usr=" + TrimAll(SMS.URLEncode(pLogin)) + "&psw=" + TrimAll(SMS.URLEncode(pPassword)) + ?(Not IsBlankString(pArgs), "&" + TrimAll(pArgs), "");
       
    vRes = HTTPGet(vAddr, vParams);
	If vRes = Undefined Then
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams, "");
		rErr = "Failed to send HTTP GET request!";
		Return false;
	EndIf;        
	
	If vRes.StatusCode = 200 Then
		If lower(Left(vRes.Body, 5)) = "error" Then
			vErrorCode = TrimAll(Mid(vRes.Body, 7));
			If vErrorCode = "12" Then
				rErr = "Login Error. Contact administrator";
			ElsIf vErrorCode = "32" Then
				rErr = "The username was disabled. Contact the administrator";
			ElsIf vErrorCode = "37" Then
				rErr = "Account must be activated";
			ElsIf vErrorCode = "43" Then
				rErr = "Username failed";
			ElsIf vErrorCode = "47" Then
				rErr = "Incorrect Password";
			ElsIf vErrorCode = "49" Then
				rErr = "Login Failed";
			ElsIf vErrorCode = "50" Then
				rErr = "IP is Blocked. Contact the administrator";
			Else
				rErr = "Unknown error code received! - " + vErrorCode;
			EndIf;
		Else
			If lower(Left(vRes.Body, 5)) = "<?xml" Then
				vCreditsStartPos = StrFind(vRes.Body, "<credits>");
				If vCreditsStartPos > 0 Then
					vCreditsEndPos = StrFind(vRes.Body, "</credits>", , vCreditsStartPos + 9);
					If vCreditsEndPos > vCreditsStartPos Then
						vBalanceStr = Mid(vRes.Body, vCreditsStartPos + 9, vCreditsEndPos - (vCreditsStartPos + 9));
						vBalanceStr = StrReplace(vBalanceStr, ",", ".");
						vBalanceStr = StrReplace(vBalanceStr, " ", "");
						If cmIsNumber(vBalanceStr) Then
							rBalance = Number(vBalanceStr);
							Return true;
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			rErr = "No credits were received!";
		EndIf;
		Return false;
	Else
		rErr = vRes.Error;
		WriteLogEvent(NStr("en='sms.ErrorSendingRequest'; de='sms.ErrorSendingRequest'; ru='sms.ОшибкаЗапросаНаСервер'"), EventLogLevel.Error, , vAddr + "?" + vParams,"status="+vRes.StatusCode+", body="+vRes.Body+"; "+ rErr);
		Return false;
	EndIf;
EndFunction // GetBalanceCommand

#EndRegion
