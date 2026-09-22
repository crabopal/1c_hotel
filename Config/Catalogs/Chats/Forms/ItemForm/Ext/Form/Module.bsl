
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	GetCurrentSession();
EndProcedure // OnCreateAtServer

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure StopCurrentSessions(pCommand)
	StopCurrentSessionsAtServer();
EndProcedure // StopCurrentSessions

// --------------------------------------------------------------------------------
&AtClient
Procedure OpenOldSessions(pCommand)
	vParameters = New Structure;
	vParameters.Insert("Chat", Object.Ref);
	OpenForm("Catalog.Chats.Form.OldSessionsForm", vParameters, ThisForm);
EndProcedure // OpenOldSessions

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure GetCurrentSession()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChatAuthorisationSliceLast.employee,
	|	ChatAuthorisationSliceLast.session_start AS session_start,
	|	ChatAuthorisationSliceLast.hotel,
	|	ChatAuthorisationSliceLast.room,
	|	ChatAuthorisationSliceLast.sessions_stop
	|FROM
	|	InformationRegister.ChatAuthorisation AS ChatAuthorisationSliceLast
	|WHERE
	|	ChatAuthorisationSliceLast.chat = &qchat
	|
	|ORDER BY
	|	session_start DESC";
	Query.SetParameter("qchat", Object.Ref);	
	QueryResult = Query.Execute();	
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		If not ValueIsFilled(SelectionDetailRecords.sessions_stop) Then
			SessionStart    = SelectionDetailRecords.session_start;
			CurrentEmployee = SelectionDetailRecords.employee;
			CurrentHotel    = SelectionDetailRecords.hotel;
			CurrentRoom     = SelectionDetailRecords.room;   
			SessionStop     = ?(Object.session_lifetime = 0,Undefined,SelectionDetailRecords.session_start + (Object.session_lifetime*60*60));
		Endif;
	EndIf;
EndProcedure // GetCurrentSession

// --------------------------------------------------------------------------------
&AtServer
Procedure StopCurrentSessionsAtServer()
	vMessage = New Structure;
	vMessage.Insert("bot",  Object.bot);
	vMessage.Insert("chat", Object.Ref);
	
	vCurrentSession = New Structure;
	vCurrentSession.Insert("employee", CurrentEmployee);
	vCurrentSession.Insert("session_start", SessionStart);
	
	vMessage.Insert("current_session",vCurrentSession);
	
	vAPI = cmGetChatBotAPI(Object.bot.BotType);
	If vAPI = Undefined Then
		vErr = Nstr("en = 'Unknown integration type'; de = 'Unbekannter Integrationstyp'; ru = 'Неизвестный тип интеграции'");
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vErr);
		Return;
	EndIf;
	
	vAPI.CloseCurrrentSessions(vMessage);
	GetCurrentSession();
EndProcedure // StopCurrentSessionsAtServer

#EndRegion