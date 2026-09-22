
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	chat = Parameters.Chat;
	Title = Title + " " + chat;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel)
	FillSessions();
	AttachIdleHandler("RefreshMessage", 10);  
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure SessionsListOnActivateRow(pItem)
	sessions_start = pItem.CurrentData.sessions_start;
	sessions_stop  = pItem.CurrentData.sessions_stop;
	RefreshMessage();
EndProcedure

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Procedure FillSessions()
	SessionsList.Clear();
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ChatAuthorisation.employee,
		|	ChatAuthorisation.session_start AS session_start,
		|	ChatAuthorisation.hotel,
		|	ChatAuthorisation.room,
		|	ChatAuthorisation.sessions_stop
		|FROM
		|	InformationRegister.ChatAuthorisation AS ChatAuthorisation
		|WHERE
		|	ChatAuthorisation.chat = &chat
		|
		|ORDER BY
		|	session_start";
	Query.SetParameter("chat", chat);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		vNewRow = SessionsList.Add();
		vNewRow.employee = SelectionDetailRecords.employee;
		vNewRow.sessions_start = SelectionDetailRecords.session_start;
		If not ValueIsFilled(SelectionDetailRecords.sessions_stop) Then
			vSL = Chat.session_lifetime;
			if vSL = 0 Then
				vSL = 24;
			Endif;
			vNewRow.sessions_stop = SelectionDetailRecords.session_start + vSL*60*60
		Else
			vNewRow.sessions_stop = SelectionDetailRecords.sessions_stop;
		Endif;
	EndDo;
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure RefreshMessage()
	FillMessage();
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure FillMessage()
	MessageList.Clear();
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ChatBotUpdates.date AS date,
		|	ChatBotUpdates.messageSender,
		|	ChatBotUpdates.message_id,
		|	ChatBotUpdates.update_id,
		|	ChatBotUpdates.Text,
		|	ChatBotUpdates.message_type
		|FROM
		|	InformationRegister.ChatBotUpdates AS ChatBotUpdates
		|WHERE
		|	ChatBotUpdates.chat = &chat
		|	AND ChatBotUpdates.date BETWEEN &To AND &From
		|
		|ORDER BY
		|	date";
	Query.SetParameter("chat", chat);		
	Query.SetParameter("To",   sessions_start);
	Query.SetParameter("From", sessions_stop);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		vNewRow = MessageList.Add();
		vNewRow.time          = SelectionDetailRecords.date;
		vNewRow.sender        = SelectionDetailRecords.messageSender;
		vNewRow.message_type  = SelectionDetailRecords.message_type;
		vNewRow.text          = SelectionDetailRecords.Text;
	EndDo;
EndProcedure

#EndRegion    
