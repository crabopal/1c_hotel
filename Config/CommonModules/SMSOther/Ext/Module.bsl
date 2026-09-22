// --------------------------------------------------------------------------------------------------------------
// API for user specific SMS gateway
// --------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------
Function SendSMS(pLogin, pPassword, pPhones, pMessage, pSender, pDeliveryDate = "") Export
	vStruct = New Structure("Success, MessageID, NumberOfSegments, Cost, Balance, Result, ErrorDescription", False, "", 0, 0, 0, "", "");
	SetSafeMode(True);
	Execute(TrimR(Catalogs.ExternalDataProcessors.OtherSendSMS.Algorithm));
	SetSafeMode(False);
    Return vStruct;
EndFunction // SendSMS

// --------------------------------------------------------------------------------------------------------------
Function GetStatus(pLogin, pPassword, pMessageID, pPhone) Export
	vStruct = New Structure("Success, Status, Result, ErrorDescription", False, "", "", "");
	SetSafeMode(True);
	Execute(TrimR(Catalogs.ExternalDataProcessors.OtherSMSGetStatus.Algorithm));
	SetSafeMode(False);
    Return vStruct;
EndFunction // GetStatus

// --------------------------------------------------------------------------------------------------------------
Function GetBalance(pLogin, pPassword, rErrorCode, rErrorDescription) Export
	rErrorCode = "";
	rErrorDescription = "";
	rBalance = 0;
	SetSafeMode(True);
	Execute(TrimR(Catalogs.ExternalDataProcessors.OtherSMSGetBalance.Algorithm));
	SetSafeMode(False);
	Return rBalance;
EndFunction // GetBalance

