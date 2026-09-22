
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ReadOnly  = True;
EndProcedure

#EndRegion   

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure ViewResponseInTree(Command)
	ViewResponseInTree_AtServer();
EndProcedure
// --------------------------------------------------------------------------------
&AtClient
Procedure ViewRequestInTree(Command)
	ViewRequestInTree_AtServer();
EndProcedure

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

EndProcedure
// --------------------------------------------------------------------------------
&AtServer
Procedure ViewResponseInTree_AtServer()
	
	Try
		vResultTree = Catalogs.DataConvertationRules.JSON_or_XML_to_ValueTable(Record.Response);
		ValueToFormAttribute(vResultTree, "ResultTree");
	Except
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Failed to read the response as JSON or XML!'; de = 'Fehler beim Lesen der Antwort als JSON oder XML!'; ru = 'Не удалось прочитать ответ как JSON или XML!'"));
	EndTry;

EndProcedure

#EndRegion
