#Region EventHandlers 

// --------------------------------------------------------------------------------
Function SynchronizePOST(pRequest)
	Try 
		// Initialize params
		vParamsArray = New Array;
		vParamsArray.Add("ExchangePlanName");
		vParamsArray.Add("MessageNo");
		vParamsArray.Add("SourceNodeCode");
		vParamsArray.Add("TargetNodeCode");
		vParamsArray.Add("ChangedData");
		vParamsArray.Add("FileSize");
		
		vNonMandatoryParamsArray = New Array;
		
		vInputParameters = cmCheckRequestParameters("JSON", vParamsArray, vNonMandatoryParamsArray, pRequest);
		If ValueIsFilled(vInputParameters.Error) Then
			Return GetResponce(400, vInputParameters.Error);
		EndIf;
		
		// Try to find source and target nodes by codes
		vSourceNode = ExchangePlans[vInputParameters.ExchangePlanName].FindByCode(TrimAll(vInputParameters.SourceNodeCode));
		If Not ValueIsFilled(vSourceNode) Then
			vResult = NStr("en='Source node code is wrong: '; de='Source node code is wrong: '; ru='Неправильно указан код узла источника данных: '") + TrimAll(vInputParameters.SourceNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
		If vSourceNode.DeletionMark Then
			vResult = NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimAll(vInputParameters.SourceNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
		If Not vSourceNode.OnlineSyncIsActive Then
			vResult = NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimAll(vInputParameters.SourceNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
		vTargetNode = ExchangePlans[vInputParameters.ExchangePlanName].FindByCode(TrimAll(vInputParameters.TargetNodeCode));
		If Not ValueIsFilled(vTargetNode) Then
			vResult = NStr("en='Target node code is wrong: '; de='Target node code is wrong: '; ru='Неправильно указан код узла получателя данных: '") + TrimAll(vInputParameters.TargetNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
		If vTargetNode.DeletionMark Then
			vResult = NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimAll(vInputParameters.TargetNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
		If Not vTargetNode.OnlineSyncIsActive Then
			vResult = NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimAll(vInputParameters.TargetNodeCode) + " (" + TrimAll(vInputParameters.ExchangePlanName) + ")!";
			Return GetResponce(400, vResult);	
		EndIf;
 
		InformationRegisters.ExchangePlanData.WriteData(vInputParameters.MessageNo, vSourceNode, vTargetNode, Base64Value(vInputParameters.ChangedData), vInputParameters.FileSize / 100, False, '00010101', True, CurrentSessionDate(), False, '00010101');					
	Except 
		vResult = ErrorDescription();
		WriteLogEvent(NStr("en='On-line synchronize'; ru='Синхронизация on-line'; de='Online-Synchronisation'"), EventLogLevel.Error, , , vResult);
		Return GetResponce(400, vResult);
	EndTry;
	
	// Return changes being read	
	Return GetResponce(200, "");
EndFunction // SynchronizePOST

#EndRegion 

#Region Private 

// --------------------------------------------------------------------------------
Function GetResponce(pStatus, pBody)
	vResponse = New HTTPServiceResponse(pStatus);
	vResponse.SetBodyFromString(pBody, TextEncoding.UTF8);
	Return vResponse;
EndFunction // GetResponce

#EndRegion 