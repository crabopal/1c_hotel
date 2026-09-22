#Region EventHandlers

// -----------------------------------------------------------------------------
Function AnyURLpost(pRequest)
	vRequestString = pRequest.GetBodyAsString();
	vBot = Catalogs.ChatBots.EmptyRef();
	
	For Each vHeaderRow In pRequest.Headers Do
		If StrFind(vHeaderRow.Key, "Bot-Api-Secret") = 0 Or IsBlankString(vHeaderRow.Value) Then
			Continue;
		EndIf;
		
		vBot = Catalogs.ChatBots.GetRef(New UUID(vHeaderRow.Value));
		If ValueIsFilled(vBot) And Not IsBlankString(vBot.DataVersion) Then
			Break;
		EndIf;
	EndDo;
	
	If Not ValueIsFilled(vBot) Or IsBlankString(vBot.DataVersion) Then
		vBotName = StrReplace(pRequest.RelativeURL,"/","");
		vBot = Catalogs.ChatBots.FindByDescription(vBotName);
	EndIf;
	
	If ValueIsFilled(vBot) And Not IsBlankString(vBot.DataVersion) And vBot.IsActive Then
		vAPI = cmGetChatBotAPI(vBot.BotType);
		vAPI.ProcessReply(vRequestString, vBot, True);
	EndIf;
	
	vResponse = New HTTPServiceResponse(200);
	vParamValue = pRequest.QueryOptions.Get("hello");
	If vParamValue <> Undefined Then
		vResponse.SetBodyFromString("Hello! " + vParamValue);
	EndIf;
	
	Return vResponse;
EndFunction // AnyURLpost

#EndRegion