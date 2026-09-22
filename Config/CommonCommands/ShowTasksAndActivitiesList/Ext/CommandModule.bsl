// --------------------------------------------------------------------------------
&AtClient
Procedure CommandProcessing(pCommandParameter, pCommandExecuteParameters)
	vShowDocumentsJournal = True;
	vCurEmployee = tcOnServer.cmGetSessionParametersAttribute("CurrentUser");
	If ValueIsFilled(vCurEmployee) And ValueIsFilled(tcOnServer.cmGetAttributeByRef(vCurEmployee, "Customer")) Then
		vShowDocumentsJournal = False;
	ElsIf Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToSeeAllMessages") Then
		vShowDocumentsJournal = False;
	EndIf;
	If vShowDocumentsJournal Then
		OpenForm("Document.Message.ListForm", , pCommandExecuteParameters.Source, pCommandExecuteParameters.Uniqueness, pCommandExecuteParameters.Window, pCommandExecuteParameters.URL);
	Else
		tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights to open tasks and activities list!'; ru='У вас нет прав на открытие списка задач и действий!'; de='Sie haben keine Berechtigung, die Aufgaben- und Aktivitätenliste zu öffnen!'"), MessageStatus.Attention);
	EndIf;
EndProcedure // CommandProcessing
