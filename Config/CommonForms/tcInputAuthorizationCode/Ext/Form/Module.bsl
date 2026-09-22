
#Region FormEventHandlers

// -----------------------------------------------------------------------------
&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
		
	vErrorDescription 	= "";
	If Parameters.Property("SelPhone") Then
		Phone = Parameters.SelPhone;		
	EndIf;
	If Parameters.Property("SelLanguage") Then
		Language = Parameters.SelLanguage;		
	EndIf;
	If Parameters.Property("ExternalSystem") Then
		ExternalSystem = Parameters.ExternalSystem;		
	EndIf;
	If Parameters.Property("AuthorizationCode") Then
		AuthorizationCode = Parameters.AuthorizationCode;
	Else
		AuthorizationCode = GenerateVerificationCode();
	EndIf;
	If Parameters.Property("CountCharacter") And Parameters.CountCharacter > 0 And Parameters.CountCharacter <= 4 Then
		CountCharacter = Parameters.CountCharacter;	
	Else
		CountCharacter = 4;	
	EndIf;
	If Parameters.Property("SelSeconds") Then
		Seconds = Parameters.SelSeconds;
	Else
		Seconds = 40;	
	EndIf;
	OldSeconds = Seconds; 
	If Not ValueIsFilled(Language) Then
		Language = SessionParameters.CurrentLanguage;
	EndIf;
	If IsBlankString(AuthorizationCode) And Not ValueIsFilled(ExternalSystem) Then
		If Not ValueIsFilled(Phone) Then              
			pCancel = True;
			Raise NStr("en='Phone number to send SMS with verification code is empty!'; ru='Не указан номер телефона для отправки СМС с кодом подтверждения!'; de='Keine Telefonnummer für das Versenden von SMS mit Bestätigungscode!'");
		EndIf;
		// Send verification code by SMS
		vSMSTemplate = Catalogs.SMSTemplates.SendVerificationCodeMessage;
		vMessageText = SMS.GetSMSTextByLanguage(vSMSTemplate, Language);
		If IsBlankString(vMessageText) Then
			vMessageText = NStr("en='Your verification code is '; ru='Код подтверждения '; de='Ihr Bestätigungscode ist '", Language) + "&VerificationCode";
		EndIf;
		vMessageText = StrReplace(vMessageText, "&VerificationCode", AuthorizationCode);
		vMessageID = Undefined;
		
		SMS.SendMessage(vMessageText, Phone, vSMSTemplate, TrimAll(vSMSTemplate.Sender), Undefined, , SessionParameters.CurrentUser, , vErrorDescription, vMessageID);
		
		If Not ValueIsFilled(vMessageID) Then
			vErrorArr = SMS.ServerResponseDescription(vErrorDescription);       
			pCancel = True;
			Raise NStr("en = 'The authorization system is temporarily not available.'; ru = 'Система авторизации временно не работает.'; de = 'Das Autorisierungssystem ist vorübergehend nicht verfügbar.'", Language) + Chars.LF + vErrorArr.Text;
		EndIf;
		vMinutes = Int(Seconds / 60);
		vSeconds = Seconds - vMinutes * 60; 
		Items.DecorationProgress.Title = NStr("en = 'Send again via '; de = 'Nochmals senden über '; ru = 'Отправить еще раз через '") + vMinutes + ":" + vSeconds;
	EndIf;
	Items.FirstCharacter.Visible = CountCharacter > 0;
	Items.SecondCharacter.Visible = CountCharacter > 1;
	Items.ThirdCharacter.Visible = CountCharacter > 2;
	Items.FourthCharacter.Visible = CountCharacter > 3;
	Items.SendSMS.Visible = False;
	Items.DecorationProgress.Visible = Not ValueIsFilled(ExternalSystem);	  
EndProcedure // OnCreateAtServer

// -----------------------------------------------------------------------------
&AtClient
Procedure OnOpen(pCancel) 
	UniqueKey = UUID;
	If Not ValueIsFilled(ExternalSystem) Then
		AttachIdleHandler("Representation", 5);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure CharacterAutoComplete(pItem, pText, pChoiceData, pDataGetParameters, pWait, pStandardProcessing)
	ThisObject[pItem.Name] = pText;
	WindowOptionsKey = UUID;
	If StrLen(pText) = 1 Then
		If pItem.Name = "FirstCharacter" And Items.SecondCharacter.Visible Then
			CurrentItem = Items.SecondCharacter;
		ElsIf pItem.Name = "SecondCharacter" And Items.ThirdCharacter.Visible Then
			CurrentItem = Items.ThirdCharacter;
		ElsIf pItem.Name = "ThirdCharacter" And Items.FourthCharacter.Visible Then
			CurrentItem = Items.FourthCharacter;
		ElsIf pItem.Name = "FourthCharacter" And Items.FirstCharacter.Visible Then
			CurrentItem = Items.FirstCharacter;
		EndIf;
	EndIf;
	If (StrLen(FirstCharacter) = 1 Or Not Items.FirstCharacter.Visible) And (StrLen(SecondCharacter) = 1 Or Not Items.SecondCharacter.Visible) 
		And (StrLen(ThirdCharacter) = 1 Or Not Items.ThirdCharacter.Visible) And (StrLen(FourthCharacter) = 1 Or Not Items.FourthCharacter.Visible) Then
		vAuthCode = (TrimAll(FirstCharacter) + TrimAll(SecondCharacter) + TrimAll(ThirdCharacter) + TrimAll(FourthCharacter));
		If ValueIsFilled(ExternalSystem) Then
			Close(New Structure("AuthorizationCode", vAuthCode));
		Else	
			If AuthorizationCode = vAuthCode Then
				Close(True);	
			Else	
				FirstCharacter = "";
				SecondCharacter = "";
				ThirdCharacter = "";
				FourthCharacter = "";
				ShowMessageBox(, NStr("en = 'Code Input incorrectly'; de = 'Code falsch eingeben'; ru = 'Код введен неправильно'"), 2);
			EndIf;
		EndIf;
	EndIf;
EndProcedure // CharacterAutoComplete

#EndRegion

#Region FormCommandsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure SendSMS(pCommand)
	vResultSendSMS = SendSMSAtServer();
	If Not ValueIsFilled(vResultSendSMS.MessageID) Then
		ShowMessageBox(, vResultSendSMS.ErrorDescription);
	Else
		vMinutes = Int(Seconds / 60);
		vSeconds = Seconds - vMinutes * 60;  
		Items.DecorationProgress.Title = NStr("en = 'Send again via '; de = 'Nochmals senden über '; ru = 'Отправить еще раз через '") + vMinutes + ":" + vSeconds;
		Items.SendSMS.Visible = False;
		Items.DecorationProgress.Visible = True;
		AttachIdleHandler("Representation", 5);
	EndIf;
EndProcedure // SendSMS

#EndRegion

#Region Private

// ----------------------------------------------------------------------------- 
&AtServer
Function GenerateVerificationCode()
	vRnd = New RandomNumberGenerator(CurrentSessionDate() - '20000101');
	Return Format(vRnd.RandomNumber(1, 9999), "ND=4; NFD=; NLZ=; NG=");
EndFunction // GenerateVerificationCode

// -----------------------------------------------------------------------------
&AtClient
Procedure Representation() 
	Seconds = Seconds - 5;
	If Seconds > 0 Then
		vMinutes = Int(Seconds / 60);
		vSeconds = Seconds - vMinutes * 60;  
		Items.DecorationProgress.Title = NStr("en = 'Send again via '; de = 'Nochmals senden über '; ru = 'Отправить еще раз через '") + vMinutes + ":" + vSeconds;
	ElsIf Seconds <= 0 Then
		Items.SendSMS.Visible = True;
		Items.DecorationProgress.Visible = False;
		DetachIdleHandler("Representation");
		Seconds = OldSeconds;
	EndIf;
EndProcedure // Representation

// -----------------------------------------------------------------------------
&AtServer
Function SendSMSAtServer()
	vResult = New Structure("MessageID, ErrorDescription");
	vErrorDescription = "";
	AuthorizationCode = GenerateVerificationCode();
	// Send verification code by SMS
	vSMSTemplate = Catalogs.SMSTemplates.SendVerificationCodeMessage;
	vMessageText = SMS.GetSMSTextByLanguage(vSMSTemplate, Language);
	If IsBlankString(vMessageText) Then
		vMessageText = NStr("en='Your verification code is '; ru='Код подтверждения '; de='Ihr Bestätigungscode ist '", Language) + "&VerificationCode";
	EndIf;
	vMessageText = StrReplace(vMessageText, "&VerificationCode", AuthorizationCode);
	vMessageID = Undefined;
	SMS.SendMessage(vMessageText, Phone, vSMSTemplate, TrimAll(vSMSTemplate.Sender), Undefined, , SessionParameters.CurrentUser, , vErrorDescription, vMessageID);
	vResult.MessageID = vMessageID; 
	If Not ValueIsFilled(vMessageID) Then
		vErrorDescription = SMS.ServerResponseDescription(vErrorDescription);
		vResult.ErrorDescription = NStr("en = 'The authorization system is temporarily not available.'; ru = 'Система авторизации временно не работает.'; de = 'Das Autorisierungssystem ist vorübergehend nicht verfügbar.'", Language) + Chars.LF + vErrorDescription; 		
	EndIf;
	Return vResult;
EndFunction // SendSMSAtServer

#EndRegion
