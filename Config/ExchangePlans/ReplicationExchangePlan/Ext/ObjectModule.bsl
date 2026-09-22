#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnSendNodeDataToSlave(pDataItem, pIgnore)
	pIgnore = True;
EndProcedure // OnSendNodeDataToSlave

// -----------------------------------------------------------------------------
Procedure OnSendDataToSlave(pDataItem, pItemSend, pInitialImageCreating)
	If IsDebugMode Then
		#IF CLIENT THEN
			tcCommonFunctionOnClientServer.TextMessage("ReplicationExchangePlan.OnSendDataToSlave - " + TrimAll(pInitialImageCreating) + " - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), MessageStatus.Information);
		#ELSE
			WriteLogEvent("ReplicationExchangePlan.OnSendDataToSlave", EventLogLevel.Information, , , TrimAll(pInitialImageCreating) + " - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), EventLogEntryTransactionMode.Independent);
		#ENDIF
	EndIf; 
	If IgnoreMessagesWithChanges Then
		pItemSend = DataItemSend.Ignore;	
	EndIf;
EndProcedure // OnSendDataToSlave

// -----------------------------------------------------------------------------
Procedure OnSendDataToMaster(pDataItem, pItemSend)
	If IsDebugMode Then
		#IF CLIENT THEN
			tcCommonFunctionOnClientServer.TextMessage("ReplicationExchangePlan.OnSendDataToMaster - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), MessageStatus.Information);
		#ELSE
			WriteLogEvent("ReplicationExchangePlan.OnSendDataToMaster", EventLogLevel.Information, , , String(TypeOf(pDataItem)) + " - " + String(pDataItem), EventLogEntryTransactionMode.Independent);
		#ENDIF
	EndIf;
EndProcedure // OnSendDataToSlave

#EndRegion

