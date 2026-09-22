
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		If ValueIsFilled(vRow.Key.Ref) Then
			vRow.Value.Data.Description = tcOnServer.cmNStrAtServer(vRow.Key.Description);
			If Not vRow.Key.Ref.IsFolder And (Not IsBlankString(vRow.Key.SMSTextRu) Or Not IsBlankString(vRow.Key.SMSTextEn) Or Not IsBlankString(vRow.Key.SMSTextDe)) Then
				If SessionParameters.CurrentLanguage = Catalogs.Languages.RU Then
					vRow.Value.Data.SMSText = TrimAll(vRow.Key.SMSTextRu);
					vRow.Value.Data.MessageLength = Format(StrLen(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG="); 
					vRow.Value.Data.NumberOfSMS = Format(SMS.GetNumberOfSegments(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG=");
				ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.EN Then
					vRow.Value.Data.SMSText = TrimAll(vRow.Key.SMSTextEn);
					vRow.Value.Data.MessageLength = Format(StrLen(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG="); 
					vRow.Value.Data.NumberOfSMS = Format(SMS.GetNumberOfSegments(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG=");					
				ElsIf SessionParameters.CurrentLanguage = Catalogs.Languages.DE Then
					vRow.Value.Data.SMSText = TrimAll(vRow.Key.SMSTextDe);
					vRow.Value.Data.MessageLength = Format(StrLen(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG="); 
					vRow.Value.Data.NumberOfSMS = Format(SMS.GetNumberOfSegments(vRow.Value.Data.SMSText), "ND=10; NFD=0; NG=");					
				EndIf;
			EndIf;
		EndIf;
	EndDo;                                          
EndProcedure
