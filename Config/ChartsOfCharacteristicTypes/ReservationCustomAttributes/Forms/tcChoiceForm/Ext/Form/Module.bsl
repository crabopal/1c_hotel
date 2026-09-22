// --------------------------------------------------------------------------------
&AtServerNoContext
Procedure ListOnGetDataAtServer(pItemName, pSettings, pRows)
	For Each vRow In pRows Do
		vRowValue = vRow.Value;
		// Description translation
		vDescriptionAppearance = vRowValue.Appearance.Get("Description");
		If vDescriptionAppearance <> Undefined Then
			vDescription = TrimAll(vRowValue.Data["Description"]);
			If Not IsBlankString(vDescription) Then
				vDescriptionInCurLang = cmNStr(vDescription, SessionParameters.CurrentLanguage);
				vDescriptionAppearance.SetParameterValue("Text", vDescriptionInCurLang);
			EndIf;
		EndIf;
	EndDo;
EndProcedure // ListOnGetDataAtServer
