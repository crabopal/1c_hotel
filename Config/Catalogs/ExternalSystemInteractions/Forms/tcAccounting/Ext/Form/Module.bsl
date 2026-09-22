#Region FormItemsEventHandlers

// -----------------------------------------------------------------------------
&AtClient
Procedure WebhookURLStartChoice(pItem, pChoiceData, pStandardProcessing)
	pStandardProcessing = True;
	Object.WebhookURL = GetInfoBaseURL();
EndProcedure

// -----------------------------------------------------------------------------
&AtClient
Procedure AddRedirect(pCommand)
	#If Not WebClient And Not MobileClient Then
		vCMD = "@echo off
		       |reg add HKCU\Software\Classes\e1c /ve /t REG_SZ /d 1С:Предприятие /f
		       |reg add HKCU\Software\Classes\e1c /v ""URL Protocol"" /t REG_SZ /f
		       |reg add HKCU\Software\Classes\e1c\DefaultIcon /ve /t REG_EXPAND_SZ /d %%AppData%%\1C\1cv8\common\1ceunt.dll,17 /f
		       |reg add HKCU\Software\Classes\e1c\shell\open\command /ve /t REG_EXPAND_SZ /d ""\""%%AppData%%\1C\1cv8\common\1cestart.exe\"" /URL \""%%1\"" /f";
		System(vCMD);
	#EndIf	
EndProcedure

#EndRegion
