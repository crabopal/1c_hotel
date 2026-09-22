
#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = Items.FormSetColor.BackColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject))
EndProcedure // SetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	Object.ColorString = "";
	Items.FormSetColor.BackColor = tcCommonFunctionOnClientServer.ColorConstructor();
EndProcedure // ClearColor

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			Items.FormSetColor.BackColor = pColor;
			Object.ColorString = GetColorString(pColor);
		Else
			ShowMessageBox(, NStr("en = 'You can choose web or absolute colors only! Style and windows colors are not supported.'; 
								  |de = 'Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'; 
								  |ru = 'Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColorString(pColor)
	Return XDTOSerializer.XMLString(pColor);	
EndFunction // GetColorString

#EndRegion 
