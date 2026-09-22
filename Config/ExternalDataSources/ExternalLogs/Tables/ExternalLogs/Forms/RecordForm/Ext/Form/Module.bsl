
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	ReadOnly  = True;
	Try
		ExternalSystem = Catalogs.ExternalSystemInteractions.GetRef(New UUID(Record.ExternalSystemUUID)); 
		EventType = XMLValue(Type("EnumRef.ExternalSystemEventTypes"), Record.EventType); 
	Except
	EndTry;
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ViewResponseInTree(pCommand)
	ViewResponseInTree_AtServer();
EndProcedure // ViewResponseInTree

// --------------------------------------------------------------------------------
&AtClient
Procedure ViewRequestInTree(pCommand)
	ViewRequestInTree_AtServer();
EndProcedure // ViewRequestInTree

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure ViewRequestInTree_AtServer()
	Try
		vResultTree = Catalogs.DataConvertationRules.JSON_or_XML_to_ValueTable(Record.Request);
		ValueToFormAttribute(vResultTree, "ResultTree");
	Except
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to read the request as JSON or XML!'; de = 'Fehler beim Lesen der Anfrage als JSON oder XML!'; ru = 'Не удалось прочитать запрос как JSON или XML!'"));
	EndTry;
EndProcedure // ViewRequestInTree_AtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure ViewResponseInTree_AtServer()
	Try
		vResultTree = Catalogs.DataConvertationRules.JSON_or_XML_to_ValueTable(Record.Response);
		ValueToFormAttribute(vResultTree, "ResultTree");
	Except
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to read the response as JSON or XML!'; de = 'Fehler beim Lesen der Antwort als JSON oder XML!'; ru = 'Не удалось прочитать ответ как JSON или XML!'"));
	EndTry;
EndProcedure // ViewResponseInTree_AtServer

#EndRegion