// --------------------------------------------------------------------------------------------------------------
// API for www.smsdelivery.ru
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function SendSMS(pLogin, pPassword, pPhones, pMessage, pSender, pDeliveryDate = "") Export
	vSMSFlash = 0; //SMS is not saved
	vLifeTime = 1; // SMS life time (hour)
	vErrorDescription = "";
	vStruct = New Structure("Success, MessageID, NumberOfSegments, Cost, Balance, Result, ErrorDescription", False, "", 0, 0, 0, "", "");
	Try	
		vDefinition = New WSDefinitions("http://ws1.smsdelivery.ru/SMSWebservice.asmx?WSDL");
		vProxy = New WSProxy(vDefinition,"http://smsdelivery.ru/","SMSWebService","SMSWebServiceSoap");
		// Sending SMS and get result
		WSProxyResponse = vProxy.SendMessage(pLogin, pPassword, vSMSFlash, vLifeTime, pPhones, pSender, pMessage);
	Except
		vStruct.Success = False;
		vStruct.Result = "Exception";
		vStruct.ErrorDescription = ErrorDescription();
		Return vStruct;
	EndTry;
	If WSProxyResponse.MessageID = -1 Then
		vStruct.Success = False;
		vStruct.Result = "Error";
		vStruct.ErrorDescription = SMS.ServerResponseDescription(WSProxyResponse.Result).Text;
		Return vStruct;
	ElsIf WSProxyResponse.Result <> "OK" Then
		vErrorDescription = SMS.ServerResponseDescription(WSProxyResponse.Result).Text;
	EndIf;
	rMessageID = StrReplace(StrReplace(String(WSProxyResponse.MessageID), " ", ""), Chars.NBSp, "");;
	// Return
	vStruct.Success = True;
	vStruct.MessageID = rMessageID;
	vStruct.NumberOfSegments = WSProxyResponse.SegmentsNumber;
	vStruct.Cost = 0;
	vStruct.Balance = 0;
	vStruct.Result = WSProxyResponse.Result;
	vStruct.ErrorDescription = vErrorDescription;
    Return vStruct;
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	vResultStructure = New Structure("Success, Status, Result, ErrorDescription", False, "", "", "");
	Try
		vDefinition = New WSDefinitions("http://ws1.smsdelivery.ru/SMSWebservice.asmx?WSDL");
		vProxy = New WSProxy(vDefinition, "http://smsdelivery.ru/", "SMSWebService", "SMSWebServiceSoap");
		// Get message status by message ID
		vMessageStatus = vProxy.GetMessageStatus(pLogin, pPassword, pMessageID);
	Except
		vResultStructure.Success = False;
		vResultStructure.Result = "Error";
		vResultStructure.ErrorDescription = ErrorDescription();
		Return vResultStructure;
	EndTry;
	vResultStructure.Success = True;
	vResultStructure.Status = vMessageStatus.MessageStatus;
	vResultStructure.Result = vMessageStatus.Result;
    Return vResultStructure;
EndFunction // GetStatus

// --------------------------------------------------------------------------------------------------------------
Function GetBalance(pLogin, pPassword, rErrorCode, rErrorDescription) Export
	rErrorCode = "";
	rErrorDescription = "";
           
	Try
		vDefinition = New WSDefinitions("http://ws1.smsdelivery.ru/SMSWebservice.asmx?WSDL");
		vProxy = New WSProxy(vDefinition,"http://smsdelivery.ru/","SMSWebService","SMSWebServiceSoap");
		// Checking the balance on your account
		vBalance = vProxy.GetBalance(pLogin, pPassword);
	Except
		rErrorCode = "Exception";
		rErrorDescription = ErrorDescription();
		Return 0;
	EndTry;
	If vBalance.Balance = -1 Then
		rErrorCode = TrimAll(vBalance.Result);
		rErrorDescription = SMS.ServerResponseDescription(TrimAll(vBalance.Result)).Text;
		Return 0;
	EndIf;
	Return vBalance.Balance;
EndFunction // GetBalance

