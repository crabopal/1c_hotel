#Region EventHandlers

// -----------------------------------------------------------------------------
Procedure OnSendDataToSlave(pDataItem, pItemSend, pInitialImageCreating)
	If IsDebugMode Then
		#IF CLIENT THEN
			tcCommonFunctionOnClientServer.TextMessage("CentralOfficeExchangePlan.OnSendDataToSlave - " + TrimAll(pInitialImageCreating) + " - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), MessageStatus.Information);
		#ELSE
			WriteLogEvent("CentralOfficeExchangePlan.OnSendDataToSlave", EventLogLevel.Information, , , TrimAll(pInitialImageCreating) + " - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), EventLogEntryTransactionMode.Independent);
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
			tcCommonFunctionOnClientServer.TextMessage("CentralOfficeExchangePlan.OnSendDataToMaster - " + String(TypeOf(pDataItem)) + " - " + String(pDataItem), MessageStatus.Information);
		#ELSE
			WriteLogEvent("CentralOfficeExchangePlan.OnSendDataToMaster", EventLogLevel.Information, , , String(TypeOf(pDataItem)) + " - " + String(pDataItem), EventLogEntryTransactionMode.Independent);
		#ENDIF
	EndIf;
EndProcedure // OnSendDataToMaster

// -----------------------------------------------------------------------------
Procedure OnSendNodeDataToSlave(pDataItem, pIgnore)
	pIgnore = True;
EndProcedure // OnSendNodeDataToSlave


#EndRegion