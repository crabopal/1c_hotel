
#Region FormEventHandlers

// --------------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing) 
	UpdateForm();
EndProcedure // OnCreateAtServer

// --------------------------------------------------------------------------------
&AtClient
Procedure BeforeWrite(pCancel, pWriteParameters)
	If Not Object.IsActive Then
		Return;
	EndIf;
	
	UpdateForm();
	
	If Not Object.UseMiniBar Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.MiniBarRootElement) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'Поле ""Корневая папка минибара"" не заполнено!';en = 'Field ""Mini bar root folder"" is not filled!'"));
	EndIf;
	
	If Not ValueIsFilled(Object.MiniBarMaxValue) Then
		pCancel = True;
		tcCommonFunctionOnClientServer.TextMessage(NStr("ru = 'Поле ""Макс. кол. элементов"" не заполнено!';en = 'Field ""Mini-bar max value"" is not filled!'"));	
	EndIf;
EndProcedure // BeforeWrite

// --------------------------------------------------------------------------------
&AtServer
Procedure OnReadAtServer(pCurrentObject)
	Items.Description.ReadOnly = True;
EndProcedure // OnReadAtServer

#EndRegion

#Region FormHeaderItemsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure MiniBarOnChange(pItem)
	UpdateForm();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure EngineerDepartmentsOnActivateRow(pItem)
	If pItem.CurrentData = Undefined Or pItem.CurrentData.ID <> 0 Then
		Return;
	EndIf;
	
	pItem.CurrentData.ID = Object.EngineerDepartments.Count();
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure DecorationCheckLinkClick(pItem)
	BeginRunningApplication(New NotifyDescription, TrimAll(Object.WebhookKey)+"/"+TrimAll(Object.Description)+"?hello=OK");
EndProcedure

// --------------------------------------------------------------------------------
&AtClient
Procedure BotTypeOnChange(pItem)
	UpdateForm();
EndProcedure // BotTypeOnChange

#EndRegion

#Region FormCommandsEventHandlers

// --------------------------------------------------------------------------------
&AtClient
Procedure CheckConnection(pCommand)
	If Modified And (Not CheckFilling() Or Not Write()) Then
		Return;
	EndIf;
	
	CheckConnectionServer();
EndProcedure // CheckConnection

// --------------------------------------------------------------------------------
&AtClient
Procedure SetWebhook(pCommand)
	If Modified And (Not CheckFilling() Or Not Write()) Then
		Return;
	EndIf;
	
	SetWebhookAtServer();
EndProcedure // SetWebhook

// --------------------------------------------------------------------------------
&AtClient
Procedure GetWebhookInfo(pCommand)
	If Modified And (Not CheckFilling() Or Not Write()) Then
		Return;
	EndIf;
	
	GetWebhookInfoAtServer();
EndProcedure // GetWebhookInfo

// --------------------------------------------------------------------------------
&AtClient
Procedure DeleteWebhook(pCommand)
	If Modified And (Not CheckFilling() Or Not Write()) Then
		Return;
	EndIf;
	
	DeleteWebhookAtServer();
EndProcedure // DeleteWebhook

#EndRegion

#Region Private

// --------------------------------------------------------------------------------
&AtServer
Function CheckConnectionServer()
	vAPI = Undefined;
	
	vAPI = cmGetChatBotAPI(Object.BotType);
	
	If vAPI = Undefined Then
		vErr = Nstr("en = 'Unknown integration type'; de = 'Unbekannter Integrationstyp'; ru = 'Неизвестный тип интеграции'");
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vErr);
		Return False;
	EndIf;
	
	vResponse = vAPI.CheckConnection(Object.Ref);
	If Not vResponse.Result Then
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vResponse.Error);
		Return False;
	EndIf;
	
	tcCommonFunctionOnClientServer.TextMessage("Bot name: " + vResponse.UserName);
	Return True;
EndFunction // CheckConnectionServer

// --------------------------------------------------------------------------------
&AtServer
Procedure SetWebhookAtServer()
	vAPI = cmGetChatBotAPI(Object.BotType);
	
	If vAPI = Undefined Then
		vErr = Nstr("en = 'Unknown integration type'; de = 'Unbekannter Integrationstyp'; ru = 'Неизвестный тип интеграции'");
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vErr);
		Return;
	EndIf;
	
	vAPI.SetWebHook(Object.Ref);
EndProcedure // SetWebhookAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure GetWebhookInfoAtServer()
	vAPI = cmGetChatBotAPI(Object.BotType);
	
	If vAPI = Undefined Then
		vErr = Nstr("en = 'Unknown integration type'; de = 'Unbekannter Integrationstyp'; ru = 'Неизвестный тип интеграции'");
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vErr);
		Return;
	EndIf;
	
	vAPI.getWebhookInfo(Object.Ref);
EndProcedure // GetWebhookInfoAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure DeleteWebhookAtServer()
	vAPI = cmGetChatBotAPI(Object.BotType);
	
	If vAPI = Undefined Then
		vErr = Nstr("en = 'Unknown integration type'; de = 'Unbekannter Integrationstyp'; ru = 'Неизвестный тип интеграции'");
		tcCommonFunctionOnClientServer.TextMessage("Error: " + vErr);
		Return;
	EndIf;
	
	vAPI.deleteWebhook(Object.Ref);
EndProcedure // DeleteWebhookAtServer

// --------------------------------------------------------------------------------
&AtServer
Procedure UpdateForm()
	Items.MiniBarRootElement.Enabled = Object.UseMiniBar;
	Items.MiniBarMaxValue.Enabled = Object.UseMiniBar;
	
	If Object.BotType = Enums.BotTypes.MAX Then
		Items.Server.InputHint = "platform-api.max.ru";
	Else
		Items.Server.InputHint = "api.telegram.org";
	EndIf;
EndProcedure // UpdateForm

#EndRegion
