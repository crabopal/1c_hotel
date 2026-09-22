
#Region Public

// -----------------------------------------------------------------------------
//  Creates connections with settings defined in pBot ref
//
// Parameters:
//  pBot - CatalogRef.ChatBots	 - Bot
// 
// Returns:
//  HTTPConnection - HTTPConnection
//
Function Connect(pBot) Export
	vProxy = Undefined;
	If ValueIsFilled(pBot.Proxy) Then
		vProxy = New InternetProxy(False);
		
		vProxySettings = pBot.Proxy;
		For Each vProtocol In vProxySettings.Protocols Do
			vProxy.Set(vProtocol.Protocol, vProtocol.Server, vProtocol.Port, vProxySettings.User, vProxySettings.Password, False);
		EndDo;
	EndIf;
	
	vOpenSSLSecureConnection = Undefined;
	If pBot.UseSsl Or pBot.Server = "api.telegram.org" Then
		vOpenSSLSecureConnection = New OpenSSLSecureConnection();
	EndIf;
	
	vConnection = New HTTPConnection(pBot.Server, , , , vProxy, , vOpenSSLSecureConnection);
	Return vConnection;
EndFunction // Connect

// -----------------------------------------------------------------------------
//  Cheack connections with settings defined in pBot ref
//
// Parameters:
//  pBot - CatalogRef.ChatBots	 - Bot
// 
// Returns:
//  Structure - Response
//
Function CheckConnection(pBot) Export    
	vResponse = New Structure;
	vResponse.Insert("Result", False);
	vResponse.Insert("UserName", "");
	vResponse.Insert("Description", "");
	vResponse.Insert("Error", "");
	
	vRequestString = "bot" + pBot.Token + "/getMe";

	Try
		vConnection  =  Connect(pBot); 
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'The server address is incorrect.'; ru = 'Не правильно указан адрес сервера.'") + Chars.LF + vError);
		vResponse.Error = vError;  
		Return vResponse;
	EndTry;
	vRequest = New HTTPRequest(vRequestString);
	Try
		vReply 		= vConnection.Post(vRequest);
		vReplyText  = vReply.GetBodyAsString();
		tcCommonFunctionOnClientServer.TextMessage("Reply: " + vReplyText);
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Could not connect to the server.'; ru = 'Не удалось подключиться к серверу.'") + Chars.LF + vError);
		vResponse.Error = vError;  
		Return vResponse;
	EndTry;	 
	Try
		JSONReader = New JSONReader();
		JSONReader.SetString(vReplyText);	
		vResult = ReadJSON(JSONReader);	
		JSONReader.Close();	
		vResponse.Result = True;
	Except
		vError = ErrorDescription();
		tcCommonFunctionOnClientServer.TextMessage(NStr("en = 'Could not connect to the server.'; ru = 'Не удалось подключиться к серверу.'") + Chars.LF + vError);
		vResponse.Error = vError;  
	EndTry;
	If vResult.ok Then    
		vResponse.UserName = vResult.result.username;
		vResponse.Description = vResult.result.first_name;
	EndIf;	
	
	Return vResponse;
EndFunction

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBot - CatalogRef.ChatBots	 - Bot
//
Procedure setWebHook(pBot) Export
	requestParams = "?url=" + pBot.WebhookKey;
	vRequestString = "bot" + pBot.Token + "/setWebhook" + requestParams + "/" + pBot.Description + "&secret_token=" + TrimAll(pBot.UUID());;
	vConnection = Connect(pBot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);
	vRequest.SetBodyFromString(requestParams);
	vReply = vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	vResult = StringToStruct(vReplyText);
	tcCommonFunctionOnClientServer.TextMessage("setWebHook:" + Chars.LF + StructToString(vResult));
EndProcedure // setWebHook

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBot - CatalogRef.ChatBots	 - Bot
//
Procedure getWebhookInfo(pBot) Export
	vRequestString = "bot" + pBot.Token + "/getWebhookInfo";
	vConnection  =  Connect(pBot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);
	vReply 		= vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	vResult = StringToStruct(vReplyText);
	tcCommonFunctionOnClientServer.TextMessage("getWebhookInfo:" + Chars.LF + StructToString(vResult));
EndProcedure // getWebhookInfo

// -----------------------------------------------------------------------------
//
// Parameters:
//  pBot - CatalogRef.ChatBots - Bot 
//
Procedure deleteWebhook(pBot) Export
	vRequestString = "bot" + pBot.Token + "/deleteWebhook";
	vConnection  =  Connect(pBot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);
	vReply 		= vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	vResult = StringToStruct(vReplyText);	
	tcCommonFunctionOnClientServer.TextMessage("deleteWebhook:" + Chars.LF + StructToString(vResult));
EndProcedure // deleteWebhook

// -----------------------------------------------------------------------------
//  Get new messages from telegram server
//
// Parameters:
//  pBot - CatalogRef.ChatBots	 - Bot
//
Procedure getUpdates(pBot) Export
	vRequestString = "bot" + pBot.Token + "/getUpdates?offset=" + Format(pBot.offset + 1, "NG=");
	vConnection = Connect(pBot);
	If vConnection <> Undefined Then
		vRequest = New HTTPRequest(vRequestString);
		vReply = vConnection.Get(vRequest);
		vReplyData = vReply.GetBodyAsString();
		ProcessReply(vReplyData, pBot);
	EndIf;
EndProcedure // getUpdates

// -----------------------------------------------------------------------------
//
// Parameters:
//  pHotel		 - CatalogRef.Hotels - Ref
//  pRecipient	 - String			 - Recipient
//  pText		 - String			 - Text
// 
// Returns:
//  Boolen - Result sent
//
Function SendEmployeeMessage(pHotel, pRecipient, pText) Export
	vWasSent = False;
	Try
		vChats = Catalogs.ChatBots.GetAutorizaitingEmployee(pHotel, , pRecipient);
		If vChats.Count() > 0 Then
			For Each vRow In vChats Do
				vChat = vRow.Chat; 
				If vChat.Bot.IsActive Then
					pText =  StrReplace(pText, "&", "");
					requestParams = "?chat_id=" + Format(vChat.chat_id, "NG=") + "&text=" + pText;
					requestParams = requestParams + "&parse_mode=HTML";
					
					vRequestString = "bot" + vChat.Bot.Token + "/sendMessage" + requestParams;
					
					vConnection = Connect(vChat.Bot);
					vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
					vRequest = New HTTPRequest(vRequestString);	
					
					vRequest.SetBodyFromString(requestParams);
					vReply = vConnection.Post(vRequest);
					
					vReplyText  = vReply.GetBodyAsString();
					ProcessBotReply(vReplyText, vChat.Bot);  
					If vReply.StatusCode = 200 Then
						vWasSent = True;
					EndIf;
				EndIf;	
			EndDo;
		EndIf;
		Return vWasSent;
	Except
		Return vWasSent;
	EndTry;
EndFunction // SendEmployeeMessage

// -----------------------------------------------------------------------------
//  Parse messages recieved from telegram server
//
// Parameters:
//  pData		 - Date			 - Date
//  pBot		 - CatalogRef.ChatBots	 - Bot
//  pIsWebHook	 - Boolen				 - IsWebHook
//
Procedure ProcessReply(pData, pBot, pIsWebHook = False) Export
	Try
		vResult = StringToStruct(pData);		
		If pIsWebHook Then	
			vMessage = GetInfoStruct(vResult, pBot);
			RegisterMessage(vMessage, False);
			ProcessCommand(vMessage);	
		Else
			If Not vResult.ok Then
				Return;
			EndIf;	
			RequestList = vResult.result;	
			For Each Request In RequestList Do
				vMessage = GetInfoStruct(Request, pBot);
				RegisterMessage(vMessage, False);
				ProcessCommand(vMessage);		
			EndDo;
		EndIf;
	Except
		vError = ErrorDescription();	
		WriteLogEvent("Chat bot error", EventLogLevel.Error, , CurrentSessionDate(), vError);
	EndTry;
EndProcedure // ProcessReply

// -----------------------------------------------------------------------------
//
// Parameters:
//  pRoom				 - CatalogRef.Rooms		 - Ref
//  pText				 - String				 - Text
//  pEmployee			 - CatalogRef.Employees	 - Ref
//  pPhoto				 - Photo				 - Photo
//  vPhotoId			 - String				 - PhotoId
//  pBot				 - CatalogRef.ChatBots	 - Bot
//  EngineerDepartment	 - CatalogRef.Departments	 - Ref
// 
// Returns:
//  DocumentRef.Message - Ref
//
Function SetTask(pRoom, pText, pEmployee, pPhoto = Undefined, vPhotoId = Undefined, pMessage, pEngineerDepartment = Undefined, pTaskType = "") Export
	If IsBlankString(pText) And pPhoto = Undefined Then
		Return Null;
	EndIf;
	If Not ValueIsFilled(pRoom) Then
		Return Null;
	EndIf;
 
	If Not ValueIsFilled(pEngineerDepartment) Then
		vEngDeps = pMessage.Bot.EngineerDepartments;
		If vEngDeps.Count() > 0 Then
			pEngineerDepartmentRow = vEngDeps.Find(pText, "TaskType");
			If pEngineerDepartmentRow <> Undefined Then
				pEngineerDepartment = pEngineerDepartmentRow.Departments;
			Else
				pEngineerDepartment = pMessage.Bot.EngineerDepartment;
			EndIf;
		EndIf;
	EndIf;
	
	If pPhoto <> Undefined Then
		If pMessage.Property("caption") Then
			pText = pText + ". " + pMessage.caption + ", " + NStr("ru='см. фото';en='see photo';de='siehe Foto'");
		Else
			pText = pText + ", " + NStr("ru='см. фото';en='see photo';de='siehe Foto'");			
		EndIf;
	EndIf;
		
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Messages.Remarks AS Remarks,
	|	Messages.ByObject AS ByObject,
	|	Messages.Ref AS Ref
	|FROM
	|	Document.Message AS Messages
	|WHERE
	|	Messages.Remarks LIKE &qRemarks
	|	AND Messages.Posted
	|	AND NOT Messages.IsClosed
	|	AND Messages.ByObject = &qRoom
	|
	|ORDER BY
	|	Messages.Date DESC";
	vQ.SetParameter("qRemarks", pText);
	vQ.SetParameter("qRoom", pRoom);
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return Null;
	EndIf;
	Try
		vDoc = Documents.Message.CreateDocument();
		vDoc.pmFillAttributesWithDefaultValues();
		vDoc.Type		   = Enums.MessageTypes.Task;
		vDoc.ByObject      = pRoom;
		vDoc.Author        = pEmployee;
		vDoc.Remarks       = pText;
		vDoc.ForDepartment = pEngineerDepartment;
		vDoc.Write(DocumentWriteMode.Posting);
		// Attach photo to this message
		If pPhoto <> Undefined Then
			// Add record to the message attachments register
			vRcdMgr = InformationRegisters.MessageAttachments.CreateRecordManager();
			vRcdMgr.Period             = CurrentSessionDate();
			vRcdMgr.Message            = vDoc.Ref;
			vRcdMgr.Author             = vDoc.Author;
			vRcdMgr.PhotoID    = vPhotoId;
			vRcdMgr.ExtFile            = New ValueStorage(pPhoto);
			vRcdMgr.FileName           = "foto_" + TrimAll(vDoc.ByObject) + "_" + Format(CurrentSessionDate(), "DF=yyyy-MM-dd_HHmm") + ".jpg";
			vRcdMgr.FileLoadTime       = vRcdMgr.Period;
			vRcdMgr.FileLastChangeTime = vRcdMgr.Period;
			vRcdMgr.Write();
		EndIf;
		Catalogs.ChatBots.SendNotification(vDoc.Ref.ByObject.Owner, vDoc.Ref.ForDepartment);
		Return vDoc.Ref;
	Except
	EndTry;
EndFunction

// -----------------------------------------------------------------------------
//  Function - Close currrent sessions
//
// Parameters:
//  pMessage - 	 - Message struct
//  	-----------------------------------------------------------------------------
//
Procedure CloseCurrrentSessions(pMessage) Export 
	vRecordSet = InformationRegisters.ChatAuthorisation.CreateRecordSet();
	vRecordSet.Filter.chat.Set(pMessage.chat);
	vRecordSet.Filter.employee.Set(pMessage.current_session.employee);	
	vRecordSet.Filter.session_start.Set(pMessage.current_session.session_start);	
	vRecordSet.Read();
	If vRecordSet.Count() > 0 Then
		vCurrentSessions = vRecordSet[0];
		vCurrentSessions.sessions_stop = CurrentSessionDate();
		vRecordSet.Write();
	EndIf;
	DeleteContext(pMessage.chat, pMessage.message_id - 1);
	vRM = InformationRegisters.HousekeepingShift.CreateRecordManager();	
	vRM.Hotel    = vCurrentSessions.hotel;
	vRM.Employee = vCurrentSessions.employee;
	vRM.Read();
	If vRM.Selected() Then
		vRM.Delete();
	EndIf;
	sendMessage(pMessage, NStr("en = 'Shift was successfully closed!'; de = 'Schicht wurde erfolgreich geschlossen!'; ru = 'Смена успешно закрыта!'"), hideKeyboard());
EndProcedure

// -----------------------------------------------------------------------------
//  Procedure - Edit currrent sessions
//
// Parameters:
//  pMessage - 	 - Message struct
//  	-----------------------------------------------------------------------------
//
Procedure EditCurrentSessions(pMessage) Export
	vRecordSet = InformationRegisters.ChatAuthorisation.CreateRecordSet();
	vRecordSet.Filter.chat.Set(pMessage.chat);
	vRecordSet.Filter.employee.Set(pMessage.current_session.employee);	
	vRecordSet.Filter.session_start.Set(pMessage.current_session.session_start);	
	vRecordSet.Read();
	vCurrentSessions = vRecordSet[0];
	If pMessage.current_session.hotel <> vCurrentSessions.hotel Then
		vCurrentSessions.hotel = pMessage.current_session.hotel;
		vRM = InformationRegisters.HousekeepingShift.CreateRecordManager();	
		vRM.Hotel    = vCurrentSessions.hotel;
		vRM.Employee = pMessage.current_session.employee;
		vRM.Write();		
	EndIf;
	If pMessage.current_session.room <> vCurrentSessions.room Then
		vCurrentSessions.room = pMessage.current_session.room;	
	EndIf;
	If pMessage.current_session.section <> vCurrentSessions.section Then
		vCurrentSessions.section = pMessage.current_session.section;	
	EndIf;
	
	vRecordSet.Write();
EndProcedure // EditCurrentSessions

// -----------------------------------------------------------------------------
//
// Parameters:
//  pEmployee	 - CatalogRef.Employees	 - Ref
// 
// Returns:
//  Array - List keys
//
Function getKeyboard(pEmployee) Export
	BaseArray = New Array;
	If pEmployee.PermissionGroup.ChatRole = Enums.ChatRoles.Supervisor Then
		Keys = New Array;
		Keys.Add(NStr("en = 'List of attendants'; de = 'Liste der Teilnehmer'; ru = 'Список сотрудников'"));
		BaseArray.Add(Keys);		
		Keys = New Array;
		Keys.Add(NStr("en = 'List of rooms'; de = 'Liste der Zimmer'; ru = 'Список номеров'"));
		BaseArray.Add(Keys);
		Keys = New Array;
		Keys.Add(NStr("en = 'List of assignments'; de = 'Liste der Aufgaben'; ru = 'Список работ'"));
		BaseArray.Add(Keys);
		Keys = New Array;
		Keys.Add(NStr("en = 'Consumption on demand'; de = 'Verbrauch nach Bedarf'; ru = 'Расход по требованию'"));
		BaseArray.Add(Keys);		
	ElsIf pEmployee.PermissionGroup.ChatRole = Enums.ChatRoles.Engineer Then
		Keys = New Array;
		Keys.Add(NStr("en = 'Task list'; de = 'Aufgabenliste'; ru = 'Список задач'"));
		BaseArray.Add(Keys);
	ElsIf pEmployee.PermissionGroup.ChatRole = Enums.ChatRoles.Maid Then
		Keys = New Array;
		Keys.Add(NStr("en = 'List of assignments'; de = 'Liste der Aufgaben'; ru = 'Список работ'"));
		BaseArray.Add(Keys);
		Keys = New Array;
		Keys.Add(NStr("en = 'Consumption on demand'; de = 'Verbrauch nach Bedarf'; ru = 'Расход по требованию'"));
		BaseArray.Add(Keys);
	EndIf;
	
	Keys = New Array;
	Keys.Add(NStr("en = 'Help'; de = 'Hilfe'; ru = 'Помощь'"));
	BaseArray.Add(Keys);
	
	Keys = New Array;
	Keys.Add(NStr("en = 'Close shift'; de = 'Schicht schließen'; ru = 'Закрыть смену'"));
	BaseArray.Add(Keys);
	
	Return ArrayToJSON(BaseArray);
EndFunction // getKeyboard

// -----------------------------------------------------------------------------
//
// Parameters:
//  pMessage		 - Structure - Message
//  pText			 - String	 - Text
//  pKeyboard		 - String	 - Keyboard
//  pDeleteButton	 - Boolean	 - Delete button
// 
// Returns:
//  String - Result
//
Function sendMessage(pMessage, pText, pKeyboard = "", pDeleteButton = True) Export
	pText = StrReplace(pText, "&", "");
	
	If pDeleteButton Then
		DeleteButton(pMessage.Chat);
	EndIf;
	
	vRequestParams = "?chat_id=" + Format(pMessage.Chat.chat_id, "NG=") + "&text=" + pText;
	vRequestParams = vRequestParams + "&parse_mode=HTML";
	If Not IsBlankString(pKeyboard) Then 
		vRequestParams = vRequestParams + "&reply_markup=" + pKeyboard;    
	Else
		pKeyboard = hideKeyboard(); 
		vRequestParams = vRequestParams + "&reply_markup=" + pKeyboard;
	EndIf;
	vRequestString = "bot" + pMessage.Bot.Token + "/sendMessage" + vRequestParams;
	
	vConnection  =  Connect(pMessage.Bot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);	
	vRequest.SetBodyFromString(vRequestParams);
	vReply 		= vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	Return ProcessBotReply(vReplyText, pMessage.Bot);
EndFunction // sendMessage

#EndRegion

#Region Private

#Region Telegram_api

// -----------------------------------------------------------------------------
Procedure updateMessage(pMessage, pText, pKeyboard = "", message_id = "")
	pText =  StrReplace(pText, "&", "");
	vRequestParams = "?chat_id=" + Format(pMessage.Chat.chat_id, "NG=");
	If message_id = "" Then
		vRequestParams = vRequestParams + "&message_id=" + Format(pMessage.message_id, "NG=");
	Else
		vRequestParams = vRequestParams + "&message_id=" + Format(message_id, "NG=");
	EndIf;
	
	vRequestParams = vRequestParams +  "&text=" + pText;
	vRequestParams = vRequestParams + "&parse_mode=HTML";
	If Not IsBlankString(pKeyboard) Then 
		vRequestParams = vRequestParams + "&reply_markup=" + pKeyboard;    
	EndIf;
	
	vRequestString = "bot" + pMessage.Bot.Token + "/editMessageText" + vRequestParams;
	vConnection  =  Connect(pMessage.Bot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);		
	vRequest.SetBodyFromString(vRequestParams);
	vReply 		= vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	ProcessBotReply(vReplyText, pMessage.Bot);    
EndProcedure // updateMessage

// -----------------------------------------------------------------------------
Procedure sendPhoto(pBot, pChat_id, pPhoto) 
	pText =  StrReplace(pText, "&", "");
	requestParams = "?chat_id=" + Format(pChat_id, "NG=") + "&photo=" + pPhoto;
	
	vRequestString = "bot" + pBot.Token + "/sendPhoto" + requestParams;
	vConnection  =  Connect(pBot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);
	vRequest.SetBodyFromString(requestParams);
	vReply 		= vConnection.Post(vRequest);
	vReplyText  = vReply.GetBodyAsString();
	ProcessBotReply(vReplyText, pBot);	
EndProcedure // sendPhoto

// -----------------------------------------------------------------------------
Procedure editMessageReplyMarkup(pChat, pMessage_id, pBot, Val pText, pKeyboard = "")
	pText =  StrReplace(pText, "&", "");
	vRequestParams = "?chat_id=" + Format(pChat.chat_id, "NG=") + "&message_id=" + Format(pMessage_id, "NG=");
	If Not IsBlankString(pKeyboard) Then 
		vRequestParams = vRequestParams + "&reply_markup=" + pKeyboard;    
	EndIf;
	
	vRequestString = "bot" + pBot.Token + "/editMessageReplyMarkup" + vRequestParams;
	vConnection  =  Connect(pBot);
	vRequestString = StrReplace(vRequestString, Chars.LF, "%0D%0A");
	vRequest = New HTTPRequest(vRequestString);	
	vRequest.SetBodyFromString(vRequestParams);
	vConnection.Post(vRequest);
EndProcedure // EditMessageReplyMarkup

// -----------------------------------------------------------------------------
Function getPhoto(pFile_id, pBot)
	vReplyData = Undefined;
	vRequestString = "bot" + pBot.Token + "/getFile?file_id=" + pFile_id;
	vConnection  =  Connect(pBot);
	vRequest = New HTTPRequest(vRequestString);
	vReply = vConnection.Get(vRequest);
	vReplyString = vReply.GetBodyAsString();
	vFilePathPos = StrFind(vReplyString, "file_path");
	If vFilePathPos > 0 Then
		vFilePath = Mid(vReplyString, vFilePathPos + 12);
		vFilePath = Left(vFilePath, StrLen(vFilePath) - 3);		
		vRequestString = "file/bot" + pBot.Token + "/" + StrReplace(vFilePath, "\", "");
		vConnection  =  Connect(pBot);
		vRequest = New HTTPRequest(vRequestString);
		vReply = vConnection.Get(vRequest);
		vReplyData = vReply.GetBodyAsBinaryData();
	EndIf;
	Return vReplyData;
EndFunction // getPhoto

#EndRegion

#Region ProcessMessage

// -----------------------------------------------------------------------------
// Main processing function
// Parameters: pRequest - message recieved from telegram server;
// pBot - ref to ChatBot catalog for communication params like token etc.
// Parses message, look for command name and sends reply
// -----------------------------------------------------------------------------
Procedure ProcessCommand(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vDelimiter = "%0D%0A";  
	vOperationType = "ChatContext"; 
	vOperationKey = "Task";
	vEmployee = BotAuthorisation(pMessage);
	If ValueIsFilled(vEmployee) Then
		vPermissions = vEmployee.PermissionGroup.ChatRole;
		If ValueIsFilled(vPermissions) Then
			#Region MAIDS			
			If vPermissions = Enums.ChatRoles.Maid Then
				// ==  MAIDS  =======================================================================================================================================================	
				If pMessage.message_type = "text" Then
					chatCommand = GetChatCommand(pMessage.data);
					vHotel = Undefined;
					If Not ValueIsFilled(pMessage.current_session.hotel) Then
						// Choose hotel
						If ValueIsFilled(vEmployee.Hotel) Then							
							vHotel = vEmployee.Hotel; 
						Else
							Hotels = GetHotelNumber(); 
							If Hotels.Count() > 1 Then
								vHotel = Catalogs.Hotels.FindByDescription(pMessage.data);
							Else								
								vHotel = Hotels[0].Hotel;
							EndIf;							
						EndIf;
						If ValueIsFilled(vHotel) Then
							pMessage.current_session.hotel = vHotel;
							EditCurrentSessions(pMessage);
							// Get list of rooms where operation should be done
							vMaidOperList = cmGetEmployeeOperationQueue(CurrentSessionDate(), , vEmployee);
							If vMaidOperList.Count() > 0 And pMessage.Bot.UseAutoOperationControl Then
								vEmplOper = vMaidOperList[0].RefDoc.GetObject();
								vEmplOper.Employee = vEmployee;
								vEmplOper.EmployeeAssignmentTime = CurrentSessionDate();
								vEmplOper.Write(DocumentWriteMode.Posting);
								sendMessage(pMessage, "<b>" + NStr("en = 'You have a new room assigned'; ru = 'Назначен новый номер'; de = 'Sie haben eine neue Zimmer zugewiesen'") + "</b>" + vDelimiter + Catalogs.ChatBots.GetRoomText(vEmplOper.Room, vShowGuestsLastName), getKeyboard(vEmployee));
								Catalogs.ChatBots.SendNotification(vHotel);							
								Return;
							Else
								// Get list of all started operations
								vAllActiveOperations = Catalogs.ChatBots.GetCurrentOperations();
								// Get list of started operations assigned to the employee
								vEmployeeOperations = Catalogs.ChatBots.GetCurrentOperations(, vEmployee);
								If vAllActiveOperations.Count() > 0 And vEmployeeOperations.Count() = 0 Then
									sendMessage(pMessage, "<b>" + NStr("en = 'No rooms assigned'; ru = 'На данный момент работы нет'; de = 'Im Moment gibt es keine Arbeit'") + "</b>", getKeyboard(vEmployee));
									Catalogs.ChatBots.SendNotification(vHotel);							
									Return;
								EndIf;
							EndIf;								
						Else
							sendMessage(pMessage, "<b>" + NStr("en = 'Choose the hotel'; de = 'Wählen Sie das Hotel, wo Sie arbeiten werden'; ru = 'Выберите отель, в котором будете работать'") + "</b>", getHotelKeyboard());
							Return;
						EndIf;
					Else
						vHotel = pMessage.current_session.hotel;
					EndIf;
					vRoom = GetRoom(pMessage.Data, vHotel);
					If ValueIsFilled(vRoom) Then 
						DeleteContext(pMessage.chat, , vOperationType, vOperationKey);
						pMessage.current_session.room = vRoom;
						EditCurrentSessions(pMessage);
						vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, "Consumption");	
						If ValueIsFilled(vContext) Then
							DeleteContext(pMessage.chat, , vOperationType, "Consumption");
							sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());								
							vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + vDelimiter + NStr( "en = 'Items consumption'; de = 'Nomenklaturaufwand'; ru = 'Расход номенклатуры'") + vDelimiter +
							GetArticleTableForDocumentNew(vRoom, pMessage) + "<b>" + NStr("en = 'choose the item'; de = 'Wählen Sie eine Nomenklatur aus'; ru = 'Выберите номенклатуру'") + "</b>", getInLineKeyboardForArticlesNew(vRoom, pMessage));								
						Else								
							sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());
							vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));								
						EndIf;
						SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
					ElsIf chatCommand = "Bye" Then
						CloseCurrrentSessions(pMessage);
					ElsIf chatCommand = "MyRoomsList" Or chatCommand = "Menu" Then
						pMessage.current_session.room = Undefined;
						EditCurrentSessions(pMessage);
						sendMessage(pMessage, GetRoomListMessage(pMessage), getKeyboard(pMessage.current_session.Employee));									
					ElsIf chatCommand = "Consumption" Then
						vMessage_id = sendMessage(pMessage, NStr("en = 'Enter room number'; de = 'Zimmernummer eingeben'; ru = 'Введите номер комнаты'"));
						SetContext(pMessage.chat, vMessage_id, vOperationType, "Consumption", "ConsumptionNew");							
					ElsIf chatCommand = "Help" Then
						sendMessage(pMessage, GetHelpText(pMessage.current_session.employee), getKeyboard(pMessage.current_session.Employee));								
					Else
						vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
						If ValueIsFilled(vContext) Then
							CreateTask(pMessage);
						Else
							vEmp = Undefined;
							Try
								vEmp = cmGetEmployeeByPBXAccountCode(Number(pMessage.Data));
							Except
							EndTry;
							If Not ValueIsFilled(vEmp) Then
								vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, "Consumption");	
								If ValueIsFilled(vContext) Then
									DeleteContext(pMessage.chat, , vOperationType, "Consumption");
									sendMessage(pMessage, NStr("ru='Номер не найден!';en='Room is not found!';de='Zimmer nicht gefunden!'"), getKeyboard(pMessage.current_session.Employee));	
								Else
									sendMessage(pMessage, NStr("ru='Эта команда мне не известна';de='Unbekannter Befehl';en='Unknown command'"), getKeyboard(pMessage.current_session.Employee));	
								EndIf;
							EndIf;
						EndIf;
					EndIf;							
					Catalogs.ChatBots.SendNotification(vHotel);	
				ElsIf pMessage.message_type = "callback_query" Then						
					ProcessCommandCallback(pMessage);
				ElsIf pMessage.message_type = "photo" Then						
					vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
					If ValueIsFilled(vContext) Then
						CreateTask(pMessage);
					EndIf;
				EndIf;
			#EndRegion
			#Region	SUPERVISOR
			ElsIf vPermissions = Enums.ChatRoles.Supervisor Then
				// ==  SUPERVISOR  =================================================================================================================================================
				If pMessage.message_type = "text" Then
					chatCommand = GetChatCommand(pMessage.data);
					If Not ValueIsFilled(pMessage.current_session.hotel) Then
						// Choise hotel
						If ValueIsFilled(vEmployee.Hotel) Then								
							vHotel = vEmployee.Hotel; 
						Else
							Hotels = GetHotelNumber(); 
							If Hotels.Count() > 1 Then
								vHotel = Catalogs.Hotels.FindByDescription(pMessage.data);
							Else									
								vHotel = Hotels[0].Hotel;
							EndIf;								
						EndIf;							
						If ValueIsFilled(vHotel) Then
							pMessage.current_session.hotel = vHotel;
							EditCurrentSessions(pMessage);
							If Catalogs.ChatBots.UseSections(pMessage.current_session.hotel) And Not ValueIsFilled(pMessage.current_session.section) Then	
								If ValueIsFilled(vEmployee.RoomSection) Then
									pMessage.current_session.section = vEmployee.RoomSection;
									EditCurrentSessions(pMessage);
									sendMessage(pMessage, EmployeeList(pMessage.current_session.hotel, Enums.ChatRoles.Maid) + RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection, , pMessage.current_session.section), getKeyboard(pMessage.current_session.Employee));	
								Else
									sendMessage(pMessage, NStr("en = 'Choose the section'; de = 'Wählen Sie das section, wo Sie arbeiten werden'; ru = 'Выберите секцию, в которой будете работать'"), getSectionKeyboard(pMessage.current_session.hotel));
								EndIf;
							Else
								sendMessage(pMessage, EmployeeList(pMessage.current_session.hotel, Enums.ChatRoles.Maid) + RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection, , pMessage.current_session.section), getKeyboard(pMessage.current_session.Employee));
							EndIf;
						Else
							sendMessage(pMessage, NStr("en = 'Choose the hotel'; de = 'Wählen Sie das Hotel, wo Sie arbeiten werden'; ru = 'Выберите отель, в котором будете работать'"), getHotelKeyboard());
						EndIf;
					ElsIf Catalogs.ChatBots.UseSections(pMessage.current_session.hotel) And Not ValueIsFilled(pMessage.current_session.section) Then	
						// Section choice
						vSection = Catalogs.RoomSections.FindByDescription(pMessage.data);
						If ValueIsFilled(vSection) Then
							If ValueIsFilled(vSection.Hotel) Then
								pMessage.current_session.hotel = vSection.Hotel;
							ElsIf ValueIsFilled(vEmployee.Hotel) Then
								pMessage.current_session.hotel = vEmployee.Hotel;
							EndIf;
							pMessage.current_session.section = vSection;
							EditCurrentSessions(pMessage);
							sendMessage(pMessage, EmployeeList(pMessage.current_session.hotel, Enums.ChatRoles.Maid) + RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection, , pMessage.current_session.section), getKeyboard(pMessage.current_session.Employee));	
						ElsIf ValueIsFilled(vEmployee.RoomSection) Then
							pMessage.current_session.section = vEmployee.RoomSection;
							EditCurrentSessions(pMessage);
							sendMessage(pMessage, EmployeeList(pMessage.current_session.hotel, Enums.ChatRoles.Maid) + RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection, , pMessage.current_session.section), getKeyboard(pMessage.current_session.Employee));	
						Else
							sendMessage(pMessage, NStr("en = 'Choose the section'; ru = 'Выберите секцию, в которой будете работать'; de = 'Wählen Sie das section, wo Sie arbeiten werden'"), getSectionKeyboard(pMessage.current_session.hotel));
						EndIf;
					Else 
						vRoom = GetRoom(pMessage.Data, pMessage.current_session.hotel);
						vStatuses = GetRoomStatus(pMessage.current_session.hotel, pMessage.Data);
						chatCommand = GetChatCommand(pMessage.data);
						If ValueIsFilled(vRoom) Then 
							DeleteContext(pMessage.chat, , vOperationType, vOperationKey);
							pMessage.current_session.room = vRoom;
							EditCurrentSessions(pMessage);
							vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, "Consumption");	
							If ValueIsFilled(vContext) Then
								DeleteContext(pMessage.chat, , vOperationType, "Consumption");
								sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());									
								vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + vDelimiter + NStr( "en = 'Items consumption'; ru = 'Расход номенклатуры'; de = 'Nomenklaturaufwand'") + vDelimiter +
								GetArticleTableForDocumentNew(vRoom, pMessage) + "<b>" + NStr("en = 'choose the item'; ru = 'Выберите номенклатуру'; de = 'Wählen Sie eine Nomenklatur aus'") + "</b>", getInLineKeyboardForArticlesNew(vRoom, pMessage));									
							Else								
								sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());
								vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));								
							EndIf;
							SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
						ElsIf ValueIsFilled(vStatuses) Then 
							sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());		
							vRoomsCount = RoomStatusList(pMessage.current_session.hotel, vStatuses, False, pMessage.current_session.section).Count();
							vMessage_id = sendMessage(pMessage, RoomStatusList(pMessage.current_session.hotel, vStatuses, , pMessage.current_session.section), ?(vRoomsCount > 30, getRoomSwichKeyboard(), getKeyboard(pMessage.current_session.Employee)));	
							SetContext(pMessage.chat, vMessage_id, "Statuses", pMessage.Data, 1);				
						ElsIf chatCommand = "Bye" Then
							CloseCurrrentSessions(pMessage);	
						ElsIf chatCommand = "Help" Then
							sendMessage(pMessage, GetHelpText(pMessage.current_session.employee), getKeyboard(pMessage.current_session.Employee));	
						ElsIf chatCommand = "MyRoomsList" Or chatCommand = "Menu" Then
							sendMessage(pMessage, RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection, , pMessage.current_session.section), getKeyboard(pMessage.current_session.Employee));	
						ElsIf chatCommand = "MaidsList" Then
							sendMessage(pMessage, EmployeeList(pMessage.current_session.hotel, Enums.ChatRoles.Maid), getKeyboard(pMessage.current_session.Employee));		
						ElsIf chatCommand = "RoomStats" Then
							sendMessage(pMessage, GetAllStatusRoomList(pMessage.current_session.hotel, pMessage.current_session.section), GetAllStatusRoomListKeyboard(pMessage.current_session.hotel, pMessage.current_session.section));	
						ElsIf chatCommand = "Consumption" Then
							vMessage_id = sendMessage(pMessage, NStr("ru='Введите номер комнаты';en='Enter room number';de='Zimmernummer eingeben'"));
							SetContext(pMessage.chat, vMessage_id, vOperationType, "Consumption", "ConsumptionNew");							
						ElsIf chatCommand = "Tasks" Then
							sendMessage(pMessage, getTaskList(pMessage.current_session.hotel, Undefined, False, pMessage.bot.EngineerDepartment));
						Else
							vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
							If ValueIsFilled(vContext) Then
								CreateTask(pMessage);
							Else
								vEmp = Undefined;
								Try
									vEmp = cmGetEmployeeByPBXAccountCode(Number(pMessage.Data));
								Except
								EndTry;
								If Not ValueIsFilled(vEmp) Then
									vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, "Consumption");	
									If ValueIsFilled(vContext) Then
										DeleteContext(pMessage.chat, , vOperationType, "Consumption");
										sendMessage(pMessage, NStr("en = 'Room is not found!'; de = 'Zimmer nicht gefunden!'; ru = 'Номер не найден!'"), getKeyboard(pMessage.current_session.Employee));	
									Else
										sendMessage(pMessage, NStr("en = 'Unknown command'; de = 'Unbekannter Befehl'; ru = 'Эта команда мне не известна'"), getKeyboard(pMessage.current_session.Employee));	
									EndIf;
								EndIf;									
							EndIf;									
						EndIf;
					EndIf;		
					Catalogs.ChatBots.SendNotification(pMessage.current_session.hotel);
				ElsIf pMessage.message_type = "callback_query" Then						
					ProcessCommandCallback(pMessage);		
				ElsIf pMessage.message_type = "photo"  Then						
					vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
					If ValueIsFilled(vContext) Then
						CreateTask(pMessage);
					EndIf;
				EndIf;
			#EndRegion
			#Region	ENGINEER
			ElsIf vPermissions = Enums.ChatRoles.Engineer Then
				// ==|| ENGINEER ||====================================================================================================================================================|
				If pMessage.message_type = "text" Then
					chatCommand = GetChatCommand(pMessage.data);
					If Not ValueIsFilled(pMessage.current_session.hotel) Then
						// Hotel choice
						If ValueIsFilled(vEmployee.Hotel) Then								
							vHotel = vEmployee.Hotel; 
						Else
							Hotels = GetHotelNumber(); 
							If Hotels.Count() > 1 Then
								vHotel = Catalogs.Hotels.FindByDescription(pMessage.data);
							Else
								
								vHotel = Hotels[0].Hotel;
							EndIf;								
						EndIf;							
						If ValueIsFilled(vHotel) Then
							pMessage.current_session.hotel = vHotel;
							EditCurrentSessions(pMessage);
							sendMessage(pMessage, getTaskList(pMessage.current_session.hotel, pMessage.current_session.Employee), getKeyboard(pMessage.current_session.Employee));	
						Else
							sendMessage(pMessage, NStr("en = 'Choose the hotel'; de = 'Wählen Sie das Hotel, wo Sie arbeiten werden'; ru = 'Выберите отель, в котором будете работать'"), getHotelKeyboard());
						EndIf;
					Else
						vRoom = GetRoom(pMessage.Data, pMessage.current_session.hotel); 					
						If ValueIsFilled(vRoom) Then 
							DeleteContext(pMessage.chat, , vOperationType, vOperationKey);
							pMessage.current_session.room = vRoom;
							EditCurrentSessions(pMessage);
							sendMessage(pMessage, Catalogs.ChatBots.GetEmoji("white down pointing backhand index"), getMenuKeyboard());								
							vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
							SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
						ElsIf chatCommand = "Bye" Then
							CloseCurrrentSessions(pMessage);
						ElsIf chatCommand = "Help" Then
							sendMessage(pMessage, GetHelpText(pMessage.current_session.employee), getKeyboard(pMessage.current_session.Employee));	
						ElsIf chatCommand = "Tasks" Or chatCommand = "Menu"  Then
							sendMessage(pMessage, getTaskList(pMessage.current_session.hotel, pMessage.current_session.Employee), getKeyboard(pMessage.current_session.Employee));								
						Else
							vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
							If ValueIsFilled(vContext) Then
								vTask = getTask(vContext);
								If ValueIsFilled(vTask) Then
									AddCommentToTask(pMessage, vTask);
								Else						
									CreateTask(pMessage);
								EndIf;	
							Else	
								vEmp = Undefined;
								Try
									vEmp = cmGetEmployeeByPBXAccountCode(Number(pMessage.Data));										
								Except
								EndTry;
								If Not ValueIsFilled(vEmp) Then
									sendMessage(pMessage, NStr("en = 'Unknown command'; de = 'Unbekannter Befehl'; ru = 'Эта команда мне не известна'"), getKeyboard(pMessage.current_session.Employee));	
								EndIf;									
							EndIf;								
						EndIf;
					EndIf;	
					Catalogs.ChatBots.SendNotification(pMessage.current_session.hotel);						
				ElsIf pMessage.message_type = "callback_query" Then						
					ProcessCommandCallback(pMessage);		
				ElsIf pMessage.message_type = "photo" Then						
					vContext = GetTempGlobalVlalue(pMessage.chat, vOperationType, vOperationKey);	
					If ValueIsFilled(vContext) Then
						CreateTask(pMessage);
					EndIf;
				EndIf;					
			EndIf;
			#EndRegion
		Else
			sendMessage(pMessage, NStr("ru='Не установлена роль!';en='Chat role is not set yet!';de='Chat-Rolle ist noch nicht festgelegt!'"));	
		EndIf;
	EndIf;
EndProcedure // ProcessCommand

// -----------------------------------------------------------------------------
Procedure ProcessCommandCallback(pMessage)
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True); 
	vCommand = vOperationData[0];
	If StrFind(vCommand, "Cons") Then
		If pMessage.Bot.UseConsumption Then 
			If StrFind(vCommand, "New") Then
				NewConsumption(pMessage);
			Else
				Consumption(pMessage);
			EndIf;	
		Else 
			updateMessage(pMessage, NStr("en = 'The ""Consumption"" module is currently disabled!'; de = 'Momentan ist das Modul ""Verbrauch "" deaktiviert!'; ru = 'На данный момент модуль ""Расход"" отключен!'"));
		EndIf;
	ElsIf StrFind(vCommand, "Room") Then 	
		Room(pMessage);		
	ElsIf StrFind(vCommand, "Bar") Then 
		If pMessage.Bot.UseMiniBar Then 		
			MiniBar(pMessage);	
		Else 
			updateMessage(pMessage, NStr("en = 'The ""Mini-bar"" module is currently disabled!'; de = 'Im Moment ist das Modul ""Minibar "" deaktiviert!'; ru = 'На данный момент модуль ""Мини-бар"" отключен!'"));
		EndIf;
	ElsIf StrFind(vCommand, "Task") Then	
		Task(pMessage);		
	ElsIf StrFind(vCommand, "Status") Then	
		vTable = GetTempTable(pMessage.chat, pMessage.message_id, "Statuses");
		vTebleCount = vTable.Count();
		If vTebleCount = 1 Then
			vStatuses = GetRoomStatus(pMessage.current_session.hotel, vTable[0].Key);
			vCurrentPage = Number(vTable[0].Value);
			vTotalRoom = RoomStatusList(pMessage.current_session.hotel, vStatuses, False, pMessage.current_session.section).Count();
			vPages = Int(vTotalRoom / 30) + ?(vTotalRoom % 30 <> 0, 1, 0);
			If vOperationData[1] = "NexPage" Then
				If vCurrentPage >= vPages Then 
					vNextPage = 1;
				Else
					vNextPage = vCurrentPage + 1;
				EndIf;				
				updateMessage(pMessage, RoomStatusList(pMessage.current_session.hotel, vStatuses, , pMessage.current_session.section, vNextPage), getRoomSwichKeyboard());	
				DeleteContext(pMessage.chat, pMessage.Message_id, "Statuses", vStatuses);
				SetContext(pMessage.chat, pMessage.Message_id, "Statuses", vStatuses, vNextPage);
			ElsIf vOperationData[1] = "PrevPage" Then
				If vCurrentPage <= 1 Then 
					vNextPage = vPages;
				Else
					vNextPage = vCurrentPage - 1;
				EndIf;	
				updateMessage(pMessage, RoomStatusList(pMessage.current_session.hotel, vStatuses, , pMessage.current_session.section, vNextPage), getRoomSwichKeyboard());	
				DeleteContext(pMessage.chat, pMessage.Message_id, "Statuses", vStatuses);
				SetContext(pMessage.chat, pMessage.Message_id, "Statuses", vStatuses, vNextPage);
			EndIf;
		EndIf;
	EndIf;	
EndProcedure // ProcessCommandCallback

// -----------------------------------------------------------------------------
Function ProcessBotReply(pData, pBot)
	Try		
		vResult = StringToStruct(pData);	
		If Not vResult.ok Then
			Return Null;
		EndIf;	
		vMessage = GetInfoStruct(vResult.result, pBot);
		RegisterMessage(vMessage, True);
		Return vMessage.Message_id; 
	Except
		vError = ErrorDescription();	
		WriteLogEvent("Chat bot error", EventLogLevel.Error, , CurrentSessionDate(), vError);
	EndTry;  
	Return "";
EndFunction // ProcessBotReply

// -----------------------------------------------------------------------------
Procedure RegisterMessage(pMessage, pIsProcessed = False)
	vTm = InformationRegisters.ChatBotUpdates.CreateRecordManager();	
	vTm.chat = pMessage.chat;
	vTm.message_id = pMessage.message_id;
	If pMessage.Property("update_id") Then
		vTm.update_id = pMessage.update_id;
		vTm.messageSender = Enums.MessageSender.User;		
	Else
		vTm.messageSender = Enums.MessageSender.Bot;
	EndIf;
	vTm.isProcessed  = True;
	vTm.message_type = pMessage.message_type;
	vTm.Date = pMessage.message_date;
	If pMessage.message_type = "text" Then 	
		vTm.text = pMessage.data;	
	ElsIf pMessage.message_type = "callback_query" Then
		vTm.Date = pMessage.callback_time;
		vTm.text = pMessage.data;
	EndIf;	
	vTm.Write();	
EndProcedure // RegisterMessage

// -----------------------------------------------------------------------------
Function GetInfoStruct(Result, Bot)
	MessageInfo = New Structure;	
	vText = "";	
	If Result.Property("update_id") Then
		UpdateUpdateID(Bot, Result.update_id);
		MessageInfo.Insert("update_id",  Result.update_id);		
		
		dBagText = NStr("en = ' The message is received: '; de = ' Die Nachricht wird empfangen: '; ru = ' Сообщение получено: '");
	Else
		dBagText = NStr("en = ' Message sent: '; de = ' Nachricht gesendet: '; ru = ' Сообщение отправлено: '");
	EndIf;		
	If Result.Property("callback_query") Then
		vMessageType = "callback_query";
		Result       = Result.callback_query;
		vData        = StrReplace(Result.data, "'", "");	
		MessageInfo.Insert("callback_time", CurrentSessionDate());
		dBagText = dBagText + NStr("en = 'Inline button response '; de = 'Inline-Taste Antwort '; ru = 'Ответ inline кнопки '") + vData;
		Result = Result.Message;	
	ElsIf Result.Property("edited_message") Then
		Result = Result.edited_message;		
		If Result.Property("sticker") Then
			vMessageType = "sticker";
			vData        = Result.sticker;
			dBagText = dBagText + NStr("ru='Стикер ';en='Sticker ';de='Aufkleber '") + Result.sticker.emoji;
		ElsIf Result.Property("location") Then 
			vMessageType = "location";	
			vData        = Result.location;
			dBagText = dBagText + NStr("en = 'Cordinates: Latitude('; de = 'Kordinate: Breite('; ru = 'Координаты: Широта('") + Result.location.latitude + NStr("ru=') Долгота(';en=') Longitude (';de=') Längengrad ('") + Result.location.longitude + ")";
		ElsIf Result.Property("contact") Then
			vMessageType = "contact";	
			vData        = Result.location;		
			dBagText = dBagText + NStr("en='Contact '; ru='Контакт '; de='Kontakt '");
		ElsIf Result.Property("voice") Then
			vMessageType = "voice";	
			dBagText = dBagText + NStr("ru='Голосовое сообщение ';en='Voice message ';de='Sprachnachricht '") + Result.voice.duration;
		ElsIf Result.Property("photo") Then
			vMessageType = "photo";	
			vData        = Result.photo;	
			dBagText = dBagText + NStr("ru='Фото ';de='Foto ';en='Photo '");
			If Result.Property("caption") Then
				MessageInfo.Insert("caption", Result.caption);	
			EndIf;			
		ElsIf Result.Property("document") Then
			vMessageType = "document";	
			vData        = Result.document;	
			dBagText = dBagText + NStr("en='Document '; ru='Документ '; de='Dokument '");
		ElsIf Result.Property("text", vText) Then
			vMessageType = "text";
			vData        = vText;
			dBagText = dBagText + Chars.LF + Result.text;
		EndIf;
	ElsIf Result.Property("Message") Then
		Result = Result.Message;		
		If Result.Property("sticker") Then
			vMessageType = "sticker";
			vData        = Result.sticker;
			dBagText = dBagText + NStr("en = 'Sticker '; de = 'Aufkleber '; ru = 'Стикер '") + Result.sticker.emoji;
		ElsIf Result.Property("location") Then 
			vMessageType = "location";	
			vData        = Result.location;
			dBagText = dBagText + NStr("en = 'Cordinates: Latitude('; de = 'Kordinate: Breite('; ru = 'Координаты: Широта('") + Result.location.latitude + NStr("ru=') Долгота(';en=') Longitude (';de=') Längengrad ('") + Result.location.longitude + ")";
		ElsIf Result.Property("contact") Then
			vMessageType = "contact";	
			vData        = Result.location;		
			dBagText = dBagText + NStr("en='Contact '; ru='Контакт '; de='Kontakt '");
		ElsIf Result.Property("voice") Then
			vMessageType = "voice";	
			dBagText = dBagText + NStr("en = 'Voice message '; de = 'Sprachnachricht '; ru = 'Голосовое сообщение '") + Result.voice.duration;
		ElsIf Result.Property("photo") Then
			vMessageType = "photo";	
			vData        = Result.photo;	
			dBagText = dBagText + NStr("en = 'Photo '; de = 'Foto '; ru = 'Фото '");
			If Result.Property("caption") Then
				MessageInfo.Insert("caption", Result.caption);	
			EndIf;			
		ElsIf Result.Property("document") Then
			vMessageType = "document";	
			vData        = Result.document;	
			dBagText = dBagText + NStr("en = 'Document '; de = 'Dokument '; ru = 'Документ '");
		ElsIf Result.Property("text", vText) Then
			vMessageType = "text";
			vData        = vText;
			dBagText = dBagText + Chars.LF + Result.text;
		EndIf;
	Else
		If Result.Property("sticker") Then
			vMessageType = "sticker";
			vData        = Result.sticker;
			dBagText = dBagText + NStr("en = 'Sticker '; de = 'Aufkleber '; ru = 'Стикер '") + Result.sticker.emoji;
		ElsIf Result.Property("location") Then 
			vMessageType = "location";	
			vData        = Result.location;
			dBagText = dBagText + NStr("en = 'Cordinates: Latitude('; de = 'Kordinate: Breite('; ru = 'Координаты: Широта('") + Result.location.latitude + NStr("en = ') Longitude ('; de = ') Längengrad ('; ru = ') Долгота('") + Result.location.longitude + ")";
		ElsIf Result.Property("contact") Then
			vMessageType = "contact";	
			vData        = Result.location;		
			dBagText = dBagText + NStr("en = 'Contact '; de = 'Kontakt '; ru = 'Контакт '");
		ElsIf Result.Property("voice") Then
			vMessageType = "voice";	
			dBagText = dBagText + NStr("en = 'Voice message '; de = 'Sprachnachricht '; ru = 'Голосовое сообщение '") + Result.voice.duration;
		ElsIf Result.Property("photo") Then
			vMessageType = "photo";	
			vData        = Result.photo;	
			dBagText = dBagText + NStr("en = 'Photo '; de = 'Foto '; ru = 'Фото '");
		ElsIf Result.Property("document") Then
			vMessageType = "document";	
			vData        = Result.document;	
			dBagText = dBagText + NStr("en = 'Document '; de = 'Dokument '; ru = 'Документ '");
		ElsIf Result.Property("text", vText) Then
			vMessageType = "text";
			vData        = vText;
			dBagText = dBagText + Chars.LF + Result.text;
		EndIf;		
	EndIf;	     
	vDateOld = Date(1970, 1, 1, 3, 0, 0);
	MessageInfo.Insert("message_type",   vMessageType);
	MessageInfo.Insert("data",           vData);	
	MessageInfo.Insert("bot",      		 Bot);		
	vChat = Catalogs.Chats.FindByAttribute("chat_id", Result.chat.id);
	If Not ValueIsFilled(vChat) Then	
		vChat = CreateChat(Result.chat.id,Bot);
	EndIf;
	MessageInfo.Insert("chat",           vChat);
	MessageInfo.Insert("from",           Result.from);
	MessageInfo.Insert("message_date",   vDateOld + Result.date);
	MessageInfo.Insert("message_id",     Result.message_id); 
	
	// Log event
	WriteLogEvent("Register chat bot message", EventLogLevel.Information, , CurrentSessionDate(), String(vDateOld + Result.date) + Chars.LF + "Bot: " + Bot + Chars.LF + "Chat: " + vChat + Chars.LF + dBagText);

	Return MessageInfo;	
EndFunction // GetInfoStruct

// -----------------------------------------------------------------------------
Function CreateChat(pChat_id, pBot)
	vChat = Catalogs.Chats.CreateItem();
	vChat.chat_id          = pChat_id;
	vChat.bot              = pbot;
	vChat.session_lifetime = pbot.session_lifetime;
	vChat.Description      = String(pbot) + " - " + pChat_id;
	vChat.Write();
	Return vChat.Ref;	
EndFunction // CreateChat

// -----------------------------------------------------------------------------
Function StringToStruct(pText)
	Try
		JSONReader = New JSONReader();
		JSONReader.SetString(pText);	
		Result = ReadJSON(JSONReader);	
		JSONReader.Close();	
	Except
		WriteLogEvent("ChatStringToStruct", EventLogLevel.Error, , CurrentSessionDate(), pText);
		Result = New Structure("ok", False);
	EndTry;
	Return Result;
EndFunction // StringToStruct

// -----------------------------------------------------------------------------
Function StructToString(pStructure)
	vText = "";
	For Each vRow In pStructure Do 
		If TypeOf(vRow.Value) = TypeOf(pStructure) Then
			vText = vText +	StructToString(vRow.Value);
		Else
			vText = vText +	vRow.Key + ": " + vRow.Value + Chars.LF;
		EndIf;
	EndDo;
	Return vText;
EndFunction // StructToString

#EndRegion

#Region Authorisation

// -----------------------------------------------------------------------------
Function BotAuthorisation(pMessage)
	If pMessage.Chat.isActive Then
		Try
			vCode = Number(pMessage.data);
		Except	
			vCode = Null;
		EndTry;
		vEmployee = cmGetEmployeeByPBXAccountCode(vCode);
		If ValueIsFilled(vEmployee) Then
			OpenNewSession(pMessage, vEmployee);
			Return vEmployee;
		Else
			vEmployee = GetCurrentSession(pMessage);
			If ValueIsFilled(vEmployee) Then
				Return vEmployee;
			Else		
				vReplyText = Catalogs.ChatBots.GetEmoji("no entry sign") + NStr("en = 'No access. Enter your code'; de = 'Kein Zugang. Geben Sie Ihren code ein'; ru = 'Нет доступа. Представьтесь пожалуйста.'") 
				+ "%0D%0A"
				+ NStr("en = 'Enter your personal code'; de = 'Geben Sie Ihren persönlichen code'; ru = 'Персональный код?'");				
			EndIf;
		EndIf;
		sendMessage(pMessage, vReplyText);
		Return vEmployee;	
	Else 
		If pMessage.message_type = "text" Then
			If pMessage.bot.MasterPassword = pMessage.data Then
				vChat = pMessage.Chat.GetObject();
				vChat.isActive = True;
				vChat.Write();
				
				vReplyText = NStr("en = 'Welcome! Your device is authorized'; de = 'Willkommen! Ihr Gerät ist autorisiert'; ru = 'Добро пожаловать. Вашему устройству предоставлен доступ.'") 
					+ "%0D%0A"
				 	+ NStr("en = 'Enter your personal code'; de = 'Geben Sie Ihren persönlichen code'; ru = 'Введите персональный код?'");				
			Else
				vReplyText = Catalogs.ChatBots.GetEmoji("no entry sign") + " " + NStr("en = 'This device is unknown to me. I will not do anything.'; de = 'Dieses Gerät ist mir unbekannt. Ich werde nichts tun.'; ru = 'Это устройство мне неизвестно. Ничего не буду делать.'");							
			EndIf;
		Else
			vReplyText = Catalogs.ChatBots.GetEmoji("no entry sign") + " " + NStr("en = 'This device is unknown to me. I will not do anything.'; de = 'Dieses Gerät ist mir unbekannt. Ich werde nichts tun.'; ru = 'Это устройство мне неизвестно. Ничего не буду делать.'");	
		EndIf;		
		sendMessage(pMessage, vReplyText);
		Return Catalogs.Employees.EmptyRef(); 
	EndIf;	
EndFunction // BotAuthorisation

// -----------------------------------------------------------------------------
Procedure OpenNewSession(pMessage, pEmployee)
	vEmployee = GetCurrentSession(pMessage);
	If Not vEmployee = pEmployee Then 
		DeleteContext(pMessage.chat, , "ChatContext");
		If ValueIsFilled(vEmployee) Then
			CloseCurrrentSessions(pMessage);
		EndIf;
		vRecordManager = InformationRegisters.ChatAuthorisation.CreateRecordManager();
		vCurrentDate                 = CurrentSessionDate();				
		vRecordManager.Period        = vCurrentDate;
		vRecordManager.chat          = pMessage.Chat;  
		vRecordManager.session_start = vCurrentDate; 
		vRecordManager.Employee      = pEmployee;
		vRecordManager.hotel         = ?(ValueIsFilled(pEmployee.Hotel), pEmployee.Hotel, Catalogs.Hotels.EmptyRef());
		vRecordManager.Write();
		vCurrentSession = New Structure;
		vCurrentSession.Insert("employee",     pEmployee);
		vCurrentSession.Insert("session_start", vCurrentDate);
		vCurrentSession.Insert("hotel",        ?(ValueIsFilled(pEmployee.Hotel), pEmployee.Hotel, Catalogs.Hotels.EmptyRef()));
		vCurrentSession.Insert("room",         Catalogs.Rooms.EmptyRef());
		vCurrentSession.Insert("section",      Catalogs.RoomSections.EmptyRef());
		
		pMessage.Insert("current_session", vCurrentSession);				
		vReplyText = Hello() + ?(IsBlankString(pEmployee.FirstName), ", " + TrimAll(pEmployee), ", " + pEmployee.FirstName) + "!";	
		sendMessage(pMessage, vReplyText);
		
		vEmployee = pEmployee;
	EndIf;
	vPermissions = vEmployee.PermissionGroup.ChatRole;
	If vPermissions = Enums.ChatRoles.Maid Then
		sendMessage(pMessage, GetRoomListMessage(pMessage), getKeyboard(vEmployee));
	ElsIf vPermissions = Enums.ChatRoles.Supervisor Then
		sendMessage(pMessage, RoomStatusList(pMessage.current_session.hotel, pMessage.current_session.hotel.RoomStatusInspection), getKeyboard(vEmployee));
	ElsIf vPermissions = Enums.ChatRoles.Engineer Then
		sendMessage(pMessage, getTaskList(pMessage.current_session.hotel, pMessage.current_session.Employee), getKeyboard(vEmployee));	
	EndIf;
EndProcedure // OpenNewSession

// -----------------------------------------------------------------------------
Function GetCurrentSession(pMessage)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChatAuthorisationSliceLast.employee AS employee,
	|	ChatAuthorisationSliceLast.session_start AS session_start,
	|	ChatAuthorisationSliceLast.hotel AS hotel,
	|	ChatAuthorisationSliceLast.room AS room,
	|	ChatAuthorisationSliceLast.sessions_stop AS sessions_stop,
	|	ChatAuthorisationSliceLast.section AS section
	|FROM
	|	InformationRegister.ChatAuthorisation AS ChatAuthorisationSliceLast
	|WHERE
	|	ChatAuthorisationSliceLast.chat = &qchat
	|
	|ORDER BY
	|	session_start DESC";
	Query.SetParameter("qchat", pMessage.Chat);	
	QueryResult = Query.Execute();	
	SelectionDetailRecords = QueryResult.Select();
	If SelectionDetailRecords.Next() Then
		If Not ValueIsFilled(SelectionDetailRecords.sessions_stop) Then
			vSessions_duration = (CurrentSessionDate() - SelectionDetailRecords.session_start) / 60 / 60;
			If vSessions_duration < pMessage.chat.session_lifetime Or pMessage.chat.session_lifetime = 0 And vSessions_duration < 24 Then
				vCurrentSession = New Structure;
				vCurrentSession.Insert("employee", SelectionDetailRecords.employee);
				vCurrentSession.Insert("session_start", SelectionDetailRecords.session_start);
				vCurrentSession.Insert("hotel", SelectionDetailRecords.hotel);
				vCurrentSession.Insert("room", SelectionDetailRecords.room);
				vCurrentSession.Insert("section", SelectionDetailRecords.section);	
				pMessage.Insert("current_session", vCurrentSession);
				Return SelectionDetailRecords.employee;
			Else
				vRecordSet = InformationRegisters.ChatAuthorisation.CreateRecordSet();
				vRecordSet.Filter.chat.Set(pMessage.chat);
				vRecordSet.Filter.employee.Set(SelectionDetailRecords.employee);	
				vRecordSet.Filter.session_start.Set(SelectionDetailRecords.session_start);	
				vRecordSet.Read();
				vCurrentSessions = vRecordSet[0];
				vCurrentSessions.sessions_stop = CurrentSessionDate();
				vRecordSet.Write();
				Return Null;
			EndIf;
		EndIf;
	EndIf;
EndFunction // GetCurrentSession

// -----------------------------------------------------------------------------
Function GetHotelNumber()
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Hotels.Ref AS Hotel
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder";
	vQueryResult = vQuery.Execute();
	Return vQueryResult.Unload();
EndFunction // GetHotelNumber

#EndRegion

#Region Supervisor

// -----------------------------------------------------------------------------
// Returns Room Status by name
Function GetRoomStatus(pHotel, pStatusName)
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	RoomStatuses.Ref AS Ref
	|FROM
	|	Catalog.RoomStatuses AS RoomStatuses
	|WHERE
	|	RoomStatuses.Description = &qDescription
	|	AND NOT RoomStatuses.DeletionMark
	|	AND (RoomStatuses.Hotel = &qHotel
	|			OR RoomStatuses.Hotel = &qEmptyHotel)";
	vQ.SetParameter("qDescription", TrimAll(pStatusName));
	vQ.SetParameter("qHotel", pHotel);
	vQ.SetParameter("qEmptyHotel", Catalogs.Hotels.EmptyRef());
	
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.Ref;
	EndIf;
	Return Catalogs.RoomStatuses.EmptyRef(); 
EndFunction // GetRoomStatus

// -----------------------------------------------------------------------------
Function RoomStatusList(pHotel, pStatus, pReturnText = True, pSection = Undefined, pList = 1)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND Rooms.RoomStatus = &RoomStatus
	|	AND Rooms.Owner = &Owner
	|	";
	If ValueIsFilled(pSection) Then
		vQuery.Text = vQuery.Text + 
		"AND Rooms.RoomSection = &RoomSection
		|	";
		vQuery.SetParameter("RoomSection", pSection);		
	EndIf;
	vQuery.Text = vQuery.Text + 
	"ORDER BY
	|	Rooms.SortCode";	
	vQuery.SetParameter("RoomStatus", pStatus);
	vQuery.SetParameter("Owner", pHotel);
	QueryResult = vQuery.Execute();
	If pReturnText Then
		NumberTo   = pList * 30;
		NumberFrom = NumberTo - 30;

		SelectionDetailRecords = QueryResult.Select();
		vTotalRoom = SelectionDetailRecords.Count();
		vPages = Int(vTotalRoom / 30) + ?(vTotalRoom % 30 <> 0, 1, 0);

		vText = "";
		
		If SelectionDetailRecords.Count() = 0 Then			
			vText = StrTemplate(NStr("en = 'No rooms in status <b>%1</b>'; de = 'Keine Zimmer im Status <b>%1</b>'; ru = 'Нет номеров в статусе <b>%1</b>'"), pStatus);		
		Else   
			vMsg = NStr("en = 'Rooms in status <b>%1</b> in the hotel <b>%2</b>'; 
						|de = 'Zimmer im Status <b>%1</b> im Hotel <b>%2</b>'; 
						|ru = 'Номера в статусе <b>%1</b>  в отеле <b>%2</b>'");
			vText = StrTemplate(vMsg, pStatus, pHotel) + "%0D%0A";
			vNumber = 0;
			
			While SelectionDetailRecords.Next() Do
				If vNumber >= NumberFrom And vNumber <= NumberTo Then
					vText = vText + Catalogs.ChatBots.GetRoomText(SelectionDetailRecords.Ref, False, True, False, False) + "%0D%0A";
				EndIf;
				vNumber = vNumber + 1;
			EndDo;
		EndIf;	
		Return vText + ?(vPages <= 1, "", String(pList) + "/" + vPages);
	Else
		Return QueryResult.Unload();
	EndIf;
EndFunction // RoomStatusList

// -----------------------------------------------------------------------------
Function getInLineKeyboardForRoomSuper(pMessage, pRoom = Undefined)
	If pRoom = Undefined Then		
		pRoom = pMessage.current_session.room;		
	EndIf;	
	vBaseArray = New Array;	
	vRoomFunc = "Room:";	
	vInspec = False;	
	vOperations = GetCurrentOperationsOnInspections(pRoom);
	For Each vOperationRow In vOperations Do
		If vOperationRow.Room = pRoom Then
			vKeys = New Array;
			vKeys.Add(getInLineButton(NStr("en = 'Accept work'; de = 'Arbeit annehmen'; ru = 'Принять работу'"), TrimAll(vRoomFunc + "AcceptWork")));
			vBaseArray.Add(vKeys);	
			vKeys = New Array;
			vKeys.Add(getInLineButton(NStr("en = 'Return to work'; de = 'Zurück zur Arbeit'; ru = 'Вернуть в работу'"), TrimAll(vRoomFunc + "CancelWork")));
			vBaseArray.Add(vKeys);	
			
			vInspec = True;
			Break;
		EndIf;
	EndDo;
	
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	PermissionGroupsRoomStatusesAllowed.RoomStatus.Code AS RoomStatusCode,
	|	PermissionGroupsRoomStatusesAllowed.RoomStatus.Description AS RoomStatus
	|FROM
	|	Catalog.PermissionGroups.RoomStatusesAllowed AS PermissionGroupsRoomStatusesAllowed
	|		INNER JOIN Catalog.RoomStatuses.TransitionsAllowed AS RoomStatusesTransitionsAllowed
	|		ON PermissionGroupsRoomStatusesAllowed.RoomStatus = RoomStatusesTransitionsAllowed.RoomStatus
	|WHERE
	|	PermissionGroupsRoomStatusesAllowed.Ref = &qPG
	|	AND RoomStatusesTransitionsAllowed.Ref = &qCurrentStatus";	
	vQuery.SetParameter("qCurrentStatus", pRoom.RoomStatus);
	vQuery.SetParameter("qPG", pMessage.current_session.employee.PermissionGroup);
	vQueryResult = vQuery.Execute();	
	vSelectionDetailRecords = vQueryResult.Select();
	
	If Not vInspec Then
		While vSelectionDetailRecords.Next() Do
			vKeys = New Array;
			vKeys.Add(getInLineButton(vSelectionDetailRecords.RoomStatus, TrimAll(vRoomFunc + vSelectionDetailRecords.RoomStatusCode)));		
			vBaseArray.Add(vKeys);
		EndDo;
	EndIf;
	
	vOperations = Catalogs.ChatBots.GetCurrentOperations(pRoom);
	For Each vOperationRow In vOperations Do
		If vOperationRow.Room = pRoom Then
			vEmployeeList = Catalogs.ChatBots.GetAutorizaitingEmployee(pRoom.Owner, Enums.ChatRoles.Maid);
			If vEmployeeList.Count() > 0 Then
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Assign an employee'; de = 'Mitarbeiter ernennen'; ru = 'Назначить сотрудника'"), TrimAll(vRoomFunc + "SetEmployee")));
				vBaseArray.Add(vKeys);	
			EndIf;
			Break;
		EndIf;
	EndDo;
	vOperations = Catalogs.ChatBots.GetCurrentOperations(pRoom, pMessage.current_session.Employee);	
	If vOperations.Count() > 0 Then
		If pMessage.bot.UseConsumption Then
			vKeys = New Array;
			vKeys.Add(getInLineButton(NStr("en = 'Consumption'; de = 'Verbrauch'; ru = 'Расход'"), TrimAll(vRoomFunc + "Consumption")));
			vBaseArray.Add(vKeys);		
		EndIf;
	EndIf;
	
	If pMessage.bot.UseMiniBar Then
		If cmGetRoomGuests(pRoom.Owner, Undefined, pRoom, CurrentSessionDate(), CurrentSessionDate()).Count() > 0 Then	
			vKeys = New Array;
			vKeys.Add(getInLineButton(NStr("en = 'Mini-bar'; de = 'Mini-bar'; ru = 'Мини-бар'"), TrimAll(vRoomFunc + "MiniBar")));
			vBaseArray.Add(vKeys);
		EndIf;		
	EndIf;  
	If pMessage.bot.UseConsumption Then 
		vOperations = GetLastOperation(pMessage, pRoom, pMessage.current_session.Employee);
		For Each vOperationRow In vOperations Do
			If vOperationRow.Room = pRoom Then
				vQuantity = 0;
				For Each vRow In vOperationRow.Ref.Articles Do
					If vRow.Article.UseForChatBot Then
						vQuantity = vQuantity + vRow.Quantity;
					EndIf;						
				EndDo; 
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Consumption'; de = 'Verbrauch'; ru = 'Расход'") + ?(vQuantity <> 0, " (" + vQuantity + ")", ""), TrimAll(vRoomFunc + "Consumption")));
				vBaseArray.Add(vKeys);
				Break;
			EndIf;
		EndDo;	
	EndIf;

	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("en = 'Malfunction'; de = 'Fehlfunktion'; ru = 'Неисправность'"), TrimAll(vRoomFunc + "Task")));
	vBaseArray.Add(vKeys);
	
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // GetInLineKeyboardForRoomSuper

// -----------------------------------------------------------------------------
Function EmployeeList(pHotel, pChatRole)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	MainTable.chat AS chat,
	|	MainTable.session_start AS session_start,
	|	MainTable.employee AS employee,
	|	MainTable.hotel AS hotel,
	|	MainTable.room AS room,
	|	MainTable.employee.PermissionGroup.ChatRole AS chat_role,
	|	MainTable.CurrentLifeTime AS current_life_time
	|FROM
	|	(SELECT
	|		current_sessions.chat AS chat,
	|		current_sessions.session_start AS session_start,
	|		ChatAuthorisation.employee AS employee,
	|		DATEDIFF(current_sessions.session_start, &qCurrentDate, MINUTE) AS CurrentLifeTime,
	|		ChatAuthorisation.hotel AS hotel,
	|		ChatAuthorisation.room AS room
	|	FROM
	|		(SELECT
	|			ChatAuthorisation.chat AS chat,
	|			MAX(ChatAuthorisation.session_start) AS session_start
	|		FROM
	|			InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|		WHERE
	|			ChatAuthorisation.sessions_stop < ChatAuthorisation.session_start
	|		
	|		GROUP BY
	|			ChatAuthorisation.chat) AS current_sessions
	|			LEFT JOIN InformationRegister.ChatAuthorisation AS ChatAuthorisation
	|			ON (ChatAuthorisation.chat = current_sessions.chat)
	|				AND (ChatAuthorisation.session_start = current_sessions.session_start)) AS MainTable
	|WHERE
	|	(MainTable.CurrentLifeTime <= MainTable.chat.session_lifetime * 60
	|			OR MainTable.chat.session_lifetime = 0
	|				AND MainTable.CurrentLifeTime <= 24 * 60)
	|	AND MainTable.employee.PermissionGroup.ChatRole = &qChatRole
	|	AND MainTable.hotel = &qHotel";
	vQuery.SetParameter("qChatRole", pChatRole);
	vQuery.SetParameter("qHotel", pHotel);
	vQuery.SetParameter("qCurrentDate", CurrentSessionDate());
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	If vSelectionDetailRecords.Count() = 0 Then
		vText = NStr("en = '<b>No employees in the network</b>'; de = '<b>Keine Mitarbeiter im Netz</b>'; ru = '<b>В сети нет сотрудников</b>'") + "%0D%0A";
	Else
		vText = NStr("en = '<b>Maids list</b>'; de = '<b>Zimmermädchen Liste</b>'; ru = '<b>Список горничных</b>'") + "%0D%0A";
		While vSelectionDetailRecords.Next() Do
			vText = vText + Catalogs.ChatBots.GetEmoji("princess") + "<b>" + vSelectionDetailRecords.employee + "</b> " + vSelectionDetailRecords.room + "%0D%0A";
		EndDo;
	EndIf;
	
	Return vText;
EndFunction // EmployeeList

#EndRegion

#Region Housekeep

// -----------------------------------------------------------------------------
Procedure Room(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True);
	vRoom = GetRoomFromContext(pMessage);
	vOperations = GetLastOperation(pMessage, vRoom, pMessage.current_session.Employee);
	If Not vOperations.Count() = 0 Or pMessage.current_session.employee.PermissionGroup.ChatRole <> Enums.ChatRoles.Maid Then
		If vOperationData[1] = "MiniBar" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + "<b>" + NStr("en = 'Mini-bar'; de = 'Mini-bar'; ru = 'Мини-бар'") + "</b>", getInLineKeyboardForMiniBarMenu(pMessage.Bot));			
		ElsIf vOperationData[1] = "Task" Then
			vReplyText = "<b>" + NStr("en = 'What`s happened? What is the issue?'; de = 'Was funktioniert nicht im Zimmer?'; ru = 'Что случилось? Что не работает в номере?'") + "</b>";
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + vReplyText, getPredifineTask(pMessage.bot));		
			SetContext(pMessage.chat, pMessage.Message_id, "ChatContext", "Task", "NewTask:" + vRoom);
		ElsIf vOperationData[1] = "Consumption" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + NStr( "en = 'Consumption'; de = 'Nomenklaturaufwand'; ru = 'Расход номенклатуры'") + "%0D%0A" +
			GetArticleTableForDocument(vRoom, pMessage) + "<b>" + NStr("en = 'Select item'; de = 'Wählen Sie eine Nomenklatur aus'; ru = 'Выберите номенклатуру'") + "</b>", getInLineKeyboardForArticles(vRoom, pMessage));
		ElsIf vOperationData[1] = "SetEmployee" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + NStr("en = 'Whom to assign?'; de = 'Wen soll ich ernennen?'; ru = 'Кого назначить?'"), getInLineKeyboardForAuthEmployee(vRoom.Owner));
		ElsIf vOperationData[1] = "AcceptWork" Then
			vOperations = GetCurrentOperationsOnInspections(vRoom);
			For Each vOperationRow In vOperations Do
				If vOperationRow.Room = vRoom Then
					vRoomObj = vRoom.GetObject();
					If ValueIsFilled(vRoomObj.RoomStatus.NextRoomStatus) Then
						vRoomObj.RoomStatus = vRoomObj.RoomStatus.NextRoomStatus;
					Else
						vRoomObj.RoomStatus = pMessage.current_session.hotel.VacantRoomStatus;		
					EndIf;
					vRoomObj.Write();
					vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), pMessage.current_session.Employee, "via Bot");
					
					vObject = vOperationRow.Ref.GetObject();
					vObject.OperationEndConfirmedTime = CurrentSessionDate();
					vObject.Write(DocumentWriteMode.Posting);
					
					updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
					
					Break;
				EndIf;
			EndDo;
		ElsIf vOperationData[1] = "CancelWork" Then
			vOperations = GetCurrentOperationsOnInspections(vRoom);
			For Each vOperationRow In vOperations Do
				If vOperationRow.Room = vRoom Then
					vRoomObj = vRoom.GetObject();
					
					// Get room previous status
					vPrevRoomStates = vRoomObj.pmGetRoomStatusHistoryState(CurrentSessionDate(), vRoomObj.RoomStatus);
					
					vObject = vOperationRow.Ref.GetObject();
					vObject.OperationEndTime = Undefined;
					vObject.Write(DocumentWriteMode.Posting);
					
					If vPrevRoomStates.Count() > 0 Then
						vPrevRoomState = vPrevRoomStates.Get(0);
						If ValueIsFilled(vPrevRoomState.RoomStatus) Then
							vRoomObj.RoomStatus = vPrevRoomState.RoomStatus;
							vRoomObj.Write();
							vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), pMessage.current_session.Employee, "via Bot", , True);
						EndIf;
					EndIf;
					
					Catalogs.ChatBots.AddNotification(vOperationRow.Ref, vRoom.Owner, vOperationRow.Ref.Employee, NStr("ru='Работа не принята';en='';de=''"), Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False, False, vOperationRow.Ref));	
					Catalogs.ChatBots.SendNotification(pMessage.current_session.Hotel, vOperationRow.Ref.Employee);					
					updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
					
					Break;
				EndIf;
			EndDo;
		ElsIf vOperationData[1] = "Empl" Then
			vTOperation = Catalogs.ChatBots.GetCurrentOperations(vRoom)[0].Ref;
			vEmployee = Catalogs.Employees.FindByCode(vOperationData[2]);
			If ValueIsFilled(vTOperation) And ValueIsFilled(vEmployee) Then
				vTOperationObject = vTOperation.GetObject();
				vTOperationObject.Employee = vEmployee;
				vTOperationObject.EmployeeAssignmentTime = CurrentSessionDate();
				vTOperationObject.Write(DocumentWriteMode.Posting);
			EndIf;	
			Catalogs.ChatBots.SendNotification(pMessage.current_session.hotel, vEmployee);
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		ElsIf vOperationData[1] = "TaskView" Then
			vTask = getTask(vOperationData[2]);
			updateMessage(pMessage,GetTaskText(vTask, False), getOpenTaskKeyboard(vTask));
		ElsIf vOperationData[1] = "OperationStart" Then
			For Each vOperationRow In vOperations Do
				If vOperationRow.Room = vRoom Then
					If Not ValueIsFilled(vOperationRow.OperationEndTime) Then 
						vRoomObj = vRoom.GetObject();
						If ValueIsFilled(vOperationRow.Operation.OperationsStart) Then 
							vRoomObj.RoomStatus = vOperationRow.Operation.OperationsStart;
						EndIf;
						
						vRoomObj.Write();
						vObject = vOperationRow.Ref.GetObject();
						vObject.OperationStartTime = CurrentSessionDate();
						vObject.Write(DocumentWriteMode.Posting);
					EndIf;
					updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
					
				EndIf;
			EndDo;
		ElsIf vOperationData[1] = "DoNotDisturb" Then
			For Each vOperationRow In vOperations Do
				If vOperationRow.Room = vRoom Then
					If Not ValueIsFilled(vOperationRow.OperationEndTime) Then 
						vObject = vOperationRow.Ref.GetObject();
						vObject.DoNotDisturbTime = CurrentSessionDate();
						vObject.Write(DocumentWriteMode.Posting);
					EndIf;
					updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
				EndIf;
			EndDo;
		ElsIf vOperationData[1] = "OperationFinish" Then
			For Each vOperationRow In vOperations Do
				If vOperationRow.Room = vRoom Then
					If Not ValueIsFilled(vOperationRow.OperationEndTime) Then 
						vRoomObj = vRoom.GetObject();
						If ValueIsFilled(vOperationRow.Operation.OperationsFinish) Then 
							vRoomObj.RoomStatus = vOperationRow.Operation.OperationsFinish;
						EndIf;
						vRoomObj.Write();
						vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), pMessage.current_session.Employee, "via Bot");
						
						vObject = vOperationRow.Ref.GetObject();
						vObject.OperationEndTime = CurrentSessionDate();
						vObject.Write(DocumentWriteMode.Posting);
						pMessage.current_session.room = Undefined;
						EditCurrentSessions(pMessage);	
						Catalogs.ChatBots.SendNotification(pMessage.current_session.Hotel, Enums.ChatRoles.Supervisor);
					EndIf;
					
					updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
				EndIf;
			EndDo;
		Else			
			vRoomObj = vRoom.GetObject();
			vRoomObj.RoomStatus = Catalogs.RoomStatuses.FindByCode(vOperationData[1]);
			vRoomObj.Write();
			vRoomObj.pmWriteToRoomStatusChangeHistory(CurrentSessionDate(), pMessage.current_session.Employee, "via Bot");
			vStatusTime = Catalogs.ChatBots.GetCurrentStatusTime(vRoom);			
			vReplyText = "" + Catalogs.ChatBots.GetEmoji("DOOR") + " <b>" + TrimAll(vRoom) + "</b> - " + TrimAll(vRoom.RoomStatus) + ?(IsBlankString(vStatusTime), "", NStr("ru=' c ';en=' from ';de=' von '") + vStatusTime);			
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		EndIf;
	Else	
		If vOperationData[1] = "Task" Then
			vReplyText = "<b>" + NStr("en = 'What happened? What does not work in the room?'; de = 'Was passierte? Was funktioniert nicht im Zimmer?'; ru = 'Что случилось? Что не работает в номере?'") + "</b>";
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + vReplyText, getPredifineTask(pMessage.bot));		
		SetContext(pMessage.chat, pMessage.Message_id, "ChatContext", "Task", "NewTask:" + vRoom);

		ElsIf vOperationData[1] = "NewConsumption" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + NStr( "en = 'Comsumption'; de = 'Nomenklaturaufwand'; ru = 'Расход номенклатуры'") + "%0D%0A" +
			GetArticleTableForDocumentNew(vRoom, pMessage) + "<b>" + NStr("en = 'Select item'; de = 'Wählen Sie eine Nomenklatur aus'; ru = 'Выберите номенклатуру'") + "</b>", getInLineKeyboardForArticlesNew(vRoom, pMessage));
		Else 
			updateMessage(pMessage, NStr("en = 'Operation with this room is not available!'; de = 'Operation mit dieser Zimmer ist nicht verfügbar!'; ru = 'Операция с этим номером недоступна!'") + "%0D%0A" + Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));	
		EndIf;
	EndIf;
EndProcedure // Room

// -----------------------------------------------------------------------------
Function GetAllStatusRoomListKeyboard(pHotel, pSection = Undefined)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT Rooms.Ref) AS Ref,
	|	Rooms.RoomStatus AS RoomStatus
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND Rooms.Owner = &qHotel
	|	";
	If ValueIsFilled(pSection) Then
		Query.Text = Query.Text + 
		"AND Rooms.RoomSection = &RoomSection
		|	";
		Query.SetParameter("RoomSection", pSection);		
	EndIf;
	Query.Text = Query.Text + 
	"GROUP BY
	|	Rooms.RoomStatus";
	Query.SetParameter("qHotel", pHotel);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	BaseArray = New Array;
	While SelectionDetailRecords.Next() Do
		Keys = New Array;
		Keys.Add(String(SelectionDetailRecords.RoomStatus));
		BaseArray.Add(Keys);		
	EndDo;
	Return ArrayToJSON(BaseArray);
EndFunction // GetAllStatusRoomListKeyboard

// -----------------------------------------------------------------------------
Function GetAllStatusRoomList(pHotel, pSection = Undefined)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	COUNT(DISTINCT Rooms.Ref) AS Ref,
	|	Rooms.RoomStatus AS RoomStatus
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	NOT Rooms.IsFolder
	|	AND NOT Rooms.DeletionMark
	|	AND Rooms.Owner = &qHotel
	|	";
	If ValueIsFilled(pSection) Then
		vQuery.Text = vQuery.Text + 
		"AND Rooms.RoomSection = &qRoomSection
		|	";
		vQuery.SetParameter("qRoomSection", pSection);		
	EndIf;
	vQuery.Text = vQuery.Text + 
	"GROUP BY
	|	Rooms.RoomStatus";
	vQuery.SetParameter("qHotel", pHotel);
	vQueryResult = vQuery.Execute();
	vRes = vQueryResult.Select();
	vText = "";
	While vRes.Next() Do
		vText = vText + "<b>[" + vRes.Ref  + "]</b> " + vRes.RoomStatus + " " + "%0D%0A";		
	EndDo;
	Return vText;
EndFunction // GetAllStatusRoomList

// -----------------------------------------------------------------------------
Procedure CreateTask(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vRoom = pMessage.current_session.room;
	vPhoto = Undefined;
	If pMessage.message_type = "text" Then		
		vText = pMessage.data;
		chatCommand = GetChatCommand(vText);
		If chatCommand = "Cancel" Or chatCommand = "Menu" Then
			vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
			SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
			
			Return;
		EndIf;
	ElsIf pMessage.message_type = "photo" Then	
		vText = GetTempRemarks(pMessage.chat, pMessage.message_id, "ChatContext", "Task");
		vPhotoId = pMessage.data[pMessage.data.Count() - 1].file_id;
		vPhoto = getPhoto(vPhotoId, pMessage.bot);
	EndIf;
	DeleteContext(pMessage.chat, , "ChatContext", "Task");
	vTask = SetTask(vRoom, vText, pMessage.current_session.employee, vPhoto, vPhotoId, pMessage);
	If ValueIsFilled(vTask) Then
		vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
	Else
		sendMessage(pMessage, NStr("en = 'Oops! An error has occurred!'; de = 'Hoppla! Ein Fehler ist aufgetreten!'; ru = 'Упс! Случилась ошибка!'"));
	EndIf;
EndProcedure // CreateTask

// -----------------------------------------------------------------------------
Function getInLineKeyboardForRoom(pMessage, pRoom = Undefined)
	vPermissions = pMessage.current_session.Employee.PermissionGroup.ChatRole;
	If vPermissions = Enums.ChatRoles.Maid Then
		vRes = getInLineKeyboardForRoomMaid(pMessage, pRoom);
	ElsIf vPermissions = Enums.ChatRoles.Supervisor Then
		vRes = getInLineKeyboardForRoomSuper(pMessage, pRoom);
	ElsIf vPermissions = Enums.ChatRoles.Engineer Then
		vRes = getInLineKeyboardForRoomEnginer(pMessage, pRoom);   
	Else
		vRes = Undefined;	
	EndIf;  
	
	Return vRes;
EndFunction // getInLineKeyboardForRoom

// -----------------------------------------------------------------------------
Function getInLineKeyboardForPhotoAttaching()
	BaseArray = New Array;	
	
	Keys = New Array;                               
	Keys.Add(getInLineButton(NStr("ru='Не прикреплять';en='Do not attach';de='Nicht anhängen'"), "noPhotoTask:DoNotAttachPhoto"));
	BaseArray.Add(Keys);
	
	Return ArrayToInLineJSON(BaseArray);
EndFunction // getInLineKeyboardForPhotoAttaching

// -----------------------------------------------------------------------------
Function getInLineKeyboardForRoomMaid(pMessage, pRoom = Undefined)
	If pRoom = Undefined Then		
		pRoom = pMessage.current_session.room;		
	EndIf;	
	
	vBaseArray = New Array;		
	
	vRoomFunc = "Room:";	
	
	vOperations = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee);
	For Each vOperationRow In vOperations Do
		If vOperationRow.Room = pRoom Then
			If Not ValueIsFilled(vOperationRow.OperationStartTime) Then
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Start cleaning'; de = 'Reinigung beginnen'; ru = 'Начать уборку'"), TrimAll(vRoomFunc + "OperationStart")));
				vBaseArray.Add(vKeys);
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Do not disturb'; de = 'Nicht stören'; ru = 'Не беспокоить'"), TrimAll(vRoomFunc + "DoNotDisturb")));
				vBaseArray.Add(vKeys);
			ElsIf ValueIsFilled(vOperationRow.OperationStartTime) And Not ValueIsFilled(vOperationRow.OperationEndTime) Then
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Finish cleaning'; de = 'Reinigung beenden'; ru = 'Закончить уборку'"), TrimAll(vRoomFunc + "OperationFinish")));
				vBaseArray.Add(vKeys);
			EndIf;
			
			If pMessage.bot.UseMiniBar Then
				If cmGetRoomGuests(pRoom.Owner, Undefined, pRoom, CurrentSessionDate(), CurrentSessionDate()).Count() > 0 Then	
					vKeys = New Array;
					vKeys.Add(getInLineButton(NStr("en = 'Mini-bar'; de = 'Mini-bar'; ru = 'Мини-бар'"), TrimAll(vRoomFunc + "MiniBar")));
					vBaseArray.Add(vKeys);
				EndIf;
			EndIf;
			
			If pMessage.bot.UseConsumption Then
				vQuantity = 0;
				For Each vRow In vOperationRow.Ref.Articles Do
					If vRow.Article.UseForChatBot Then
						vQuantity = vQuantity + vRow.Quantity;
					EndIf;						
				EndDo;
				
				vKeys = New Array;
				vKeys.Add(getInLineButton(NStr("en = 'Consumption'; de = 'Verbrauch'; ru = 'Расход'") + ?(vQuantity <> 0, " (" + vQuantity + ")", ""), TrimAll(vRoomFunc + "Consumption")));
				vBaseArray.Add(vKeys);		
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("en = 'Malfunction'; de = 'Fehlfunktion'; ru = 'Неисправность'"), TrimAll(vRoomFunc + "Task")));
	vBaseArray.Add(vKeys);
	
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // getInLineKeyboardForRoomMaid

// -----------------------------------------------------------------------------
Function getInLineKeyboardForAuthEmployee(pHotel)	
	vEmployeeList = Catalogs.ChatBots.GetAutorizaitingEmployee(pHotel, Enums.ChatRoles.Maid);	
	
	vBaseArray = New Array;	
	For Each vEmployeeRow In vEmployeeList Do
		vKeys = New Array;
		vKeys.Add(getInLineButton(String(vEmployeeRow.employee), TrimAll("Room:Empl:" + vEmployeeRow.employee.Code)));
		vBaseArray.Add(vKeys);	
	EndDo;
	
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // getInLineKeyboardForAuthEmployee

// -----------------------------------------------------------------------------
Function GetRoomListMessage(pMessage)
	vRoomList = GetEmployeeRoomsList(pMessage.current_session.Employee);
	If  vRoomList.Count() = 0 Then
		vReplyText = "<b>" + NStr("en = 'At the moment there is no work'; de = 'Im Moment gibt es keine Arbeit'; ru = 'На данный момент работ нет'") + "</b>";
	Else
		vReplyText = NStr("en = '<b>Your worklist</b>'; de = '<b>Ihre Jobliste</b>'; ru = '<b>Список работ</b>'") + "%0D%0A";
		vCurrHotel = Undefined;
		vCurrOperation = Undefined;
		For Each vRoomRow In vRoomList Do
			If vCurrHotel <> vRoomRow.Hotel Then
				vReplyText = vReplyText+TrimAll(vRoomRow.Hotel) + ":" + "%0D%0A";
				vCurrHotel = vRoomRow.Hotel;
			EndIf;		
			If vCurrOperation <> vRoomRow.Operation Then
				vReplyText = vReplyText + "[" + vRoomRow.OperationsCount + "]" + "<b>" + TrimAll(vRoomRow.Operation) + "</b>" + ":" + "%0D%0A";
				vCurrOperation = vRoomRow.Operation;
			EndIf;		
			vReplyText = vReplyText+ Catalogs.ChatBots.GetRoomText(vRoomRow.Room, False, False, False, False, False) + "%0D%0A";
		EndDo;
	EndIf;
	Return vReplyText;
EndFunction // GetRoomListMessage

// -----------------------------------------------------------------------------
Function GetRoom(pRoomCode, pHotel, pExtSystemCode = "HSK")
	If Left(pRoomCode, 1) = "/" Then
		pRoomCode = Mid(pRoomCode, 2);
	EndIf;
	// Find room by code
	vRoom = Catalogs.Rooms.EmptyRef();
	vQry = New Query();
	vQry.Text = 
	"SELECT
	|	Rooms.Ref AS Ref
	|FROM
	|	Catalog.Rooms AS Rooms
	|WHERE
	|	Rooms.Description = &qRoomCode
	|	AND NOT Rooms.DeletionMark
	|	AND NOT Rooms.IsFolder
	|	AND Rooms.Owner = &qHotel";
	vQry.SetParameter("qRoomCode", pRoomCode);
	vQry.SetParameter("qHotel", pHotel);
	vRooms = vQry.Execute().Unload();
	If vRooms.Count() > 0 Then
		vRoom = vRooms.Get(0).Ref;
	Else
		vRoom = cmGetObjectRefByExternalSystemCode(pHotel, pExtSystemCode, "Rooms", TrimR(pRoomCode));
		If Not ValueIsFilled(vRoom) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	Rooms.Ref AS Ref
			|FROM
			|	Catalog.Rooms AS Rooms
			|WHERE
			|	Rooms.Description = &qRoomCode
			|	AND NOT Rooms.DeletionMark
			|	AND NOT Rooms.IsFolder";
			vQry.SetParameter("qRoomCode", pRoomCode);
			vRooms = vQry.Execute().Unload();
			If vRooms.Count() > 0 Then
				vRoom = vRooms.Get(0).Ref;
			EndIf;
		EndIf;
	EndIf;
	Return vRoom;
EndFunction // GetRoom

#EndRegion

#Region Consumption

// -----------------------------------------------------------------------------
Procedure Consumption(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True);
	vRoom          = GetRoomFromContext(pMessage);	
	vOperation     = GetLastOperation(pMessage, vRoom, pMessage.current_session.Employee);
	If Not vOperation.Count() = 0 Then
		// =========================================================================
		If vOperationData[0] = "ConsArt" Then 
			Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
			ArticlesDis =  Articles.Description;
			If ValueIsFilled(Articles) And Not Articles.IsFolder Then 				
				updateMessage(pMessage,  
							  Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName, False) 
							  	+ "%0D%0A"
								+ NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'")
								+ "%0D%0A" 
								+ ArticlesDis + ": " + "<b>" 
								+ GetValueForArticle(vRoom, Articles, pMessage) + "</b>" + "%0D%0A" 
								+ NStr("en = '<b>How many?</b>'; de = '<b>Wie viele?</b>'; ru = '<b>Сколько?</b>'"),
							  getInLineKeyboardForArticlesValue(Articles));
			Else
				updateMessage(pMessage, 
				Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
				NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
				GetArticleTableForDocument(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles));
			EndIf;
			// =========================================================================	
		ElsIf vOperationData[0] = "ConsArtOK" Then 		
			updateMessage(pMessage, 
			Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
			NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
			GetArticleTableForDocument(vRoom, pMessage) + NStr("ru='<b>Выберите номенклатуру</b>';en='<b> Choose an item </ b>';de='<b> Wählen Sie einen Artikel aus </ b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles));
			// =========================================================================	
		ElsIf vOperationData[0] = "ConsArtCancel" Then 					
			Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
			updateMessage(pMessage,
			Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" +
			NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
			GetArticleTableForDocument(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles));
			// =========================================================================	
		ElsIf vOperationData[0] = "ConsArtAdd" Then 		
			Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
			ArticlesDis =  Articles.Description;
			Result = AddDataToDocument(Articles, vRoom, Number(vOperationData[2]), pMessage);
			If Result Then
				updateMessage(pMessage, 
				Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
				NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
				GetArticleTableForDocument(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles.Parent));
			Else
				updateMessage(pMessage,NStr("en = '<b>Operation could not be continued! The document is closed!</b>'; de = '<b>Operation konnte nicht fortgesetzt werden! Das Dokument ist geschlossen!</b>'; ru = '<b>Продолжение операции невозможно! Документ закрыт!</b>'"));
			EndIf;
			// =========================================================================	   
		ElsIf vOperationData[0] = "ConsArtAddInc" Then 		
			Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
			ArticlesDis =  Articles.Description;
			vValue = vOperation[0].Ref.Articles.FindRows(New Structure("Article", Articles));
			
			If vValue.Count() > 0 Then
				vValue = vValue[0].Quantity + 1;
				If Articles.MaxValue >= vValue Then
					Result = AddDataToDocument(Articles, vRoom, vValue, pMessage);
				Else
					Result = True;
				EndIf;
			Else
				Result = AddDataToDocument(Articles, vRoom, 1, pMessage);				
			EndIf;
			If Result Then
				updateMessage(pMessage, 
				Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
				NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
				GetArticleTableForDocument(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles.Parent));
			Else
				updateMessage(pMessage, NStr("en = '<b>Operation could not be continued! The document is closed!</b>'; de = '<b>Operation konnte nicht fortgesetzt werden! Das Dokument ist geschlossen!</b>'; ru = '<b>Продолжение операции невозможно! Документ закрыт!</b>'"));
			EndIf;
			// =========================================================================	
		ElsIf vOperationData[0] = "ConsArtAddDec" Then 		
			Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
			ArticlesDis =  Articles.Description;
			vValue = vOperation[0].Ref.Articles.FindRows(New Structure("Article", Articles));
			If vValue.Count() > 0 Then
				vValue = vValue[0].Quantity - 1;
				
				If vValue >= 0 Then
					Result = AddDataToDocument(Articles, vRoom, vValue, pMessage);
				Else
					Result = True;
				EndIf;
			Else
				Result = True;
			EndIf;		
			If Result Then
				updateMessage(pMessage, 
				Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
				NStr("en='Item Consumption';ru='Расход номенклатуры';de='Artikelverbrauch'") + "%0D%0A" + 
				GetArticleTableForDocument(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticles(vRoom, pMessage, Articles.Parent));
			Else
				updateMessage(pMessage,NStr("en='<b>Operation could not be continued! The document is closed!</b>'; de='<b>Operation konnte nicht fortgesetzt werden! Das Dokument ist geschlossen!</b>'; ru='<b>Продолжение операции невозможно! Документ закрыт!</b>'"));
			EndIf;
			// =========================================================================	
		ElsIf vOperationData[0] = "ConsOK" Then 
			updateMessage(pMessage,
			Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		EndIf;	
	Else	
		updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A"  + NStr("en = '<b>Operation with this room is not available!</b>'; de = '<b>Operation mit diesem Zimmer ist nicht verfügbar!</b>'; ru = '<b>Операция с этим номером недоступна!</b>'"), getInLineKeyboardForRoom(pMessage, vRoom));		
	EndIf;
EndProcedure // Consumption

// -----------------------------------------------------------------------------
Function GetValueForArticle(pRoom, Article, pMessage)
	Operation = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee).Get(0).Ref;
	If ValueIsFilled(Operation.Articles.Find(Article)) Then
		ArticlesRow = Operation.Articles.Find(Article);
		Return ArticlesRow.Quantity; 
	Else		
		Return "0"; 		
	EndIf;		
EndFunction

// -----------------------------------------------------------------------------
Function GetArticleTableForDocument(pRoom, pMessage)
	Operation = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee).Get(0).Ref;
	Result = "";	
	For Each row In Operation.Articles Do
		
		If row.Article.UseForChatBot Then
			If row.Quantity <> 0 Then 
				Articls = row.Article;
				Result =  Result + " - " + Articls.Description + ": <b>" + row.Quantity + "</b>" + "%0D%0A";  
			EndIf;			
		EndIf;
		
	EndDo;
	Return Result;
EndFunction // GetArticleTableForDocument

// -----------------------------------------------------------------------------
Function AddDataToDocument(Article, pRoom, Value, pMessage)
	Operations = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee);
	
	If Not ValueIsFilled(Operations.count()) Then 	
		Return False;	
	Else
		Operation = Operations.Get(0).Ref.GetObject();
		If ValueIsFilled(Operation.Articles.Find(Article)) Then
			ArticlesRow = Operation.Articles.Find(Article);	
		Else		
			ArticlesRow = Operation.Articles.Add();	
		EndIf;
		If Value = 0 Then
			Operation.Articles.Delete(ArticlesRow);
		Else
			ArticlesRow.Article         = Article;
			ArticlesRow.QuantityPerUnit = Number(Value);
			ArticlesRow.Quantity        = Number(Value);
			ArticlesRow.Unit            = Article.Unit;
			ArticlesRow.PlannedQuantity = GetPlanedUnit(pMessage.current_session.hotel, pMessage.current_session.room.RoomType, pMessage.current_session.room, Operation.Operation, Article);
		EndIf;
		If Operation.Operation = pMessage.bot.VirtualOperations Then
			Operation.AdditionalProperties.Insert("IsVirtual", True);
		EndIf;
		Operation.Write(DocumentWriteMode.Posting);
		Return True;
	EndIf;
EndFunction // AddDataToDocument

// -----------------------------------------------------------------------------
Function getInLineKeyboardForArticles(pRoom, pMessage, pArticle = "")
	If TypeOf(pArticle) = Type("String") Then
		If Not ValueIsFilled(pArticle) Then	
			pArticle = Catalogs.Articles.EmptyRef();		
		EndIf;	
	Else
		If ValueIsFilled(pArticle) And Not pArticle.isFolder Then
			Return Undefined;
		EndIf;
	EndIf;	
	
	If pMessage.Bot.UseConsumptionHierarchy Then	
		vBaseArray = New Array;
		Ref = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee).Get(0).Ref;
		vQ = New Query("SELECT
		               |	Articles.IsFolder AS IsFolder,
		               |	Articles.Ref AS Ref,
		               |	NestedSelect.Quantity AS Quantity,
		               |	NestedSelect1.UseForChatBot AS UseForChatBot,
		               |	Articles.MaxValue AS MaxValue
		               |FROM
		               |	Catalog.Articles AS Articles
		               |		LEFT JOIN (SELECT
		               |			EmployeeOperationArticles.Ref AS Ref,
		               |			EmployeeOperationArticles.Article AS Article,
		               |			EmployeeOperationArticles.Quantity AS Quantity
		               |		FROM
		               |			Document.EmployeeOperation.Articles AS EmployeeOperationArticles
		               |		WHERE
		               |			EmployeeOperationArticles.Ref = &qRef) AS NestedSelect
		               |		ON Articles.Ref = NestedSelect.Article
		               |		LEFT JOIN (SELECT
		               |			MAX(Articles.UseForChatBot) AS UseForChatBot,
		               |			Articles.Parent AS Parent
		               |		FROM
		               |			Catalog.Articles AS Articles
		               |		WHERE
		               |			NOT Articles.DeletionMark
		               |			AND NOT Articles.IsFolder
		               |		
		               |		GROUP BY
		               |			Articles.Parent) AS NestedSelect1
		               |		ON Articles.Ref = NestedSelect1.Parent
		               |WHERE
		               |	(Articles.UseForChatBot
		               |			OR Articles.IsFolder)
		               |	AND NOT Articles.DeletionMark
		               |	AND Articles.Parent = &qParent
		               |
		               |ORDER BY
		               |	IsFolder DESC,
		               |	Articles.SortCode");	
		vQ.SetParameter("qRef", Ref);
		vQ.SetParameter("qParent", pArticle);		
		qRes = vQ.Execute().Select();
		While qRes.Next() Do	
			If qRes.IsFolder Then
				If qRes.UseForChatBot = True Then
					vKeys = New Array;				
					vText = Catalogs.ChatBots.GetEmoji("FILE FOLDER") + " " + TrimAll(qRes.Ref.Description);
					vKeys.Add(getInLineButton(vText, "ConsArt:" + TrimR(qRes.Ref.Code)));	
					vBaseArray.Add(vKeys);
				EndIf;	
			Else
				If qRes.MaxValue > 0 Then
					vKeys = New Array;					
					If ValueIsFilled(qRes.Quantity) Then 
						vText = StrTemplate(NStr("en = '(%1) %2'; de = '(%1) %2'; ru = '(%1) %2'"), qRes.Quantity, TrimAll(qRes.Ref.Description));
					Else
						vText = TrimAll(qRes.Ref.Description);
					EndIf;
					vKeys.Add(getInLineButton(vText, "ConsArt:" + TrimR(qRes.Ref.Code)));
					If ValueIsFilled(qRes.Quantity) Then 
						vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MINUS SIGN"), "ConsArtAddDec:" + TrimR(qRes.Ref.Code)));
					EndIf;
					
					vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY PLUS SIGN"), "ConsArtAddInc:" + TrimR(qRes.Ref.Code)));	
					vBaseArray.Add(vKeys);	
				EndIf;
			EndIf;
		EndDo;		
		vKeys = New Array;
		If ValueIsFilled(pArticle.code) Then 
			vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("BACK WITH LEFTWARDS ARROW ABOVE") + NStr("en=' Back'; ru=' Назад'; de=' Zurück'"), "ConsArt:" + TrimAll(pArticle.Parent.code)));
		EndIf;	
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK") + " OK", "ConsOK"));
		vBaseArray.Add(vKeys);
	Else		
		vBaseArray = New Array;
		Ref = GetLastOperation(pMessage, pRoom, pMessage.current_session.employee).Get(0).Ref;
		vQ = New Query("SELECT
		               |	Articles.Ref AS Ref,
		               |	NestedSelect.Quantity AS Quantity,
		               |	Articles.MaxValue AS MaxValue
		               |FROM
		               |	Catalog.Articles AS Articles
		               |		LEFT JOIN (SELECT
		               |			EmployeeOperationArticles.Ref AS Ref,
		               |			EmployeeOperationArticles.Article AS Article,
		               |			EmployeeOperationArticles.Quantity AS Quantity
		               |		FROM
		               |			Document.EmployeeOperation.Articles AS EmployeeOperationArticles
		               |		WHERE
		               |			EmployeeOperationArticles.Ref = &Ref) AS NestedSelect
		               |		ON Articles.Ref = NestedSelect.Article
		               |WHERE
		               |	Articles.UseForChatBot
		               |	AND NOT Articles.DeletionMark
		               |
		               |ORDER BY
		               |	Articles.SortCode");	
		vQ.SetParameter("Ref", Ref);	
		qRes = vQ.Execute().Select();
		While qRes.Next() Do
			If qRes.MaxValue > 0 Then				
				vKeys = New Array;
				If ValueIsFilled(qRes.Quantity) Then  
					vText = StrTemplate(NStr("en = '(%1) %2'; de = '(%1) %2'; ru = '(%1) %2'"), qRes.Quantity, TrimAll(qRes.Ref.Description));
				Else
					vText = TrimAll(qRes.Ref.Description);
				EndIf;				
				vKeys.Add(getInLineButton(vText, "ConsArt:" + TrimR(qRes.Ref.Code)));
				If ValueIsFilled(qRes.Quantity) Then 
					vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MINUS SIGN"), "ConsArtAddDec:" + TrimR(qRes.Ref.Code)));
				EndIf;
				
				vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY PLUS SIGN"), "ConsArtAddInc:" + TrimR(qRes.Ref.Code)));		
				
				vBaseArray.Add(vKeys);
			EndIf;
		EndDo;	
		vKeys = New Array;
		emoji = Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK");
		vKeys.Add(getInLineButton(emoji, "ConsOK"));
		vBaseArray.Add(vKeys);
	EndIf;
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // getInLineKeyboardForArticles

// -----------------------------------------------------------------------------
Function getInLineKeyboardForArticlesValue(pArticles)
	vBaseArray = New Array;
	vValue = 0;
	vKeys = New Array;
	While vValue <= pArticles.MaxValue Do	
		vKeys.Add(getInLineButton(?(vValue = 0, NStr("en = 'Delete'; de = 'Löschen'; ru = 'Удалить'"), String(vValue)), "ConsArtAdd:" + TrimR(pArticles.Code) + ":" + vValue));
		vValue = vValue + 1;		
	EndDo;	
	vBaseArray.Add(vKeys);
	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("en = 'Back'; de = 'Back'; ru = 'Назад'"), "ConsArtCancel:" + TrimR(pArticles.Parent.Code)));
	vBaseArray.Add(vKeys);
	Return ArrayToInLineJSON(vBaseArray);	
EndFunction // getInLineKeyboardForArticlesValue

// -----------------------------------------------------------------------------
Function GetPlanedUnit(pHotel, pRoomType, pRoom, pOperation, pArticle)
	vStds = New ValueTable();
	
	If ValueIsFilled(pOperation) Then
		// Get data from the standards table for the room
		If ValueIsFilled(pRoom) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoom", pRoom);
			vQry.SetParameter("qArticle", pArticle);	
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the room type
		If vStds.Count() = 0 And ValueIsFilled(pRoomType) Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoomType", pRoomType);
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the hotel and empty room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", pHotel);
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Get data from the standards table for the empty hotel, room and room type
		If vStds.Count() = 0 Then
			vQry = New Query();
			vQry.Text = 
			"SELECT
			|	ArticleConsumptionStandards.Article AS Article,
			|	ArticleConsumptionStandards.Quantity AS Quantity,
			|	ArticleConsumptionStandards.Unit AS Unit,
			|	ArticleConsumptionStandards.IsPerPerson AS IsPerPerson,
			|	ArticleConsumptionStandards.IsPerRoomSpaceUnit AS IsPerRoomSpaceUnit
			|FROM
			|	InformationRegister.ArticleConsumptionStandards AS ArticleConsumptionStandards
			|WHERE
			|	ArticleConsumptionStandards.Operation = &qOperation
			|	AND ArticleConsumptionStandards.Hotel = &qHotel
			|	AND ArticleConsumptionStandards.RoomType = &qRoomType
			|	AND ArticleConsumptionStandards.Room = &qRoom
			|	AND ArticleConsumptionStandards.Article = &qArticle
			|
			|ORDER BY
			|	ArticleConsumptionStandards.Article.SortCode";
			vQry.SetParameter("qOperation", pOperation);
			vQry.SetParameter("qHotel", Catalogs.Hotels.EmptyRef());
			vQry.SetParameter("qRoomType", Catalogs.RoomTypes.EmptyRef());
			vQry.SetParameter("qRoom", Catalogs.Rooms.EmptyRef());
			vQry.SetParameter("qArticle", pArticle);
			vStds = vQry.Execute().Unload();
		EndIf;
		
		// Add rows to the articles tabular part
		If vStds.Count() > 0 Then
			Return vStds[0].Quantity;
		EndIf;
	EndIf;	
EndFunction // GetPlanedUnit

#EndRegion

#Region NewConsumption

// -----------------------------------------------------------------------------
Procedure NewConsumption(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True);
	vRoom = GetRoomFromContext(pMessage);	
	If vOperationData[0] = "ConsNewArt" Then 
		Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
		ArticlesDis =  Articles.Description;
		If ValueIsFilled(Articles) And Not Articles.IsFolder Then 				
			updateMessage(pMessage, 
			Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName, False) + "%0D%0A" + 
			NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
			ArticlesDis + ": " + "<b>" +  GetTempValue(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1]) + "</b>" + "%0D%0A" + 
			NStr("ru='<b>Сколько?</b>';en='<b>How many?</b>';de='<b>Wie viele?</b>'"), getInLineKeyboardForArticlesValueNew(Articles));	
		Else
			updateMessage(pMessage, 
			Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
			NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
			GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("ru='<b>Выберите номенклатуру</b>';en='<b>Choose an item</b>';de='<b>Wählen Sie einen Artikel aus</b>'"), getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles));
		EndIf;
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewArtOK" Then 		
		updateMessage(pMessage, 
		Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
		NStr("en='Item Consumption';ru='Расход номенклатуры';de='Artikelverbrauch'") + "%0D%0A" + 
		GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("ru='<b>Выберите номенклатуру</b>';en='<b>Choose an item</b>';de='<b>Wählen Sie einen Artikel aus</b>'"), getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles));
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewArtCancel" Then 					
		Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
		updateMessage(pMessage,
		Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" +
		NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
		GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"),
		getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles));		
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewArtAdd" Then 		
		Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
		ArticlesDis =  Articles.Description;
		
		SetContext(pMessage.chat, pMessage.Message_id, vOperationData[0], vOperationData[1], vOperationData[2]);
		
		updateMessage(pMessage, 
						Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
						NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
		GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles.Parent));
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewArtAddInc" Then 		
		Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
		ArticlesDis =  Articles.Description;
		vValue = GetTempValue(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1]);
		If ValueIsFilled(vValue) Then
			vValue = Number(vValue) + 1;
			If Articles.MaxValue >= vValue Then
				SetContext(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1], vValue);
			EndIf;
		Else
			SetContext(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1], 1);			
		EndIf;
		updateMessage(pMessage, 
						Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
						NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
		GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles.Parent));		
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewArtAddDec" Then 		
		Articles = Catalogs.Articles.FindByCode(vOperationData[1]);
		ArticlesDis =  Articles.Description;
		vValue = GetTempValue(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1]);
		If ValueIsFilled(vValue) Then
			vValue = Number(vValue) - 1;
			If vValue >= 0 Then
				SetContext(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd", vOperationData[1], vValue);
			EndIf;			
		EndIf;		
		updateMessage(pMessage, 
		Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False) + "%0D%0A" + 
		NStr("en = 'Item Consumption'; de = 'Artikelverbrauch'; ru = 'Расход номенклатуры'") + "%0D%0A" + 
		GetArticleTableForDocumentNew(vRoom, pMessage) + NStr("en = '<b>Choose an item</b>'; de = '<b>Wählen Sie einen Artikel aus</b>'; ru = '<b>Выберите номенклатуру</b>'"), getInLineKeyboardForArticlesNew(vRoom, pMessage, Articles.Parent));
		// =========================================================================	
	ElsIf vOperationData[0] = "ConsNewOK" Then 
		SaveNewDoc(pMessage, vRoom);
	EndIf;	
EndProcedure

// -----------------------------------------------------------------------------
Function GetArticleTableForDocumentNew(pRoom, pMessage)
	vTemp = GetTempTable(pMessage.chat, pMessage.message_id, "ConsNewArtAdd");
	vText = "";
	For Each row In vTemp Do		
		vTextArticles = Catalogs.Articles.FindByCode(row.key);
		vText =  vText + " - " + vTextArticles + ": " + row.value + "%0D%0A";  		
	EndDo;	
	Return vText;	
EndFunction // GetArticleTableForDocumentNew

// -----------------------------------------------------------------------------
Procedure SaveNewDoc(pMessage, pRoom)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vTemp = GetTempTable(pMessage.chat, pMessage.message_id, "ConsNewArtAdd");
	If vTemp.Count() > 0 Then 	
		vDoc = Documents.EmployeeOperation.CreateDocument();
		vDoc.Hotel = pMessage.current_session.hotel;
		vDoc.pmFillAttributesWithDefaultValues();
		vDoc.Room                      = pRoom;
		vDoc.RoomType                  = pRoom.RoomType;
		vDoc.Employee                  = pMessage.current_session.employee;
		vDoc.Operation                 = pMessage.bot.VirtualOperations;
		vDoc.OperationIntentTime       = CurrentSessionDate();	
		vDoc.EmployeeAssignmentTime    = CurrentSessionDate();		
		vDoc.OperationStartTime        = CurrentSessionDate();	
		vDoc.OperationEndTime          = CurrentSessionDate();	
		vDoc.OperationEndConfirmedTime = CurrentSessionDate();
		vTemp = GetTempTable(pMessage.chat, pMessage.message_id, "ConsNewArtAdd");
		For Each vRow In vTemp Do		
			vArticle     = Catalogs.Articles.FindByCode(vRow.key);
			vArticlesRow = vDoc.Articles.Find(vArticle);	
			If Not ValueIsFilled(vArticlesRow) Then			
				vArticlesRow = vDoc.Articles.Add();	
			EndIf;
			Try
				vValue = Number(vRow.Value);
			Except
			EndTry;
			If vValue = 0 Then
				vDoc.Articles.Delete(vArticlesRow);
			Else
				vArticlesRow.Article         = vArticle;
				vArticlesRow.QuantityPerUnit = vValue;
				vArticlesRow.Quantity        = vValue;
				vArticlesRow.Unit            = vArticle.Unit;
				vArticlesRow.PlannedQuantity = GetPlanedUnit(pMessage.current_session.hotel, pMessage.current_session.room.RoomType, pMessage.current_session.room, pMessage.bot.VirtualOperations, vArticle);
			EndIf;
		EndDo;
		vDoc.AdditionalProperties.Insert("IsVirtual", True);
		vDoc.Write(DocumentWriteMode.Posting);
		DeleteContext(pMessage.chat, pMessage.Message_id, "ConsNewArtAdd");	
	EndIf;
	updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(pRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, pRoom));	
EndProcedure // SaveNewDoc

// -----------------------------------------------------------------------------
Function getInLineKeyboardForArticlesNew(pRoom, pMessage, pArticle = "")
	If TypeOf(pArticle) = Type("String") Then
		If Not ValueIsFilled(pArticle) Then	
			pArticle = Catalogs.Articles.EmptyRef();		
		EndIf;	
	Else
		If ValueIsFilled(pArticle) And Not pArticle.isFolder Then
			Return Undefined;
		EndIf;
	EndIf;	
	vTemp = GetTempTable(pMessage.chat, pMessage.message_id, "ConsNewArtAdd");
	
	If pMessage.Bot.UseConsumptionHierarchy Then	
		vBaseArray = New Array;
		vQ = New Query("SELECT
		               |	Articles.IsFolder AS IsFolder,
		               |	Articles.Ref AS Ref,
		               |	NestedSelect1.UseForChatBot AS UseForChatBot,
		               |	Articles.MaxValue AS MaxValue
		               |FROM
		               |	Catalog.Articles AS Articles
		               |		LEFT JOIN (SELECT
		               |			MAX(Articles.UseForChatBot) AS UseForChatBot,
		               |			Articles.Parent AS Parent
		               |		FROM
		               |			Catalog.Articles AS Articles
		               |		WHERE
		               |			NOT Articles.DeletionMark
		               |			AND NOT Articles.IsFolder
		               |		
		               |		GROUP BY
		               |			Articles.Parent) AS NestedSelect1
		               |		ON Articles.Ref = NestedSelect1.Parent
		               |WHERE
		               |	(Articles.UseForChatBot
		               |			OR Articles.IsFolder)
		               |	AND NOT Articles.DeletionMark
		               |	AND Articles.Parent = &qParent
		               |
		               |ORDER BY
		               |	IsFolder DESC,
		               |	Articles.SortCode");	
		vQ.SetParameter("qParent", pArticle);
		qRes = vQ.Execute().Select();
		While qRes.Next() Do	
			If qRes.IsFolder Then
				If qRes.UseForChatBot = True Then
					vKeys = New Array;				
					vText = Catalogs.ChatBots.GetEmoji("FILE FOLDER") + " " + TrimAll(qRes.Ref.Description);
					vKeys.Add(getInLineButton(vText, "ConsNewArt:" + TrimR(qRes.Ref.Code)));		
					vBaseArray.Add(vKeys);
				EndIf;	
			Else
				vQuantity = 0;
				For Each vRow In vTemp Do		
					vArticle = Catalogs.Articles.FindByCode(vRow.key);
					If qRes.Ref = vArticle Then
						vQuantity = Number(vRow.Value);
						Break;
					EndIf;
				EndDo;	
				If qRes.MaxValue > 0 Then
					vKeys = New Array;
					vText = ?(vQuantity = 0, "", "(" + vQuantity + ") ") + TrimAll(qRes.Ref.Description);
					vKeys.Add(getInLineButton(vText, "ConsNewArt:" + TrimR(qRes.Ref.Code)));	
					If vQuantity > 0 Then
						vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MINUS SIGN"), "ConsNewArtAddDec:" + TrimR(qRes.Ref.Code)));
					EndIf;
					vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY PLUS SIGN"), "ConsNewArtAddInc:" + TrimR(qRes.Ref.Code)));				
					vBaseArray.Add(vKeys);	
				EndIf;
				
			EndIf;
		EndDo;		
		vKeys = New Array;
		If ValueIsFilled(pArticle.code) Then 
			vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("BACK WITH LEFTWARDS ARROW ABOVE") + " Назад", "ConsNewArt:" + TrimAll(pArticle.Parent.code)));
		EndIf;	
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK") + " OK", "ConsNewOK"));
		vBaseArray.Add(vKeys);
	Else		
		vBaseArray = New Array;
		vQ = New Query("SELECT
		               |	Articles.Ref AS Ref,
		               |	Articles.MaxValue AS MaxValue
		               |FROM
		               |	Catalog.Articles AS Articles
		               |WHERE
		               |	Articles.UseForChatBot
		               |	AND NOT Articles.DeletionMark
		               |
		               |ORDER BY
		               |	Articles.SortCode");	
		qRes = vQ.Execute().Select();
		While qRes.Next() Do	
			vQuantity = 0;
			For Each vRow In vTemp Do		
				vArticle     = Catalogs.Articles.FindByCode(vRow.key);
				If qRes.Ref = vArticle Then
					vQuantity = Number(vRow.Value);
					Break;
				EndIf;
			EndDo;	
			
			If qRes.MaxValue > 0 Then
				
				vKeys = New Array;
				vText = ?(vQuantity = 0, "", "(" + vQuantity + ") ") + TrimAll(qRes.Ref.Description);
				
				vKeys.Add(getInLineButton(vText, "ConsNewArt:" + TrimR(qRes.Ref.Code)));
				If vQuantity > 0 Then
					
					vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MINUS SIGN"), "ConsNewArtAddDec:" + TrimR(qRes.Ref.Code)));
				EndIf;
				vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY PLUS SIGN"), "ConsNewArtAddInc:" + TrimR(qRes.Ref.Code)));
				
				vBaseArray.Add(vKeys);
			EndIf;
			
		EndDo;	
		vKeys = New Array;
		emoji = Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK");
		vKeys.Add(getInLineButton(emoji, "ConsNewOK"));
		vBaseArray.Add(vKeys);
	EndIf;
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // GetInLineKeyboardForArticlesNew

// -----------------------------------------------------------------------------
Function getInLineKeyboardForArticlesValueNew(pArticles)
	vBaseArray = New Array;
	vValue = 0;
	vKeys = New Array;
	While vValue <= pArticles.MaxValue Do	
		vKeys.Add(getInLineButton(?(vValue = 0, NStr("ru='Удалить';de='Löschen';en='Delete'"), String(vValue)), "ConsNewArtAdd:" + TrimR(pArticles.Code) + ":" + vValue));
		vValue = vValue + 1;		
	EndDo;	
	vBaseArray.Add(vKeys);
	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("ru='Назад';en='Back';de='Zurück'"), "ConsNewArtCancel:" + TrimR(pArticles.Parent.Code)));
	vBaseArray.Add(vKeys);
	Return ArrayToInLineJSON(vBaseArray);	
EndFunction // getInLineKeyboardForArticlesValueNew

#EndRegion

#Region Mini_Bar

// -----------------------------------------------------------------------------
Procedure MiniBar(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True);
	vRoom = GetRoomFromContext(pMessage);
	vText = Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + "<b>" + Nstr("ru='Мини-бар';en='Mini-bar';de='Mini-bar'") + "</b>";
	
	vOperation = Catalogs.ChatBots.GetCurrentOperations(vRoom, pMessage.current_session.Employee);
	If Not vOperation.Count() = 0 Or pMessage.current_session.employee.PermissionGroup.ChatRole <> Enums.ChatRoles.Maid Then
		
		If vOperationData[0] = "BarSer" Then 	
			vServices = Catalogs.Services.FindByCode(vOperationData[1]);
			vKeyboard = "";
			If vServices.IsFolder Then 
				vKeyboard = getInLineKeyboardForMiniBarMenu(pMessage.Bot, vServices);
				vText = vText + "%0D%0A" + GetServicesList(pMessage);
			Else
				vKeyboard = getInLineKeyboardForMiniBarServices(pMessage.Bot, vServices);
				vText     = vText + "%0D%0A" + vServices.Description + ": " + GetTempValue(pMessage.chat, pMessage.message_id, "BarSerValue", TrimAll(vServices.Code)) + "%0D%0A" + "Сколько?" ;
			EndIf;	
			updateMessage(pMessage, vText, vKeyboard);
			// =========================================================================
		ElsIf vOperationData[0] = "BarBack" Then 	
			vServices = Catalogs.Services.FindByCode(vOperationData[1]).Parent;
			vKeyboard = "";
			vText = vText + "%0D%0A" + GetServicesList(pMessage);
			If vServices.IsFolder Then 
				vKeyboard = getInLineKeyboardForMiniBarMenu(pMessage.Bot, vServices);
			EndIf;
			updateMessage(pMessage, vText, vKeyboard);
			// =========================================================================	
		ElsIf vOperationData[0] = "BarSerValue" Then 	
			vServices = Catalogs.Services.FindByCode(vOperationData[1]).Parent;
			vKeyboard = getInLineKeyboardForMiniBarMenu(pMessage.Bot, vServices);	
			If vOperationData[2] = "0" Then
				DeleteContext(pMessage.chat, pMessage.Message_id, vOperationData[0], vOperationData[1]);
			Else
				SetContext(pMessage.chat, pMessage.Message_id, vOperationData[0], vOperationData[1], vOperationData[2]);
			EndIf;
			vText     = vText + "%0D%0A" + GetServicesList(pMessage);	
			updateMessage(pMessage, vText, vKeyboard);
			// =========================================================================	
		ElsIf vOperationData[0] = "BarCancel" Then 	
			vText = "";
			DeleteContext(pMessage.chat, pMessage.Message_id, "BarSerValue");	
			vText     = vText + "%0D%0A" + "<b>" + NStr("ru='Операция отменена!';en='Operation is cancelled!';de='Operation ist abgebrochen!'") + "</b>";	
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName) + "%0D%0A" + vText, getInLineKeyboardForRoom(pMessage, vRoom));		
			// =========================================================================	
		ElsIf vOperationData[0] = "BarOK" Then 	
			vText = "";
			vText     = vText + "%0D%0A" + FinishBarServices(pMessage.chat, pMessage.message_id, vRoom);
			DeleteContext(pMessage.chat, pMessage.Message_id, "BarSerValue");
			vText     = vText + "<b>" + NStr("ru='Операция завершена!';en='Operation is finished!';de='Operation ist beendet!'") + "</b>";
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False, False) + "%0D%0A" + "<b>" + NStr("en = 'Mini-bar'; ru = 'Мини-бар'; de = 'Mini-bar'") + "</b>" + vText);
			vMessage_id = sendMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
			SetContext(pMessage.chat, vMessage_id, "MessageContext", "Room", String(vRoom));
		EndIf;	
	Else
		updateMessage(pMessage, NStr("ru='Операция с этим номером недоступна!'; en='Operation with this room is not available!'; de='Eine Operation mit dieser Zimmer ist nicht verfügbar!'") + "%0D%0A" + Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
	EndIf;
EndProcedure // MiniBar

// -----------------------------------------------------------------------------
Function GetServicesList(pMessage)
	vTemp = GetTempTable(pMessage.chat, pMessage.message_id, "BarSerValue");
	vText = "";
	For Each row In vTemp Do
		vTextServices = Catalogs.Services.FindByCode(row.key);
		vText =  vText + " - " + vTextServices + ": " + row.value + "%0D%0A";  
	EndDo;
	
	Return vText;	
EndFunction // GetServicesList

// -----------------------------------------------------------------------------
Function getInLineKeyboardForMiniBarMenu(pBot, pParent = "")
	vBaseArray = New Array;
	If ValueIsFilled(pBot.MiniBarRootElement) Then 		
		vRootServices = pBot.MiniBarRootElement; 		
	Else	
		vRootServices = Catalogs.Services.FindByCode("mb");
	EndIf;
	
	If Not ValueIsFilled(pParent) Then 		
		pParent = vRootServices; 		
	EndIf;
	
	If TypeOf(pParent) = Type("String") Then
		vServices = Catalogs.Services.FindByCode(pParent);
	Else
		vServices = pParent;
	EndIf;
	
	vQ = New Query(
	"SELECT
	|	Services.Ref AS Ref
	|FROM
	|	Catalog.Services AS Services
	|WHERE
	|	Services.Parent = &qParent");	
	vQ.SetParameter("qParent", vServices);	
	vRes = vQ.Execute().Select();
	
	While vRes.Next() Do
		vKeys = New Array;
		vText = vRes.Ref.Description;
		vCommand = "BarSer:" + TrimAll(vRes.Ref.Code);
		If vRes.Ref.IsFolder Then
			vText = Catalogs.ChatBots.GetEmoji("FILE FOLDER") + " " + vText;
		EndIf;
		vKeys.Add(getInLineButton(vText, vCommand));
		vBaseArray.Add(vKeys);
	EndDo;
	
	If vServices = vRootServices Then
		vKeys = New Array;
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MULTIPLICATION X")          + NStr("en=' Cancel'; de=' Cancel'; ru=' Отмена'"), "BarCancel"));
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK")                + NStr("en=' OK'; de=' OK'; ru=' OK'"), "BarOK"));
		vBaseArray.Add(vKeys);
	Else
		vKeys = New Array;
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("BACK WITH LEFTWARDS ARROW ABOVE") + NStr("en=' Back'; de=' Zurück'; ru=' Назад'"), "BarBack:" + TrimAll(vServices.code)));
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY MULTIPLICATION X")          + NStr("en=' Cancel'; de=' Cancel'; ru=' Отмена'"), "BarCancel"));
		vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK")                + NStr("en=' OK'; de=' OK'; ru=' OK'"), "BarOK"));
		vBaseArray.Add(vKeys);
	EndIf;
	Return ArrayToInLineJSON(vBaseArray);
EndFunction

// -----------------------------------------------------------------------------
Function getInLineKeyboardForMiniBarServices(pBot, pServices)
	vBaseArray = New Array;	
	vValue = 1;
	vKeys = New Array;
	vText = NStr("ru='Удалить';en='Delete';de='Löschen'");
	vCommand = "BarSerValue:" + TrimAll(pServices.Code) + ":" + 0;
	vKeys.Add(getInLineButton(vText, vCommand));
	
	While vValue <= pBot.MiniBarMaxValue Do
		vText = String(vValue);
		vCommand = "BarSerValue:" + TrimAll(pServices.Code) + ":" + vValue;
		vKeys.Add(getInLineButton(vText, vCommand));
		vValue = vValue + 1;
	EndDo;
	vBaseArray.Add(vKeys);
	
	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("ru='Отмена';en='Cancel';de='Cancel'"), "BarBack:" + TrimAll(pServices.code)));
	vBaseArray.Add(vKeys);
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // GetInLineKeyboardForMiniBarServices

// -----------------------------------------------------------------------------
Function FinishBarServices(pChat, pMessage_id, pRoom)
	vTemp = GetTempTable(pChat, pMessage_id, "BarSerValue");
	vText = "";
	For Each vRow In vTemp Do
		vService = Catalogs.Services.FindByCode(vRow.key);
		If ValueIsFilled(vService) Then
			vPrice = 0;
			vPrices = vService.GetObject().pmGetServicePrices(pRoom.Owner, CurrentSessionDate(), Catalogs.ClientTypes.EmptyRef());
			If vPrices.Count() > 0 Then
				vPrice = vPrices.Get(0).Price;
			EndIf;
			vQ =  Number(vRow.value);
			If vQ <= 0 Then
				vQ = 1;
			EndIf;
			vClientCode = cmGetRoomGuests(pRoom.Owner, Undefined, pRoom, CurrentSessionDate(), CurrentSessionDate())[0].Guest.Code;
			vRetVal = cmChargeRoomService(pRoom, CurrentSessionDate(), Round(vPrice * vQ, 2), vClientCode, , TrimAll(vService.Code), vQ, , , , TrimAll(pRoom.Owner));
			vRetVal = TrimAll(Right(vRetVal, StrLen(vRetVal) - StrFind(vRetVal, ":")));
			If vRetVal = "" Then 	
				vEmoji = Catalogs.ChatBots.GetEmoji("HEAVY CHECK MARK");
				vText =  vText + vEmoji + " " + vService + ": " + vRow.value + "%0D%0A";  
			Else
				vEmoji = Catalogs.ChatBots.GetEmoji("HEAVY MULTIPLICATION X");
				vText =  vText + vEmoji + " " + vService + ": " + vRow.value + "%0D%0A" + vRetVal + "%0D%0A";  
			EndIf;
		Else  
			vEmoji = Catalogs.ChatBots.GetEmoji("HEAVY MULTIPLICATION X");
			vText = vEmoji + NStr("en = 'An error occurred while searching for the service. Please contact support team!'; 
								  |de = 'Bei der Suche nach einem Dienst ist ein Fehler aufgetreten. Kontaktieren Sie den technischen Support!'; 
								  |ru = 'Произошла ошибка при поиске услуги. Обратитесь в тех. поддержку!'") + " (" + vRow.key + ")" + "%0D%0A";
		EndIf;
	EndDo;
	Return vText;
EndFunction // FinishBarServices

#EndRegion

#Region Engineer

// -----------------------------------------------------------------------------
Procedure task(pMessage)
	vShowGuestsLastName = pMessage.Bot.ShowGuestsLastName;
	vOperationData = StrSplit(TrimAll(pMessage.Data), ":", True);
	vRoom = GetRoomFromContext(pMessage);
	
	// =========================================================================
	If vOperationData[0] = "TaskOpen" Then
		vTask =  getTask(vOperationData[1]);
		If ValueIsFilled(vTask) Then 	
			vText = GetTaskText(vTask);
			vKeyboard = GetOpenTaskKeyboard(vTask);
			updateMessage(pMessage, vText, vKeyboard);
		EndIf;		
		// =========================================================================	
	ElsIf vOperationData[0] = "TaskPhoto" Then 
		vTask =  getTask(vOperationData[1]);
		If ValueIsFilled(vTask) Then  
			vPhoto = GetFileToTask(vTask);
			If ValueIsFilled(vPhoto) Then 
				sendPhoto(pMessage.Bot, pMessage.Chat.Chat_id, vPhoto); 
			EndIf;
		EndIf;
		// =========================================================================	
	ElsIf vOperationData[0] = "TaskReOpen" Then 
		vTask = getTask(vOperationData[1]);
		If ValueIsFilled(vTask) Then  	
			vTaskObject = vTask.GetObject();
			vTaskObject.IsClosed = False;
			vTaskObject.ClosedBy = Catalogs.Employees.EmptyRef();
			vTaskObject.Write(DocumentWriteMode.Posting);
			vText = GetTaskText(vTask);
			vKeyboard = GetOpenTaskKeyboard(vTask);
			updateMessage(pMessage, vText, vKeyboard);		
		EndIf;	
		// =========================================================================	
	ElsIf vOperationData[0] = "TaskFinish" Then 	
		vTask = getTask(vOperationData[1]);
		If ValueIsFilled(vTask) Then  	
			vTaskObject = vTask.GetObject();
			vTaskObject.IsClosed = True;
			vTaskObject.DateWhenClosed = CurrentSessionDate();
			vTaskObject.ClosedBy = pMessage.current_session.employee;
			vTaskObject.Write(DocumentWriteMode.Posting);
			updateMessage(pMessage, GetTaskText(vTask) + "<b>" + NStr("ru='Задача закрыта!';en='Task is closed!';de='Task is closed!'") + "</b>"); 
			sendMessage(pMessage, getTaskList(pMessage.current_session.hotel, pMessage.current_session.Employee), getKeyboard(pMessage.current_session.Employee));
		EndIf;		
		// =========================================================================	
	ElsIf vOperationData[0] = "TaskAddComment" Then 
		vTask = getTask(vOperationData[1]);
		If ValueIsFilled(vTask) Then  		
			SetContext(pMessage.chat, pMessage.Message_id, "ChatContext", "Task", vOperationData[1]);
			updateMessage(pMessage, GetTaskText(vTask) + "<b>" + NStr("ru='Введите новый коментарий';en='Enter a new comment';de='Geben Sie einen neuen Kommentar'") + "</b>");
		EndIf;	
		// =========================================================================	
	ElsIf vOperationData[0] = "pdTask" Then 
		vRoomText = GetTempValue(pMessage.chat, pMessage.Message_id, "MessageContext", "Room");
		vRoom     = GetRoom(vRoomText, pMessage.current_session.hotel);
		
		If vOperationData[1] = "Cancel" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		Else
			vEDRow = pMessage.bot.EngineerDepartments.Find(Number(vOperationData[1]), "ID");
			vText = vEDRow.TaskType;
			DeleteContext(pMessage.chat, pMessage.Message_id, "ChatContext", "Task");
			SetContext(pMessage.chat, pMessage.Message_id, "ChatContext", "Task", "NewTask:" + vRoomText, vText);
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, False, False, False, False, False, , True), getInLineKeyboardForPhotoAttaching());
		EndIf;	
		// =========================================================================	
	ElsIf vOperationData[0] = "noPhotoTask" Then 
		
		vRoomText = GetTempValue(pMessage.chat, pMessage.Message_id, "MessageContext", "Room");
		vRoom     = GetRoom(vRoomText, pMessage.current_session.hotel);
		
		If vOperationData[1] = "Cancel" Then
			updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
		Else
			vText = GetTempRemarks(pMessage.chat, pMessage.message_id, "ChatContext", "Task");
			DeleteContext(pMessage.chat, pMessage.Message_id , "ChatContext", "Task");
			vTask = SetTask(vRoom, vText, pMessage.current_session.employee, , , pMessage);
			If ValueIsFilled(vTask) Then
				updateMessage(pMessage, Catalogs.ChatBots.GetRoomText(vRoom, vShowGuestsLastName), getInLineKeyboardForRoom(pMessage, vRoom));
			Else
				updateMessage(pMessage, NStr("ru='Упс! Случилась ошибка!';en='Oops! An error has occurred!';de='Hoppla! Ein Fehler ist aufgetreten!'"));
			EndIf;
		EndIf;
		// =========================================================================	
	EndIf;	
EndProcedure // Task

// -----------------------------------------------------------------------------
Function GetTaskText(pTask, vFull = True)
	vText = Catalogs.ChatBots.GetRoomText(pTask.ByObject, False, False, False, False) + "%0D%0A" + 
	Catalogs.ChatBots.GetEmoji("WRENCH") + "<b>" + NStr("ru='Задача от: ';en='Date ';de='Datum '") + pTask.Date + "%0D%0A" + "</b>" + 
	"<b>" + NStr("ru='Описание задачи: '; en='Task description: '; de='Aufgabe Beschreibung: '") + "</b><i>" + pTask.Remarks + "</i>" + "%0D%0A" + "%0D%0A"; 	
	
	If vFull Then
		For Each vComments In pTask.Comments Do
			vCommentText = Catalogs.ChatBots.GetEmoji("SPEECH BALLOON") + NStr("ru='Комментарий №'; en='Comment N'; de='Kommentar Nr.'") + vComments.LineNumber + "%0D%0A" + vComments.Employee + ": " + vComments.Comments + "%0D%0A" + "%0D%0A";
			vText = vText + vCommentText;
		EndDo;
	Else
		vCount = pTask.Comments.Count();
		VCurCount = 1;
		For Each vComments In pTask.Comments Do
			If vCount = VCurCount Then
				vCommentText = Catalogs.ChatBots.GetEmoji("SPEECH BALLOON") + NStr("ru='Последний комментарий:'; en='Last comment:'; de='Letzter Kommentar:'") + "%0D%0A" + vComments.Employee + ": " + vComments.Comments + "%0D%0A" + "%0D%0A";
				vText = vText + vCommentText;
			EndIf;
			VCurCount = VCurCount + 1;
		EndDo;
	EndIf;
	
	Return vText;	
EndFunction // GetTaskText

// -----------------------------------------------------------------------------
Procedure AddCommentToTask(pMessage, pTask)
	DeleteContext(pMessage.chat, , "ChatContext", "Task");
	
	vTaskObject = pTask.GetObject();
	vNewComment = vTaskObject.Comments.Add();
	vNewComment.Employee = pMessage.current_session.employee;
	vNewComment.Comments = pMessage.Data;
	vNewComment.Period   = CurrentSessionDate();
	
	vTaskObject.Write();
	vText = GetTaskText(pTask);
	vKeyboard = GetOpenTaskKeyboard(pTask);
	sendMessage(pMessage, vText, vKeyboard);
EndProcedure // AddCommentToTask

// -----------------------------------------------------------------------------
Function getFileToTask(vTask)
	vQ = New Query("SELECT
	               |	MessageAttachments.ExtFile AS ExtFile,
	               |	MessageAttachments.FileName AS FileName,
	               |	MessageAttachments.PhotoID AS PhotoID
	               |FROM
	               |	InformationRegister.MessageAttachments AS MessageAttachments
	               |WHERE
	               |	MessageAttachments.Message = &Message");
	
	vQ.SetParameter("Message", vTask);
	
	vQueryResult = vQ.Execute().Select();
	If vQueryResult.Next() Then
		Return vQueryResult.PhotoID;
	EndIf;
	Return Null;
EndFunction // getFileToTask

// -----------------------------------------------------------------------------
Function getOpenTaskKeyboard(pTask)
	BaseArray = New Array;	
	
	Keys = New Array;
	Keys.Add(getInLineButton(NStr("ru='Завершить задачу';en='Finish task';de='Aufgabe beenden'"), "TaskFinish:" + TrimAll(pTask.Number)));
	BaseArray.Add(Keys);
	If getFileToTask(pTask) <> Null Then	
		Keys = New Array;
		Keys.Add(getInLineButton(Nstr("ru='Посмотреть фото';en='Show photo';de='Foto anzeigen'"), "TaskPhoto:" + TrimAll(pTask.Number)));
		BaseArray.Add(Keys);
	EndIf;	
	Keys = New Array;
	Keys.Add(getInLineButton(NStr("ru='Добавить комментарий';en='Add comment';de='Kommentar hinzufügen'"), "TaskAddComment:" + TrimAll(pTask.Number)));
	BaseArray.Add(Keys);	
	
	Return ArrayToInLineJSON(BaseArray);
EndFunction

// -----------------------------------------------------------------------------
Function getTaskList(pHotel, pEmployee = Undefined, pIsClosed = False, pDepartment = Undefined)
	vQ = New Query();
	vQ.Text = 
	"SELECT
	|	Messages.Object AS Room,
	|	Messages.Recorder AS Ref
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	Messages.IsClosed = &qIsClosed
	|	AND Messages.ForDepartment = &qForDepartment
	|	AND Messages.Object <> UNDEFINED
	|	AND Messages.Object.Owner = &qHotel
	|	AND Messages.Object REFS Catalog.Rooms
	|
	|GROUP BY
	|	Messages.Object,
	|	Messages.Recorder
	|
	|ORDER BY
	|	Messages.Object.SortCode";
	vQ.SetParameter("qForDepartment", ?(pEmployee = Undefined, pDepartment, pEmployee.Department));
	vQ.SetParameter("qIsClosed", pIsClosed);
	vQ.SetParameter("qHotel", pHotel);
	vQueryResult = vQ.Execute().Unload();
	
	vText = "";	
	vCurrentRoom = "";
	For Each vRoomRow In vQueryResult Do
		If ValueIsFilled(vRoomRow.Room) Then
			If vCurrentRoom <> vRoomRow.Room Then
				vText = vText + Catalogs.ChatBots.GetRoomText(vRoomRow.Room, False, False, False, False) + "%0D%0A";
				vCurrentRoom = vRoomRow.Room;
			EndIf;	
			vTask = vRoomRow.Ref;
			If ValueIsFilled(vTask) Then 	
				vText = vText + Catalogs.ChatBots.GetEmoji("WRENCH") + "<b>" + NStr("ru='Задача от: ';en='Date ';de='Datum '") + vTask.Date + "%0D%0A" + "</b>" + 
				"<b>" + NStr("ru='Описание задачи: '; en='Task description: '; de='Aufgabe Beschreibung: '") + "</b><i>" + vTask.Remarks + "</i>" + "%0D%0A" + "%0D%0A"; 		
				vCount = vTask.Comments.Count();
				VCurCount = 1;
				For Each vComments In vTask.Comments Do
					If vCount = VCurCount Then
						vCommentText = Catalogs.ChatBots.GetEmoji("SPEECH BALLOON") + NStr("ru='Последний комментарий:'; en='Last comment:'; de='Letzter Kommentar:'") + "%0D%0A" + vComments.Employee + ": " + vComments.Comments + "%0D%0A" + "%0D%0A";
						vText = vText + vCommentText;
					EndIf;
					VCurCount = VCurCount + 1;
				EndDo;
			EndIf;	
		EndIf;	
	EndDo;
	
	Return ?(vText = "", NStr("ru='Задач больше нет'; en='No more tasks'; de='Keine Aufgaben mehr'"), vText);
EndFunction // getTaskList

// -----------------------------------------------------------------------------
Function getPredifineTask(pBot)
	BaseArray = New Array;	
	
	For Each vTaskRow In pBot.EngineerDepartments Do
		
		vText    = vTaskRow.TaskType; 
		vCommand = "pdTask:" + TrimAll(vTaskRow.ID);
		
		Keys = New Array;                               
		Keys.Add(getInLineButton(vText, vCommand));
		BaseArray.Add(Keys);
	EndDo;
	Keys = New Array;                               
	Keys.Add(getInLineButton(NStr("ru='Отмена';en='Cancel';de='Cancel'"), "pdTask:Cancel"));
	BaseArray.Add(Keys);
	
	Return ArrayToInLineJSON(BaseArray);
EndFunction // getPredifineTask

// -----------------------------------------------------------------------------
Function getInLineKeyboardForRoomEnginer(pMessage, pRoom = Undefined)
	
	If pRoom = Undefined Then
		pRoom = pMessage.current_session.room;		
	EndIf;	
	vBaseArray = New Array;	
	
	vRoomFunc = "Room:";
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Messages.Recorder AS Ref,
	|	CAST(Messages.Remarks AS STRING(1024)) AS Remarks,
	|	Messages.Recorder.Number AS Number
	|FROM
	|	InformationRegister.Messages AS Messages
	|WHERE
	|	Messages.IsClosed = &qIsClosed
	|	AND Messages.ForDepartment = &qForDepartment
	|	AND Messages.Object <> UNDEFINED
	|	AND Messages.Object = &qObject";
	Query.SetParameter("qObject", pRoom);
	Query.SetParameter("qForDepartment", pMessage.current_session.employee.Department);
	Query.SetParameter("qIsClosed", False);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	While SelectionDetailRecords.Next() Do
		vKeys = New Array;
		vKeys.Add(getInLineButton(NStr("ru='Задача: ';en='Task: ';de='Aufgabe: '") + SelectionDetailRecords.Remarks, TrimAll(vRoomFunc + "TaskView:" + SelectionDetailRecords.Number)));
		vBaseArray.Add(vKeys);
	EndDo;
	
	vKeys = New Array;
	vKeys.Add(getInLineButton(NStr("ru='Неисправность';de='Fehlfunktion';en='Malfunction'"), TrimAll(vRoomFunc + "Task")));
	vBaseArray.Add(vKeys);
	
	Return ArrayToInLineJSON(vBaseArray);
EndFunction // getInLineKeyboardForRoomEnginer

#EndRegion

#Region Context

// -----------------------------------------------------------------------------
Procedure UpdateUpdateID(pBot, update_id)
	botObject         = pBot.GetObject();
	botObject.offset  = update_id;
	botObject.Write();	
EndProcedure // UpdateUpdateID

// -----------------------------------------------------------------------------
Procedure SetContext(pChat, pMessage_id, pOperations, pKey, pValue, pRemarks="")
	vTm = InformationRegisters.ChatContext.CreateRecordManager();
	vTm.chat       = pChat;
	vTm.message_id = pMessage_id;
	vTm.operations = pOperations;
	vTm.key        = pKey;
	vTm.value      = pValue;
	vTm.remarks	   = pRemarks;
	vTm.Write();
EndProcedure // SetContext

// -----------------------------------------------------------------------------
Procedure DeleteContext(pChat_id, pMessage_id = "", pOperations = "", pKey = "")	
	vRecordManager = InformationRegisters.ChatContext.CreateRecordSet();
	vRecordManager.Filter.chat.Set(pChat_id);

	If ValueIsFilled(pMessage_id) Then
		vRecordManager.Filter.operations.Set(pMessage_id);	
	EndIf;	
	
	If ValueIsFilled(pOperations) Then
		vRecordManager.Filter.operations.Set(pOperations);	
	EndIf;	
	If ValueIsFilled(pKey) Then
		vRecordManager.Filter.key.Set(pKey);	
	EndIf;
	vRecordManager.Write();	
EndProcedure // DeleteContext

// -----------------------------------------------------------------------------
Function GetTempTable(pChat_id, pMessage_id, pOperations)	
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	ChatContext.key AS key,
	|	ChatContext.value AS value
	|FROM
	|	InformationRegister.ChatContext AS ChatContext
	|WHERE
	|	ChatContext.chat = &qchat_id
	|	AND ChatContext.message_id = &qmessage_id
	|	AND ChatContext.operations = &qoperations";		
	vQ.SetParameter("qchat_id",    pChat_id);
	vQ.SetParameter("qmessage_id", pMessage_id);
	vQ.SetParameter("qoperations", pOperations);	
	vRes = vQ.Execute().Unload();		
	Return vRes;	
EndFunction // GetTempTable

// -----------------------------------------------------------------------------
Function GetTempValue(pChat, pMessage_id, pOperations, pKey)
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	ChatContext.key AS key,
	|	ChatContext.value AS value
	|FROM
	|	InformationRegister.ChatContext AS ChatContext
	|WHERE
	|	ChatContext.chat = &qchat_id
	|	AND ChatContext.message_id = &qmessage_id
	|	AND ChatContext.operations = &qoperations
	|	AND ChatContext.key = &qkey";
	vQ.SetParameter("qchat_id",    pChat);
	vQ.SetParameter("qmessage_id", pMessage_id);
	vQ.SetParameter("qoperations", pOperations);
	vQ.SetParameter("qkey",        pKey);
	
	qRes = vQ.Execute().Select();	
	While qRes.Next() Do
		Return qRes.value;
	EndDo;
	Return "";
EndFunction // GetTempValue

// -----------------------------------------------------------------------------
Function GetTempRemarks(pChat, pMessage_id, pOperations, pKey)
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	ChatContext.key AS key,
	|	ChatContext.remarks AS remarks
	|FROM
	|	InformationRegister.ChatContext AS ChatContext
	|WHERE
	|	ChatContext.chat = &qchat_id
	|	AND ChatContext.operations = &qoperations
	|	AND ChatContext.key = &qkey";
	vQ.SetParameter("qchat_id",    pChat);
	vQ.SetParameter("qoperations", pOperations);
	vQ.SetParameter("qkey",        pKey);
	
	qRes = vQ.Execute().Select();	
	While qRes.Next() Do
		Return qRes.remarks;
	EndDo;
	Return "";
EndFunction // GetTempRemarks

// -----------------------------------------------------------------------------
Function GetTempGlobalVlalue(pChat, pOperations, pKey)
	vQ = New Query;
	vQ.Text = 
	"SELECT
	|	ChatContext.key AS key,
	|	ChatContext.value AS value
	|FROM
	|	InformationRegister.ChatContext AS ChatContext
	|WHERE
	|	ChatContext.chat = &qchat_id
	|	AND ChatContext.operations = &qoperations
	|	AND ChatContext.key = &qkey";
	vQ.SetParameter("qchat_id",    pChat);
	vQ.SetParameter("qoperations", pOperations);
	vQ.SetParameter("qkey",        pKey);
	
	qRes = vQ.Execute().Select();	
	While qRes.Next() Do
		Return qRes.value;
	EndDo;
	Return "";
EndFunction // GetTempGlobalVlalue

// -----------------------------------------------------------------------------
Function GetRoomFromContext(pMessage)
	vRoomText = GetTempValue(pMessage.chat, pMessage.message_id, "MessageContext", "Room");
	vRoom = GetRoom(vRoomText, pMessage.current_session.hotel);
	Return vRoom;
EndFunction

// -----------------------------------------------------------------------------
Procedure DeleteButton(pChat)
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	NestedSelect.chat AS chat,
	|	NestedSelect.message_id AS message_id,
	|	ChatBotUpdates.Text AS Text,
	|	NestedSelect.date AS date,
	|	ChatContext.operations AS operations,
	|	ChatContext.key AS key,
	|	ChatContext.value AS value,
	|	ChatBotUpdates.messageSender AS messageSender
	|FROM
	|	(SELECT
	|		ChatBotUpdates.chat AS chat,
	|		ChatBotUpdates.message_id AS message_id,
	|		MAX(ChatBotUpdates.date) AS date
	|	FROM
	|		InformationRegister.ChatBotUpdates AS ChatBotUpdates
	|	WHERE
	|		ChatBotUpdates.messageSender = &messageSender
	|	
	|	GROUP BY
	|		ChatBotUpdates.message_id,
	|		ChatBotUpdates.chat) AS NestedSelect
	|		LEFT JOIN InformationRegister.ChatBotUpdates AS ChatBotUpdates
	|		ON NestedSelect.message_id = ChatBotUpdates.message_id
	|			AND NestedSelect.date = ChatBotUpdates.date
	|		LEFT JOIN InformationRegister.ChatContext AS ChatContext
	|		ON NestedSelect.message_id = ChatContext.message_id
	|WHERE
	|	ChatContext.key = &key
	|	AND NestedSelect.chat = &chat
	|
	|ORDER BY
	|	date";
	vQuery.SetParameter("chat", pChat);
	vQuery.SetParameter("key", "Room");
	vQuery.SetParameter("messageSender", Enums.MessageSender.Bot);
	vQueryResult = vQuery.Execute();
	
	vRes = vQueryResult.Select();
	
	While vRes.Next() Do
		editMessageReplyMarkup(vRes.Chat, vRes.message_id, vRes.Chat.Bot, vRes.Text);
		DeleteContext(vRes.Chat, vRes.message_id, vRes.operations, vRes.key);		
	EndDo;
EndProcedure // DeleteButton

#EndRegion

#Region InLineKeyboards 

// -----------------------------------------------------------------------------
Function arrayToInLineJSON(pArray)
	FileName = GetTempFileName("txt");     
	
	Struct = New Structure;
	Struct.Insert("inline_keyboard", pArray);
	Struct.Insert("hide_keyboard", True);
	
	File = New TextDocument;
	File.Write(FileName, "UTF-8");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, Struct);
	JSONWriter.Close();
	
	File.Read(FileName, "UTF-8");
	
	TextJSON = File.GetText();
	TextJSON = StrReplace(TextJSON, "Истина", "True");	
	
	Try
		DeleteFiles(FileName);
	Except
	EndTry;
	Return TextJSON;
EndFunction // ArrayToInLineJSON

// -----------------------------------------------------------------------------
//  Function - Create inline button
//
// Parameters:
//  pText			 - String	 - Text
//  pCallback		 - String	 - Callback
//  pCallbackType	 - String	 - CallbackType
// 
// Returns:
//  Structure - Button Structure
//
Function getInLineButton(pText, pCallback, pCallbackType = "callback_data")
	pCallback = "'" + pCallback + "'"; 		
	
	ButtonStruct = New Structure;
	ButtonStruct.Insert("text", pText);	
	ButtonStruct.Insert(pCallbackType, pCallback);
	
	Return ButtonStruct;			
EndFunction // GetInLineButton

#EndRegion

#Region Keyboard

// -----------------------------------------------------------------------------
Function getRoomSwichKeyboard()
	vBaseArray = New Array;
	
	vKeys = New Array;
	vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("black left-pointing triangle"), "Status:PrevPage"));
	vKeys.Add(getInLineButton(Catalogs.ChatBots.GetEmoji("black right-pointing triangle"), "Status:NexPage"));
	vBaseArray.Add(vKeys);
	
	Return ArrayToInLineJSON(vBaseArray);	
EndFunction // GetRoomSwichКeyboard

// -----------------------------------------------------------------------------
Function getMenuKeyboard()
	vBaseArray = New Array;
	vKeys = New Array;
	vKeys.Add(NStr("en = 'Menu'; de = 'Menü'; ru = 'Меню'"));
	vBaseArray.Add(vKeys);
	Return ArrayToJSON(vBaseArray, , True);
EndFunction // GetMenuKeyboard

// -----------------------------------------------------------------------------
Function getHotelKeyboard()
	vBaseArray = New Array;
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	Hotels.Description AS Description
	|FROM
	|	Catalog.Hotels AS Hotels
	|WHERE
	|	NOT Hotels.DeletionMark
	|	AND NOT Hotels.IsFolder";
	vQueryResult = vQuery.Execute();
	vSelectionDetailRecords = vQueryResult.Select();
	While vSelectionDetailRecords.Next() Do
		vKeys = New Array;
		vKeys.Add(vSelectionDetailRecords.Description);
		vBaseArray.Add(vKeys);
	EndDo;
	Return ArrayToJSON(vBaseArray);
EndFunction // getHotelKeyboard

// -----------------------------------------------------------------------------
Function hideKeyboard()
	FileName = GetTempFileName("txt");
	Struct = New Structure;
	Struct.Insert("hide_keyboard", True);
	
	File = New TextDocument;
	File.Write(FileName, "UTF-8");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, Struct);
	JSONWriter.Close();
	
	File.Read(FileName, "UTF-8");
	
	TextJSON = File.GetText();
	TextJSON = StrReplace(TextJSON, "Истина", "True");
	Try
		DeleteFiles(FileName);
	Except
	EndTry;

	Return TextJSON;
EndFunction // hideKeyboard

// -----------------------------------------------------------------------------
Function ArrayToJSON(pArray, one_time_keyboard = True, resize_keyboard = False)
	FileName = GetTempFileName("txt");     
	
	Struct = New Structure;
	Struct.Insert("keyboard"         , pArray);
	Struct.Insert("one_time_keyboard", one_time_keyboard);
	Struct.Insert("resize_keyboard", resize_keyboard);
	
	File = New TextDocument;
	File.Write(FileName, "UTF-8");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, Struct);
	JSONWriter.Close();
	
	File.Read(FileName, "UTF-8");
	
	TextJSON = File.GetText();
	TextJSON = StrReplace(TextJSON, "Истина", "True");
	
	Try
		DeleteFiles(FileName);
	Except
	EndTry;
	Return TextJSON;
EndFunction // ArrayToJSON

#EndRegion

#Region Operation

// -----------------------------------------------------------------------------
Function GetCurrentOperationsOnInspections(pRoom)
	vText = "SELECT
	        |	EmployeeOperation.Ref AS Ref,
	        |	EmployeeOperation.Room AS Room,
	        |	EmployeeOperation.Employee AS Employee,
	        |	EmployeeOperation.Operation AS Operation,
	        |	EmployeeOperation.OperationIntentTime AS OperationIntentTime,
	        |	EmployeeOperation.EmployeeAssignmentTime AS EmployeeAssignmentTime,
	        |	EmployeeOperation.OperationStartTime AS OperationStartTime,
	        |	EmployeeOperation.OperationEndTime AS OperationEndTime,
	        |	EmployeeOperation.OperationEndConfirmedTime AS OperationEndConfirmedTime
	        |FROM
	        |	Document.EmployeeOperation AS EmployeeOperation
	        |WHERE
	        |	EmployeeOperation.Posted
	        |	AND NOT EmployeeOperation.DeletionMark
	        |	AND EmployeeOperation.OperationEndConfirmedTime = &qEmptyDate
	        |	AND EmployeeOperation.OperationEndTime <> &qEmptyDate
	        |	AND (EmployeeOperation.Room.RoomStatus = &qRoomStatus
	        |			OR EmployeeOperation.Room.RoomStatus.InspectionIsInProgress)
	        |	AND EmployeeOperation.Hotel = &qHotel
			|	";
	If ValueIsFilled(pRoom) Then
		vText = vText + " AND EmployeeOperation.Room = &qRoom
		                |ORDER BY
						|	EmployeeOperation.OperationStartTime DESC";
	EndIf;
	vQ = New Query();	
	vQ.Text = vText;
	If ValueIsFilled(pRoom) Then
		vQ.SetParameter("qRoom", pRoom);
	EndIf;
	vQ.SetParameter("qHotel", pRoom.Owner);
	vQ.SetParameter("qRoomStatus", pRoom.Owner.RoomStatusInspection);
	vQ.SetParameter("qEmptyDate", '00010101');
	qTRes = vQ.Execute().Unload();
	Return qTRes;
EndFunction // GetCurrentOperationsOnInspections

// -----------------------------------------------------------------------------
Function GetLastOperation(pMessage, pRoom = Undefined, pEmployee = Undefined)
	vText = "SELECT TOP 1
	        |	EmployeeOperation.Ref AS Ref,
	        |	EmployeeOperation.Room AS Room,
	        |	EmployeeOperation.Employee AS Employee,
	        |	EmployeeOperation.Operation AS Operation,
	        |	EmployeeOperation.OperationIntentTime AS OperationIntentTime,
	        |	EmployeeOperation.EmployeeAssignmentTime AS EmployeeAssignmentTime,
	        |	EmployeeOperation.OperationStartTime AS OperationStartTime,
	        |	EmployeeOperation.OperationEndTime AS OperationEndTime,
	        |	EmployeeOperation.OperationEndConfirmedTime AS OperationEndConfirmedTime
	        |FROM
	        |	Document.EmployeeOperation AS EmployeeOperation
	        |WHERE
	        |	EmployeeOperation.Posted
	        |	AND NOT EmployeeOperation.DeletionMark
	        |	AND EmployeeOperation.Room = &qRoom
	        |	AND CASE
	        |			WHEN &qEmployeeIsEmpty
	        |				THEN TRUE
	        |			ELSE EmployeeOperation.Employee = &qEmployee
	        |		END
	        |	AND (EmployeeOperation.OperationEndTime > &qStartDate
	        |			OR EmployeeOperation.OperationEndTime = &qEmptyDate)
	        |
	        |ORDER BY
	        |	EmployeeOperation.Date DESC";
	vQ = New Query();	
	vQ.Text = vText;
	vQ.SetParameter("qRoom", pRoom);
	vQ.SetParameter("qEmployee", pEmployee);
	vQ.SetParameter("qEmployeeIsEmpty", Not ValueIsFilled(pEmployee));
	vQ.SetParameter("qEmptyDate", '00010101');
	vQ.SetParameter("qStartDate", pMessage.current_session.session_start);
	
	qTRes = vQ.Execute().Unload();
	Return qTRes;
EndFunction // GetLastOperation

#EndRegion

#Region Sections

// -----------------------------------------------------------------------------
Function getSectionKeyboard(pHotel)
	vBaseArray = New Array;
	
	vHotels = New Array;
	vHotels.Add(pHotel);
	vHotels.Add(Catalogs.Hotels.EmptyRef());
	vQuery = New Query;
	vQuery.Text = 
	"SELECT
	|	RoomSections.Ref AS Ref,
	|	RoomSections.Description AS Description
	|FROM
	|	Catalog.RoomSections AS RoomSections
	|WHERE
	|	NOT RoomSections.IsFolder
	|	AND NOT RoomSections.DeletionMark
	|	AND RoomSections.Hotel IN(&qHotels)
	|
	|ORDER BY
	|	RoomSections.SortCode";
	vQuery.SetParameter("qHotels", vHotels);
	
	vQueryResult = vQuery.Execute();
	
	vSelectionDetailRecords = vQueryResult.Select();
	
	While vSelectionDetailRecords.Next() Do
		vKeys = New Array;
		vKeys.Add(vSelectionDetailRecords.Description);
		vBaseArray.Add(vKeys);		
	EndDo;
	
	Return ArrayToJSON(vBaseArray);
EndFunction // getSectionKeyboard

#EndRegion

// -----------------------------------------------------------------------------
Function GetHelpText(pEmployee)
	vText = "";
	If ValueIsFilled(pEmployee) And 
		ValueIsFilled(pEmployee.PermissionGroup) Then
		If pEmployee.PermissionGroup.ChatRole = Enums.ChatRoles.Supervisor Then
			vText = NStr("en = 'Enter your personal code to start working with chat'; ru = 'Работа всегда начинается с ввода персонального кода.'; de = 'Enter your personal code to start working with chat'") + "%0D%0A" +
			NStr("en = 'Enter room number. You can assign maid, change room status or attach malfunction descriptions to the room'; 
			     |ru = 'Введите номер комнаты. По номеру можете назначать горничную, поменять статус номера и фиксировать неисправности.'; 
				 |de = 'Geben Sie die Zimmernummer ein. Nach der Zimmernummer können Sie eine Magd ernennen, den Status die Zimmer ändern und Fehler beheben.'") + "%0D%0A" +
			NStr("en = 'Tap Rooms list button to view rooms of different statuses'; 
			     |ru = 'Можете просматривать списки номеров - грязные неназначенные, номера в работе, номера на инспекции.'; 
				 |de = 'Tippen Sie auf Zimmer Liste, um Zimmer mit verschiedenen Status anzuzeigen'") + "%0D%0A" +
			NStr("en = 'You will be notified in case room status is changed. Close shift to stop recieving notifications.'; 
			     |ru = 'В случае изменения статуса номера, приходят уведомления с указанием номера комнаты и времени установки статуса. Закройте смену, чтобы перестать получать уведомления.'; 
				 |de = 'Sie werden benachrichtigt, falls die zimmerstatus geändert wird. Schließen Sie shift, um Benachrichtigungen zu erhalten.'") + "%0D%0A";
		ElsIf pEmployee.PermissionGroup.ChatRole = Enums.ChatRoles.Maid Then
			vText = NStr("en = 'Enter your personal code to start working with chat. Enter room number. You can assign maid, change room status or attach malfunction descriptions to the room'; 
			            |ru = 'Введите номер комнаты. Если номер назначен в работу, то можете менять статус номера и фиксировать неисправности, по остальным номерам можно только просматривать информацию.'; 
						|de = 'Geben Sie die Zimmernummer ein. Wenn Ihnen eine Zimmernummer zugewiesen ist, können Sie den Status die Zimmer ändern und Störungen beheben, die übrigen Zimmern können nur die Informationen anzeigen.'") + "%0D%0A" +
			NStr("ru = 'Можете проверить список своих номеров в работе, а также список своих уже выполненных работ за смену.';
			     |en = 'You can check the list of your rooms in work, as well as the list of your already completed rooms per shift.';
				 |de = 'Sie können die Liste Ihrer Zimmer in Arbeit sowie die Liste Ihrer bereits fertiggestellten Zimmer pro Schicht überprüfen.'") + "%0D%0A" +
			NStr("en = 'You will be notified in case new room is assigned for you. Close shift to stop recieving notifications.'; 
			     |ru = 'В случае назначения номера в работу, приходит уведомление с указанием номера комнаты и времени установки статуса.'; 
				 |de = 'Sie werden benachrichtigt, falls Ihnen ein neues Zimmer zugewiesen wird. Schließen Sie shift, um Benachrichtigungen zu erhalten.'") + "%0D%0A";
		EndIf;
	EndIf;
	vText = vText + NStr("en = 'Enter room number or tap a button below'; 
	                   |ru = 'Для продолжения работы введите номер комнаты, или выберите одну из кнопок ниже.'; 
					   |de = 'Geben Sie Zimmer Nummer oder Tippen Sie auf eine Taste unten'");
	Return vText;
EndFunction // GetHelpText

// -----------------------------------------------------------------------------
Function GetEmployeeRoomsList(pEmployee)
	vEmployee = pEmployee;
	vQ = New Query;
	qText = "SELECT
	        |	EmployeeOperations.Room AS Room,
	        |	EmployeeOperations.Room.RoomStatus AS RoomStatus,
	        |	EmployeeOperations.Hotel.Description AS Hotel,
	        |	EmployeeOperations.Employee AS Employee,
	        |	EmployeeOperations.Room.SortCode AS RoomSortCode,
	        |	EmployeeOperations.Operation.Description AS Operation,
	        |	EmployeeOperationTotals.OperationsCount AS OperationsCount
	        |FROM
	        |	Document.EmployeeOperation AS EmployeeOperations
	        |		LEFT JOIN (SELECT
	        |			EmployeeOperationTotalRows.Hotel AS Hotel,
	        |			EmployeeOperationTotalRows.Operation AS Operation,
	        |			COUNT(EmployeeOperationTotalRows.Operation) AS OperationsCount
	        |		FROM
	        |			Document.EmployeeOperation AS EmployeeOperationTotalRows
	        |		WHERE
	        |			EmployeeOperationTotalRows.Posted
	        |			AND EmployeeOperationTotalRows.Employee = &qEmployee
	        |			AND EmployeeOperationTotalRows.OperationEndTime = &qEmptyDate
	        |		
	        |		GROUP BY
	        |			EmployeeOperationTotalRows.Hotel,
	        |			EmployeeOperationTotalRows.Operation) AS EmployeeOperationTotals
	        |		ON (EmployeeOperationTotals.Hotel = EmployeeOperations.Hotel)
	        |			AND (EmployeeOperationTotals.Operation = EmployeeOperations.Operation)
	        |WHERE
	        |	EmployeeOperations.Posted
	        |	AND EmployeeOperations.Employee = &qEmployee
	        |	AND EmployeeOperations.OperationEndTime = &qEmptyDate";
	vQ.Text = qText;			   
	vQ.SetParameter("qEmployee", vEmployee);
	vQ.SetParameter("qEmptyDate", '00010101');
	
	TRooms = vQ.Execute().Unload();
	TRooms.Columns.Add("StatusTime");
	For Each R In TRooms Do
		R.StatusTime = Catalogs.ChatBots.GetCurrentStatusTime(R.Room);
	EndDo;
	TRooms.Sort("Hotel, Operation, RoomSortCode");
	Return TRooms;
EndFunction // GetEmployeeRoomsList

// -----------------------------------------------------------------------------
Function Hello()
	If CurrentSessionDate() <= BegOfDay(CurrentSessionDate()) + 11 * 3600 
		And CurrentSessionDate() > BegOfDay(CurrentSessionDate()) + 4 * 3600 Then
		Return Catalogs.ChatBots.GetEmoji("sunrise") + NStr("de='Guten Morgen ';en='Good morning ';ru='Доброе утро'");
	EndIf;
	If CurrentSessionDate() <= BegOfDay(CurrentSessionDate()) + 18 * 3600 And 
		CurrentSessionDate() > BegOfDay(CurrentSessionDate()) + 11 * 3600 Then
		Return Catalogs.ChatBots.GetEmoji("black sun with rays") + NStr("ru='Добрый день';en='Good afternoon ';de='Guten Tag '");
	EndIf;
	If CurrentSessionDate() <= BegOfDay(CurrentSessionDate()) + 23 * 3600 And 
		CurrentSessionDate() > BegOfDay(CurrentSessionDate()) + 18 * 3600 Then
		Return Catalogs.ChatBots.GetEmoji("cityscape at dusk") + NStr("ru='Добрый вечер';de='Guten Abend ';en='Good evening '");
	EndIf;
	If CurrentSessionDate() <= BegOfDay(CurrentSessionDate()) + 4 * 3600 And 
		CurrentSessionDate() > BegOfDay(CurrentSessionDate()) + 0 * 3600 Then
		Return Catalogs.ChatBots.GetEmoji("night with stars") + NStr("de='Gute Nacht ';ru='Доброй ночи';en='Goodnight '");
	EndIf;
	Return NStr("de='Hallo';en='Hello';ru='Здравствуйте'");
EndFunction

// -----------------------------------------------------------------------------
Function getTask(pNumber)
	vTask = Documents.Message.FindByNumber(pNumber, CurrentSessionDate());	
	If Not ValueIsFilled(vTask) Then		
		vTask = Documents.Message.FindByNumber(pNumber, BegOfYear(CurrentSessionDate()) - 1);
		If ValueIsFilled(vTask) Then
			Return vTask;	
		EndIf;	
	Else
		Return vTask;
	EndIf;
EndFunction

// -----------------------------------------------------------------------------
Function GetChatCommand(pText)
	vQ = New Query("SELECT
	               |	ChatCommands.Text AS Text,
	               |	ChatCommands.CommandName AS CommandName
	               |FROM
	               |	InformationRegister.ChatCommands AS ChatCommands
	               |WHERE
	               |	ChatCommands.Text = &qText");
	vQ.SetParameter("qText", pText);
	qRes = vQ.Execute().Select();
	If qRes.Next() Then
		Return qRes.CommandName;
	EndIf;
	Return "";
EndFunction // GetChatCommand

#EndRegion
