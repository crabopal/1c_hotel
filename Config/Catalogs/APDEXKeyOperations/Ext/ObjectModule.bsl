
#Region EventHandlers

Procedure BeforeWrite(pCancel)
	If DataExchange.Load Then
		Return;
	EndIf;;
	
	PriorityCheck(pCancel);
	If pCancel Тогда
		Return;
	КонецЕсли;
EndProcedure // BeforeWrite

#EndRegion

#Region Private

Procedure PriorityCheck(pCancel)
	
	If AdditionalProperties.Property("DoNotCheckPriority") Or Priority = 0 Then
		Return;
	EndIf;
	
	vQuery = New Query;
	vQuery.SetParameter("qPriority", Priority);
	vQuery.SetParameter("qRef", Ref);
	vQuery.Text = 
	"SELECT TOP 1
	|	APDEXKeyOperations.Ref AS Ref,
	|	APDEXKeyOperations.Description AS Description
	|FROM
	|	Catalog.APDEXKeyOperations AS APDEXKeyOperations
	|WHERE
	|	APDEXKeyOperations.Priority = &qPriority
	|	AND APDEXKeyOperations.Ref <> &qRef";
	
	vRes = vQuery.Execute().Select();
	If vRes.Next() Then
		vMsg = NStr("en = 'A key operation with priority ''%1'' already exists (%2).'; 
					|de = 'Es existiert bereits eine Tastenbetätigung mit der Priorität ''%1'' (%2).'; 
					|ru = 'Ключевая операция с приоритетом ""%1"" уже существует (%2).'");
		vMsg = StrReplace(vMsg, "%1", String(Priority));
		vMsg = StrReplace(vMsg, "%2", vRes.Description);
		
		tcOnServer.cmWriteLogEventAtServer("Catalog.APDEXKeyOperations.ObjectModul.BeforeWrite", "Error", , , vMsg);
		
		tcCommonFunctionOnClientServer.UserMessage(vMsg);
		pCancel = True;
	EndIf;
	
EndProcedure // PriorityCheck

#EndRegion
