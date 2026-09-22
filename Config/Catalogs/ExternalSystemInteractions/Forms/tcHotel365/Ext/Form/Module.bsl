#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateToken(pCommand)
	Object.InteractionID = String(New UUID);
	Modified = True;
EndProcedure // GenerateToken 

// -----------------------------------------------------------------------------
&AtClient
Procedure GenerateSecretKey(pCommand)
	If ValueIsFilled(Object.SecretKey) Then
		ShowQueryBox(New NotifyDescription("AfterShowQueryBox", ThisForm), NStr("en = 'Change private key?
                                                                                 |All authorized sessions of Hotel365 users will be disabled!'; de = 'Privaten Schlüssel ändern?
                                                                                 |Alle autorisierten Sitzungen von Hotel365-Benutzern werden deaktiviert!'; ru = 'Изменить секретный ключ?
                                                                                 |Все авторизованные сессии пользователей Hotel365 будут отключены!'"), QuestionDialogMode.YesNo,,, NStr("en = 'Changing the secret key'; de = 'Ändern des geheimen Schlüssels'; ru = 'Изменение секретного ключа'"));	
	Else
		Object.SecretKey = StrReplace(String(New UUID), "-", "");
		Modified = True;	
	EndIf;
EndProcedure // GenerateSecretKey

#EndRegion

#Region Private

// -----------------------------------------------------------------------------
&AtClient
Procedure AfterShowQueryBox(pResult, pExtraParams) Export
	If pResult = DialogReturnCode.Yes Then
		Object.SecretKey = StrReplace(String(New UUID), "-", "");
		Modified = True;	
	EndIf;
EndProcedure // AfterShowQueryBox 

#EndRegion