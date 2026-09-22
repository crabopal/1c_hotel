// --------------------------------------------------------------------------------
Procedure ReceiverNodeReceiveMessageProcessing(pMessage, pCancel)
	Try
		vExchangePlanName	= TrimAll(pMessage.Parameters["ExchangePlanName"]);
		vMessageNo			= Number(TrimAll(pMessage.Parameters["MessageNo"]));  
		
		vResult = "";                                                          
		
		// Try to find source and target nodes by codes
		vSourceNode = ExchangePlans[vExchangePlanName].FindByCode(TrimAll(pMessage.SenderCode));
		If Not ValueIsFilled(vSourceNode) Then
			vResult = NStr("en='Source node code is wrong: '; de='Source node code is wrong: '; ru='Неправильно указан код узла источника данных: '") + TrimAll(pMessage.SenderCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		If vSourceNode.DeletionMark Then
			vResult = NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimAll(pMessage.SenderCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		If Not vSourceNode.OnlineSyncIsActive Then
			vResult = NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimAll(pMessage.SenderCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		vTargetNode = ExchangePlans[vExchangePlanName].FindByCode(TrimAll(pMessage.RecipientCode));
		If Not ValueIsFilled(vTargetNode) Then
			vResult = NStr("en='Target node code is wrong: '; de='Target node code is wrong: '; ru='Неправильно указан код узла получателя данных: '") + TrimAll(pMessage.RecipientCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		If vTargetNode.DeletionMark Then
			vResult = NStr("en='On-line synchronization is switched off for marked for deletion node: '; de='On-line synchronization is switched off for marked for deletion node: '; ru='On-line синхронизация выключена для помеченного на удаление узла: '") + TrimAll(pMessage.RecipientCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		If Not vTargetNode.OnlineSyncIsActive Then
			vResult = NStr("en='On-line synchronization is switched off for node: '; de='On-line synchronization is switched off for node: '; ru='On-line синхронизация выключена для узла: '") + TrimAll(pMessage.RecipientCode) + " (" + TrimAll(vExchangePlanName) + ")!";
			pCancel = True;	
		EndIf;
		
		If pCancel Then
			WriteLogEvent(NStr("en='On-line synchronize'; ru='Синхронизация on-line'; de='Online-Synchronisation'"), EventLogLevel.Error, , , vResult);	
			Return;
		EndIf;
		
		If Not pMessage.CorrelationId = ExchangePlans[vExchangePlanName].EmptyRef().UUID() Then
			If vTargetNode.DeleteMessageAfterConfirmation Then
				InformationRegisters.ExchangePlanData.DeleteData(vMessageNo, vTargetNode, vSourceNode);	
			Else
				InformationRegisters.ExchangePlanData.UpdateData(vMessageNo, vTargetNode, vSourceNode,,,, True, pMessage.SendDate);
			EndIf;
			Return;
		EndIf;
			
		vFileSize = TrimAll(pMessage.Parameters["FileSize"]);
		
		vDataReader = New DataReader(pMessage.GetBodyAsStream());
		vBinaryDataBuffer = vDataReader.ReadIntoBinaryDataBuffer();
		vDataReader.Close();
				
		InformationRegisters.ExchangePlanData.WriteData(vMessageNo, vSourceNode, vTargetNode, GetBinaryDataFromBinaryDataBuffer(vBinaryDataBuffer), vFileSize / 100, False, '00010101', True, CurrentSessionDate(), False, '00010101');	
	Except 
		vResult = ErrorDescription();
		WriteLogEvent(NStr("en='On-line synchronize'; ru='Синхронизация on-line'; de='Online-Synchronisation'"), EventLogLevel.Error, , , vResult);
		pCancel = True;
		Return;
	EndTry; 
	
	SendNodeMessageResponse(vExchangePlanName, vMessageNo, pMessage.ID, vTargetNode, vSourceNode);
EndProcedure //ReceiverNodeReceiveMessageProcessing

// --------------------------------------------------------------------------------
Procedure SendNodeMessageResponse(pExchangePlanName, pMessageNo, pMessageID, pSenderNode, pReceiverNode)
	vMessage = IntegrationServices.DataExchangeInterfaces.CreateMessage();
	
	vMessage.SenderCode = TrimAll(pSenderNode.Code);
	vMessage.RecipientCode = TrimAll(pReceiverNode.Code);
	
	vMessage.Parameters.Insert("ExchangePlanName", pExchangePlanName); 
	vMessage.Parameters.Insert("MessageNo", pMessageNo);
	vMessage.CorrelationId = pMessageID; 
			
   	IntegrationServices.DataExchangeInterfaces.SenderNode.SendMessage(vMessage);
EndProcedure // SendNodeMessageResponse