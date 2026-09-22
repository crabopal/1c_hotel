#Region Public

// --------------------------------------------------------------------------------
Function GenerateRandomCode(pCharacters = 4) Export
	
	vResult = "";
	vRandom = new RandomNumberGenerator();
	i = 0;
	While i < pCharacters Do
		vResult = vResult + String(vRandom.RandomNumber(0, 9)); 
		i = i + 1;
	EndDo;
	Return String(vResult);
	
EndFunction

// --------------------------------------------------------------------------------
Function GetLastSentCodeAndDate(pPhone) Export
	
	vResult = New Structure("Code, DateSent", "", Date("00010101"));
	
	vQuery = New Query;
	vQuery.Text = 
		"SELECT TOP 1
		|	ClientVerificationCodes.VerificationCode AS VerificationCode,
		|	ClientVerificationCodes.DateSent AS DateSent
		|FROM
		|	InformationRegister.ClientVerificationCodes AS ClientVerificationCodes
		|WHERE
		|	ClientVerificationCodes.Phone = &qPhone
		|	AND ClientVerificationCodes.IsSent
		|	AND NOT ClientVerificationCodes.IsUsed
		|
		|ORDER BY
		|	DateSent DESC";
	
	vQuery.SetParameter("qPhone", pPhone);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vResult.Code 		= vSelectionDetailRecords.VerificationCode;
		vResult.DateSent 	= vSelectionDetailRecords.DateSent;
	EndDo;
	
	Return vResult;
	
EndFunction

// --------------------------------------------------------------------------------
Function VerifyCode(pExternalSystemInteractions, pPhone, pVerificationCode) Export
	
	vResult = New Structure("Success, ErrorDescription, Client", False, "Wrong code");
		
	vQuery = New Query;
	vQuery.Text = 
		"SELECT
		|	ClientVerificationCodes.VerificationCode AS VerificationCode,
		|	ClientVerificationCodes.DateSent AS DateSent,
		|	ClientVerificationCodes.IsUsed AS IsUsed,
		|	ClientVerificationCodes.Client AS Client
		|FROM
		|	InformationRegister.ClientVerificationCodes AS ClientVerificationCodes
		|WHERE
		|	ClientVerificationCodes.VerificationCode = &qVerificationCode
		|	AND ClientVerificationCodes.IsSent
		|	AND ClientVerificationCodes.Phone = &qPhone";
	
	vQuery.SetParameter("qPhone", pPhone);
	vQuery.SetParameter("qVerificationCode", pVerificationCode);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	vCodeLifeTime 	= pExternalSystemInteractions.SMSVerificationCodeLifeTime;
	vCurrentDate	= CurrentSessionDate();	
	
	While vSelectionDetailRecords.Next() Do
		If vSelectionDetailRecords.IsUsed Then
			vResult.ErrorDescription = "Code already used";
			Continue;
		EndIf;
		
		If vCodeLifeTime > 0 Then
			vCodeTime = (vCurrentDate - vSelectionDetailRecords.DateSent) / 60;
			If vCodeTime > vCodeLifeTime Then
				vResult.ErrorDescription = "Code timeout";
				Continue;
			Else
				vResult.Success = True;
				UseCode(pPhone, pVerificationCode, vSelectionDetailRecords.DateSent, vSelectionDetailRecords.Client);
				vResult.Client = vSelectionDetailRecords.Client; 
				Break;
			EndIf;
		Else
			vResult.Success = True;
			UseCode(pPhone, pVerificationCode, vSelectionDetailRecords.DateSent, vSelectionDetailRecords.Client);
			vResult.Client = vSelectionDetailRecords.Client; 
			Break;
		EndIf;
	EndDo;
	
	Return vResult;
		
EndFunction

// --------------------------------------------------------------------------------
Procedure ExchangePlansRecordChanges(pData, pReceiverNode = Undefined) Export
	// DATA FROM THIS REGISTER SHOULD NOT BE DISTRIBUTED BETWEEN NODES
EndProcedure // ExchangePlansRecordChanges

#EndRegion

#Region Private

Procedure UseCode(pPhone, pVerificationCode, pDateSent, pClient)
	
	vRcdMgr 					= InformationRegisters.ClientVerificationCodes.CreateRecordManager();
	vRcdMgr.Phone 				= pPhone;
	vRcdMgr.VerificationCode 	= pVerificationCode;
	vRcdMgr.IsSent				= True;
	vRcdMgr.DateSent			= pDateSent;
	vRcdMgr.IsUsed 				= True;
	vRcdMgr.DateUsed 			= CurrentSessionDate();
	vRcdMgr.Client 				= pClient;
	vRcdMgr.Write(True);
	
EndProcedure

#EndRegion