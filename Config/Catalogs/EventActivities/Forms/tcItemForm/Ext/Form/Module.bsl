#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(pCancel, pStandardProcessing)
	If Parameters.Property("AvtoTest") Then
		If Parameters.AvtoTest Then
			Return;
		EndIf;	
	EndIf;
	If Not tcOnServer.cmCheckUserPermissionsAtServer("HavePermissionToManageResources") Then 
		If Object.Ref.IsEmpty() Then
			tcCommonFunctionOnClientServer.TextMessage(NStr("en='You do not have rights for MICE management!';ru='Нет прав на управление MICE!';de='Sie haben keine Rechte, den MICE zu verwalten!'"));
			pCancel = True;
			Return;
		Else
			ReadOnly = True;
		EndIf;
	EndIf;	
	
	// Let's set the properties of the form
	tcProtection.SetFormProperties(ThisObject);
	
	// Color
	vColor = GetColor();
	If vColor <> Undefined Then
		ItemColor = vColor;
		ItemColorIsSet = True;
		Items.FormSetColor.BackColor = vColor;
	Else
		ItemColor = Undefined;
		ItemColorIsSet = False;
	EndIf;
EndProcedure

// --------------------------------------------------------------------------------
&AtServer
Procedure BeforeWriteAtServer(pCancel, pCurrentObject, pWriteParameters)
	If ItemColorIsSet Then
		pCurrentObject.ColorHexString = tcOnServer.ColorToHex(ItemColor);
		pCurrentObject.Color = New ValueStorage(tcOnServer.HexToColor(pCurrentObject.ColorHexString));
	Else
		pCurrentObject.ColorHexString = "";
		pCurrentObject.Color = Undefined;
	EndIf;
EndProcedure // BeforeWriteAtServer

#EndRegion

#Region FormCommandsEventHandlers

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColor(pCommand)
	// Choose color
	vColorDlg =  New ColorChooseDialog;
	vColorDlg.Color = ItemColor;
	vColorDlg.Show(New NotifyDescription("SetColorAfterUserChoice", ThisObject))
EndProcedure

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure ClearColor(pCommand)
	// Clear color
	ItemColor = Undefined;
	ItemColorIsSet = False;
	Items.FormSetColor.BackColor = Items.FormClearColor.BackColor;
EndProcedure // ClearColor

#EndRegion

#Region Private

// ------------------------------------------------------------------------------------------------
&AtServer
Function GetColor()
	vColor = Undefined;
	If Not IsBlankString(Object.ColorHexString) Then
		vColor = tcOnServer.HexToColor(Object.ColorHexString);
		If TypeOf(vColor) <> Type("Color") Then
			vColor = Undefined;
		EndIf;
	EndIf;
	Return vColor;
EndFunction // GetColor

// ------------------------------------------------------------------------------------------------
&AtClient
Procedure SetColorAfterUserChoice(pColor, pExtraParams) Export
	If pColor <> Undefined Then
		If pColor.Type = ColorType.WebColor Or pColor.Type = ColorType.Absolute Then
			ItemColor = pColor;
			ItemColorIsSet = True;
			Items.FormSetColor.BackColor = pColor;
		Else
			ShowMessageBox(, NStr("en='You can choose web or absolute colors only! Style and windows colors are not supported.';ru='Можете выбирать только абсолютные цвета (по названию или по RGB)! Выбор цветов из стилей не поддерживается.';de='Sie dürfen nur absolute Farben wählen (nach Bezeichnung oder nach RGB)! Die Farbenauswahl aus Stilen wird nicht unterstützt.'"));
		EndIf;
	EndIf;
EndProcedure // SetColorAfterUserChoice

#EndRegion
